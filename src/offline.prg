/*
 * Copyright (c) 2026 xDev-Language
 *
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: offline.prg
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "openssl.ch"
#include "xfaktura.ch"

PROCEDURE p_Offline( oDialog )

   LOCAL cKatalog := p_RokPobierz() + "xml"
   LOCAL hFirma
   LOCAL cNip
   LOCAL hCert
   LOCAL nTryb
   LOCAL dTermin
   LOCAL cXml
   LOCAL nPlik

   IF FKTHEAD->( Eof() )
      RETURN
   ENDIF
   IF FKTHEAD->KSEF_STAT == 2
      gui_MsgInfo( "Faktura jest już w KSeF." + Eol() + "Numer KSeF: " + AllTrim( FKTHEAD->KSEF_NR ), "Offline" )
      RETURN
   ENDIF
   IF FKTHEAD->KSEF_TRYB > 0
      gui_MsgInfo( "Faktura jest już wystawiona w trybie " + p_OfflineTryb( FKTHEAD->KSEF_TRYB ) + "." + Eol() + ;
                   "Wyślij ją do KSeF (F6) do dnia " + DToC( FKTHEAD->KSEF_TERM ) + ".", "Offline" )
      RETURN
   ENDIF
   IF FKTHEAD->KSEF_STAT == 1
      gui_MsgInfo( "KSeF przyjmuje już tę fakturę." + Eol() + "Sprawdź ją klawiszem F7.", "Offline" )
      RETURN
   ENDIF
   hFirma := p_FirmaPobierzDane()
   IF hFirma == NIL
      RETURN
   ENDIF
   cNip := AllTrim( hFirma[ "NIP__FIRMY" ] )
   IF Empty( cNip ) .OR. Empty( hFirma[ "NAZWAFIRMY" ] ) .OR. ;
      Empty( hFirma[ "ULICAFIRMY" ] ) .AND. Empty( hFirma[ "MIASTO" ] )
      gui_MsgInfo( "Uzupełnij NIP, nazwę i adres firmy:" + Eol() + ;
                   "Pliki - Ustawienia - Firma.", "Offline" )
      RETURN
   ENDIF
   IF Empty( FKTHEAD->NAZWA___OD ) .OR. ;
      Empty( FKTHEAD->ULICA___OD ) .AND. Empty( FKTHEAD->MIEJSCE_OD )
      gui_MsgInfo( "Faktura nie ma nazwy albo adresu nabywcy.", "Offline" )
      RETURN
   ENDIF
   hCert := s_Certyfikat( cNip, hFirma[ "KSEF_SROD" ] )
   IF hCert == NIL
      RETURN
   ENDIF

   nTryb := s_WybierzTryb( oDialog )
   IF nTryb == 0
      RETURN
   ENDIF
   dTermin := s_Termin( nTryb, FKTHEAD->D_WYSTAWIE )

   cXml := p_Fa3GenerujXml( hFirma )
   IF ! DirExists( cKatalog )
      DirMake( cKatalog )
   ENDIF
   nPlik := FCreate( s_PlikXml() )
   IF nPlik < 0
      gui_MsgError( "Nie można zapisać pliku " + s_PlikXml() + ".", "Offline" )
      RETURN
   ENDIF
   FWrite( nPlik, cXml )
   FClose( nPlik )

   dbSelectArea( "FKTHEAD" )
   IF ! NetRLock()
      RETURN
   ENDIF
   FKTHEAD->KSEF_TRYB := nTryb
   FKTHEAD->KSEF_TERM := dTermin
   FKTHEAD->KSEF_STAT := 0
   FKTHEAD->KSEF_OPIS := "Wystawiona w trybie " + p_OfflineTryb( nTryb ) + " " + DToC( Date() )
   dbCommit()
   dbUnlock()
   oDialog:BRW:Refresh()

   gui_MsgInfo( "Faktura " + AllTrim( FKTHEAD->NUMER_FKT ) + " wystawiona w trybie " + p_OfflineTryb( nTryb ) + "." + Eol() + Eol() + ;
                "Wydruk (F9) ma kod QR faktury (OFFLINE) i kod QR certyfikatu." + Eol() + ;
                "Wyślij fakturę do KSeF (F6) do dnia " + DToC( dTermin ) + "." + ;
                IIF( nTryb == 1, "", Eol() + "Jeśli awaria lub niedostępność KSeF potrwa dłużej," + Eol() + ;
                                     "termin liczy się od dnia jej zakończenia." ), "Offline" )

RETURN

FUNCTION p_OfflineTryb( nTryb )

   DO CASE
   CASE nTryb == 1
      RETURN "offline24"
   CASE nTryb == 2
      RETURN "offline (niedostępność KSeF)"
   CASE nTryb == 3
      RETURN "awaryjnym (awaria KSeF)"
   ENDCASE

RETURN ""

PROCEDURE p_OfflinePrzypomnij()

   LOCAL nRecNo := FKTHEAD->( RecNo() )
   LOCAL cTekst := ""

   FKTHEAD->( dbGoTop() )
   DO WHILE ! FKTHEAD->( Eof() )
      IF FKTHEAD->KSEF_TRYB > 0 .AND. FKTHEAD->KSEF_STAT != 2
         cTekst += Eol() + IIF( FKTHEAD->RODZAJ == "KOR", "Korekta ", "Faktura " ) + AllTrim( FKTHEAD->NUMER_FKT ) + ;
                   ": do " + DToC( FKTHEAD->KSEF_TERM ) + ;
                   IIF( FKTHEAD->KSEF_TERM < Date(), " - termin minął!", IIF( FKTHEAD->KSEF_TERM == Date(), " - dzisiaj!", "" ) )
      ENDIF
      FKTHEAD->( dbSkip() )
   ENDDO
   FKTHEAD->( dbGoto( nRecNo ) )

   IF ! Empty( cTekst )
      gui_MsgWarning( "Faktury offline do wysłania do KSeF (F6):" + Eol() + cTekst, "Offline" )
   ENDIF

RETURN

FUNCTION p_OfflineKodII( hFirma )

   LOCAL cNip
   LOCAL hCert
   LOCAL cXml
   LOCAL cDoPodpisu
   LOCAL cPodpis

   IF FKTHEAD->KSEF_TRYB == 0
      RETURN ""
   ENDIF
   cNip  := AllTrim( hFirma[ "NIP__FIRMY" ] )
   hCert := s_Certyfikat( cNip, hFirma[ "KSEF_SROD" ] )
   IF hCert == NIL
      RETURN ""
   ENDIF
   cXml := MemoRead( s_PlikXml(), .T. )
   IF Empty( cXml )
      gui_MsgWarning( "Brak pliku XML faktury offline:" + Eol() + s_PlikXml() + Eol() + ;
                      "Wydruk bez kodu QR certyfikatu.", "Offline" )
      RETURN ""
   ENDIF

   cDoPodpisu := IIF( hFirma[ "KSEF_SROD" ] == 3, "qr.ksef.mf.gov.pl", "qr-test.ksef.mf.gov.pl" ) + ;
                 "/certificate/Nip/" + cNip + "/" + cNip + "/" + hCert[ "NUMER" ] + "/" + ;
                 s_Base64Url( HashData( "SHA256", cXml ) )
   IF hCert[ "RSA" ]
      cPodpis := SignData( hCert[ "KLUCZ" ], cDoPodpisu, "SHA256", hCert[ "HASLO" ], RSA_PADDING_PSS )
   ELSE
      cPodpis := SignData( hCert[ "KLUCZ" ], cDoPodpisu, "SHA256", hCert[ "HASLO" ] )
      IF cPodpis != NIL
         cPodpis := s_P1363( cPodpis )
      ENDIF
   ENDIF
   IF Empty( cPodpis )
      gui_MsgWarning( "Nie można podpisać kodu QR certyfikatem KSeF." + Eol() + CryptoError() + Eol() + ;
                      "Wydruk bez kodu QR certyfikatu.", "Offline" )
      RETURN ""
   ENDIF

RETURN "https://" + cDoPodpisu + "/" + s_Base64Url( cPodpis )

STATIC FUNCTION s_Certyfikat( cNip, nSrodowisko )

   LOCAL hCert := p_CertyfikatyPobierz( cNip, nSrodowisko, "Offline" )

   IF hCert == NIL
      gui_MsgInfo( "Brak ważnego certyfikatu KSeF typu Offline dla NIP " + cNip + Eol() + ;
                   "i środowiska z danych firmy." + Eol() + ;
                   "Wczytaj go w Pliki - Tokeny / Certyfikaty - Lista certyfikatów.", "Offline" )
   ENDIF

RETURN hCert

STATIC FUNCTION s_PlikXml()
RETURN p_RokPobierz() + "xml" + DirSepToOS( "\" ) + StrTran( AllTrim( FKTHEAD->NUMER_FKT ), "/", "_" ) + ".xml"

STATIC FUNCTION s_Base64Url( cDane )
RETURN StrTran( StrTran( StrTran( Base64Encode( cDane ), "+", "-" ), "/", "_" ), "=", "" )

STATIC FUNCTION s_P1363( cDer )

   LOCAL nPoz
   LOCAL nDlugosc
   LOCAL cWynik := ""
   LOCAL cLiczba
   LOCAL nLiczba

   nPoz := IIF( Asc( SubStr( cDer, 2, 1 ) ) > 127, 4, 3 )
   FOR nLiczba := 1 TO 2
      IF Asc( SubStr( cDer, nPoz, 1 ) ) != 0x02
         RETURN cDer
      ENDIF
      nDlugosc := Asc( SubStr( cDer, nPoz + 1, 1 ) )
      cLiczba  := SubStr( cDer, nPoz + 2, nDlugosc )
      DO WHILE Len( cLiczba ) > 32 .AND. Left( cLiczba, 1 ) == Chr( 0 )
         cLiczba := SubStr( cLiczba, 2 )
      ENDDO
      cWynik += Replicate( Chr( 0 ), 32 - Len( cLiczba ) ) + cLiczba
      nPoz += 2 + nDlugosc
   NEXT

RETURN cWynik

STATIC FUNCTION s_WybierzTryb( oWindow )

   LOCAL oDialog
   LOCAL aTryb := {}
   LOCAL oOk
   LOCAL oAnuluj
   LOCAL nTryb := 0

   oDialog := gui_Dialog():New( oWindow, "Wystaw w trybie offline", 520, 230 )
   oDialog:Center()

   gui_Say():New( oDialog, 20, 15, 54, 20, "Faktura " + AllTrim( FKTHEAD->NUMER_FKT ) + " - tryb wystawienia:" )
   AAdd( aTryb, gui_RadioButton():New( oDialog, 20,  45, 480, 20, "offline24 - z wyboru, wysyłka do następnego dnia roboczego" ) )
   AAdd( aTryb, gui_RadioButton():New( oDialog, 20,  75, 480, 20, "offline - ogłoszona niedostępność KSeF" ) )
   AAdd( aTryb, gui_RadioButton():New( oDialog, 20, 105, 480, 20, "awaryjny - ogłoszona awaria KSeF (7 dni roboczych)" ) )
   aTryb[ 1 ]:value := .T.

   oOk     := gui_Button():New( oDialog, 310, 160, 90, 28, "OK" )
   oAnuluj := gui_Button():New( oDialog, 410, 160, 90, 28, "Anuluj" )

   oOk:isDefault    := .T.
   oOk:onClick      := {|| nTryb := AScan( aTryb, {| oTryb | oTryb:value } ), oDialog:EndDialog( 1 ) }
   oAnuluj:isCancel := .T.
   oAnuluj:onClick  := {|| oDialog:EndDialog( 0 ) }

   oDialog:ShowModal()

RETURN nTryb

STATIC FUNCTION s_Termin( nTryb, dWystawienia )

   DO CASE
   CASE nTryb == 1
      RETURN s_DodajRobocze( dWystawienia, 1 )
   CASE nTryb == 2
      RETURN s_DodajRobocze( Max( Date(), dWystawienia ), 1 )
   ENDCASE

RETURN s_DodajRobocze( Max( Date(), dWystawienia ), 7 )

STATIC FUNCTION s_DodajRobocze( dData, nDni )

   DO WHILE nDni > 0
      dData := dData + 1
      IF s_Roboczy( dData )
         nDni--
      ENDIF
   ENDDO

RETURN dData

STATIC FUNCTION s_Roboczy( dData )

   LOCAL dWielkanoc

   IF DoW( dData ) == 1 .OR. DoW( dData ) == 7
      RETURN .F.
   ENDIF
   IF StrZero( Month( dData ), 2 ) + StrZero( Day( dData ), 2 ) $ "0101 0106 0501 0503 0815 1101 1111 1224 1225 1226"
      RETURN .F.
   ENDIF
   dWielkanoc := s_Wielkanoc( Year( dData ) )

RETURN dData != dWielkanoc + 1 .AND. dData != dWielkanoc + 60

STATIC FUNCTION s_Wielkanoc( nRok )

   LOCAL a := nRok % 19
   LOCAL b := Int( nRok / 100 )
   LOCAL c := nRok % 100
   LOCAL d := Int( b / 4 )
   LOCAL e := b % 4
   LOCAL f := Int( ( b + 8 ) / 25 )
   LOCAL g := Int( ( b - f + 1 ) / 3 )
   LOCAL h := ( 19 * a + b - d - g + 15 ) % 30
   LOCAL i := Int( c / 4 )
   LOCAL k := c % 4
   LOCAL l := ( 32 + 2 * e + 2 * i - h - k ) % 7
   LOCAL m := Int( ( a + 11 * h + 22 * l ) / 451 )
   LOCAL nMiesiac := Int( ( h + l - 7 * m + 114 ) / 31 )
   LOCAL nDzien   := ( h + l - 7 * m + 114 ) % 31 + 1

RETURN SToD( Str( nRok, 4 ) + StrZero( nMiesiac, 2 ) + StrZero( nDzien, 2 ) )
