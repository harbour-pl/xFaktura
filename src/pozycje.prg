/*
 * Copyright (c) 2026 xDev-Language
 *
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: pozycje.prg
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "inkey.ch"

#define MAKS_WARTOSC  1000000000

PROCEDURE p_PozycjeEdytuj( oDialog, cAlias, lNowa, cTytul, cKomunikat, lZero, bOdswiez )

   LOCAL GetList := {}
   LOCAL oOkno
   LOCAL nRecNo  := ( cAlias )->( RecNo() )
   LOCAL cNazwa
   LOCAL nIlosc
   LOCAL cJm
   LOCAL nCena
   LOCAL cStawka
   LOCAL nNetto
   LOCAL nVat

   IF ! lNowa .AND. ( cAlias )->( Eof() )
      RETURN
   ENDIF
   IF lNowa
      ( cAlias )->( dbGoBottom() )
      ( cAlias )->( dbSkip() )
   ENDIF
   cNazwa  := ( cAlias )->NAZWA_TOWA
   nIlosc  := IIF( lNowa, 1, ( cAlias )->ILOSC__FKT )
   cJm     := IIF( lNowa, "szt.", AllTrim( ( cAlias )->JM_____FKT ) )
   nCena   := ( cAlias )->CENA_JEDNO
   cStawka := PadR( IIF( lNowa, "23", AllTrim( ( cAlias )->STAWKA_VAT ) ), 2 )

   oOkno := gui_Dialog():New( oDialog, cTytul, 640, 200 )
   oOkno:background := 0xe9edf1

   s_Opis( oOkno, 20,  23, "Nazwa:" )
   s_Opis( oOkno, 20,  53, "Ilość / j.m.:" )
   s_Opis( oOkno, 20,  83, "Cena netto:" )
   s_Opis( oOkno, 20, 113, "Stawka VAT:" )

   AAdd( GetList, gui_Get():New( oOkno, 160,  20, 50, NIL, @cNazwa, NIL, NIL, 256 ) )
   AAdd( GetList, gui_Get():New( oOkno, 160,  50, 10, NIL, @nIlosc, "999999.999" ) )
   AAdd( GetList, gui_Get():New( oOkno, 260,  50,  6, NIL, @cJm, NIL, NIL, 10 ) )
   AAdd( GetList, gui_Get():New( oOkno, 160,  80, 11, NIL, @nCena, "99999999.99" ) )
   AAdd( GetList, gui_Get():New( oOkno, 160, 110,  2, NIL, @cStawka, "@K XX" ) )

   oDialog:PASEK:enabled := .F.
   oDialog:BRW:enabled   := .F.
   oOkno:Center()
   oOkno:Show()
   p_PozycjeTrybEdycji( oDialog, .T. )
   oOkno:ReadModal( GetList )
   p_PozycjeTrybEdycji( oDialog, .F. )
   oOkno:Close()
   oDialog:PASEK:enabled := .T.
   oDialog:BRW:enabled   := ( cAlias )->( LastRec() ) > 0

   IF LastKey() == K_ESC .OR. Empty( cNazwa )
      ( cAlias )->( dbGoto( nRecNo ) )
      Eval( bOdswiez )
      RETURN
   ENDIF
   IF p_PozycjeStawka( cStawka ) == NIL
      gui_MsgInfo( "Nieznana stawka VAT: " + AllTrim( cStawka ) + Eol() + "Dozwolone: 23, 22, 8, 7, 5, 4, 3, 0, zw, oo, np", cKomunikat )
      ( cAlias )->( dbGoto( nRecNo ) )
      Eval( bOdswiez )
      RETURN
   ENDIF
   IF nIlosc < 0 .OR. ( nIlosc == 0 .AND. ! lZero ) .OR. nCena < 0 .OR. Abs( nIlosc * nCena ) >= MAKS_WARTOSC
      gui_MsgInfo( "Ilość musi być " + IIF( lZero, "nieujemna", "większa od zera" ) + ", cena nieujemna," + Eol() + ;
                   "a wartość pozycji mniejsza niż 1 000 000 000.", cKomunikat )
      ( cAlias )->( dbGoto( nRecNo ) )
      Eval( bOdswiez )
      RETURN
   ENDIF
   cStawka := p_PozycjeStawka( cStawka )
   nNetto  := Round( nIlosc * nCena, 2 )
   nVat    := IIF( IsDigit( cStawka ), Round( nNetto * Val( cStawka ) / 100, 2 ), 0 )

   IF lNowa
      ( cAlias )->( dbAppend() )
      ( cAlias )->LP_FKT_ROW := ( cAlias )->( LastRec() )
   ENDIF
   ( cAlias )->NAZWA_TOWA := cNazwa
   ( cAlias )->ILOSC__FKT := nIlosc
   ( cAlias )->JM_____FKT := cJm
   ( cAlias )->CENA_JEDNO := nCena
   ( cAlias )->STAWKA_VAT := cStawka
   ( cAlias )->WART_NETTO := nNetto
   ( cAlias )->KWOTA__VAT := nVat
   ( cAlias )->WAR_BRUTTO := nNetto + nVat
   ( cAlias )->DATA_____P := Date()

   oDialog:BRW:Refresh()
   Eval( bOdswiez )

RETURN

PROCEDURE p_PozycjeUsun( oDialog, cAlias, cKomunikat, bOdswiez )

   LOCAL nLp := 0

   IF ( cAlias )->( Eof() ) .OR. ! gui_MsgYesNo( "Usunąć pozycję" + Eol() + AllTrim( ( cAlias )->NAZWA_TOWA ) + "?", cKomunikat )
      RETURN
   ENDIF
   ( cAlias )->( dbDelete() )
   ( cAlias )->( DbPack() )
   ( cAlias )->( dbEval( {|| ( cAlias )->LP_FKT_ROW := ++nLp } ) )
   ( cAlias )->( dbGoTop() )
   oDialog:BRW:Refresh()
   Eval( bOdswiez )

RETURN

PROCEDURE p_PozycjeTrybEdycji( oDialog, lWlacz )

   IF lWlacz
      oDialog:STATUS_BAR:text       := " Tryb edycji --> PgUp PgDn Enter = zapisz, Esc = bez zapisu"
      oDialog:STATUS_BAR:background := 0x73264d
      oDialog:STATUS_BAR:foreground := 0xffffff
   ELSE
      oDialog:STATUS_BAR:text       := ""
      oDialog:STATUS_BAR:background := NIL
      oDialog:STATUS_BAR:foreground := NIL
   ENDIF

RETURN

FUNCTION p_PozycjeStawka( cStawka )

   LOCAL cJest := Lower( AllTrim( cStawka ) )

RETURN IIF( AScan( { "23", "22", "8", "7", "5", "4", "3", "0", "zw", "oo", "np" }, {| c | c == cJest } ) > 0, cJest, NIL )

FUNCTION p_PozycjeSuma( cAlias, nNetto, nVat, lZw )

   LOCAL nRecNo := ( cAlias )->( RecNo() )

   nNetto := 0
   nVat   := 0
   lZw    := .F.
   ( cAlias )->( dbEval( {|| nNetto += ( cAlias )->WART_NETTO, nVat += ( cAlias )->KWOTA__VAT, ;
                             lZw := lZw .OR. AllTrim( ( cAlias )->STAWKA_VAT ) == "zw" } ) )
   ( cAlias )->( dbGoto( nRecNo ) )

RETURN Abs( nNetto ) < MAKS_WARTOSC .AND. Abs( nNetto + nVat ) < MAKS_WARTOSC

FUNCTION p_PozycjeZapisz( cAlias, nNr, cRodzaj, nLpOd, lPrzed, aDodane )

   ( cAlias )->( dbGoTop() )
   DO WHILE ! ( cAlias )->( Eof() )
      dbSelectArea( "FKTROW" )
      IF ! NetAppBlank( NIL, .F. )
         RETURN .F.
      ENDIF
      AAdd( aDodane, FKTROW->( RecNo() ) )
      FKTROW->NR_FAKTURY := nNr
      FKTROW->RODZAJ     := cRodzaj
      FKTROW->LP_FKT_ROW := nLpOd + ( cAlias )->LP_FKT_ROW
      FKTROW->KOD_TOWARU := ( cAlias )->KOD_TOWARU
      FKTROW->NAZWA_TOWA := ( cAlias )->NAZWA_TOWA
      FKTROW->JM_____FKT := ( cAlias )->JM_____FKT
      FKTROW->ILOSC__FKT := ( cAlias )->ILOSC__FKT
      FKTROW->CENA_JEDNO := ( cAlias )->CENA_JEDNO
      FKTROW->WART_NETTO := ( cAlias )->WART_NETTO
      FKTROW->STAWKA_VAT := ( cAlias )->STAWKA_VAT
      FKTROW->KWOTA__VAT := ( cAlias )->KWOTA__VAT
      FKTROW->WAR_BRUTTO := ( cAlias )->WAR_BRUTTO
      FKTROW->PRZED      := lPrzed
      FKTROW->DATA_____P := Date()
      dbCommit()
      ( cAlias )->( dbSkip() )
   ENDDO

RETURN .T.

PROCEDURE p_PozycjeWycofaj( aDodane )

   LOCAL nRec

   FOR EACH nRec IN aDodane
      FKTROW->( dbGoto( nRec ) )
      FKTROW->( dbDelete() )
   NEXT
   FKTROW->( dbCommit() )
   FKTROW->( dbUnlock() )

RETURN

STATIC PROCEDURE s_Opis( oPanel, nX, nY, cText )

   gui_Say():New( oPanel, nX, nY, 14, 20, cText )

RETURN
