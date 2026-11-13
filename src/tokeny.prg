/*
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: tokeny.prg
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

PROCEDURE p_Tokeny( oWindow )

   LOCAL oDialog
   LOCAL oToolbar
   LOCAL oPanel
   LOCAL oBrowse
   LOCAL oStatus
   LOCAL aZamroz := {}

   IF ! s_DbOpen()
      RETURN
   ENDIF

   oDialog := gui_Dialog():New( oWindow, "Lista tokenów KSeF", 900, 600 )
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
   oToolbar:Add( "F2-Dodaj",    NIL, {|| s_Dodaj( oDialog, oPanel ), s_Stan( oDialog, aZamroz ) }, NIL, "F2" )
   oToolbar:AddSeparator()
   oToolbar:Add( "F3-Aplikacja KSeF", NIL, {|| s_Aplikacja() }, NIL, "F3" )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F5-Sprawdź",  NIL, {|| s_Sprawdz( oDialog ) }, NIL, "F5" ) )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F8-Usuń",     NIL, {|| s_Usun( oDialog ), s_Stan( oDialog, aZamroz ) }, NIL, "F8" ) )
   oToolbar:AddSeparator()
   oToolbar:Add( "Esc-Zamknij", NIL, {|| oDialog:Close() },      NIL, "Esc" )

   oPanel := gui_Panel():New( oDialog )

   s_Opis( oPanel,  13, "Nazwa tokenu:" )
   s_Opis( oPanel,  43, "Token:" )
   s_Opis( oPanel,  73, "NIP / środowisko:" )
   s_Opis( oPanel, 103, "Sprawdzenie:" )

   s_Pole( oPanel, 175,  10, 60, "NAZWA" )
   s_Pole( oPanel, 175,  40, 60, "TOKEN" )
   s_Pole( oPanel, 175,  70, 20, "NIP" )
   s_Pole( oPanel, 373,  70, 38, "SRODOWISK" )
   s_Pole( oPanel, 175, 100, 60, "STATUS" )

   oBrowse := gui_Browse():New( oPanel, 10, 140, oPanel:width - 20, oPanel:height - 150 )
   oBrowse:name             := "BRW"
   oBrowse:headerBackground := 0x4d7326
   oBrowse:anchor           := "LTRB"
   oBrowse:goTopBlock       := {|| TOKENY->( dbGoTop() ) }
   oBrowse:goBottomBlock    := {|| TOKENY->( dbGoBottom() ) }
   oBrowse:skipBlock        := {| n | TOKENY->( DbSkipper( n ) ) }
   oBrowse:positionBlock    := {|| TOKENY->( IIF( LastRec() > 0, RecNo() / LastRec(), 0 ) ) }
   oBrowse:emptyBlock       := {|| s_Pusta() }
   oBrowse:AddColumn( "Poz.",                     {|| TOKENY->( RecNo() ) }, 4 )
   oBrowse:AddColumn( PadR( "Nazwa tokenu", 40 ), {|| TOKENY->NAZWA }, 40 )
   oBrowse:AddColumn( PadC( "NIP", 12 ),          {|| Left( TOKENY->NIP, 12 ) } )
   oBrowse:AddColumn( "Środowisko",               {|| s_Srodowisko( TOKENY->KSEF_SROD ) } )
   oBrowse:AddColumn( "Dodany",                   {|| TOKENY->D_DODANIA } )
   oBrowse:AddColumn( "Sprawdzony",               {|| IIF( Empty( TOKENY->D_SPRAWDZ ), Space( 10 ), DToC( TOKENY->D_SPRAWDZ ) ) } )
   oBrowse:OnChange := {|| s_Okno( oDialog ) }

   TOKENY->( dbGoTop() )
   s_Okno( oDialog )
   s_Stan( oDialog, aZamroz )

   oDialog:Center()
   oDialog:ShowModal()

   TOKENY->( dbCloseArea() )

RETURN

/* ---------------------------------------------------------------------------------------------
   Baza
   --------------------------------------------------------------------------------------------- */

STATIC FUNCTION s_Struct()
RETURN { ;
   { "NAZWA",          "C",  60, 0 }, ;
   { "NIP",            "C",  20, 0 }, ;
   { "KSEF_SROD",      "N",   1, 0 }, ;
   { "SZYFR",          "M",  10, 0 }, ;
   { "D_DODANIA",      "D",   8, 0 }, ;
   { "D_SPRAWDZ",      "D",   8, 0 }, ;
   { "WYNIK",          "C", 100, 0 } }

STATIC FUNCTION s_DbOpen()

   LOCAL cBaza

   cBaza := "ksef" + DirSepToOS( "\" ) + "tokeny"
   IF ! FileExists( cBaza + ".dbf" )
      dbCreate( cBaza, s_Struct() )
   ENDIF

   dbSelectArea( 0 )
   IF ! NetUse( cBaza, .F., NIL, "TOKENY" )
      RETURN .F.
   ENDIF

   IF ! s_Okay()
      TOKENY->( dbCloseArea() )
      gui_MsgInfo( "Zmiana struktury bazy tokenów", "Tokeny" )
      s_Rekonstrukcja()
      dbSelectArea( 0 )
      IF ! NetUse( cBaza, .F., NIL, "TOKENY" )
         RETURN .F.
      ENDIF
      IF ! s_Okay()
         TOKENY->( dbCloseArea() )
         RETURN .F.
      ENDIF
   ENDIF

RETURN .T.

STATIC FUNCTION s_Okay()

   LOCAL aWzor
   LOCAL aBaza
   LOCAL nPole

   aWzor := s_Struct()
   aBaza := TOKENY->( dbStruct() )
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

   cBaza := "ksef" + DirSepToOS( "\" ) + "tokeny"
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
   IF ! NetUse( cBaza, .T., NIL, "TOKENY" )
      FErase( cBaza + ".dbf" )
      FErase( cBaza + cExt )
      FRename( cTmp, cBaza + ".dbf" )
      FRename( cMemo, cBaza + cStary )
      RETURN
   ENDIF
   TOKENY->( DbAppendFrom( cTmp ) )
   TOKENY->( dbCloseArea() )
   FErase( cTmp )
   FErase( cMemo )

RETURN

FUNCTION p_TokenyPobierz( cNipFirmy, nSrodowiskoKsef )

   LOCAL cToken

   cToken := ""
   IF ! s_DbOpen()
      RETURN ""
   ENDIF
   TOKENY->( dbGoBottom() )
   DO WHILE ! TOKENY->( Bof() ) .AND. ! TOKENY->( Eof() )
      IF AllTrim( TOKENY->NIP ) == AllTrim( cNipFirmy ) .AND. TOKENY->KSEF_SROD == nSrodowiskoKsef
         cToken := s_Odszyfruj( TOKENY->SZYFR )
         EXIT
      ENDIF
      TOKENY->( dbSkip( -1 ) )
   ENDDO
   TOKENY->( dbCloseArea() )

RETURN cToken

/* ---------------------------------------------------------------------------------------------
   Indexy
   --------------------------------------------------------------------------------------------- */

PROCEDURE p_TokenyNtx()

   LOCAL cBaza

   cBaza := "ksef" + DirSepToOS( "\" ) + "tokeny"
   IF FileExists( cBaza + ".dbf" )

      dbSelectArea( 0 )
      IF NetUse( cBaza, .T., NIL, "TOKENY" )
         NetPack()
         TOKENY->( dbCloseArea() )
      ENDIF

   ENDIF

RETURN

STATIC FUNCTION s_Pusta()

   LOCAL nRecNo := TOKENY->( RecNo() )
   LOCAL lPusta

   TOKENY->( dbGoTop() )
   lPusta := TOKENY->( Eof() )
   TOKENY->( dbGoto( nRecNo ) )

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

STATIC PROCEDURE s_Opis( oPanel, nY, cText )

   gui_Say():New( oPanel, 20, nY, 15, 20, cText )

RETURN

STATIC PROCEDURE s_Pole( oPanel, nX, nY, nLen, cName )

   LOCAL oSay

   oSay := gui_Say():New( oPanel, nX, nY, nLen, 24 )
   oSay:name   := cName
   oSay:border := .T.

RETURN

STATIC PROCEDURE s_Pomoc( oWindow )

   p_Pomoc( oWindow, "Lista tokenów KSeF", ;
      Eol() + ;
      "Token KSeF to klucz, którym xFaktura loguje się do KSeF." + Eol() + ;
      "Generuje się go w Aplikacji Podatnika KSeF, w zakładce Tokeny," + Eol() + ;
      "dla NIP-u firmy z Pliki - Ustawienia - Firma i w jej środowisku." + Eol() + ;
      Eol() + ;
      "F1             pomoc" + Eol() + ;
      "F2, Ins        nowy token: nazwa i token wklejony z Aplikacji Podatnika" + Eol() + ;
      "F3             Aplikacja Podatnika KSeF w przeglądarce (środowisko firmy)" + Eol() + ;
      "F5             sprawdzenie połączenia z KSeF tym tokenem" + Eol() + ;
      "F8             usunięcie tokenu" + Eol() + ;
      "Strzałki       poprzedni / następny token" + Eol() + ;
      "Esc            zamknięcie okna" + Eol() + ;
      Eol() + ;
      "Wpisywanie danych" + Eol() + ;
      Eol() + ;
      "Ctrl+V         wklejenie tokenu" + Eol() + ;
      "Enter          następne pole, na ostatnim zapis" + Eol() + ;
      "PgUp, PgDn     zapis" + Eol() + ;
      "Esc            bez zapisu" + Eol() + ;
      Eol() + ;
      "Token jest zapisany w bazie zaszyfrowany i na ekranie widać tylko jego początek." )

RETURN

STATIC PROCEDURE s_Okno( oDialog )

   LOCAL cToken

   cToken := IIF( TOKENY->( Eof() ), "", s_Odszyfruj( TOKENY->SZYFR ) )
   oDialog:NAZWA:text     := TOKENY->NAZWA
   oDialog:TOKEN:text     := IIF( Empty( cToken ), "", Left( cToken, 24 ) + "…" )
   oDialog:NIP:text       := TOKENY->NIP
   oDialog:SRODOWISK:text := IIF( TOKENY->( Eof() ), "", s_Srodowisko( TOKENY->KSEF_SROD, .T. ) )
   oDialog:STATUS:text    := TOKENY->WYNIK

RETURN

STATIC FUNCTION s_Srodowisko( nSrodowiskoKsef, lPelna )

   DO CASE
   CASE nSrodowiskoKsef == 3
      RETURN IIF( lPelna == .T., "Produkcyjne (prawdziwe faktury)", "Produkcyjne" )
   ENDCASE

RETURN IIF( lPelna == .T., "Testowe (próbny, do testów)", "Testowe" )

STATIC PROCEDURE s_Dodaj( oDialog, oPanel )

   LOCAL GetList
   LOCAL nRecNo
   LOCAL cNazwaTokenu
   LOCAL cToken
   LOCAL cNipFirmy
   LOCAL nSrodowiskoKsef
   LOCAL nGet

   GetList         := {}
   nRecNo          := TOKENY->( RecNo() )
   cNazwaTokenu    := Space( Len( TOKENY->NAZWA ) )
   cToken          := Space( 512 )
   cNipFirmy       := ""
   nSrodowiskoKsef := 1
   IF ! p_FirmaPobierzKsef( @cNipFirmy, @nSrodowiskoKsef ) .OR. Empty( cNipFirmy )
      gui_MsgInfo( "Najpierw wpisz NIP firmy w Pliki - Ustawienia - Firma.", "Tokeny" )
      RETURN
   ENDIF

   TOKENY->( dbGoBottom() )
   TOKENY->( dbSkip() )
   s_Okno( oDialog )
   oDialog:NIP:text       := cNipFirmy
   oDialog:SRODOWISK:text := s_Srodowisko( nSrodowiskoKsef, .T. )

   AAdd( GetList, gui_Get():New( oPanel, 175, 10, 60, NIL, @cNazwaTokenu ) )
   AAdd( GetList, gui_Get():New( oPanel, 175, 40, 60, NIL, @cToken ) )

   oDialog:STATUS_BAR:text := " Tryb edycji --> PgUp PgDn Enter = zapisz, Esc = bez zapisu"
   oDialog:STATUS_BAR:background := 0x73264d
   oDialog:STATUS_BAR:foreground := 0xffffff

   oDialog:ReadModal( GetList )

   oDialog:STATUS_BAR:text       := ""
   oDialog:STATUS_BAR:background := NIL
   oDialog:STATUS_BAR:foreground := NIL

   FOR nGet := 1 TO Len( GetList )
      GetList[ nGet ]:Destroy()
   NEXT

   IF LastKey() == K_ESC .OR. Empty( cToken )
      TOKENY->( dbGoto( nRecNo ) )
      s_Okno( oDialog )
      RETURN
   ENDIF

   dbSelectArea( "TOKENY" )
   IF ! NetAppBlank()
      TOKENY->( dbGoto( nRecNo ) )
      s_Okno( oDialog )
      RETURN
   ENDIF
   TOKENY->NAZWA    := IIF( Empty( cNazwaTokenu ), "Token " + DToC( Date() ), cNazwaTokenu )
   TOKENY->NIP       := cNipFirmy
   TOKENY->KSEF_SROD := nSrodowiskoKsef
   TOKENY->SZYFR     := s_Zaszyfruj( AllTrim( cToken ) )
   TOKENY->D_DODANIA    := Date()
   dbCommit()
   dbUnlock()

   oDialog:BRW:Refresh()
   s_Okno( oDialog )

RETURN

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
      gui_MsgInfo( "Otwórz w przeglądarce:" + Eol() + cAdres, "Tokeny" )
   ENDIF

RETURN

STATIC PROCEDURE s_Sprawdz( oDialog )

   LOCAL cBlad
   LOCAL hOdp
   LOCAL cWynikSprawdzenia

   cBlad := ""
   IF TOKENY->( Eof() )
      RETURN
   ENDIF

   oDialog:STATUS_BAR:text := " Łączenie z KSeF (" + s_Srodowisko( TOKENY->KSEF_SROD ) + ")..."
   hOdp := p_KsefZaloguj( TOKENY->NIP, s_Odszyfruj( TOKENY->SZYFR ), TOKENY->KSEF_SROD, @cBlad )
   oDialog:STATUS_BAR:text := ""

   IF hOdp == NIL
      cWynikSprawdzenia := "Błąd: " + StrTran( cBlad, Eol(), " " )
      gui_MsgError( cBlad, "Połączenie z KSeF" )
   ELSE
      cWynikSprawdzenia := "Połączono, bilet ważny do " + hOdp[ "accessToken" ][ "validUntil" ]
      gui_MsgInfo( "Połączono z KSeF (" + s_Srodowisko( TOKENY->KSEF_SROD ) + ")." + Eol() + ;
                   "Bilet dostępu ważny do: " + hOdp[ "accessToken" ][ "validUntil" ], "Połączenie z KSeF" )
   ENDIF

   dbSelectArea( "TOKENY" )
   IF NetRLock()
      TOKENY->D_SPRAWDZ  := Date()
      TOKENY->WYNIK := cWynikSprawdzenia
      dbCommit()
      dbUnlock()
   ENDIF
   oDialog:BRW:Refresh()
   s_Okno( oDialog )

RETURN

STATIC PROCEDURE s_Usun( oDialog )

   IF TOKENY->( Eof() )
      RETURN
   ENDIF

   IF gui_MsgYesNo( "Czy na pewno usunąć token" + Eol() + AllTrim( TOKENY->NAZWA ) + "?", "Tokeny" )
      dbSelectArea( "TOKENY" )
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
RETURN HashData( "SHA256", "xFaktura - token KSeF" )

STATIC FUNCTION s_Zaszyfruj( cToken )

   LOCAL cIv

   cIv := RandomBytes( 16 )

RETURN Base64Encode( cIv + AesEncrypt( s_Klucz(), cIv, cToken ) )

STATIC FUNCTION s_Odszyfruj( cZapis )

   LOCAL cDane
   LOCAL cToken

   cDane := Base64Decode( AllTrim( cZapis ) )
   IF Len( cDane ) <= 16
      RETURN ""
   ENDIF
   cToken := AesDecrypt( s_Klucz(), Left( cDane, 16 ), SubStr( cDane, 17 ) )

RETURN IIF( cToken == NIL, "", cToken )
