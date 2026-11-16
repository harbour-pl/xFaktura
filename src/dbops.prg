/*
 * Copyright (c) 2026 xDev-Language
 *
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: dbops.prg
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "dbinfo.ch"

FUNCTION OpenDatabase( cBaza, aWzor, cAlias, cTytul )

   IF ! FileExists( cBaza + ".dbf" )
      dbCreate( cBaza, aWzor )
   ENDIF

   IF ! s_DbUse( cBaza, cAlias, cTytul )
      RETURN .F.
   ENDIF
   IF s_Okay( cAlias, aWzor )
      RETURN .T.
   ENDIF
   ( cAlias )->( dbCloseArea() )

   IF ! s_Rekonstrukcja( cBaza, aWzor, cAlias )
      gui_MsgError( "Nie udało się zmienić struktury bazy " + cBaza + "." + Eol() + ;
                    "Zamknij program na pozostałych stanowiskach i spróbuj ponownie.", cTytul )
      RETURN .F.
   ENDIF

   IF ! s_DbUse( cBaza, cAlias, cTytul )
      RETURN .F.
   ENDIF
   IF ! s_Okay( cAlias, aWzor )
      ( cAlias )->( dbCloseArea() )
      gui_MsgError( "Struktura bazy " + cBaza + " nadal nie zgadza się ze wzorem.", cTytul )
      RETURN .F.
   ENDIF

RETURN .T.

PROCEDURE PackDatabase( cBaza, cAlias )

   IF FileExists( cBaza + ".dbf" )
      dbSelectArea( 0 )
      IF NetUse( cBaza, .T., NIL, cAlias )
         NetPack()
         ( cAlias )->( dbCloseArea() )
      ENDIF
   ENDIF

RETURN

FUNCTION ExclusiveDatabase( aPliki, cTytul )

   LOCAL nObszar := Select()
   LOCAL cPlik

   FOR EACH cPlik IN aPliki
      IF Lower( Right( cPlik, 4 ) ) == ".dbf" .AND. FileExists( cPlik )
         dbSelectArea( 0 )
         IF ! NetUse( Left( cPlik, Len( cPlik ) - 4 ), .T., 0, "WYLACZNIE", .T. )
            dbSelectArea( nObszar )
            gui_MsgError( "Baza " + cPlik + " jest używana na innym stanowisku." + Eol() + ;
                          "Zamknij xFakturę na pozostałych stanowiskach i spróbuj ponownie.", cTytul )
            RETURN .F.
         ENDIF
         WYLACZNIE->( dbCloseArea() )
      ENDIF
   NEXT
   dbSelectArea( nObszar )

RETURN .T.

STATIC FUNCTION s_DbUse( cBaza, cAlias, cTytul )

   dbSelectArea( 0 )
   IF ! NetUse( cBaza, .F., NIL, cAlias )
      RETURN .F.
   ENDIF
   IF !( ( cAlias )->( DbInfo( DBI_DB_VERSION ) ) == "xDev 7" )
      ( cAlias )->( dbCloseArea() )
      gui_MsgError( "Plik " + cBaza + ".dbf nie jest bazą xDev 7 RDD.", cTytul )
      RETURN .F.
   ENDIF

RETURN .T.

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

STATIC FUNCTION s_Rekonstrukcja( cBaza, aWzor, cAlias )

   LOCAL cMemo  := RddInfo( RDDI_MEMOEXT )
   LOCAL cTmp   := cBaza + "_tmp"
   LOCAL lMemo  := FileExists( cBaza + cMemo )
   LOCAL lOkay  := .F.

   FErase( cTmp + ".dbf" )
   FErase( cTmp + cMemo )
   IF FRename( cBaza + ".dbf", cTmp + ".dbf" ) != 0
      RETURN .F.
   ENDIF
   IF lMemo .AND. FRename( cBaza + cMemo, cTmp + cMemo ) != 0
      FRename( cTmp + ".dbf", cBaza + ".dbf" )
      RETURN .F.
   ENDIF

   dbCreate( cBaza, aWzor )
   dbSelectArea( 0 )
   IF FileExists( cBaza + ".dbf" ) .AND. NetUse( cBaza, .T., NIL, cAlias, .T. )
      lOkay := ( cAlias )->( DbAppendFrom( cTmp + ".dbf" ) )
      ( cAlias )->( dbCloseArea() )
   ENDIF

   IF ! lOkay
      FErase( cBaza + ".dbf" )
      FErase( cBaza + cMemo )
      FRename( cTmp + ".dbf", cBaza + ".dbf" )
      IF lMemo
         FRename( cTmp + cMemo, cBaza + cMemo )
      ENDIF
      RETURN .F.
   ENDIF

   FErase( cTmp + ".dbf" )
   FErase( cTmp + cMemo )
   s_UsunIndeksy( cBaza )

RETURN .T.

STATIC PROCEDURE s_UsunIndeksy( cBaza )

   LOCAL cKatalog := ""
   LOCAL aPlik

   FNameSplit( cBaza, @cKatalog )
   FOR EACH aPlik IN Directory( cBaza + "*" + IndexExt() )
      FErase( cKatalog + aPlik[ 1 ] )
   NEXT

RETURN
