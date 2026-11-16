/*
 * Copyright (c) 2026 xDev-Language
 *
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: faktury.prg
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "hpdf.ch"
#include "ord.ch"
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
   p_OfflinePrzypomnij()
   p_FakturyZakres( "FV " )

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
   AAdd( aZamroz, oToolbar:Add( "F3-Podgląd",  NIL, {|| p_FakturyPodglad( oDialog ) }, NIL, "F3" ) )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F5-Offline",  NIL, {|| p_Offline( oDialog ) }, NIL, "F5" ) )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F6-Wyślij do KSeF", NIL, {|| p_FakturyWyslij( oDialog ) }, NIL, "F6" ) )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F7-Sprawdź w KSeF", NIL, {|| p_FakturySprawdz( oDialog ) }, NIL, "F7" ) )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F9-Drukuj",   NIL, {|| p_FakturyDrukuj() }, NIL, "F9" ) )
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
   oBrowse:emptyBlock       := {|| ! p_FakturyJest() }
   oBrowse:AddColumn( "W KSeF",                   {|| p_FakturyWKsef() } )
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
   { "MIEJSCE_OD",     "C", 160, 0 }, ;
   { "ULICA___OD",     "C", 240, 0 }, ;
   { "FORMA_PLAT",     "N",   1, 0 }, ;
   { "TERMIN_PLA",     "D",   8, 0 }, ;
   { "BANK____OD",     "C", 240, 0 }, ;
   { "KONTO___OD",     "C",  34, 0 }, ;
   { "ODEBRAL_OD",     "C", 120, 0 }, ;
   { "UWAGI___OD",     "M",  10, 0 }, ;
   { "ZWOLNIENIE",     "M",  10, 0 }, ;
   { "NETTO__FKT",     "N",  12, 2 }, ;
   { "KWOTA__VAT",     "N",  12, 2 }, ;
   { "BRUTTO_FKT",     "N",  12, 2 }, ;
   { "KSEF_NR",        "C",  40, 0 }, ;
   { "KSEF_STAT",      "N",   1, 0 }, ;
   { "KSEF_DATA",      "C",  30, 0 }, ;
   { "KSEF_OPIS",      "M",  10, 0 }, ;
   { "KSEF_SESJA",     "C",  40, 0 }, ;
   { "KSEF_REF",       "C",  40, 0 }, ;
   { "KSEF_TRYB",      "N",   1, 0 }, ;
   { "KSEF_TERM",      "D",   8, 0 }, ;
   { "KSEF_SROD",      "N",   1, 0 }, ;
   { "KOR_NUMER",      "C",  30, 0 }, ;
   { "KOR_DATA",       "D",   8, 0 }, ;
   { "KOR_KSEF",       "C",  40, 0 }, ;
   { "KOR_PRZYCZ",     "M",  10, 0 }, ;
   { "DATA_____P",     "D",   8, 0 } }

FUNCTION p_PozycjeStruct()
RETURN { ;
   { "NR_FAKTURY",     "N",   6, 0 }, ;
   { "RODZAJ",         "C",   3, 0 }, ;
   { "LP_FKT_ROW",     "N",   4, 0 }, ;
   { "KOD_TOWARU",     "C",  10, 0 }, ;
   { "NAZWA_TOWA",     "M",  10, 0 }, ;
   { "JM_____FKT",     "C",  40, 0 }, ;
   { "ILOSC__FKT",     "N",  12, 3 }, ;
   { "CENA_JEDNO",     "N",  12, 2 }, ;
   { "WART_NETTO",     "N",  12, 2 }, ;
   { "STAWKA_VAT",     "C",   5, 0 }, ;
   { "KWOTA__VAT",     "N",  12, 2 }, ;
   { "WAR_BRUTTO",     "N",  12, 2 }, ;
   { "PRZED",          "L",   1, 0 }, ;
   { "DATA_____P",     "D",   8, 0 } }

FUNCTION p_FakturyOtworz()

   IF ! s_DbOpen( "fkthead", s_Struct(), "FKTHEAD" )
      RETURN .F.
   ENDIF
   IF ! s_DbOpen( "fktrow", p_PozycjeStruct(), "FKTROW" )
      FKTHEAD->( dbCloseArea() )
      RETURN .F.
   ENDIF
   IF ! s_Indeks( "FKTHEAD" ) .OR. ! s_Indeks( "FKTROW" )
      IF Select( "FKTROW" ) > 0
         FKTROW->( dbCloseArea() )
      ENDIF
      IF Select( "FKTHEAD" ) > 0
         FKTHEAD->( dbCloseArea() )
      ENDIF
      RETURN .F.
   ENDIF

RETURN .T.

STATIC FUNCTION s_DbOpen( cPlik, aWzor, cAlias )

   LOCAL cBaza := p_RokPobierz() + cPlik

   IF ! OpenDatabase( cBaza, aWzor, cAlias, "Faktury" )
      RETURN .F.
   ENDIF

RETURN .T.

PROCEDURE p_FakturyZakres( cRodzaj )

   FKTHEAD->( ordScope( TOPSCOPE,    cRodzaj + Str( 0, 6 ) ) )
   FKTHEAD->( ordScope( BOTTOMSCOPE, cRodzaj + Str( 999999, 6 ) ) )

RETURN

FUNCTION p_FakturyNastepnyNumer( cRodzaj )

   LOCAL nRecNo := FKTHEAD->( RecNo() )
   LOCAL nNr    := 0

   FKTHEAD->( dbSeek( cRodzaj + Str( 999999, 6 ), .T. ) )
   FKTHEAD->( dbSkip( -1 ) )
   IF ! FKTHEAD->( Bof() ) .AND. ! FKTHEAD->( Eof() ) .AND. FKTHEAD->RODZAJ == cRodzaj
      nNr := FKTHEAD->NR_FAKTURY
   ENDIF
   FKTHEAD->( dbGoto( nRecNo ) )

RETURN nNr + 1

FUNCTION p_FakturyPlik( cKatalog, cRozszerzenie )
RETURN p_RokPobierz() + cKatalog + DirSepToOS( "\" ) + StrTran( AllTrim( FKTHEAD->NUMER_FKT ), "/", "_" ) + cRozszerzenie

/* ---------------------------------------------------------------------------------------------
   Indexy
   --------------------------------------------------------------------------------------------- */

PROCEDURE p_FakturyNtx()

   PackDatabase( p_RokPobierz() + "fkthead", "FKTHEAD" )
   PackDatabase( p_RokPobierz() + "fktrow", "FKTROW" )
   FErase( p_RokPobierz() + "fkthead1.ntx" )
   FErase( p_RokPobierz() + "fktrow1.ntx" )

RETURN

STATIC FUNCTION s_Indeks( cAlias )

   LOCAL cBaza   := p_RokPobierz() + Lower( cAlias )
   LOCAL cIndeks := cBaza + "1"
   LOCAL cKlucz  := "RODZAJ + Str( NR_FAKTURY, 6 )"
   LOCAL bKlucz  := {|| ( cAlias )->RODZAJ + Str( ( cAlias )->NR_FAKTURY, 6 ) }

   IF FileExists( cIndeks + ".ntx" ) .AND. s_PodlaczIndeks( cAlias, cIndeks, cKlucz, bKlucz )
      RETURN .T.
   ENDIF

   ( cAlias )->( dbCloseArea() )
   dbSelectArea( 0 )
   IF ! NetUse( cBaza, .T., NIL, cAlias )
      RETURN .F.
   ENDIF
   ( cAlias )->( dbCreateIndex( cIndeks, cKlucz, bKlucz ) )
   ( cAlias )->( dbCloseArea() )
   dbSelectArea( 0 )
   IF ! NetUse( cBaza, .F., NIL, cAlias )
      RETURN .F.
   ENDIF

RETURN s_PodlaczIndeks( cAlias, cIndeks, cKlucz, bKlucz )

STATIC FUNCTION s_PodlaczIndeks( cAlias, cIndeks, cKlucz, bKlucz )

   LOCAL lOkay := .F.
   LOCAL bBlad := ErrorBlock( {| oBlad | Break( oBlad ) } )

   BEGIN SEQUENCE
      ( cAlias )->( dbSetIndex( cIndeks, { { NIL, cKlucz, bKlucz, NIL, NIL } } ) )
      lOkay := .T.
   RECOVER
      lOkay := .F.
   END SEQUENCE
   ErrorBlock( bBlad )

RETURN lOkay

FUNCTION p_FakturyWKsef()

   DO CASE
   CASE FKTHEAD->KSEF_STAT == KSEF_PRZYJETA
      RETURN "Tak    "
   CASE FKTHEAD->KSEF_STAT == KSEF_W_TOKU
      RETURN "W toku "
   CASE FKTHEAD->KSEF_TRYB > 0
      RETURN "Offline"
   ENDCASE

RETURN "Nie    "

FUNCTION p_FakturyJest()

   LOCAL nRecNo := FKTHEAD->( RecNo() )
   LOCAL lJest

   FKTHEAD->( dbGoTop() )
   lJest := ! FKTHEAD->( Eof() )
   FKTHEAD->( dbGoto( nRecNo ) )

RETURN lJest

FUNCTION p_FakturySrodowisko( hFirma, cTytul )

   IF FKTHEAD->KSEF_SROD > 0 .AND. FKTHEAD->KSEF_SROD != hFirma[ "KSEF_SROD" ]
      gui_MsgInfo( "Faktura " + AllTrim( FKTHEAD->NUMER_FKT ) + " była wysyłana do środowiska KSeF " + ;
                   Lower( p_KsefSrodowisko( FKTHEAD->KSEF_SROD ) ) + "," + Eol() + ;
                   "a w danych firmy jest teraz środowisko " + Lower( p_KsefSrodowisko( hFirma[ "KSEF_SROD" ] ) ) + ".", cTytul )
      RETURN .F.
   ENDIF

RETURN .T.

STATIC PROCEDURE s_Stan( oDialog, aZamroz )

   LOCAL lJest := p_FakturyJest()

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
      "F5             wystawienie w trybie offline (offline24, niedostępność, awaria);" + Eol() + ;
      "               wydruk F9 ma wtedy kod QR certyfikatu KSeF typu Offline" + Eol() + ;
      "F6             wysłanie faktury do KSeF tokenem z listy tokenów;" + Eol() + ;
      "               kopia XML zostaje w katalogu roku\xml" + Eol() + ;
      "F7             sprawdzenie faktury w KSeF i pobranie UPO" + Eol() + ;
      "               do katalogu roku\upo" + Eol() + ;
      "F9             wydruk faktury do PDF w katalogu roku\wydruki" + Eol() + ;
      "Strzałki       poprzednia / następna faktura" + Eol() + ;
      "Esc            zamknięcie okna" )

RETURN

PROCEDURE p_FakturyPodglad( oWindow )

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
      AAdd( aPoz, { FKTROW->LP_FKT_ROW, IIF( FKTROW->PRZED, "[przed] ", IIF( FKTHEAD->RODZAJ == "KOR", "[po] ", "" ) ) + AllTrim( FKTROW->NAZWA_TOWA ), FKTROW->ILOSC__FKT, AllTrim( FKTROW->JM_____FKT ), ;
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
   oPlat:value   := FKTHEAD->FORMA_PLAT == PLATNOSC_GOTOWKA
   oPlat:enabled := .F.
   oPlat := gui_RadioButton():New( oPanel, 255, 96, 80, 20, "Karta" )
   oPlat:value   := FKTHEAD->FORMA_PLAT == PLATNOSC_KARTA
   oPlat:enabled := .F.
   oPlat := gui_RadioButton():New( oPanel, 340, 96, 90, 20, "Przelew" )
   oPlat:value   := FKTHEAD->FORMA_PLAT == PLATNOSC_PRZELEW
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
   s_Pole( oPanel, 160, 166, 50, IIF( FKTHEAD->KSEF_STAT == KSEF_PRZYJETA, AllTrim( FKTHEAD->KSEF_NR ), ;
                                 IIF( FKTHEAD->KSEF_TRYB > 0, "offline, wyślij do " + DToC( FKTHEAD->KSEF_TERM ), "nie wysłana" ) ) )

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
   oBrowse:AddColumn( PadL( "Ilość", 10 ),                 {|| PadL( p_WydrukIlosc( aPoz[ nPoz ][ 3 ] ), 10 ) } )
   oBrowse:AddColumn( "J.m.",                              {|| PadR( aPoz[ nPoz ][ 4 ], 5 ) } )
   oBrowse:AddColumn( PadL( "Cena netto", 12 ),            {|| PadL( p_WydrukKwota( aPoz[ nPoz ][ 5 ] ), 12 ) } )
   oBrowse:AddColumn( PadL( "Netto", 12 ),                 {|| PadL( p_WydrukKwota( aPoz[ nPoz ][ 6 ] ), 12 ) } )
   oBrowse:AddColumn( "VAT",                               {|| PadR( aPoz[ nPoz ][ 7 ], 3 ) } )
   oBrowse:AddColumn( PadL( "Kwota VAT", 12 ),             {|| PadL( p_WydrukKwota( aPoz[ nPoz ][ 8 ] ), 12 ) } )
   oBrowse:AddColumn( PadL( "Brutto", 12 ),                {|| PadL( p_WydrukKwota( aPoz[ nPoz ][ 9 ] ), 12 ) } )

   s_Pole( oPanel, 10, oPanel:height - 36, 100, ;
           " Pozycji: " + LTrim( Str( Len( aPoz ) ) ) + ;
           "     Netto: " + p_WydrukKwota( FKTHEAD->NETTO__FKT ) + ;
           "     VAT: " + p_WydrukKwota( FKTHEAD->KWOTA__VAT ) + ;
           "     Brutto: " + p_WydrukKwota( FKTHEAD->BRUTTO_FKT ) + " zł", "LB" )

   oBrowse:SetFocus()
   oDialog:Center()
   oDialog:ShowModal()

RETURN

PROCEDURE p_FakturyWyslij( oDialog )

   LOCAL cKatalog := p_RokPobierz() + "xml"
   LOCAL hFirma
   LOCAL cNip
   LOCAL cToken
   LOCAL cXml
   LOCAL cBlad := ""
   LOCAL hOdp
   LOCAL nPlik
   LOCAL nSrodowisko

   IF FKTHEAD->( Eof() )
      RETURN
   ENDIF
   IF FKTHEAD->KSEF_STAT == KSEF_PRZYJETA
      gui_MsgInfo( "Faktura jest już w KSeF." + Eol() + "Numer KSeF: " + AllTrim( FKTHEAD->KSEF_NR ), "KSeF" )
      RETURN
   ENDIF
   IF FKTHEAD->KSEF_STAT == KSEF_W_TOKU
      gui_MsgInfo( "KSeF jeszcze przetwarza tę fakturę." + Eol() + "Sprawdź ją klawiszem F7.", "KSeF" )
      RETURN
   ENDIF
   hFirma := p_FirmaPobierzDane()
   IF hFirma == NIL
      RETURN
   ENDIF
   IF ! p_FakturySrodowisko( hFirma, "KSeF" )
      RETURN
   ENDIF
   nSrodowisko := hFirma[ "KSEF_SROD" ]
   cNip        := AllTrim( hFirma[ "NIP__FIRMY" ] )
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
   cToken := s_Token( cNip, nSrodowisko )
   IF Empty( cToken )
      RETURN
   ENDIF
   IF ! gui_MsgYesNo( "Wysłać fakturę " + AllTrim( FKTHEAD->NUMER_FKT ) + " do KSeF" + Eol() + ;
                      "(środowisko " + Lower( p_KsefSrodowisko( nSrodowisko ) ) + ;
                      IIF( FKTHEAD->KSEF_TRYB > 0, ", faktura offline", "" ) + ")?", "KSeF" )
      RETURN
   ENDIF

   IF FKTHEAD->KSEF_TRYB > 0
      cXml := MemoRead( p_FakturyPlik( "xml", ".xml" ), .T. )
      IF Empty( cXml )
         gui_MsgError( "Brak pliku XML faktury offline:" + Eol() + p_FakturyPlik( "xml", ".xml" ), "KSeF" )
         RETURN
      ENDIF
   ELSE
      cXml := p_Fa3GenerujXml( hFirma )
      IF ! DirExists( cKatalog )
         DirMake( cKatalog )
      ENDIF
      nPlik := FCreate( p_FakturyPlik( "xml", ".xml" ) )
      IF nPlik < 0 .OR. FWrite( nPlik, cXml ) != Len( cXml )
         IF nPlik >= 0
            FClose( nPlik )
         ENDIF
         gui_MsgError( "Nie można zapisać pliku " + p_FakturyPlik( "xml", ".xml" ) + "." + Eol() + ;
                       "Faktura nie została wysłana.", "KSeF" )
         RETURN
      ENDIF
      FClose( nPlik )
   ENDIF

   oDialog:STATUS_BAR:text := " Wysyłanie faktury do KSeF..."
   hOdp := p_KsefWyslij( cNip, cToken, nSrodowisko, cXml, @cBlad, FKTHEAD->KSEF_TRYB > 0, ;
                         {| cSesja, cFaktura | s_Przyjeta( cSesja, cFaktura, nSrodowisko ) } )
   oDialog:STATUS_BAR:text := ""

   s_Wynik( oDialog, hOdp, cBlad )

RETURN

STATIC PROCEDURE s_Przyjeta( cSesja, cFaktura, nSrodowisko )

   dbSelectArea( "FKTHEAD" )
   IF NetRLock()
      FKTHEAD->KSEF_SESJA := cSesja
      FKTHEAD->KSEF_REF   := cFaktura
      FKTHEAD->KSEF_STAT  := KSEF_W_TOKU
      FKTHEAD->KSEF_SROD  := nSrodowisko
      dbCommit()
      dbUnlock()
   ENDIF

RETURN

PROCEDURE p_FakturySprawdz( oDialog )

   LOCAL hFirma
   LOCAL cNip
   LOCAL cToken
   LOCAL cBlad := ""
   LOCAL hOdp

   IF FKTHEAD->( Eof() )
      RETURN
   ENDIF
   IF FKTHEAD->KSEF_STAT == KSEF_PRZYJETA .AND. File( p_FakturyPlik( "upo", ".xml" ) )
      gui_MsgInfo( "Faktura jest w KSeF." + Eol() + ;
                   "Numer KSeF: " + AllTrim( FKTHEAD->KSEF_NR ) + Eol() + ;
                   "UPO: " + p_FakturyPlik( "upo", ".xml" ), "KSeF" )
      RETURN
   ENDIF
   IF FKTHEAD->KSEF_STAT != KSEF_W_TOKU .AND. FKTHEAD->KSEF_STAT != KSEF_PRZYJETA
      gui_MsgInfo( "Faktura nie została przyjęta przez KSeF." + Eol() + ;
                   "Wyślij ją klawiszem F6.", "KSeF" )
      RETURN
   ENDIF
   IF Empty( FKTHEAD->KSEF_SESJA ) .OR. Empty( FKTHEAD->KSEF_REF )
      gui_MsgInfo( "Brak numeru sesji KSeF przy tej fakturze;" + Eol() + ;
                   "została wysłana wcześniejszą wersją programu.", "KSeF" )
      RETURN
   ENDIF
   hFirma := p_FirmaPobierzDane()
   IF hFirma == NIL
      RETURN
   ENDIF
   IF ! p_FakturySrodowisko( hFirma, "KSeF" )
      RETURN
   ENDIF
   cNip   := AllTrim( hFirma[ "NIP__FIRMY" ] )
   cToken := s_Token( cNip, hFirma[ "KSEF_SROD" ] )
   IF Empty( cToken )
      RETURN
   ENDIF

   oDialog:STATUS_BAR:text := " Sprawdzanie faktury w KSeF..."
   hOdp := p_KsefSprawdz( cNip, cToken, hFirma[ "KSEF_SROD" ], AllTrim( FKTHEAD->KSEF_SESJA ), AllTrim( FKTHEAD->KSEF_REF ), @cBlad )
   oDialog:STATUS_BAR:text := ""

   s_Wynik( oDialog, hOdp, cBlad )

RETURN

STATIC FUNCTION s_Token( cNip, nSrodowisko )

   LOCAL cToken := p_TokenyPobierz( cNip, nSrodowisko )

   IF Empty( cToken )
      gui_MsgInfo( "Brak tokenu KSeF dla NIP " + cNip + " i środowiska z danych firmy." + Eol() + ;
                   "Dodaj go w Pliki - Tokeny - Lista tokenów.", "KSeF" )
   ENDIF

RETURN cToken

STATIC PROCEDURE s_Wynik( oDialog, hOdp, cBlad )

   LOCAL cOpis
   LOCAL cNumer
   LOCAL xData
   LOCAL xOpis
   LOCAL lUpo   := .F.
   LOCAL lZapis
   LOCAL nKod   := p_KsefKod( hOdp )
   LOCAL nPlik

   dbSelectArea( "FKTHEAD" )
   lZapis := NetRLock()

   IF hOdp == NIL
      IF lZapis
         FKTHEAD->KSEF_OPIS := StrTran( cBlad, Eol(), " " )
         dbCommit()
         dbUnlock()
      ENDIF
      gui_MsgError( cBlad + IIF( FKTHEAD->KSEF_STAT == KSEF_W_TOKU, Eol() + Eol() + ;
                    "Faktura dotarła do KSeF. Sprawdź ją za chwilę klawiszem F7.", "" ), "KSeF" )
      oDialog:BRW:Refresh()
      RETURN
   ENDIF

   IF nKod == 200
      cNumer := hOdp[ "ksefNumber" ]
      IF lZapis
         xData := p_KsefPole( hOdp, "acquisitionDate" )
         xOpis := p_KsefPole( hOdp, "status", "description" )
         FKTHEAD->KSEF_SESJA := hOdp[ "sesja" ]
         FKTHEAD->KSEF_REF   := hOdp[ "faktura" ]
         FKTHEAD->KSEF_STAT  := KSEF_PRZYJETA
         FKTHEAD->KSEF_NR    := cNumer
         FKTHEAD->KSEF_DATA  := IIF( ValType( xData ) == "C", xData, "" )
         FKTHEAD->KSEF_OPIS  := IIF( ValType( xOpis ) == "C", xOpis, "" )
         dbCommit()
         dbUnlock()
      ENDIF
      IF HHasKey( hOdp, "upo" )
         IF ! DirExists( p_RokPobierz() + "upo" )
            DirMake( p_RokPobierz() + "upo" )
         ENDIF
         nPlik := FCreate( p_FakturyPlik( "upo", ".xml" ) )
         IF nPlik >= 0
            lUpo := FWrite( nPlik, hOdp[ "upo" ] ) == Len( hOdp[ "upo" ] )
            FClose( nPlik )
         ENDIF
      ENDIF
      gui_MsgInfo( "Faktura przyjęta w KSeF." + Eol() + ;
                   "Numer KSeF: " + cNumer + Eol() + ;
                   IIF( lUpo, "UPO: " + p_FakturyPlik( "upo", ".xml" ), "UPO jeszcze niedostępne, pobierz je później klawiszem F7." ) + ;
                   IIF( lZapis, "", Eol() + Eol() + "Nie udało się zapisać numeru KSeF w bazie." + Eol() + ;
                                    "Zanotuj go i sprawdź fakturę ponownie klawiszem F7." ), "KSeF" )
   ELSE
      cOpis := p_KsefOpisStatusu( hOdp )
      IF lZapis
         FKTHEAD->KSEF_SESJA := hOdp[ "sesja" ]
         FKTHEAD->KSEF_REF   := hOdp[ "faktura" ]
         FKTHEAD->KSEF_STAT  := IIF( nKod == 100 .OR. nKod == 150, KSEF_W_TOKU, KSEF_ODRZUCONA )
         FKTHEAD->KSEF_OPIS  := StrTran( cOpis, Eol(), " " )
         dbCommit()
         dbUnlock()
      ENDIF
      IF nKod == 100 .OR. nKod == 150
         gui_MsgInfo( "KSeF jeszcze przetwarza fakturę." + Eol() + ;
                      "Sprawdź ją za chwilę klawiszem F7.", "KSeF" )
      ELSE
         gui_MsgError( cOpis, "KSeF" )
      ENDIF
   ENDIF
   oDialog:BRW:Refresh()

RETURN

/* ---------------------------------------------------------------------------------------------
   Wydruki
   --------------------------------------------------------------------------------------------- */

PROCEDURE p_FakturyDrukuj()

   LOCAL cKatalog := p_RokPobierz() + "wydruki"
   LOCAL cPlik
   LOCAL hFirma
   LOCAL cBlad := ""

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
   cPlik := p_FakturyPlik( "wydruki", ".pdf" )

   IF ! s_DrukPdf( cPlik, hFirma, @cBlad )
      gui_MsgError( cBlad, "Wydruk faktury" )
   ELSEIF ! gui_OpenFile( cPlik )
      gui_MsgInfo( "Wydruk zapisany w pliku " + cPlik + ".", "Wydruk faktury" )
   ENDIF

RETURN

STATIC FUNCTION s_DrukPdf( cPlik, hFirma, cBlad )

   LOCAL aKolumna := { 40, 60, 245, 290, 320, 380, 440, 470, 515, 555 }
   LOCAL aTytul   := { "Lp", "Nazwa towaru / usługi", "Ilość", "J.m.", "Cena netto", "Netto", "VAT", "Kwota VAT", "Brutto" }
   LOCAL aPrawo   := { .T., .F., .T., .F., .T., .T., .T., .T., .T. }
   LOCAL lKor     := FKTHEAD->RODZAJ == "KOR"
   LOCAL cKlucz   := FKTHEAD->RODZAJ + Str( FKTHEAD->NR_FAKTURY, 6 )
   LOCAL cTytul   := IIF( lKor, "Faktura korygująca ", "Faktura VAT " ) + AllTrim( FKTHEAD->NUMER_FKT )
   LOCAL hStawki  := { => }
   LOCAL pPdf     := HPDF_New()
   LOCAL pFont
   LOCAL pBold
   LOCAL pPage
   LOCAL nY
   LOCAL nStrona  := 1
   LOCAL nSekcja  := 0
   LOCAL nZnak
   LOCAL cAdres
   LOCAL cStawka
   LOCAL aSuma
   LOCAL lZapis
   LOCAL cQr
   LOCAL cKodII

   HPDF_SetCompressionMode( pPdf, HPDF_COMP_ALL )
   HPDF_SetInfoAttr( pPdf, HPDF_INFO_TITLE, cTytul )
   HPDF_SetInfoAttr( pPdf, HPDF_INFO_CREATOR, "xFaktura" )
   HPDF_UseUTFEncodings( pPdf )
   HPDF_SetCurrentEncoder( pPdf, "UTF-8" )
   pFont := p_WydrukCzcionka( pPdf, "arial.ttf" )
   pBold := p_WydrukCzcionka( pPdf, "arialbd.ttf" )
   IF pFont == NIL .OR. pBold == NIL
      HPDF_Free( pPdf )
      cBlad := "Brak czcionki Arial w katalogu " + GetEnv( "WINDIR" ) + DirSepToOS( "\" ) + "Fonts."
      RETURN .F.
   ENDIF

   pPage := HPDF_AddPage( pPdf )
   HPDF_Page_SetSize( pPage, HPDF_PAGE_SIZE_A4, HPDF_PAGE_PORTRAIT )
   p_WydrukUstawZnaki( pPage, pFont )

   p_WydrukPrawo( pPage, pBold, 16, 555, 800, cTytul )
   p_WydrukPrawo( pPage, pFont, 9, 555, 784, "Data wystawienia: " + DToC( FKTHEAD->D_WYSTAWIE ) )
   nY := 772
   IF ! lKor
      p_WydrukPrawo( pPage, pFont, 9, 555, nY, "Data sprzedaży: " + DToC( FKTHEAD->D_SPRZEDAZ ) )
      nY -= 12
   ENDIF
   IF ! Empty( FKTHEAD->KSEF_NR )
      p_WydrukPrawo( pPage, pFont, 9, 555, nY, "Numer KSeF: " + AllTrim( FKTHEAD->KSEF_NR ) )
   ENDIF

   cAdres := AllTrim( hFirma[ "ULICAFIRMY" ] ) + " " + AllTrim( hFirma[ "NRDOMUFIRM" ] ) + ;
             IIF( Empty( hFirma[ "NRLOKALUFI" ] ), "", "/" + AllTrim( hFirma[ "NRLOKALUFI" ] ) )
   p_WydrukStrona( pPage, pFont, pBold, 40, 730, "Sprzedawca", hFirma[ "NAZWAFIRMY" ], ;
                   { AllTrim( cAdres ), AllTrim( hFirma[ "KODPOCZ" ] + " " + hFirma[ "MIASTO" ] ) }, ;
                   AllTrim( hFirma[ "NIP__FIRMY" ] ) )
   p_WydrukStrona( pPage, pFont, pBold, 310, 730, "Nabywca", FKTHEAD->NAZWA___OD, ;
                   { AllTrim( FKTHEAD->ULICA___OD ), AllTrim( FKTHEAD->KODPOCZ_OD + " " + FKTHEAD->MIEJSCE_OD ) }, ;
                   IIF( Empty( FKTHEAD->NIP_ODBIOR ), "", IIF( FKTHEAD->KODKRAJ_OD == "PL", "", FKTHEAD->KODKRAJ_OD ) + AllTrim( FKTHEAD->NIP_ODBIOR ) ) )

   IF lKor
      p_WydrukTekst( pPage, pFont, 9, 40, 632, "Korekta faktury " + AllTrim( FKTHEAD->KOR_NUMER ) + " z dnia " + DToC( FKTHEAD->KOR_DATA ) + ;
                     IIF( Empty( FKTHEAD->KOR_KSEF ), "", ", numer KSeF " + AllTrim( FKTHEAD->KOR_KSEF ) ), 515 )
      p_WydrukTekst( pPage, pFont, 9, 40, 619, "Przyczyna korekty: " + AllTrim( FKTHEAD->KOR_PRZYCZ ), 515 )
      nY := 596
   ELSE
      nY := 610
   ENDIF

   p_WydrukPasek( pPage, pBold, nY, aKolumna, aTytul, aPrawo )
   nY -= 17
   HPDF_Page_SetRGBStroke( pPage, 0.75, 0.75, 0.75 )
   HPDF_Page_SetLineWidth( pPage, 0.5 )
   FKTROW->( dbSeek( cKlucz ) )
   DO WHILE ! FKTROW->( Eof() ) .AND. FKTROW->RODZAJ + Str( FKTROW->NR_FAKTURY, 6 ) == cKlucz
      IF nY < 120
         p_WydrukPrawo( pPage, pFont, 8, 555, 40, "Strona " + LTrim( Str( nStrona ) ) )
         pPage := HPDF_AddPage( pPdf )
         HPDF_Page_SetSize( pPage, HPDF_PAGE_SIZE_A4, HPDF_PAGE_PORTRAIT )
         p_WydrukUstawZnaki( pPage, pFont )
         nStrona++
         p_WydrukPrawo( pPage, pBold, 12, 555, 800, cTytul + " (ciąg dalszy)" )
         nY := 770
         p_WydrukPasek( pPage, pBold, nY, aKolumna, aTytul, aPrawo )
         nY -= 17
         HPDF_Page_SetRGBStroke( pPage, 0.75, 0.75, 0.75 )
         HPDF_Page_SetLineWidth( pPage, 0.5 )
      ENDIF
      IF lKor .AND. nSekcja != IIF( FKTROW->PRZED, 1, 2 )
         nSekcja := IIF( FKTROW->PRZED, 1, 2 )
         p_WydrukTekst( pPage, pBold, 8, aKolumna[ 2 ] + 3, nY, IIF( nSekcja == 1, "Przed korektą", "Po korekcie" ), 200 )
         nY -= 15
      ENDIF
      p_WydrukPrawo( pPage, pFont, 8, aKolumna[ 2 ] - 3, nY, LTrim( Str( FKTROW->LP_FKT_ROW ) ) )
      p_WydrukTekst( pPage, pFont, 8, aKolumna[ 2 ] + 3, nY, AllTrim( FKTROW->NAZWA_TOWA ), aKolumna[ 3 ] - aKolumna[ 2 ] - 6 )
      p_WydrukPrawo( pPage, pFont, 8, aKolumna[ 4 ] - 3, nY, p_WydrukIlosc( FKTROW->ILOSC__FKT ) )
      p_WydrukTekst( pPage, pFont, 8, aKolumna[ 4 ] + 3, nY, AllTrim( FKTROW->JM_____FKT ), aKolumna[ 5 ] - aKolumna[ 4 ] - 6 )
      p_WydrukPrawo( pPage, pFont, 8, aKolumna[ 6 ] - 3, nY, p_WydrukKwota( FKTROW->CENA_JEDNO ) )
      p_WydrukPrawo( pPage, pFont, 8, aKolumna[ 7 ] - 3, nY, p_WydrukKwota( FKTROW->WART_NETTO ) )
      p_WydrukPrawo( pPage, pFont, 8, aKolumna[ 8 ] - 3, nY, AllTrim( FKTROW->STAWKA_VAT ) + IIF( IsDigit( FKTROW->STAWKA_VAT ), "%", "" ) )
      p_WydrukPrawo( pPage, pFont, 8, aKolumna[ 9 ] - 3, nY, p_WydrukKwota( FKTROW->KWOTA__VAT ) )
      p_WydrukPrawo( pPage, pFont, 8, aKolumna[ 10 ] - 3, nY, p_WydrukKwota( FKTROW->WAR_BRUTTO ) )
      HPDF_Page_MoveTo( pPage, aKolumna[ 1 ], nY - 5 )
      HPDF_Page_LineTo( pPage, ATail( aKolumna ), nY - 5 )
      HPDF_Page_Stroke( pPage )

      cStawka := AllTrim( FKTROW->STAWKA_VAT )
      IF ! HHasKey( hStawki, cStawka )
         hStawki[ cStawka ] := { 0, 0, 0 }
      ENDIF
      nZnak := IIF( FKTROW->PRZED, -1, 1 )
      hStawki[ cStawka ][ 1 ] += nZnak * FKTROW->WART_NETTO
      hStawki[ cStawka ][ 2 ] += nZnak * FKTROW->KWOTA__VAT
      hStawki[ cStawka ][ 3 ] += nZnak * FKTROW->WAR_BRUTTO

      nY -= 15
      FKTROW->( dbSkip() )
   ENDDO

   nY -= 8
   p_WydrukPasek( pPage, pBold, nY, { 320, 440, 470, 515, 555 }, { IIF( lKor, "Zmiana", "Razem" ), "VAT", "Kwota VAT", "Brutto" }, { .F., .T., .T., .T. } )
   nY -= 15
   FOR EACH aSuma IN hStawki
      p_WydrukPrawo( pPage, pFont, 8, 437, nY, p_WydrukKwota( aSuma[ 1 ] ) )
      p_WydrukPrawo( pPage, pFont, 8, 467, nY, aSuma:enumKey + IIF( IsDigit( aSuma:enumKey ), "%", "" ) )
      p_WydrukPrawo( pPage, pFont, 8, 512, nY, p_WydrukKwota( aSuma[ 2 ] ) )
      p_WydrukPrawo( pPage, pFont, 8, 552, nY, p_WydrukKwota( aSuma[ 3 ] ) )
      nY -= 13
   NEXT
   p_WydrukPrawo( pPage, pBold, 8, 437, nY, p_WydrukKwota( FKTHEAD->NETTO__FKT ) )
   p_WydrukPrawo( pPage, pBold, 8, 467, nY, "razem" )
   p_WydrukPrawo( pPage, pBold, 8, 512, nY, p_WydrukKwota( FKTHEAD->KWOTA__VAT ) )
   p_WydrukPrawo( pPage, pBold, 8, 552, nY, p_WydrukKwota( FKTHEAD->BRUTTO_FKT ) )

   nY -= 30
   p_WydrukTekst( pPage, pBold, 12, 40, nY, IIF( FKTHEAD->BRUTTO_FKT < 0, "Do zwrotu: ", "Do zapłaty: " ) + ;
                  p_WydrukKwota( Abs( FKTHEAD->BRUTTO_FKT ) ) + " zł", 515 )
   nY -= 15
   p_WydrukTekst( pPage, pFont, 9, 40, nY, "Słownie: " + KwotaSlownie( Abs( FKTHEAD->BRUTTO_FKT ) ), 515 )
   IF ! lKor
      nY -= 18
      p_WydrukTekst( pPage, pFont, 9, 40, nY, "Forma płatności: " + p_WydrukFormaPlatnosci( FKTHEAD->FORMA_PLAT ) + ;
                     IIF( Empty( FKTHEAD->TERMIN_PLA ), "", "     Termin płatności: " + DToC( FKTHEAD->TERMIN_PLA ) ), 515 )
      IF ! Empty( FKTHEAD->KONTO___OD )
         nY -= 13
         p_WydrukTekst( pPage, pFont, 9, 40, nY, "Konto: " + AllTrim( FKTHEAD->BANK____OD ) + "  " + AllTrim( FKTHEAD->KONTO___OD ), 515 )
      ENDIF
   ENDIF
   IF HHasKey( hStawki, "zw" ) .AND. ! Empty( FKTHEAD->ZWOLNIENIE )
      nY -= 13
      p_WydrukTekst( pPage, pFont, 9, 40, nY, "Podstawa zwolnienia z VAT: " + AllTrim( FKTHEAD->ZWOLNIENIE ), 515 )
   ENDIF

   cQr := p_WydrukQrAdres( hFirma )
   IF ! Empty( cQr )
      IF nY < 190
         p_WydrukPrawo( pPage, pFont, 8, 555, 40, "Strona " + LTrim( Str( nStrona ) ) )
         pPage := HPDF_AddPage( pPdf )
         HPDF_Page_SetSize( pPage, HPDF_PAGE_SIZE_A4, HPDF_PAGE_PORTRAIT )
         p_WydrukUstawZnaki( pPage, pFont )
         nStrona++
         nY := 800
      ENDIF
      p_WydrukQr( pPage, cQr, 40, nY - 120, 96 )
      p_WydrukTekst( pPage, pFont, 7, 40, nY - 130, IIF( Empty( FKTHEAD->KSEF_NR ), "OFFLINE", AllTrim( FKTHEAD->KSEF_NR ) ), 200 )
      cKodII := p_OfflineKodII( hFirma )
      IF ! Empty( cKodII )
         p_WydrukQr( pPage, cKodII, 435, nY - 144, 120 )
         p_WydrukTekst( pPage, pFont, 7, 435, nY - 154, "CERTYFIKAT", 120 )
      ENDIF
   ENDIF
   IF nStrona > 1
      p_WydrukPrawo( pPage, pFont, 8, 555, 40, "Strona " + LTrim( Str( nStrona ) ) )
   ENDIF

   lZapis := HPDF_SaveToFile( pPdf, cPlik ) == HPDF_OK
   HPDF_Free( pPdf )
   IF ! lZapis
      cBlad := "Nie można zapisać pliku " + cPlik + "." + Eol() + "Plik może być otwarty w innym programie."
   ENDIF

RETURN lZapis
