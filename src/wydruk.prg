/*
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: wydruk.prg
 *
 * Copyright (c) 2026 xDev-Language
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "hpdf.ch"
#include "qrcode.ch"

PROCEDURE p_WydrukUstawZnaki( pPage, pFont )

   LOCAL aKolor   := { { 0.451, 0.149, 0.302 }, { 0.149, 0.153, 0.451 }, { 0.149, 0.451, 0.451 } }
   LOCAL nPromien := 11.34
   LOCAL nGora    := HPDF_Page_GetHeight( pPage ) - 35
   LOCAL cStopka  := "Wydrukowano w programie xFaktura"
   LOCAL nKolko

   FOR nKolko := 1 TO Len( aKolor )
      HPDF_Page_SetRGBFill( pPage, aKolor[ nKolko ][ 1 ], aKolor[ nKolko ][ 2 ], aKolor[ nKolko ][ 3 ] )
      HPDF_Page_Circle( pPage, 40 + nPromien + ( nKolko - 1 ) * ( 2 * nPromien + 6 ), nGora, nPromien )
      HPDF_Page_Fill( pPage )
   NEXT

   HPDF_Page_SetRGBFill( pPage, 0.55, 0.55, 0.55 )
   HPDF_Page_SetFontAndSize( pPage, pFont, 8 )
   HPDF_Page_BeginText( pPage )
   HPDF_Page_TextOut( pPage, ( HPDF_Page_GetWidth( pPage ) - HPDF_Page_TextWidth( pPage, cStopka ) ) / 2, 25, cStopka )
   HPDF_Page_EndText( pPage )
   HPDF_Page_SetRGBFill( pPage, 0, 0, 0 )

RETURN

FUNCTION p_WydrukKwota( nKwota )

   LOCAL cLiczba := LTrim( Str( Abs( nKwota ), 15, 2 ) )
   LOCAL cCalosc := Left( cLiczba, Len( cLiczba ) - 3 )
   LOCAL cWynik  := ""

   DO WHILE Len( cCalosc ) > 3
      cWynik  := " " + Right( cCalosc, 3 ) + cWynik
      cCalosc := Left( cCalosc, Len( cCalosc ) - 3 )
   ENDDO

RETURN IIF( nKwota < 0, "-", "" ) + cCalosc + cWynik + "," + Right( cLiczba, 2 )

FUNCTION p_WydrukIlosc( nIlosc )

   LOCAL cLiczba := LTrim( Str( nIlosc, 15, 3 ) )

   DO WHILE Right( cLiczba, 1 ) == "0"
      cLiczba := Left( cLiczba, Len( cLiczba ) - 1 )
   ENDDO
   IF Right( cLiczba, 1 ) == "."
      cLiczba := Left( cLiczba, Len( cLiczba ) - 1 )
   ENDIF

RETURN StrTran( cLiczba, ".", "," )

FUNCTION p_WydrukFormaPlatnosci( nForma )

   DO CASE
   CASE nForma == 1
      RETURN "gotówka"
   CASE nForma == 2
      RETURN "karta"
   ENDCASE

RETURN "przelew"

PROCEDURE p_WydrukTekst( pPage, pFont, nSize, nX, nY, cTekst, nSzer )

   HPDF_Page_SetFontAndSize( pPage, pFont, nSize )
   IF HPDF_Page_TextWidth( pPage, cTekst ) > nSzer
      DO WHILE ULen( cTekst ) > 0 .AND. HPDF_Page_TextWidth( pPage, cTekst + "…" ) > nSzer
         cTekst := ULeft( cTekst, ULen( cTekst ) - 1 )
      ENDDO
      cTekst += "…"
   ENDIF
   HPDF_Page_BeginText( pPage )
   HPDF_Page_TextOut( pPage, nX, nY, cTekst )
   HPDF_Page_EndText( pPage )

RETURN

PROCEDURE p_WydrukPrawo( pPage, pFont, nSize, nPrawo, nY, cTekst )

   HPDF_Page_SetFontAndSize( pPage, pFont, nSize )
   HPDF_Page_BeginText( pPage )
   HPDF_Page_TextOut( pPage, nPrawo - HPDF_Page_TextWidth( pPage, cTekst ), nY, cTekst )
   HPDF_Page_EndText( pPage )

RETURN

PROCEDURE p_WydrukPasek( pPage, pBold, nY, aKolumna, aTytul, aPrawo )

   LOCAL nKolumna

   HPDF_Page_SetRGBFill( pPage, 0.302, 0.451, 0.149 )
   HPDF_Page_Rectangle( pPage, aKolumna[ 1 ], nY - 5, ATail( aKolumna ) - aKolumna[ 1 ], 16 )
   HPDF_Page_Fill( pPage )
   HPDF_Page_SetRGBFill( pPage, 1, 1, 1 )
   FOR nKolumna := 1 TO Len( aTytul )
      IF aPrawo[ nKolumna ]
         p_WydrukPrawo( pPage, pBold, 8, aKolumna[ nKolumna + 1 ] - 3, nY, aTytul[ nKolumna ] )
      ELSE
         p_WydrukTekst( pPage, pBold, 8, aKolumna[ nKolumna ] + 3, nY, aTytul[ nKolumna ], aKolumna[ nKolumna + 1 ] - aKolumna[ nKolumna ] - 6 )
      ENDIF
   NEXT
   HPDF_Page_SetRGBFill( pPage, 0, 0, 0 )

RETURN

PROCEDURE p_WydrukStrona( pPage, pFont, pBold, nX, nY, cTytul, cNazwa, aAdres, cNip )

   LOCAL aLinie := ATokens( cNazwa, Eol( cNazwa ) )
   LOCAL cLinia

   p_WydrukTekst( pPage, pFont, 8, nX, nY, cTytul, 240 )
   HPDF_Page_SetRGBStroke( pPage, 0.302, 0.451, 0.149 )
   HPDF_Page_SetLineWidth( pPage, 0.8 )
   HPDF_Page_MoveTo( pPage, nX, nY - 4 )
   HPDF_Page_LineTo( pPage, nX + 245, nY - 4 )
   HPDF_Page_Stroke( pPage )
   nY -= 18
   FOR EACH cLinia IN aLinie
      IF ! Empty( cLinia )
         p_WydrukTekst( pPage, pBold, 10, nX, nY, AllTrim( cLinia ), 245 )
         nY -= 13
      ENDIF
   NEXT
   FOR EACH cLinia IN aAdres
      IF ! Empty( cLinia )
         p_WydrukTekst( pPage, pFont, 9, nX, nY, cLinia, 245 )
         nY -= 12
      ENDIF
   NEXT
   IF ! Empty( cNip )
      p_WydrukTekst( pPage, pFont, 9, nX, nY, "NIP: " + cNip, 245 )
   ENDIF

RETURN

FUNCTION p_WydrukQrAdres( hFirma )

   LOCAL cXml
   LOCAL cSkrot

   IF FKTHEAD->KSEF_STAT != 2 .AND. FKTHEAD->KSEF_TRYB == 0
      RETURN ""
   ENDIF
   cXml := MemoRead( p_RokPobierz() + "xml" + DirSepToOS( "\" ) + StrTran( AllTrim( FKTHEAD->NUMER_FKT ), "/", "_" ) + ".xml" )
   IF Empty( cXml )
      RETURN ""
   ENDIF
   cSkrot := StrTran( StrTran( StrTran( Base64Encode( HashData( "SHA256", cXml ) ), "+", "-" ), "/", "_" ), "=", "" )

RETURN IIF( hFirma[ "KSEF_SROD" ] == 3, "https://qr.ksef.mf.gov.pl", "https://qr-test.ksef.mf.gov.pl" ) + ;
       "/invoice/" + AllTrim( hFirma[ "NIP__FIRMY" ] ) + "/" + ;
       StrZero( Day( FKTHEAD->D_WYSTAWIE ), 2 ) + "-" + StrZero( Month( FKTHEAD->D_WYSTAWIE ), 2 ) + "-" + ;
       Str( Year( FKTHEAD->D_WYSTAWIE ), 4 ) + "/" + cSkrot

PROCEDURE p_WydrukQr( pPage, cTekst, nX, nY, nRozmiar )

   LOCAL aRzad := QrEncode( cTekst, QR_ECC_MEDIUM )
   LOCAL nModul
   LOCAL nRzad
   LOCAL nKol
   LOCAL nOd

   IF aRzad == NIL
      RETURN
   ENDIF
   nModul := nRozmiar / Len( aRzad )
   HPDF_Page_SetRGBFill( pPage, 0, 0, 0 )
   FOR nRzad := 1 TO Len( aRzad )
      nKol := 1
      DO WHILE nKol <= Len( aRzad[ nRzad ] )
         IF SubStr( aRzad[ nRzad ], nKol, 1 ) == "1"
            nOd := nKol
            DO WHILE nKol <= Len( aRzad[ nRzad ] ) .AND. SubStr( aRzad[ nRzad ], nKol, 1 ) == "1"
               nKol++
            ENDDO
            HPDF_Page_Rectangle( pPage, nX + ( nOd - 1 ) * nModul, nY + nRozmiar - nRzad * nModul, ;
                                 ( nKol - nOd ) * nModul, nModul )
         ELSE
            nKol++
         ENDIF
      ENDDO
   NEXT
   HPDF_Page_Fill( pPage )

RETURN
