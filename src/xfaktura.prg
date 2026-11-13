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
   oPorzadek:AddSeparator()
   oPorzadek:Add( "Wyczyść dane",               {| oWindow | s_Wyczysc( oWindow ) }, NIL, NIL, {|| s_Testowe() } )
   oPliki:AddSeparator()
   oPliki:Add( "Zakończ",                       {| oWindow | oWindow:Close() }, "Esc" )

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

STATIC FUNCTION s_Testowe()

   LOCAL cNip        := ""
   LOCAL nSrodowisko := 3

RETURN p_FirmaPobierzKsef( @cNip, @nSrodowisko ) .AND. nSrodowisko != 3

STATIC PROCEDURE s_Wyczysc( oWindow )

   LOCAL oDialog
   LOCAL oFaktury
   LOCAL oTokeny
   LOCAL oKontrahenci
   LOCAL oOk
   LOCAL oAnuluj
   LOCAL oFirma
   LOCAL aWybor := { .F., .F., .F., .F. }
   LOCAL aKatalog
   LOCAL cRok

   oDialog := gui_Dialog():New( oWindow, "Wyczyść dane", 420, 210 )
   oDialog:Center()

   oFaktury     := gui_CheckBox():New( oDialog, 20,  20, 380, 20, "Faktury, pliki XML i wydruki" )
   oTokeny      := gui_CheckBox():New( oDialog, 20,  50, 380, 20, "Tokeny KSeF" )
   oKontrahenci := gui_CheckBox():New( oDialog, 20,  80, 380, 20, "Kontrahenci" )
   oFirma       := gui_CheckBox():New( oDialog, 20, 110, 380, 20, "Dane firmy" )

   oOk     := gui_Button():New( oDialog, 220, 150, 90, 28, "OK" )
   oAnuluj := gui_Button():New( oDialog, 320, 150, 90, 28, "Anuluj" )

   oOk:isDefault    := .T.
   oOk:onClick      := {|| aWybor := { oFaktury:value, oTokeny:value, oKontrahenci:value, oFirma:value }, oDialog:EndDialog( 1 ) }
   oAnuluj:isCancel := .T.
   oAnuluj:onClick  := {|| oDialog:EndDialog( 0 ) }

   oDialog:ShowModal()

   IF aWybor[ 1 ]
      aKatalog := Directory( "*.*", "D" )
      FOR EACH cRok IN aKatalog
         IF Len( cRok[ 1 ] ) == 4 .AND. Val( cRok[ 1 ] ) > 0
            s_Usun( cRok[ 1 ] + DirSepToOS( "\" ) )
            s_Usun( cRok[ 1 ] + DirSepToOS( "\" ) + "xml" + DirSepToOS( "\" ) )
            s_Usun( cRok[ 1 ] + DirSepToOS( "\" ) + "wydruki" + DirSepToOS( "\" ) )
         ENDIF
      NEXT
   ENDIF
   IF aWybor[ 2 ]
      s_Usun( "ksef" + DirSepToOS( "\" ) )
   ENDIF
   IF aWybor[ 3 ]
      s_Usun( "kontrahenci" + DirSepToOS( "\" ) )
   ENDIF
   IF aWybor[ 4 ]
      s_Usun( "firma" + DirSepToOS( "\" ), "firma.*" )
   ENDIF

RETURN

STATIC PROCEDURE s_Usun( cKatalog, cMaska )

   LOCAL aPlik

   FOR EACH aPlik IN Directory( cKatalog + IIF( cMaska == NIL, "*.*", cMaska ) )
      FErase( cKatalog + aPlik[ 1 ] )
   NEXT

RETURN

STATIC PROCEDURE s_Start( oWindow )

   LOCAL cNip := ""
   LOCAL nSrodowisko

   IF p_FirmaPobierzKsef( @cNip, @nSrodowisko ) .AND. ! Empty( cNip )
      RETURN
   ENDIF

   p_Pomoc( oWindow, "Pierwsze kroki", ;
      Eol() + ;
      "Przed rozpoczęciem pracy uzupełnij dane:" + Eol() + ;
      Eol() + ;
      "1. Dane firmy:" + Eol() + ;
      "      Pliki --> Ustawienia --> Firma" + Eol() + ;
      "         Dane firmy" + Eol() + ;
      "            NIP, nazwa, adres itd." + Eol() + ;
      Eol() + ;
      "         KSeF" + Eol() + ;
      "            ( ) Testowe (próbny, do testów)" + Eol() + ;
      "            ( ) Produkcyjne (prawdziwe faktury)" + Eol() + ;
      Eol() + ;
      "2. Token KSeF:" + Eol() + ;
      "      Pliki --> Tokeny --> Lista tokenów" + Eol() + ;
      "         F3-Aplikacja KSeF" + Eol() + ;
      "            Zaloguj się do Aplikacji Podatnika KSeF" + Eol() + ;
      "            Wygeneruj token, a następnie skopiuj token" + Eol() + ;
      Eol() + ;
      "         F2-Dodaj" + Eol() + ;
      "            Wklej token (Ctrl+V), zapisz (PgDn)" + Eol() + ;
      Eol() + ;
      "         F5-Sprawdź" + Eol() + ;
      "            Sprawdza połączenie z KSeF" + Eol() + ;
      Eol() + ;
      "To okno pokazuje się, dopóki nie wpiszesz NIP firmy." )

RETURN

STATIC PROCEDURE s_Pomoc( oWindow )

   p_Pomoc( oWindow, "xFaktura", ;
      "Klawisze ogólne" + Eol() + ;
      Eol() + ;
      "F1             pomoc do bieżącego okna" + Eol() + ;
      "Esc, Alt+F4    zakończenie pracy z programem" + Eol() + ;
      Eol() + ;
      "Menu" + Eol() + ;
      Eol() + ;
      "Alt albo F10   wejście do menu" + Eol() + ;
      "Alt+P          Pliki" + Eol() + ;
      "Alt+M          Magazyn" + Eol() + ;
      "Alt+K          Kontrahenci" + Eol() + ;
      "Alt+F          Faktury" + Eol() + ;
      "Alt+O          Pomoc" + Eol() + ;
      "Strzałki       poruszanie się po menu" + Eol() + ;
      "Enter          wybór pozycji" + Eol() + ;
      "Esc            wyjście z menu" + Eol() + ;
      Eol() + ;
      "Okna i formularze" + Eol() + ;
      Eol() + ;
      "Tab            następne pole" + Eol() + ;
      "Shift+Tab      poprzednie pole" + Eol() + ;
      "Ctrl+Tab       następna zakładka" + Eol() + ;
      "Ctrl+Shift+Tab poprzednia zakładka" + Eol() + ;
      "Enter          przycisk domyślny okna" + Eol() + ;
      "Esc            rezygnacja, zamknięcie okna" )

RETURN

STATIC PROCEDURE s_WPrzygotowaniu()

   gui_MsgInfo( "Ta funkcja jest w przygotowaniu.", "xFaktura" )

RETURN
