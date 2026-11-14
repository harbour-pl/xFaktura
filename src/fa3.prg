/*
 * Copyright (c) 2026 xDev-Language
 *
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: fa3.prg
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#define FA3_NAMESPACE "http://crd.gov.pl/wzor/2025/06/25/13775/"

FUNCTION p_Fa3GenerujXml( hFirma )

   LOCAL cKlucz                 := FKTHEAD->RODZAJ + Str( FKTHEAD->NR_FAKTURY, 6 )

   LOCAL cNipSprzedawcy         := s_Tekst( hFirma[ "NIP__FIRMY" ] )
   LOCAL cNazwaSprzedawcy       := s_Tekst( hFirma[ "NAZWAFIRMY" ] )
   LOCAL cUlicaSprzedawcy       := s_Tekst( hFirma[ "ULICAFIRMY" ] )
   LOCAL cNrDomuSprzedawcy      := s_Tekst( hFirma[ "NRDOMUFIRM" ] )
   LOCAL cNrLokaluSprzedawcy    := s_Tekst( hFirma[ "NRLOKALUFI" ] )
   LOCAL cKodPocztowySprzedawcy := s_Tekst( hFirma[ "KODPOCZ" ] )
   LOCAL cMiejscowoscSprzedawcy := s_Tekst( hFirma[ "MIASTO" ] )

   LOCAL cNipNabywcy            := FKTHEAD->( FieldXml( "NIP_ODBIOR" ) )

   LOCAL cNazwaNabywcy          := s_Tekst( FKTHEAD->NAZWA___OD )
   LOCAL cKrajNabywcy           := IIF( Empty( FKTHEAD->KODKRAJ_OD ), "PL", FKTHEAD->( FieldXml( "KODKRAJ_OD" ) ) )
   LOCAL cUlicaNabywcy          := FKTHEAD->( FieldXml( "ULICA___OD" ) )
   LOCAL cKodPocztowyNabywcy    := FKTHEAD->( FieldXml( "KODPOCZ_OD" ) )
   LOCAL cMiejscowoscNabywcy    := FKTHEAD->( FieldXml( "MIEJSCE_OD" ) )
   LOCAL hStawki := { => }
   LOCAL aSuma
   LOCAL nNetto
   LOCAL nVat
   LOCAL pDoc    := xml_New()
   LOCAL pFaktura
   LOCAL pNode
   LOCAL pFa
   LOCAL pAdnotacje
   LOCAL pWiersz
   LOCAL pPlatnosc
   LOCAL cStawka
   LOCAL cXml
   LOCAL cAdresSprzedawcy1
   LOCAL cAdresSprzedawcy2
   LOCAL cAdresNabywcy2

   pFaktura := xml_Add( pDoc, "Faktura" )
   xml_SetAttr( pFaktura, "xmlns", FA3_NAMESPACE )

   pNode := xml_Add( pFaktura, "Naglowek" )

   xml_SetAttr( xml_Add( pNode, "KodFormularza", "FA" ), "kodSystemowy", "FA (3)" )
   xml_SetAttr( xml_Child( pNode, "KodFormularza" ), "wersjaSchemy", "1-0E" )

   xml_Add( pNode, "WariantFormularza", "3" )
   xml_Add( pNode, "DataWytworzeniaFa", s_Data( Date() ) + "T" + Time() )
   xml_Add( pNode, "SystemInfo", "xFaktura" )

   pNode := xml_Add( pFaktura, "Podmiot1" )
   cAdresSprzedawcy1 := s_AdresL1( cUlicaSprzedawcy, cNrDomuSprzedawcy, cNrLokaluSprzedawcy )
   cAdresSprzedawcy2 := s_AdresL2( cKodPocztowySprzedawcy, cMiejscowoscSprzedawcy )
   s_Strona( pNode, cNipSprzedawcy, cNazwaSprzedawcy, "PL", cAdresSprzedawcy1, cAdresSprzedawcy2 )

   pNode := xml_Add( pFaktura, "Podmiot2" )
   cAdresNabywcy2 := s_AdresL2( cKodPocztowyNabywcy, cMiejscowoscNabywcy )
   s_Strona( pNode, cNipNabywcy, cNazwaNabywcy, cKrajNabywcy, cUlicaNabywcy, cAdresNabywcy2 )
   xml_Add( pNode, "JST", "2" )
   xml_Add( pNode, "GV", "2" )

   FKTROW->( dbSeek( cKlucz ) )
   DO WHILE ! FKTROW->( Eof() ) .AND. FKTROW->RODZAJ + Str( FKTROW->NR_FAKTURY, 6 ) == cKlucz
      cStawka := s_Tekst( FKTROW->STAWKA_VAT )
      IF ! HHasKey( hStawki, cStawka )
         hStawki[ cStawka ] := { 0, 0 }
      ENDIF
      hStawki[ cStawka ][ 1 ] += IIF( FKTROW->PRZED, -1, 1 ) * FKTROW->WART_NETTO
      hStawki[ cStawka ][ 2 ] += IIF( FKTROW->PRZED, -1, 1 ) * FKTROW->KWOTA__VAT
      FKTROW->( dbSkip() )
   ENDDO

   pFa := xml_Add( pFaktura, "Fa" )
   xml_Add( pFa, "KodWaluty", "PLN" )
   xml_Add( pFa, "P_1", FKTHEAD->( FieldXml( "D_WYSTAWIE" ) ) )
   xml_Add( pFa, "P_2", FKTHEAD->( FieldXml( "NUMER_FKT" ) ) )
   IF ! Empty( FKTHEAD->D_SPRZEDAZ ) .AND. FKTHEAD->D_SPRZEDAZ != FKTHEAD->D_WYSTAWIE
      xml_Add( pFa, "P_6", FKTHEAD->( FieldXml( "D_SPRZEDAZ" ) ) )
   ENDIF
   FOR EACH aSuma IN { { "23", "22", "1" }, { "8", "7", "2" }, { "5", "5", "3" }, { "4", "3", "4" } }
      nNetto := 0
      nVat   := 0
      IF HHasKey( hStawki, aSuma[ 1 ] )
         nNetto += hStawki[ aSuma[ 1 ] ][ 1 ]
         nVat   += hStawki[ aSuma[ 1 ] ][ 2 ]
      ENDIF
      IF !( aSuma[ 2 ] == aSuma[ 1 ] ) .AND. HHasKey( hStawki, aSuma[ 2 ] )
         nNetto += hStawki[ aSuma[ 2 ] ][ 1 ]
         nVat   += hStawki[ aSuma[ 2 ] ][ 2 ]
      ENDIF
      IF HHasKey( hStawki, aSuma[ 1 ] ) .OR. HHasKey( hStawki, aSuma[ 2 ] )
         xml_Add( pFa, "P_13_" + aSuma[ 3 ], s_Kwota( nNetto ) )
         xml_Add( pFa, "P_14_" + aSuma[ 3 ], s_Kwota( nVat ) )
      ENDIF
   NEXT
   IF HHasKey( hStawki, "0" )
      xml_Add( pFa, "P_13_6_1", s_Kwota( hStawki[ "0" ][ 1 ] ) )
   ENDIF
   IF HHasKey( hStawki, "zw" )
      xml_Add( pFa, "P_13_7", s_Kwota( hStawki[ "zw" ][ 1 ] ) )
   ENDIF
   IF HHasKey( hStawki, "np" )
      xml_Add( pFa, "P_13_8", s_Kwota( hStawki[ "np" ][ 1 ] ) )
   ENDIF
   IF HHasKey( hStawki, "oo" )
      xml_Add( pFa, "P_13_10", s_Kwota( hStawki[ "oo" ][ 1 ] ) )
   ENDIF
   xml_Add( pFa, "P_15", FKTHEAD->( FieldXml( "BRUTTO_FKT" ) ) )

   pAdnotacje := xml_Add( pFa, "Adnotacje" )
   xml_Add( pAdnotacje, "P_16", "2" )
   xml_Add( pAdnotacje, "P_17", "2" )
   xml_Add( pAdnotacje, "P_18", IIF( HHasKey( hStawki, "oo" ), "1", "2" ) )
   xml_Add( pAdnotacje, "P_18A", "2" )
   pNode := xml_Add( pAdnotacje, "Zwolnienie" )
   IF HHasKey( hStawki, "zw" )
      xml_Add( pNode, "P_19", "1" )
      xml_Add( pNode, "P_19A", FKTHEAD->( FieldXml( "ZWOLNIENIE" ) ) )
   ELSE
      xml_Add( pNode, "P_19N", "1" )
   ENDIF
   xml_Add( xml_Add( pAdnotacje, "NoweSrodkiTransportu" ), "P_22N", "1" )
   xml_Add( pAdnotacje, "P_23", "2" )
   xml_Add( xml_Add( pAdnotacje, "PMarzy" ), "P_PMarzyN", "1" )
   IF FKTHEAD->RODZAJ == "KOR"
      xml_Add( pFa, "RodzajFaktury", "KOR" )
      IF ! Empty( FKTHEAD->KOR_PRZYCZ )
         xml_Add( pFa, "PrzyczynaKorekty", FKTHEAD->( FieldXml( "KOR_PRZYCZ" ) ) )
      ENDIF
      pNode := xml_Add( pFa, "DaneFaKorygowanej" )
      xml_Add( pNode, "DataWystFaKorygowanej", FKTHEAD->( FieldXml( "KOR_DATA" ) ) )
      xml_Add( pNode, "NrFaKorygowanej", FKTHEAD->( FieldXml( "KOR_NUMER" ) ) )
      IF Empty( FKTHEAD->KOR_KSEF )
         xml_Add( pNode, "NrKSeFN", "1" )
      ELSE
         xml_Add( pNode, "NrKSeF", "1" )
         xml_Add( pNode, "NrKSeFFaKorygowanej", FKTHEAD->( FieldXml( "KOR_KSEF" ) ) )
      ENDIF
   ELSE
      xml_Add( pFa, "RodzajFaktury", "VAT" )
   ENDIF

   FKTROW->( dbSeek( cKlucz ) )
   DO WHILE ! FKTROW->( Eof() ) .AND. FKTROW->RODZAJ + Str( FKTROW->NR_FAKTURY, 6 ) == cKlucz
      pWiersz := xml_Add( pFa, "FaWiersz" )
      xml_Add( pWiersz, "NrWierszaFa", FKTROW->( FieldXml( "LP_FKT_ROW" ) ) )
      xml_Add( pWiersz, "P_7",  FKTROW->( FieldXml( "NAZWA_TOWA" ) ) )
      xml_Add( pWiersz, "P_8A", FKTROW->( FieldXml( "JM_____FKT" ) ) )
      xml_Add( pWiersz, "P_8B", FKTROW->( FieldXml( "ILOSC__FKT" ) ) )
      xml_Add( pWiersz, "P_9A", FKTROW->( FieldXml( "CENA_JEDNO" ) ) )
      xml_Add( pWiersz, "P_11", FKTROW->( FieldXml( "WART_NETTO" ) ) )
      xml_Add( pWiersz, "P_12", s_Stawka( FKTROW->( FieldXml( "STAWKA_VAT" ) ) ) )
      IF FKTROW->PRZED
         xml_Add( pWiersz, "StanPrzed", "1" )
      ENDIF
      FKTROW->( dbSkip() )
   ENDDO

   pPlatnosc := xml_Add( pFa, "Platnosc" )
   IF ! Empty( FKTHEAD->TERMIN_PLA )
      xml_Add( xml_Add( pPlatnosc, "TerminPlatnosci" ), "Termin", FKTHEAD->( FieldXml( "TERMIN_PLA" ) ) )
   ENDIF
   xml_Add( pPlatnosc, "FormaPlatnosci", LTrim( Str( IIF( FKTHEAD->FORMA_PLAT == 0, 6, FKTHEAD->FORMA_PLAT ) ) ) )
   IF ! Empty( FKTHEAD->KONTO___OD )
      pNode := xml_Add( pPlatnosc, "RachunekBankowy" )
      xml_Add( pNode, "NrRB", s_Rachunek( FKTHEAD->KONTO___OD ) )
      IF ! Empty( FKTHEAD->BANK____OD )
         xml_Add( pNode, "NazwaBanku", FKTHEAD->( FieldXml( "BANK____OD" ) ) )
      ENDIF
   ENDIF

   cXml := xml_ToString( pDoc )
   xml_Free( pDoc )

RETURN cXml

STATIC PROCEDURE s_Strona( pNode, cNip, cNazwa, cKraj, cAdres1, cAdres2 )

   LOCAL pDane  := xml_Add( pNode, "DaneIdentyfikacyjne" )
   LOCAL pAdres

   IF Empty( cNip )
      xml_Add( pDane, "BrakID", "1" )
   ELSE
      xml_Add( pDane, "NIP", cNip )
   ENDIF

   xml_Add( pDane, "Nazwa", cNazwa )

   pAdres := xml_Add( pNode, "Adres" )
   xml_Add( pAdres, "KodKraju", cKraj )
   xml_Add( pAdres, "AdresL1", IIF( Empty( cAdres1 ), cAdres2, cAdres1 ) )
   IF ! Empty( cAdres1 ) .AND. ! Empty( cAdres2 )
      xml_Add( pAdres, "AdresL2", cAdres2 )
   ENDIF

RETURN

STATIC FUNCTION s_Tekst( cTekst )
RETURN AllTrim( StrTran( cTekst, Eol( cTekst ), " " ) )

STATIC FUNCTION s_AdresL1( cUlica, cNrDomu, cNrLokalu )

   LOCAL cAdres := cUlica + " " + cNrDomu

   IF ! Empty( cNrLokalu )
      cAdres += "/" + cNrLokalu
   ENDIF

RETURN s_Tekst( cAdres )

STATIC FUNCTION s_AdresL2( cKodPocztowy, cMiejscowosc )
RETURN s_Tekst( cKodPocztowy + " " + cMiejscowosc )

STATIC FUNCTION s_Rachunek( cKonto )
RETURN StrTran( StrTran( s_Tekst( cKonto ), " " ), "PL" )

STATIC FUNCTION s_Data( dData )

   LOCAL cData := DToS( dData )

RETURN Left( cData, 4 ) + "-" + SubStr( cData, 5, 2 ) + "-" + Right( cData, 2 )

STATIC FUNCTION s_Kwota( nKwota )

RETURN LTrim( Str( nKwota, 15, 2 ) )

STATIC FUNCTION s_Stawka( cStawka )

   DO CASE
   CASE cStawka == "0"
      RETURN "0 KR"
   CASE cStawka == "np"
      RETURN "np I"
   ENDCASE

RETURN cStawka
