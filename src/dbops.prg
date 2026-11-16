/*
 * Copyright (c) 2026 xDev-Language
 *
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: dbutil.prg
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "dbinfo.ch"
#include "fileio.ch"

FUNCTION OpenDatabase( cBaza, aWzor, cAlias, cTytul )

   IF ! FileExists( cBaza + ".dbf" )
      dbCreate( cBaza, aWzor )
   ENDIF

   dbSelectArea( 0 )
   IF ! NetUse( cBaza, .F., NIL, cAlias )
      RETURN .F.
   ENDIF
   IF ( cAlias )->( DbInfo( DBI_DB_VERSION ) ) == "xDev 7" .AND. s_Okay( cAlias, aWzor )
      RETURN .T.
   ENDIF

   ( cAlias )->( dbCloseArea() )

RETURN .F.

PROCEDURE PackDatabase( cBaza, cAlias )

   IF FileExists( cBaza + ".dbf" )
      dbSelectArea( 0 )
      IF NetUse( cBaza, .T., NIL, cAlias )
         NetPack()
         ( cAlias )->( dbCloseArea() )
      ENDIF
   ENDIF

RETURN

STATIC FUNCTION s_Okay( cAlias, aWzor )

   LOCAL aBaza := ( cAlias )->( dbStruct() )
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
