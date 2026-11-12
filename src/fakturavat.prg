/*
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: fakturavat.prg
 *
 * Copyright (c) 2026 xDev-Language
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "inkey.ch"
#include "xfaktura.ch"

PROCEDURE p_FakturaVat( oWindow )

   LOCAL oDialog
   LOCAL oToolbar
   LOCAL oPanel
   LOCAL oBrowse
   LOCAL oStatus
   LOCAL hFirma
   LOCAL hFkt
   LOCAL aZamroz  := {}
   LOCAL lOtwarte := Select( "FKTHEAD" ) > 0

   hFirma := p_FirmaPobierzDane()
   IF hFirma == NIL
      RETURN
   ENDIF
   IF ! lOtwarte .AND. ! p_FakturyOtworz()
      RETURN
   ENDIF
   IF ! s_Tymczasowa()
      IF ! lOtwarte
         FKTROW->( dbCloseArea() )
         FKTHEAD->( dbCloseArea() )
      ENDIF
      RETURN
   ENDIF

   hFkt := { "D_WYSTAWIE" => Date(), ;
             "D_SPRZEDAZ" => Date(), ;
             "FORMA_PLAT" => 1, ;
             "TERMIN_PLA" => Date(), ;
             "KODKRAJ_OD" => "PL", ;
             "NIP_ODBIOR" => Space( 20 ), ;
             "NAZWA___OD" => "", ;
             "ULICA___OD" => Space( 60 ), ;
             "KODPOCZ_OD" => Space( 6 ), ;
             "MIEJSCE_OD" => Space( 40 ), ;
             "BANK____OD" => "", ;
             "KONTO___OD" => "", ;
             "ZWOLNIENIE" => AllTrim( hFirma[ "ZWOLNIENIE" ] ) }
   IF hFirma[ "DRUK_BANK" ]
      hFkt[ "BANK____OD" ] := AllTrim( IIF( hFirma[ "DRUKUJ_TO" ] == 2, hFirma[ "NAZWABANK2" ], hFirma[ "NAZWABANKU" ] ) )
      hFkt[ "KONTO___OD" ] := AllTrim( IIF( hFirma[ "DRUKUJ_TO" ] == 2, hFirma[ "NRRACHUNK2" ], hFirma[ "NRRACHUNKU" ] ) )
   ENDIF

   oDialog := gui_Dialog():New( oWindow, "Wystaw fakturę VAT", 1100, 700 )
   oDialog:background := 0xe9edf1
   oDialog:sizable := .T.
   oDialog:SetKey( "Ins", {|| s_Pozycja( oDialog, hFkt, .T. ), s_Stan( oDialog, aZamroz ) } )

   oStatus := gui_StatusBar():New( oDialog )
   oStatus:name := "STATUS_BAR"
   oStatus:font := gui_Font():New( NIL, .F., .F., "xFont 9x18" )
   oStatus:Add( 0 )
   oStatus:Add( 60 )
   oStatus:scoreboard := 2

   oToolbar := gui_Toolbar():New( oDialog, "Bottom" )
   oToolbar:name := "PASEK"
   oToolbar:Add( "F1-Pomoc",                    NIL, {|| s_Pomoc( oDialog ) }, NIL, "F1" )
   oToolbar:AddSeparator()
   oToolbar:Add( "F2-Dodaj pozycję",            NIL, {|| s_Pozycja( oDialog, hFkt, .T. ), s_Stan( oDialog, aZamroz ) }, NIL, "F2" )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F3-Nagłówek",  NIL, {|| s_Naglowek( oDialog, oPanel, hFkt ) }, NIL, "F3" ) )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F4-Popraw",    NIL, {|| s_Pozycja( oDialog, hFkt, .F. ) }, NIL, "F4" ) )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F8-Usuń",      NIL, {|| s_UsunPozycje( oDialog, hFkt ), s_Stan( oDialog, aZamroz ) }, NIL, "F8" ) )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F10-Zapisz",   NIL, {|| s_Zapisz( oDialog, hFkt ) }, NIL, "F10" ) )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F12-Nabywca",  NIL, {|| s_Nabywca( oDialog, hFkt ) }, NIL, "F12" ) )
   oToolbar:AddSeparator()
   oToolbar:Add( "Esc-Anuluj",   NIL, {|| s_Anuluj( oDialog ) }, NIL, "Esc" )
   oToolbar:AddSeparator()

   oPanel := gui_Panel():New( oDialog )

   s_Opis( oPanel, 20,   7, 14, "Numer faktury:" )
   s_Opis( oPanel, 20,  37, 14, "Data wystawienia:" )
   s_Opis( oPanel, 20,  67, 14, "Data sprzedaży:" )
   s_Opis( oPanel, 20,  97, 14, "Płatność:" )
   s_Opis( oPanel, 20, 127, 14, "Data płatności:" )
   s_Pole( oPanel, 160,   4, 14, "NUMER_FKT" )
   s_Pole( oPanel, 160,  34, 10, "D_WYSTAWIE" )
   s_Pole( oPanel, 160,  64, 10, "D_SPRZEDAZ" )
   s_Pole( oPanel, 160, 124, 10, "TERMIN_PLA" )

   gui_RadioButton():New( oPanel, 160, 96, 90, 20, "Gotówka" ):name := "PLAT_1"
   gui_RadioButton():New( oPanel, 255, 96, 80, 20, "Karta" ):name   := "PLAT_2"
   gui_RadioButton():New( oPanel, 340, 96, 90, 20, "Przelew" ):name := "PLAT_6"

   gui_Panel():New( oPanel, 445, 4, 1, 144 ):background := 0xa0a0a0

   s_Opis( oPanel, 460,  7, 14, "Kod kraju / NIP:" )
   s_Opis( oPanel, 460, 37, 14, "Nazwa kontrahenta:" )
   s_Opis( oPanel, 460, 67, 14, "Ulica:" )
   s_Opis( oPanel, 460, 97, 14, "Kod / Miejscowość:" )
   s_Pole( oPanel, 600,  4,  2, "KODKRAJ_OD" )
   s_Pole( oPanel, 636,  4, 20, "NIP_ODBIOR" )
   s_Pole( oPanel, 600, 34, 40, "NAZWA___OD" )
   s_Pole( oPanel, 600, 64, 40, "ULICA___OD" )
   s_Pole( oPanel, 600, 94,  6, "KODPOCZ_OD" )
   s_Pole( oPanel, 672, 94, 32, "MIEJSCE_OD" )

   oBrowse := gui_Browse():New( oPanel, 10, 158, oPanel:width - 20, oPanel:height - 202 )
   oBrowse:name             := "BRW"
   oBrowse:headerBackground := 0x4d7326
   oBrowse:anchor           := "LTRB"
   oBrowse:goTopBlock       := {|| FKTTEMP->( dbGoTop() ) }
   oBrowse:goBottomBlock    := {|| FKTTEMP->( dbGoBottom() ) }
   oBrowse:skipBlock        := {| n | FKTTEMP->( DbSkipper( n ) ) }
   oBrowse:positionBlock    := {|| FKTTEMP->( IIF( LastRec() > 0, RecNo() / LastRec(), 0 ) ) }
   oBrowse:emptyBlock       := {|| FKTTEMP->( LastRec() ) == 0 }
   oBrowse:AddColumn( "Lp",                         {|| FKTTEMP->LP_FKT_ROW } )
   oBrowse:AddColumn( PadR( "Nazwa towaru / usługi", 36 ), {|| Left( FKTTEMP->NAZWA_TOWA, 36 ) }, 36 )
   oBrowse:AddColumn( PadL( "Ilość", 12 ),          {|| FKTTEMP->ILOSC__FKT } )
   oBrowse:AddColumn( "J.m.",                       {|| Left( FKTTEMP->JM_____FKT, 5 ) } )
   oBrowse:AddColumn( PadL( "Cena netto", 12 ),     {|| FKTTEMP->CENA_JEDNO } )
   oBrowse:AddColumn( PadL( "Netto", 12 ),          {|| FKTTEMP->WART_NETTO } )
   oBrowse:AddColumn( "VAT",                        {|| FKTTEMP->STAWKA_VAT } )
   oBrowse:AddColumn( PadL( "Kwota VAT", 12 ),      {|| FKTTEMP->KWOTA__VAT } )
   oBrowse:AddColumn( PadL( "Brutto", 12 ),         {|| FKTTEMP->WAR_BRUTTO } )
   oBrowse:OnChange := {|| s_Okno( oDialog, hFkt ) }

   s_Pole( oPanel, 10, oPanel:height - 36, 100, "SUMA" )
   oDialog:SUMA:anchor := "LB"

   AEval( s_Wybor( oDialog ), {| oWybor | oWybor:enabled := .F. } )
   s_Okno( oDialog, hFkt )
   s_Stan( oDialog, aZamroz )

   oDialog:Center()
   oDialog:ShowModal()

   FKTTEMP->( dbCloseArea() )
   FErase( p_RokPobierz() + "fkttemp.dbf" )
   IF ! lOtwarte
      FKTROW->( dbCloseArea() )
      FKTHEAD->( dbCloseArea() )
   ENDIF

RETURN

/* ---------------------------------------------------------------------------------------------
   Baza
   --------------------------------------------------------------------------------------------- */

STATIC FUNCTION s_Tymczasowa()

   LOCAL cBaza := p_RokPobierz() + "fkttemp"

   FErase( cBaza + ".dbf" )
   dbCreate( cBaza, p_PozycjeStruct() )
   dbSelectArea( 0 )

RETURN NetUse( cBaza, .T., NIL, "FKTTEMP" )

STATIC PROCEDURE s_Stan( oDialog, aZamroz )

   LOCAL lJest := FKTTEMP->( LastRec() ) > 0

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

STATIC PROCEDURE s_Pole( oPanel, nX, nY, nLen, cName )

   LOCAL oSay := gui_Say():New( oPanel, nX, nY, nLen, 24 )

   oSay:name   := cName
   oSay:border := .T.

RETURN

STATIC FUNCTION s_Wybor( oDialog )
RETURN { oDialog:PLAT_1, oDialog:PLAT_2, oDialog:PLAT_6 }

STATIC FUNCTION s_Data( dData )
RETURN IIF( Empty( dData ), "", DToC( dData ) )

STATIC FUNCTION s_Numer( nNr )
RETURN "FV/" + LTrim( Str( nNr ) ) + "/" + Left( p_RokPobierz(), 4 )

STATIC FUNCTION s_NastepnyNumer()

   LOCAL nNr    := 0
   LOCAL nRecNo := FKTHEAD->( RecNo() )

   FKTHEAD->( dbEval( {|| nNr := Max( nNr, FKTHEAD->NR_FAKTURY ) }, {|| FKTHEAD->RODZAJ == "FV " } ) )
   FKTHEAD->( dbGoto( nRecNo ) )

RETURN nNr + 1

STATIC PROCEDURE s_Okno( oDialog, hFkt )

   LOCAL nNetto  := 0
   LOCAL nVat    := 0
   LOCAL nRecNo  := FKTTEMP->( RecNo() )

   oDialog:NUMER_FKT:text  := s_Numer( s_NastepnyNumer() )
   oDialog:D_WYSTAWIE:text := s_Data( hFkt[ "D_WYSTAWIE" ] )
   oDialog:D_SPRZEDAZ:text := s_Data( hFkt[ "D_SPRZEDAZ" ] )
   oDialog:TERMIN_PLA:text := s_Data( hFkt[ "TERMIN_PLA" ] )
   oDialog:PLAT_1:value    := hFkt[ "FORMA_PLAT" ] == 1
   oDialog:PLAT_2:value    := hFkt[ "FORMA_PLAT" ] == 2
   oDialog:PLAT_6:value    := hFkt[ "FORMA_PLAT" ] == 6
   oDialog:KODKRAJ_OD:text := hFkt[ "KODKRAJ_OD" ]
   oDialog:NIP_ODBIOR:text := hFkt[ "NIP_ODBIOR" ]
   oDialog:NAZWA___OD:text := StrTran( hFkt[ "NAZWA___OD" ], Eol( hFkt[ "NAZWA___OD" ] ), " " )
   oDialog:ULICA___OD:text := hFkt[ "ULICA___OD" ]
   oDialog:KODPOCZ_OD:text := hFkt[ "KODPOCZ_OD" ]
   oDialog:MIEJSCE_OD:text := hFkt[ "MIEJSCE_OD" ]

   FKTTEMP->( dbEval( {|| nNetto += FKTTEMP->WART_NETTO, nVat += FKTTEMP->KWOTA__VAT } ) )
   FKTTEMP->( dbGoto( nRecNo ) )
   oDialog:SUMA:text := " Pozycji: " + LTrim( Str( FKTTEMP->( LastRec() ) ) ) + ;
                        "     Netto: " + LTrim( Str( nNetto, 12, 2 ) ) + ;
                        "     VAT: " + LTrim( Str( nVat, 12, 2 ) ) + ;
                        "     Brutto: " + LTrim( Str( nNetto + nVat, 12, 2 ) )

RETURN

STATIC PROCEDURE s_TrybEdycji( oDialog, lWlacz )

   IF lWlacz
      oDialog:STATUS_BAR:text := " Tryb edycji - PgUp PgDn Enter = zapisz, Esc = bez zapisu"
      oDialog:STATUS_BAR:background := 0x73264d
      oDialog:STATUS_BAR:foreground := 0xffffff
   ELSE
      oDialog:STATUS_BAR:text       := ""
      oDialog:STATUS_BAR:background := NIL
      oDialog:STATUS_BAR:foreground := NIL
   ENDIF

RETURN

STATIC PROCEDURE s_Pomoc( oWindow )

   p_Pomoc( oWindow, "Wystaw fakturę VAT", ;
      Eol() + ;
      "Pozycje" + Eol() + ;
      Eol() + ;
      "F2, Ins        nowa pozycja" + Eol() + ;
      "F4             poprawienie pozycji" + Eol() + ;
      "F8             usunięcie pozycji" + Eol() + ;
      "Strzałki       poprzednia / następna pozycja" + Eol() + ;
      Eol() + ;
      "Faktura" + Eol() + ;
      Eol() + ;
      "F3             daty, płatność i dane nabywcy" + Eol() + ;
      "F12            nabywca z kartoteki kontrahentów" + Eol() + ;
      "F10            zapis faktury, numer FV/kolejny/rok nadaje program" + Eol() + ;
      "Esc            rezygnacja z faktury" + Eol() + ;
      Eol() + ;
      "Wpisywanie danych" + Eol() + ;
      Eol() + ;
      "Enter          następne pole, na ostatnim zapis" + Eol() + ;
      "PgUp, PgDn     zapis" + Eol() + ;
      "Esc            bez zapisu" + Eol() + ;
      Eol() + ;
      "Stawki VAT: 23, 22, 8, 7, 5, 4, 3, 0 (krajowe), zw (zwolnione)," + Eol() + ;
      "            oo (odwrotne obciążenie), np (nie podlega)" + Eol() + ;
      "Netto pozycji = ilość x cena netto, VAT liczony od netto pozycji." )

RETURN

STATIC FUNCTION s_Stawka( cStawka )

   LOCAL cJest := Lower( AllTrim( cStawka ) )

RETURN IIF( AScan( { "23", "22", "8", "7", "5", "4", "3", "0", "zw", "oo", "np" }, {| c | c == cJest } ) > 0, cJest, NIL )

STATIC PROCEDURE s_Pozycja( oDialog, hFkt, lNowa )

   LOCAL GetList := {}
   LOCAL oOkno
   LOCAL nRecNo  := FKTTEMP->( RecNo() )
   LOCAL cNazwa
   LOCAL nIlosc
   LOCAL cJm
   LOCAL nCena
   LOCAL cStawka
   LOCAL nNetto
   LOCAL nVat

   IF ! lNowa .AND. FKTTEMP->( Eof() )
      RETURN
   ENDIF
   IF lNowa
      FKTTEMP->( dbGoBottom() )
      FKTTEMP->( dbSkip() )
   ENDIF
   cNazwa  := FKTTEMP->NAZWA_TOWA
   nIlosc  := IIF( lNowa, 1, FKTTEMP->ILOSC__FKT )
   cJm     := IIF( lNowa, PadR( "szt.", Len( FKTTEMP->JM_____FKT ) ), FKTTEMP->JM_____FKT )
   nCena   := FKTTEMP->CENA_JEDNO
   cStawka := PadR( IIF( lNowa, "23", AllTrim( FKTTEMP->STAWKA_VAT ) ), 2 )

   oOkno := gui_Dialog():New( oDialog, "Pozycje na fakturze", 640, 200 )
   oOkno:background := 0xe9edf1

   s_Opis( oOkno, 20,  23, 14, "Nazwa:" )
   s_Opis( oOkno, 20,  53, 14, "Ilość / j.m.:" )
   s_Opis( oOkno, 20,  83, 14, "Cena netto:" )
   s_Opis( oOkno, 20, 113, 14, "Stawka VAT:" )

   AAdd( GetList, gui_Get():New( oOkno, 160,  20, 50, NIL, @cNazwa ) )
   AAdd( GetList, gui_Get():New( oOkno, 160,  50, 10, NIL, @nIlosc, "999999.999" ) )
   AAdd( GetList, gui_Get():New( oOkno, 260,  50,  6, NIL, @cJm ) )
   AAdd( GetList, gui_Get():New( oOkno, 160,  80, 11, NIL, @nCena, "99999999.99" ) )
   AAdd( GetList, gui_Get():New( oOkno, 160, 110,  2, NIL, @cStawka, "@K XX" ) )

   oDialog:PASEK:enabled := .F.
   oDialog:BRW:enabled   := .F.
   oOkno:Center()
   oOkno:Show()
   s_TrybEdycji( oDialog, .T. )
   oOkno:ReadModal( GetList )
   s_TrybEdycji( oDialog, .F. )
   oOkno:Close()
   oDialog:PASEK:enabled := .T.
   oDialog:BRW:enabled   := FKTTEMP->( LastRec() ) > 0

   IF LastKey() == K_ESC .OR. Empty( cNazwa )
      FKTTEMP->( dbGoto( nRecNo ) )
      s_Okno( oDialog, hFkt )
      RETURN
   ENDIF
   IF s_Stawka( cStawka ) == NIL
      gui_MsgInfo( "Nieznana stawka VAT: " + AllTrim( cStawka ) + Eol() + "Dozwolone: 23, 22, 8, 7, 5, 4, 3, 0, zw, oo, np", "Faktura" )
      FKTTEMP->( dbGoto( nRecNo ) )
      s_Okno( oDialog, hFkt )
      RETURN
   ENDIF
   cStawka := s_Stawka( cStawka )
   nNetto  := Round( nIlosc * nCena, 2 )
   nVat    := IIF( IsDigit( cStawka ), Round( nNetto * Val( cStawka ) / 100, 2 ), 0 )

   IF lNowa
      FKTTEMP->( dbAppend() )
      FKTTEMP->LP_FKT_ROW := FKTTEMP->( LastRec() )
   ENDIF
   FKTTEMP->NAZWA_TOWA := cNazwa
   FKTTEMP->ILOSC__FKT := nIlosc
   FKTTEMP->JM_____FKT := cJm
   FKTTEMP->CENA_JEDNO := nCena
   FKTTEMP->STAWKA_VAT := cStawka
   FKTTEMP->WART_NETTO := nNetto
   FKTTEMP->KWOTA__VAT := nVat
   FKTTEMP->WAR_BRUTTO := nNetto + nVat
   FKTTEMP->DATA_____P := Date()

   oDialog:BRW:Refresh()
   s_Okno( oDialog, hFkt )

RETURN

STATIC PROCEDURE s_Naglowek( oDialog, oPanel, hFkt )

   LOCAL GetList  := {}
   LOCAL aWybor   := s_Wybor( oDialog )
   LOCAL dWyst    := hFkt[ "D_WYSTAWIE" ]
   LOCAL dSprz    := hFkt[ "D_SPRZEDAZ" ]
   LOCAL dTermin  := hFkt[ "TERMIN_PLA" ]
   LOCAL cKraj    := PadR( hFkt[ "KODKRAJ_OD" ], 2 )
   LOCAL cNip     := PadR( hFkt[ "NIP_ODBIOR" ], 20 )
   LOCAL cNazwa   := hFkt[ "NAZWA___OD" ]
   LOCAL cUlica   := PadR( hFkt[ "ULICA___OD" ], 60 )
   LOCAL cKod     := PadR( hFkt[ "KODPOCZ_OD" ], 6 )
   LOCAL cMiasto  := PadR( hFkt[ "MIEJSCE_OD" ], 40 )
   LOCAL oTermin
   LOCAL nGet

   AAdd( GetList, gui_Get():New( oPanel, 160,  34, NIL, NIL, @dWyst ) )
   AAdd( GetList, gui_Get():New( oPanel, 160,  64, NIL, NIL, @dSprz ) )
   AAdd( GetList, oDialog:PLAT_1 )
   AAdd( GetList, oDialog:PLAT_2 )
   AAdd( GetList, oDialog:PLAT_6 )
   oTermin := gui_Get():New( oPanel, 160, 124, NIL, NIL, @dTermin )
   AAdd( GetList, oTermin )
   AAdd( GetList, gui_Get():New( oPanel, 600,  4, NIL, NIL, @cKraj, "@! AA" ) )
   AAdd( GetList, gui_Get():New( oPanel, 636,  4,  20, NIL, @cNip ) )
   AAdd( GetList, gui_Get():New( oPanel, 600, 34,  40, NIL, @cNazwa, NIL, 4, 512 ) )
   AAdd( GetList, gui_Get():New( oPanel, 600, 64,  40, NIL, @cUlica ) )
   AAdd( GetList, gui_Get():New( oPanel, 600, 94, NIL, NIL, @cKod, "99-999" ) )
   AAdd( GetList, gui_Get():New( oPanel, 672, 94,  32, NIL, @cMiasto ) )
   AEval( aWybor, {| oWybor | oWybor:enabled := .T., oWybor:onChange := {|| oTermin:enabled := oDialog:PLAT_6:value } } )
   oTermin:enabled := oDialog:PLAT_6:value

   s_TrybEdycji( oDialog, .T. )
   oDialog:ReadModal( GetList )
   s_TrybEdycji( oDialog, .F. )

   AEval( aWybor, {| oWybor | oWybor:enabled := .F., oWybor:onChange := NIL } )
   FOR nGet := 1 TO Len( GetList )
      IF AScan( aWybor, {| oWybor | oWybor == GetList[ nGet ] } ) == 0
         GetList[ nGet ]:Destroy()
      ENDIF
   NEXT

   IF LastKey() != K_ESC
      hFkt[ "D_WYSTAWIE" ] := dWyst
      hFkt[ "D_SPRZEDAZ" ] := dSprz
      hFkt[ "FORMA_PLAT" ] := IIF( oDialog:PLAT_1:value, 1, IIF( oDialog:PLAT_2:value, 2, 6 ) )
      hFkt[ "TERMIN_PLA" ] := IIF( hFkt[ "FORMA_PLAT" ] == 6, dTermin, dWyst )
      hFkt[ "KODKRAJ_OD" ] := cKraj
      hFkt[ "NIP_ODBIOR" ] := cNip
      hFkt[ "NAZWA___OD" ] := AllTrim( cNazwa )
      hFkt[ "ULICA___OD" ] := cUlica
      hFkt[ "KODPOCZ_OD" ] := IIF( Empty( StrTran( cKod, "-" ) ), Space( 6 ), cKod )
      hFkt[ "MIEJSCE_OD" ] := cMiasto
   ENDIF

   s_Okno( oDialog, hFkt )

RETURN

STATIC PROCEDURE s_UsunPozycje( oDialog, hFkt )

   LOCAL nLp := 0

   IF FKTTEMP->( Eof() )
      RETURN
   ENDIF
   IF ! gui_MsgYesNo( "Usunąć pozycję" + Eol() + AllTrim( FKTTEMP->NAZWA_TOWA ) + "?", "Faktura" )
      RETURN
   ENDIF
   FKTTEMP->( dbDelete() )
   FKTTEMP->( DbPack() )
   FKTTEMP->( dbEval( {|| FKTTEMP->LP_FKT_ROW := ++nLp } ) )
   FKTTEMP->( dbGoTop() )
   oDialog:BRW:Refresh()
   s_Okno( oDialog, hFkt )

RETURN

STATIC PROCEDURE s_Zapisz( oDialog, hFkt )

   LOCAL nNr
   LOCAL nNetto := 0
   LOCAL nVat   := 0
   LOCAL lZw    := .F.

   IF Empty( hFkt[ "NAZWA___OD" ] )
      gui_MsgInfo( "Brak nabywcy: F12 z kartoteki albo F3 ręcznie.", "Faktura" )
      RETURN
   ENDIF
   IF FKTTEMP->( LastRec() ) == 0
      gui_MsgInfo( "Faktura nie ma pozycji: F2 dodaje pozycję.", "Faktura" )
      RETURN
   ENDIF
   FKTTEMP->( dbEval( {|| nNetto += FKTTEMP->WART_NETTO, nVat += FKTTEMP->KWOTA__VAT, ;
                          lZw := lZw .OR. AllTrim( FKTTEMP->STAWKA_VAT ) == "zw" } ) )
   IF lZw .AND. Empty( hFkt[ "ZWOLNIENIE" ] )
      gui_MsgInfo( "Pozycja ze stawką zw wymaga podstawy prawnej zwolnienia." + Eol() + ;
                   "Wpisz ją w Pliki - Ustawienia - Firma, zakładka Faktury.", "Faktura" )
      RETURN
   ENDIF

   dbSelectArea( "FKTHEAD" )
   IF ! NetAppBlank()
      RETURN
   ENDIF
   nNr := s_NastepnyNumer()
   FKTHEAD->NR_FAKTURY := nNr
   FKTHEAD->RODZAJ     := "FV"
   FKTHEAD->NUMER_FKT  := s_Numer( nNr )
   FKTHEAD->D_WYSTAWIE := hFkt[ "D_WYSTAWIE" ]
   FKTHEAD->D_SPRZEDAZ := hFkt[ "D_SPRZEDAZ" ]
   FKTHEAD->KODKRAJ_OD := hFkt[ "KODKRAJ_OD" ]
   FKTHEAD->NIP_ODBIOR := hFkt[ "NIP_ODBIOR" ]
   FKTHEAD->NAZWA___OD := hFkt[ "NAZWA___OD" ]
   FKTHEAD->ULICA___OD := hFkt[ "ULICA___OD" ]
   FKTHEAD->KODPOCZ_OD := hFkt[ "KODPOCZ_OD" ]
   FKTHEAD->MIEJSCE_OD := hFkt[ "MIEJSCE_OD" ]
   FKTHEAD->FORMA_PLAT := hFkt[ "FORMA_PLAT" ]
   FKTHEAD->TERMIN_PLA := hFkt[ "TERMIN_PLA" ]
   FKTHEAD->BANK____OD := hFkt[ "BANK____OD" ]
   FKTHEAD->KONTO___OD := hFkt[ "KONTO___OD" ]
   FKTHEAD->ZWOLNIENIE := IIF( lZw, hFkt[ "ZWOLNIENIE" ], "" )
   FKTHEAD->NETTO__FKT := nNetto
   FKTHEAD->KWOTA__VAT := nVat
   FKTHEAD->BRUTTO_FKT := nNetto + nVat
   FKTHEAD->DATA_____P := Date()
   dbCommit()
   dbUnlock()

   FKTTEMP->( dbGoTop() )
   DO WHILE ! FKTTEMP->( Eof() )
      dbSelectArea( "FKTROW" )
      IF NetAppBlank()
         FKTROW->NR_FAKTURY := nNr
         FKTROW->RODZAJ     := "FV"
         FKTROW->LP_FKT_ROW := FKTTEMP->LP_FKT_ROW
         FKTROW->KOD_TOWARU := FKTTEMP->KOD_TOWARU
         FKTROW->NAZWA_TOWA := FKTTEMP->NAZWA_TOWA
         FKTROW->JM_____FKT := FKTTEMP->JM_____FKT
         FKTROW->ILOSC__FKT := FKTTEMP->ILOSC__FKT
         FKTROW->CENA_JEDNO := FKTTEMP->CENA_JEDNO
         FKTROW->WART_NETTO := FKTTEMP->WART_NETTO
         FKTROW->STAWKA_VAT := FKTTEMP->STAWKA_VAT
         FKTROW->KWOTA__VAT := FKTTEMP->KWOTA__VAT
         FKTROW->WAR_BRUTTO := FKTTEMP->WAR_BRUTTO
         FKTROW->DATA_____P := Date()
         dbCommit()
         dbUnlock()
      ENDIF
      FKTTEMP->( dbSkip() )
   ENDDO

   gui_MsgInfo( "Zapisano fakturę " + s_Numer( nNr ) + Eol() + ;
                "Brutto: " + LTrim( Str( nNetto + nVat, 12, 2 ) ) + " zł", "Faktura" )
   oDialog:Close()

RETURN

STATIC PROCEDURE s_Nabywca( oDialog, hFkt )

   LOCAL hKontrahent := p_KontrahenciWybierz( oDialog )

   IF hKontrahent == NIL
      RETURN
   ENDIF
   hFkt[ "KODKRAJ_OD" ] := hKontrahent[ "KODKRAJU" ]
   hFkt[ "NIP_ODBIOR" ] := hKontrahent[ "NIP" ]
   hFkt[ "NAZWA___OD" ] := AllTrim( hKontrahent[ "NAZWA" ] )
   hFkt[ "ULICA___OD" ] := hKontrahent[ "ULICA" ]
   hFkt[ "KODPOCZ_OD" ] := hKontrahent[ "KODPOCZ" ]
   hFkt[ "MIEJSCE_OD" ] := hKontrahent[ "MIASTO" ]
   s_Okno( oDialog, hFkt )

RETURN

STATIC PROCEDURE s_Anuluj( oDialog )

   IF FKTTEMP->( LastRec() ) == 0 .OR. gui_MsgYesNo( "Zrezygnować z tej faktury?" + Eol() + "Pozycje nie zostaną zapisane.", "Faktura" )
      oDialog:Close()
   ENDIF

RETURN
