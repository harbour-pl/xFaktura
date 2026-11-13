/*
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: faktury.prg
 *
 * Copyright (c) 2026 xDev-Language
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "dbinfo.ch"
#include "hpdf.ch"
#include "xfaktura.ch"

PROCEDURE p_Faktury( oWindow )

   LOCAL oDialog
   LOCAL oStatus
   LOCAL oToolbar
   LOCAL oPanel
   LOCAL oBrowse
   LOCAL aZamroz := {}

   IF ! p_FakturyOtworz()
      RETURN
   ENDIF

   oDialog := gui_Dialog():New( oWindow, "Faktury VAT " + Left( p_RokPobierz(), 4 ), 1000, 700 )
   oDialog:background := 0xe9edf1
   oDialog:sizable := .T.
   oDialog:SetKey( "Ins", {|| p_FakturaVat( oDialog ), s_Stan( oDialog, aZamroz ) } )

   oStatus := gui_StatusBar():New( oDialog )
   oStatus:name := "STATUS_BAR"
   oStatus:font := gui_Font():New( NIL, .F., .F., "xFont 9x18" )
   oStatus:Add( 0 )

   oToolbar := gui_Toolbar():New( oDialog, "Bottom" )
   oToolbar:name := "PASEK"
   oToolbar:Add( "F1-Pomoc",    NIL, {|| s_Pomoc( oDialog ) }, NIL, "F1" )
   oToolbar:AddSeparator()
   oToolbar:Add( "F2-Nowa",     NIL, {|| p_FakturaVat( oDialog ), s_Stan( oDialog, aZamroz ) }, NIL, "F2" )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F3-Podgląd",  NIL, {|| s_Podglad( oDialog ) }, NIL, "F3" ) )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F6-Wyślij do KSeF", NIL, {|| s_Wyslij( oDialog ) }, NIL, "F6" ) )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F9-Drukuj",   NIL, {|| s_Drukuj() }, NIL, "F9" ) )
   oToolbar:AddSeparator()
   oToolbar:Add( "Esc", NIL, {|| oDialog:Close() }, NIL, "Esc" )

   oPanel := gui_Panel():New( oDialog )

   oBrowse := gui_Browse():New( oPanel, 10, 10, oPanel:width - 20, oPanel:height - 20 )
   oBrowse:name             := "BRW"
   oBrowse:headerBackground := 0x4d7326
   oBrowse:anchor           := "LTRB"
   oBrowse:goTopBlock       := {|| FKTHEAD->( dbGoTop() ) }
   oBrowse:goBottomBlock    := {|| FKTHEAD->( dbGoBottom() ) }
   oBrowse:skipBlock        := {| n | FKTHEAD->( DbSkipper( n ) ) }
   oBrowse:positionBlock    := {|| FKTHEAD->( IIF( LastRec() > 0, RecNo() / LastRec(), 0 ) ) }
   oBrowse:emptyBlock       := {|| FKTHEAD->( LastRec() ) == 0 }
   oBrowse:AddColumn( "W KSeF",                   {|| IIF( FKTHEAD->KSEF_STAT == 2, "Tak", "Nie" ) } )
   oBrowse:AddColumn( "Poz.",                     {|| FKTHEAD->( RecNo() ) }, 4 )
   oBrowse:AddColumn( PadR( "Numer", 14 ),        {|| Left( FKTHEAD->NUMER_FKT, 14 ) } )
   oBrowse:AddColumn( "Wystawiona",               {|| FKTHEAD->D_WYSTAWIE } )
   oBrowse:AddColumn( PadC( "NIP nabywcy", 12 ),  {|| Left( FKTHEAD->NIP_ODBIOR, 12 ) } )
   oBrowse:AddColumn( PadR( "Nabywca", 34 ),      {|| StrTran( FKTHEAD->NAZWA___OD, Eol( FKTHEAD->NAZWA___OD ), " " ) }, 34 )
   oBrowse:AddColumn( PadL( "Netto", 12 ),        {|| FKTHEAD->NETTO__FKT } )
   oBrowse:AddColumn( PadL( "VAT", 12 ),          {|| FKTHEAD->KWOTA__VAT } )
   oBrowse:AddColumn( PadL( "Brutto", 12 ),       {|| FKTHEAD->BRUTTO_FKT } )

   FKTHEAD->( dbGoBottom() )
   s_Stan( oDialog, aZamroz )

   oDialog:Center()
   oDialog:ShowModal()

   FKTROW->( dbCloseArea() )
   FKTHEAD->( dbCloseArea() )

RETURN

/* ---------------------------------------------------------------------------------------------
   Baza
   --------------------------------------------------------------------------------------------- */

STATIC FUNCTION s_Struct()
RETURN { ;
   { "NR_FAKTURY",     "N",   6, 0 }, ;
   { "RODZAJ",         "C",   3, 0 }, ;
   { "NUMER_FKT",      "C",  30, 0 }, ;
   { "D_WYSTAWIE",     "D",   8, 0 }, ;
   { "D_SPRZEDAZ",     "D",   8, 0 }, ;
   { "KODKRAJ_OD",     "C",   2, 0 }, ;
   { "NIP_ODBIOR",     "C",  20, 0 }, ;
   { "NAZWA___OD",     "M",  10, 0 }, ;
   { "KODPOCZ_OD",     "C",   6, 0 }, ;
   { "MIEJSCE_OD",     "C",  40, 0 }, ;
   { "ULICA___OD",     "C",  60, 0 }, ;
   { "FORMA_PLAT",     "N",   1, 0 }, ;
   { "TERMIN_PLA",     "D",   8, 0 }, ;
   { "BANK____OD",     "C",  60, 0 }, ;
   { "KONTO___OD",     "C",  34, 0 }, ;
   { "ODEBRAL_OD",     "C",  30, 0 }, ;
   { "UWAGI___OD",     "C", 200, 0 }, ;
   { "ZWOLNIENIE",     "C", 200, 0 }, ;
   { "NETTO__FKT",     "N",  12, 2 }, ;
   { "KWOTA__VAT",     "N",  12, 2 }, ;
   { "BRUTTO_FKT",     "N",  12, 2 }, ;
   { "KSEF_NR",        "C",  40, 0 }, ;
   { "KSEF_STAT",      "N",   1, 0 }, ;
   { "KSEF_DATA",      "C",  30, 0 }, ;
   { "KSEF_OPIS",      "C", 200, 0 }, ;
   { "DATA_____P",     "D",   8, 0 } }

FUNCTION p_PozycjeStruct()
RETURN { ;
   { "NR_FAKTURY",     "N",   6, 0 }, ;
   { "RODZAJ",         "C",   3, 0 }, ;
   { "LP_FKT_ROW",     "N",   4, 0 }, ;
   { "KOD_TOWARU",     "C",  10, 0 }, ;
   { "NAZWA_TOWA",     "C", 250, 0 }, ;
   { "JM_____FKT",     "C",  10, 0 }, ;
   { "ILOSC__FKT",     "N",  12, 3 }, ;
   { "CENA_JEDNO",     "N",  12, 2 }, ;
   { "WART_NETTO",     "N",  12, 2 }, ;
   { "STAWKA_VAT",     "C",   5, 0 }, ;
   { "KWOTA__VAT",     "N",  12, 2 }, ;
   { "WAR_BRUTTO",     "N",  12, 2 }, ;
   { "DATA_____P",     "D",   8, 0 } }

FUNCTION p_FakturyOtworz()

   LOCAL cGlowa   := p_RokPobierz() + "fkthead"
   LOCAL cPozycje := p_RokPobierz() + "fktrow"

   IF ! s_DbOpen( cGlowa, s_Struct(), "FKTHEAD" )
      RETURN .F.
   ENDIF
   IF ! s_DbOpen( cPozycje, p_PozycjeStruct(), "FKTROW" )
      FKTHEAD->( dbCloseArea() )
      RETURN .F.
   ENDIF
   IF ! s_Indeks()
      IF Select( "FKTROW" ) > 0
         FKTROW->( dbCloseArea() )
      ENDIF
      FKTHEAD->( dbCloseArea() )
      RETURN .F.
   ENDIF

RETURN .T.

STATIC FUNCTION s_DbOpen( cBaza, aWzor, cAlias )

   IF ! FileExists( cBaza + ".dbf" )
      dbCreate( cBaza, aWzor )
   ENDIF

   dbSelectArea( 0 )
   IF ! NetUse( cBaza, .F., NIL, cAlias )
      RETURN .F.
   ENDIF

   IF ! s_Okay( cAlias, aWzor )
      ( cAlias )->( dbCloseArea() )
      gui_MsgInfo( "Zmiana struktury bazy faktur", "Faktury" )
      s_Rekonstrukcja( cBaza, aWzor, cAlias )
      FErase( p_RokPobierz() + "fktrow1.ntx" )
      dbSelectArea( 0 )
      IF ! NetUse( cBaza, .F., NIL, cAlias )
         RETURN .F.
      ENDIF
   ENDIF

RETURN .T.

STATIC FUNCTION s_Okay( cAlias, aWzor )

   LOCAL aBaza := ( cAlias )->( dbStruct() )
   LOCAL nPole

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

STATIC PROCEDURE s_Rekonstrukcja( cBaza, aWzor, cAlias )

   LOCAL cTmp   := p_RokPobierz() + "tmp.dbf"
   LOCAL cExt   := RddInfo( RDDI_MEMOEXT )
   LOCAL cStary := IIF( FileExists( cBaza + ".fpt" ), ".fpt", cExt )
   LOCAL cMemo  := p_RokPobierz() + "tmp" + cStary

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

   dbCreate( cBaza, aWzor )

   IF ! FileExists( cBaza + ".dbf" )
      FRename( cTmp, cBaza + ".dbf" )
      FRename( cMemo, cBaza + cStary )
      RETURN
   ENDIF

   dbSelectArea( 0 )
   NetUse( cBaza, .T., NIL, cAlias )
   ( cAlias )->( DbAppendFrom( cTmp ) )
   ( cAlias )->( dbCloseArea() )
   FErase( cTmp )
   FErase( cMemo )

RETURN

/* ---------------------------------------------------------------------------------------------
   Indexy
   --------------------------------------------------------------------------------------------- */

PROCEDURE p_FakturyNtx()

   LOCAL cBaza

   FOR EACH cBaza IN { "fkthead", "fktrow" }
      IF FileExists( p_RokPobierz() + cBaza + ".dbf" )
         dbSelectArea( 0 )
         IF NetUse( p_RokPobierz() + cBaza, .T., NIL, Upper( cBaza ) )
            NetPack()
            ( Upper( cBaza ) )->( dbCloseArea() )
         ENDIF
      ENDIF
   NEXT
   FErase( p_RokPobierz() + "fktrow1.ntx" )

RETURN

STATIC FUNCTION s_Indeks()

   LOCAL cBaza   := p_RokPobierz() + "fktrow"
   LOCAL cIndeks := p_RokPobierz() + "fktrow1"

   LOCAL cKlucz  := "RODZAJ + Str( NR_FAKTURY, 6 )"
   LOCAL bKlucz  := {|| FKTROW->RODZAJ + Str( FKTROW->NR_FAKTURY, 6 ) }

   IF FileExists( cIndeks + ".ntx" )
      IF s_PodlaczIndeks( cIndeks, cKlucz, bKlucz )
         RETURN .T.
      ENDIF
   ENDIF

   FKTROW->( dbCloseArea() )
   dbSelectArea( 0 )
   IF ! NetUse( cBaza, .T., NIL, "FKTROW" )
      RETURN .F.
   ENDIF
   FKTROW->( dbCreateIndex( cIndeks, cKlucz, bKlucz ) )
   FKTROW->( dbCloseArea() )
   dbSelectArea( 0 )
   IF ! NetUse( cBaza, .F., NIL, "FKTROW" )
      RETURN .F.
   ENDIF

RETURN s_PodlaczIndeks( cIndeks, cKlucz, bKlucz )

STATIC FUNCTION s_PodlaczIndeks( cIndeks, cKlucz, bKlucz )

   LOCAL lOkay := .F.
   LOCAL bBlad := ErrorBlock( {| oBlad | Break( oBlad ) } )

   BEGIN SEQUENCE
      FKTROW->( dbSetIndex( cIndeks, { { NIL, cKlucz, bKlucz, NIL, NIL } } ) )
      lOkay := .T.
   RECOVER
      lOkay := .F.
   END SEQUENCE
   ErrorBlock( bBlad )

RETURN lOkay

STATIC PROCEDURE s_Stan( oDialog, aZamroz )

   LOCAL lJest := FKTHEAD->( LastRec() ) > 0

   AEval( aZamroz, {| nPrzycisk | oDialog:PASEK:Enable( nPrzycisk, lJest ) } )
   oDialog:BRW:enabled := lJest
   oDialog:BRW:Refresh()

   IF lJest
      oDialog:BRW:SetFocus()
   ENDIF

RETURN

STATIC PROCEDURE s_Opis( oPanel, nX, nY, nLen, cText )

   gui_Say():New( oPanel, nX, nY, nLen, 20, cText )

RETURN

STATIC PROCEDURE s_Pole( oPanel, nX, nY, nLen, cText, cAnchor )

   LOCAL oSay := gui_Say():New( oPanel, nX, nY, nLen, 24, cText )

   oSay:border := .T.
   IF cAnchor != NIL
      oSay:anchor := cAnchor
   ENDIF

RETURN

STATIC PROCEDURE s_Pomoc( oWindow )

   p_Pomoc( oWindow, "Lista faktur", ;
      Eol() + ;
      "F1             pomoc" + Eol() + ;
      "F2, Ins        nowa faktura VAT" + Eol() + ;
      "F3             podgląd faktury: nabywca, pozycje, sumy, KSeF" + Eol() + ;
      "F6             wysłanie faktury do KSeF tokenem z listy tokenów;" + Eol() + ;
      "               kopia XML zostaje w katalogu roku\xml" + Eol() + ;
      "F9             wydruk faktury do PDF w katalogu roku\wydruki" + Eol() + ;
      "Strzałki       poprzednia / następna faktura" + Eol() + ;
      "Esc            zamknięcie okna" )

RETURN

STATIC PROCEDURE s_Podglad( oWindow )

   LOCAL cKlucz := FKTHEAD->RODZAJ + Str( FKTHEAD->NR_FAKTURY, 6 )
   LOCAL aPoz   := {}
   LOCAL nPoz   := 1
   LOCAL nStary
   LOCAL oDialog
   LOCAL oToolbar
   LOCAL oPanel
   LOCAL oBrowse
   LOCAL oPlat
   LOCAL oLinia

   IF FKTHEAD->( Eof() )
      RETURN
   ENDIF
   FKTROW->( dbSeek( cKlucz ) )
   DO WHILE ! FKTROW->( Eof() ) .AND. FKTROW->RODZAJ + Str( FKTROW->NR_FAKTURY, 6 ) == cKlucz
      AAdd( aPoz, { FKTROW->LP_FKT_ROW, AllTrim( FKTROW->NAZWA_TOWA ), FKTROW->ILOSC__FKT, AllTrim( FKTROW->JM_____FKT ), ;
                    FKTROW->CENA_JEDNO, FKTROW->WART_NETTO, AllTrim( FKTROW->STAWKA_VAT ), FKTROW->KWOTA__VAT, FKTROW->WAR_BRUTTO } )
      FKTROW->( dbSkip() )
   ENDDO

   oDialog := gui_Dialog():New( oWindow, "Podgląd faktury " + AllTrim( FKTHEAD->NUMER_FKT ), 1000, 700 )
   oDialog:background := 0xe9edf1
   oDialog:sizable := .T.

   oToolbar := gui_Toolbar():New( oDialog, "Bottom" )
   oToolbar:Add( "Esc", NIL, {|| oDialog:Close() }, NIL, "Esc" )
   oToolbar:AddSeparator()

   oPanel := gui_Panel():New( oDialog )

   s_Opis( oPanel, 20,   7, 14, "Numer faktury:" )
   s_Opis( oPanel, 20,  37, 14, "Data wystawienia:" )
   s_Opis( oPanel, 20,  67, 14, "Data sprzedaży:" )
   s_Opis( oPanel, 20,  97, 14, "Płatność:" )
   s_Opis( oPanel, 20, 127, 14, "Data płatności:" )
   s_Pole( oPanel, 160,   4, 14, AllTrim( FKTHEAD->NUMER_FKT ) )
   s_Pole( oPanel, 160,  34, 10, DToC( FKTHEAD->D_WYSTAWIE ) )
   s_Pole( oPanel, 160,  64, 10, DToC( FKTHEAD->D_SPRZEDAZ ) )
   s_Pole( oPanel, 160, 124, 10, IIF( Empty( FKTHEAD->TERMIN_PLA ), "", DToC( FKTHEAD->TERMIN_PLA ) ) )

   oPlat := gui_RadioButton():New( oPanel, 160, 96, 90, 20, "Gotówka" )
   oPlat:value   := FKTHEAD->FORMA_PLAT == 1
   oPlat:enabled := .F.
   oPlat := gui_RadioButton():New( oPanel, 255, 96, 80, 20, "Karta" )
   oPlat:value   := FKTHEAD->FORMA_PLAT == 2
   oPlat:enabled := .F.
   oPlat := gui_RadioButton():New( oPanel, 340, 96, 90, 20, "Przelew" )
   oPlat:value   := FKTHEAD->FORMA_PLAT == 6
   oPlat:enabled := .F.

   gui_Panel():New( oPanel, 445, 4, 1, 144 ):background := 0xa0a0a0

   s_Opis( oPanel, 460,  7, 14, "Kod kraju / NIP:" )
   s_Opis( oPanel, 460, 37, 14, "Nazwa kontrahenta:" )
   s_Opis( oPanel, 460, 67, 14, "Ulica:" )
   s_Opis( oPanel, 460, 97, 14, "Kod / Miejscowość:" )
   s_Pole( oPanel, 600,  4,  2, FKTHEAD->KODKRAJ_OD )
   s_Pole( oPanel, 636,  4, 20, FKTHEAD->NIP_ODBIOR )
   s_Pole( oPanel, 600, 34, 40, StrTran( FKTHEAD->NAZWA___OD, Eol( FKTHEAD->NAZWA___OD ), " " ) )
   s_Pole( oPanel, 600, 64, 40, FKTHEAD->ULICA___OD )
   s_Pole( oPanel, 600, 94,  6, FKTHEAD->KODPOCZ_OD )
   s_Pole( oPanel, 672, 94, 32, FKTHEAD->MIEJSCE_OD )

   oLinia := gui_Panel():New( oPanel, 10, 156, oPanel:width - 20, 1 )
   oLinia:background := 0xa0a0a0
   oLinia:anchor     := "LTR"

   s_Opis( oPanel, 20, 169, 14, "Numer KSeF:" )
   s_Pole( oPanel, 160, 166, 50, IIF( FKTHEAD->KSEF_STAT == 2, AllTrim( FKTHEAD->KSEF_NR ), "nie wysłana" ) )

   oBrowse := gui_Browse():New( oPanel, 10, 200, oPanel:width - 20, oPanel:height - 244 )
   oBrowse:headerBackground := 0x4d7326
   oBrowse:anchor           := "LTRB"
   oBrowse:goTopBlock       := {|| nPoz := 1 }
   oBrowse:goBottomBlock    := {|| nPoz := Max( 1, Len( aPoz ) ) }
   oBrowse:skipBlock        := {| n | nStary := nPoz, nPoz := Max( 1, Min( Len( aPoz ), nPoz + n ) ), nPoz - nStary }
   oBrowse:positionBlock    := {|| IIF( Len( aPoz ) > 0, nPoz / Len( aPoz ), 0 ) }
   oBrowse:emptyBlock       := {|| Len( aPoz ) == 0 }
   oBrowse:AddColumn( "Poz.",                              {|| aPoz[ nPoz ][ 1 ] }, 4 )
   oBrowse:AddColumn( PadR( "Nazwa towaru / usługi", 30 ), {|| PadR( aPoz[ nPoz ][ 2 ], 30 ) }, 30 )
   oBrowse:AddColumn( PadL( "Ilość", 10 ),                 {|| PadL( s_Ilosc( aPoz[ nPoz ][ 3 ] ), 10 ) } )
   oBrowse:AddColumn( "J.m.",                              {|| PadR( aPoz[ nPoz ][ 4 ], 5 ) } )
   oBrowse:AddColumn( PadL( "Cena netto", 12 ),            {|| PadL( s_Kwota( aPoz[ nPoz ][ 5 ] ), 12 ) } )
   oBrowse:AddColumn( PadL( "Netto", 12 ),                 {|| PadL( s_Kwota( aPoz[ nPoz ][ 6 ] ), 12 ) } )
   oBrowse:AddColumn( "VAT",                               {|| PadR( aPoz[ nPoz ][ 7 ], 3 ) } )
   oBrowse:AddColumn( PadL( "Kwota VAT", 12 ),             {|| PadL( s_Kwota( aPoz[ nPoz ][ 8 ] ), 12 ) } )
   oBrowse:AddColumn( PadL( "Brutto", 12 ),                {|| PadL( s_Kwota( aPoz[ nPoz ][ 9 ] ), 12 ) } )

   s_Pole( oPanel, 10, oPanel:height - 36, 100, ;
           " Pozycji: " + LTrim( Str( Len( aPoz ) ) ) + ;
           "     Netto: " + s_Kwota( FKTHEAD->NETTO__FKT ) + ;
           "     VAT: " + s_Kwota( FKTHEAD->KWOTA__VAT ) + ;
           "     Brutto: " + s_Kwota( FKTHEAD->BRUTTO_FKT ) + " zł", "LB" )

   oBrowse:SetFocus()
   oDialog:Center()
   oDialog:ShowModal()

RETURN

STATIC PROCEDURE s_Wyslij( oDialog )

   LOCAL cKatalog := p_RokPobierz() + "xml"
   LOCAL hFirma
   LOCAL cNip
   LOCAL cToken
   LOCAL cXml
   LOCAL cBlad := ""
   LOCAL hOdp
   LOCAL nPlik
   LOCAL cOpis

   IF FKTHEAD->( Eof() )
      RETURN
   ENDIF
   IF FKTHEAD->KSEF_STAT == 2
      gui_MsgInfo( "Faktura jest już w KSeF." + Eol() + "Numer KSeF: " + AllTrim( FKTHEAD->KSEF_NR ), "KSeF" )
      RETURN
   ENDIF
   hFirma := p_FirmaPobierzDane()
   IF hFirma == NIL
      RETURN
   ENDIF
   cNip   := AllTrim( hFirma[ "NIP__FIRMY" ] )
   IF Empty( cNip ) .OR. Empty( hFirma[ "NAZWAFIRMY" ] ) .OR. ;
      Empty( hFirma[ "ULICAFIRMY" ] ) .AND. Empty( hFirma[ "MIASTO" ] )
      gui_MsgInfo( "Uzupełnij NIP, nazwę i adres firmy:" + Eol() + ;
                   "Pliki - Ustawienia - Firma.", "KSeF" )
      RETURN
   ENDIF
   IF Empty( FKTHEAD->NAZWA___OD ) .OR. ;
      Empty( FKTHEAD->ULICA___OD ) .AND. Empty( FKTHEAD->MIEJSCE_OD )
      gui_MsgInfo( "Faktura nie ma nazwy albo adresu nabywcy.", "KSeF" )
      RETURN
   ENDIF
   cToken := p_TokenyPobierz( cNip, hFirma[ "KSEF_SROD" ] )
   IF Empty( cToken )
      gui_MsgInfo( "Brak tokenu KSeF dla NIP " + cNip + " i środowiska z danych firmy." + Eol() + ;
                   "Dodaj go w Pliki - Tokeny - Lista tokenów.", "KSeF" )
      RETURN
   ENDIF
   IF ! gui_MsgYesNo( "Wysłać fakturę " + AllTrim( FKTHEAD->NUMER_FKT ) + " do KSeF" + Eol() + ;
                      "(środowisko " + IIF( hFirma[ "KSEF_SROD" ] == 3, "produkcyjne", "testowe" ) + ")?", "KSeF" )
      RETURN
   ENDIF

   cXml := p_Fa3GenerujXml( hFirma )
   IF ! DirExists( cKatalog )
      DirMake( cKatalog )
   ENDIF
   nPlik := FCreate( cKatalog + DirSepToOS( "\" ) + StrTran( AllTrim( FKTHEAD->NUMER_FKT ), "/", "_" ) + ".xml" )
   IF nPlik >= 0
      FWrite( nPlik, cXml )
      FClose( nPlik )
   ENDIF

   oDialog:STATUS_BAR:text := " Wysyłanie faktury do KSeF..."
   hOdp := p_KsefWyslij( cNip, cToken, hFirma[ "KSEF_SROD" ], cXml, @cBlad )
   oDialog:STATUS_BAR:text := ""

   dbSelectArea( "FKTHEAD" )
   IF ! NetRLock()
      RETURN
   ENDIF
   IF hOdp == NIL
      FKTHEAD->KSEF_OPIS := StrTran( cBlad, Eol(), " " )
      dbCommit()
      dbUnlock()
      gui_MsgError( cBlad, "KSeF" )
   ELSEIF hOdp[ "status" ][ "code" ] == 200
      FKTHEAD->KSEF_STAT := 2
      FKTHEAD->KSEF_NR   := hOdp[ "ksefNumber" ]
      FKTHEAD->KSEF_DATA := IIF( HHasKey( hOdp, "acquisitionDate" ), hOdp[ "acquisitionDate" ], "" )
      FKTHEAD->KSEF_OPIS := hOdp[ "status" ][ "description" ]
      dbCommit()
      dbUnlock()
      gui_MsgInfo( "Faktura przyjęta w KSeF." + Eol() + "Numer KSeF: " + hOdp[ "ksefNumber" ], "KSeF" )
   ELSE
      cOpis := LTrim( Str( hOdp[ "status" ][ "code" ] ) ) + " " + hOdp[ "status" ][ "description" ]
      IF HHasKey( hOdp[ "status" ], "details" ) .AND. ValType( hOdp[ "status" ][ "details" ] ) == "A"
         AEval( hOdp[ "status" ][ "details" ], {| cSzczegol | cOpis += Eol() + cSzczegol } )
      ENDIF
      FKTHEAD->KSEF_STAT := IIF( hOdp[ "status" ][ "code" ] == 100 .OR. hOdp[ "status" ][ "code" ] == 150, 1, 3 )
      FKTHEAD->KSEF_OPIS := StrTran( cOpis, Eol(), " " )
      dbCommit()
      dbUnlock()
      gui_MsgError( cOpis, "KSeF" )
   ENDIF
   oDialog:BRW:Refresh()

RETURN

/* ---------------------------------------------------------------------------------------------
   Wydruki
   --------------------------------------------------------------------------------------------- */

STATIC PROCEDURE s_Drukuj()

   LOCAL cKatalog := p_RokPobierz() + "wydruki"
   LOCAL cPlik
   LOCAL hFirma

   IF FKTHEAD->( Eof() )
      RETURN
   ENDIF
   hFirma := p_FirmaPobierzDane()
   IF hFirma == NIL
      RETURN
   ENDIF
   IF ! DirExists( cKatalog )
      DirMake( cKatalog )
   ENDIF
   cPlik := cKatalog + DirSepToOS( "\" ) + StrTran( AllTrim( FKTHEAD->NUMER_FKT ), "/", "_" ) + ".pdf"

   IF ! s_DrukPdf( cPlik, hFirma )
      gui_MsgError( "Nie można zapisać pliku " + cPlik + "." + Eol() + ;
                    "Plik może być otwarty w innym programie.", "Wydruk faktury" )
   ELSEIF ! gui_OpenFile( cPlik )
      gui_MsgInfo( "Wydruk zapisany w pliku " + cPlik + ".", "Wydruk faktury" )
   ENDIF

RETURN

STATIC FUNCTION s_Kwota( nKwota )

   LOCAL cLiczba := LTrim( Str( Abs( nKwota ), 15, 2 ) )
   LOCAL cCalosc := Left( cLiczba, Len( cLiczba ) - 3 )
   LOCAL cWynik  := ""

   DO WHILE Len( cCalosc ) > 3
      cWynik  := " " + Right( cCalosc, 3 ) + cWynik
      cCalosc := Left( cCalosc, Len( cCalosc ) - 3 )
   ENDDO

RETURN IIF( nKwota < 0, "-", "" ) + cCalosc + cWynik + "," + Right( cLiczba, 2 )

STATIC FUNCTION s_Ilosc( nIlosc )

   LOCAL cLiczba := LTrim( Str( nIlosc, 15, 3 ) )

   DO WHILE Right( cLiczba, 1 ) == "0"
      cLiczba := Left( cLiczba, Len( cLiczba ) - 1 )
   ENDDO
   IF Right( cLiczba, 1 ) == "."
      cLiczba := Left( cLiczba, Len( cLiczba ) - 1 )
   ENDIF

RETURN StrTran( cLiczba, ".", "," )

STATIC FUNCTION s_FormaPlatnosci( nForma )

   DO CASE
   CASE nForma == 1
      RETURN "gotówka"
   CASE nForma == 2
      RETURN "karta"
   ENDCASE

RETURN "przelew"

STATIC PROCEDURE s_PdfTekst( pPage, pFont, nSize, nX, nY, cTekst, nSzer )

   HPDF_Page_SetFontAndSize( pPage, pFont, nSize )
   IF HPDF_Page_TextWidth( pPage, cTekst ) > nSzer
      DO WHILE ULen( cTekst ) > 0 .AND. HPDF_Page_TextWidth( pPage, cTekst + "…" ) > nSzer
         cTekst := ULeft( cTekst, ULen( cTekst ) - 1 )
      ENDDO
      cTekst += "…"
   ENDIF
   HPDF_Page_BeginText( pPage )
   HPDF_Page_TextOut( pPage, nX, nY, cTekst )
   HPDF_Page_EndText( pPage )

RETURN

STATIC PROCEDURE s_PdfPrawo( pPage, pFont, nSize, nPrawo, nY, cTekst )

   HPDF_Page_SetFontAndSize( pPage, pFont, nSize )
   HPDF_Page_BeginText( pPage )
   HPDF_Page_TextOut( pPage, nPrawo - HPDF_Page_TextWidth( pPage, cTekst ), nY, cTekst )
   HPDF_Page_EndText( pPage )

RETURN

STATIC PROCEDURE s_PdfPasek( pPage, pBold, nY, aKolumna, aTytul, aPrawo )

   LOCAL nKolumna

   HPDF_Page_SetRGBFill( pPage, 0.302, 0.451, 0.149 )
   HPDF_Page_Rectangle( pPage, aKolumna[ 1 ], nY - 5, ATail( aKolumna ) - aKolumna[ 1 ], 16 )
   HPDF_Page_Fill( pPage )
   HPDF_Page_SetRGBFill( pPage, 1, 1, 1 )
   FOR nKolumna := 1 TO Len( aTytul )
      IF aPrawo[ nKolumna ]
         s_PdfPrawo( pPage, pBold, 8, aKolumna[ nKolumna + 1 ] - 3, nY, aTytul[ nKolumna ] )
      ELSE
         s_PdfTekst( pPage, pBold, 8, aKolumna[ nKolumna ] + 3, nY, aTytul[ nKolumna ], aKolumna[ nKolumna + 1 ] - aKolumna[ nKolumna ] - 6 )
      ENDIF
   NEXT
   HPDF_Page_SetRGBFill( pPage, 0, 0, 0 )

RETURN

STATIC PROCEDURE s_PdfStrona( pPage, pFont, pBold, nX, nY, cTytul, cNazwa, aAdres, cNip )

   LOCAL aLinie := ATokens( cNazwa, Eol( cNazwa ) )
   LOCAL cLinia

   s_PdfTekst( pPage, pFont, 8, nX, nY, cTytul, 240 )
   HPDF_Page_SetRGBStroke( pPage, 0.302, 0.451, 0.149 )
   HPDF_Page_SetLineWidth( pPage, 0.8 )
   HPDF_Page_MoveTo( pPage, nX, nY - 4 )
   HPDF_Page_LineTo( pPage, nX + 245, nY - 4 )
   HPDF_Page_Stroke( pPage )
   nY -= 18
   FOR EACH cLinia IN aLinie
      IF ! Empty( cLinia )
         s_PdfTekst( pPage, pBold, 10, nX, nY, AllTrim( cLinia ), 245 )
         nY -= 13
      ENDIF
   NEXT
   FOR EACH cLinia IN aAdres
      IF ! Empty( cLinia )
         s_PdfTekst( pPage, pFont, 9, nX, nY, cLinia, 245 )
         nY -= 12
      ENDIF
   NEXT
   IF ! Empty( cNip )
      s_PdfTekst( pPage, pFont, 9, nX, nY, "NIP: " + cNip, 245 )
   ENDIF

RETURN

STATIC FUNCTION s_DrukPdf( cPlik, hFirma )

   LOCAL aKolumna := { 40, 60, 245, 290, 320, 380, 440, 470, 515, 555 }
   LOCAL aTytul   := { "Lp", "Nazwa towaru / usługi", "Ilość", "J.m.", "Cena netto", "Netto", "VAT", "Kwota VAT", "Brutto" }
   LOCAL aPrawo   := { .T., .F., .T., .F., .T., .T., .T., .T., .T. }
   LOCAL cKlucz   := FKTHEAD->RODZAJ + Str( FKTHEAD->NR_FAKTURY, 6 )
   LOCAL hStawki  := { => }
   LOCAL pPdf     := HPDF_New()
   LOCAL pFont
   LOCAL pBold
   LOCAL pPage
   LOCAL nY
   LOCAL nStrona  := 1
   LOCAL cAdres
   LOCAL cStawka
   LOCAL aSuma
   LOCAL lZapis

   HPDF_SetCompressionMode( pPdf, HPDF_COMP_ALL )
   HPDF_SetInfoAttr( pPdf, HPDF_INFO_TITLE, "Faktura VAT " + AllTrim( FKTHEAD->NUMER_FKT ) )
   HPDF_SetInfoAttr( pPdf, HPDF_INFO_CREATOR, "xFaktura" )
   HPDF_UseUTFEncodings( pPdf )
   HPDF_SetCurrentEncoder( pPdf, "UTF-8" )
   pFont := HPDF_GetFont( pPdf, HPDF_LoadTTFontFromFile( pPdf, GetEnv( "WINDIR" ) + "\Fonts\arial.ttf", HPDF_TRUE ), "UTF-8" )
   pBold := HPDF_GetFont( pPdf, HPDF_LoadTTFontFromFile( pPdf, GetEnv( "WINDIR" ) + "\Fonts\arialbd.ttf", HPDF_TRUE ), "UTF-8" )

   pPage := HPDF_AddPage( pPdf )
   HPDF_Page_SetSize( pPage, HPDF_PAGE_SIZE_A4, HPDF_PAGE_PORTRAIT )
   p_WydrukUstawZnaki( pPage, pFont )

   s_PdfPrawo( pPage, pBold, 16, 555, 800, "Faktura VAT " + AllTrim( FKTHEAD->NUMER_FKT ) )
   s_PdfPrawo( pPage, pFont, 9, 555, 784, "Data wystawienia: " + DToC( FKTHEAD->D_WYSTAWIE ) )
   s_PdfPrawo( pPage, pFont, 9, 555, 772, "Data sprzedaży: " + DToC( FKTHEAD->D_SPRZEDAZ ) )
   IF ! Empty( FKTHEAD->KSEF_NR )
      s_PdfPrawo( pPage, pFont, 9, 555, 760, "Numer KSeF: " + AllTrim( FKTHEAD->KSEF_NR ) )
   ENDIF

   cAdres := AllTrim( hFirma[ "ULICAFIRMY" ] ) + " " + AllTrim( hFirma[ "NRDOMUFIRM" ] ) + ;
             IIF( Empty( hFirma[ "NRLOKALUFI" ] ), "", "/" + AllTrim( hFirma[ "NRLOKALUFI" ] ) )
   s_PdfStrona( pPage, pFont, pBold, 40, 730, "Sprzedawca", hFirma[ "NAZWAFIRMY" ], ;
                { AllTrim( cAdres ), AllTrim( hFirma[ "KODPOCZ" ] + " " + hFirma[ "MIASTO" ] ) }, ;
                AllTrim( hFirma[ "NIP__FIRMY" ] ) )
   s_PdfStrona( pPage, pFont, pBold, 310, 730, "Nabywca", FKTHEAD->NAZWA___OD, ;
                { AllTrim( FKTHEAD->ULICA___OD ), AllTrim( FKTHEAD->KODPOCZ_OD + " " + FKTHEAD->MIEJSCE_OD ) }, ;
                IIF( Empty( FKTHEAD->NIP_ODBIOR ), "", IIF( FKTHEAD->KODKRAJ_OD == "PL", "", FKTHEAD->KODKRAJ_OD ) + AllTrim( FKTHEAD->NIP_ODBIOR ) ) )

   nY := 610
   s_PdfPasek( pPage, pBold, nY, aKolumna, aTytul, aPrawo )
   nY -= 17
   HPDF_Page_SetRGBStroke( pPage, 0.75, 0.75, 0.75 )
   HPDF_Page_SetLineWidth( pPage, 0.5 )
   FKTROW->( dbSeek( cKlucz ) )
   DO WHILE ! FKTROW->( Eof() ) .AND. FKTROW->RODZAJ + Str( FKTROW->NR_FAKTURY, 6 ) == cKlucz
      IF nY < 120
         s_PdfPrawo( pPage, pFont, 8, 555, 40, "Strona " + LTrim( Str( nStrona ) ) )
         pPage := HPDF_AddPage( pPdf )
         HPDF_Page_SetSize( pPage, HPDF_PAGE_SIZE_A4, HPDF_PAGE_PORTRAIT )
         p_WydrukUstawZnaki( pPage, pFont )
         nStrona++
         s_PdfPrawo( pPage, pBold, 12, 555, 800, "Faktura VAT " + AllTrim( FKTHEAD->NUMER_FKT ) + " (ciąg dalszy)" )
         nY := 770
         s_PdfPasek( pPage, pBold, nY, aKolumna, aTytul, aPrawo )
         nY -= 17
         HPDF_Page_SetRGBStroke( pPage, 0.75, 0.75, 0.75 )
         HPDF_Page_SetLineWidth( pPage, 0.5 )
      ENDIF
      s_PdfPrawo( pPage, pFont, 8, aKolumna[ 2 ] - 3, nY, LTrim( Str( FKTROW->LP_FKT_ROW ) ) )
      s_PdfTekst( pPage, pFont, 8, aKolumna[ 2 ] + 3, nY, AllTrim( FKTROW->NAZWA_TOWA ), aKolumna[ 3 ] - aKolumna[ 2 ] - 6 )
      s_PdfPrawo( pPage, pFont, 8, aKolumna[ 4 ] - 3, nY, s_Ilosc( FKTROW->ILOSC__FKT ) )
      s_PdfTekst( pPage, pFont, 8, aKolumna[ 4 ] + 3, nY, AllTrim( FKTROW->JM_____FKT ), aKolumna[ 5 ] - aKolumna[ 4 ] - 6 )
      s_PdfPrawo( pPage, pFont, 8, aKolumna[ 6 ] - 3, nY, s_Kwota( FKTROW->CENA_JEDNO ) )
      s_PdfPrawo( pPage, pFont, 8, aKolumna[ 7 ] - 3, nY, s_Kwota( FKTROW->WART_NETTO ) )
      s_PdfPrawo( pPage, pFont, 8, aKolumna[ 8 ] - 3, nY, AllTrim( FKTROW->STAWKA_VAT ) + IIF( IsDigit( FKTROW->STAWKA_VAT ), "%", "" ) )
      s_PdfPrawo( pPage, pFont, 8, aKolumna[ 9 ] - 3, nY, s_Kwota( FKTROW->KWOTA__VAT ) )
      s_PdfPrawo( pPage, pFont, 8, aKolumna[ 10 ] - 3, nY, s_Kwota( FKTROW->WAR_BRUTTO ) )
      HPDF_Page_MoveTo( pPage, aKolumna[ 1 ], nY - 5 )
      HPDF_Page_LineTo( pPage, ATail( aKolumna ), nY - 5 )
      HPDF_Page_Stroke( pPage )

      cStawka := AllTrim( FKTROW->STAWKA_VAT )
      IF ! HHasKey( hStawki, cStawka )
         hStawki[ cStawka ] := { 0, 0, 0 }
      ENDIF
      hStawki[ cStawka ][ 1 ] += FKTROW->WART_NETTO
      hStawki[ cStawka ][ 2 ] += FKTROW->KWOTA__VAT
      hStawki[ cStawka ][ 3 ] += FKTROW->WAR_BRUTTO

      nY -= 15
      FKTROW->( dbSkip() )
   ENDDO

   nY -= 8
   s_PdfPasek( pPage, pBold, nY, { 320, 440, 470, 515, 555 }, { "Razem", "VAT", "Kwota VAT", "Brutto" }, { .F., .T., .T., .T. } )
   nY -= 15
   FOR EACH aSuma IN hStawki
      s_PdfPrawo( pPage, pFont, 8, 437, nY, s_Kwota( aSuma[ 1 ] ) )
      s_PdfPrawo( pPage, pFont, 8, 467, nY, aSuma:enumKey + IIF( IsDigit( aSuma:enumKey ), "%", "" ) )
      s_PdfPrawo( pPage, pFont, 8, 512, nY, s_Kwota( aSuma[ 2 ] ) )
      s_PdfPrawo( pPage, pFont, 8, 552, nY, s_Kwota( aSuma[ 3 ] ) )
      nY -= 13
   NEXT
   s_PdfPrawo( pPage, pBold, 8, 437, nY, s_Kwota( FKTHEAD->NETTO__FKT ) )
   s_PdfPrawo( pPage, pBold, 8, 467, nY, "razem" )
   s_PdfPrawo( pPage, pBold, 8, 512, nY, s_Kwota( FKTHEAD->KWOTA__VAT ) )
   s_PdfPrawo( pPage, pBold, 8, 552, nY, s_Kwota( FKTHEAD->BRUTTO_FKT ) )

   nY -= 30
   s_PdfTekst( pPage, pBold, 12, 40, nY, "Do zapłaty: " + s_Kwota( FKTHEAD->BRUTTO_FKT ) + " zł", 515 )
   nY -= 15
   s_PdfTekst( pPage, pFont, 9, 40, nY, "Słownie: " + KwotaSlownie( FKTHEAD->BRUTTO_FKT ), 515 )
   nY -= 18
   s_PdfTekst( pPage, pFont, 9, 40, nY, "Forma płatności: " + s_FormaPlatnosci( FKTHEAD->FORMA_PLAT ) + ;
               IIF( Empty( FKTHEAD->TERMIN_PLA ), "", "     Termin płatności: " + DToC( FKTHEAD->TERMIN_PLA ) ), 515 )
   IF ! Empty( FKTHEAD->KONTO___OD )
      nY -= 13
      s_PdfTekst( pPage, pFont, 9, 40, nY, "Konto: " + AllTrim( FKTHEAD->BANK____OD ) + "  " + AllTrim( FKTHEAD->KONTO___OD ), 515 )
   ENDIF
   IF HHasKey( hStawki, "zw" ) .AND. ! Empty( FKTHEAD->ZWOLNIENIE )
      nY -= 13
      s_PdfTekst( pPage, pFont, 9, 40, nY, "Podstawa zwolnienia z VAT: " + AllTrim( FKTHEAD->ZWOLNIENIE ), 515 )
   ENDIF
   IF nStrona > 1
      s_PdfPrawo( pPage, pFont, 8, 555, 40, "Strona " + LTrim( Str( nStrona ) ) )
   ENDIF

   lZapis := HPDF_SaveToFile( pPdf, cPlik ) == HPDF_OK
   HPDF_Free( pPdf )

RETURN lZapis
