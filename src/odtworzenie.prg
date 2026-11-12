/*
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: odtworzenie.prg
 *
 * Copyright (c) 2026 xDev-Language
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "xfaktura.ch"

PROCEDURE p_Odtworzenie( oWindow )

   LOCAL cStart
   LOCAL cKontrolny
   LOCAL cArchiwum
   LOCAL aArchiwum
   LOCAL aOstatnia
   LOCAL aPozycja
   LOCAL aPliki := {}
   LOCAL cPlik

   IF ! gui_MsgYesNo( "Czy wykonać odtworzenie danych?", "Odtworzenie" )
      RETURN
   ENDIF

   cStart := DiskName() + ":" + DirSepToOS( "\" ) + CurDir()
   cKontrolny := gui_FileOpenDialog( "Wskaż plik kontrolny kopii (firma\kopia.txt)", ;
                                     { { "Plik kontrolny kopii", "kopia.txt" } } )
   DirChange( cStart )
   IF Empty( cKontrolny )
      RETURN
   ENDIF
   IF ! Lower( Right( cKontrolny, Len( p_PlikKontrolny() ) ) ) == p_PlikKontrolny()
      gui_MsgError( "Wskazany plik nie jest plikiem kontrolnym kopii xFaktury:" + Eol() + cKontrolny, "Odtworzenie" )
      RETURN
   ENDIF
   cArchiwum := Left( cKontrolny, Len( cKontrolny ) - Len( p_PlikKontrolny() ) )

   aArchiwum := s_Kontrolny( cKontrolny )
   IF aArchiwum == NIL
      gui_MsgError( "Plik kontrolny kopii jest uszkodzony:" + Eol() + cKontrolny, "Odtworzenie" )
      RETURN
   ENDIF
   aOstatnia := s_Kontrolny( p_PlikKontrolny() )

   IF aOstatnia != NIL .AND. aArchiwum[ 1 ] < aOstatnia[ 1 ]
      IF ! gui_MsgYesNo( "Wskazane archiwum z " + s_Opis( aArchiwum[ 1 ] ) + Eol() + ;
                         "jest starsze od ostatniej kopii z " + s_Opis( aOstatnia[ 1 ] ) + "." + Eol() + ;
                         "Dane wprowadzone później zostaną utracone." + Eol() + ;
                         "Czy mimo to odtworzyć dane?", "Odtworzenie" )
         RETURN
      ENDIF
   ENDIF

   FOR EACH aPozycja IN aArchiwum[ 2 ]
      cPlik := aPozycja[ 1 ]
      IF ! FileExists( cArchiwum + cPlik ) .OR. ;
         Len( Directory( cArchiwum + cPlik ) ) == 0 .OR. Directory( cArchiwum + cPlik )[ 1 ][ 2 ] != aPozycja[ 2 ]
         gui_MsgError( "Archiwum jest niekompletne albo zmienione." + Eol() + ;
                       "Brak pliku lub inny rozmiar: " + cPlik, "Odtworzenie" )
         RETURN
      ENDIF
      AAdd( aPliki, cPlik )
   NEXT

   IF Len( aPliki ) == 0
      gui_MsgInfo( "Archiwum nie zawiera plików do odtworzenia.", "Odtworzenie" )
      RETURN
   ENDIF

   s_Kopiuj( oWindow, aPliki, cArchiwum )

RETURN

STATIC FUNCTION s_Kontrolny( cKontrolny )

   LOCAL cTekst
   LOCAL cLinia
   LOCAL cData   := ""
   LOCAL cGodzina := ""
   LOCAL nPlikow := -1
   LOCAL aPliki  := {}
   LOCAL nSpacja

   IF ! FileExists( cKontrolny )
      RETURN NIL
   ENDIF
   cTekst := StrTran( MemoRead( cKontrolny ), Chr( 13 ), "" )

   FOR EACH cLinia IN s_Linie( cTekst )
      DO CASE
      CASE Empty( cLinia ) .OR. Left( cLinia, 9 ) == "xFaktura "
      CASE Left( cLinia, 6 ) == "Data: "
         cData := SubStr( cLinia, 7 )
      CASE Left( cLinia, 9 ) == "Godzina: "
         cGodzina := SubStr( cLinia, 10 )
      CASE Left( cLinia, 5 ) == "Rok: "
      CASE Left( cLinia, Len( "Plików: " ) ) == "Plików: "

         nPlikow := Val( SubStr( cLinia, Len( "Plików: " ) + 1 ) )
      OTHERWISE
         nSpacja := RAt( " ", cLinia )
         IF nSpacja == 0
            RETURN NIL
         ENDIF
         AAdd( aPliki, { Left( cLinia, nSpacja - 1 ), Val( SubStr( cLinia, nSpacja + 1 ) ) } )
      ENDCASE
   NEXT

   IF Empty( cData ) .OR. Empty( cGodzina ) .OR. nPlikow != Len( aPliki )
      RETURN NIL
   ENDIF

RETURN { cData + " " + cGodzina, aPliki }

STATIC FUNCTION s_Linie( cTekst )

   LOCAL aLinie := {}
   LOCAL nPoz

   DO WHILE ( nPoz := At( Chr( 10 ), cTekst ) ) > 0
      AAdd( aLinie, Left( cTekst, nPoz - 1 ) )
      cTekst := SubStr( cTekst, nPoz + 1 )
   ENDDO
   IF ! Empty( cTekst )
      AAdd( aLinie, cTekst )
   ENDIF

RETURN aLinie

STATIC FUNCTION s_Opis( cKiedy )
RETURN Left( cKiedy, 4 ) + "-" + SubStr( cKiedy, 5, 2 ) + "-" + SubStr( cKiedy, 7 )

STATIC PROCEDURE s_Kopiuj( oWindow, aPliki, cArchiwum )

   LOCAL oDialog
   LOCAL oOpis
   LOCAL oPasek
   LOCAL oTimer
   LOCAL nPlik := 0
   LOCAL cBlad := ""

   oDialog := gui_Dialog():New( oWindow, "Odtworzenie danych", 460, 130 )
   oOpis   := gui_Label():New( oDialog, 20, 20, 420, 24, "" )
   oPasek  := gui_ProgressBar():New( oDialog, 20, 54, 420, 22 )
   oPasek:maximum := Len( aPliki )

   oTimer := gui_Timer():New( oDialog, 10, {|| ;
      nPlik++, ;
      oOpis:text := "Odtwarzanie: " + aPliki[ nPlik ] + "  (" + LTrim( Str( nPlik ) ) + " z " + LTrim( Str( Len( aPliki ) ) ) + ")", ;
      IIF( s_KopiujPlik( aPliki[ nPlik ], cArchiwum ), oPasek:value := nPlik, cBlad := aPliki[ nPlik ] ), ;
      IIF( ! Empty( cBlad ) .OR. nPlik == Len( aPliki ), ( oTimer:Stop(), oDialog:EndDialog( 1 ) ), NIL ) } )
   oTimer:Start()

   oDialog:ShowModal()

   IF ! Empty( cBlad )
      gui_MsgError( "Odtworzenie przerwane na pliku: " + cBlad + Eol() + ;
                    "Odtworzono " + LTrim( Str( nPlik - 1 ) ) + " z " + LTrim( Str( Len( aPliki ) ) ) + " plików." + Eol() + ;
                    "Dane są niespójne, powtórz odtworzenie.", "Odtworzenie" )
   ELSEIF nPlik < Len( aPliki )
      gui_MsgWarning( "Odtworzenie przerwane. Odtworzono " + LTrim( Str( nPlik ) ) + " z " + ;
                      LTrim( Str( Len( aPliki ) ) ) + " plików." + Eol() + ;
                      "Dane są niespójne, powtórz odtworzenie.", "Odtworzenie" )
   ELSE
      gui_MsgInfo( "Odtworzenie zakończone poprawnie." + Eol() + ;
                   "Odtworzono " + LTrim( Str( nPlik ) ) + " plików z:" + Eol() + cArchiwum, "Odtworzenie" )
   ENDIF

RETURN

STATIC FUNCTION s_KopiujPlik( cPlik, cArchiwum )

   LOCAL cSep := DirSepToOS( "\" )
   LOCAL i

   FOR i := 1 TO Len( cPlik )
      IF SubStr( cPlik, i, 1 ) == cSep .AND. ! DirExists( Left( cPlik, i ) )
         DirMake( Left( cPlik, i - 1 ) )
      ENDIF
   NEXT

RETURN FileCopy( cArchiwum + cPlik, cPlik ) == 0
