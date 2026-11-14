/*
 * Copyright (c) 2026 xDev-Language
 *
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: netuse.prg
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "dbinfo.ch"

#define NET_WAIT  1

FUNCTION NetUse( cDatabase, lExclusive, nSeconds, cAlias, lNoAlert )
   LOCAL cErrMsg
   LOCAL nDelay

   lExclusive := DefaultValue( lExclusive, .F. )
   nSeconds   := DefaultValue( nSeconds, NET_WAIT )
   lNoAlert   := DefaultValue( lNoAlert, .F. )
   cErrMsg    := "Nie można otworzyć pliku " + cDatabase + " w trybie " + IIF( lExclusive, "wyłącznym", "współdzielonym" ) + "."

   DO WHILE .T.
      NetErr( .F. )
      DBUseArea( .F., NIL, cDatabase, cAlias, ! lExclusive, .F. )
      IF ! NetErr() .AND. Used()
         RETURN .T.
      ENDIF

      IF nSeconds <= 0
         IF lNoAlert .OR. ! s_Ponow( cErrMsg )
            EXIT
         ENDIF
         nSeconds := NET_WAIT
      ELSE
         nDelay := Min( 1, nSeconds )
         IdleSleep( nDelay )
         nSeconds -= nDelay
      ENDIF
   ENDDO
RETURN .F.

FUNCTION NetPack()
   LOCAL lRet

   IF ! Used()
      s_Blad( "PACK nieudany", "Żadna baza nie jest otwarta" )
      RETURN .F.
   ENDIF
   IF DBInfo( DBI_SHARED )
      s_Blad( "PACK nieudany", "Baza musi być otwarta w trybie wyłącznym" )
      RETURN .F.
   ENDIF

   NetErr( .F. )
   DbPack()
   lRet := ! NetErr()
   IF ! lRet
      s_Blad( "PACK nieudany", "Baza musi być otwarta w trybie wyłącznym" )
   ENDIF
RETURN lRet

FUNCTION NetZap()
   LOCAL lRet

   IF ! Used()
      s_Blad( "ZAP nieudany", "Żadna baza nie jest otwarta" )
      RETURN .F.
   ENDIF
   IF DBInfo( DBI_SHARED )
      s_Blad( "ZAP nieudany", "Baza musi być otwarta w trybie wyłącznym" )
      RETURN .F.
   ENDIF

   NetErr( .F. )
   DbZap()
   lRet := ! NetErr()
   IF ! lRet
      s_Blad( "ZAP nieudany", "Baza musi być otwarta w trybie wyłącznym" )
   ENDIF
RETURN lRet

FUNCTION NetAppBlank( nWaitSeconds )
   LOCAL nDelay

   IF ! Used()
      s_Blad( "Nie można dopisać rekordu", "Żadna baza nie jest otwarta" )
      RETURN .F.
   ENDIF

   nWaitSeconds := DefaultValue( nWaitSeconds, NET_WAIT )

   DO WHILE .T.
      NetErr( .F. )
      DBAppend()
      IF ! NetErr()
         RETURN .T.
      ENDIF

      IF nWaitSeconds <= 0
         IF ! s_Ponow( "Nie można dopisać rekordu." )
            EXIT
         ENDIF
         nWaitSeconds := NET_WAIT
      ELSE
         nDelay := Min( 0.5, nWaitSeconds )
         IdleSleep( nDelay )
         nWaitSeconds -= nDelay
      ENDIF
   ENDDO
RETURN .F.

FUNCTION NetRLock( nWait )
   LOCAL nDelay

   IF ! Used()
      s_Blad( "Nie można zablokować rekordu", "Żadna baza nie jest otwarta" )
      RETURN .F.
   ENDIF
   IF ! DBInfo( DBI_SHARED )
      RETURN .T.
   ENDIF

   nWait := DefaultValue( nWait, NET_WAIT )

   DO WHILE .T.
      IF RLock()
         RETURN .T.
      ENDIF

      IF nWait <= 0
         IF ! s_Ponow( "Nie można zablokować rekordu." )
            EXIT
         ENDIF
         nWait := NET_WAIT
      ELSE
         nDelay := Min( 0.5, nWait )
         IdleSleep( nDelay )
         nWait -= nDelay
      ENDIF
   ENDDO
RETURN .F.

STATIC FUNCTION s_Ponow( cTekst )

RETURN gui_MsgYesNo( cTekst + Chr( 10 ) + "Spróbować ponownie?", "Baza danych" )

STATIC PROCEDURE s_Blad( cTekst, cPowod )

   gui_MsgError( cTekst + "." + Chr( 10 ) + cPowod + ".", "Baza danych" )

RETURN
