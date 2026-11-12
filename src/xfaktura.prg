/*
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: xfaktura.prg
 *
 * Copyright (c) 2026 xDev-Language
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "set.ch"
#include "xfaktura.ch"

STATIC aSet := { NIL }

PROCEDURE Main( cWybierzRok )

   LOCAL oWindow
   LOCAL oStatus

   Set( _SET_DELETED, .T. )
   Set( _SET_DATEFORMAT, "dd.mm.yyyy" )

   SetCentury( .T. )

   IF Empty( cWybierzRok )
      aSet[ ROK ] := LTrim( Str( Year( Date() ) ) ) + DirSepToOS( "\" )
   ELSE
      aSet[ ROK ] := cWybierzRok + DirSepToOS( "\" )
   ENDIF

   s_Katalog()

   gui_MenuStyle( .T., 32 )

   oWindow := gui_Window():New( "xFaktura ", 1000, 640 )
   oWindow:menu       := s_Menu()
   oWindow:background := 0x132639
   oWindow:Center()

   oStatus := gui_StatusBar():New( oWindow )

   oWindow:Show()
   s_Start( oWindow )

   gui_Application():Run( oWindow )

RETURN

FUNCTION p_RokPobierz()
RETURN aSet[ ROK ]

FUNCTION p_PlikKontrolny()
RETURN "firma" + DirSepToOS( "\" ) + "kopia.txt"

STATIC PROCEDURE s_Katalog()

   LOCAL aKatalog
   LOCAL lRok         := .F.
   LOCAL lFirma       := .F.
   LOCAL lKsef        := .F.
   LOCAL lKontrahenci := .F.
   LOCAL lTowary      := .F.
   LOCAL i

   aKatalog := Directory( "*.*", "D" )

   FOR i := 1 TO Len( aKatalog )
      IF aKatalog[ i ][ 1 ] == SubStr( aSet[ ROK ], 1, 4 )
         lRok := .T.
      ENDIF
      IF aKatalog[ i ][ 1 ] == "firma"
         lFirma := .T.
      ENDIF
      IF aKatalog[ i ][ 1 ] == "ksef"
         lKsef := .T.
      ENDIF
      IF aKatalog[ i ][ 1 ] == "kontrahenci"
         lKontrahenci := .T.
      ENDIF
      IF aKatalog[ i ][ 1 ] == "towary"
         lTowary := .T.
      ENDIF
   NEXT

   IF ! lRok
      MakeDir( aSet[ ROK ] )
      MakeDir( aSet[ ROK ] + "wydruki" )
   ENDIF
   IF ! lFirma
      MakeDir( "firma" )
   ENDIF
   IF ! lKsef
      MakeDir( "ksef" )
   ENDIF
   IF ! lKontrahenci
      MakeDir( "kontrahenci" )
   ENDIF
   IF ! lTowary
      MakeDir( "towary" )
   ENDIF

RETURN

STATIC FUNCTION s_Menu()

   LOCAL oMenu
   LOCAL oPliki
   LOCAL oMagazyn
   LOCAL oKontrahenci
   LOCAL oFaktury
   LOCAL oPomoc
   LOCAL oTokeny
   LOCAL oKopie
   LOCAL oPorzadek
   LOCAL oUstawienia

   oMenu := gui_Menu():New()

   oPliki := oMenu:AddMenu( "&Pliki" )
   oUstawienia := oPliki:AddMenu( "Ustawienia" )
   oUstawienia:Add( "Firma",                    {| oWindow | p_Firma( oWindow ) } )
   oUstawienia:Add( "Opcje",                    {| oWindow | p_Opcje( oWindow ) } )
   oTokeny := oPliki:AddMenu( "Tokeny" )
   oTokeny:Add( "Generuj token",                {| oWindow | p_GenerujToken( oWindow ) }, NIL, NIL, {|| .F. } )
   oTokeny:Add( "Lista tokenów",                {| oWindow | p_Tokeny( oWindow ) } )
   oPliki:AddSeparator()
   oKopie := oPliki:AddMenu( "Obsługa kopii danych", "Save" )
   oKopie:Add( "Archiwizacja baz danych",       {| oWindow | p_Archiwizacja( oWindow ) }, NIL, "Backup" )
   oKopie:Add( "Odtworzenie baz danych",        {| oWindow | p_Odtworzenie( oWindow ) }, NIL, "Restore" )
   oPorzadek := oPliki:AddMenu( "Porządkowanie danych" )
   oPorzadek:Add( "Indeksowanie baz danych",    {|| s_Indeksowanie() } )
   oPliki:AddSeparator()
   oPliki:Add( "Zakończ",                       {| oWindow | s_Zakoncz( oWindow ) }, "Alt+F4" )

   oMagazyn := oMenu:AddMenu( "&Magazyn" )
   oMagazyn:Add( "Towary i usługi",       {|| NIL }, NIL, NIL, {|| .F. } )
   oMagazyn:AddSeparator()
   oMagazyn:Add( "Przyjęcie towaru (PZ)", {|| NIL }, NIL, NIL, {|| .F. } )
   oMagazyn:Add( "Stany magazynowe",      {|| NIL }, NIL, NIL, {|| .F. } )
   oMagazyn:AddSeparator()
   oMagazyn:Add( "Remanent",              {|| NIL }, NIL, NIL, {|| .F. } )

   oKontrahenci := oMenu:AddMenu( "&Kontrahenci" )
   oKontrahenci:Add( "Lista kontrahentów", {| oWindow | p_Kontrahenci( oWindow ) } )

   oFaktury := oMenu:AddMenu( "&Faktury" )
   oFaktury:Add( "Wystaw fakturę VAT", {| oWindow | p_Faktury( oWindow ) } )
   oFaktury:Add( "Wystaw fakturę RR",  {|| NIL }, NIL, NIL, {|| .F. } )

   oPomoc := oMenu:AddMenu( "P&omoc" )
   oPomoc:Add( "Pomoc",                {| oWindow | s_Pomoc( oWindow ) }, "F1" )
   oPomoc:Add( "Pomoc indeks",         {|| s_WPrzygotowaniu() }, "Alt+F1" )
   oPomoc:Add( "Zawartość pomocy",     {|| s_WPrzygotowaniu() } )
   oPomoc:AddSeparator()
   oPomoc:Add( "Witryna Online",       {|| s_WPrzygotowaniu() } )
   oPomoc:Add( "Kontakt z nami",       {|| s_WPrzygotowaniu() } )
   oPomoc:AddSeparator()
   oPomoc:Add( "Sprawdź aktualizację", {|| s_WPrzygotowaniu() } )
   oPomoc:Add( "Aktywuj produkt...",   {|| s_WPrzygotowaniu() } )
   oPomoc:AddSeparator()
   oPomoc:Add( "Fakturowanie sprzedaży - Informacje", {|| s_WPrzygotowaniu() } )

RETURN oMenu

STATIC PROCEDURE s_Indeksowanie()

   IF gui_MsgYesNo( "Indeksowanie i czyszczenie zbiorów", "Porządkowanie danych" )

      p_KontrahenciNtx()
      p_TokenyNtx()
      p_FakturyNtx()

      gui_MsgInfo( "Indeksowanie przebiegło prawidłowo", "Porządkowanie danych" )

   ENDIF

RETURN

STATIC PROCEDURE s_Zakoncz( oWindow )

   IF gui_MsgYesNo( "Kończysz pracę z programem?", "Koniec pracy" )
      oWindow:Close()
   ENDIF

RETURN

STATIC PROCEDURE s_Start( oWindow )

   LOCAL cNip := ""
   LOCAL nSrodowisko

   IF p_FirmaPobierzKsef( @cNip, @nSrodowisko ) .AND. ! Empty( cNip )
      RETURN
   ENDIF

   p_Pomoc( oWindow, "Pierwsze kroki", ;
      e"\n" + ;
      e"Przed rozpoczęciem pracy uzupełnij dane:\n" + ;
      e"\n" + ;
      e"1. Dane firmy:\n" + ;
      e"      Pliki --> Ustawienia --> Firma\n" + ;
      e"         Dane Firmy\n" + ;
      e"            NIP, nazwa, adres itd.\n" + ;
      e"\n" + ;
      e"         KSeF\n" + ;
      e"            ( ) Testowe (próbny, do testów)\n" + ;
      e"            ( ) Produkcyjne (prawdziwe faktury)\n" + ;
      e"\n" + ;
      e"2. Token KSeF:\n" + ;
      e"      Pliki --> Tokeny --> Lista tokenów\n" + ;
      e"         F3-Aplikacja KSeF\n" + ;
      e"            Zaloguj się do Aplikacji Podatnika KSeF\n" + ;
      e"            Wygeneruj token, a następnie skopiuj token\n" + ;
      e"\n" + ;
      e"         F2-Dodaj\n" + ;
      e"            Wklej token (Ctrl+V), zapisz (PgDn)\n" + ;
      e"\n" + ;
      e"         F5-Sprawdź\n" + ;
      e"            Sprawdza połączenie z KSeF\n" + ;
      e"\n" + ;
      "To okno pokazuje się, dopóki nie wpiszesz NIP firmy." )

RETURN

STATIC PROCEDURE s_Pomoc( oWindow )

   p_Pomoc( oWindow, "xFaktura", ;
      "Klawisze ogólne" + Chr( 10 ) + ;
      Chr( 10 ) + ;
      "F1             pomoc do bieżącego okna" + Chr( 10 ) + ;
      "Alt+F4         zakończenie pracy z programem" + Chr( 10 ) + ;
      Chr( 10 ) + ;
      "Menu" + Chr( 10 ) + ;
      Chr( 10 ) + ;
      "Alt albo F10   wejście do menu" + Chr( 10 ) + ;
      "Alt+P          Pliki" + Chr( 10 ) + ;
      "Alt+M          Magazyn" + Chr( 10 ) + ;
      "Alt+K          Kontrahenci" + Chr( 10 ) + ;
      "Alt+F          Faktury" + Chr( 10 ) + ;
      "Alt+U          Ustawienia" + Chr( 10 ) + ;
      "Alt+O          Pomoc" + Chr( 10 ) + ;
      "Strzałki       poruszanie się po menu" + Chr( 10 ) + ;
      "Enter          wybór pozycji" + Chr( 10 ) + ;
      "Esc            wyjście z menu" + Chr( 10 ) + ;
      Chr( 10 ) + ;
      "Okna i formularze" + Chr( 10 ) + ;
      Chr( 10 ) + ;
      "Tab            następne pole" + Chr( 10 ) + ;
      "Shift+Tab      poprzednie pole" + Chr( 10 ) + ;
      "Ctrl+Tab       następna zakładka" + Chr( 10 ) + ;
      "Ctrl+Shift+Tab poprzednia zakładka" + Chr( 10 ) + ;
      "Enter          przycisk domyślny okna" + Chr( 10 ) + ;
      "Esc            rezygnacja, zamknięcie okna" )

RETURN

STATIC PROCEDURE s_WPrzygotowaniu()

   gui_MsgInfo( "Ta funkcja jest w przygotowaniu.", "xFaktura" )

RETURN
