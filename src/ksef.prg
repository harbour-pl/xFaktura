/*
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: ksef.prg
 *
 * Copyright (c) 2026 xDev-Language
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "curl.ch"

FUNCTION p_KsefZaloguj( cNip, cToken, nSrodowisko, cBlad )

   LOCAL cUrl := s_Adres( nSrodowisko )
   LOCAL hOdp
   LOCAL hWyzwanie
   LOCAL cKlucz
   LOCAL cAuth
   LOCAL cNumer
   LOCAL nStatus
   LOCAL nProba

   cBlad := ""

   hWyzwanie := s_Zapytanie( "POST", cUrl + "/auth/challenge", "{}", NIL, @nStatus, @cBlad )
   IF hWyzwanie == NIL
      RETURN NIL
   ENDIF

   cKlucz := s_Klucz( cUrl, "KsefTokenEncryption", @cBlad )
   IF cKlucz == NIL
      RETURN NIL
   ENDIF

   hOdp := s_Zapytanie( "POST", cUrl + "/auth/ksef-token", ;
      json_Encode( { "challenge" => hWyzwanie[ "challenge" ], ;
                     "contextIdentifier" => { "type" => "Nip", "value" => AllTrim( cNip ) }, ;
                     "encryptedToken" => Base64Encode( RsaEncrypt( cKlucz, AllTrim( cToken ) + "|" + LTrim( Str( hWyzwanie[ "timestampMs" ], 20 ) ) ) ) } ), ;
      NIL, @nStatus, @cBlad )
   IF hOdp == NIL
      RETURN NIL
   ENDIF
   cNumer := hOdp[ "referenceNumber" ]
   cAuth  := hOdp[ "authenticationToken" ][ "token" ]

   FOR nProba := 1 TO 20
      hOdp := s_Zapytanie( "GET", cUrl + "/auth/" + cNumer, NIL, cAuth, @nStatus, @cBlad )
      IF hOdp == NIL
         RETURN NIL
      ENDIF
      IF hOdp[ "status" ][ "code" ] == 200
         EXIT
      ENDIF
      IF hOdp[ "status" ][ "code" ] != 100
         cBlad := LTrim( Str( hOdp[ "status" ][ "code" ] ) ) + " " + hOdp[ "status" ][ "description" ]
         IF HHasKey( hOdp[ "status" ], "details" ) .AND. ValType( hOdp[ "status" ][ "details" ] ) == "A"
            AEval( hOdp[ "status" ][ "details" ], {| cOpis | cBlad += Eol() + cOpis } )
         ENDIF
         RETURN NIL
      ENDIF
      IdleSleep( 0.5 )
   NEXT
   IF hOdp[ "status" ][ "code" ] != 200
      cBlad := "KSeF nie odpowiedział w czasie, spróbuj ponownie."
      RETURN NIL
   ENDIF

   hOdp := s_Zapytanie( "POST", cUrl + "/auth/token/redeem", "", cAuth, @nStatus, @cBlad )
   IF hOdp == NIL
      RETURN NIL
   ENDIF

RETURN hOdp

FUNCTION p_KsefWyslij( cNip, cToken, nSrodowisko, cXml, cBlad )

   LOCAL cUrl := s_Adres( nSrodowisko )
   LOCAL hBilety
   LOCAL cBilet
   LOCAL cCert
   LOCAL cKlucz
   LOCAL cIv
   LOCAL cZaszyfrowana
   LOCAL hOdp
   LOCAL cSesja
   LOCAL cFaktura
   LOCAL nStatus
   LOCAL nProba

   hBilety := p_KsefZaloguj( cNip, cToken, nSrodowisko, @cBlad )
   IF hBilety == NIL
      RETURN NIL
   ENDIF
   cBilet := hBilety[ "accessToken" ][ "token" ]

   cCert := s_Klucz( cUrl, "SymmetricKeyEncryption", @cBlad )
   IF cCert == NIL
      RETURN NIL
   ENDIF
   cKlucz := RandomBytes( 32 )
   cIv    := RandomBytes( 16 )

   hOdp := s_Zapytanie( "POST", cUrl + "/sessions/online", ;
      json_Encode( { "formCode" => { "systemCode" => "FA (3)", "schemaVersion" => "1-0E", "value" => "FA" }, ;
                     "encryption" => { "encryptedSymmetricKey" => Base64Encode( RsaEncrypt( cCert, cKlucz ) ), ;
                                       "initializationVector" => Base64Encode( cIv ) } } ), ;
      cBilet, @nStatus, @cBlad )
   IF hOdp == NIL
      RETURN NIL
   ENDIF
   cSesja := hOdp[ "referenceNumber" ]

   cZaszyfrowana := AesEncrypt( cKlucz, cIv, cXml )
   hOdp := s_Zapytanie( "POST", cUrl + "/sessions/online/" + cSesja + "/invoices", ;
      json_Encode( { "invoiceHash" => Base64Encode( HashData( "SHA256", cXml ) ), ;
                     "invoiceSize" => Len( cXml ), ;
                     "encryptedInvoiceHash" => Base64Encode( HashData( "SHA256", cZaszyfrowana ) ), ;
                     "encryptedInvoiceSize" => Len( cZaszyfrowana ), ;
                     "encryptedInvoiceContent" => Base64Encode( cZaszyfrowana ) } ), ;
      cBilet, @nStatus, @cBlad )
   IF hOdp == NIL
      s_Zapytanie( "POST", cUrl + "/sessions/online/" + cSesja + "/close", "", cBilet, NIL, NIL )
      RETURN NIL
   ENDIF
   cFaktura := hOdp[ "referenceNumber" ]

   s_Zapytanie( "POST", cUrl + "/sessions/online/" + cSesja + "/close", "", cBilet, NIL, NIL )

   FOR nProba := 1 TO 40
      hOdp := s_Zapytanie( "GET", cUrl + "/sessions/" + cSesja + "/invoices/" + cFaktura, NIL, cBilet, @nStatus, @cBlad )
      IF hOdp == NIL
         RETURN NIL
      ENDIF
      IF hOdp[ "status" ][ "code" ] != 100 .AND. hOdp[ "status" ][ "code" ] != 150
         EXIT
      ENDIF
      IdleSleep( 1 )
   NEXT

RETURN hOdp

STATIC FUNCTION s_Adres( nSrodowisko )

   DO CASE
   CASE nSrodowisko == 2
      RETURN "https://api-demo.ksef.mf.gov.pl/v2"
   CASE nSrodowisko == 3
      RETURN "https://api.ksef.mf.gov.pl/v2"
   ENDCASE

RETURN "https://api-test.ksef.mf.gov.pl/v2"

STATIC FUNCTION s_Klucz( cUrl, cUzycie, cBlad )

   LOCAL aCert := s_Zapytanie( "GET", cUrl + "/security/public-key-certificates", NIL, NIL, NIL, @cBlad )
   LOCAL hCert

   IF aCert == NIL
      RETURN NIL
   ENDIF
   FOR EACH hCert IN aCert
      IF AScan( hCert[ "usage" ], cUzycie ) > 0
         RETURN Base64Decode( hCert[ "certificate" ] )
      ENDIF
   NEXT
   cBlad := "Brak certyfikatu KSeF: " + cUzycie

RETURN NIL

STATIC FUNCTION s_Zapytanie( cMetoda, cUrl, cTresc, cBilet, nStatus, cBlad )

   LOCAL pCurl     := curl_easy_init()
   LOCAL aNaglowki := { "Accept: application/json" }
   LOCAL nKod
   LOCAL cOdp
   LOCAL xOdp

   IF cTresc != NIL
      AAdd( aNaglowki, "Content-Type: application/json" )
   ENDIF
   IF cBilet != NIL
      AAdd( aNaglowki, "Authorization: Bearer " + cBilet )
   ENDIF
   curl_easy_setopt( pCurl, CURLOPT_URL, cUrl )
   curl_easy_setopt( pCurl, CURLOPT_HTTPHEADER, aNaglowki )
   curl_easy_setopt( pCurl, CURLOPT_TIMEOUT, 30 )
   IF cMetoda == "POST"
      curl_easy_setopt( pCurl, CURLOPT_POSTFIELDS, IIF( cTresc == NIL, "", cTresc ) )
   ENDIF

   nKod := curl_easy_perform( pCurl )
   IF nKod != 0
      cBlad := "Brak połączenia z KSeF: " + curl_easy_strerror( nKod )
      curl_easy_cleanup( pCurl )
      RETURN NIL
   ENDIF
   nStatus := curl_easy_getinfo( pCurl, CURLINFO_RESPONSE_CODE )
   cOdp    := curl_easy_buffer( pCurl )
   curl_easy_cleanup( pCurl )

   xOdp := json_Decode( cOdp )
   IF nStatus >= 400 .OR. xOdp == NIL
      cBlad := "KSeF " + LTrim( Str( nStatus ) ) + ": " + s_OpisBledu( xOdp, cOdp )
      RETURN NIL
   ENDIF

RETURN xOdp

STATIC FUNCTION s_OpisBledu( xOdp, cOdp )

   LOCAL cOpis := ""

   IF ValType( xOdp ) == "H" .AND. HHasKey( xOdp, "exception" ) .AND. HHasKey( xOdp[ "exception" ], "exceptionDetailList" )
      AEval( xOdp[ "exception" ][ "exceptionDetailList" ], ;
             {| hSzczegol | cOpis += IIF( Empty( cOpis ), "", Eol() ) + LTrim( Str( hSzczegol[ "exceptionCode" ] ) ) + " " + hSzczegol[ "exceptionDescription" ] } )
      RETURN cOpis
   ENDIF
   IF ValType( xOdp ) == "H" .AND. HHasKey( xOdp, "title" )
      RETURN xOdp[ "title" ]
   ENDIF

RETURN Left( cOdp, 300 )
