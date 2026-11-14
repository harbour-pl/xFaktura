/*
 * Copyright (c) 2026 xDev-Language
 *
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: fakturykor.prg
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "inkey.ch"
#include "hpdf.ch"
#include "xfaktura.ch"

PROCEDURE p_FakturyKor( oWindow )

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
   FKTHEAD->( dbSetFilter( {|| FKTHEAD->RODZAJ == "KOR" } ) )

   oDialog := gui_Dialog():New( oWindow, "Faktury korygujące " + Left( p_RokPobierz(), 4 ), 1000, 700 )
   oDialog:background := 0xe9edf1
   oDialog:sizable := .T.
   oDialog:SetKey( "Ins", {|| s_Nowa( oDialog ), s_Stan( oDialog, aZamroz ) } )

   oStatus := gui_StatusBar():New( oDialog )
   oStatus:name := "STATUS_BAR"
   oStatus:font := gui_Font():New( NIL, .F., .F., "xFont 9x18" )
   oStatus:Add( 0 )

   oToolbar := gui_Toolbar():New( oDialog, "Bottom" )
   oToolbar:name := "PASEK"
   oToolbar:Add( "F1-Pomoc",    NIL, {|| s_Pomoc( oDialog ) }, NIL, "F1" )
   oToolbar:AddSeparator()
   oToolbar:Add( "F2-Nowa",     NIL, {|| s_Nowa( oDialog ), s_Stan( oDialog, aZamroz ) }, NIL, "F2" )
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
   oToolbar:Add( "Esc-Zamknij", NIL, {|| oDialog:Close() }, NIL, "Esc" )

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
   oBrowse:AddColumn( PadR( "Numer", 14 ),        {|| Left( FKTHEAD->NUMER_FKT, 14 ) } )
   oBrowse:AddColumn( "Wystawiona",               {|| FKTHEAD->D_WYSTAWIE } )
   oBrowse:AddColumn( PadR( "Do faktury", 14 ),   {|| Left( FKTHEAD->KOR_NUMER, 14 ) } )
   oBrowse:AddColumn( PadR( "Nabywca", 30 ),      {|| StrTran( FKTHEAD->NAZWA___OD, Eol( FKTHEAD->NAZWA___OD ), " " ) }, 30 )
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

STATIC FUNCTION s_Tymczasowa()

   LOCAL cBaza := p_RokPobierz() + "kortemp"

   FErase( cBaza + ".dbf" )
   dbCreate( cBaza, p_PozycjeStruct() )
   dbSelectArea( 0 )

RETURN NetUse( cBaza, .T., NIL, "KORTEMP" )

STATIC FUNCTION s_NastepnyNumer()

   LOCAL nNr    := 0
   LOCAL nRecNo := FKTHEAD->( RecNo() )

   FKTHEAD->( dbEval( {|| nNr := Max( nNr, FKTHEAD->NR_FAKTURY ) }, {|| FKTHEAD->RODZAJ == "KOR" } ) )
   FKTHEAD->( dbGoto( nRecNo ) )

RETURN nNr + 1

STATIC FUNCTION s_Numer( nNr )
RETURN "KOR/" + LTrim( Str( nNr ) ) + "/" + Left( p_RokPobierz(), 4 )

/* ---------------------------------------------------------------------------------------------
   Przyciski
   --------------------------------------------------------------------------------------------- */

STATIC PROCEDURE s_Stan( oDialog, aZamroz )

   LOCAL lJest := p_FakturyJest()

   AEval( aZamroz, {| nPrzycisk | oDialog:PASEK:Enable( nPrzycisk, lJest ) } )
   oDialog:BRW:enabled := lJest
   oDialog:BRW:Refresh()

   IF lJest
      oDialog:BRW:SetFocus()
   ENDIF

RETURN

STATIC PROCEDURE s_Pomoc( oWindow )

   p_Pomoc( oWindow, "Faktury korygujące", ;
      Eol() + ;
      "F1             pomoc" + Eol() + ;
      "F2, Ins        nowa korekta: wybór faktury VAT, potem poprawa pozycji" + Eol() + ;
      "F3             podgląd korekty: pozycje przed korektą i po korekcie" + Eol() + ;
      "F5             wystawienie korekty w trybie offline" + Eol() + ;
      "F6             wysłanie korekty do KSeF" + Eol() + ;
      "F7             sprawdzenie korekty w KSeF i pobranie UPO" + Eol() + ;
      "F9             wydruk korekty do PDF w katalogu roku\wydruki" + Eol() + ;
      "Esc            zamknięcie okna" + Eol() + ;
      Eol() + ;
      "Okno korekty" + Eol() + ;
      Eol() + ;
      "Na starcie są pozycje faktury korygowanej. Popraw je tak," + Eol() + ;
      "jak powinny wyglądać po korekcie:" + Eol() + ;
      Eol() + ;
      "F2, Ins        nowa pozycja" + Eol() + ;
      "F4             poprawienie pozycji" + Eol() + ;
      "F8             usunięcie pozycji" + Eol() + ;
      "F10            zapis: przyczyna korekty, numer KOR/kolejny/rok" + Eol() + ;
      "Esc            rezygnacja z korekty" + Eol() + ;
      Eol() + ;
      "Program zapisuje stan przed korektą i po korekcie, a kwoty korekty" + Eol() + ;
      "to różnica między nimi. Ujemna kwota oznacza zwrot dla nabywcy." )

RETURN

STATIC PROCEDURE s_Nowa( oWindow )

   LOCAL nPowrot     := FKTHEAD->( RecNo() )
   LOCAL nKorygowana := s_Wybierz( oWindow )

   IF nKorygowana > 0
      s_Korekta( oWindow, nKorygowana )
      IF !( FKTHEAD->RODZAJ == "KOR" )
         FKTHEAD->( dbGoto( nPowrot ) )
         IF !( FKTHEAD->RODZAJ == "KOR" )
            FKTHEAD->( dbGoBottom() )
         ENDIF
      ENDIF
      oWindow:BRW:Refresh()
   ENDIF

RETURN

STATIC FUNCTION s_Wybierz( oWindow )

   LOCAL oDialog
   LOCAL oToolbar
   LOCAL oPanel
   LOCAL oBrowse
   LOCAL nWybor := 0

   dbSelectArea( 0 )
   IF ! NetUse( p_RokPobierz() + "fkthead", .F., NIL, "FKTWYBOR" )
      RETURN 0
   ENDIF
   FKTWYBOR->( dbSetFilter( {|| FKTWYBOR->RODZAJ == "FV " } ) )
   FKTWYBOR->( dbGoBottom() )
   IF FKTWYBOR->( Eof() )
      FKTWYBOR->( dbCloseArea() )
      gui_MsgInfo( "Brak faktur VAT do skorygowania.", "Faktura korygująca" )
      RETURN 0
   ENDIF

   oDialog := gui_Dialog():New( oWindow, "Wybierz fakturę VAT do korekty", 900, 560 )
   oDialog:background := 0xe9edf1
   oDialog:sizable := .T.

   oToolbar := gui_Toolbar():New( oDialog, "Bottom" )
   oToolbar:Add( "Enter-Wybierz", NIL, {|| nWybor := FKTWYBOR->( RecNo() ), oDialog:EndDialog( 1 ) }, NIL, "Enter" )
   oToolbar:AddSeparator()
   oToolbar:Add( "Esc-Rezygnuj", NIL, {|| oDialog:Close() }, NIL, "Esc" )

   oPanel := gui_Panel():New( oDialog )

   oBrowse := gui_Browse():New( oPanel, 10, 10, oPanel:width - 20, oPanel:height - 20 )
   oBrowse:headerBackground := 0x4d7326
   oBrowse:anchor           := "LTRB"
   oBrowse:goTopBlock       := {|| FKTWYBOR->( dbGoTop() ) }
   oBrowse:goBottomBlock    := {|| FKTWYBOR->( dbGoBottom() ) }
   oBrowse:skipBlock        := {| n | FKTWYBOR->( DbSkipper( n ) ) }
   oBrowse:positionBlock    := {|| FKTWYBOR->( IIF( LastRec() > 0, RecNo() / LastRec(), 0 ) ) }
   oBrowse:AddColumn( "W KSeF",                   {|| IIF( FKTWYBOR->KSEF_STAT == 2, "Tak", "Nie" ) } )
   oBrowse:AddColumn( PadR( "Numer", 14 ),        {|| Left( FKTWYBOR->NUMER_FKT, 14 ) } )
   oBrowse:AddColumn( "Wystawiona",               {|| FKTWYBOR->D_WYSTAWIE } )
   oBrowse:AddColumn( PadR( "Nabywca", 34 ),      {|| StrTran( FKTWYBOR->NAZWA___OD, Eol( FKTWYBOR->NAZWA___OD ), " " ) }, 34 )
   oBrowse:AddColumn( PadL( "Brutto", 12 ),       {|| FKTWYBOR->BRUTTO_FKT } )
   oBrowse:SetFocus()

   oDialog:Center()
   oDialog:ShowModal()

   FKTWYBOR->( dbCloseArea() )

RETURN nWybor

STATIC PROCEDURE s_Korekta( oWindow, nKorygowana )

   LOCAL oDialog
   LOCAL oStatus
   LOCAL oToolbar
   LOCAL oPanel
   LOCAL oBrowse
   LOCAL aZamroz := {}
   LOCAL hKor
   LOCAL cKlucz

   FKTHEAD->( dbClearFilter() )
   FKTHEAD->( dbGoto( nKorygowana ) )
   cKlucz := FKTHEAD->RODZAJ + Str( FKTHEAD->NR_FAKTURY, 6 )
   hKor := { "RECNO"  => nKorygowana, ;
             "KLUCZ"  => cKlucz, ;
             "NUMER"  => AllTrim( FKTHEAD->NUMER_FKT ), ;
             "DATA"   => FKTHEAD->D_WYSTAWIE, ;
             "KSEF"   => IIF( FKTHEAD->KSEF_STAT == 2, AllTrim( FKTHEAD->KSEF_NR ), "" ), ;
             "NABYWCA"=> StrTran( FKTHEAD->NAZWA___OD, Eol( FKTHEAD->NAZWA___OD ), " " ), ;
             "NETTO"  => FKTHEAD->NETTO__FKT, ;
             "VAT"    => FKTHEAD->KWOTA__VAT, ;
             "ZRODLO" => cKlucz, ;
             "PO"     => "" }
   FKTHEAD->( dbGoBottom() )
   DO WHILE ! FKTHEAD->( Bof() ) .AND. ! FKTHEAD->( Eof() )
      IF FKTHEAD->RODZAJ == "KOR" .AND. AllTrim( FKTHEAD->KOR_NUMER ) == hKor[ "NUMER" ]
         hKor[ "ZRODLO" ] := FKTHEAD->RODZAJ + Str( FKTHEAD->NR_FAKTURY, 6 )
         hKor[ "PO" ]     := AllTrim( FKTHEAD->NUMER_FKT )
         EXIT
      ENDIF
      FKTHEAD->( dbSkip( -1 ) )
   ENDDO
   FKTHEAD->( dbSetFilter( {|| FKTHEAD->RODZAJ == "KOR" } ) )

   IF ! s_Tymczasowa()
      RETURN
   ENDIF
   IF ! Empty( hKor[ "PO" ] )
      hKor[ "NETTO" ] := 0
      hKor[ "VAT" ]   := 0
   ENDIF
   FKTROW->( dbSeek( hKor[ "ZRODLO" ] ) )
   DO WHILE ! FKTROW->( Eof() ) .AND. FKTROW->RODZAJ + Str( FKTROW->NR_FAKTURY, 6 ) == hKor[ "ZRODLO" ]
      IF FKTROW->PRZED
         FKTROW->( dbSkip() )
         LOOP
      ENDIF
      IF ! Empty( hKor[ "PO" ] )
         hKor[ "NETTO" ] += FKTROW->WART_NETTO
         hKor[ "VAT" ]   += FKTROW->KWOTA__VAT
      ENDIF
      KORTEMP->( dbAppend() )
      KORTEMP->LP_FKT_ROW := KORTEMP->( LastRec() )
      KORTEMP->KOD_TOWARU := FKTROW->KOD_TOWARU
      KORTEMP->NAZWA_TOWA := FKTROW->NAZWA_TOWA
      KORTEMP->JM_____FKT := FKTROW->JM_____FKT
      KORTEMP->ILOSC__FKT := FKTROW->ILOSC__FKT
      KORTEMP->CENA_JEDNO := FKTROW->CENA_JEDNO
      KORTEMP->WART_NETTO := FKTROW->WART_NETTO
      KORTEMP->STAWKA_VAT := FKTROW->STAWKA_VAT
      KORTEMP->KWOTA__VAT := FKTROW->KWOTA__VAT
      KORTEMP->WAR_BRUTTO := FKTROW->WAR_BRUTTO
      FKTROW->( dbSkip() )
   ENDDO
   KORTEMP->( dbGoTop() )

   oDialog := gui_Dialog():New( oWindow, "Faktura korygująca do " + hKor[ "NUMER" ] + ;
                                IIF( Empty( hKor[ "PO" ] ), "", " - stan po korekcie " + hKor[ "PO" ] ), 1100, 700 )
   oDialog:background := 0xe9edf1
   oDialog:sizable := .T.
   oDialog:SetKey( "Ins", {|| s_Pozycja( oDialog, hKor, .T. ), s_StanKorekty( oDialog, aZamroz ) } )

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
   oToolbar:Add( "F2-Dodaj pozycję",            NIL, {|| s_Pozycja( oDialog, hKor, .T. ), s_StanKorekty( oDialog, aZamroz ) }, NIL, "F2" )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F4-Popraw",    NIL, {|| s_Pozycja( oDialog, hKor, .F. ) }, NIL, "F4" ) )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F8-Usuń",      NIL, {|| s_Usun( oDialog, hKor ), s_StanKorekty( oDialog, aZamroz ) }, NIL, "F8" ) )
   oToolbar:AddSeparator()
   oToolbar:Add( "F10-Zapisz",                  NIL, {|| s_Zapisz( oDialog, hKor ) }, NIL, "F10" )
   oToolbar:AddSeparator()
   oToolbar:Add( "Esc-Anuluj",                  NIL, {|| IIF( gui_MsgYesNo( "Zrezygnować z korekty?", "Faktura korygująca" ), oDialog:Close(), NIL ) }, NIL, "Esc" )

   oPanel := gui_Panel():New( oDialog )

   s_Opis( oPanel, 20,   7, "Numer korekty:" )
   s_Opis( oPanel, 20,  37, "Data wystawienia:" )
   s_Opis( oPanel, 20,  67, "Faktura korygowana:" )
   s_Opis( oPanel, 20,  97, "Numer KSeF:" )
   s_Opis( oPanel, 20, 127, "Nabywca:" )
   s_Pole( oPanel, 160,   4, 14, s_Numer( s_NastepnyNumer() ) )
   s_Pole( oPanel, 160,  34, 10, DToC( Date() ) )
   s_Pole( oPanel, 160,  64, 40, hKor[ "NUMER" ] + " z dnia " + DToC( hKor[ "DATA" ] ) )
   s_Pole( oPanel, 160,  94, 40, IIF( Empty( hKor[ "KSEF" ] ), "faktura poza KSeF", hKor[ "KSEF" ] ) )
   s_Pole( oPanel, 160, 124, 60, hKor[ "NABYWCA" ] )

   oBrowse := gui_Browse():New( oPanel, 10, 158, oPanel:width - 20, oPanel:height - 202 )
   oBrowse:name             := "BRW"
   oBrowse:headerBackground := 0x4d7326
   oBrowse:anchor           := "LTRB"
   oBrowse:goTopBlock       := {|| KORTEMP->( dbGoTop() ) }
   oBrowse:goBottomBlock    := {|| KORTEMP->( dbGoBottom() ) }
   oBrowse:skipBlock        := {| n | KORTEMP->( DbSkipper( n ) ) }
   oBrowse:positionBlock    := {|| KORTEMP->( IIF( LastRec() > 0, RecNo() / LastRec(), 0 ) ) }
   oBrowse:emptyBlock       := {|| KORTEMP->( LastRec() ) == 0 }
   oBrowse:AddColumn( "Lp",                                {|| KORTEMP->LP_FKT_ROW } )
   oBrowse:AddColumn( PadR( "Po korekcie: nazwa towaru / usługi", 36 ), {|| Left( KORTEMP->NAZWA_TOWA, 36 ) }, 36 )
   oBrowse:AddColumn( PadL( "Ilość", 12 ),                 {|| KORTEMP->ILOSC__FKT } )
   oBrowse:AddColumn( "J.m.",                              {|| Left( KORTEMP->JM_____FKT, 5 ) } )
   oBrowse:AddColumn( PadL( "Cena netto", 12 ),            {|| KORTEMP->CENA_JEDNO } )
   oBrowse:AddColumn( PadL( "Netto", 12 ),                 {|| KORTEMP->WART_NETTO } )
   oBrowse:AddColumn( "VAT",                               {|| KORTEMP->STAWKA_VAT } )
   oBrowse:AddColumn( PadL( "Kwota VAT", 12 ),             {|| KORTEMP->KWOTA__VAT } )
   oBrowse:AddColumn( PadL( "Brutto", 12 ),                {|| KORTEMP->WAR_BRUTTO } )
   oBrowse:OnChange := {|| s_Suma( oDialog, hKor ) }

   s_Pole( oPanel, 10, oPanel:height - 36, 100, "" ):name := "SUMA"
   oDialog:SUMA:anchor := "LB"

   s_Suma( oDialog, hKor )
   s_StanKorekty( oDialog, aZamroz )

   oDialog:Center()
   oDialog:ShowModal()

   KORTEMP->( dbCloseArea() )
   FErase( p_RokPobierz() + "kortemp.dbf" )

RETURN

STATIC PROCEDURE s_StanKorekty( oDialog, aZamroz )

   LOCAL lJest := KORTEMP->( LastRec() ) > 0

   AEval( aZamroz, {| nPrzycisk | oDialog:PASEK:Enable( nPrzycisk, lJest ) } )
   oDialog:BRW:enabled := lJest
   oDialog:BRW:Refresh()
   IF lJest
      oDialog:BRW:SetFocus()
   ENDIF

RETURN

STATIC PROCEDURE s_Suma( oDialog, hKor )

   LOCAL nNetto := 0
   LOCAL nVat   := 0
   LOCAL nRecNo := KORTEMP->( RecNo() )

   KORTEMP->( dbEval( {|| nNetto += KORTEMP->WART_NETTO, nVat += KORTEMP->KWOTA__VAT } ) )
   KORTEMP->( dbGoto( nRecNo ) )
   nNetto -= hKor[ "NETTO" ]
   nVat   -= hKor[ "VAT" ]
   oDialog:SUMA:text := " Zmiana po korekcie:     Netto: " + LTrim( Str( nNetto, 12, 2 ) ) + ;
                        "     VAT: " + LTrim( Str( nVat, 12, 2 ) ) + ;
                        "     Brutto: " + LTrim( Str( nNetto + nVat, 12, 2 ) )

RETURN

STATIC PROCEDURE s_Pozycja( oDialog, hKor, lNowa )

   LOCAL GetList := {}
   LOCAL oOkno
   LOCAL nRecNo  := KORTEMP->( RecNo() )
   LOCAL cNazwa
   LOCAL nIlosc
   LOCAL cJm
   LOCAL nCena
   LOCAL cStawka
   LOCAL nNetto
   LOCAL nVat

   IF ! lNowa .AND. KORTEMP->( Eof() )
      RETURN
   ENDIF
   IF lNowa
      KORTEMP->( dbGoBottom() )
      KORTEMP->( dbSkip() )
   ENDIF
   cNazwa  := KORTEMP->NAZWA_TOWA
   nIlosc  := IIF( lNowa, 1, KORTEMP->ILOSC__FKT )
   cJm     := IIF( lNowa, PadR( "szt.", Len( KORTEMP->JM_____FKT ) ), KORTEMP->JM_____FKT )
   nCena   := KORTEMP->CENA_JEDNO
   cStawka := PadR( IIF( lNowa, "23", AllTrim( KORTEMP->STAWKA_VAT ) ), 2 )

   oOkno := gui_Dialog():New( oDialog, "Pozycja po korekcie", 640, 200 )
   oOkno:background := 0xe9edf1

   s_Opis( oOkno, 20,  23, "Nazwa:" )
   s_Opis( oOkno, 20,  53, "Ilość / j.m.:" )
   s_Opis( oOkno, 20,  83, "Cena netto:" )
   s_Opis( oOkno, 20, 113, "Stawka VAT:" )

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
   oDialog:BRW:enabled   := KORTEMP->( LastRec() ) > 0

   IF LastKey() == K_ESC .OR. Empty( cNazwa )
      KORTEMP->( dbGoto( nRecNo ) )
      s_Suma( oDialog, hKor )
      RETURN
   ENDIF
   IF s_Stawka( cStawka ) == NIL
      gui_MsgInfo( "Nieznana stawka VAT: " + AllTrim( cStawka ) + Eol() + "Dozwolone: 23, 22, 8, 7, 5, 4, 3, 0, zw, oo, np", "Faktura korygująca" )
      KORTEMP->( dbGoto( nRecNo ) )
      s_Suma( oDialog, hKor )
      RETURN
   ENDIF
   cStawka := s_Stawka( cStawka )
   nNetto  := Round( nIlosc * nCena, 2 )
   nVat    := IIF( IsDigit( cStawka ), Round( nNetto * Val( cStawka ) / 100, 2 ), 0 )

   IF lNowa
      KORTEMP->( dbAppend() )
      KORTEMP->LP_FKT_ROW := KORTEMP->( LastRec() )
   ENDIF
   KORTEMP->NAZWA_TOWA := cNazwa
   KORTEMP->ILOSC__FKT := nIlosc
   KORTEMP->JM_____FKT := cJm
   KORTEMP->CENA_JEDNO := nCena
   KORTEMP->STAWKA_VAT := cStawka
   KORTEMP->WART_NETTO := nNetto
   KORTEMP->KWOTA__VAT := nVat
   KORTEMP->WAR_BRUTTO := nNetto + nVat

   oDialog:BRW:Refresh()
   s_Suma( oDialog, hKor )

RETURN

STATIC PROCEDURE s_Usun( oDialog, hKor )

   LOCAL nLp := 0

   IF KORTEMP->( Eof() ) .OR. ! gui_MsgYesNo( "Usunąć pozycję " + AllTrim( KORTEMP->NAZWA_TOWA ) + "?", "Faktura korygująca" )
      RETURN
   ENDIF
   KORTEMP->( dbDelete() )
   KORTEMP->( DbPack() )
   KORTEMP->( dbEval( {|| KORTEMP->LP_FKT_ROW := ++nLp } ) )
   KORTEMP->( dbGoTop() )
   oDialog:BRW:Refresh()
   s_Suma( oDialog, hKor )

RETURN

STATIC PROCEDURE s_Zapisz( oDialog, hKor )

   LOCAL nNr
   LOCAL nNetto := 0
   LOCAL nVat   := 0
   LOCAL lZw    := .F.
   LOCAL cPowod
   LOCAL aPrzed := {}
   LOCAL aPoz
   LOCAL nLp
   LOCAL hFirma
   LOCAL hGlowa := { => }
   LOCAL cPole

   KORTEMP->( dbEval( {|| nNetto += KORTEMP->WART_NETTO, nVat += KORTEMP->KWOTA__VAT, ;
                          lZw := lZw .OR. AllTrim( KORTEMP->STAWKA_VAT ) == "zw" } ) )
   IF nNetto == hKor[ "NETTO" ] .AND. nVat == hKor[ "VAT" ] .AND. ;
      ! gui_MsgYesNo( "Korekta nie zmienia kwot faktury." + Eol() + "Zapisać ją mimo to?", "Faktura korygująca" )
      RETURN
   ENDIF
   cPowod := s_Powod( oDialog )
   IF cPowod == NIL
      RETURN
   ENDIF

   FKTHEAD->( dbClearFilter() )
   FKTHEAD->( dbGoto( hKor[ "RECNO" ] ) )
   FOR EACH cPole IN { "D_SPRZEDAZ", "KODKRAJ_OD", "NIP_ODBIOR", "NAZWA___OD", "ULICA___OD", "KODPOCZ_OD", ;
                       "MIEJSCE_OD", "FORMA_PLAT", "TERMIN_PLA", "BANK____OD", "KONTO___OD", "ZWOLNIENIE" }
      hGlowa[ cPole ] := FKTHEAD->( FieldGet( FieldPos( cPole ) ) )
   NEXT
   IF lZw .AND. Empty( hGlowa[ "ZWOLNIENIE" ] )
      hFirma := p_FirmaPobierzDane()
      hGlowa[ "ZWOLNIENIE" ] := IIF( hFirma == NIL, "", AllTrim( hFirma[ "ZWOLNIENIE" ] ) )
      IF Empty( hGlowa[ "ZWOLNIENIE" ] )
         FKTHEAD->( dbSetFilter( {|| FKTHEAD->RODZAJ == "KOR" } ) )
         gui_MsgInfo( "Pozycja ze stawką zw wymaga podstawy prawnej zwolnienia." + Eol() + ;
                      "Wpisz ją w Pliki - Ustawienia - Firma, zakładka Faktury.", "Faktura korygująca" )
         RETURN
      ENDIF
   ENDIF

   FKTROW->( dbSeek( hKor[ "ZRODLO" ] ) )
   DO WHILE ! FKTROW->( Eof() ) .AND. FKTROW->RODZAJ + Str( FKTROW->NR_FAKTURY, 6 ) == hKor[ "ZRODLO" ]
      IF FKTROW->PRZED
         FKTROW->( dbSkip() )
         LOOP
      ENDIF
      AAdd( aPrzed, { FKTROW->KOD_TOWARU, FKTROW->NAZWA_TOWA, FKTROW->JM_____FKT, FKTROW->ILOSC__FKT, ;
                      FKTROW->CENA_JEDNO, FKTROW->WART_NETTO, FKTROW->STAWKA_VAT, FKTROW->KWOTA__VAT, FKTROW->WAR_BRUTTO } )
      FKTROW->( dbSkip() )
   ENDDO

   nNr := s_NastepnyNumer()
   dbSelectArea( "FKTHEAD" )
   IF ! NetAppBlank()
      FKTHEAD->( dbSetFilter( {|| FKTHEAD->RODZAJ == "KOR" } ) )
      RETURN
   ENDIF
   FKTHEAD->NR_FAKTURY := nNr
   FKTHEAD->RODZAJ     := "KOR"
   FKTHEAD->NUMER_FKT  := s_Numer( nNr )
   FKTHEAD->D_WYSTAWIE := Date()
   FOR EACH cPole IN hGlowa
      FKTHEAD->( FieldPut( FieldPos( cPole:enumKey ), cPole ) )
   NEXT
   FKTHEAD->KOR_NUMER  := hKor[ "NUMER" ]
   FKTHEAD->KOR_DATA   := hKor[ "DATA" ]
   FKTHEAD->KOR_KSEF   := hKor[ "KSEF" ]
   FKTHEAD->KOR_PRZYCZ := cPowod
   FKTHEAD->NETTO__FKT := nNetto - hKor[ "NETTO" ]
   FKTHEAD->KWOTA__VAT := nVat - hKor[ "VAT" ]
   FKTHEAD->BRUTTO_FKT := nNetto + nVat - hKor[ "NETTO" ] - hKor[ "VAT" ]
   FKTHEAD->DATA_____P := Date()
   dbCommit()
   dbUnlock()

   FOR nLp := 1 TO Len( aPrzed )
      aPoz := aPrzed[ nLp ]
      dbSelectArea( "FKTROW" )
      IF NetAppBlank()
         FKTROW->NR_FAKTURY := nNr
         FKTROW->RODZAJ     := "KOR"
         FKTROW->LP_FKT_ROW := nLp
         FKTROW->KOD_TOWARU := aPoz[ 1 ]
         FKTROW->NAZWA_TOWA := aPoz[ 2 ]
         FKTROW->JM_____FKT := aPoz[ 3 ]
         FKTROW->ILOSC__FKT := aPoz[ 4 ]
         FKTROW->CENA_JEDNO := aPoz[ 5 ]
         FKTROW->WART_NETTO := aPoz[ 6 ]
         FKTROW->STAWKA_VAT := aPoz[ 7 ]
         FKTROW->KWOTA__VAT := aPoz[ 8 ]
         FKTROW->WAR_BRUTTO := aPoz[ 9 ]
         FKTROW->PRZED      := .T.
         FKTROW->DATA_____P := Date()
         dbCommit()
         dbUnlock()
      ENDIF
   NEXT

   KORTEMP->( dbGoTop() )
   DO WHILE ! KORTEMP->( Eof() )
      dbSelectArea( "FKTROW" )
      IF NetAppBlank()
         FKTROW->NR_FAKTURY := nNr
         FKTROW->RODZAJ     := "KOR"
         FKTROW->LP_FKT_ROW := Len( aPrzed ) + KORTEMP->LP_FKT_ROW
         FKTROW->KOD_TOWARU := KORTEMP->KOD_TOWARU
         FKTROW->NAZWA_TOWA := KORTEMP->NAZWA_TOWA
         FKTROW->JM_____FKT := KORTEMP->JM_____FKT
         FKTROW->ILOSC__FKT := KORTEMP->ILOSC__FKT
         FKTROW->CENA_JEDNO := KORTEMP->CENA_JEDNO
         FKTROW->WART_NETTO := KORTEMP->WART_NETTO
         FKTROW->STAWKA_VAT := KORTEMP->STAWKA_VAT
         FKTROW->KWOTA__VAT := KORTEMP->KWOTA__VAT
         FKTROW->WAR_BRUTTO := KORTEMP->WAR_BRUTTO
         FKTROW->PRZED      := .F.
         FKTROW->DATA_____P := Date()
         dbCommit()
         dbUnlock()
      ENDIF
      KORTEMP->( dbSkip() )
   ENDDO

   FKTHEAD->( dbSetFilter( {|| FKTHEAD->RODZAJ == "KOR" } ) )
   FKTHEAD->( dbGoBottom() )

   gui_MsgInfo( "Zapisano fakturę korygującą " + s_Numer( nNr ) + Eol() + ;
                "Zmiana brutto: " + LTrim( Str( nNetto + nVat - hKor[ "NETTO" ] - hKor[ "VAT" ], 12, 2 ) ) + " zł", "Faktura korygująca" )
   oDialog:Close()

RETURN

STATIC FUNCTION s_Powod( oWindow )

   LOCAL oPytanie
   LOCAL oTekst
   LOCAL oOk
   LOCAL oAnuluj
   LOCAL cPowod := NIL

   oPytanie := gui_Dialog():New( oWindow, "Faktura korygująca", 520, 120 )
   oPytanie:Center()

   gui_Say():New( oPytanie, 10, 12, 50, 20, "Przyczyna korekty, np. zwrot towaru, błędna cena:" )

   oTekst  := gui_Edit():New( oPytanie, 10, 36, 500 )

   oOk     := gui_Button():New( oPytanie, 320, 76, 90, 28, "OK" )
   oAnuluj := gui_Button():New( oPytanie, 420, 76, 90, 28, "Anuluj" )

   oOk:isDefault    := .T.
   oOk:onClick      := {|| cPowod := AllTrim( oTekst:value ), oPytanie:EndDialog( 1 ) }
   oAnuluj:isCancel := .T.
   oAnuluj:onClick  := {|| oPytanie:EndDialog( 0 ) }

   oPytanie:ShowModal()

RETURN cPowod

STATIC PROCEDURE s_Opis( oPanel, nX, nY, cText )

   gui_Say():New( oPanel, nX, nY, 15, 20, cText )

RETURN

STATIC FUNCTION s_Pole( oPanel, nX, nY, nLen, cText )

   LOCAL oSay := gui_Say():New( oPanel, nX, nY, nLen, 24, cText )

   oSay:border := .T.

RETURN oSay

STATIC PROCEDURE s_TrybEdycji( oDialog, lWlacz )

   IF lWlacz
      oDialog:STATUS_BAR:text := " Tryb edycji --> PgUp PgDn Enter = zapisz, Esc = bez zapisu"
      oDialog:STATUS_BAR:background := 0x73264d
      oDialog:STATUS_BAR:foreground := 0xffffff
   ELSE
      oDialog:STATUS_BAR:text       := ""
      oDialog:STATUS_BAR:background := NIL
      oDialog:STATUS_BAR:foreground := NIL
   ENDIF

RETURN

STATIC FUNCTION s_Stawka( cStawka )

   LOCAL cJest := Lower( AllTrim( cStawka ) )

RETURN IIF( AScan( { "23", "22", "8", "7", "5", "4", "3", "0", "zw", "oo", "np" }, {| c | c == cJest } ) > 0, cJest, NIL )

/* ---------------------------------------------------------------------------------------------
   Wydruki
   --------------------------------------------------------------------------------------------- */

FUNCTION p_FakturyKorPdf( cPlik, hFirma )

   LOCAL aKolumna := { 40, 60, 245, 290, 320, 380, 440, 470, 515, 555 }
   LOCAL aTytul   := { "Lp", "Nazwa towaru / usługi", "Ilość", "J.m.", "Cena netto", "Netto", "VAT", "Kwota VAT", "Brutto" }
   LOCAL aPrawo   := { .T., .F., .T., .F., .T., .T., .T., .T., .T. }
   LOCAL cKlucz   := FKTHEAD->RODZAJ + Str( FKTHEAD->NR_FAKTURY, 6 )
   LOCAL cTytul   := "Faktura korygująca " + AllTrim( FKTHEAD->NUMER_FKT )
   LOCAL hStawki  := { => }
   LOCAL pPdf     := HPDF_New()
   LOCAL pFont
   LOCAL pBold
   LOCAL pPage
   LOCAL nY
   LOCAL nStrona  := 1
   LOCAL nSekcja  := 0
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
   pFont := HPDF_GetFont( pPdf, HPDF_LoadTTFontFromFile( pPdf, GetEnv( "WINDIR" ) + "\Fonts\arial.ttf", HPDF_TRUE ), "UTF-8" )
   pBold := HPDF_GetFont( pPdf, HPDF_LoadTTFontFromFile( pPdf, GetEnv( "WINDIR" ) + "\Fonts\arialbd.ttf", HPDF_TRUE ), "UTF-8" )

   pPage := HPDF_AddPage( pPdf )
   HPDF_Page_SetSize( pPage, HPDF_PAGE_SIZE_A4, HPDF_PAGE_PORTRAIT )
   p_WydrukUstawZnaki( pPage, pFont )

   p_WydrukPrawo( pPage, pBold, 16, 555, 800, cTytul )
   p_WydrukPrawo( pPage, pFont, 9, 555, 784, "Data wystawienia: " + DToC( FKTHEAD->D_WYSTAWIE ) )
   IF ! Empty( FKTHEAD->KSEF_NR )
      p_WydrukPrawo( pPage, pFont, 9, 555, 772, "Numer KSeF: " + AllTrim( FKTHEAD->KSEF_NR ) )
   ENDIF

   cAdres := AllTrim( hFirma[ "ULICAFIRMY" ] ) + " " + AllTrim( hFirma[ "NRDOMUFIRM" ] ) + ;
             IIF( Empty( hFirma[ "NRLOKALUFI" ] ), "", "/" + AllTrim( hFirma[ "NRLOKALUFI" ] ) )
   p_WydrukStrona( pPage, pFont, pBold, 40, 730, "Sprzedawca", hFirma[ "NAZWAFIRMY" ], ;
                   { AllTrim( cAdres ), AllTrim( hFirma[ "KODPOCZ" ] + " " + hFirma[ "MIASTO" ] ) }, ;
                   AllTrim( hFirma[ "NIP__FIRMY" ] ) )
   p_WydrukStrona( pPage, pFont, pBold, 310, 730, "Nabywca", FKTHEAD->NAZWA___OD, ;
                   { AllTrim( FKTHEAD->ULICA___OD ), AllTrim( FKTHEAD->KODPOCZ_OD + " " + FKTHEAD->MIEJSCE_OD ) }, ;
                   IIF( Empty( FKTHEAD->NIP_ODBIOR ), "", IIF( FKTHEAD->KODKRAJ_OD == "PL", "", FKTHEAD->KODKRAJ_OD ) + AllTrim( FKTHEAD->NIP_ODBIOR ) ) )

   p_WydrukTekst( pPage, pFont, 9, 40, 632, "Korekta faktury " + AllTrim( FKTHEAD->KOR_NUMER ) + " z dnia " + DToC( FKTHEAD->KOR_DATA ) + ;
                  IIF( Empty( FKTHEAD->KOR_KSEF ), "", ", numer KSeF " + AllTrim( FKTHEAD->KOR_KSEF ) ), 515 )
   p_WydrukTekst( pPage, pFont, 9, 40, 619, "Przyczyna korekty: " + AllTrim( FKTHEAD->KOR_PRZYCZ ), 515 )

   nY := 596
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
      IF nSekcja != IIF( FKTROW->PRZED, 1, 2 )
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
      hStawki[ cStawka ][ 1 ] += IIF( FKTROW->PRZED, -1, 1 ) * FKTROW->WART_NETTO
      hStawki[ cStawka ][ 2 ] += IIF( FKTROW->PRZED, -1, 1 ) * FKTROW->KWOTA__VAT
      hStawki[ cStawka ][ 3 ] += IIF( FKTROW->PRZED, -1, 1 ) * FKTROW->WAR_BRUTTO

      nY -= 15
      FKTROW->( dbSkip() )
   ENDDO

   nY -= 8
   p_WydrukPasek( pPage, pBold, nY, { 320, 440, 470, 515, 555 }, { "Zmiana", "VAT", "Kwota VAT", "Brutto" }, { .F., .T., .T., .T. } )
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

RETURN lZapis
