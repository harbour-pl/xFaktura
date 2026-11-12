#include "svg.ch"

PROCEDURE Main()

   LOCAL pSvg
   LOCAL nWidth := 512, nHeight := 512
   LOCAL nY := 422

   pSvg := svg_Init( "xFaktura.svg", nWidth, nHeight )

   svg_Comment( pSvg, "#132639 #264d73 #73264d #4d7326 #262773 #267373 #734c26" )

   svg_FilledRect( pSvg, 0, 0, 512, 512, "#132639" )

   svg_Text( pSvg, nWidth / 2 + 2, nY, "F", "Times New Roman", 500, FONT_WEIGHT_BOLD, "#ffffff", SVG_ALIGN_CENTER )

   svg_Close( pSvg )

RETURN
