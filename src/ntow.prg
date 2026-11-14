/*
 * Copyright (c) 2026 xDev-Language
 *
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: ntow.prg
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

STATIC FUNCTION s_Slownie( nValue )

   LOCAL aJednosci   := { "jeden", "dwa", "trzy", "cztery", "pięć", "sześć", "siedem", "osiem", "dziewięć" }
   LOCAL aNascie     := { "jedenaście", "dwanaście", "trzynaście", "czternaście", "piętnaście", "szesnaście", "siedemnaście", "osiemnaście", "dziewiętnaście" }
   LOCAL aDziesiatki := { "dziesięć", "dwadzieścia", "trzydzieści", "czterdzieści", "pięćdziesiąt", "sześćdziesiąt", "siedemdziesiąt", "osiemdziesiąt", "dziewięćdziesiąt" }
   LOCAL aSetki      := { "sto", "dwieście", "trzysta", "czterysta", "pięćset", "sześćset", "siedemset", "osiemset", "dziewięćset" }
   LOCAL aGrupy      := { { "tysiąc", "tysiące", "tysięcy"   }, { "milion", "miliony", "milionów"  }, { "miliard", "miliardy", "miliardów" }, { "bilion", "biliony", "bilionów"  }, { "biliard", "biliardy", "biliardów" }, { "trylion", "tryliony", "trylionów" } }
   LOCAL nGrupy   := 1
   LOCAL cSlownie := ""
   LOCAL cZnak    := ""
   LOCAL nWart
   LOCAL cWartSl
   LOCAL n

   nValue := Int( nValue )

   IF nValue < 0
      cZnak := "minus"
      nValue := -nValue
   ENDIF
   IF nValue == 0
      cZnak := "zero"
   ENDIF

   DO WHILE nValue > 0

      nWart := nValue % 1000

      IF nWart == 1
         n := 1
      ELSEIF ;
            nWart % 10 >= 2 .AND. ;
            nWart % 10 <= 4 .AND. ;
            ( nWart % 100 < 12 .OR. nWart % 100 > 14 )
         n := 2
      ELSE
         n := 3
      ENDIF

      cWartSl := ""
      IF nWart >= 100
         cWartSl := " " + aSetki[ Int( nWart / 100 ) ]
         nWart %= 100
      ENDIF
      IF nWart >= 11 .AND. nWart <= 19
         cWartSl += " " + aNascie[ nWart - 10 ]
         nWart := 0
      ELSEIF nWart >= 10
         cWartSl += " " + aDziesiatki[ Int( nWart / 10 ) ]
         nWart %= 10
      ENDIF
      IF nWart != 0
         cWartSl += " " + aJednosci[ nWart ]
      ENDIF
      IF Len( cWartSl ) > 0 .AND. nGrupy >= 2
         cWartSl += " " + aGrupy[ nGrupy - 1 ][ n ]
      ENDIF

      cSlownie := cWartSl + cSlownie
      nValue   := Int( nValue / 1000 )
      nGrupy++

   ENDDO

   cSlownie := cZnak + cSlownie

   RETURN LTrim( cSlownie )

FUNCTION KwotaSlownie( nKwota )
RETURN s_Slownie( Int( nKwota ) ) + " zł " + StrZero( Round( ( Abs( nKwota ) - Int( Abs( nKwota ) ) ) * 100, 0 ), 2 ) + "/100"
