#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; This script makes use of the following repo: https://github.com/hi5/CSV
; File contents: https://raw.githubusercontent.com/hi5/CSV/master/csv.ahk
; You'll need to add csv.ahk to any of the following locations:
;      .\Lib
;      MyDocuments\AutoHotKey\Lib
;      <AutoHotKeyInstallationDir>\AutoHotKey\Lib

SigRow := 2    ; this will be the row of the oldest date (skipping the header line)

Gui, +AlwaysOnTop
Gui, Add, Button, x126 y7 w100 h30 Default gBtnLoadEvt, Load signal file
Gui, Add, DateTime, x115 y44 w120 h30 vSigDate gDateChangeEvt, ddd dd MMM yyyy
Gui, Add, Button, x17 y44 w90 h30 vBtnPrevDayEvt gBtnPrevDayEvt, Prev Day
Gui, Add, Button, x247 y44 w100 h30 vBtnNextDayEvt gBtnNextDayEvt, Next Day
Gui, Add, Checkbox, x131 y80 w90 h20 vChkLinkONE, Link with ONE
Gui, Add, StatusBar,, `  Please load a signal file
Gui, Add, ListView, x17 y110 r1 w330 vLVSigData,

; initially hide/disable some controls until the signal file is loaded
GuiControl, Hide, SigDate
GuiControl, Hide, BtnPrevDayEvt
GuiControl, Hide, BtnNextDayEvt
GuiControl, Hide, ChkLinkONE
GuiControl, Hide, LVSigData

Gui, Show, w360 h195, Signal Browser
return


BtnLoadEvt:
	FileSelectFile, SelectedFile, 3, , Open a file, CSV Files (*.csv)   ; 3 = file and path must exit
	CSV_Load(SelectedFile, "data")
	TotRows := CSV_TotalRows("data")
	TotSignals := CSV_TotalCols("data") - 1   ; we'll ignore the Date column
	FirstDate := CSV_ReadCell("data", 2, 1)
	LastDate := CSV_ReadCell("data", TotRows, 1)
	FirstDate_short := StrReplace(FirstDate, "-", "")
	LastDate_short := StrReplace(LastDate, "-", "")
	GuiControl, +Range%FirstDate_short%-%LastDate_short%, SigDate
	GuiControl,, SigDate, % LastDate_short

	; ListView control - header row (signal names)
	ColWidth := (330 / TotSignals) - 2
	SigNameRowContents := CSV_ReadRow("data", 1)
	SigNameElements := StrSplit(SigNameRowContents, ",")
	Loop %TotSignals% {
		SigElementIndex := A_Index + 1
		LV_InsertCol(A_Index, ColWidth, SigNameElements[SigElementIndex])
		LV_ModifyCol(A_Index, "Center")
	}

	; ListView control - initial data row
	SigDataRowContents := CSV_ReadRow("data", 2)
	SigDataElements := StrSplit(SigDataRowContents, ",")
	LV_add(, SigDataElements[2], SigDataElements[3], SigDataElements[4])

	; re-enable the controls
	GuiControl, Show, SigDate
	GuiControl, Show, BtnPrevDayEvt
	GuiControl, Show, BtnNextDayEvt
	GuiControl, Show, ChkLinkONE
	GuiControl, Show, LVSigData

	SB_SetText("  F7: Prev day     F8: Next day     F11: Link To One")   ; status bar

	return


BtnNextDayEvt:
	if (SigRow < TotRows) {
		++SigRow
		SigRowContents := CSV_ReadRow("data", SigRow)
		SigElements := StrSplit(SigRowContents, ",")
		NewDate := StrReplace(SigElements[1], "-", "")
		GuiControl,, SigDate, % NewDate
		LV_Modify(1,, SigElements[2], SigElements[3], SigElements[4])
	}
	return


BtnPrevDayEvt:
	if (SigRow > 2) {
		--SigRow
		SigRowContents := CSV_ReadRow("data", SigRow)
		SigElements := StrSplit(SigRowContents, ",")
		NewDate := StrReplace(SigElements[1], "-", "")
		GuiControl,, SigDate, % NewDate
		LV_Modify(1,, SigElements[2], SigElements[3], SigElements[4])
	}
	return


DateChangeEvt:
	GuiControlGet, NewDateTime,, SigDate
	FormatTime, NewDate, % NewDateTime, yyyy-MM-dd
	Result := CSV_MatchCell("data", NewDate, 1)
	SigRow := StrSplit(Result, ",")[1]
	SigRowContents := CSV_ReadRow("data", SigRow)
	SigElements := StrSplit(SigRowContents, ",")
	NewDate := StrReplace(SigElements[1], "-", "")
	GuiControl,, SigDate, % NewDate
	LV_Modify(1,, SigElements[2], SigElements[3], SigElements[4])
	return


GuiEscape:
GuiClose:
	ExitApp


; keyboard shortcuts
F7::
	GuiControlGet, LinkStatus,, ChkLinkONE
	if (LinkStatus = 1) {
		WinActivate, OptionNET Explorer
		WinWaitActive, OptionNET Explorer
		SendInput {F2}
	}

	gosub, BtnPrevDayEvt
	return


F8::
	GuiControlGet, LinkStatus,, ChkLinkONE
	if (LinkStatus = 1) {
		WinActivate, OptionNET Explorer
		WinWaitActive, OptionNET Explorer
		SendInput {F3}
	}

	gosub, BtnNextDayEvt
	return


F11::
	GuiControlGet, LinkStatus,, ChkLinkONE
	if (LinkStatus = 0)
		GuiControl,, ChkLinkONE, 1
	else
		GuiControl,, ChkLinkONE, 0
	Gui, Submit, NoHide
	return
