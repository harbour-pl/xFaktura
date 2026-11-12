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

FUNCTION p_BazaPrzenies( cPlik, hNazwy )

   LOCAL nCel := Select()
   LOCAL nZrodlo := 0
   LOCAL nPole
   LOCAL nStare
   LOCAL nRekord
   LOCAL cPole
   LOCAL aPola := {}
   LOCAL lOkay := .F.
   LOCAL bBlad := ErrorBlock( {| oBlad | Break( oBlad ) } )

   BEGIN SEQUENCE
      dbSelectArea( 0 )
      dbUseArea( .F., NIL, cPlik, "TMP_MIGRACJA", .F., .T. )
      IF NetErr() .OR. ! Used()
         BREAK
      ENDIF
      nZrodlo := Select()
      FOR nPole := 1 TO ( nCel )->( FCount() )
         cPole := ( nCel )->( FieldName( nPole ) )
         nStare := ( nZrodlo )->( FieldPos( cPole ) )
         IF nStare == 0 .AND. HHasKey( hNazwy, cPole )
            nStare := ( nZrodlo )->( FieldPos( hNazwy[ cPole ] ) )
         ENDIF
         AAdd( aPola, nStare )
      NEXT
      FOR nRekord := 1 TO ( nZrodlo )->( LastRec() )
         ( nZrodlo )->( dbGoTo( nRekord ) )
         ( nCel )->( dbAppend() )
         IF NetErr()
            BREAK
         ENDIF
         FOR nPole := 1 TO Len( aPola )
            IF aPola[ nPole ] > 0
               ( nCel )->( FieldPut( nPole, ( nZrodlo )->( FieldGet( aPola[ nPole ] ) ) ) )
            ENDIF
         NEXT
         IF ( nZrodlo )->( Deleted() )
            ( nCel )->( dbDelete() )
         ENDIF
      NEXT
      ( nCel )->( dbCommit() )
      lOkay := ! NetErr()
   RECOVER
      lOkay := .F.
   END SEQUENCE

   IF nZrodlo > 0
      ( nZrodlo )->( dbCloseArea() )
   ENDIF
   dbSelectArea( nCel )
   ErrorBlock( bBlad )

RETURN lOkay
