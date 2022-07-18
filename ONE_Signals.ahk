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
Gui, Add, StatusBar,, Please load a signal file

; signal label text objects
Gui, Font, bold
Gui, Add, Text, x17 y110 w90 h20 vLblSig1,
Gui, Add, Text, x115 y110 w90 h20 vLblSig2,
Gui, Add, Text, x247 y110 w90 h20 vLblSig3,
GuiControl, +Center, LblSig1
GuiControl, +Center, LblSig2
GuiControl, +Center, LblSig3

; signal data text objects
Gui, Font, norm
Gui, Add, Text, x17 y135 w90 h20 vTxtSig1Data,
Gui, Add, Text, x115 y135 w90 h20 vTxtSig2Data,
Gui, Add, Text, x247 y135 w90 h20 vTxtSig3Data,
GuiControl, +Center, TxtSig1Data
GuiControl, +Center, TxtSig2Data
GuiControl, +Center, TxtSig3Data

; initially hide/disable some controls until the signal file is loaded
GuiControl, Hide, SigDate
GuiControl, Hide, BtnPrevDayEvt
GuiControl, Hide, BtnNextDayEvt
GuiControl, Hide, ChkLinkONE

Gui, Show, w360 h180, Signal Browser
return


BtnLoadEvt:
	FileSelectFile, SelectedFile, 3, , Open a file, CSV Files (*.csv)   ; 3 = file and path must exit
	CSV_Load(SelectedFile, "data")
	TotRows := CSV_TotalRows("data")
	FirstDate := CSV_ReadCell("data", 2, 1)
	LastDate := CSV_ReadCell("data", TotRows, 1)
	FirstDate_short := StrReplace(FirstDate, "-", "")
	LastDate_short := StrReplace(LastDate, "-", "")
	GuiControl, +Range%FirstDate_short%-%LastDate_short%, SigDate
	GuiControl,, SigDate, % LastDate_short

	; update the labels
	SigRowContents := CSV_ReadRow("data", 1)
	SigElements := StrSplit(SigRowContents, ",")
	GuiControl,, LblSig1, % SigElements[2]
	GuiControl,, LblSig2, % SigElements[3]
	GuiControl,, LblSig3, % SigElements[4]

	; update the signal data
	SigRowContents := CSV_ReadRow("data", 2)
	SigElements := StrSplit(SigRowContents, ",")
	GuiControl,, TxtSig1Data, % SigElements[2]
	GuiControl,, TxtSig2Data, % SigElements[3]
	GuiControl,, TxtSig3Data, % SigElements[4]

	; re-enable the controls
	GuiControl, Show, SigDate
	GuiControl, Show, BtnPrevDayEvt
	GuiControl, Show, BtnNextDayEvt
	GuiControl, Show, ChkLinkONE

	SB_SetText("  F7: Prev day     F8: Next day     F11: Link To One")   ; status bar

	return


BtnNextDayEvt:
	if (SigRow < TotRows) {
		++SigRow
		SigRowContents := CSV_ReadRow("data", SigRow)
		SigElements := StrSplit(SigRowContents, ",")
		NewDate := StrReplace(SigElements[1], "-", "")
		GuiControl,, SigDate, % NewDate
		GuiControl,, TxtSig1Data, % SigElements[2]
		GuiControl,, TxtSig2Data, % SigElements[3]
		GuiControl,, TxtSig3Data, % SigElements[4]
	}
	return


BtnPrevDayEvt:
	if (SigRow > 2) {
		--SigRow
		SigRowContents := CSV_ReadRow("data", SigRow)
		SigElements := StrSplit(SigRowContents, ",")
		NewDate := StrReplace(SigElements[1], "-", "")
		GuiControl,, SigDate, % NewDate
		GuiControl,, TxtSig1Data, % SigElements[2]
		GuiControl,, TxtSig2Data, % SigElements[3]
		GuiControl,, TxtSig3Data, % SigElements[4]
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
	GuiControl,, TxtSig1Data, % SigElements[2]
	GuiControl,, TxtSig2Data, % SigElements[3]
	GuiControl,, TxtSig3Data, % SigElements[4]
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
