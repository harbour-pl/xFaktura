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
   p_FakturyZakres( "KOR" )

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
   oBrowse:positionBlock    := {|| FKTHEAD->( IIF( ordKeyCount() > 0, ordKeyNo() / ordKeyCount(), 0 ) ) }
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
   FErase( cBaza + ".dbt" )
   dbCreate( cBaza, p_PozycjeStruct() )
   dbSelectArea( 0 )

RETURN NetUse( cBaza, .T., NIL, "KORTEMP" )

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
      "F2, Ins        nowa korekta: wybór roku i faktury VAT, potem poprawa pozycji;" + Eol() + ;
      "               korekta dostaje dzisiejszą datę i numer w bieżącym roku" + Eol() + ;
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

   LOCAL cRok
   LOCAL nKorygowana

   IF ! s_RokBiezacy( Date() )
      RETURN
   ENDIF
   cRok := p_RokWybierz( oWindow, "Rok faktury korygowanej", .T. )
   IF Empty( cRok )
      RETURN
   ENDIF
   cRok += DirSepToOS( "\" )
   nKorygowana := s_Wybierz( oWindow, cRok )
   IF nKorygowana > 0
      s_Korekta( oWindow, cRok, nKorygowana )
      oWindow:BRW:Refresh()
   ENDIF

RETURN

STATIC FUNCTION s_Wybierz( oWindow, cRok )

   LOCAL oDialog
   LOCAL oToolbar
   LOCAL oPanel
   LOCAL oBrowse
   LOCAL nWybor := 0

   dbSelectArea( 0 )
   IF ! NetUse( cRok + "fkthead", .F., NIL, "FKTWYBOR" )
      RETURN 0
   ENDIF
   FKTWYBOR->( dbSetFilter( {|| FKTWYBOR->RODZAJ == "FV " } ) )
   FKTWYBOR->( dbGoBottom() )
   IF FKTWYBOR->( Eof() )
      FKTWYBOR->( dbCloseArea() )
      gui_MsgInfo( "Brak faktur VAT do skorygowania w roku " + Left( cRok, 4 ) + ".", "Faktura korygująca" )
      RETURN 0
   ENDIF

   oDialog := gui_Dialog():New( oWindow, "Wybierz fakturę VAT do korekty - rok " + Left( cRok, 4 ), 900, 560 )
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
   oBrowse:AddColumn( "W KSeF",                   {|| IIF( FKTWYBOR->KSEF_STAT == KSEF_PRZYJETA, "Tak", "Nie" ) } )
   oBrowse:AddColumn( PadR( "Numer", 14 ),        {|| Left( FKTWYBOR->NUMER_FKT, 14 ) } )
   oBrowse:AddColumn( "Wystawiona",               {|| FKTWYBOR->D_WYSTAWIE } )
   oBrowse:AddColumn( PadR( "Nabywca", 34 ),      {|| StrTran( FKTWYBOR->NAZWA___OD, Eol( FKTWYBOR->NAZWA___OD ), " " ) }, 34 )
   oBrowse:AddColumn( PadL( "Brutto", 12 ),       {|| FKTWYBOR->BRUTTO_FKT } )
   oBrowse:SetFocus()

   oDialog:Center()
   oDialog:ShowModal()

   FKTWYBOR->( dbCloseArea() )

RETURN nWybor

STATIC PROCEDURE s_Korekta( oWindow, cRok, nKorygowana )

   LOCAL oDialog
   LOCAL oStatus
   LOCAL oToolbar
   LOCAL oPanel
   LOCAL oBrowse
   LOCAL aZamroz := {}
   LOCAL hKor
   LOCAL aOstatnia
   LOCAL aPoz
   LOCAL bOdswiez

   dbSelectArea( 0 )
   IF ! NetUse( cRok + "fkthead", .F., NIL, "FKTHEAD_ZRODLO" )
      RETURN
   ENDIF
   FKTHEAD_ZRODLO->( dbGoto( nKorygowana ) )
   hKor := { "ROK"    => cRok, ;
             "RECNO"  => nKorygowana, ;
             "NUMER"  => AllTrim( FKTHEAD_ZRODLO->NUMER_FKT ), ;
             "DATA"   => FKTHEAD_ZRODLO->D_WYSTAWIE, ;
             "KSEF"   => IIF( FKTHEAD_ZRODLO->KSEF_STAT == KSEF_PRZYJETA, AllTrim( FKTHEAD_ZRODLO->KSEF_NR ), "" ), ;
             "NABYWCA"=> StrTran( FKTHEAD_ZRODLO->NAZWA___OD, Eol( FKTHEAD_ZRODLO->NAZWA___OD ), " " ), ;
             "NETTO"  => FKTHEAD_ZRODLO->NETTO__FKT, ;
             "VAT"    => FKTHEAD_ZRODLO->KWOTA__VAT, ;
             "PO"     => "", ;
             "POZYCJE"=> NIL }

   aOstatnia := s_OstatniaKorekta( p_RokPobierz(), hKor[ "NUMER" ] )
   IF aOstatnia == NIL .AND. !( cRok == p_RokPobierz() )
      aOstatnia := s_OstatniaKorekta( cRok, hKor[ "NUMER" ] )
   ENDIF
   IF aOstatnia == NIL
      hKor[ "POZYCJE" ] := s_PozycjeZrodla( cRok, FKTHEAD_ZRODLO->RODZAJ + Str( FKTHEAD_ZRODLO->NR_FAKTURY, 6 ) )
   ELSE
      hKor[ "PO" ]      := aOstatnia[ 3 ]
      hKor[ "POZYCJE" ] := s_PozycjeZrodla( aOstatnia[ 1 ], aOstatnia[ 2 ] )
   ENDIF
   IF hKor[ "POZYCJE" ] == NIL
      FKTHEAD_ZRODLO->( dbCloseArea() )
      RETURN
   ENDIF

   IF ! s_Tymczasowa()
      FKTHEAD_ZRODLO->( dbCloseArea() )
      RETURN
   ENDIF
   IF ! Empty( hKor[ "PO" ] )
      hKor[ "NETTO" ] := 0
      hKor[ "VAT" ]   := 0
   ENDIF
   FOR EACH aPoz IN hKor[ "POZYCJE" ]
      IF ! Empty( hKor[ "PO" ] )
         hKor[ "NETTO" ] += aPoz[ 6 ]
         hKor[ "VAT" ]   += aPoz[ 8 ]
      ENDIF
      KORTEMP->( dbAppend() )
      KORTEMP->LP_FKT_ROW := KORTEMP->( LastRec() )
      KORTEMP->KOD_TOWARU := aPoz[ 1 ]
      KORTEMP->NAZWA_TOWA := aPoz[ 2 ]
      KORTEMP->JM_____FKT := aPoz[ 3 ]
      KORTEMP->ILOSC__FKT := aPoz[ 4 ]
      KORTEMP->CENA_JEDNO := aPoz[ 5 ]
      KORTEMP->WART_NETTO := aPoz[ 6 ]
      KORTEMP->STAWKA_VAT := aPoz[ 7 ]
      KORTEMP->KWOTA__VAT := aPoz[ 8 ]
      KORTEMP->WAR_BRUTTO := aPoz[ 9 ]
   NEXT
   KORTEMP->( dbGoTop() )

   oDialog := gui_Dialog():New( oWindow, "Faktura korygująca do " + hKor[ "NUMER" ] + ;
                                IIF( Empty( hKor[ "PO" ] ), "", " - stan po korekcie " + hKor[ "PO" ] ), 1100, 700 )
   oDialog:background := 0xe9edf1
   oDialog:sizable := .T.
   bOdswiez := {|| s_Suma( oDialog, hKor ) }
   oDialog:SetKey( "Ins", {|| s_Pozycja( oDialog, .T., bOdswiez ), s_StanKorekty( oDialog, aZamroz ) } )

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
   oToolbar:Add( "F2-Dodaj pozycję",            NIL, {|| s_Pozycja( oDialog, .T., bOdswiez ), s_StanKorekty( oDialog, aZamroz ) }, NIL, "F2" )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F4-Popraw",    NIL, {|| s_Pozycja( oDialog, .F., bOdswiez ) }, NIL, "F4" ) )
   oToolbar:AddSeparator()
   AAdd( aZamroz, oToolbar:Add( "F8-Usuń",      NIL, {|| p_PozycjeUsun( oDialog, "KORTEMP", "Faktura korygująca", bOdswiez ), s_StanKorekty( oDialog, aZamroz ) }, NIL, "F8" ) )
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
   s_Pole( oPanel, 160,   4, 14, s_Numer( p_FakturyNastepnyNumer( "KOR" ) ) )
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
   oBrowse:AddColumn( PadR( "Po korekcie: nazwa towaru / usługi", 36 ), {|| ULeft( KORTEMP->NAZWA_TOWA, 36 ) }, 36 )
   oBrowse:AddColumn( PadL( "Ilość", 12 ),                 {|| KORTEMP->ILOSC__FKT } )
   oBrowse:AddColumn( "J.m.",                              {|| ULeft( KORTEMP->JM_____FKT, 5 ) } )
   oBrowse:AddColumn( PadL( "Cena netto", 12 ),            {|| KORTEMP->CENA_JEDNO } )
   oBrowse:AddColumn( PadL( "Netto", 12 ),                 {|| KORTEMP->WART_NETTO } )
   oBrowse:AddColumn( "VAT",                               {|| KORTEMP->STAWKA_VAT } )
   oBrowse:AddColumn( PadL( "Kwota VAT", 12 ),             {|| KORTEMP->KWOTA__VAT } )
   oBrowse:AddColumn( PadL( "Brutto", 12 ),                {|| KORTEMP->WAR_BRUTTO } )
   oBrowse:OnChange := bOdswiez

   s_Pole( oPanel, 10, oPanel:height - 36, 100, "" ):name := "SUMA"
   oDialog:SUMA:anchor := "LB"

   s_Suma( oDialog, hKor )
   s_StanKorekty( oDialog, aZamroz )

   oDialog:Center()
   oDialog:ShowModal()

   KORTEMP->( dbCloseArea() )
   FErase( p_RokPobierz() + "kortemp.dbf" )
   FErase( p_RokPobierz() + "kortemp.dbt" )
   FKTHEAD_ZRODLO->( dbCloseArea() )

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

   LOCAL nNetto
   LOCAL nVat

   p_PozycjeSuma( "KORTEMP", @nNetto, @nVat )
   nNetto -= hKor[ "NETTO" ]
   nVat   -= hKor[ "VAT" ]
   oDialog:SUMA:text := " Zmiana po korekcie:     Netto: " + LTrim( Str( nNetto, 12, 2 ) ) + ;
                        "     VAT: " + LTrim( Str( nVat, 12, 2 ) ) + ;
                        "     Brutto: " + LTrim( Str( nNetto + nVat, 12, 2 ) )

RETURN

STATIC PROCEDURE s_Pozycja( oDialog, lNowa, bOdswiez )

   p_PozycjeEdytuj( oDialog, "KORTEMP", lNowa, "Pozycja po korekcie", "Faktura korygująca", .T., bOdswiez )

RETURN

STATIC PROCEDURE s_Zapisz( oDialog, hKor )

   LOCAL nNr
   LOCAL nNetto
   LOCAL nVat
   LOCAL lZw
   LOCAL cPowod
   LOCAL aPrzed
   LOCAL aDodane := {}
   LOCAL aPoz
   LOCAL nLp
   LOCAL hFirma
   LOCAL hGlowa  := { => }
   LOCAL cPole
   LOCAL lOkay   := .T.
   LOCAL dWyst   := Date()

   IF ! s_RokBiezacy( dWyst )
      RETURN
   ENDIF
   IF ! p_PozycjeSuma( "KORTEMP", @nNetto, @nVat, @lZw )
      gui_MsgInfo( "Wartość faktury musi być mniejsza niż 1 000 000 000.", "Faktura korygująca" )
      RETURN
   ENDIF
   IF nNetto == hKor[ "NETTO" ] .AND. nVat == hKor[ "VAT" ] .AND. ;
      ! gui_MsgYesNo( "Korekta nie zmienia kwot faktury." + Eol() + "Zapisać ją mimo to?", "Faktura korygująca" )
      RETURN
   ENDIF
   cPowod := s_Powod( oDialog )
   IF cPowod == NIL
      RETURN
   ENDIF

   FKTHEAD_ZRODLO->( dbGoto( hKor[ "RECNO" ] ) )
   FOR EACH cPole IN { "D_SPRZEDAZ", "KODKRAJ_OD", "NIP_ODBIOR", "NAZWA___OD", "ULICA___OD", "KODPOCZ_OD", ;
                       "MIEJSCE_OD", "FORMA_PLAT", "TERMIN_PLA", "BANK____OD", "KONTO___OD", "ZWOLNIENIE" }
      hGlowa[ cPole ] := FKTHEAD_ZRODLO->( FieldGet( FieldPos( cPole ) ) )
   NEXT
   IF lZw .AND. Empty( hGlowa[ "ZWOLNIENIE" ] )
      hFirma := p_FirmaPobierzDane()
      hGlowa[ "ZWOLNIENIE" ] := IIF( hFirma == NIL, "", AllTrim( hFirma[ "ZWOLNIENIE" ] ) )
      IF Empty( hGlowa[ "ZWOLNIENIE" ] )
         gui_MsgInfo( "Pozycja ze stawką zw wymaga podstawy prawnej zwolnienia." + Eol() + ;
                      "Wpisz ją w Pliki - Ustawienia - Firma, zakładka Faktury.", "Faktura korygująca" )
         RETURN
      ENDIF
   ENDIF

   aPrzed := hKor[ "POZYCJE" ]

   dbSelectArea( "FKTHEAD" )
   IF ! FLock()
      gui_MsgInfo( "Inne stanowisko zapisuje teraz fakturę. Spróbuj za chwilę.", "Faktura korygująca" )
      RETURN
   ENDIF
   nNr := p_FakturyNastepnyNumer( "KOR" )

   FOR nLp := 1 TO Len( aPrzed )
      aPoz := aPrzed[ nLp ]
      dbSelectArea( "FKTROW" )
      IF ! NetAppBlank( NIL, .F. )
         lOkay := .F.
         EXIT
      ENDIF
      AAdd( aDodane, FKTROW->( RecNo() ) )
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
   NEXT
   IF lOkay
      lOkay := p_PozycjeZapisz( "KORTEMP", nNr, "KOR", Len( aPrzed ), .F., aDodane )
   ENDIF
   IF ! lOkay
      p_PozycjeWycofaj( aDodane )
      FKTHEAD->( dbUnlock() )
      gui_MsgError( "Nie udało się zapisać pozycji. Korekta nie została zapisana.", "Faktura korygująca" )
      RETURN
   ENDIF

   dbSelectArea( "FKTHEAD" )
   dbAppend( .F. )
   IF NetErr()
      p_PozycjeWycofaj( aDodane )
      FKTHEAD->( dbUnlock() )
      gui_MsgError( "Nie udało się dopisać nagłówka korekty. Korekta nie została zapisana.", "Faktura korygująca" )
      RETURN
   ENDIF
   FKTHEAD->NR_FAKTURY := nNr
   FKTHEAD->RODZAJ     := "KOR"
   FKTHEAD->NUMER_FKT  := s_Numer( nNr )
   FKTHEAD->D_WYSTAWIE := dWyst
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
   FKTROW->( dbUnlock() )

   gui_MsgInfo( "Zapisano fakturę korygującą " + s_Numer( nNr ) + Eol() + ;
                "Zmiana brutto: " + LTrim( Str( nNetto + nVat - hKor[ "NETTO" ] - hKor[ "VAT" ], 12, 2 ) ) + " zł", "Faktura korygująca" )
   oDialog:Close()

RETURN

STATIC FUNCTION s_OstatniaKorekta( cRok, cNumer )

   LOCAL aOstatnia := NIL

   dbSelectArea( 0 )
   IF ! NetUse( cRok + "fkthead", .F., NIL, "FKTSZUKAJ" )
      RETURN NIL
   ENDIF
   FKTSZUKAJ->( dbGoBottom() )
   DO WHILE ! FKTSZUKAJ->( Bof() ) .AND. ! FKTSZUKAJ->( Eof() )
      IF FKTSZUKAJ->RODZAJ == "KOR" .AND. AllTrim( FKTSZUKAJ->KOR_NUMER ) == cNumer
         aOstatnia := { cRok, FKTSZUKAJ->RODZAJ + Str( FKTSZUKAJ->NR_FAKTURY, 6 ), AllTrim( FKTSZUKAJ->NUMER_FKT ) }
         EXIT
      ENDIF
      FKTSZUKAJ->( dbSkip( -1 ) )
   ENDDO
   FKTSZUKAJ->( dbCloseArea() )

RETURN aOstatnia

STATIC FUNCTION s_PozycjeZrodla( cRok, cKlucz )

   LOCAL aPozycje := {}

   dbSelectArea( 0 )
   IF ! NetUse( cRok + "fktrow", .F., NIL, "FKTROW_ZRODLO" )
      RETURN NIL
   ENDIF
   FKTROW_ZRODLO->( dbGoTop() )
   DO WHILE ! FKTROW_ZRODLO->( Eof() )
      IF FKTROW_ZRODLO->RODZAJ + Str( FKTROW_ZRODLO->NR_FAKTURY, 6 ) == cKlucz .AND. ! FKTROW_ZRODLO->PRZED
         AAdd( aPozycje, { FKTROW_ZRODLO->KOD_TOWARU, FKTROW_ZRODLO->NAZWA_TOWA, FKTROW_ZRODLO->JM_____FKT, ;
                           FKTROW_ZRODLO->ILOSC__FKT, FKTROW_ZRODLO->CENA_JEDNO, FKTROW_ZRODLO->WART_NETTO, ;
                           FKTROW_ZRODLO->STAWKA_VAT, FKTROW_ZRODLO->KWOTA__VAT, FKTROW_ZRODLO->WAR_BRUTTO } )
      ENDIF
      FKTROW_ZRODLO->( dbSkip() )
   ENDDO
   FKTROW_ZRODLO->( dbCloseArea() )

RETURN aPozycje

STATIC FUNCTION s_RokBiezacy( dWyst )

   IF Year( dWyst ) != Val( p_RokPobierz() )
      gui_MsgInfo( "Korekta ma datę wystawienia " + DToC( dWyst ) + "," + Eol() + ;
                   "a program pracuje na roku " + Left( p_RokPobierz(), 4 ) + "." + Eol() + ;
                   "Uruchom xFakturę dla roku " + LTrim( Str( Year( dWyst ) ) ) + ", aby wystawić korektę.", "Faktura korygująca" )
      RETURN .F.
   ENDIF

RETURN .T.

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
   oTekst:maxLength := 254

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
