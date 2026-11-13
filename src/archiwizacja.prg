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

#include "xfaktura.ch"

PROCEDURE p_Archiwizacja( oWindow )

   LOCAL cData := DToS( Date() )
   LOCAL cCel
   LOCAL cStart
   LOCAL aPliki := {}
   LOCAL cKatalog

   cData := Left( cData, 4 ) + "-" + SubStr( cData, 5, 2 ) + "-" + Right( cData, 2 )

   IF ! gui_MsgYesNo( "Czy wykonać archiwizację danych?", "Archiwizacja" )
      RETURN
   ENDIF

   cStart := DiskName() + ":" + DirSepToOS( "\" ) + CurDir()
   cCel := gui_FileSaveDialog( "Wskaż miejsce kopii danych", NIL, "xFaktura-kopia-" + cData )
   DirChange( cStart )
   IF Empty( cCel )
      RETURN
   ENDIF

   IF ! DirExists( cCel )
      DirMake( cCel )
   ENDIF
   IF ! DirExists( cCel )
      gui_MsgError( "Nie można utworzyć folderu kopii: " + cCel, "Archiwizacja" )
      RETURN
   ENDIF
   cCel += DirSepToOS( "\" )

   FOR EACH cKatalog IN { Left( p_RokPobierz(), 4 ), "firma", "kontrahenci", "ksef" }
      IF DirExists( cKatalog )
         s_Pliki( cKatalog + DirSepToOS( "\" ), aPliki )
      ENDIF
   NEXT

   IF Len( aPliki ) == 0
      gui_MsgInfo( "Brak plików do zarchiwizowania.", "Archiwizacja" )
      RETURN
   ENDIF

   s_Kopiuj( oWindow, aPliki, cCel )

RETURN

STATIC PROCEDURE s_Pliki( cKatalog, aPliki )

   LOCAL aPozycja

   FOR EACH aPozycja IN Directory( cKatalog + "*.*", "D" )
      IF aPozycja[ 1 ] == "." .OR. aPozycja[ 1 ] == ".."
         LOOP
      ENDIF
      IF "D" $ aPozycja[ 5 ]
         s_Pliki( cKatalog + aPozycja[ 1 ] + DirSepToOS( "\" ), aPliki )
      ELSEIF ! Lower( cKatalog + aPozycja[ 1 ] ) == p_PlikKontrolny()

         AAdd( aPliki, cKatalog + aPozycja[ 1 ] )
      ENDIF
   NEXT

RETURN

STATIC PROCEDURE s_Kopiuj( oWindow, aPliki, cCel )

   LOCAL oDialog
   LOCAL oOpis
   LOCAL oPasek
   LOCAL oTimer
   LOCAL nPlik := 0
   LOCAL cBlad := ""

   oDialog := gui_Dialog():New( oWindow, "Archiwizacja danych", 460, 130 )
   oOpis   := gui_Label():New( oDialog, 20, 20, 420, 24, "" )
   oPasek  := gui_ProgressBar():New( oDialog, 20, 54, 420, 22 )
   oPasek:maximum := Len( aPliki )

   oTimer := gui_Timer():New( oDialog, 10, {|| ;
      nPlik++, ;
      oOpis:text := "Kopiowanie: " + aPliki[ nPlik ] + "  (" + LTrim( Str( nPlik ) ) + " z " + LTrim( Str( Len( aPliki ) ) ) + ")", ;
      IIF( s_KopiujPlik( aPliki[ nPlik ], cCel ), oPasek:value := nPlik, cBlad := aPliki[ nPlik ] ), ;
      IIF( ! Empty( cBlad ) .OR. nPlik == Len( aPliki ), ( oTimer:Stop(), oDialog:EndDialog( 1 ) ), NIL ) } )
   oTimer:Start()

   oDialog:ShowModal()

   IF Empty( cBlad ) .AND. nPlik == Len( aPliki ) .AND. ;
      ( ! s_Kontrolny( aPliki ) .OR. ! s_KopiujPlik( p_PlikKontrolny(), cCel ) )
      gui_MsgError( "Nie można zapisać pliku kontrolnego: " + p_PlikKontrolny() + Eol() + ;
                    "Kopia w " + cCel + " jest niekompletna.", "Archiwizacja" )
      RETURN
   ENDIF

   IF ! Empty( cBlad )
      gui_MsgError( "Archiwizacja przerwana na pliku: " + cBlad + Eol() + ;
                    "Skopiowano " + LTrim( Str( nPlik - 1 ) ) + " z " + LTrim( Str( Len( aPliki ) ) ) + " plików.", "Archiwizacja" )
   ELSEIF nPlik < Len( aPliki )
      gui_MsgWarning( "Archiwizacja przerwana. Skopiowano " + LTrim( Str( nPlik ) ) + " z " + ;
                      LTrim( Str( Len( aPliki ) ) ) + " plików.", "Archiwizacja" )
   ELSE
      gui_MsgInfo( "Archiwizacja zakończona poprawnie." + Eol() + ;
                   "Skopiowano " + LTrim( Str( nPlik ) ) + " plików do:" + Eol() + cCel, "Archiwizacja" )
   ENDIF

RETURN

STATIC FUNCTION s_KopiujPlik( cPlik, cCel )

   LOCAL cSep := DirSepToOS( "\" )
   LOCAL i

   FOR i := 1 TO Len( cPlik )
      IF SubStr( cPlik, i, 1 ) == cSep .AND. ! DirExists( cCel + Left( cPlik, i ) )
         DirMake( cCel + Left( cPlik, i - 1 ) )
      ENDIF
   NEXT

RETURN FileCopy( cPlik, cCel + cPlik ) == 0

STATIC FUNCTION s_Kontrolny( aPliki )

   LOCAL cTekst
   LOCAL cPlik
   LOCAL aPozycja
   LOCAL nPlik

   cTekst := "xFaktura 0.0.0" + Eol() + ;
             "Data: " + DToS( Date() ) + Eol() + ;
             "Godzina: " + Time() + Eol() + ;
             "Rok: " + Left( p_RokPobierz(), 4 ) + Eol() + ;
             "Plików: " + LTrim( Str( Len( aPliki ) ) ) + Eol()

   FOR EACH cPlik IN aPliki
      aPozycja := Directory( cPlik )
      cTekst += cPlik + " " + IIF( Len( aPozycja ) > 0, LTrim( Str( aPozycja[ 1 ][ 2 ] ) ), "0" ) + Eol()
   NEXT

   nPlik := FCreate( p_PlikKontrolny() )
   IF nPlik < 0
      RETURN .F.
   ENDIF
   IF FWrite( nPlik, cTekst ) != Len( cTekst )
      FClose( nPlik )
      RETURN .F.
   ENDIF
   FClose( nPlik )

RETURN .T.
