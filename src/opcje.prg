/*
 * Copyright (c) 2026 xDev-Language
 *
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: opcje.prg
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

#include "xfaktura.ch"

PROCEDURE p_Opcje( oWindow )

   LOCAL oDialog
   LOCAL oToolbar
   LOCAL oPanel
   LOCAL oStatus

   oDialog := gui_Dialog():New( oWindow, "Ustawienie opcji", 650, 450 )
   oDialog:background := 0xe9edf1

   oStatus := gui_StatusBar():New( oDialog )
   oStatus:name := "STATUS_BAR"
   oStatus:font := gui_Font():New( NIL, .F., .F., "xFont 9x18" )
   oStatus:Add( 0 )

   oToolbar := gui_Toolbar():New( oDialog, "Bottom" )
   oToolbar:Add( "F1-Pomoc",    NIL, {|| s_Pomoc( oDialog ) }, NIL, "F1" )
   oToolbar:AddSeparator()
   oToolbar:Add( "Esc-Zamknij", NIL, {|| oDialog:Close() }, NIL, "Esc" )

   oPanel := gui_Panel():New( oDialog )

   oDialog:Center()
   oDialog:ShowModal()

RETURN

STATIC PROCEDURE s_Pomoc( oWindow )

   p_Pomoc( oWindow, "Ustawienie opcji", ;
      Eol() + ;
      "F1             pomoc" + Eol() + ;
      "Esc            zamknięcie okna" )

RETURN
