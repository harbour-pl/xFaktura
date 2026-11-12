/*
 * Program....: xFaktura
 * Version....: 0.0.0
 * Plik.......: pomoc.prg
 *
 * Copyright (c) 2026 xDev-Language
 *
 * Compiler...: xDev
 * Version....: 0.0.0
 *
 * LICENSE....: GNU GENERAL PUBLIC LICENSE, Version 3, 29 June 2007
 */

PROCEDURE p_Pomoc( oOwner, cTytul, cTekst )

   LOCAL oDialog := gui_Dialog():New( oOwner, "Pomoc - " + cTytul, 560, 420 )
   LOCAL oOk     := gui_Button():New( oDialog, 460, 380, 90, 28, "OK" )
   LOCAL oTekst  := gui_Memo():New( oDialog, 10, 10, 540, 360, cTekst )

   oTekst:readOnly := .T.
   oTekst:font     := gui_Font():New( 10, .F., .F., "Consolas" )
   oTekst:anchor   := "LTRB"
   oOk:anchor      := "RB"
   oOk:isDefault   := .T.
   oOk:isCancel    := .T.
   oOk:onClick     := {|| oDialog:EndDialog( 1 ) }

   oDialog:ShowModal()

RETURN
