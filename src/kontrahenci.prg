/*
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: archiwizacja.prg
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
#include "hpdf.ch"
#include "svg.ch"
#include "xfaktura.ch"

PROCEDURE p_Kontrahenci( oWindow )

   s_Kartoteka( oWindow, .F. )

RETURN

FUNCTION p_KontrahenciWybierz( oWindow )
RETURN s_Kartoteka( oWindow, .T. )

STATIC FUNCTION s_Kartoteka( oWindow, lWybor )

   LOCAL oDialog
   LOCAL oToolbar
   LOCAL oPanel
   LOCAL oTabControl
   LOCAL oPage
   LOCAL oBrowse
   LOCAL oDrukuj
   LOCAL oStatus
   LOCAL hWybor
   LOCAL nPole

   IF ! s_DbOpen()
      RETURN NIL
   ENDIF

   oDialog := gui_Dialog():New( oWindow, IIF( lWybor, "Wybór kontrahenta", "Kartoteka kontrahentów" ), 900, 600 )
   oDialog:background := 0xe9edf1
   oDialog:sizable := .T.
   oDialog:SetKey( "F3", {|| s_Nowy( oDialog, KOPIA ) } )
   oDialog:SetKey( "Ins", {|| s_Nowy( oDialog, NOWY ) } )

   oStatus := gui_StatusBar():New( oDialog )
   oStatus:name := "STATUS_BAR"
   oStatus:font := gui_Font():New( NIL, .F., .F., "xFont 9x18" )
   oStatus:Add( 0 )
   oStatus:Add( 60 )
   oStatus:scoreboard := 2

   oToolbar := gui_Toolbar():New( oDialog, "Bottom" )
   oToolbar:Add( "F1-Pomoc",    NIL, {|| s_Pomoc( oDialog ) }, NIL, "F1" )
   oToolbar:AddSeparator()
   IF lWybor
      oToolbar:Add( "Enter-Wybierz", NIL, {|| IIF( s_Pusta(), NIL, oDialog:EndDialog( 1 ) ) }, NIL, "Enter" )
      oToolbar:AddSeparator()
   ENDIF
   oToolbar:Add( "F2-Dodaj",   NIL, {|| s_Nowy( oDialog, NOWY ) },   NIL, "F2" )
   oToolbar:AddSeparator()
   oToolbar:Add( "F4-Popraw",   NIL, {|| s_Nowy( oDialog, POPRAW ) }, NIL, "F4" )
   oToolbar:AddSeparator()
   oToolbar:Add( "F8-Usuń",     NIL, {|| s_Usun( oDialog ) },         NIL, "F8" )
   oToolbar:AddSeparator()

   oDrukuj := gui_Menu():New( .T. )
   oDrukuj:Add( "Drukuj bieżącego",  {|| s_Drukuj( oDialog, BIEZACY ) },    NIL, NIL, {|| ! KONTRAH->( Eof() ) } )
   oDrukuj:Add( "Drukuj zaznaczone", {|| s_Drukuj( oDialog, ZAZNACZONE ) }, NIL, NIL, {|| s_Zaznaczone() } )
   oDrukuj:Add( "Drukuj wszystkich", {|| s_Drukuj( oDialog, WSZYSTKIE ) },  NIL, NIL, {|| KONTRAH->( LastRec() ) > 0 } )
   oToolbar:AddMenu( "F9-Drukuj", oDrukuj, NIL, NIL, "F9" )

   oToolbar:AddSeparator()
   oToolbar:Add( "F12-Szukaj",  NIL, {|| s_Szukaj( oDialog, oDialog:BRW:colPos ) }, NIL, "F12" )
   oToolbar:AddSeparator()
   oToolbar:Add( IIF( lWybor, "Esc-Rezygnuj", "Esc-Zamknij" ), NIL, {|| oDialog:Close() }, NIL, "Esc" )
   oToolbar:AddSeparator()

   oPanel := gui_Panel():New( oDialog )

   oTabControl := gui_TabControl():New( oPanel, 10, 10, oPanel:width - 20, 220 )
   oTabControl:name   := "ZAKLADKI"
   oTabControl:anchor := "LTR"

   oPage := oTabControl:AddPage( "Informacje podstawowe" )
   gui_Say():New( oPage, 20,  23,  14, 20, "Kod kraju / NIP:" )
   gui_Say():New( oPage, 20,  53,  14, 20, "Nazwa kontrahenta:" )
   gui_Say():New( oPage, 20,  83,  14, 20, "Ulica:" )
   gui_Say():New( oPage, 20, 113,  14, 20, "Kod / Miejscowość:" )

   gui_Say():New( oPage, 160,  20,   2, 24 ):name := "KODKRAJU"
   gui_Say():New( oPage, 196,  20,  20, 24 ):name := "NIP"
   gui_Say():New( oPage, 160,  50,  40, 24 ):name := "NAZWA"
   gui_Say():New( oPage, 160,  80,  40, 24 ):name := "ULICA"
   gui_Say():New( oPage, 160, 110,   6, 24 ):name := "KODPOCZ"
   gui_Say():New( oPage, 232, 110,  32, 24 ):name := "MIASTO"

   oPage := oTabControl:AddPage( "Kontakt" )
   gui_Say():New( oPage, 20, 23,  14, 20, "Telefon:" )
   gui_Say():New( oPage, 20, 53,  14, 20, "E-mail:" )

   gui_Say():New( oPage, 160,  20,  20, 24 ):name := "TELEFON"
   gui_Say():New( oPage, 160,  50,  44, 24 ):name := "EMAIL"

   oPage := oTabControl:AddPage( "Bank" )
   gui_CheckBox():New( oPage, 20, 12, 320, 20, "Drukuj konto bankowe na fakturze" ):name := "DRUK_BANK"
   gui_GroupBox():New( oPage, 10, 38, 620, 142, "Rachunki bankowe" )
   gui_Say():New( oPage, 20,  59,  14, 20, "Nazwa banku:" )
   gui_Say():New( oPage, 20,  87,  14, 20, "Numer rachunku:" )
   gui_Say():New( oPage, 20, 122,  14, 20, "Nazwa banku:" )
   gui_Say():New( oPage, 20, 150,  14, 20, "Numer rachunku:" )

   gui_Say():New( oPage, 160,  56,  44, 24 ):name := "NAZWABANK1"
   gui_Say():New( oPage, 160,  84,  34, 24 ):name := "KONTO_NR1"
   gui_Say():New( oPage, 160, 119,  44, 24 ):name := "NAZWABANK2"
   gui_Say():New( oPage, 160, 147,  34, 24 ):name := "KONTO_NR2"

   gui_RadioButton():New( oPage, 495,  86, 110, 20, "Drukuj to" ):name := "DRUKUJ_1"
   gui_RadioButton():New( oPage, 495, 149, 110, 20, "Drukuj to" ):name := "DRUKUJ_2"
   oDialog:DRUK_BANK:enabled := .F.
   oDialog:DRUKUJ_1:enabled  := .F.
   oDialog:DRUKUJ_2:enabled  := .F.

   oPage := oTabControl:AddPage( "Uwagi" )
   gui_Say():New( oPage, 20, 23,  14, 20, "Uwagi:" )

   gui_Say():New( oPage, 160, 20,  53, 24 ):name := "UWAGI"

   oDialog:KODKRAJU:border := .T.
   oDialog:NIP:border      := .T.
   oDialog:NAZWA:border    := .T.
   oDialog:ULICA:border    := .T.
   oDialog:KODPOCZ:border  := .T.
   oDialog:MIASTO:border   := .T.
   oDialog:TELEFON:border  := .T.
   oDialog:EMAIL:border    := .T.
   oDialog:NAZWABANK1:border := .T.
   oDialog:KONTO_NR1:border  := .T.
   oDialog:NAZWABANK2:border := .T.
   oDialog:KONTO_NR2:border  := .T.
   oDialog:UWAGI:border    := .T.

   oBrowse := gui_Browse():New( oPanel, 10, 240, oPanel:width - 20, oPanel:height - 250 )
   oBrowse:name             := "BRW"
   oBrowse:headerBackground := 0x4d7326
   oBrowse:checkForeground  := 0xFF0000
   oBrowse:anchor           := "LTRB"
   oBrowse:goTopBlock       := {|| KONTRAH->( dbGoTop() ) }
   oBrowse:goBottomBlock    := {|| KONTRAH->( dbGoBottom() ) }
   oBrowse:skipBlock        := {| n | KONTRAH->( DbSkipper( n ) ) }
   oBrowse:positionBlock    := {|| KONTRAH->( IIF( LastRec() > 0, RecNo() / LastRec(), 0 ) ) }
   oBrowse:emptyBlock       := {|| s_Pusta() }
   oBrowse:AddColumn( "Poz.",                    {|| KONTRAH->( RecNo() ) }, 4 )
   oBrowse:AddColumn( "Chk",                     {| l | IIF( l == NIL, KONTRAH->ZAZNACZONY, s_Zaznacz( l ) ) } )
   oBrowse:freeze := 2
   oBrowse:AddColumn( PadC( "NIP", 20 ),         {|| KONTRAH->NIP } )
   oBrowse:AddColumn( PadC( "Nazwa kontrahenta", 40 ), {|| StrTran( KONTRAH->NAZWA, Eol( KONTRAH->NAZWA ), " " ) }, 40 )
   oBrowse:AddColumn( "Miejscowość",             {|| KONTRAH->MIASTO } )
   oBrowse:AddColumn( "Ulica",                   {|| KONTRAH->ULICA } )
   oBrowse:OnChange      := {|| s_Okno( oDialog ) }

   KONTRAH->( dbGoTop() )
   s_Okno( oDialog )
   s_Stan( oDialog )

   oDialog:Center()
   IF oDialog:ShowModal() == 1 .AND. lWybor .AND. ! KONTRAH->( Eof() )
      hWybor := { => }
      FOR nPole := 1 TO KONTRAH->( FCount() )
         hWybor[ KONTRAH->( FieldName( nPole ) ) ] := KONTRAH->( FieldGet( nPole ) )
      NEXT
   ENDIF

   KONTRAH->( dbCloseArea() )

RETURN hWybor

/* ---------------------------------------------------------------------------------------------
   Baza
   --------------------------------------------------------------------------------------------- */

STATIC FUNCTION s_Struct()
RETURN { ;
   { "ZAZNACZONY",     "L",   1, 0 }, ;
   { "KODKRAJU",       "C",   2, 0 }, ;
   { "NIP",            "C",  20, 0 }, ;
   { "NAZWA",          "M",  10, 0 }, ;
   { "KODPOCZ",        "C",   6, 0 }, ;
   { "MIASTO",         "C",  40, 0 }, ;
   { "ULICA",          "C",  60, 0 }, ;
   { "TELEFON",        "C",  20, 0 }, ;
   { "EMAIL",          "C",  60, 0 }, ;
   { "DRUK_BANK",      "L",   1, 0 }, ;
   { "BANK1",          "C",  60, 0 }, ;
   { "KONTO1",         "C",  34, 0 }, ;
   { "BANK2",          "C",  60, 0 }, ;
   { "KONTO2",         "C",  34, 0 }, ;
   { "DRUKUJ_TO",      "N",   1, 0 }, ;
   { "UWAGI",          "C", 200, 0 } }

STATIC FUNCTION s_DbOpen()

   LOCAL cBaza := "kontrahenci" + DirSepToOS( "\" ) + "kontrah"

   IF ! FileExists( cBaza + ".dbf" )
      dbCreate( cBaza, s_Struct() )
   ENDIF

   dbSelectArea( 0 )
   IF ! NetUse( cBaza, .F., NIL, "KONTRAH" )
      RETURN .F.
   ENDIF

   IF ! s_Okay()
      KONTRAH->( dbCloseArea() )
      gui_MsgInfo( "Zmiana struktury bazy kontrahentów", "Kontrahenci" )
      s_Rekonstrukcja()
      dbSelectArea( 0 )
      IF ! NetUse( cBaza, .F., NIL, "KONTRAH" )
         RETURN .F.
      ENDIF
      IF ! s_Okay()
         KONTRAH->( dbCloseArea() )
         RETURN .F.
      ENDIF
   ENDIF

RETURN .T.

STATIC FUNCTION s_Okay()

   LOCAL aWzor := s_Struct()
   LOCAL aBaza := KONTRAH->( dbStruct() )
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

STATIC PROCEDURE s_Rekonstrukcja()

   LOCAL cBaza := "kontrahenci" + DirSepToOS( "\" ) + "kontrah"
   LOCAL cTmp  := "kontrahenci" + DirSepToOS( "\" ) + "tmp.dbf"

   LOCAL cExt   := RddInfo( RDDI_MEMOEXT )
   LOCAL cStary := IIF( FileExists( cBaza + ".fpt" ), ".fpt", cExt )
   LOCAL cMemo  := "kontrahenci" + DirSepToOS( "\" ) + "tmp" + cStary

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
   IF ! NetUse( cBaza, .T., NIL, "KONTRAH" )
      FErase( cBaza + ".dbf" )
      FErase( cBaza + cExt )
      FRename( cTmp, cBaza + ".dbf" )
      FRename( cMemo, cBaza + cStary )
      RETURN
   ENDIF
   IF ! p_BazaPrzenies( cTmp, { "KODKRAJU" => "KOD_KRAJU", ;
      "KODPOCZ" => "KOD_POCZTOWY", ;
      "MIASTO" => "MIEJSCOWOSC", ;
      "DRUK_BANK" => "DRUKUJ_KONTO", ;
      "BANK1" => "NAZWA_BANKU_1", ;
      "BANK2" => "NAZWA_BANKU_2", ;
      "KONTO1" => "NUMER_KONTA_1", ;
      "KONTO2" => "NUMER_KONTA_2", ;
      "DRUKUJ_TO" => "KTORE_KONTO" } )
      KONTRAH->( dbCloseArea() )
      FErase( cBaza + ".dbf" )
      FErase( cBaza + cExt )
      FRename( cTmp, cBaza + ".dbf" )
      FRename( cMemo, cBaza + cStary )
      RETURN
   ENDIF
   KONTRAH->( dbCloseArea() )
   FErase( cTmp )
   FErase( cMemo )

RETURN

/* ---------------------------------------------------------------------------------------------
   Indexy
   --------------------------------------------------------------------------------------------- */

PROCEDURE p_KontrahenciNtx()

   LOCAL cBaza := "kontrahenci" + DirSepToOS( "\" ) + "kontrah"

   IF FileExists( cBaza + ".dbf" )

      dbSelectArea( 0 )
      IF NetUse( cBaza, .T., NIL, "KONTRAH" )
         NetPack()
         KONTRAH->( dbCloseArea() )
      ENDIF

   ENDIF

RETURN

STATIC FUNCTION s_Pusta()

   LOCAL nRecNo := KONTRAH->( RecNo() )
   LOCAL lPusta

   KONTRAH->( dbGoTop() )
   lPusta := KONTRAH->( Eof() )
   KONTRAH->( dbGoto( nRecNo ) )

RETURN lPusta

STATIC PROCEDURE s_Stan( oDialog )

   LOCAL lJest := ! s_Pusta()

   oDialog:BRW:enabled := lJest
   oDialog:BRW:Refresh()

   IF lJest
      oDialog:BRW:SetFocus()
   ENDIF

RETURN

STATIC PROCEDURE s_Pomoc( oWindow )

   p_Pomoc( oWindow, "Kontrahenci", ;
      Eol() + ;
      "Przeglądanie" + Eol() + ;
      Eol() + ;
      "F1             pomoc" + Eol() + ;
      "F2, Ins        nowy kontrahent" + Eol() + ;
      "F3             kopia bieżącego kontrahenta jako nowy" + Eol() + ;
      "F4             poprawienie kontrahenta" + Eol() + ;
      "F8             usunięcie kontrahenta" + Eol() + ;
      "F9             wydruk: bieżącego, zaznaczonych albo wszystkich" + Eol() + ;
      "Spacja         zaznaczenie / odznaczenie kontrahenta" + Eol() + ;
      "F12            szukanie w kolumnie, na której stoi belka" + Eol() + ;
      "Strzałki       poprzedni / następny kontrahent, lewo / prawo kolumna" + Eol() + ;
      "PgUp, PgDn     poprzednia / następna strona" + Eol() + ;
      "Ctrl+Home      pierwszy kontrahent" + Eol() + ;
      "Ctrl+End       ostatni kontrahent" + Eol() + ;
      "Esc            zamknięcie kartoteki" + Eol() + ;
      Eol() + ;
      "Wpisywanie danych" + Eol() + ;
      Eol() + ;
      "Enter          następne pole, na ostatnim polu ostatniej zakładki zapis" + Eol() + ;
      "Tab            następne pole, bez zapisu" + Eol() + ;
      "Shift+Tab      poprzednie pole" + Eol() + ;
      "Ctrl+Tab       następna zakładka danych" + Eol() + ;
      "Ins            wstawianie / zastępowanie znaków, Ins na pasku stanu" + Eol() + ;
      "Spacja         na zakładce Bank: drukowanie konta, wybór konta" + Eol() + ;
      "PgUp, PgDn     zapis" + Eol() + ;
      "Esc            bez zapisu" + Eol() + ;
      Eol() + ;
      "Nazwa kontrahenta (pole wielowierszowe)" + Eol() + ;
      Eol() + ;
      "Shift+Enter    nowa linia w nazwie, np. Firma PHU / Jan Kowalski" + Eol() + ;
      "Enter          następne pole" + Eol() + ;
      "               pole rozwija się do 4 linii, najwyżej 512 znaków" + Eol() + ;
      "               w tabeli i do KSeF nowa linia staje się spacją" )

RETURN

STATIC PROCEDURE s_Okno( oDialog )

   oDialog:KODKRAJU:text   := KONTRAH->KODKRAJU
   oDialog:NIP:text        := KONTRAH->NIP
   oDialog:NAZWA:text      := StrTran( KONTRAH->NAZWA, Eol( KONTRAH->NAZWA ), " " )
   oDialog:ULICA:text      := KONTRAH->ULICA
   oDialog:KODPOCZ:text    := KONTRAH->KODPOCZ
   oDialog:MIASTO:text     := KONTRAH->MIASTO
   oDialog:TELEFON:text    := KONTRAH->TELEFON
   oDialog:EMAIL:text      := KONTRAH->EMAIL
   oDialog:DRUK_BANK:value := KONTRAH->DRUK_BANK
   oDialog:NAZWABANK1:text := KONTRAH->BANK1
   oDialog:KONTO_NR1:text  := KONTRAH->KONTO1
   oDialog:NAZWABANK2:text := KONTRAH->BANK2
   oDialog:KONTO_NR2:text  := KONTRAH->KONTO2
   oDialog:DRUKUJ_1:value  := KONTRAH->DRUKUJ_TO != 2
   oDialog:DRUKUJ_2:value  := KONTRAH->DRUKUJ_TO == 2
   oDialog:UWAGI:text      := KONTRAH->UWAGI

RETURN

STATIC PROCEDURE s_Nowy( oDialog, nMode )

   LOCAL GetList := {}
   LOCAL nRecNo  := KONTRAH->( RecNo() )
   LOCAL oPage1  := oDialog:ZAKLADKI:Page( 1 )
   LOCAL oPage2  := oDialog:ZAKLADKI:Page( 2 )
   LOCAL oPage3  := oDialog:ZAKLADKI:Page( 3 )
   LOCAL oPage4  := oDialog:ZAKLADKI:Page( 4 )
   LOCAL cKodKraju
   LOCAL cNip
   LOCAL cNazwa
   LOCAL cUlica
   LOCAL cKodPocztowy
   LOCAL cMiejscowosc
   LOCAL cTelefon
   LOCAL cEmail
   LOCAL cNazwaBanku1
   LOCAL cNumerKonta1
   LOCAL cNazwaBanku2
   LOCAL cNumerKonta2
   LOCAL cUwagi

   LOCAL aWybor := { oDialog:DRUK_BANK, oDialog:DRUKUJ_1, oDialog:DRUKUJ_2 }
   LOCAL lDrukujKonto
   LOCAL nKtoreKonto
   LOCAL nGet

   IF nMode == POPRAW .AND. KONTRAH->( Eof() )
      RETURN
   ENDIF

   IF nMode == NOWY
      KONTRAH->( dbGoBottom() )
      KONTRAH->( dbSkip() )
   ENDIF

   cKodKraju    := IIF( nMode == NOWY, "PL", KONTRAH->KODKRAJU )
   cNip         := KONTRAH->NIP
   cNazwa       := KONTRAH->NAZWA
   cUlica       := IIF( nMode == NOWY, PadR( "ul.", Len( KONTRAH->ULICA ) ), KONTRAH->ULICA )
   cKodPocztowy := KONTRAH->KODPOCZ
   cMiejscowosc := KONTRAH->MIASTO
   cTelefon     := KONTRAH->TELEFON
   cEmail       := KONTRAH->EMAIL
   cNazwaBanku1 := KONTRAH->BANK1
   cNumerKonta1 := KONTRAH->KONTO1
   cNazwaBanku2 := KONTRAH->BANK2
   cNumerKonta2 := KONTRAH->KONTO2
   cUwagi       := KONTRAH->UWAGI

   AAdd( GetList, gui_Get():New( oPage1, 160,  20, NIL, NIL, @cKodKraju, "@! AA" ) )
   AAdd( GetList, gui_Get():New( oPage1, 196,  20,  20, NIL, @cNip ) )
   AAdd( GetList, gui_Get():New( oPage1, 160,  50,  40, NIL, @cNazwa, NIL, 4, 512 ) )
   AAdd( GetList, gui_Get():New( oPage1, 160,  80,  40, NIL, @cUlica ) )
   AAdd( GetList, gui_Get():New( oPage1, 160, 110, NIL, NIL, @cKodPocztowy, "99-999" ) )
   AAdd( GetList, gui_Get():New( oPage1, 232, 110,  32, NIL, @cMiejscowosc ) )
   AAdd( GetList, gui_Get():New( oPage2, 160,  20, NIL, NIL, @cTelefon ) )
   AAdd( GetList, gui_Get():New( oPage2, 160,  50,  44, NIL, @cEmail ) )
   AAdd( GetList, oDialog:DRUK_BANK )
   AAdd( GetList, gui_Get():New( oPage3, 160,  56,  44, NIL, @cNazwaBanku1 ) )
   AAdd( GetList, gui_Get():New( oPage3, 160,  84,  34, NIL, @cNumerKonta1 ) )
   AAdd( GetList, oDialog:DRUKUJ_1 )
   AAdd( GetList, gui_Get():New( oPage3, 160, 119,  44, NIL, @cNazwaBanku2 ) )
   AAdd( GetList, gui_Get():New( oPage3, 160, 147,  34, NIL, @cNumerKonta2 ) )
   AAdd( GetList, oDialog:DRUKUJ_2 )
   AAdd( GetList, gui_Get():New( oPage4, 160,  20,  53, NIL, @cUwagi ) )
   AEval( aWybor, {| oWybor | oWybor:enabled := .T. } )

   oDialog:STATUS_BAR:text := " Tryb edycji - PgUp PgDn Enter = zapisz, Esc = bez zapisu"
   oDialog:STATUS_BAR:background := 0x73264d
   oDialog:STATUS_BAR:foreground := 0xffffff

   oDialog:ReadModal( GetList, 2 )

   oDialog:STATUS_BAR:text       := ""
   oDialog:STATUS_BAR:background := NIL
   oDialog:STATUS_BAR:foreground := NIL

   lDrukujKonto := oDialog:DRUK_BANK:value
   nKtoreKonto  := IIF( oDialog:DRUKUJ_2:value, 2, 1 )
   AEval( aWybor, {| oWybor | oWybor:enabled := .F. } )
   FOR nGet := 1 TO Len( GetList )
      IF AScan( aWybor, {| oWybor | oWybor == GetList[ nGet ] } ) == 0
         GetList[ nGet ]:Destroy()
      ENDIF
   NEXT

   IF LastKey() == K_ESC
      KONTRAH->( dbGoto( nRecNo ) )

      s_Okno( oDialog )
      RETURN
   ENDIF

   dbSelectArea( "KONTRAH" )
   IF nMode == NOWY .OR. nMode == KOPIA
      IF ! NetAppBlank()
         KONTRAH->( dbGoto( nRecNo ) )
         RETURN
      ENDIF
   ELSE
      IF ! NetRLock()
         RETURN
      ENDIF
   ENDIF

   KONTRAH->KODKRAJU     := cKodKraju
   KONTRAH->NIP           := cNip
   KONTRAH->NAZWA         := AllTrim( cNazwa )
   KONTRAH->ULICA         := cUlica
   KONTRAH->KODPOCZ  := IIF( Empty( StrTran( cKodPocztowy, "-" ) ), "", cKodPocztowy )
   KONTRAH->MIASTO   := cMiejscowosc
   KONTRAH->TELEFON       := cTelefon
   KONTRAH->EMAIL         := cEmail
   KONTRAH->DRUK_BANK  := lDrukujKonto
   KONTRAH->BANK1 := cNazwaBanku1
   KONTRAH->KONTO1 := cNumerKonta1
   KONTRAH->BANK2 := cNazwaBanku2
   KONTRAH->KONTO2 := cNumerKonta2
   KONTRAH->DRUKUJ_TO   := nKtoreKonto
   KONTRAH->UWAGI         := cUwagi
   dbCommit()
   dbUnlock()

   s_Stan( oDialog )
   s_Okno( oDialog )

RETURN

STATIC PROCEDURE s_Usun( oDialog )

   IF KONTRAH->( Eof() )
      RETURN
   ENDIF

   IF gui_MsgYesNo( "Czy na pewno usunąć kontrahenta" + Eol() + AllTrim( KONTRAH->NAZWA ) + "?", "Kontrahenci" )
      dbSelectArea( "KONTRAH" )
      IF NetRLock()
         dbDelete()
         dbCommit()
         dbUnlock()
         dbSkip()
         IF Eof()
            dbGoBottom()
         ENDIF
      ENDIF
      s_Stan( oDialog )
      s_Okno( oDialog )
   ENDIF

RETURN

STATIC FUNCTION s_Zaznacz( lZaznacz )

   IF KONTRAH->( NetRLock() )
      KONTRAH->ZAZNACZONY := lZaznacz
      KONTRAH->( dbCommit() )
      KONTRAH->( dbUnlock() )
   ENDIF

RETURN KONTRAH->ZAZNACZONY

STATIC FUNCTION s_Zaznaczone()

   LOCAL nRecNo := KONTRAH->( RecNo() )
   LOCAL lJest

   KONTRAH->( DbLocate( {|| KONTRAH->ZAZNACZONY } ) )
   lJest := KONTRAH->( Found() )
   KONTRAH->( dbGoto( nRecNo ) )

RETURN lJest

STATIC PROCEDURE s_Szukaj( oDialog, nKolumna )

   LOCAL oSzukaj
   LOCAL oTekst
   LOCAL oOk
   LOCAL oAnuluj
   LOCAL cTekst := ""
   LOCAL cOpis
   LOCAL bPole
   LOCAL nRecNo

   IF KONTRAH->( Eof() )
      RETURN
   ENDIF

   DO CASE
   CASE nKolumna == 3
      cOpis := "NIP:"
      bPole := {|| KONTRAH->NIP }
   CASE nKolumna == 5
      cOpis := "Miejscowość:"
      bPole := {|| KONTRAH->MIASTO }
   CASE nKolumna == 6
      cOpis := "Ulica:"
      bPole := {|| KONTRAH->ULICA }
   OTHERWISE
      cOpis := "Nazwa kontrahenta:"
      bPole := {|| KONTRAH->NAZWA }
   ENDCASE

   oSzukaj := gui_Dialog():New( oDialog, "Szukaj kontrahenta", 400, 120 )
   oSzukaj:Center()

   gui_Say():New( oSzukaj, 10, 12,  41, 20, cOpis )

   oTekst  := gui_Edit():New( oSzukaj, 10, 36, 380 )

   oOk     := gui_Button():New( oSzukaj, 200, 76, 90, 28, "OK" )
   oAnuluj := gui_Button():New( oSzukaj, 300, 76, 90, 28, "Anuluj" )

   oOk:isDefault    := .T.
   oOk:onClick      := {|| cTekst := oTekst:value, oSzukaj:EndDialog( 1 ) }
   oAnuluj:isCancel := .T.
   oAnuluj:onClick  := {|| oSzukaj:EndDialog( 0 ) }

   oSzukaj:ShowModal()

   cTekst := Upper( AllTrim( cTekst ) )
   IF Empty( cTekst )
      RETURN
   ENDIF

   dbSelectArea( "KONTRAH" )
   nRecNo := RecNo()
   DO WHILE .T.
      dbSkip()
      IF Eof()
         dbGoTop()
      ENDIF
      IF cTekst $ Upper( Eval( bPole ) )
         oDialog:BRW:Refresh()
         s_Okno( oDialog )
         RETURN
      ENDIF
      IF RecNo() == nRecNo
         EXIT
      ENDIF
   ENDDO
   gui_MsgInfo( "Nie znaleziono: " + cTekst, "Kontrahenci" )

RETURN

/* ---------------------------------------------------------------------------------------------
   Wydruki
   --------------------------------------------------------------------------------------------- */

STATIC PROCEDURE s_Drukuj( oDialog, nZakres )

   LOCAL oPytanie
   LOCAL oPdf
   LOCAL oSvg
   LOCAL oAnuluj
   LOCAL nGdzie
   LOCAL aDane
   LOCAL cTytul
   LOCAL cPlik
   LOCAL lZapis

   oPytanie := gui_Dialog():New( oDialog, "Wydruk kontrahentów", 330, 110 )
   oPytanie:Center()

   gui_Say():New( oPytanie, 10, 12, 34, 20, "Dokąd drukować?" )

   oPdf    := gui_Button():New( oPytanie,  10, 56, 90, 28, "PDF" )
   oSvg    := gui_Button():New( oPytanie, 115, 56, 90, 28, "SVG" )
   oAnuluj := gui_Button():New( oPytanie, 230, 56, 90, 28, "Anuluj" )

   oPdf:isDefault   := .T.
   oPdf:onClick     := {|| oPytanie:EndDialog( 1 ) }
   oSvg:onClick     := {|| oPytanie:EndDialog( 2 ) }
   oAnuluj:isCancel := .T.
   oAnuluj:onClick  := {|| oPytanie:EndDialog( 0 ) }

   nGdzie := oPytanie:ShowModal()
   IF nGdzie == 0
      RETURN
   ENDIF

   aDane := s_DoDruku( nZakres )
   DO CASE
   CASE nZakres == BIEZACY
      cTytul := "Kontrahent"
   CASE nZakres == ZAZNACZONE
      cTytul := "Kontrahenci zaznaczeni"
   OTHERWISE
      cTytul := "Wszyscy kontrahenci"
   ENDCASE

   IF ! DirExists( "wydruki" )
      DirMake( "wydruki" )
   ENDIF
   cPlik := "wydruki" + DirSepToOS( "\" ) + "kontrahenci" + IIF( nGdzie == 1, ".pdf", ".svg" )

   lZapis := IIF( nGdzie == 1, s_DrukPdf( cPlik, cTytul, aDane ), s_DrukSvg( cPlik, cTytul, aDane ) )
   IF ! lZapis
      gui_MsgError( "Nie można zapisać pliku " + cPlik + "." + Eol() + ;
                    "Plik może być otwarty w innym programie.", "Wydruk kontrahentów" )
   ELSEIF ! gui_OpenFile( cPlik )
      gui_MsgInfo( "Wydruk zapisany w pliku " + cPlik + ".", "Wydruk kontrahentów" )
   ENDIF

RETURN

STATIC FUNCTION s_DoDruku( nZakres )

   LOCAL aDane  := {}
   LOCAL nRecNo := KONTRAH->( RecNo() )

   IF nZakres == BIEZACY
      AAdd( aDane, s_Wiersz( 1 ) )
      RETURN aDane
   ENDIF

   KONTRAH->( dbGoTop() )
   DO WHILE ! KONTRAH->( Eof() )
      IF nZakres == WSZYSTKIE .OR. KONTRAH->ZAZNACZONY
         AAdd( aDane, s_Wiersz( Len( aDane ) + 1 ) )
      ENDIF
      KONTRAH->( dbSkip() )
   ENDDO
   KONTRAH->( dbGoto( nRecNo ) )

RETURN aDane

STATIC FUNCTION s_Wiersz( nLp )

RETURN { LTrim( Str( nLp ) ) + ".", ;
         AllTrim( AllTrim( KONTRAH->KODKRAJU ) + " " + AllTrim( KONTRAH->NIP ) ), ;
         AllTrim( KONTRAH->NAZWA ), ;
         AllTrim( KONTRAH->ULICA ), ;
         AllTrim( AllTrim( KONTRAH->KODPOCZ ) + " " + AllTrim( KONTRAH->MIASTO ) ), ;
         AllTrim( KONTRAH->TELEFON ), ;
         AllTrim( KONTRAH->EMAIL ) }

STATIC FUNCTION s_DwieLinie( cTekst, bMiesci )

   LOCAL cEol    := Eol( cTekst )
   LOCAL nPoz    := At( cEol, cTekst )
   LOCAL cLinia1 := cTekst
   LOCAL nSpacja

   IF nPoz > 0
      RETURN { Left( cTekst, nPoz - 1 ), AllTrim( StrTran( SubStr( cTekst, nPoz + Len( cEol ) ), cEol, " " ) ) }
   ENDIF
   DO WHILE ! Eval( bMiesci, cLinia1 ) .AND. ( nSpacja := RAt( " ", cLinia1 ) ) > 0
      cLinia1 := RTrim( Left( cLinia1, nSpacja - 1 ) )
   ENDDO

RETURN { cLinia1, LTrim( SubStr( cTekst, Len( cLinia1 ) + 1 ) ) }

STATIC FUNCTION s_DrukPdf( cPlik, cTytul, aDane )

   LOCAL aNaglowek := { "Lp.", "NIP", "Nazwa", "Adres", "Telefon", "e-mail" }
   LOCAL aKolumna  := { 40, 68, 195, 430, 640, 715, 802 }
   LOCAL nNaStrone := 16
   LOCAL nStron    := Max( 1, Int( ( Len( aDane ) + nNaStrone - 1 ) / nNaStrone ) )
   LOCAL pPdf      := HPDF_New()
   LOCAL pFont
   LOCAL pBold
   LOCAL pPage
   LOCAL nStrona
   LOCAL nWiersz
   LOCAL nKolumna
   LOCAL nY
   LOCAL lZapis
   LOCAL aNazwa
   LOCAL aLinia1
   LOCAL aLinia2

   HPDF_SetCompressionMode( pPdf, HPDF_COMP_ALL )
   HPDF_SetInfoAttr( pPdf, HPDF_INFO_TITLE, cTytul )
   HPDF_SetInfoAttr( pPdf, HPDF_INFO_CREATOR, "xFaktura" )
   HPDF_UseUTFEncodings( pPdf )
   HPDF_SetCurrentEncoder( pPdf, "UTF-8" )
   pFont := HPDF_GetFont( pPdf, HPDF_LoadTTFontFromFile( pPdf, GetEnv( "WINDIR" ) + "\Fonts\arial.ttf", HPDF_TRUE ), "UTF-8" )
   pBold := HPDF_GetFont( pPdf, HPDF_LoadTTFontFromFile( pPdf, GetEnv( "WINDIR" ) + "\Fonts\arialbd.ttf", HPDF_TRUE ), "UTF-8" )

   FOR nStrona := 1 TO nStron
      pPage := HPDF_AddPage( pPdf )
      HPDF_Page_SetSize( pPage, HPDF_PAGE_SIZE_A4, HPDF_PAGE_LANDSCAPE )

      p_WydrukUstawZnaki( pPage, pFont )

      s_PdfTekst( pPage, pBold, 16, 40, 520, cTytul, 500 )
      s_PdfTekst( pPage, pFont, 9, 40, 504, "Liczba kontrahentów: " + LTrim( Str( Len( aDane ) ) ), 300 )
      s_PdfTekst( pPage, pFont, 9, 650, 520, "Wydruk: " + DToC( Date() ) + " " + Left( Time(), 5 ), 152 )

      HPDF_Page_SetRGBFill( pPage, 0.302, 0.451, 0.149 )
      HPDF_Page_Rectangle( pPage, aKolumna[ 1 ], 470, ATail( aKolumna ) - aKolumna[ 1 ], 18 )
      HPDF_Page_Fill( pPage )
      HPDF_Page_SetRGBFill( pPage, 1, 1, 1 )
      FOR nKolumna := 1 TO Len( aNaglowek )
         s_PdfTekst( pPage, pBold, 9, aKolumna[ nKolumna ] + 4, 475, aNaglowek[ nKolumna ], ;
                     aKolumna[ nKolumna + 1 ] - aKolumna[ nKolumna ] - 8 )
      NEXT
      HPDF_Page_SetRGBFill( pPage, 0, 0, 0 )

      HPDF_Page_SetLineWidth( pPage, 0.5 )
      HPDF_Page_SetRGBStroke( pPage, 0.75, 0.75, 0.75 )
      nY := 470
      FOR nWiersz := ( nStrona - 1 ) * nNaStrone + 1 TO Min( nStrona * nNaStrone, Len( aDane ) )
         HPDF_Page_SetFontAndSize( pPage, pFont, 9 )
         aNazwa  := s_DwieLinie( aDane[ nWiersz ][ 3 ], {| cTekst | HPDF_Page_TextWidth( pPage, cTekst ) <= aKolumna[ 4 ] - aKolumna[ 3 ] - 8 } )
         aLinia1 := { aDane[ nWiersz ][ 1 ], aDane[ nWiersz ][ 2 ], aNazwa[ 1 ], aDane[ nWiersz ][ 4 ], aDane[ nWiersz ][ 6 ], aDane[ nWiersz ][ 7 ] }
         aLinia2 := { "", "", aNazwa[ 2 ], aDane[ nWiersz ][ 5 ], "", "" }
         FOR nKolumna := 1 TO Len( aNaglowek )
            s_PdfTekst( pPage, pFont, 9, aKolumna[ nKolumna ] + 4, nY - 11, aLinia1[ nKolumna ], ;
                        aKolumna[ nKolumna + 1 ] - aKolumna[ nKolumna ] - 8 )
            s_PdfTekst( pPage, pFont, 9, aKolumna[ nKolumna ] + 4, nY - 22, aLinia2[ nKolumna ], ;
                        aKolumna[ nKolumna + 1 ] - aKolumna[ nKolumna ] - 8 )
         NEXT
         nY -= 26
         HPDF_Page_MoveTo( pPage, aKolumna[ 1 ], nY )
         HPDF_Page_LineTo( pPage, ATail( aKolumna ), nY )
         HPDF_Page_Stroke( pPage )
      NEXT

      s_PdfTekst( pPage, pFont, 8, 700, 25, "Strona " + LTrim( Str( nStrona ) ) + " z " + LTrim( Str( nStron ) ), 102 )
   NEXT

   lZapis := HPDF_SaveToFile( pPdf, cPlik ) == HPDF_OK
   HPDF_Free( pPdf )

RETURN lZapis

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

STATIC FUNCTION s_DrukSvg( cPlik, cTytul, aDane )

   LOCAL aNaglowek := { "Lp.", "NIP", "Nazwa", "Adres", "Telefon", "E-mail" }
   LOCAL aZnaki    := { 5, 24, 40, 40, 16, 30 }
   LOCAL nZnak     := 7.2
   LOCAL cFont     := "Consolas, Courier New, monospace"
   LOCAL nSzer     := 40 + Int( 155 * nZnak )
   LOCAL nWys      := 130 + Len( aDane ) * 36
   LOCAL nSvg      := svg_Init( cPlik, nSzer, nWys )
   LOCAL nWiersz
   LOCAL nKolumna
   LOCAL nX
   LOCAL nY
   LOCAL aNazwa
   LOCAL aLinia1
   LOCAL aLinia2

   IF nSvg == 0
      RETURN .F.
   ENDIF

   svg_FilledRect( nSvg, 0, 0, nSzer, nWys, "#ffffff" )
   svg_Text( nSvg, 20, 34, cTytul, "Arial", 20, FONT_WEIGHT_BOLD, "#000000" )
   svg_Text( nSvg, 20, 56, "Liczba kontrahentów: " + LTrim( Str( Len( aDane ) ) ), "Arial", 12, FONT_WEIGHT_NORMAL, "#000000" )
   svg_Text( nSvg, nSzer - 20, 34, "Wydruk: " + DToC( Date() ) + " " + Left( Time(), 5 ), "Arial", 12, ;
             FONT_WEIGHT_NORMAL, "#000000", SVG_ALIGN_RIGHT )

   nY := 70
   svg_FilledRect( nSvg, 20, nY, nSzer - 40, 20, "#4d7326" )
   nX := 20
   FOR nKolumna := 1 TO Len( aNaglowek )
      svg_Text( nSvg, nX + 4, nY + 14, aNaglowek[ nKolumna ], cFont, 12, FONT_WEIGHT_BOLD, "#ffffff" )
      nX += aZnaki[ nKolumna ] * nZnak
   NEXT

   nY += 20
   FOR nWiersz := 1 TO Len( aDane )
      aNazwa  := s_DwieLinie( aDane[ nWiersz ][ 3 ], {| cTekst | ULen( cTekst ) <= aZnaki[ 3 ] - 1 } )
      aLinia1 := { aDane[ nWiersz ][ 1 ], aDane[ nWiersz ][ 2 ], aNazwa[ 1 ], aDane[ nWiersz ][ 4 ], aDane[ nWiersz ][ 6 ], aDane[ nWiersz ][ 7 ] }
      aLinia2 := { "", "", aNazwa[ 2 ], aDane[ nWiersz ][ 5 ], "", "" }
      nX := 20
      FOR nKolumna := 1 TO Len( aNaglowek )
         svg_Text( nSvg, nX + 4, nY + 14, s_SvgTekst( aLinia1[ nKolumna ], aZnaki[ nKolumna ] - 1 ), ;
                   cFont, 12, FONT_WEIGHT_NORMAL, "#000000" )
         svg_Text( nSvg, nX + 4, nY + 30, s_SvgTekst( aLinia2[ nKolumna ], aZnaki[ nKolumna ] - 1 ), ;
                   cFont, 12, FONT_WEIGHT_NORMAL, "#000000" )
         nX += aZnaki[ nKolumna ] * nZnak
      NEXT
      nY += 36
      svg_Line( nSvg, 20, nY, nSzer - 20, nY, 0.5, "#bfbfbf" )
   NEXT

   svg_Close( nSvg )

RETURN .T.

STATIC FUNCTION s_SvgTekst( cTekst, nZnakow )

   IF ULen( cTekst ) > nZnakow
      cTekst := ULeft( cTekst, nZnakow - 1 ) + "…"
   ENDIF

RETURN cTekst
