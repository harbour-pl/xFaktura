/*
 * Copyright (c) 2026 xDev-Language
 *
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: ksef.prg
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "curl.ch"
#include "openssl.ch"
#include "xfaktura.ch"

#define BILET_SEKUND  600

STATIC s_hKlucze := { => }
STATIC s_hBilety := { => }
STATIC s_cKluczInstalacji

FUNCTION p_KsefZaloguj( cNip, cToken, nSrodowisko, cBlad )

   LOCAL cUrl := s_Adres( nSrodowisko )
   LOCAL hOdp
   LOCAL hWyzwanie
   LOCAL cKlucz
   LOCAL cSzyfr
   LOCAL nStatus

   cBlad := ""

   hWyzwanie := s_Zapytanie( "POST", cUrl + "/auth/challenge", "{}", NIL, @nStatus, @cBlad )
   IF hWyzwanie == NIL
      RETURN NIL
   ENDIF
   IF ValType( p_KsefPole( hWyzwanie, "challenge" ) ) != "C" .OR. ValType( p_KsefPole( hWyzwanie, "timestampMs" ) ) != "N"
      cBlad := s_Nieoczekiwana()
      RETURN NIL
   ENDIF

   cKlucz := s_Klucz( cUrl, "KsefTokenEncryption", @cBlad )
   IF cKlucz == NIL
      RETURN NIL
   ENDIF
   cSzyfr := s_Rsa( cKlucz, AllTrim( cToken ) + "|" + LTrim( Str( hWyzwanie[ "timestampMs" ], 20 ) ), @cBlad )
   IF cSzyfr == NIL
      RETURN NIL
   ENDIF

   hOdp := s_Zapytanie( "POST", cUrl + "/auth/ksef-token", ;
      json_Encode( { "challenge" => hWyzwanie[ "challenge" ], ;
                     "contextIdentifier" => { "type" => "Nip", "value" => AllTrim( cNip ) }, ;
                     "encryptedToken" => cSzyfr } ), ;
      NIL, @nStatus, @cBlad )
   IF hOdp == NIL
      RETURN NIL
   ENDIF

RETURN s_Bilet( cUrl, hOdp, @cBlad )

FUNCTION p_KsefZalogujXades( cNip, cKlucz, cCert, cHaslo, nSrodowisko, cBlad )

   LOCAL cUrl := s_Adres( nSrodowisko )
   LOCAL hWyzwanie
   LOCAL cPodpisany
   LOCAL hOdp
   LOCAL nStatus

   cBlad := ""

   hWyzwanie := s_Zapytanie( "POST", cUrl + "/auth/challenge", "{}", NIL, @nStatus, @cBlad )
   IF hWyzwanie == NIL
      RETURN NIL
   ENDIF
   IF ValType( p_KsefPole( hWyzwanie, "challenge" ) ) != "C"
      cBlad := s_Nieoczekiwana()
      RETURN NIL
   ENDIF

   cPodpisany := XadesSign( '<?xml version="1.0" encoding="utf-8"?>' + ;
                            '<AuthTokenRequest xmlns="http://ksef.mf.gov.pl/auth/token/2.0">' + ;
                            '<Challenge>' + hWyzwanie[ "challenge" ] + '</Challenge>' + ;
                            '<ContextIdentifier><Nip>' + AllTrim( cNip ) + '</Nip></ContextIdentifier>' + ;
                            '<SubjectIdentifierType>certificateSubject</SubjectIdentifierType>' + ;
                            '</AuthTokenRequest>', cKlucz, cCert, cHaslo )
   IF cPodpisany == NIL
      cBlad := "Nie można podpisać żądania certyfikatem:" + Eol() + XadesError()
      RETURN NIL
   ENDIF

   hOdp := s_Zapytanie( "POST", cUrl + "/auth/xades-signature", cPodpisany, NIL, @nStatus, @cBlad, NIL, "application/xml" )
   IF hOdp == NIL
      RETURN NIL
   ENDIF

RETURN s_Bilet( cUrl, hOdp, @cBlad )

PROCEDURE p_KsefWyloguj( nSrodowisko, hBilety )

   LOCAL cBilet := p_KsefPole( hBilety, "accessToken", "token" )

   IF ValType( cBilet ) == "C"
      s_Zapytanie( "DELETE", s_Adres( nSrodowisko ) + "/auth/sessions/current", NIL, cBilet, NIL, NIL )
   ENDIF

RETURN

STATIC FUNCTION s_Bilet( cUrl, hOdp, cBlad )

   LOCAL cNumer
   LOCAL cAuth
   LOCAL nStatus
   LOCAL nProba
   LOCAL nKod := -1

   cNumer := p_KsefPole( hOdp, "referenceNumber" )
   cAuth  := p_KsefPole( hOdp, "authenticationToken", "token" )
   IF ValType( cNumer ) != "C" .OR. ValType( cAuth ) != "C"
      cBlad := s_Nieoczekiwana()
      RETURN NIL
   ENDIF

   FOR nProba := 1 TO 20
      hOdp := s_Zapytanie( "GET", cUrl + "/auth/" + cNumer, NIL, cAuth, @nStatus, @cBlad )
      IF hOdp == NIL
         RETURN NIL
      ENDIF
      nKod := p_KsefKod( hOdp )
      IF nKod == 200
         EXIT
      ENDIF
      IF nKod != 100
         cBlad := s_OpisStatusu( hOdp )
         RETURN NIL
      ENDIF
      IdleSleep( 0.5 )
   NEXT
   IF nKod != 200
      cBlad := "KSeF nie odpowiedział w czasie, spróbuj ponownie."
      RETURN NIL
   ENDIF

   hOdp := s_Zapytanie( "POST", cUrl + "/auth/token/redeem", "", cAuth, @nStatus, @cBlad )
   IF hOdp == NIL
      RETURN NIL
   ENDIF
   IF ValType( p_KsefPole( hOdp, "accessToken", "token" ) ) != "C"
      cBlad := s_Nieoczekiwana()
      RETURN NIL
   ENDIF

RETURN hOdp

FUNCTION p_KsefWyslij( cNip, cToken, nSrodowisko, cXml, cBlad, lOffline, bPrzyjeta )

   LOCAL cUrl := s_Adres( nSrodowisko )
   LOCAL hDostep
   LOCAL cCert
   LOCAL cKlucz
   LOCAL cSzyfrKlucza
   LOCAL cIv
   LOCAL cZaszyfrowana
   LOCAL cTresc
   LOCAL hOdp
   LOCAL cSesja
   LOCAL cFaktura

   hDostep := s_Dostep( cNip, cToken, nSrodowisko, @cBlad )
   IF hDostep == NIL
      RETURN NIL
   ENDIF

   cCert := s_Klucz( cUrl, "SymmetricKeyEncryption", @cBlad )
   IF cCert == NIL
      RETURN NIL
   ENDIF
   cKlucz := RandomBytes( 32 )
   cIv    := RandomBytes( 16 )
   cSzyfrKlucza := s_Rsa( cCert, cKlucz, @cBlad )
   IF cSzyfrKlucza == NIL
      RETURN NIL
   ENDIF

   cTresc := json_Encode( { "formCode" => { "systemCode" => "FA (3)", "schemaVersion" => "1-0E", "value" => "FA" }, ;
                            "encryption" => { "encryptedSymmetricKey" => cSzyfrKlucza, ;
                                              "initializationVector" => Base64Encode( cIv ) } } )
   hOdp := s_ZapytanieDostep( "POST", cUrl + "/sessions/online", cTresc, hDostep, @cBlad )
   IF hOdp == NIL
      RETURN NIL
   ENDIF
   cSesja := p_KsefPole( hOdp, "referenceNumber" )
   IF ValType( cSesja ) != "C"
      cBlad := s_Nieoczekiwana()
      RETURN NIL
   ENDIF

   cZaszyfrowana := AesEncrypt( cKlucz, cIv, cXml )
   IF cZaszyfrowana == NIL
      cBlad := "Nie można zaszyfrować faktury:" + Eol() + CryptoError()
      s_ZapytanieDostep( "POST", cUrl + "/sessions/online/" + cSesja + "/close", "", hDostep )
      RETURN NIL
   ENDIF
   hOdp := s_ZapytanieDostep( "POST", cUrl + "/sessions/online/" + cSesja + "/invoices", ;
      json_Encode( { "invoiceHash" => Base64Encode( HashData( "SHA256", cXml ) ), ;
                     "invoiceSize" => Len( cXml ), ;
                     "encryptedInvoiceHash" => Base64Encode( HashData( "SHA256", cZaszyfrowana ) ), ;
                     "encryptedInvoiceSize" => Len( cZaszyfrowana ), ;
                     "encryptedInvoiceContent" => Base64Encode( cZaszyfrowana ), ;
                     "offlineMode" => ( lOffline == .T. ) } ), ;
      hDostep, @cBlad )
   cFaktura := p_KsefPole( hOdp, "referenceNumber" )
   IF ValType( cFaktura ) != "C"
      IF hOdp != NIL
         cBlad := s_Nieoczekiwana()
      ENDIF
      s_ZapytanieDostep( "POST", cUrl + "/sessions/online/" + cSesja + "/close", "", hDostep )
      RETURN NIL
   ENDIF
   IF bPrzyjeta != NIL
      Eval( bPrzyjeta, cSesja, cFaktura )
   ENDIF

   s_ZapytanieDostep( "POST", cUrl + "/sessions/online/" + cSesja + "/close", "", hDostep )

RETURN s_Status( cUrl, hDostep, cSesja, cFaktura, 40, @cBlad )

FUNCTION p_KsefSprawdz( cNip, cToken, nSrodowisko, cSesja, cFaktura, cBlad )

   LOCAL hDostep := s_Dostep( cNip, cToken, nSrodowisko, @cBlad )

   IF hDostep == NIL
      RETURN NIL
   ENDIF

RETURN s_Status( s_Adres( nSrodowisko ), hDostep, cSesja, cFaktura, 5, @cBlad )

FUNCTION p_KsefKod( hOdp )

   LOCAL nKod := p_KsefPole( hOdp, "status", "code" )

RETURN IIF( ValType( nKod ) == "N", nKod, -1 )

FUNCTION p_KsefPole( hOdp, cKlucz, cPodklucz )

   IF ValType( hOdp ) != "H" .OR. ! HHasKey( hOdp, cKlucz )
      RETURN NIL
   ENDIF
   IF cPodklucz == NIL
      RETURN hOdp[ cKlucz ]
   ENDIF
   IF ValType( hOdp[ cKlucz ] ) != "H" .OR. ! HHasKey( hOdp[ cKlucz ], cPodklucz )
      RETURN NIL
   ENDIF

RETURN hOdp[ cKlucz ][ cPodklucz ]

FUNCTION p_KsefOpisStatusu( hOdp )
RETURN s_OpisStatusu( hOdp )

FUNCTION p_KsefSrodowisko( nSrodowisko, lPelna )

   IF nSrodowisko == SROD_PRODUKCYJNE
      RETURN IIF( lPelna == .T., "Produkcyjne (prawdziwe faktury)", "Produkcyjne" )
   ENDIF

RETURN IIF( lPelna == .T., "Testowe (próbny, do testów)", "Testowe" )

PROCEDURE p_KsefAplikacja( cTytul )

   LOCAL cNip        := ""
   LOCAL nSrodowisko := SROD_TESTOWE
   LOCAL cAdres

   p_FirmaPobierzKsef( @cNip, @nSrodowisko )
   cAdres := IIF( nSrodowisko == SROD_PRODUKCYJNE, "https://ap.ksef.mf.gov.pl", "https://ap-test.ksef.mf.gov.pl" )
   IF ! gui_OpenFile( cAdres )
      gui_MsgInfo( "Otwórz w przeglądarce:" + Eol() + cAdres, cTytul )
   ENDIF

RETURN

FUNCTION p_KsefZaszyfruj( cDane )

   LOCAL cKlucz := s_KluczInstalacji()
   LOCAL cIv

   IF cKlucz == NIL
      RETURN NIL
   ENDIF
   cIv := RandomBytes( 12 )

RETURN Base64Encode( cIv + AesEncrypt( cKlucz, cIv, cDane, AES_MODE_GCM ) )

FUNCTION p_KsefOdszyfruj( cZapis )

   LOCAL cDane := Base64Decode( AllTrim( cZapis ) )
   LOCAL cWynik

   IF Len( cDane ) <= 12 + 16 .OR. s_KluczInstalacji() == NIL
      RETURN ""
   ENDIF
   cWynik := AesDecrypt( s_KluczInstalacji(), Left( cDane, 12 ), SubStr( cDane, 13 ), AES_MODE_GCM )

RETURN IIF( cWynik == NIL, "", cWynik )

STATIC FUNCTION s_KluczInstalacji()

   LOCAL cKatalog
   LOCAL cPlik
   LOCAL cKlucz
   LOCAL nPlik

   IF s_cKluczInstalacji != NIL
      RETURN s_cKluczInstalacji
   ENDIF
   IF Empty( GetEnv( "APPDATA" ) )
      RETURN NIL
   ENDIF
   cKatalog := GetEnv( "APPDATA" ) + DirSepToOS( "\" ) + "xFaktura"
   cPlik    := cKatalog + DirSepToOS( "\" ) + "klucz.bin"

   cKlucz := IIF( FileExists( cPlik ), MemoRead( cPlik, .T. ), "" )
   IF Len( cKlucz ) != 32
      IF FileExists( cPlik )
         RETURN NIL
      ENDIF
      cKlucz := RandomBytes( 32 )
      IF ! DirExists( cKatalog )
         DirMake( cKatalog )
      ENDIF
      nPlik := FCreate( cPlik )
      IF nPlik < 0
         RETURN NIL
      ENDIF
      IF FWrite( nPlik, cKlucz ) != 32
         FClose( nPlik )
         FErase( cPlik )
         RETURN NIL
      ENDIF
      FClose( nPlik )
   ENDIF
   s_cKluczInstalacji := cKlucz

RETURN s_cKluczInstalacji

STATIC FUNCTION s_BiletDostepu( cNip, cToken, nSrodowisko, cBlad )

   LOCAL cKlucz := s_KluczBiletu( cNip, cToken, nSrodowisko )
   LOCAL hBilety

   IF HHasKey( s_hBilety, cKlucz ) .AND. s_hBilety[ cKlucz ][ 2 ] > s_Teraz()
      RETURN s_hBilety[ cKlucz ][ 1 ]
   ENDIF

   hBilety := p_KsefZaloguj( cNip, cToken, nSrodowisko, @cBlad )
   IF hBilety == NIL
      RETURN NIL
   ENDIF
   s_hBilety[ cKlucz ] := { hBilety[ "accessToken" ][ "token" ], s_Teraz() + BILET_SEKUND }

RETURN s_hBilety[ cKlucz ][ 1 ]

STATIC PROCEDURE s_ZapomnijBilet( cNip, cToken, nSrodowisko )

   LOCAL cKlucz := s_KluczBiletu( cNip, cToken, nSrodowisko )

   IF HHasKey( s_hBilety, cKlucz )
      HDel( s_hBilety, cKlucz )
   ENDIF

RETURN

STATIC FUNCTION s_KluczBiletu( cNip, cToken, nSrodowisko )
RETURN AllTrim( cNip ) + "|" + LTrim( Str( nSrodowisko ) ) + "|" + Base64Encode( HashData( "SHA256", AllTrim( cToken ) ) )

STATIC FUNCTION s_Teraz()
RETURN ( Date() - SToD( "20000101" ) ) * 86400 + Seconds()

STATIC FUNCTION s_Dostep( cNip, cToken, nSrodowisko, cBlad )

   LOCAL cBilet := s_BiletDostepu( cNip, cToken, nSrodowisko, @cBlad )

   IF cBilet == NIL
      RETURN NIL
   ENDIF

RETURN { "NIP" => cNip, "TOKEN" => cToken, "SROD" => nSrodowisko, "BILET" => cBilet }

STATIC FUNCTION s_ZapytanieDostep( cMetoda, cUrl, cTresc, hDostep, cBlad, lXml )

   LOCAL nStatus := 0
   LOCAL xOdp    := s_Zapytanie( cMetoda, cUrl, cTresc, hDostep[ "BILET" ], @nStatus, @cBlad, lXml )
   LOCAL cBilet

   IF xOdp == NIL .AND. nStatus == 401
      s_ZapomnijBilet( hDostep[ "NIP" ], hDostep[ "TOKEN" ], hDostep[ "SROD" ] )
      cBilet := s_BiletDostepu( hDostep[ "NIP" ], hDostep[ "TOKEN" ], hDostep[ "SROD" ], @cBlad )
      IF cBilet == NIL
         RETURN NIL
      ENDIF
      hDostep[ "BILET" ] := cBilet
      xOdp := s_Zapytanie( cMetoda, cUrl, cTresc, cBilet, @nStatus, @cBlad, lXml )
   ENDIF

RETURN xOdp

STATIC FUNCTION s_Status( cUrl, hDostep, cSesja, cFaktura, nProb, cBlad )

   LOCAL hOdp
   LOCAL nProba
   LOCAL cUpo

   FOR nProba := 1 TO nProb
      hOdp := s_ZapytanieDostep( "GET", cUrl + "/sessions/" + cSesja + "/invoices/" + cFaktura, NIL, hDostep, @cBlad )
      IF hOdp == NIL
         RETURN NIL
      ENDIF
      IF p_KsefKod( hOdp ) == -1
         cBlad := s_Nieoczekiwana()
         RETURN NIL
      ENDIF
      IF p_KsefKod( hOdp ) != 100 .AND. p_KsefKod( hOdp ) != 150
         EXIT
      ENDIF
      IdleSleep( 1 )
   NEXT
   hOdp[ "sesja" ]   := cSesja
   hOdp[ "faktura" ] := cFaktura

   IF p_KsefKod( hOdp ) == 200
      IF ValType( p_KsefPole( hOdp, "ksefNumber" ) ) != "C"
         cBlad := s_Nieoczekiwana()
         RETURN NIL
      ENDIF
      FOR nProba := 1 TO 10
         cUpo := s_ZapytanieDostep( "GET", cUrl + "/sessions/" + cSesja + "/invoices/" + cFaktura + "/upo", NIL, hDostep, NIL, .T. )
         IF cUpo != NIL
            hOdp[ "upo" ] := cUpo
            EXIT
         ENDIF
         IdleSleep( 1 )
      NEXT
   ENDIF

RETURN hOdp

STATIC FUNCTION s_OpisStatusu( hOdp )

   LOCAL cOpis   := LTrim( Str( p_KsefKod( hOdp ) ) )
   LOCAL xOpis   := p_KsefPole( hOdp, "status", "description" )
   LOCAL aDetale := p_KsefPole( hOdp, "status", "details" )

   IF ValType( xOpis ) == "C"
      cOpis += " " + xOpis
   ENDIF
   IF ValType( aDetale ) == "A"
      AEval( aDetale, {| cSzczegol | IIF( ValType( cSzczegol ) == "C", cOpis += Eol() + cSzczegol, NIL ) } )
   ENDIF

RETURN cOpis

STATIC FUNCTION s_Nieoczekiwana()
RETURN "Nieoczekiwana odpowiedź KSeF, spróbuj ponownie później."

STATIC FUNCTION s_Adres( nSrodowisko )

   IF nSrodowisko == SROD_PRODUKCYJNE
      RETURN "https://api.ksef.mf.gov.pl/v2"
   ENDIF

RETURN "https://api-test.ksef.mf.gov.pl/v2"

STATIC FUNCTION s_Klucz( cUrl, cUzycie, cBlad )

   LOCAL cKlucz := cUrl + "|" + cUzycie
   LOCAL aCert
   LOCAL hCert

   IF HHasKey( s_hKlucze, cKlucz )
      RETURN s_hKlucze[ cKlucz ]
   ENDIF

   aCert := s_Zapytanie( "GET", cUrl + "/security/public-key-certificates", NIL, NIL, NIL, @cBlad )
   IF aCert == NIL
      RETURN NIL
   ENDIF
   IF ValType( aCert ) != "A"
      cBlad := s_Nieoczekiwana()
      RETURN NIL
   ENDIF
   FOR EACH hCert IN aCert
      IF ValType( p_KsefPole( hCert, "usage" ) ) == "A" .AND. AScan( hCert[ "usage" ], cUzycie ) > 0 .AND. ;
         ValType( p_KsefPole( hCert, "certificate" ) ) == "C"
         s_hKlucze[ cKlucz ] := Base64Decode( hCert[ "certificate" ] )
         RETURN s_hKlucze[ cKlucz ]
      ENDIF
   NEXT
   cBlad := "Brak certyfikatu KSeF: " + cUzycie

RETURN NIL

STATIC FUNCTION s_Rsa( cCert, cDane, cBlad )

   LOCAL cSzyfr := RsaEncrypt( cCert, cDane )

   IF cSzyfr == NIL
      cBlad := "Nie można zaszyfrować danych certyfikatem KSeF:" + Eol() + CryptoError()
      RETURN NIL
   ENDIF

RETURN Base64Encode( cSzyfr )

STATIC FUNCTION s_Zapytanie( cMetoda, cUrl, cTresc, cBilet, nStatus, cBlad, lXml, cTypTresci )

   LOCAL pCurl     := curl_easy_init()
   LOCAL aNaglowki := { IIF( lXml == .T., "Accept: application/xml", "Accept: application/json" ) }
   LOCAL nKod
   LOCAL cOdp
   LOCAL xOdp

   IF pCurl == NIL
      cBlad := "Nie można uruchomić połączenia sieciowego."
      RETURN NIL
   ENDIF
   IF cTresc != NIL
      AAdd( aNaglowki, "Content-Type: " + IIF( cTypTresci == NIL, "application/json", cTypTresci ) )
   ENDIF
   IF cBilet != NIL
      AAdd( aNaglowki, "Authorization: Bearer " + cBilet )
   ENDIF
   curl_easy_setopt( pCurl, CURLOPT_URL, cUrl )
   curl_easy_setopt( pCurl, CURLOPT_HTTPHEADER, aNaglowki )
   curl_easy_setopt( pCurl, CURLOPT_TIMEOUT, 30 )
   DO CASE
   CASE cMetoda == "POST"
      curl_easy_setopt( pCurl, CURLOPT_POSTFIELDS, IIF( cTresc == NIL, "", cTresc ) )
   CASE cMetoda == "DELETE"
      curl_easy_setopt( pCurl, CURLOPT_CUSTOMREQUEST, "DELETE" )
   ENDCASE

   nKod := curl_easy_perform( pCurl )
   IF nKod != 0
      cBlad := "Brak połączenia z KSeF: " + curl_easy_strerror( nKod )
      curl_easy_cleanup( pCurl )
      RETURN NIL
   ENDIF
   nStatus := curl_easy_getinfo( pCurl, CURLINFO_RESPONSE_CODE )
   cOdp    := curl_easy_buffer( pCurl )
   curl_easy_cleanup( pCurl )

   IF lXml == .T.
      RETURN IIF( nStatus == 200 .AND. ! Empty( cOdp ), cOdp, NIL )
   ENDIF
   IF cMetoda == "DELETE"
      RETURN IIF( nStatus < 400, { => }, NIL )
   ENDIF

   xOdp := json_Decode( cOdp )
   IF nStatus >= 400 .OR. xOdp == NIL
      cBlad := "KSeF " + LTrim( Str( nStatus ) ) + ": " + s_OpisBledu( xOdp, cOdp )
      RETURN NIL
   ENDIF

RETURN xOdp

STATIC FUNCTION s_OpisBledu( xOdp, cOdp )

   LOCAL cOpis := ""
   LOCAL aLista := p_KsefPole( xOdp, "exception", "exceptionDetailList" )

   IF ValType( aLista ) == "A"
      AEval( aLista, {| hSzczegol | cOpis += IIF( Empty( cOpis ), "", Eol() ) + ;
                                     IIF( ValType( p_KsefPole( hSzczegol, "exceptionCode" ) ) == "N", LTrim( Str( hSzczegol[ "exceptionCode" ] ) ) + " ", "" ) + ;
                                     IIF( ValType( p_KsefPole( hSzczegol, "exceptionDescription" ) ) == "C", hSzczegol[ "exceptionDescription" ], "" ) } )
      RETURN cOpis
   ENDIF
   IF ValType( p_KsefPole( xOdp, "title" ) ) == "C"
      RETURN xOdp[ "title" ]
   ENDIF

RETURN Left( cOdp, 300 )
