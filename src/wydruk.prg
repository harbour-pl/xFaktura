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
