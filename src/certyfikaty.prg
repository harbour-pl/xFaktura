/*
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: certyfikaty.prg
 *
 * Copyright (c) 2026 xDev-Language
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "dbinfo.ch"
#include "inkey.ch"
#include "xfaktura.ch"

#define DNI_OSTRZEZENIA  30

PROCEDURE p_Certyfikaty( oWindow )

   LOCAL oDialog
   LOCAL oToolbar
   LOCAL oPanel
   LOCAL oBrowse
   LOCAL oStatus
   LOCAL aZamroz := {}

   IF ! s_DbOpen()
      RETURN
   ENDIF

   oDialog := gui_Dialog():New( oWindow, "Lista certyfikatów KSeF", 900, 600 )
   oDialog:background := 0xe9edf1
   oDialog:sizable := .T.
   oDialog:SetKey( "Ins", {|| s_Dodaj( oDialog, oPanel ), s_Stan( oDialog, aZamroz ) } )

   oStatus := gui_StatusBar():New( oDialog )
   oStatus:name := "STATUS_BAR"
   oStatus:font := gui_Font():New( NIL, .F., .F., "xFont 9x18" )
   oStatus:Add( 0 )
   oStatus:Add( 60 )
   oStatus:scoreboard := 2

   oToolbar := gui_Toolbar():New( oDialog, "Bottom" )
   oToolbar:name := "PASEK"
   oToolbar:Add( "F1-Pomoc",    NIL, {|| s_Pomoc( oDialog ) }, NIL, "F1" )
   oToolbar:AddSeparator()
   oToolbar:Add( "F2-Wczytaj",  NIL, {|| s_Dodaj( oDialog, oPanel ), s_Stan( oDialog, aZamroz ) }, NIL, "F2" )
   oToolbar:AddSeparator()
   oToolbar:Add( "F3-Aplikacja KSeF", NIL, {|| s_Aplikacja() }, NIL, "F3" )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F8-Usuń",     NIL, {|| s_Usun( oDialog ), s_Stan( oDialog, aZamroz ) }, NIL, "F8" ) )
   oToolbar:AddSeparator()
   oToolbar:Add( "Esc-Zamknij", NIL, {|| oDialog:Close() },      NIL, "Esc" )

   oPanel := gui_Panel():New( oDialog )

   s_Opis( oPanel,  13, "Nazwa:" )
   s_Opis( oPanel,  43, "Typ / numer:" )
   s_Opis( oPanel,  73, "Właściciel:", "OPIS_PODMIOT" )
   s_Opis( oPanel, 103, "Ważność:" )

   s_Pole( oPanel, 175,  10, 60, "NAZWA" )
   s_Pole( oPanel, 175,  40, 23, "TYP" )
   s_Pole( oPanel, 400,  40, 35, "NUMER" )
   s_Pole( oPanel, 175,  70, 60, "PODMIOT" )
   s_Pole( oPanel, 175, 100, 23, "WAZNY" )
   s_Pole( oPanel, 400, 100, 35, "STAN" )

   oBrowse := gui_Browse():New( oPanel, 10, 140, oPanel:width - 20, oPanel:height - 150 )
   oBrowse:name             := "BRW"
   oBrowse:headerBackground := 0x4d7326
   oBrowse:anchor           := "LTRB"
   oBrowse:goTopBlock       := {|| CERTYFIKATY->( dbGoTop() ) }
   oBrowse:goBottomBlock    := {|| CERTYFIKATY->( dbGoBottom() ) }
   oBrowse:skipBlock        := {| n | CERTYFIKATY->( DbSkipper( n ) ) }
   oBrowse:positionBlock    := {|| CERTYFIKATY->( IIF( LastRec() > 0, RecNo() / LastRec(), 0 ) ) }
   oBrowse:emptyBlock       := {|| s_Pusta() }
   oBrowse:AddColumn( "Poz.",                     {|| CERTYFIKATY->( RecNo() ) }, 4 )
   oBrowse:AddColumn( PadR( "Nazwa", 30 ),        {|| Left( CERTYFIKATY->NAZWA, 30 ) }, 30 )
   oBrowse:AddColumn( PadR( "Typ", 14 ),          {|| s_Typ( CERTYFIKATY->TYP ) } )
   oBrowse:AddColumn( PadC( "NIP", 12 ),          {|| Left( CERTYFIKATY->NIP, 12 ) } )
   oBrowse:AddColumn( "Środowisko",               {|| s_Srodowisko( CERTYFIKATY->KSEF_SROD ) } )
   oBrowse:AddColumn( "Ważny do",                 {|| CERTYFIKATY->D_DO } )
   oBrowse:AddColumn( PadR( "Stan", 20 ),         {|| PadR( s_Waznosc( CERTYFIKATY->D_DO ), 20 ) } )
   oBrowse:OnChange := {|| s_Okno( oDialog ) }

   CERTYFIKATY->( dbGoTop() )
   s_Okno( oDialog )
   s_Stan( oDialog, aZamroz )

   s_Ostrzez()

   oDialog:Center()
   oDialog:ShowModal()

   CERTYFIKATY->( dbCloseArea() )

RETURN

/* ---------------------------------------------------------------------------------------------
   Baza
   --------------------------------------------------------------------------------------------- */

STATIC FUNCTION s_Struct()
RETURN { ;
   { "NAZWA",          "C",  60, 0 }, ;
   { "NIP",            "C",  20, 0 }, ;
   { "KSEF_SROD",      "N",   1, 0 }, ;
   { "TYP",            "C",  14, 0 }, ;
   { "NUMER",          "C",  40, 0 }, ;
   { "PODMIOT",        "C", 200, 0 }, ;
   { "D_OD",           "D",   8, 0 }, ;
   { "D_DO",           "D",   8, 0 }, ;
   { "CERT",           "M",  10, 0 }, ;
   { "SZYFR",          "M",  10, 0 }, ;
   { "HASLO",          "M",  10, 0 }, ;
   { "D_DODANIA",      "D",   8, 0 } }

STATIC FUNCTION s_DbOpen()

   LOCAL cBaza

   cBaza := "ksef" + DirSepToOS( "\" ) + "certyfikaty"
   IF ! FileExists( cBaza + ".dbf" )
      dbCreate( cBaza, s_Struct() )
   ENDIF

   dbSelectArea( 0 )
   IF ! NetUse( cBaza, .F., NIL, "CERTYFIKATY" )
      RETURN .F.
   ENDIF

   IF ! s_Okay()
      CERTYFIKATY->( dbCloseArea() )
      gui_MsgInfo( "Zmiana struktury bazy certyfikatów", "Certyfikaty" )
      s_Rekonstrukcja()
      dbSelectArea( 0 )
      IF ! NetUse( cBaza, .F., NIL, "CERTYFIKATY" )
         RETURN .F.
      ENDIF
      IF ! s_Okay()
         CERTYFIKATY->( dbCloseArea() )
         RETURN .F.
      ENDIF
   ENDIF

RETURN .T.

STATIC FUNCTION s_Okay()

   LOCAL aWzor
   LOCAL aBaza
   LOCAL nPole

   aWzor := s_Struct()
   aBaza := CERTYFIKATY->( dbStruct() )
   IF Len( aBaza ) != Len( aWzor )
      RETURN .F.
   ENDIF
   FOR nPole := 1 TO Len( aWzor )
      IF !( aBaza[ nPole ][ 1 ] == aWzor[ nPole ][ 1 ] ) .OR. ;
         !( aBaza[ nPole ][ 2 ] == aWzor[ nPole ][ 2 ] ) .OR. ;
            aBaza[ nPole ][ 3 ] != aWzor[ nPole ][ 3 ]   .OR. ;
            aBaza[ nPole ][ 4 ] != aWzor[ nPole ][ 4 ]
         RETURN .F.
      ENDIF
   NEXT

RETURN .T.

STATIC PROCEDURE s_Rekonstrukcja()

   LOCAL cBaza
   LOCAL cTmp
   LOCAL cExt
   LOCAL cStary
   LOCAL cMemo

   cBaza := "ksef" + DirSepToOS( "\" ) + "certyfikaty"
   cTmp  := "ksef" + DirSepToOS( "\" ) + "tmp.dbf"

   cExt   := RddInfo( RDDI_MEMOEXT )
   cStary := IIF( FileExists( cBaza + ".fpt" ), ".fpt", cExt )
   cMemo  := "ksef" + DirSepToOS( "\" ) + "tmp" + cStary
   IF ! FileExists( cBaza + ".dbf" )
      RETURN
   ENDIF

   FErase( cTmp )
   FErase( cMemo )
   IF FRename( cBaza + ".dbf", cTmp ) != 0
      RETURN
   ENDIF
   IF FileExists( cBaza + cStary ) .AND. FRename( cBaza + cStary, cMemo ) != 0
      FRename( cTmp, cBaza + ".dbf" )
      RETURN
   ENDIF

   dbCreate( cBaza, s_Struct() )

   IF ! FileExists( cBaza + ".dbf" )
      FRename( cTmp, cBaza + ".dbf" )
      FRename( cMemo, cBaza + cStary )
      RETURN
   ENDIF

   dbSelectArea( 0 )
   IF ! NetUse( cBaza, .T., NIL, "CERTYFIKATY" )
      FErase( cBaza + ".dbf" )
      FErase( cBaza + cExt )
      FRename( cTmp, cBaza + ".dbf" )
      FRename( cMemo, cBaza + cStary )
      RETURN
   ENDIF
   CERTYFIKATY->( DbAppendFrom( cTmp ) )
   CERTYFIKATY->( dbCloseArea() )
   FErase( cTmp )
   FErase( cMemo )

RETURN

FUNCTION p_CertyfikatyPobierz( cNipFirmy, nSrodowiskoKsef, cTyp )

   LOCAL nObszar := Select()
   LOCAL hCert   := NIL
   LOCAL cDer

   IF ! s_DbOpen()
      dbSelectArea( nObszar )
      RETURN NIL
   ENDIF
   CERTYFIKATY->( dbGoBottom() )
   DO WHILE ! CERTYFIKATY->( Bof() ) .AND. ! CERTYFIKATY->( Eof() )
      IF AllTrim( CERTYFIKATY->NIP ) == AllTrim( cNipFirmy ) .AND. CERTYFIKATY->KSEF_SROD == nSrodowiskoKsef .AND. ;
         AllTrim( CERTYFIKATY->TYP ) == cTyp .AND. CERTYFIKATY->D_OD <= Date() .AND. CERTYFIKATY->D_DO >= Date()
         cDer  := Base64Decode( AllTrim( CERTYFIKATY->CERT ) )
         hCert := { "NUMER" => AllTrim( CERTYFIKATY->NUMER ), ;
                    "KLUCZ" => s_Odszyfruj( CERTYFIKATY->SZYFR ), ;
                    "HASLO" => s_Odszyfruj( CERTYFIKATY->HASLO ), ;
                    "RSA"   => Chr( 0x06 ) + Chr( 0x09 ) + Chr( 0x2A ) + Chr( 0x86 ) + Chr( 0x48 ) + Chr( 0x86 ) + ;
                               Chr( 0xF7 ) + Chr( 0x0D ) + Chr( 0x01 ) + Chr( 0x01 ) + Chr( 0x01 ) $ cDer }
         EXIT
      ENDIF
      CERTYFIKATY->( dbSkip( -1 ) )
   ENDDO
   CERTYFIKATY->( dbCloseArea() )
   dbSelectArea( nObszar )

RETURN hCert

/* ---------------------------------------------------------------------------------------------
   Indexy
   --------------------------------------------------------------------------------------------- */

PROCEDURE p_CertyfikatyNtx()

   LOCAL cBaza

   cBaza := "ksef" + DirSepToOS( "\" ) + "certyfikaty"
   IF FileExists( cBaza + ".dbf" )

      dbSelectArea( 0 )
      IF NetUse( cBaza, .T., NIL, "CERTYFIKATY" )
         NetPack()
         CERTYFIKATY->( dbCloseArea() )
      ENDIF

   ENDIF

RETURN

STATIC FUNCTION s_Pusta()

   LOCAL nRecNo := CERTYFIKATY->( RecNo() )
   LOCAL lPusta

   CERTYFIKATY->( dbGoTop() )
   lPusta := CERTYFIKATY->( Eof() )
   CERTYFIKATY->( dbGoto( nRecNo ) )

RETURN lPusta

STATIC PROCEDURE s_Stan( oDialog, aZamroz )

   LOCAL lJest := ! s_Pusta()

   AEval( aZamroz, {| nPrzycisk | oDialog:PASEK:Enable( nPrzycisk, lJest ) } )
   oDialog:BRW:enabled := lJest
   oDialog:BRW:Refresh()

   IF lJest
      oDialog:BRW:SetFocus()
   ENDIF

RETURN

STATIC PROCEDURE s_Opis( oPanel, nY, cText, cName )

   LOCAL oSay

   oSay := gui_Say():New( oPanel, 20, nY, 15, 20, cText )
   IF cName != NIL
      oSay:name := cName
   ENDIF

RETURN

STATIC PROCEDURE s_Pole( oPanel, nX, nY, nLen, cName )

   LOCAL oSay

   oSay := gui_Say():New( oPanel, nX, nY, nLen, 24 )
   oSay:name   := cName
   oSay:border := .T.

RETURN

STATIC PROCEDURE s_Pomoc( oWindow )

   p_Pomoc( oWindow, "Lista certyfikatów KSeF", ;
      Eol() + ;
      "Certyfikat KSeF wydaje Aplikacja Podatnika KSeF (Certyfikaty - Wnioskuj)." + Eol() + ;
      "Przy wniosku zapisuje ona klucz prywatny (plik .key) chroniony hasłem," + Eol() + ;
      "a po wydaniu certyfikat pobiera się z listy certyfikatów (plik .crt, PEM)." + Eol() + ;
      "Oba pliki zapisz w katalogu ksef programu xFaktura - tam otwiera się F2." + Eol() + ;
      Eol() + ;
      "Typ Offline służy do kodu QR II na fakturach wystawionych w trybie offline," + Eol() + ;
      "typ Authentication do logowania w KSeF." + Eol() + ;
      Eol() + ;
      "F1             pomoc" + Eol() + ;
      "F2, Ins        wczytanie certyfikatu: plik .crt, plik .key i hasło klucza" + Eol() + ;
      "F3             Aplikacja Podatnika KSeF w przeglądarce (środowisko firmy)" + Eol() + ;
      "F8             usunięcie certyfikatu z listy" + Eol() + ;
      "Strzałki       poprzedni / następny certyfikat" + Eol() + ;
      "Esc            zamknięcie okna" + Eol() + ;
      Eol() + ;
      "Wpisywanie danych" + Eol() + ;
      Eol() + ;
      "Ctrl+V         wklejenie hasła" + Eol() + ;
      "Enter          następne pole, na ostatnim zapis" + Eol() + ;
      "PgUp, PgDn     zapis" + Eol() + ;
      "Esc            bez zapisu" + Eol() + ;
      Eol() + ;
      "Klucz prywatny i hasło są zapisane w bazie zaszyfrowane." + Eol() + ;
      "Na " + LTrim( Str( DNI_OSTRZEZENIA ) ) + " dni przed końcem ważności xFaktura ostrzega przy otwarciu listy." )

RETURN

STATIC PROCEDURE s_Okno( oDialog )

   LOCAL lEof := CERTYFIKATY->( Eof() )

   oDialog:NAZWA:text   := CERTYFIKATY->NAZWA
   oDialog:TYP:text     := IIF( lEof, "", s_Typ( CERTYFIKATY->TYP ) )
   oDialog:NUMER:text   := CERTYFIKATY->NUMER
   oDialog:PODMIOT:text := CERTYFIKATY->PODMIOT
   oDialog:WAZNY:text   := IIF( lEof, "", DToC( CERTYFIKATY->D_OD ) + " - " + DToC( CERTYFIKATY->D_DO ) )
   oDialog:STAN:text    := IIF( lEof, "", s_Waznosc( CERTYFIKATY->D_DO ) )

RETURN

STATIC FUNCTION s_Srodowisko( nSrodowiskoKsef, lPelna )

   DO CASE
   CASE nSrodowiskoKsef == 3
      RETURN IIF( lPelna == .T., "Produkcyjne (prawdziwe faktury)", "Produkcyjne" )
   ENDCASE

RETURN IIF( lPelna == .T., "Testowe (próbny, do testów)", "Testowe" )

STATIC FUNCTION s_Typ( cTyp )

   DO CASE
   CASE AllTrim( cTyp ) == "Offline"
      RETURN PadR( "Offline", 14 )
   CASE AllTrim( cTyp ) == "Authentication"
      RETURN PadR( "Authentication", 14 )
   ENDCASE

RETURN PadR( "Nieznany", 14 )

STATIC FUNCTION s_Waznosc( dDo )

   LOCAL nDni

   IF Empty( dDo )
      RETURN ""
   ENDIF
   nDni := dDo - Date()
   DO CASE
   CASE nDni < 0
      RETURN "Wygasł " + DToC( dDo )
   CASE nDni == 0
      RETURN "Wygasa dzisiaj"
   CASE nDni <= DNI_OSTRZEZENIA
      RETURN "Wygasa za " + LTrim( Str( nDni ) ) + IIF( nDni == 1, " dzień", " dni" )
   ENDCASE

RETURN "Ważny"

STATIC PROCEDURE s_Ostrzez()

   LOCAL nRecNo := CERTYFIKATY->( RecNo() )
   LOCAL cTekst := ""

   CERTYFIKATY->( dbGoTop() )
   DO WHILE ! CERTYFIKATY->( Eof() )
      IF ! Empty( CERTYFIKATY->D_DO ) .AND. CERTYFIKATY->D_DO - Date() <= DNI_OSTRZEZENIA
         cTekst += Eol() + AllTrim( CERTYFIKATY->NAZWA ) + " (" + AllTrim( s_Typ( CERTYFIKATY->TYP ) ) + "): " + ;
                   s_Waznosc( CERTYFIKATY->D_DO )
      ENDIF
      CERTYFIKATY->( dbSkip() )
   ENDDO
   CERTYFIKATY->( dbGoto( nRecNo ) )

   IF ! Empty( cTekst )
      gui_MsgWarning( "Certyfikaty KSeF do odnowienia:" + Eol() + cTekst + Eol() + Eol() + ;
                      "Nowy certyfikat wnioskuje się w Aplikacji Podatnika KSeF (F3).", "Certyfikaty" )
   ENDIF

RETURN

STATIC PROCEDURE s_Dodaj( oDialog, oPanel )

   LOCAL GetList
   LOCAL nRecNo
   LOCAL cStart
   LOCAL cPlikCert
   LOCAL cPlikKlucza
   LOCAL cCert
   LOCAL cKlucz
   LOCAL aInfo
   LOCAL cTyp
   LOCAL cNumer
   LOCAL cNazwa
   LOCAL cHaslo
   LOCAL cNipFirmy
   LOCAL nSrodowiskoKsef
   LOCAL cPodpis
   LOCAL nGet

   GetList         := {}
   nRecNo          := CERTYFIKATY->( RecNo() )
   cNipFirmy       := ""
   nSrodowiskoKsef := 1
   IF ! p_FirmaPobierzKsef( @cNipFirmy, @nSrodowiskoKsef ) .OR. Empty( cNipFirmy )
      gui_MsgInfo( "Najpierw wpisz NIP firmy w Pliki - Ustawienia - Firma.", "Certyfikaty" )
      RETURN
   ENDIF

   cStart    := DiskName() + ":" + DirSepToOS( "\" ) + CurDir()
   cPlikCert := gui_FileOpenDialog( "Wskaż plik certyfikatu KSeF (.crt)", ;
                                    { { "Certyfikat KSeF", "*.crt;*.pem;*.cer" }, { "Wszystkie pliki", "*.*" } }, ;
                                    cStart + DirSepToOS( "\" ) + "ksef" + DirSepToOS( "\" ) + "*.crt" )
   DirChange( cStart )
   IF Empty( cPlikCert )
      RETURN
   ENDIF
   cCert := MemoRead( cPlikCert, .T. )
   aInfo := CertInfo( cCert )
   IF aInfo == NIL
      gui_MsgError( "Plik nie zawiera certyfikatu:" + Eol() + cPlikCert + Eol() + CryptoError(), "Certyfikaty" )
      RETURN
   ENDIF
   cTyp   := s_TypZDer( aInfo[ 6 ] )
   cNumer := s_NumerZDer( aInfo[ 6 ] )

   IF s_Jest( cNumer, nSrodowiskoKsef )
      gui_MsgInfo( "Ten certyfikat jest już na liście:" + Eol() + cNumer, "Certyfikaty" )
      RETURN
   ENDIF

   cPlikKlucza := gui_FileOpenDialog( "Wskaż plik klucza prywatnego certyfikatu (.key)", ;
                                      { { "Klucz prywatny", "*.key;*.pem" }, { "Wszystkie pliki", "*.*" } }, ;
                                      cStart + DirSepToOS( "\" ) + "ksef" + DirSepToOS( "\" ) + "*.key" )
   DirChange( cStart )
   IF Empty( cPlikKlucza )
      RETURN
   ENDIF
   cKlucz := MemoRead( cPlikKlucza, .T. )

   cNazwa := ""
   FNameSplit( cPlikCert, NIL, @cNazwa )
   cNazwa := PadR( cNazwa, Len( CERTYFIKATY->NAZWA ) )
   cHaslo := Space( 64 )

   CERTYFIKATY->( dbGoBottom() )
   CERTYFIKATY->( dbSkip() )
   s_Okno( oDialog )
   oDialog:TYP:text     := s_Typ( cTyp )
   oDialog:NUMER:text   := cNumer
   oDialog:PODMIOT:text := aInfo[ 1 ]
   oDialog:WAZNY:text   := DToC( s_Data( aInfo[ 4 ] ) ) + " - " + DToC( s_Data( aInfo[ 5 ] ) )
   oDialog:STAN:text    := s_Waznosc( s_Data( aInfo[ 5 ] ) )

   AAdd( GetList, gui_Get():New( oPanel, 175, 10, 60, NIL, @cNazwa ) )
   AAdd( GetList, gui_Get():New( oPanel, 175, 70, 60, NIL, @cHaslo ) )
   oDialog:PODMIOT:text      := ""
   oDialog:OPIS_PODMIOT:text := "Hasło klucza:"

   oDialog:STATUS_BAR:text := " Nazwa i hasło klucza --> PgUp PgDn Enter = zapisz, Esc = bez zapisu"
   oDialog:STATUS_BAR:background := 0x73264d
   oDialog:STATUS_BAR:foreground := 0xffffff

   oDialog:ReadModal( GetList )

   oDialog:STATUS_BAR:text       := ""
   oDialog:STATUS_BAR:background := NIL
   oDialog:STATUS_BAR:foreground := NIL
   oDialog:OPIS_PODMIOT:text     := "Właściciel:"

   FOR nGet := 1 TO Len( GetList )
      GetList[ nGet ]:Destroy()
   NEXT

   IF LastKey() == K_ESC
      CERTYFIKATY->( dbGoto( nRecNo ) )
      s_Okno( oDialog )
      RETURN
   ENDIF

   cHaslo  := AllTrim( cHaslo )
   cPodpis := SignData( cKlucz, "xFaktura", "SHA256", cHaslo )
   IF cPodpis == NIL
      gui_MsgError( "Nie można otworzyć klucza prywatnego - złe hasło albo zły plik:" + Eol() + ;
                    cPlikKlucza + Eol() + CryptoError(), "Certyfikaty" )
      CERTYFIKATY->( dbGoto( nRecNo ) )
      s_Okno( oDialog )
      RETURN
   ENDIF
   IF ! VerifyData( cCert, "xFaktura", cPodpis, "SHA256" )
      gui_MsgError( "Klucz prywatny nie pasuje do certyfikatu:" + Eol() + ;
                    cPlikKlucza + Eol() + cPlikCert, "Certyfikaty" )
      CERTYFIKATY->( dbGoto( nRecNo ) )
      s_Okno( oDialog )
      RETURN
   ENDIF

   dbSelectArea( "CERTYFIKATY" )
   IF ! NetAppBlank()
      CERTYFIKATY->( dbGoto( nRecNo ) )
      s_Okno( oDialog )
      RETURN
   ENDIF
   CERTYFIKATY->NAZWA     := IIF( Empty( cNazwa ), "Certyfikat " + DToC( Date() ), cNazwa )
   CERTYFIKATY->NIP       := cNipFirmy
   CERTYFIKATY->KSEF_SROD := nSrodowiskoKsef
   CERTYFIKATY->TYP       := cTyp
   CERTYFIKATY->NUMER     := cNumer
   CERTYFIKATY->PODMIOT   := aInfo[ 1 ]
   CERTYFIKATY->D_OD      := s_Data( aInfo[ 4 ] )
   CERTYFIKATY->D_DO      := s_Data( aInfo[ 5 ] )
   CERTYFIKATY->CERT      := Base64Encode( aInfo[ 6 ] )
   CERTYFIKATY->SZYFR     := s_Zaszyfruj( cKlucz )
   CERTYFIKATY->HASLO     := s_Zaszyfruj( cHaslo )
   CERTYFIKATY->D_DODANIA := Date()
   dbCommit()
   dbUnlock()

   oDialog:BRW:Refresh()
   s_Okno( oDialog )

   IF cTyp == ""
      gui_MsgWarning( "Nie rozpoznano typu certyfikatu (Offline / Authentication).", "Certyfikaty" )
   ENDIF

RETURN

STATIC FUNCTION s_Jest( cNumer, nSrodowiskoKsef )

   LOCAL nRecNo := CERTYFIKATY->( RecNo() )
   LOCAL lJest  := .F.

   CERTYFIKATY->( dbGoTop() )
   DO WHILE ! CERTYFIKATY->( Eof() )
      IF AllTrim( CERTYFIKATY->NUMER ) == cNumer .AND. CERTYFIKATY->KSEF_SROD == nSrodowiskoKsef
         lJest := .T.
         EXIT
      ENDIF
      CERTYFIKATY->( dbSkip() )
   ENDDO
   CERTYFIKATY->( dbGoto( nRecNo ) )

RETURN lJest

STATIC FUNCTION s_Data( cCzas )
RETURN SToD( StrTran( Left( cCzas, 10 ), "-", "" ) )

STATIC FUNCTION s_Der( cDer, nPoz )

   LOCAL nDlugosc
   LOCAL nTresc
   LOCAL nBajtow

   nDlugosc := Asc( SubStr( cDer, nPoz + 1, 1 ) )
   nTresc   := nPoz + 2
   IF nDlugosc > 127
      nBajtow  := nDlugosc - 128
      nDlugosc := 0
      DO WHILE nBajtow > 0
         nDlugosc := nDlugosc * 256 + Asc( SubStr( cDer, nTresc, 1 ) )
         nTresc++
         nBajtow--
      ENDDO
   ENDIF

RETURN { Asc( SubStr( cDer, nPoz, 1 ) ), nTresc, nDlugosc }

STATIC FUNCTION s_NumerZDer( cDer )

   LOCAL aElement

   aElement := s_Der( cDer, 1 )
   aElement := s_Der( cDer, aElement[ 2 ] )
   aElement := s_Der( cDer, aElement[ 2 ] )
   IF aElement[ 1 ] == 0xA0
      aElement := s_Der( cDer, aElement[ 2 ] + aElement[ 3 ] )
   ENDIF
   IF aElement[ 1 ] != 0x02
      RETURN ""
   ENDIF

RETURN Upper( StrToHex( SubStr( cDer, aElement[ 2 ], aElement[ 3 ] ) ) )

STATIC FUNCTION s_TypZDer( cDer )

   LOCAL nPoz
   LOCAL nUzycie

   nPoz := At( Chr( 0x06 ) + Chr( 0x03 ) + Chr( 0x55 ) + Chr( 0x1D ) + Chr( 0x0F ), cDer )
   IF nPoz == 0
      RETURN ""
   ENDIF
   nPoz += 5
   IF Asc( SubStr( cDer, nPoz, 1 ) ) == 0x01
      nPoz += 2 + Asc( SubStr( cDer, nPoz + 1, 1 ) )
   ENDIF
   IF Asc( SubStr( cDer, nPoz, 1 ) ) != 0x04 .OR. Asc( SubStr( cDer, nPoz + 2, 1 ) ) != 0x03
      RETURN ""
   ENDIF
   nUzycie := Asc( SubStr( cDer, nPoz + 5, 1 ) )

   DO CASE
   CASE nUzycie >= 0x80
      RETURN "Authentication"
   CASE nUzycie >= 0x40
      RETURN "Offline"
   ENDCASE

RETURN ""

STATIC PROCEDURE s_Aplikacja()

   LOCAL cNip        := ""
   LOCAL nSrodowisko := 1
   LOCAL cAdres

   p_FirmaPobierzKsef( @cNip, @nSrodowisko )
   DO CASE
   CASE nSrodowisko == 3
      cAdres := "https://ap.ksef.mf.gov.pl"
   OTHERWISE
      cAdres := "https://ap-test.ksef.mf.gov.pl"
   ENDCASE
   IF ! gui_OpenFile( cAdres )
      gui_MsgInfo( "Otwórz w przeglądarce:" + Eol() + cAdres, "Certyfikaty" )
   ENDIF

RETURN

STATIC PROCEDURE s_Usun( oDialog )

   IF CERTYFIKATY->( Eof() )
      RETURN
   ENDIF

   IF gui_MsgYesNo( "Czy na pewno usunąć certyfikat" + Eol() + AllTrim( CERTYFIKATY->NAZWA ) + "?" + Eol() + Eol() + ;
                    "Zaszyfrowany klucz prywatny zostanie usunięty z xFaktury." + Eol() + ;
                    "Zachowaj pliki .crt i .key, jeśli certyfikat jest jeszcze potrzebny.", "Certyfikaty" )
      dbSelectArea( "CERTYFIKATY" )
      IF NetRLock()
         dbDelete()
         dbCommit()
         dbUnlock()
         dbSkip()
         IF Eof()
            dbGoBottom()
         ENDIF
      ENDIF
      oDialog:BRW:Refresh()
      s_Okno( oDialog )
   ENDIF

RETURN

STATIC FUNCTION s_Klucz()
RETURN HashData( "SHA256", "xFaktura - certyfikat KSeF" )

STATIC FUNCTION s_Zaszyfruj( cDane )

   LOCAL cIv

   cIv := RandomBytes( 16 )

RETURN Base64Encode( cIv + AesEncrypt( s_Klucz(), cIv, cDane ) )

STATIC FUNCTION s_Odszyfruj( cZapis )

   LOCAL cDane
   LOCAL cWynik

   cDane := Base64Decode( AllTrim( cZapis ) )
   IF Len( cDane ) <= 16
      RETURN ""
   ENDIF
   cWynik := AesDecrypt( s_Klucz(), Left( cDane, 16 ), SubStr( cDane, 17 ) )

RETURN IIF( cWynik == NIL, "", cWynik )
