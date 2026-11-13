/*
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: firma.prg
 *
 * Copyright (c) 2026 xDev-Language
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "inkey.ch"
#include "dbinfo.ch"
#include "xfaktura.ch"

PROCEDURE p_Firma( oWindow )

   LOCAL oDialog
   LOCAL oToolbar
   LOCAL oPanel
   LOCAL oTabControl
   LOCAL oPage
   LOCAL oStatus

   IF ! s_DbOpen()
      RETURN
   ENDIF

   oDialog := gui_Dialog():New( oWindow, "Dane firmy", 720, 590 )
   oDialog:background := 0xe9edf1

   oStatus := gui_StatusBar():New( oDialog )
   oStatus:name := "STATUS_BAR"
   oStatus:font := gui_Font():New( NIL, .F., .F., "xFont 9x18" )
   oStatus:Add( 0 )
   oStatus:Add( 60 )
   oStatus:scoreboard := 2

   oToolbar := gui_Toolbar():New( oDialog, "Bottom" )
   oToolbar:Add( "F1-Pomoc",    NIL, {|| s_Pomoc( oDialog ) }, NIL, "F1" )
   oToolbar:AddSeparator()
   oToolbar:Add( "F4-Edycja",   NIL, {|| s_Popraw( oDialog ) }, NIL, "F4" )
   oToolbar:AddSeparator()
   oToolbar:Add( "Esc-Zamknij", NIL, {|| oDialog:Close() },     NIL, "Esc" )

   oPanel := gui_Panel():New( oDialog )

   oTabControl := gui_TabControl():New( oPanel, 10, 10, oPanel:width - 20, oPanel:height - 20 )
   oTabControl:name   := "ZAKLADKI"
   oTabControl:anchor := "LTRB"

   oPage := oTabControl:AddPage( "Dane firmy" )
   gui_GroupBox():New( oPage, 10, 8, 660, 110 )
   s_Opis( oPage,  23, 15, "Numer NIP:" )
   s_Opis( oPage,  53, 15, "Nazwa pełna:" )
   s_Opis( oPage,  83, 15, "Nazwa skrócona:" )
   gui_GroupBox():New( oPage, 10, 126, 660, 272, "Adres siedziby firmy" )
   s_Opis( oPage, 153, 15, "Kod kraju:" )
   s_Opis( oPage, 183, 15, "Województwo:" )
   s_Opis( oPage, 213, 15, "Powiat:" )
   s_Opis( oPage, 243, 15, "Gmina:" )
   s_Opis( oPage, 273, 15, "Ulica:" )
   s_Opis( oPage, 303, 15, "Nr domu / lokalu:" )
   s_Opis( oPage, 333, 15, "Kod / Miejscowość:" )
   s_Opis( oPage, 363, 15, "Poczta:" )

   s_Pole( oPage, 175,  20, 20, "NIP__FIRMY" )
   s_Pole( oPage, 175,  50, 40, "NAZWAFIRMY" )
   s_Pole( oPage, 175,  80, 40, "NAZWASKROC" )
   s_Pole( oPage, 175, 150,  2, "KRAJ_FIRMY" )
   s_Pole( oPage, 175, 180, 40, "WOJEWODZTW" )
   s_Pole( oPage, 175, 210, 40, "POWIATFIRM" )
   s_Pole( oPage, 175, 240, 40, "GMINAFIRMY" )
   s_Pole( oPage, 175, 270, 40, "ULICAFIRMY" )
   s_Pole( oPage, 175, 300,  9, "NRDOMUFIRM" )
   s_Pole( oPage, 274, 300, 10, "NRLOKALUFI" )
   s_Pole( oPage, 175, 330,  6, "KODPOCZ" )
   s_Pole( oPage, 247, 330, 32, "MIASTO" )
   s_Pole( oPage, 175, 360, 40, "POCZTAFIRM" )

   oPage := oTabControl:AddPage( "Dane działalności" )
   gui_GroupBox():New( oPage, 10, 8, 660, 200, "Prowadzona działalność" )
   s_Opis( oPage,  33, 15, "Data rozpoczęcia:" )
   s_Opis( oPage,  63, 15, "Numer REGON:" )
   s_Opis( oPage,  93, 15, "Rodzaj działalności:" )
   s_Opis( oPage, 123, 15, "Kod PKD:" )
   s_Opis( oPage, 153, 15, "Numer KRS:" )
   s_Opis( oPage, 183, 15, "Numer BDO:" )
   gui_GroupBox():New( oPage, 10, 216, 660, 140, "Wpis do ewidencji lub rejestru" )
   s_Opis( oPage, 241, 15, "Organ ewidencji:" )
   s_Opis( oPage, 271, 15, "Nazwa rejestru:" )
   s_Opis( oPage, 301, 15, "Data rejestracji:" )
   s_Opis( oPage, 331, 15, "Numer w ewidencji:" )

   s_Pole( oPage, 175,  30, 10, "D_ROZPOCZE" )
   s_Pole( oPage, 175,  60, 14, "NR___REGON" )
   s_Pole( oPage, 175,  90, 44, "RODZAJDZIA" )
   s_Pole( oPage, 175, 120,  7, "KOD____PKD" )
   s_Pole( oPage, 175, 150, 10, "NR_____KRS" )
   s_Pole( oPage, 175, 180,  9, "NR_____BDO" )
   s_Pole( oPage, 175, 238, 44, "ORGANREJES" )
   s_Pole( oPage, 175, 268, 44, "NAZWAREJES" )
   s_Pole( oPage, 175, 298, 10, "DATA_REJES" )
   s_Pole( oPage, 175, 328, 20, "NRREJESTRU" )

   oPage := oTabControl:AddPage( "Konto bankowe" )
   gui_CheckBox():New( oPage, 20, 12, 320, 20, "Drukuj konto bankowe na fakturze" ):name := "DRUK_BANK"
   gui_GroupBox():New( oPage, 10, 38, 660, 150, "Rachunek pierwszy" )
   s_Opis( oPage,  63, 15, "Kraj banku:" )
   s_Opis( oPage,  93, 15, "Nazwa banku:" )
   s_Opis( oPage, 123, 15, "Numer rachunku:" )
   s_Opis( oPage, 153, 15, "Kod SWIFT:" )
   gui_GroupBox():New( oPage, 10, 198, 660, 150, "Rachunek drugi" )
   s_Opis( oPage, 223, 15, "Kraj banku:" )
   s_Opis( oPage, 253, 15, "Nazwa banku:" )
   s_Opis( oPage, 283, 15, "Numer rachunku:" )
   s_Opis( oPage, 313, 15, "Kod SWIFT:" )

   s_Pole( oPage, 175,  60, 26, "KRAJ_BANKU" )
   s_Pole( oPage, 175,  90, 44, "NAZWABANKU" )
   s_Pole( oPage, 175, 120, 34, "NRRACHUNKU" )
   s_Pole( oPage, 175, 150, 11, "SWIFT_BANK" )
   s_Pole( oPage, 175, 220, 26, "KRAJ_BANK2" )
   s_Pole( oPage, 175, 250, 44, "NAZWABANK2" )
   s_Pole( oPage, 175, 280, 34, "NRRACHUNK2" )
   s_Pole( oPage, 175, 310, 11, "SWIFT_BAN2" )

   gui_RadioButton():New( oPage, 540,  62, 110, 20, "Drukuj to" ):name := "DRUKUJ_1"
   gui_RadioButton():New( oPage, 540, 222, 110, 20, "Drukuj to" ):name := "DRUKUJ_2"

   oPage := oTabControl:AddPage( "Dane kontaktowe" )
   gui_GroupBox():New( oPage, 10, 8, 660, 140 )
   s_Opis( oPage,  33, 15, "Telefon:" )
   s_Opis( oPage,  63, 15, "Telefon drugi:" )
   s_Opis( oPage,  93, 15, "E-mail:" )
   s_Opis( oPage, 123, 15, "Strona www:" )

   s_Pole( oPage, 175,  30, 20, "TEL_FIRMY1" )
   s_Pole( oPage, 175,  60, 20, "TEL_FIRMY2" )
   s_Pole( oPage, 175,  90, 44, "E_MAILFIRM" )
   s_Pole( oPage, 175, 120, 44, "WWW__FIRMY" )

   oPage := oTabControl:AddPage( "Dane do urzędów" )
   gui_GroupBox():New( oPage, 10, 8, 660, 80, "Urząd skarbowy" )
   s_Opis( oPage, 33, 15, "Kod urzędu:" )
   s_Opis( oPage, 63, 15, "Nazwa urzędu:" )

   s_Pole( oPage, 175, 30,  4, "KOD_URZEDU" )
   s_Pole( oPage, 175, 60, 44, "NAZWAURZED" )

   oPage := oTabControl:AddPage( "Faktury" )
   gui_CheckBox():New( oPage, 20, 12, 320, 20, "Firma jest płatnikiem podatku VAT" ):name := "FORMA__VAT"
   gui_GroupBox():New( oPage, 10, 38, 660, 60, "Zwolnienie z VAT (stawka zw)" )
   s_Opis( oPage, 63, 15, "Podstawa prawna:" )
   s_Pole( oPage, 175, 60, 44, "ZWOLNIENIE" )

   oPage := oTabControl:AddPage( "KSeF" )
   gui_GroupBox():New( oPage, 10, 8, 400, 90, "Środowisko KSeF" )
   gui_RadioButton():New( oPage, 30, 33, 360, 20, "Testowe (próbny, do testów)" ):name     := "SROD_1"
   gui_RadioButton():New( oPage, 30, 63, 360, 20, "Produkcyjne (prawdziwe faktury)" ):name := "SROD_3"

   AEval( s_Wybor( oDialog ), {| oWybor | oWybor:enabled := .F. } )

   s_Okno( oDialog )

   oDialog:Center()
   oDialog:ShowModal()

   FIRMA->( dbCloseArea() )

RETURN

/* ---------------------------------------------------------------------------------------------
   Baza
   --------------------------------------------------------------------------------------------- */

STATIC FUNCTION s_Struct()
RETURN { ;
   { "NIP__FIRMY",     "C",  20, 0 }, ;
   { "NAZWAFIRMY",     "M",  10, 0 }, ;
   { "NAZWASKROC",     "C",  40, 0 }, ;
   { "KRAJ_FIRMY",     "C",   2, 0 }, ;
   { "WOJEWODZTW",     "C",  20, 0 }, ;
   { "POWIATFIRM",     "C",  40, 0 }, ;
   { "GMINAFIRMY",     "C",  40, 0 }, ;
   { "ULICAFIRMY",     "C",  60, 0 }, ;
   { "NRDOMUFIRM",     "C",   9, 0 }, ;
   { "NRLOKALUFI",     "C",  10, 0 }, ;
   { "MIASTO",         "C",  40, 0 }, ;
   { "KODPOCZ",        "C",   6, 0 }, ;
   { "POCZTAFIRM",     "C",  40, 0 }, ;
   { "D_ROZPOCZE",     "D",   8, 0 }, ;
   { "NR___REGON",     "C",  14, 0 }, ;
   { "RODZAJDZIA",     "C",  60, 0 }, ;
   { "KOD____PKD",     "C",   7, 0 }, ;
   { "NR_____KRS",     "C",  10, 0 }, ;
   { "NR_____BDO",     "C",   9, 0 }, ;
   { "ORGANREJES",     "C",  60, 0 }, ;
   { "NAZWAREJES",     "C",  60, 0 }, ;
   { "DATA_REJES",     "D",   8, 0 }, ;
   { "NRREJESTRU",     "C",  20, 0 }, ;
   { "DRUK_BANK",      "L",   1, 0 }, ;
   { "KRAJ_BANKU",     "C",  26, 0 }, ;
   { "NAZWABANKU",     "C",  60, 0 }, ;
   { "NRRACHUNKU",     "C",  34, 0 }, ;
   { "SWIFT_BANK",     "C",  11, 0 }, ;
   { "KRAJ_BANK2",     "C",  26, 0 }, ;
   { "NAZWABANK2",     "C",  60, 0 }, ;
   { "NRRACHUNK2",     "C",  34, 0 }, ;
   { "SWIFT_BAN2",     "C",  11, 0 }, ;
   { "DRUKUJ_TO",      "N",   1, 0 }, ;
   { "TEL_FIRMY1",     "C",  20, 0 }, ;
   { "TEL_FIRMY2",     "C",  20, 0 }, ;
   { "E_MAILFIRM",     "C",  60, 0 }, ;
   { "WWW__FIRMY",     "C",  60, 0 }, ;
   { "KOD_URZEDU",     "C",   4, 0 }, ;
   { "NAZWAURZED",     "C",  60, 0 }, ;
   { "FORMA__VAT",     "L",   1, 0 }, ;
   { "ZWOLNIENIE",     "C", 200, 0 }, ;
   { "KSEF_SROD",      "N",   1, 0 } }

STATIC FUNCTION s_DbOpen()

   LOCAL cBaza := "firma" + DirSepToOS( "\" ) + "firma"

   IF ! FileExists( cBaza + ".dbf" )
      dbCreate( cBaza, s_Struct() )
   ENDIF

   dbSelectArea( 0 )
   IF ! NetUse( cBaza, .F., NIL, "FIRMA" )
      RETURN .F.
   ENDIF

   IF ! s_Okay()
      FIRMA->( dbCloseArea() )
      gui_MsgInfo( "Zmiana struktury bazy firmy", "Dane firmy" )
      s_Rekonstrukcja()
      dbSelectArea( 0 )
      IF ! NetUse( cBaza, .F., NIL, "FIRMA" )
         RETURN .F.
      ENDIF
      IF ! s_Okay()
         FIRMA->( dbCloseArea() )
         RETURN .F.
      ENDIF
   ENDIF

   IF FIRMA->( LastRec() ) == 0
      dbSelectArea( "FIRMA" )
      IF NetAppBlank()
         FIRMA->KRAJ_FIRMY := "PL"
         FIRMA->DRUKUJ_TO  := 1
         FIRMA->FORMA__VAT := .T.
         FIRMA->KSEF_SROD  := 1
         dbCommit()
         dbUnlock()
      ENDIF
   ENDIF
   FIRMA->( dbGoTop() )

RETURN .T.

STATIC FUNCTION s_Okay()

   LOCAL aWzor := s_Struct()
   LOCAL aBaza := FIRMA->( dbStruct() )
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

   LOCAL cBaza := "firma" + DirSepToOS( "\" ) + "firma"
   LOCAL cTmp  := "firma" + DirSepToOS( "\" ) + "tmp.dbf"

   LOCAL cExt   := RddInfo( RDDI_MEMOEXT )
   LOCAL cStary := IIF( FileExists( cBaza + ".fpt" ), ".fpt", cExt )
   LOCAL cMemo  := "firma" + DirSepToOS( "\" ) + "tmp" + cStary

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
   IF ! NetUse( cBaza, .T., NIL, "FIRMA" )
      FErase( cBaza + ".dbf" )
      FErase( cBaza + cExt )
      FRename( cTmp, cBaza + ".dbf" )
      FRename( cMemo, cBaza + cStary )
      RETURN
   ENDIF
   FIRMA->( DbAppendFrom( cTmp ) )
   FIRMA->( dbCloseArea() )
   FErase( cTmp )
   FErase( cMemo )

RETURN

FUNCTION p_FirmaPobierzKsef( cNip, nSrodowisko )

   IF ! s_DbOpen()
      RETURN .F.
   ENDIF
   cNip        := AllTrim( FIRMA->NIP__FIRMY )
   nSrodowisko := FIRMA->KSEF_SROD
   FIRMA->( dbCloseArea() )

RETURN .T.

FUNCTION p_FirmaPobierzDane()

   LOCAL hFirma := { => }
   LOCAL nPole

   IF ! s_DbOpen()
      RETURN NIL
   ENDIF
   FOR nPole := 1 TO FIRMA->( FCount() )
      hFirma[ FIRMA->( FieldName( nPole ) ) ] := FIRMA->( FieldGet( nPole ) )
   NEXT
   FIRMA->( dbCloseArea() )

RETURN hFirma

STATIC PROCEDURE s_Opis( oPage, nY, nLen, cText )

   gui_Say():New( oPage, 20, nY, nLen, 20, cText )

RETURN

STATIC PROCEDURE s_Pole( oPage, nX, nY, nLen, cName )

   LOCAL oSay := gui_Say():New( oPage, nX, nY, nLen, 24 )

   oSay:name   := cName
   oSay:border := .T.

RETURN

STATIC PROCEDURE s_Pomoc( oWindow )

   p_Pomoc( oWindow, "Dane firmy", ;
      Eol() + ;
      "Oglądanie" + Eol() + ;
      Eol() + ;
      "F1             pomoc" + Eol() + ;
      "F4             edycja danych firmy" + Eol() + ;
      "Esc            zamknięcie okna" + Eol() + ;
      Eol() + ;
      "Wpisywanie danych" + Eol() + ;
      Eol() + ;
      "Enter          następne pole, na ostatnim polu ostatniej zakładki zapis" + Eol() + ;
      "Tab            następne pole, bez zapisu" + Eol() + ;
      "Shift+Tab      poprzednie pole" + Eol() + ;
      "Ctrl+Tab       następna zakładka danych" + Eol() + ;
      "Ins            wstawianie / zastępowanie znaków, Ins na pasku stanu" + Eol() + ;
      "Spacja         zaznaczenie pola wyboru albo opcji" + Eol() + ;
      "Shift+Enter    nowa linia w nazwie pełnej" + Eol() + ;
      "PgUp, PgDn     zapis" + Eol() + ;
      "Esc            bez zapisu" + Eol() + ;
      Eol() + ;
      "Zakładki" + Eol() + ;
      Eol() + ;
      "Dane firmy         NIP, nazwa i adres sprzedawcy na fakturze i w KSeF" + Eol() + ;
      "Dane działalności  REGON, PKD, KRS, BDO i wpis do ewidencji" + Eol() + ;
      "Konto bankowe      konta firmy, które drukować na fakturze" + Eol() + ;
      "Dane kontaktowe    telefony, e-mail i strona www" + Eol() + ;
      "Dane do urzędów    urząd skarbowy firmy" + Eol() + ;
      "Faktury            płatnik VAT, podstawa prawna zwolnienia z VAT" + Eol() + ;
      "KSeF               środowisko: testowe do prób, produkcyjne naprawdę" )

RETURN

STATIC FUNCTION s_Wybor( oDialog )
RETURN { oDialog:DRUK_BANK, oDialog:DRUKUJ_1, oDialog:DRUKUJ_2, oDialog:FORMA__VAT, ;
         oDialog:SROD_1, oDialog:SROD_3 }

STATIC PROCEDURE s_Okno( oDialog )

   oDialog:NIP__FIRMY:text := FIRMA->NIP__FIRMY
   oDialog:NAZWAFIRMY:text := StrTran( FIRMA->NAZWAFIRMY, Eol( FIRMA->NAZWAFIRMY ), " " )
   oDialog:NAZWASKROC:text := FIRMA->NAZWASKROC
   oDialog:KRAJ_FIRMY:text := FIRMA->KRAJ_FIRMY
   oDialog:WOJEWODZTW:text := FIRMA->WOJEWODZTW
   oDialog:POWIATFIRM:text := FIRMA->POWIATFIRM
   oDialog:GMINAFIRMY:text := FIRMA->GMINAFIRMY
   oDialog:ULICAFIRMY:text := FIRMA->ULICAFIRMY
   oDialog:NRDOMUFIRM:text := FIRMA->NRDOMUFIRM
   oDialog:NRLOKALUFI:text := FIRMA->NRLOKALUFI
   oDialog:KODPOCZ:text := FIRMA->KODPOCZ
   oDialog:MIASTO:text := FIRMA->MIASTO
   oDialog:POCZTAFIRM:text := FIRMA->POCZTAFIRM
   oDialog:D_ROZPOCZE:text := IIF( Empty( FIRMA->D_ROZPOCZE ), "", DToC( FIRMA->D_ROZPOCZE ) )
   oDialog:NR___REGON:text := FIRMA->NR___REGON
   oDialog:RODZAJDZIA:text := FIRMA->RODZAJDZIA
   oDialog:KOD____PKD:text := FIRMA->KOD____PKD
   oDialog:NR_____KRS:text := FIRMA->NR_____KRS
   oDialog:NR_____BDO:text := FIRMA->NR_____BDO
   oDialog:ORGANREJES:text := FIRMA->ORGANREJES
   oDialog:NAZWAREJES:text := FIRMA->NAZWAREJES
   oDialog:DATA_REJES:text := IIF( Empty( FIRMA->DATA_REJES ), "", DToC( FIRMA->DATA_REJES ) )
   oDialog:NRREJESTRU:text := FIRMA->NRREJESTRU
   oDialog:DRUK_BANK:value := FIRMA->DRUK_BANK
   oDialog:KRAJ_BANKU:text := FIRMA->KRAJ_BANKU
   oDialog:NAZWABANKU:text := FIRMA->NAZWABANKU
   oDialog:NRRACHUNKU:text := FIRMA->NRRACHUNKU
   oDialog:SWIFT_BANK:text := FIRMA->SWIFT_BANK
   oDialog:KRAJ_BANK2:text := FIRMA->KRAJ_BANK2
   oDialog:NAZWABANK2:text := FIRMA->NAZWABANK2
   oDialog:NRRACHUNK2:text := FIRMA->NRRACHUNK2
   oDialog:SWIFT_BAN2:text := FIRMA->SWIFT_BAN2
   oDialog:DRUKUJ_1:value  := FIRMA->DRUKUJ_TO != 2
   oDialog:DRUKUJ_2:value  := FIRMA->DRUKUJ_TO == 2
   oDialog:TEL_FIRMY1:text := FIRMA->TEL_FIRMY1
   oDialog:TEL_FIRMY2:text := FIRMA->TEL_FIRMY2
   oDialog:E_MAILFIRM:text := FIRMA->E_MAILFIRM
   oDialog:WWW__FIRMY:text := FIRMA->WWW__FIRMY
   oDialog:KOD_URZEDU:text := FIRMA->KOD_URZEDU
   oDialog:NAZWAURZED:text := FIRMA->NAZWAURZED
   oDialog:FORMA__VAT:value := FIRMA->FORMA__VAT
   oDialog:ZWOLNIENIE:text := FIRMA->ZWOLNIENIE
   oDialog:SROD_1:value    := FIRMA->KSEF_SROD != 3
   oDialog:SROD_3:value    := FIRMA->KSEF_SROD == 3

RETURN

STATIC PROCEDURE s_Popraw( oDialog )

   LOCAL GetList := {}
   LOCAL oPage1  := oDialog:ZAKLADKI:Page( 1 )
   LOCAL oPage2  := oDialog:ZAKLADKI:Page( 2 )
   LOCAL oPage3  := oDialog:ZAKLADKI:Page( 3 )
   LOCAL oPage4  := oDialog:ZAKLADKI:Page( 4 )
   LOCAL oPage5  := oDialog:ZAKLADKI:Page( 5 )
   LOCAL oPage6  := oDialog:ZAKLADKI:Page( 6 )
   LOCAL cNip       := FIRMA->NIP__FIRMY
   LOCAL cNazwa     := FIRMA->NAZWAFIRMY
   LOCAL cSkrot     := FIRMA->NAZWASKROC
   LOCAL cKraj      := FIRMA->KRAJ_FIRMY
   LOCAL cWoj       := FIRMA->WOJEWODZTW
   LOCAL cPowiat    := FIRMA->POWIATFIRM
   LOCAL cGmina     := FIRMA->GMINAFIRMY
   LOCAL cUlica     := FIRMA->ULICAFIRMY
   LOCAL cNrDomu    := FIRMA->NRDOMUFIRM
   LOCAL cNrLokalu  := FIRMA->NRLOKALUFI
   LOCAL cKodPocz   := FIRMA->KODPOCZ
   LOCAL cMiasto    := FIRMA->MIASTO
   LOCAL cPoczta    := FIRMA->POCZTAFIRM
   LOCAL dRozpocz   := FIRMA->D_ROZPOCZE
   LOCAL cRegon     := FIRMA->NR___REGON
   LOCAL cRodzaj    := FIRMA->RODZAJDZIA
   LOCAL cPkd       := FIRMA->KOD____PKD
   LOCAL cKrs       := FIRMA->NR_____KRS
   LOCAL cBdo       := FIRMA->NR_____BDO
   LOCAL cOrgan     := FIRMA->ORGANREJES
   LOCAL cRejestr   := FIRMA->NAZWAREJES
   LOCAL dRejestr   := FIRMA->DATA_REJES
   LOCAL cNrRejes   := FIRMA->NRREJESTRU
   LOCAL cKrajBank1 := FIRMA->KRAJ_BANKU
   LOCAL cNazwaBank1 := FIRMA->NAZWABANKU
   LOCAL cKontoNr1  := FIRMA->NRRACHUNKU
   LOCAL cSwift1    := FIRMA->SWIFT_BANK
   LOCAL cKrajBank2 := FIRMA->KRAJ_BANK2
   LOCAL cNazwaBank2 := FIRMA->NAZWABANK2
   LOCAL cKontoNr2  := FIRMA->NRRACHUNK2
   LOCAL cSwift2    := FIRMA->SWIFT_BAN2
   LOCAL cTelefon1  := FIRMA->TEL_FIRMY1
   LOCAL cTelefon2  := FIRMA->TEL_FIRMY2
   LOCAL cEmail     := FIRMA->E_MAILFIRM
   LOCAL cWww       := FIRMA->WWW__FIRMY
   LOCAL cKodUrzedu := FIRMA->KOD_URZEDU
   LOCAL cUrzad     := FIRMA->NAZWAURZED
   LOCAL cZwolnienie := FIRMA->ZWOLNIENIE
   LOCAL aWybor     := s_Wybor( oDialog )
   LOCAL nGet

   AAdd( GetList, gui_Get():New( oPage1, 175,  20,  20, NIL, @cNip ) )
   AAdd( GetList, gui_Get():New( oPage1, 175,  50,  40, NIL, @cNazwa, NIL, 4, 512 ) )
   AAdd( GetList, gui_Get():New( oPage1, 175,  80,  40, NIL, @cSkrot ) )
   AAdd( GetList, gui_Get():New( oPage1, 175, 150, NIL, NIL, @cKraj, "@! AA" ) )
   AAdd( GetList, gui_Get():New( oPage1, 175, 180,  40, NIL, @cWoj ) )
   AAdd( GetList, gui_Get():New( oPage1, 175, 210,  40, NIL, @cPowiat ) )
   AAdd( GetList, gui_Get():New( oPage1, 175, 240,  40, NIL, @cGmina ) )
   AAdd( GetList, gui_Get():New( oPage1, 175, 270,  40, NIL, @cUlica ) )
   AAdd( GetList, gui_Get():New( oPage1, 175, 300, NIL, NIL, @cNrDomu ) )
   AAdd( GetList, gui_Get():New( oPage1, 274, 300, NIL, NIL, @cNrLokalu ) )
   AAdd( GetList, gui_Get():New( oPage1, 175, 330, NIL, NIL, @cKodPocz, "99-999" ) )
   AAdd( GetList, gui_Get():New( oPage1, 247, 330,  32, NIL, @cMiasto ) )
   AAdd( GetList, gui_Get():New( oPage1, 175, 360,  40, NIL, @cPoczta ) )
   AAdd( GetList, gui_Get():New( oPage2, 175,  30, NIL, NIL, @dRozpocz ) )
   AAdd( GetList, gui_Get():New( oPage2, 175,  60, NIL, NIL, @cRegon ) )
   AAdd( GetList, gui_Get():New( oPage2, 175,  90,  44, NIL, @cRodzaj ) )
   AAdd( GetList, gui_Get():New( oPage2, 175, 120, NIL, NIL, @cPkd, "@! 99.99.A" ) )
   AAdd( GetList, gui_Get():New( oPage2, 175, 150, NIL, NIL, @cKrs, "9999999999" ) )
   AAdd( GetList, gui_Get():New( oPage2, 175, 180, NIL, NIL, @cBdo, "999999999" ) )
   AAdd( GetList, gui_Get():New( oPage2, 175, 238,  44, NIL, @cOrgan ) )
   AAdd( GetList, gui_Get():New( oPage2, 175, 268,  44, NIL, @cRejestr ) )
   AAdd( GetList, gui_Get():New( oPage2, 175, 298, NIL, NIL, @dRejestr ) )
   AAdd( GetList, gui_Get():New( oPage2, 175, 328, NIL, NIL, @cNrRejes ) )
   AAdd( GetList, oDialog:DRUK_BANK )
   AAdd( GetList, gui_Get():New( oPage3, 175,  60, NIL, NIL, @cKrajBank1 ) )
   AAdd( GetList, oDialog:DRUKUJ_1 )
   AAdd( GetList, gui_Get():New( oPage3, 175,  90,  44, NIL, @cNazwaBank1 ) )
   AAdd( GetList, gui_Get():New( oPage3, 175, 120, NIL, NIL, @cKontoNr1 ) )
   AAdd( GetList, gui_Get():New( oPage3, 175, 150, NIL, NIL, @cSwift1, "@!" ) )
   AAdd( GetList, gui_Get():New( oPage3, 175, 220, NIL, NIL, @cKrajBank2 ) )
   AAdd( GetList, oDialog:DRUKUJ_2 )
   AAdd( GetList, gui_Get():New( oPage3, 175, 250,  44, NIL, @cNazwaBank2 ) )
   AAdd( GetList, gui_Get():New( oPage3, 175, 280, NIL, NIL, @cKontoNr2 ) )
   AAdd( GetList, gui_Get():New( oPage3, 175, 310, NIL, NIL, @cSwift2, "@!" ) )
   AAdd( GetList, gui_Get():New( oPage4, 175,  30, NIL, NIL, @cTelefon1 ) )
   AAdd( GetList, gui_Get():New( oPage4, 175,  60, NIL, NIL, @cTelefon2 ) )
   AAdd( GetList, gui_Get():New( oPage4, 175,  90,  44, NIL, @cEmail ) )
   AAdd( GetList, gui_Get():New( oPage4, 175, 120,  44, NIL, @cWww ) )
   AAdd( GetList, gui_Get():New( oPage5, 175,  30, NIL, NIL, @cKodUrzedu, "9999" ) )
   AAdd( GetList, gui_Get():New( oPage5, 175,  60,  44, NIL, @cUrzad ) )
   AAdd( GetList, oDialog:FORMA__VAT )
   AAdd( GetList, gui_Get():New( oPage6, 175,  60,  44, NIL, @cZwolnienie ) )
   AAdd( GetList, oDialog:SROD_1 )
   AAdd( GetList, oDialog:SROD_3 )
   AEval( aWybor, {| oWybor | oWybor:enabled := .T. } )

   oDialog:STATUS_BAR:text := " Tryb edycji --> PgUp PgDn Enter = zapisz, Esc = bez zapisu"
   oDialog:STATUS_BAR:background := 0x73264d
   oDialog:STATUS_BAR:foreground := 0xffffff

   oDialog:ReadModal( GetList, 1 )

   oDialog:STATUS_BAR:text       := ""
   oDialog:STATUS_BAR:background := NIL
   oDialog:STATUS_BAR:foreground := NIL

   AEval( aWybor, {| oWybor | oWybor:enabled := .F. } )
   FOR nGet := 1 TO Len( GetList )
      IF AScan( aWybor, {| oWybor | oWybor == GetList[ nGet ] } ) == 0
         GetList[ nGet ]:Destroy()
      ENDIF
   NEXT

   IF LastKey() == K_ESC

      s_Okno( oDialog )
      RETURN
   ENDIF

   dbSelectArea( "FIRMA" )
   IF ! NetRLock()
      s_Okno( oDialog )
      RETURN
   ENDIF

   FIRMA->NIP__FIRMY := cNip
   FIRMA->NAZWAFIRMY := AllTrim( cNazwa )
   FIRMA->NAZWASKROC := cSkrot
   FIRMA->KRAJ_FIRMY := cKraj
   FIRMA->WOJEWODZTW := cWoj
   FIRMA->POWIATFIRM := cPowiat
   FIRMA->GMINAFIRMY := cGmina
   FIRMA->ULICAFIRMY := cUlica
   FIRMA->NRDOMUFIRM := cNrDomu
   FIRMA->NRLOKALUFI := cNrLokalu
   FIRMA->KODPOCZ := IIF( Empty( StrTran( cKodPocz, "-" ) ), "", cKodPocz )
   FIRMA->MIASTO := cMiasto
   FIRMA->POCZTAFIRM := cPoczta
   FIRMA->D_ROZPOCZE := dRozpocz
   FIRMA->NR___REGON := cRegon
   FIRMA->RODZAJDZIA := cRodzaj
   FIRMA->KOD____PKD := IIF( Empty( StrTran( cPkd, "." ) ), "", cPkd )
   FIRMA->NR_____KRS := cKrs
   FIRMA->NR_____BDO := cBdo
   FIRMA->ORGANREJES := cOrgan
   FIRMA->NAZWAREJES := cRejestr
   FIRMA->DATA_REJES := dRejestr
   FIRMA->NRREJESTRU := cNrRejes
   FIRMA->DRUK_BANK  := oDialog:DRUK_BANK:value
   FIRMA->KRAJ_BANKU := cKrajBank1
   FIRMA->NAZWABANKU := cNazwaBank1
   FIRMA->NRRACHUNKU := cKontoNr1
   FIRMA->SWIFT_BANK := cSwift1
   FIRMA->KRAJ_BANK2 := cKrajBank2
   FIRMA->NAZWABANK2 := cNazwaBank2
   FIRMA->NRRACHUNK2 := cKontoNr2
   FIRMA->SWIFT_BAN2 := cSwift2
   FIRMA->DRUKUJ_TO  := IIF( oDialog:DRUKUJ_2:value, 2, 1 )
   FIRMA->TEL_FIRMY1 := cTelefon1
   FIRMA->TEL_FIRMY2 := cTelefon2
   FIRMA->E_MAILFIRM := cEmail
   FIRMA->WWW__FIRMY := cWww
   FIRMA->KOD_URZEDU := cKodUrzedu
   FIRMA->NAZWAURZED := cUrzad
   FIRMA->FORMA__VAT := oDialog:FORMA__VAT:value
   FIRMA->ZWOLNIENIE := cZwolnienie
   FIRMA->KSEF_SROD := IIF( oDialog:SROD_3:value, 3, 1 )
   dbCommit()
   dbUnlock()

   s_Okno( oDialog )

RETURN
