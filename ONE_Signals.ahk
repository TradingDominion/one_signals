#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include Lib\csv.ahk
#Include Lib\Class_LV_Colors.ahk

Gui, +AlwaysOnTop
Gui, Add, Button, x126 y7 w100 h30 Default gBtnLoadEvt, Load signal file
Gui, Add, DateTime, x115 y44 w120 h30 vSigDate gDateChangeEvt, ddd dd MMM yyyy
Gui, Add, Button, x17 y44 w90 h30 vBtnPrevDayEvt gBtnPrevDayEvt, Prev Day
Gui, Add, Button, x247 y44 w100 h30 vBtnNextDayEvt gBtnNextDayEvt, Next Day
Gui, Add, Checkbox, x131 y80 w90 h20 vChkLinkONE, Link with ONE
Gui, Add, StatusBar,, `  Please load a signal file
Gui, Add, ListView, x17 y110 r1 w330 vLVSigData hwndHLV,

; LV_Colors initial setup
global LVC := New LV_Colors(HLV)
If !IsObject(LVC) {
   MsgBox, 0, ERROR, Couldn't create a new LV_Colors object!
   ExitApp
}

; pre-load the prior signal file if it exists
IniRead, ExistingFilePath, ONE_Signals.ini, DataFile, FilePath
if (ExistingFilePath != "ERROR" and FileExist(ExistingFilePath))
	LoadSignalFile(ExistingFilePath)
else {
	; initially hide/disable some controls until the signal file is loaded
	GuiControl, Hide, SigDate
	GuiControl, Hide, BtnPrevDayEvt
	GuiControl, Hide, BtnNextDayEvt
	GuiControl, Hide, ChkLinkONE
	GuiControl, Hide, LVSigData
}

Gui, Show, w360 h195, Signal Browser - v0.1.2

return


LoadSignalFile(SelectedFile) {
	CSV_Load(SelectedFile, "data")
	global TotRows := CSV_TotalRows("data")
	TotSignals := CSV_TotalCols("data") - 1   ; we'll ignore the Date column
	FirstDate := CSV_ReadCell("data", 2, 1)
	LastDate := CSV_ReadCell("data", TotRows, 1)
	FirstDate_short := StrReplace(FirstDate, "-", "")
	LastDate_short := StrReplace(LastDate, "-", "")
	GuiControl, +Range%FirstDate_short%-%LastDate_short%, SigDate
	GuiControl,, SigDate, % LastDate_short
	global SigRow := TotRows

	; ListView control - header row (signal names)
	ColWidth := (330 / TotSignals) - 2
	SigNameRowContents := CSV_ReadRow("data", 1)
	SigNames := StrSplit(SigNameRowContents, ",")
	SigNames.RemoveAt(1)    ; remove the initial Date label from the array
	Loop %TotSignals% {
		SigName := SigNames[A_Index]
		LV_InsertCol(A_Index, ColWidth, SigName)
		LV_ModifyCol(A_Index, "Center")
	}

	GuiControl, Show, SigDate
	GuiControl, Show, BtnPrevDayEvt
	GuiControl, Show, BtnNextDayEvt
	GuiControl, Show, ChkLinkONE
	GuiControl, Show, LVSigData

	; ListView control - initial data row
	SigDataRowContents := CSV_ReadRow("data", 2)
	SigDataElements := StrSplit(SigDataRowContents, ",")
	LV_add(, SigDataElements[2], SigDataElements[3], SigDataElements[4])

	Set_Colors(SigDataElements)

	SB_SetText("  F7: Prev day     F8: Next day     F11: Link To One")   ; status bar
}


Set_Colors(SigDataElements){
	TotRows := CSV_TotalRows("data")
	TotSignals := CSV_TotalCols("data") - 1   ; we'll ignore the Date column
	SigNameRowContents := CSV_ReadRow("data", 1)
	SigNames := StrSplit(SigNameRowContents, ",")
	SigNames.RemoveAt(1)    ; remove the initial Date label from the array

	; LV_Colors settings
	GuiControl, -Redraw, %HLV%
	LVC.Clear()  ; clear colors
	Loop %TotSignals% {
		SigName := SigNames[A_Index]
		SigData := SigDataElements[A_Index + 1]
		IniRead, ColorData, ONE_Signals.ini, %SigName%, %SigData%
		Colors := StrSplit(ColorData, ",")
		LVC.Cell(1, A_Index, Colors[1], Colors[2])
	}
	GuiControl, +Redraw, %HLV%
	Sleep, 500    ; give it a bit of time to redraw the interface
}


Display_Data(SigRow){
	SigRowContents := CSV_ReadRow("data", SigRow)
	SigElements := StrSplit(SigRowContents, ",")
	NewDate := StrReplace(SigElements[1], "-", "")
	GuiControl,, SigDate, % NewDate
	LV_Modify(1,, SigElements[2], SigElements[3], SigElements[4])

	Set_Colors(SigElements)
}


BtnLoadEvt:
	FileSelectFile, SelectedFile, 3, , Open a file, CSV Files (*.csv)   ; 3 = file and path must exit
	if (SelectedFile != "") {
		; delete the contents of the existing data inside the ListView control
		LV_Delete()    ; delete all rows
		Loop % LV_GetCount("Column")    ; delete any existing columns in the ListView control
			LV_DeleteCol(1)

		IniWrite, FilePath=%SelectedFile%, ONE_Signals.ini, DataFile
		LoadSignalFile(SelectedFile)
	}
	return


BtnNextDayEvt:
	if (SigRow < TotRows) {
		++SigRow
		Display_Data(SigRow)

		GuiControlGet, LinkStatus,, ChkLinkONE
		if (LinkStatus = 1) {
			WinActivate, OptionNET Explorer
			WinWaitActive, OptionNET Explorer
			SendInput {F3}
		}
	}
	return


BtnPrevDayEvt:
	if (SigRow > 2) {
		--SigRow
		Display_Data(SigRow)

		GuiControlGet, LinkStatus,, ChkLinkONE
		if (LinkStatus = 1) {
			WinActivate, OptionNET Explorer
			WinWaitActive, OptionNET Explorer
			SendInput {F2}
		}
	}
	return


DateChangeEvt:
	GuiControlGet, NewDateTime,, SigDate
	FormatTime, NewDate, % NewDateTime, yyyy-MM-dd
	Result := CSV_MatchCell("data", NewDate, 1)
	SigRow := StrSplit(Result, ",")[1]
	Display_Data(SigRow)
	return


GuiEscape:
GuiClose:
	ExitApp


; keyboard shortcuts
F7::    ; keyboard shortcut for the "Prev Day" button
	gosub, BtnPrevDayEvt
	return


F8::     ; keyboard shortcut for the "Next Day" button
	gosub, BtnNextDayEvt
	return


F11::     ; keyboard shortcut for the "Link to ONE" checkbox
	GuiControlGet, LinkStatus,, ChkLinkONE
	if (LinkStatus = 0)
		GuiControl,, ChkLinkONE, 1
	else
		GuiControl,, ChkLinkONE, 0
	Gui, Submit, NoHide
	return
