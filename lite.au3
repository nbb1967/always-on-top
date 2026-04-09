#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=ico\AlwaysOnTop.ico
#AutoIt3Wrapper_Outfile=PowerToys.AlwaysOnTop.Lite.exe
#AutoIt3Wrapper_Res_Comment=Alternative GUI for Microsoft PowerToys AlwaysOnTop
#AutoIt3Wrapper_Res_Description=PowerToys AlwaysOnTop Lite
#AutoIt3Wrapper_Res_Fileversion=1.0.0.61
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=PowerToys AlwaysOnTop Lite
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.61
#AutoIt3Wrapper_Res_CompanyName=NyBumBum
#AutoIt3Wrapper_Res_LegalCopyright=Copyright © NyBumBum 2026. All rights reserved.
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_Res_Icon_Add=ico\picker_24.ico
#AutoIt3Wrapper_Res_File_Add=loc\en.ini, 6
#AutoIt3Wrapper_Res_File_Add=loc\ru.ini, 6
#AutoIt3Wrapper_Res_File_Add=cur\picker.cur, 1, 101
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <SliderConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <WinAPI.au3>
#include <Misc.au3>
#include <GuiComboBox.au3>
#include <ScrollBarConstants.au3>
#include <GDIPlus.au3>
#include <include\JSON.au3> ; @AspirinJunkie(https : / / github.com / Sylvan86 / autoit - json - udf)
#include <TrayConstants.au3>
#include <Array.au3>
#include <GuiMenu.au3>
#include <GuiEdit.au3>

; Prevents duplicate instances by executable name.
_Singleton("PowerToys.AlwaysOnTop.Lite.exe")

; Register cleanup function on exit.
OnAutoItExitRegister("MyCleanup")

_FixAccelHotKeyLayout()
_LockingBREAKkey()

Opt("TrayOnEventMode", 1)
Opt("TrayMenuMode", 1 + 2)
Opt("GUICloseOnESC", 0)

Global $iPID = Run(@ScriptDir & '\bin\PowerToys.AlwaysOnTop.exe')

Global $hInstance = _WinAPI_GetModuleHandle(0)
If $hInstance = 0 Then
	MsgBox($MB_ICONERROR, "Error", "Failed to get program handle.")
	Exit
EndIf

#Region;============= LOCALIZATION (BASED ON FAQ BY YASHIED) ================
Global Enum $eSettingsTray, $eAboutTray, $eExitTray
Global $asTrayMenu[3] = [6000, 6001, 6002]
Global Enum $eSettingsDlg, $eActivationGroup, $eHotKeys, $eHotKeysTip, $eGameMode, $eAppearanceGroup, $eFrameShow, $eColorMode, $eWindowsDefault, $eAdditionalColor, $eColorButtonTip, $eOpacity, $eThickness, $ePixel, $eRoundedCorners, $eSoundPlay, $eExceptionApp, $eHintException, $eTipNoAdmin, $eSaveButton
Global $asSettingsDialog[20] = [6016, 6017, 6018, 6019, 6020, 6021, 6022, 6023, 6024, 6025, 6026, 6027, 6028, 6029, 6030, 6031, 6032, 6033, 6034, 6035]
Global Enum $eAboutDlg, $eVersion, $eVersionCore, $eCopyright, $eSite, $eEmail, $eLicense, $eIncludePowerToys, $eCopyrightMS
Global $asAboutDialog[9] = [6048, 6049, 6050, 6051, 6052, 6053, 6054, 6055, 6056]
Global Enum $eColorCooser, $ePickerTip
Global $asColorDialog[2] = [6064, 6065]
Global Enum $eErrorTitle, $eErrCreateJSON, $eErrNotSaved, $eErrNotCode, $eErrSingleKey, $eErrShiftOnlyKey, $eErrStdHotkey, $eErrHotkeyInUse, $eErrManyException, $eErrNullException, $eErrWriteJSON, $eErrOpenJSON
Global $asErrMsg[12] = [6080, 6081, 6082, 6083, 6084, 6085, 6086, 6087, 6088, 6089, 6090, 6092]
Global Enum $eMsgDone
Global $asMsg[1] = [6096]
Global Enum $eCut, $eCopy, $ePaste, $eDelete, $eSelect_All
Global $asMenu[5] = [6112, 6113, 6114, 6115, 6116]

_InitAllStrings()
#EndRegion;==================================================================

#include <include\ColorChooser.au3> ; @Yashied(modified), moved down because it uses $hInstance And Localization

#Region ;============================ TRAY MENU =============================
$idTrayMenu_Settings = TrayCreateItem($asTrayMenu[$eSettingsTray])          ; "Settings"
TrayItemSetOnEvent(-1, "_CreateFormSetting")
TrayItemSetState($idTrayMenu_Settings, $TRAY_DEFAULT)
$idTrayMenu_About = TrayCreateItem($asTrayMenu[$eAboutTray])                ; "About"
TrayItemSetOnEvent(-1, "_CreateFormAbout")
TrayCreateItem("")
$idTrayMenu_Exit = TrayCreateItem($asTrayMenu[$eExitTray])                  ; "Exit"
TrayItemSetOnEvent(-1, "_PowerToys_AlwaysOnTop_Cleanup")
TraySetOnEvent($TRAY_EVENT_PRIMARYDOWN, "_CreateFormSetting")
TraySetClick(8)
TraySetToolTip("PowerToys AlwaysOnTop Lite")                                ; "PowerToys AlwaysOnTop Lite"
TraySetIcon(@ScriptFullPath, 99)
#EndRegion ;========================= TRAY MENU =============================

Global Const $SPI_SETCURSORS = 0x0057

Global $iSettingsLast_X = -1, $iSettingsLast_Y = -1, $iAboutLast_X = -1, $iAboutLast_Y = -1
Global $hFormSettings = 0, $idInputHotkeys, $hInput = 0, $idCheckboxGameMode, $idCheckboxShowBorder, $idLabelColorMode, $idComboColorMode, $idPseudoBtnColorPreview, $idLabelOpacity, $idSliderOpacity, $idLabelOpacityValue, $idLabelThickness, $idSliderThickness, $idLabelThicknessValue, $idCheckboxRounded, $idCheckboxSound, $idEditExceptions, $idButtonSave
Global $hFormAbout = 0, $idLabelSite_Link, $LabelMail_Link, $idLabelLicense_Link, $idLabelLink_MS, $idLabelLicenseMS_Link

Global $iAddHeightWin_11 = 0
If @OSVersion = "WIN_11" Then
	$iAddHeightWin_11 = 30
EndIf

Global $sSettingsPath = _WinAPI_ExpandEnvironmentStrings(@LocalAppDataDir & "\Microsoft\PowerToys\AlwaysOnTop\settings.json")
Global $sDefaultSettingsJSON = '{"properties":{"hotkey":{"value":{"win":true,"ctrl":true,"alt":false,"shift":false,"code":84,"key":""}},"frame-enabled":{"value":true},"frame-thickness":{"value":15},"frame-color":{"value":"#0099cc"},"frame-opacity":{"value":100},"frame-accent-color":{"value":true},"sound-enabled":{"value":true},"do-not-activate-on-game-mode":{"value":true},"excluded-apps":{"value":""},"round-corners-enabled":{"value":true}},"name":"AlwaysOnTop","version":"0.0.1"}'

Global $bWin, $bCtrl, $bAlt, $bShift, $bFrameEnabled, $bAccent, $bRoundCorners, $bSound, $bGameMode      ; 9 bool
Global $sColor, $sExcludedApp                                                                            ; 2 string
Global $iCode, $iThickness, $iOpacity                                                                    ; 3 int

Global $oData

_JSON_Creation()
_JSON_Read_and_Validate()

Global $sHint = $asSettingsDialog[$eHintException]                                                                                  ; "Exceptions (filename or window title, one per line)..."
Global $sExcluded = StringAddCR($sExcludedApp)

; $sExcluded is loaded from JSON. If it's empty, we use the hint.
Global $sInitialText = ($sExcluded == "" ? $sHint : $sExcluded)
Global $iInitialTextColor = ($sExcluded == "" ? 0xA0A0A0 : 0x000000)

; Initial color
Global $iColor = Number(StringReplace($sColor, "#", "0x"))
Global $iCurrentColor = $iColor

Global $hKeyHook = 0
Global $hStub_KeyProc = DllCallbackRegister("_KeyProc", "long", "int;wparam;lparam")

Global $sHotKey = _GetHotkeyStr()
Global $bDone = False

Global $hInput, $hEdit, $wProcOld_Input, $wProcOld_Edit, $hContextMenu_Edit
Global $idSelectAll    ; for castom menu
Global $wProcHandle = DllCallbackRegister("_WindowProc", "ptr", "hwnd;uint;wparam;lparam")    ;for custom menu

;========================================================= DIALOG SETTINGS =======================================================
Func _CreateFormSetting()
	If IsHWnd($hFormSettings) Then Return WinActivate($hFormSettings)

	$hFormSettings = GUICreate($asSettingsDialog[$eSettingsDlg], 441, 511 + $iAddHeightWin_11, $iSettingsLast_X, $iSettingsLast_Y)     ; "Settings"
	GUISetIcon(@ScriptFullPath, 99)
	GUISetFont(9, 400, 0, "Segoe UI")
	$idGroupActivation = GUICtrlCreateGroup($asSettingsDialog[$eActivationGroup], 20, 15, 401, 96)                                     ; "Activation"
	$idLabelHotkeys = GUICtrlCreateLabel($asSettingsDialog[$eHotKeys], 40, 47, 112, 17)                                                ; "Activation shortcut:"
	$idInputHotkeys = GUICtrlCreateInput("", 155, 45, 246, 21, BitOR($ES_READONLY, 0x0100))
	GUICtrlSetTip($idInputHotkeys, $asSettingsDialog[$eHotKeysTip])                                                                    ; "Customize the shortcut to pin or unpin an app window"
	GUICtrlSetFont(-1, 10, 700, 0, "Arial")
	$hInput = GUICtrlGetHandle($idInputHotkeys) ; for detect focus in Input and "no menu":
	;----------------------------Custom no menu----------------------------------------------------
	$wProcOld_Input = _WinAPI_SetWindowLong($hInput, $GWL_WNDPROC, DllCallbackGetPtr($wProcHandle))

	If $iCode Then GUICtrlSetData($idInputHotkeys, $sHotKey)
	$idCheckboxGameMode = GUICtrlCreateCheckbox($asSettingsDialog[$eGameMode], 40, 75, 361, 21)                                        ; "Do not activate when Game Mode is on"
	If $bGameMode Then
		GUICtrlSetState(-1, $GUI_CHECKED)
	EndIf

	GUICtrlCreateGroup("", -99, -99, 1, 1)
	;------------------------------------
	$idGroupAppearance = GUICtrlCreateGroup($asSettingsDialog[$eAppearanceGroup], 20, 125, 401, 181 + $iAddHeightWin_11)               ; "Appearance & behavior"
	$idCheckboxShowBorder = GUICtrlCreateCheckbox($asSettingsDialog[$eFrameShow], 40, 150, 360, 21)                                    ; "Show a border around the pinned window"
	If $bFrameEnabled Then
		GUICtrlSetState(-1, $GUI_CHECKED)
	EndIf

	$idLabelColorMode = GUICtrlCreateLabel($asSettingsDialog[$eColorMode], 40, 180, 109, 17)                                           ; "Color mode:"
	$idComboColorMode = GUICtrlCreateCombo("", 155, 178, 193, 100, $CBS_DROPDOWNLIST)
	GUICtrlSetData(-1, $asSettingsDialog[$eWindowsDefault] & "|" & $asSettingsDialog[$eAdditionalColor])                               ; "Windows default", "Custom color"
	_GUICtrlComboBox_SetCurSel($idComboColorMode, ($bAccent ? 0 : 1))

	$idPseudoBtnColorPreview = GUICtrlCreateLabel("", 360, 178, 41, 23, BitOR($SS_NOTIFY, $SS_SUNKEN))
	GUICtrlSetBkColor($idPseudoBtnColorPreview, $iCurrentColor)
	GUICtrlSetCursor($idPseudoBtnColorPreview, 0) ; hand-cursor on hover
	GUICtrlSetTip($idPseudoBtnColorPreview, $asSettingsDialog[$eColorButtonTip])                                                       ; "Click to change the color" (hint)
	$idLabelOpacity = GUICtrlCreateLabel($asSettingsDialog[$eOpacity], 40, 210, 109, 17)                                               ; "Opacity:"
	$idSliderOpacity = GUICtrlCreateSlider(155, 210, 193, 21)
	GUICtrlSetLimit(-1, 100, 0)
	GUICtrlSetData(-1, $iOpacity)
	Global $hSliderOpacity_Handle = GUICtrlGetHandle(-1)
	$idLabelOpacityValue = GUICtrlCreateLabel("", 360, 210, 40, 17, $SS_CENTER)
	GUICtrlSetData(-1, $iOpacity & ' %')
	$idLabelThickness = GUICtrlCreateLabel($asSettingsDialog[$eThickness], 40, 240, 109, 17)                                           ; "Thickness:"
	$idSliderThickness = GUICtrlCreateSlider(155, 240, 193, 21)
	GUICtrlSetLimit(-1, 30, 1)
	GUICtrlSetData(-1, $iThickness)
	Global $hSliderThickness_Handle = GUICtrlGetHandle(-1)
	$idLabelThicknessValue = GUICtrlCreateLabel("", 360, 240, 40, 17, $SS_CENTER)
	GUICtrlSetData(-1, $iThickness & ' ' & $asSettingsDialog[$ePixel])                                                                 ; "px"
	$idCheckboxRounded = GUICtrlCreateCheckbox($asSettingsDialog[$eRoundedCorners], 40, 270, 361, 21)                                  ; "Enable rounded corners"
	If $bRoundCorners Then
		GUICtrlSetState(-1, $GUI_CHECKED)
	EndIf
	If @OSVersion <> "WIN_11" Then GUICtrlSetState($idCheckboxRounded, $GUI_HIDE)

	_ToggleUI()
	;----------
	$idCheckboxSound = GUICtrlCreateCheckbox($asSettingsDialog[$eSoundPlay], 40, 270 + $iAddHeightWin_11, 361, 21)                     ; "Play a sound when pinning a window"
	If $bSound Then
		GUICtrlSetState(-1, $GUI_CHECKED)
	EndIf

	GUICtrlCreateGroup("", -99, -99, 1, 1)
	;-------------------------------------
	$idGroupExceptions = GUICtrlCreateGroup($asSettingsDialog[$eExceptionApp], 20, 320 + $iAddHeightWin_11, 401, 126)                  ; "Excluded apps"
	$idEditExceptions = GUICtrlCreateEdit($sInitialText, 40, 350 + $iAddHeightWin_11, 361, 71, BitOR($ES_AUTOVSCROLL, $ES_WANTRETURN, $WS_VSCROLL))
	GUICtrlSetColor(-1, $iInitialTextColor)
	;--------------------------Custom Context Menu For Edit----------------------
	$hContextMenu_Edit = _GUICtrlMenu_CreatePopup()
	If $hContextMenu_Edit <> 0 Then
		_GUICtrlMenu_AddMenuItem($hContextMenu_Edit, $asMenu[$eCut], $WM_CUT)                        ; "Cut"
		_GUICtrlMenu_AddMenuItem($hContextMenu_Edit, $asMenu[$eCopy], $WM_COPY)                      ; "Copy"
		_GUICtrlMenu_AddMenuItem($hContextMenu_Edit, $asMenu[$ePaste], $WM_PASTE)                    ; "Paste"
		_GUICtrlMenu_AddMenuItem($hContextMenu_Edit, $asMenu[$eDelete], $WM_CLEAR)                   ; "Delete"
		_GUICtrlMenu_AddMenuItem($hContextMenu_Edit, "")
		_GUICtrlMenu_AddMenuItem($hContextMenu_Edit, $asMenu[$eSelect_All], $idSelectAll)            ; "Select All"

		$hEdit = GUICtrlGetHandle($idEditExceptions)
		$wProcOld_Edit = _WinAPI_SetWindowLong($hEdit, $GWL_WNDPROC, DllCallbackGetPtr($wProcHandle))
	EndIf

	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$idLabelNoAdmin = GUICtrlCreateLabel($asSettingsDialog[$eTipNoAdmin], 20, 461 + $iAddHeightWin_11, 300, 35)                        ; "Administrator privileges are required to pin windows running as administrator."
	GUICtrlSetState(-1, $GUI_DISABLE)
	If IsAdmin() Then GUICtrlSetState($idLabelNoAdmin, $GUI_HIDE)
	$idButtonSave = GUICtrlCreateButton($asSettingsDialog[$eSaveButton], 341, 465 + $iAddHeightWin_11, 81, 25, $BS_DEFPUSHBUTTON)      ; "Save"
	GUICtrlSetState($idButtonSave, $GUI_DISABLE)
	GUISetState(@SW_SHOW, $hFormSettings)
EndFunc   ;==>_CreateFormSetting
;-----------------------------------------------------------------------------------------------------------------------------------
; Get version of the compiled file
Global $sMyVersion = FileGetVersion(@ScriptFullPath)

; Get version of the PowerToys AlwaysOnTop
Global $sCorePath = @ScriptDir & "\bin\PowerToys.AlwaysOnTop.exe"
Global $sCoreVersion = FileGetVersion($sCorePath)
;=========================================================== DIALOG ABOUT ==========================================================
Func _CreateFormAbout()
	If IsHWnd($hFormAbout) Then Return WinActivate($hFormAbout)

	$hFormAbout = GUICreate($asAboutDialog[$eAboutDlg], 451, 391, $iAboutLast_X, $iAboutLast_Y, $WS_SYSMENU)                           ; "About"
	GUISetIcon(@ScriptFullPath, 99)
	GUISetFont(9, 400, 0, "Segoe UI")
	$Icon1 = GUICtrlCreateIcon(@ScriptFullPath, 99, 20, 12, 64, 64)
	$idLabelAppNAme = GUICtrlCreateLabel("PowerToys AlwaysOnTop Lite", 100, 10, 172, 67)
	GUICtrlSetFont(-1, 14, 800, 0, "Verdana")
	$idLabelVersion = GUICtrlCreateLabel($asAboutDialog[$eVersion] & " " & $sMyVersion, 265, 40, 160, 17, $SS_RIGHT)                   ; "Version:"
	$idLabelVersionCore = GUICtrlCreateLabel($asAboutDialog[$eVersionCore] & " " & $sCoreVersion, 215, 60, 210, 17, $SS_RIGHT)         ; "Engine Version:"
	$idLabelHR1 = GUICtrlCreateLabel("", 0, 90, 446, 2, $SS_SUNKEN)
	$GroupNBB = GUICtrlCreateGroup("", 20, 105, 406, 111)
	$idLabelCopyright = GUICtrlCreateLabel($asAboutDialog[$eCopyright], 40, 125, 365, 17)                                              ; "Copyright © NyBumBum 2026. All rights reserved."
	$idLabelSite = GUICtrlCreateLabel($asAboutDialog[$eSite], 40, 145, 34, 17)                                                         ; "Website:"
	$idLabelSite_Link = GUICtrlCreateLabel("github.com/nbb1967/always-on-top", 110, 145, 295, 17)
	GUICtrlSetColor(-1, 0x00A2E8)
	GUICtrlSetCursor(-1, 0)
	$idLabelMail = GUICtrlCreateLabel($asAboutDialog[$eEmail], 40, 165, 37, 17)                                                        ; "Email:"
	$LabelMail_Link = GUICtrlCreateLabel("nybumbum@gmail.com", 110, 165, 295, 17)
	GUICtrlSetColor(-1, 0x00A2E8)
	GUICtrlSetCursor(-1, 0)
	$idLabelLicense = GUICtrlCreateLabel($asAboutDialog[$eLicense], 40, 185, 60, 17)                                                   ; "License:"
	$idLabelLicense_Link = GUICtrlCreateLabel("MIT", 110, 185, 295, 17)
	GUICtrlSetColor(-1, 0x00A2E8)
	GUICtrlSetCursor(-1, 0)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$GroupMS = GUICtrlCreateGroup("", 20, 230, 406, 111)
	$idLabelInclude = GUICtrlCreateLabel($asAboutDialog[$eIncludePowerToys], 40, 250, 365, 17)                                         ; "Includes a component: PowerToys.AlwaysOnTop"
	$idLabelCopyrightMS = GUICtrlCreateLabel($asAboutDialog[$eCopyrightMS], 40, 270, 385, 17)                                          ; "Copyright © Microsoft Corporation. All rights reserved."
	$idLabelSitePowerToys = GUICtrlCreateLabel($asAboutDialog[$eSite], 40, 290, 34, 17)                                                ; "Website:"
	$idLabelLink_MS = GUICtrlCreateLabel("github.com/microsoft/PowerToys", 110, 290, 295, 17)
	GUICtrlSetColor(-1, 0x00A2E8)
	GUICtrlSetCursor(-1, 0)
	$idLabelLicenseMS = GUICtrlCreateLabel($asAboutDialog[$eLicense], 40, 310, 57, 17)                                                 ; "License:"
	$idLabelLicenseMS_Link = GUICtrlCreateLabel("MIT", 110, 310, 295, 17)
	GUICtrlSetColor(-1, 0x00A2E8)
	GUICtrlSetCursor(-1, 0)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	GUISetState(@SW_SHOW, $hFormAbout)
EndFunc   ;==>_CreateFormAbout

; Registering the interception of notifications from Sliders
GUIRegisterMsg($WM_HSCROLL, "WM_HSCROLL")
; Registering the interception of notifications from Edit, Input and ColorChooser
GUIRegisterMsg($WM_COMMAND, "_WM_COMMAND")
; Registering the interception of window movement notifications
GUIRegisterMsg($WM_MOVE, "WM_MOVE")
;--------------------------------------------------------------

Local $iState, $aPos

While 1

	$aMsg = GUIGetMsg(1)
	If $aMsg[0] <> 0 Then
		Switch $aMsg[0]
			Case $GUI_EVENT_CLOSE
				If IsHWnd($hFormSettings) And $aMsg[1] = $hFormSettings Then
					_Unhook()
					If $bDone Then _ResetSaveButtonText()

					; If the window is NOT minimized, save the coordinates
					$iState = WinGetState($hFormSettings)
					If Not BitAND($iState, $WIN_STATE_MINIMIZED) Then
						$aPos = WinGetPos($hFormSettings)
						If Not @error Then
							$iSettingsLast_X = $aPos[0]
							$iSettingsLast_Y = $aPos[1]
						EndIf
					EndIf

					_WinAPI_SetWindowLong(GUICtrlGetHandle($idEditExceptions), $GWL_WNDPROC, $wProcOld_Edit)
					_WinAPI_SetWindowLong(GUICtrlGetHandle($idInputHotkeys), $GWL_WNDPROC, $wProcOld_Input)
					_GUICtrlMenu_DestroyMenu($hContextMenu_Edit)

					GUIDelete($hFormSettings)
					$hFormSettings = 0
				EndIf
				;--------------------------------
				If IsHWnd($hFormAbout) And $aMsg[1] = $hFormAbout Then

					; If the window is NOT minimized, save the coordinates
					$iState = WinGetState($hFormAbout)
					If Not BitAND($iState, $WIN_STATE_MINIMIZED) Then
						$aPos = WinGetPos($hFormAbout)
						If Not @error Then
							$iAboutLast_X = $aPos[0]
							$iAboutLast_Y = $aPos[1]
						EndIf
					EndIf

					GUIDelete($hFormAbout)
					$hFormAbout = 0
				EndIf
			Case $idButtonSave
				If IsHWnd($hFormSettings) And $aMsg[1] = $hFormSettings Then _SaveSettings()
			Case $idPseudoBtnColorPreview
				If IsHWnd($hFormSettings) And $aMsg[1] = $hFormSettings Then
					Local $iChosenColor = _ColorChooserDialog($iCurrentColor, $hFormSettings, 0, 0, $CC_FLAG_DEFAULT)
					If $iChosenColor <> -1 Then
						$iCurrentColor = $iChosenColor
						GUICtrlSetBkColor($idPseudoBtnColorPreview, $iCurrentColor)
						_SmartCheck() ; Let's check if it has changed.
					EndIf
				EndIf
			Case $idCheckboxShowBorder, $idComboColorMode
				If IsHWnd($hFormSettings) And $aMsg[1] = $hFormSettings Then
					_SmartCheck()
					_ToggleUI()
				EndIf
			Case $idCheckboxSound, $idCheckboxGameMode, $idCheckboxRounded
				If IsHWnd($hFormSettings) And $aMsg[1] = $hFormSettings Then _SmartCheck()
			Case $idLabelSite_Link
				If IsHWnd($hFormAbout) And $aMsg[1] = $hFormAbout Then ShellExecute("https://github.com/nbb1967/always-on-top")
			Case $LabelMail_Link
				If IsHWnd($hFormAbout) And $aMsg[1] = $hFormAbout Then ShellExecute("mailto:nybumbum@gmail.com?subject=PowerToys%20AlwaysOnTop%20Lite")
			Case $idLabelLicense_Link
				If IsHWnd($hFormAbout) And $aMsg[1] = $hFormAbout Then ShellExecute(@ScriptDir & "\LICENSE.txt")
			Case $idLabelLink_MS
				If IsHWnd($hFormAbout) And $aMsg[1] = $hFormAbout Then ShellExecute("https://github.com/microsoft/PowerToys")
			Case $idLabelLicenseMS_Link
				If IsHWnd($hFormAbout) And $aMsg[1] = $hFormAbout Then ShellExecute(@ScriptDir & "\bin\LICENSE.txt")
		EndSwitch
	EndIf

	; DYNAMIC HOOK: Enable ONLY when the cursor is inside the input field.
	; This allows you to test hotkeys without closing the window.
	If $hFormSettings And IsHWnd($hFormSettings) Then
		If _WinAPI_GetFocus() = $hInput Then
			If Not $hKeyHook Then
				$hKeyHook = _WinAPI_SetWindowsHookEx($WH_KEYBOARD_LL, DllCallbackGetPtr($hStub_KeyProc), $hInstance)
			EndIf
		Else
			_Unhook() ; As soon as focus is lost, return the keyboard to the system.
		EndIf
	EndIf

	Sleep(10)
WEnd

;=============================================================================
; System command processing function
Func _WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
	; 1. We check the first element of the array: if it contains a window handle (not 0), we listen to ColorChooser
	If $ccData[0] <> 0 Then
		; We pass control to the library so that it checks the HEX field
		CC_WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
	EndIf

	; We check whether the window still exists and whether there is a signal from it
	If Not IsHWnd($hFormSettings) Or $hWnd <> $hFormSettings Then Return $GUI_RUNDEFMSG

	Local $nNotifyCode = BitShift($wParam, 16) ; Get the notification code
	Local $nID = BitAND($wParam, 0xFFFF)       ; Get the control ID

	; 1. Logic for EXCEPTION FIELD
	If $nID = $idEditExceptions Then
		Switch $nNotifyCode
			Case $EN_CHANGE ; Press the key - we check it immediately
				_SmartCheck()
			Case $EN_SETFOCUS ; Click in the field or Tab key
				If GUICtrlRead($idEditExceptions) == $sHint Then
					GUICtrlSetData($idEditExceptions, "")
					GUICtrlSetColor($idEditExceptions, 0x000000)
				EndIf

			Case $EN_KILLFOCUS ; Click outside the field
				If GUICtrlRead($idEditExceptions) == "" Then
					GUICtrlSetData($idEditExceptions, $sHint)
					GUICtrlSetColor($idEditExceptions, 0xA0A0A0)
				EndIf
		EndSwitch
	EndIf

	; 2. Logic for HOT KEYS
	If $nID = $idInputHotkeys Then
		Switch $nNotifyCode
			Case $EN_CHANGE ; Press the key - we check it immediately
				_SmartCheck()
		EndSwitch
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc   ;==>_WM_COMMAND

Func WM_HSCROLL($hWnd, $Msg, $wParam, $lParam)
	#forceref $Msg, $wParam, $lParam

	; We check whether the window still exists and whether there is a signal from it
	If Not IsHWnd($hFormSettings) Or $hWnd <> $hFormSettings Then Return $GUI_RUNDEFMSG

	; We're checking whether the message came from transparency
	If $lParam = $hSliderOpacity_Handle Then
		GUICtrlSetData($idLabelOpacityValue, GUICtrlRead($idSliderOpacity) & ' %')
		_SmartCheck()

		; Or from thickness
	ElseIf $lParam = $hSliderThickness_Handle Then
		GUICtrlSetData($idLabelThicknessValue, GUICtrlRead($idSliderThickness) & ' ' & $asSettingsDialog[$ePixel])                 ; "px"
		_SmartCheck()
	EndIf

	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_HSCROLL

Func WM_MOVE($hWnd, $iMsg, $wParam, $lParam)
	If $hWnd = $hFormSettings Then
		Local $iState = WinGetState($hFormSettings)
		; We save coordinates ONLY if the window is not minimized
		If Not BitAND($iState, $WIN_STATE_MINIMIZED) Then
			Local $aPos = WinGetPos($hFormSettings)
			If Not @error Then
				$iSettingsLast_X = $aPos[0]
				$iSettingsLast_Y = $aPos[1]
			EndIf
		EndIf
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_MOVE

Func _WindowProc($hWnd, $Msg, $wParam, $lParam)
	Local $aRet
	Switch $hWnd
		Case $hInput
			Switch $Msg
				Case $WM_CONTEXTMENU
					; We simply return 1. The menu is not created, so TrackPopupMenu is not called.
					; Windows assumes the message has been processed and does not display the standard menu.
					Return 1
			EndSwitch
			$aRet = DllCall("user32.dll", "int", "CallWindowProc", "ptr", $wProcOld_Input, "hwnd", $hWnd, "uint", $Msg, "wparam", $wParam, "lparam", $lParam)
			Return $aRet[0]

		Case $hEdit
			Switch $Msg
				Case $WM_CONTEXTMENU
					_WinAPI_SetFocus($hWnd)
					_ActivityContextMenuItem_Edit() ; Function for checking the status of menu items
					; $wParam in WM_CONTEXTMENU — this is the HWND of the control
					_GUICtrlMenu_TrackPopupMenu($hContextMenu_Edit, $hWnd)
					Return 1
				Case $WM_COMMAND
					Local $nID = BitAND($wParam, 0xFFFF) ; Extract the command ID from the message
					Switch $nID
						Case $WM_CUT, $WM_COPY, $WM_PASTE, $WM_CLEAR
							_SendMessage($hWnd, $nID)
						Case $idSelectAll
							_SendMessage($hWnd, $EM_SETSEL, 0, -1)
					EndSwitch
			EndSwitch
			$aRet = DllCall("user32.dll", "int", "CallWindowProc", "ptr", $wProcOld_Edit, "hwnd", $hWnd, "uint", $Msg, "wparam", $wParam, "lparam", $lParam)
			Return $aRet[0]
	EndSwitch
EndFunc   ;==>_WindowProc

Func _JSON_Creation()
	; 1. GUARANTEED FILE CREATION
	If Not FileExists($sSettingsPath) Then
		Local $hFile = FileOpen($sSettingsPath, 2 + 8 + 256) ; 2 = write to end, 8 = create folders, 256 = UTF8 without BOM
		If $hFile <> -1 Then
			FileWrite($hFile, $sDefaultSettingsJSON)
			FileClose($hFile)
			FileSetTime($sSettingsPath, "", 0)
		Else
			MsgBox($MB_ICONERROR, $asErrMsg[$eErrorTitle], $asErrMsg[$eErrCreateJSON])             ; "Error", "Unable to create the settings file or folder structure."
			Exit
		EndIf
	EndIf
EndFunc   ;==>_JSON_Creation

Func _JSON_Read_and_Validate()
	; READING AND PARSE
	Local $hFile = FileOpen($sSettingsPath, 256)
	Local $sJson = FileRead($hFile)
	$oData = _JSON_Parse($sJson)
	Local $bChanged = False

	; If the output is String or Int32 (error), and not Map, the JSON is broken.
	If @error Or VarGetType($oData) <> "Map" Then
		$oData = _JSON_Parse($sDefaultSettingsJSON)
		$bChanged = True
	EndIf

	FileClose($hFile)

	; VALIDATION
	; 9 BOOL
	$bWin          = _GetValid($oData, "properties.hotkey.value.win",                   True, "bool", $bChanged)
	$bCtrl         = _GetValid($oData, "properties.hotkey.value.ctrl",                  True, "bool", $bChanged)
	$bAlt          = _GetValid($oData, "properties.hotkey.value.alt",                  False, "bool", $bChanged)
	$bShift        = _GetValid($oData, "properties.hotkey.value.shift",                False, "bool", $bChanged)
	$bFrameEnabled = _GetValid($oData, "properties.frame-enabled.value",                True, "bool", $bChanged)
	$bAccent       = _GetValid($oData, "properties.frame-accent-color.value",           True, "bool", $bChanged)
	$bRoundCorners = _GetValid($oData, "properties.round-corners-enabled.value",        True, "bool", $bChanged)
	$bSound        = _GetValid($oData, "properties.sound-enabled.value",                True, "bool", $bChanged)
	$bGameMode     = _GetValid($oData, "properties.do-not-activate-on-game-mode.value", True, "bool", $bChanged)

	; 2 STRING
	$sColor        = _GetValid($oData, "properties.frame-color.value",  "#0099cc", "str", $bChanged, "_CheckColorHex")
	$sExcludedApp  = _GetValid($oData, "properties.excluded-apps.value",       "", "str", $bChanged, "_Check_Exclusion")

	; 3 INT (with verification)
	$iCode         = _GetValid($oData, "properties.hotkey.value.code",     84, "int", $bChanged, "_CheckVKey")
	$iThickness    = _GetValid($oData, "properties.frame-thickness.value", 15, "int", $bChanged, "_Check_1_30")
	$iOpacity      = _GetValid($oData, "properties.frame-opacity.value",  100, "int", $bChanged, "_Check_0_100")

	; SMART UPDATE
	If $bChanged Then
		$hFile = FileOpen($sSettingsPath, 2 + 8 + 256)
		FileWrite($hFile, _JSON_GenerateCompact($oData))
		FileClose($hFile)
		FileSetTime($sSettingsPath, "", 0)
	EndIf
EndFunc   ;==>_JSON_Read_and_Validate

; UNIVERSAL CHECK FUNCTION WITH LOGGING
Func _GetValid(ByRef $oObj, $sKey, $vDef, $sType, ByRef $bFlag, $sFunc = "")
	Local $vVal = _JSON_Get($oObj, $sKey)
	Local $bErr = @error

	; 1. Basic type checking
	If Not $bErr Then
		Switch $sType
			Case "bool"
				If Not IsBool($vVal) Then $bErr = True
			Case "int"
				If Not IsInt($vVal) Then $bErr = True
			Case "str"
				If Not IsString($vVal) Then $bErr = True
		EndSwitch
	EndIf

	; 2. Additional checking with a special function
	If Not $bErr And $sFunc <> "" Then
		If Not Call($sFunc, $vVal) Then $bErr = True
	EndIf

	; 3. If there is an error, then mark the file for overwriting
	If $bErr Then
		_JSON_AddChangeDelete($oObj, $sKey, $vDef)
		$bFlag = True
		Return $vDef
	EndIf

	Return $vVal
EndFunc   ;==>_GetValid

; ---------------------- CHECKS ----------------------------------
Func _Check_1_30($v)
	Return ($v >= 1 And $v <= 30)
EndFunc   ;==>_Check_1_30

Func _Check_0_100($v)
	Return ($v >= 0 And $v <= 100)
EndFunc   ;==>_Check_0_100

Func _CheckColorHex($v)
	; ^# - starts with a hash
	; [0-9a-fA-F]{6} - exactly 6 characters (digits or Latin letters A-F)
	; $ - end of line (ensures the length is exactly 7, including the #)
	Return StringRegExp($v, '^#[0-9a-fA-F]{6}$')
EndFunc   ;==>_CheckColorHex

Func _CheckVKey($v)
	Switch $v
		Case 8, 9, 13, 27, 32       ; BS, Tab, Enter, Esc, Space
			Return True
		Case 33 To 40, 45, 46       ; PgUp/Down, Home, End, Arrows, Ins, Del
			Return True
		Case 48 To 57               ; 0-9
			Return True
		Case 65 To 90               ; A-Z (letters)
			Return True
		Case 96 To 111              ; Numpad 0-9, *, +, -, ., /
			Return True
		Case 112 To 123             ; F1 - F12
			Return True
		Case 186 To 192, 219 To 222 ; Punctuation (; = , - . / ` [ \ ] ')
			Return True
		Case Else
			Return False
	EndSwitch
EndFunc   ;==>_CheckVKey

Func _Check_Exclusion($v)
	Return (StringLen($v) < 8192 And Not StringInStr($v, Chr(0)))
EndFunc   ;==>_Check_Exclusion
;-------------------------------------------------------------------

Func _ToggleUI()
	; 1. Determine the baseline condition of the entire group
	Local $iState = (GUICtrlRead($idCheckboxShowBorder) = $GUI_CHECKED) ? $GUI_ENABLE : $GUI_DISABLE

	; 2. A simple listing: except...
	GUICtrlSetState($idLabelColorMode, $iState)
	GUICtrlSetState($idComboColorMode, $iState)
	GUICtrlSetState($idLabelOpacity, $iState)
	GUICtrlSetState($idSliderOpacity, $iState)
	GUICtrlSetState($idLabelOpacityValue, $iState)
	GUICtrlSetState($idLabelThickness, $iState)
	GUICtrlSetState($idSliderThickness, $iState)
	GUICtrlSetState($idLabelThicknessValue, $iState)
	GUICtrlSetState($idCheckboxRounded, $iState)

	; 3. Exception
	Local $iIndex = _GUICtrlComboBox_GetCurSel($idComboColorMode)

	If $iIndex = 0 Then
		GUICtrlSetState($idPseudoBtnColorPreview, $GUI_HIDE)
	Else
		GUICtrlSetState($idPseudoBtnColorPreview, $GUI_SHOW)
		Local $bActive = (GUICtrlRead($idCheckboxShowBorder) = $GUI_CHECKED)

		If $bActive Then
			GUICtrlSetState($idPseudoBtnColorPreview, $GUI_ENABLE)
			GUICtrlSetBkColor($idPseudoBtnColorPreview, $iCurrentColor) ; Bring back the rich color
			GUICtrlSetCursor($idPseudoBtnColorPreview, 0) ; Bring back the hand cursor
		Else
			GUICtrlSetState($idPseudoBtnColorPreview, $GUI_DISABLE)
			Local $iGrayColor = _GetDisabledColor()

			GUICtrlSetBkColor($idPseudoBtnColorPreview, $iGrayColor)
			GUICtrlSetCursor($idPseudoBtnColorPreview, -1) ; The regular arrow
		EndIf
	EndIf
EndFunc   ;==>_ToggleUI

Func _GetDisabledColor()
	; 1. Get the current system window background color
	Local $iSysBk = _WinAPI_GetSysColor($COLOR_3DFACE)

	; Parse the system background into RGB values
	Local $iSysR = BitAND(BitShift($iSysBk, 16), 0xFF)
	Local $iSysG = BitAND(BitShift($iSysBk, 8), 0xFF)
	Local $iSysB = BitAND($iSysBk, 0xFF)

	; 2. Calculate the brightness (gray tone) of our current Label color
	Local $iR = BitAND(BitShift($iCurrentColor, 16), 0xFF)
	Local $iG = BitAND(BitShift($iCurrentColor, 8), 0xFF)
	Local $iB = BitAND($iCurrentColor, 0xFF)
	Local $iLuma = Int($iR * 0.299 + $iG * 0.587 + $iB * 0.114)

	; 3. MIX: take the average between the color's brightness and the system background
	; This ensures that the Label will be grayish, but will NOT blend with the window background
	Local $iResR = Int(($iLuma + $iSysR) / 2)
	Local $iResG = Int(($iLuma + $iSysG) / 2)
	Local $iResB = Int(($iLuma + $iSysB) / 2)

	; Assemble the final color
	Return BitOR(BitShift($iResR, -16), BitShift($iResG, -8), $iResB)
EndFunc   ;==>_GetDisabledColor

Func _GetCleanText($id)
	Local $t = GUICtrlRead($id)
	Return ($t == $sHint ? "" : $t)
EndFunc   ;==>_GetCleanText

Func _SmartCheck()
	Local $bChanged = False

	; Checking the exception text
	If _GetCleanText($idEditExceptions) <> $sExcluded Then $bChanged = True

	; Checking the color
	If $iCurrentColor <> $iColor Then $bChanged = True

	; Checking the hotkey
	If GUICtrlRead($idInputHotkeys) <> $sHotKey Then $bChanged = True

	; We check each checkbox one by one
	If _IsChecked($idCheckboxShowBorder) <> $bFrameEnabled Then $bChanged = True
	If _IsChecked($idCheckboxSound) <> $bSound Then $bChanged = True
	If _IsChecked($idCheckboxGameMode) <> $bGameMode Then $bChanged = True
	If _IsChecked($idCheckboxRounded) <> $bRoundCorners Then $bChanged = True

	If GUICtrlRead($idSliderOpacity) <> $iOpacity Then $bChanged = True
	If GUICtrlRead($idSliderThickness) <> $iThickness Then $bChanged = True

	; Check in drop-down list (by index)
	; Get the current index (0 or 1)
	Local $iCurrentIndex = _GUICtrlComboBox_GetCurSel($idComboColorMode)

	; We turn the index into logic: if the index is 0, then "True" is selected.
	Local $bCurrentAccent = ($iCurrentIndex = 0)

	; Let's check if it has changed or not.
	If $bCurrentAccent <> $bAccent Then $bChanged = True

	; BUTTON STATE CONTROL
	If $bChanged Then
		; Turn the button on ONLY if it is currently off
		If BitAND(GUICtrlGetState($idButtonSave), $GUI_DISABLE) Then
			GUICtrlSetState($idButtonSave, $GUI_ENABLE)
		EndIf
	Else
		; Turn the button off ONLY if it is currently on
		If BitAND(GUICtrlGetState($idButtonSave), $GUI_ENABLE) Then
			GUICtrlSetState($idButtonSave, $GUI_DISABLE)
		EndIf
	EndIf

EndFunc   ;==>_SmartCheck

Func _SaveSettings()
	Local $bHotkeyNeedSave = False
	Local $sNewHotKey = GUICtrlRead($idInputHotkeys)
	If $sNewHotKey <> $sHotKey Then
		If $iCode = 0 Then
			MsgBox($MB_ICONERROR, $asErrMsg[$eErrorTitle], $asErrMsg[$eErrNotSaved] & @CRLF & $asErrMsg[$eErrNotCode])            ; "Error", "The settings were not saved.", "Please specify a main key for the shortcut."
			ControlFocus($hFormSettings, "", $idInputHotkeys)
			Return
		EndIf

		; 1. PROTECTION FROM THE "FOOL"
		; Check for single keys (space, letters without any padding, etc.)
		If Not ($bWin Or $bCtrl Or $bAlt Or $bShift) Then
			MsgBox($MB_ICONERROR, $asErrMsg[$eErrorTitle], $asErrMsg[$eErrNotSaved] & @CRLF & $asErrMsg[$eErrSingleKey])          ; "Error", "The settings were not saved.", "Single-key shortcuts are not allowed."
			ControlFocus($hFormSettings, "", $idInputHotkeys)
			Return
		EndIf

		; Check for Shift-only keys (uppercase letters)
		If $bShift And Not ($bWin Or $bCtrl Or $bAlt) Then
			; Block Shift + (Numbers/Letters 0x30-0x5A) or (OEM punctuation 0xBA-0xC0, 0xDB-0xDE)
			If ($iCode >= 0x30 And $iCode <= 0x5A) Or _
			   ($iCode >= 0xBA And $iCode <= 0xC0) Or _
			   ($iCode >= 0xDB And $iCode <= 0xDE) Then

				MsgBox($MB_ICONERROR, $asErrMsg[$eErrorTitle], $asErrMsg[$eErrNotSaved] & @CRLF & $asErrMsg[$eErrShiftOnlyKey])   ; "Error", "The settings were not saved.", "Shortcuts with the SHIFT key only are reserved for text input."
				ControlFocus($hFormSettings, "", $idInputHotkeys)
				Return
			EndIf
		EndIf

		; Protect standard keyboard shortcuts
		If ($bCtrl And Not ($bWin Or $bAlt Or $bShift) And ($iCode = 0x43 Or $iCode = 0x56 Or $iCode = 0x58 Or $iCode = 0x41)) Then  ; Only Ctrl+C,V,X,A
			MsgBox($MB_ICONERROR, $asErrMsg[$eErrorTitle], $asErrMsg[$eErrNotSaved] & @CRLF & $asErrMsg[$eErrStdHotkey])          ; "Error", "The settings were not saved.", "This shortcut is reserved by the system or a program!"
			ControlFocus($hFormSettings, "", $idInputHotkeys)
			Return
		EndIf

		; Temporarily release Break shortcuts
		_ReleaseBREAKkey()

		; 2. TECHNICAL FILTER (Check for system availability)
		Local $iMod = ($bAlt ? 1 : 0) + ($bCtrl ? 2 : 0) + ($bShift ? 4 : 0) + ($bWin ? 8 : 0)
		Local $aRet = DllCall("user32.dll", "bool", "RegisterHotKey", "hwnd", $hFormSettings, "int", 999, "uint", $iMod, "uint", $iCode)

		; CHECK: If the function call failed OR the function returned 0 (False) in the zero element of the array
		If @error Or Not $aRet[0] Then
			MsgBox($MB_ICONERROR, $asErrMsg[$eErrorTitle], $asErrMsg[$eErrNotSaved] & @CRLF & $asErrMsg[$eErrHotkeyInUse])        ; "Error", "The settings were not saved.", "This shortcut is already in use by another application or the system."
			ControlFocus($hFormSettings, "", $idInputHotkeys)
			_LockingBREAKkey()
			Return
		EndIf

		; If the registration is successful, we immediately release the temporary reservation.
		Local $aUnreg = DllCall("user32.dll", "bool", "UnregisterHotKey", "hwnd", $hFormSettings, "int", 999)

		_LockingBREAKkey()
		$bHotkeyNeedSave = True ; Scheduled write
	EndIf
	;---------------
	Local $bExceptionsNeedSave = False
	Local $sNewExcluded = _GetCleanText($idEditExceptions)
	If $sNewExcluded <> $sExcluded Then
		If StringLen($sNewExcluded) > 8192 Then
			MsgBox($MB_ICONERROR, $asErrMsg[$eErrorTitle], $asErrMsg[$eErrNotSaved] & @CRLF & $asErrMsg[$eErrManyException])      ; "Error", "The settings were not saved.", "The number of exceptions exceeds the limit."
			ControlFocus($hFormSettings, "", $idEditExceptions)
			Return
		EndIf
		If StringInStr($sNewExcluded, Chr(0)) Then
			MsgBox($MB_ICONERROR, $asErrMsg[$eErrorTitle], $asErrMsg[$eErrNotSaved] & @CRLF & $asErrMsg[$eErrNullException])      ; "Error", "The settings were not saved.", "The exception list contains an invalid character: NULL."
			ControlFocus($hFormSettings, "", $idEditExceptions)
			Return
		EndIf
		$bExceptionsNeedSave = True    ; Scheduled write
	EndIf
	;----------------
	If $bHotkeyNeedSave Then
		_JSON_addChangeDelete($oData, "properties.hotkey.value.win", $bWin)
		_JSON_addChangeDelete($oData, "properties.hotkey.value.ctrl", $bCtrl)
		_JSON_addChangeDelete($oData, "properties.hotkey.value.alt", $bAlt)
		_JSON_addChangeDelete($oData, "properties.hotkey.value.shift", $bShift)
		_JSON_addChangeDelete($oData, "properties.hotkey.value.code", $iCode)
	EndIf

	If $bExceptionsNeedSave Then
		_JSON_addChangeDelete($oData, "properties.excluded-apps.value", $sNewExcluded)
	EndIf
	;----------------
	If $iCurrentColor <> $iColor Then
		Local $sColorForJSON = "#" & Hex($iCurrentColor, 6)
		_JSON_addChangeDelete($oData, "properties.frame-color.value", $sColorForJSON)
	EndIf

	Local $bNewFrameEnabled = _IsChecked($idCheckboxShowBorder)
	If $bNewFrameEnabled <> $bFrameEnabled Then
		_JSON_addChangeDelete($oData, "properties.frame-enabled.value", $bNewFrameEnabled)
	EndIf

	Local $bNewSound = _IsChecked($idCheckboxSound)
	If $bNewSound <> $bSound Then
		_JSON_addChangeDelete($oData, "properties.sound-enabled.value", $bNewSound)
	EndIf

	Local $bNewGameMode = _IsChecked($idCheckboxGameMode)
	If $bNewGameMode <> $bGameMode Then
		_JSON_addChangeDelete($oData, "properties.do-not-activate-on-game-mode.value", $bNewGameMode)
	EndIf

	Local $bNewRoundCorners = _IsChecked($idCheckboxRounded)
	If $bNewRoundCorners <> $bRoundCorners Then
		_JSON_addChangeDelete($oData, "properties.round-corners-enabled.value", $bNewRoundCorners)
	EndIf

	Local $iNewOpacity = GUICtrlRead($idSliderOpacity)
	If $iNewOpacity <> $iOpacity Then
		_JSON_addChangeDelete($oData, "properties.frame-opacity.value", $iNewOpacity)
	EndIf

	Local $iNewThickness = GUICtrlRead($idSliderThickness)
	If $iNewThickness <> $iThickness Then
		_JSON_addChangeDelete($oData, "properties.frame-thickness.value", $iNewThickness)
	EndIf

	Local $iCurrentIndex = _GUICtrlComboBox_GetCurSel($idComboColorMode)
	Local $bCurrentAccent = ($iCurrentIndex = 0)
	If $bCurrentAccent <> $bAccent Then
		_JSON_addChangeDelete($oData, "properties.frame-accent-color.value", $bCurrentAccent)
	EndIf
	;-----------------------------------------

	Local $hFile = FileOpen($sSettingsPath, 2 + 8 + 256)
	If $hFile <> -1 Then
		Local $iResult = FileWrite($hFile, _JSON_GenerateCompact($oData))
		If $iResult = 0 Then
			MsgBox($MB_ICONERROR, $asErrMsg[$eErrorTitle], $asErrMsg[$eErrWriteJSON])          ; "Error", "File write error. Settings could not be saved."
			Return
		EndIf
		FileClose($hFile)
		FileSetTime($sSettingsPath, "", 0)
	Else
		MsgBox($MB_ICONERROR, $asErrMsg[$eErrorTitle], $asErrMsg[$eErrOpenJSON])                ; "Error", "Could not open the file to save settings."
		Return
	EndIf

	;----------------------------------------
	; And then UPDATE the reference standards
	$sHotKey = $sNewHotKey
	$sExcluded = $sNewExcluded
	$iColor = $iCurrentColor
	$bFrameEnabled = $bNewFrameEnabled
	$bSound = $bNewSound
	$bGameMode = $bNewGameMode
	$bRoundCorners = $bNewRoundCorners
	$iOpacity = $iNewOpacity
	$iThickness = $iNewThickness
	$bAccent = $bCurrentAccent

	GUICtrlSetState($idButtonSave, $GUI_DISABLE)
	ControlSetText($hFormSettings, "", $idButtonSave, $asMsg[$eMsgDone])        ; "Done"
	$bDone = True
	AdlibRegister("_ResetSaveButtonText", 1500) ; Restore the button text after 1.5 seconds
EndFunc   ;==>_SaveSettings

Func _ResetSaveButtonText()
	AdlibUnRegister("_ResetSaveButtonText")
	$bDone = False
	If IsHWnd($hFormSettings) Then
		GUICtrlSetData($idButtonSave, $asSettingsDialog[$eSaveButton])            ; "Save"
	EndIf
EndFunc   ;==>_ResetSaveButtonText

Func _IsChecked($idControl)
	Return BitAND(GUICtrlRead($idControl), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>_IsChecked

; Helper function for assembling a human-readable string
Func _GetHotkeyStr()
	Local $sKeyName = _GetKeyName($iCode)
	Local $sPrefix = ""
	If $bWin Then $sPrefix &= "Win + "
	If $bCtrl Then $sPrefix &= "Ctrl + "
	If $bAlt Then $sPrefix &= "Alt + "
	If $bShift Then $sPrefix &= "Shift + "
	Return $sPrefix & $sKeyName
EndFunc   ;==>_GetHotkeyStr

; Getting the name of a key by its VK code
Func _GetKeyName($iVK)
    If $iVK = 0 Then Return ""

    ; 1. Function/Control Keys Group
    Switch $iVK
		Case 0x08
			Return "Backspace"
        Case 0x09
			Return "Tab"
        Case 0x0D
			Return "Enter"
        Case 0x13, 0x91
			Return "Pause"
        Case 0x14
			Return "Caps Lock"
        Case 0x1B
			Return "Esc"
        Case 0x20
			Return "Space"
        Case 0x21
			Return "Page Up"
        Case 0x22
			Return "Page Down"
        Case 0x23
			Return "End"
        Case 0x24
			Return "Home"
        Case 0x25
			Return "Left"
        Case 0x26
			Return "Up"
        Case 0x27
			Return "Right"
        Case 0x28
			Return "Down"
        Case 0x2C
			Return "PrtSc"
        Case 0x2D
			Return "Insert"
        Case 0x2E
			Return "Delete"
        Case 0xAD
			Return "Mute"
        Case 0xAE
			Return "Vol Down"
        Case 0xAF
			Return "Vol Up"
    EndSwitch

	; 2. Exclude Numpad from "symbolic" processing (let it go to GetKeyNameText)
	; Numpad ranges: 0x60-0x6F
    If $iVK < 0x60 Or $iVK > 0x6F Then
        Local Static $hEngLayout = _WinAPI_LoadKeyboardLayout("00000409", 0)

        ; We use the standard function, passing the handle in the 3rd parameter
        Local $iChar = _WinAPI_MapVirtualKey($iVK, 2, $hEngLayout)

        If $iChar > 31 Then Return StringUpper(Chr($iChar))
    EndIf

    ; 3. For everything else (Numpad, F1-F12, additional keys) use the system name
    Local $iScanCode = _WinAPI_MapVirtualKey($iVK, 0)
    Local $lParam = BitShift($iScanCode, -16)
    ; Extended key flag for navigation (Insert, Delete, Home, End, and arrow keys)
    If $iVK >= 0x21 And $iVK <= 0x2F Then $lParam = BitOR($lParam, 0x01000000)
    ;Flag for Numpad / and Enter
    If $iVK = 0x6F Or $iVK = 0x0D Then $lParam = BitOR($lParam, 0x01000000)

    Local $sName = _WinAPI_GetKeyNameText($lParam)
    Return ($sName <> "" ? $sName : "Key 0x" & Hex($iVK, 2))
EndFunc
   ;==>_GetKeyName

; Keyboard processing function (Hook)
; Inside the _KeyProc function
Func _KeyProc($nCode, $wParam, $lParam)
	If $nCode < 0 Then Return _WinAPI_CallNextHookEx($hKeyHook, $nCode, $wParam, $lParam)

	If $wParam = $WM_KEYDOWN Or $wParam = $WM_SYSKEYDOWN Then
		Local $tKBDLL = DllStructCreate($tagKBDLLHOOKSTRUCT, $lParam)
		Local $vk = DllStructGetData($tKBDLL, "vkCode")

		; Ignore modifiers (Shift, Ctrl, Alt, Win)
		If ($vk >= 0x10 And $vk <= 0x12) Or ($vk >= 0xA0 And $vk <= 0xA5) Or $vk = 0x5B Or $vk = 0x5C Then
			Return _WinAPI_CallNextHookEx($hKeyHook, $nCode, $wParam, $lParam)
		EndIf

		; We fix the state of the modifiers
		$bWin  = (BitAND(_WinAPI_GetAsyncKeyState(0x5B), 0x8000) <> 0) Or (BitAND(_WinAPI_GetAsyncKeyState(0x5C), 0x8000) <> 0)
		$bCtrl  = BitAND(_WinAPI_GetAsyncKeyState(0x11), 0x8000) <> 0
		$bAlt   = BitAND(_WinAPI_GetAsyncKeyState(0x12), 0x8000) <> 0
		$bShift = BitAND(_WinAPI_GetAsyncKeyState(0x10), 0x8000) <> 0

		$iCode = $vk
		GUICtrlSetData($idInputHotkeys, _GetHotkeyStr())

		; BLOCK: If Tab (0x09), any combination with Win is pressed, Ctrl+Esc, Alt+F4
		; Return 1 to prevent default behavior (focus switching or the Start menu)
		If $vk = 0x09 Or $bWin Or $vk = 0x0D Or ($vk = 0x1B And $bCtrl) Or ($vk = 0x73 And $bAlt) Then Return 1
	EndIf
	Return _WinAPI_CallNextHookEx($hKeyHook, $nCode, $wParam, $lParam)
EndFunc   ;==>_KeyProc

; Removing the hook
Func _Unhook()
	If $hKeyHook Then
		_WinAPI_UnhookWindowsHookEx($hKeyHook)
		$hKeyHook = 0
	EndIf
EndFunc   ;==>_Unhook

Func _PowerToys_AlwaysOnTop_Cleanup()
	; 1. READ THE SETTINGS
	Local $hFile = FileOpen($sSettingsPath, 256)
	Local $sJson = FileRead($hFile)
	Local $oData = _JSON_Parse($sJson)
	FileClose($hFile)

	Local $bWin   = _JSON_Get($oData, "properties.hotkey.value.win")
	Local $bCtrl  = _JSON_Get($oData, "properties.hotkey.value.ctrl")
	Local $bAlt   = _JSON_Get($oData, "properties.hotkey.value.alt")
	Local $bShift = _JSON_Get($oData, "properties.hotkey.value.shift")
	Local $iCode  = _JSON_Get($oData, "properties.hotkey.value.code")

	Local $sMods = ""
	If $bCtrl Then $sMods &= "^"
	If $bAlt Then $sMods &= "!"
	If $bShift Then $sMods &= "+"
	If $bWin Then $sMods &= "#"
	Local $sKeyStroke = $sMods & "{" & Chr($iCode) & "}"

	; 2. SEARCH FOR TARGET WINDOWS
	Local $aFrames = WinList("[CLASS:AlwaysOnTop_Border]")
	Local $aTargets[0]

	If $aFrames[0][0] > 0 Then
		For $i = 1 To $aFrames[0][0]
			Local $hFrame = $aFrames[$i][1]
			Local $aF = WinGetPos($hFrame)
			If Not IsArray($aF) Then ContinueLoop

			Local $fCX = $aF[0] + ($aF[2] / 2)
			Local $fCY = $aF[1] + ($aF[3] / 2)

			Local $aWins = WinList()
			For $j = 1 To $aWins[0][0]
				Local $hWnd = $aWins[$j][1]
				If $hWnd = $hFrame Or $aWins[$j][0] == "" Then ContinueLoop

				Local $aW = WinGetPos($hWnd)
				If IsArray($aW) And (Abs($fCX - ($aW[0] + ($aW[2] / 2))) <= 1.5) And ($fCY >= $aW[1] And $fCY <= ($aW[1] + $aW[3])) Then
					If BitAND(_WinAPI_GetWindowLong($hWnd, -20), 0x00000008) Then
						_ArrayAdd($aTargets, $hWnd)
						ExitLoop
					EndIf
				EndIf
			Next
		Next
	EndIf

	$hWnd = WinGetHandle("[ACTIVE]")
	Local $hOldLayout = _WinAPI_GetKeyboardLayout($hWnd)
	_FixAccelHotKeyLayout()

	; 3. DISABLING FRAMES BY THE PROGRAM ITSELF
	If IsArray($aTargets) And UBound($aTargets) > 0 Then
		For $k = 0 To UBound($aTargets) - 1
			Local $hT = $aTargets[$k]
			If WinExists($hT) Then
				WinActivate($hT)
				If Not WinWaitActive($hT, "", 2) Then ContinueLoop

				Local $sCleanKey = $sMods & StringLower(Chr($iCode)) ; --------------------------------------->>>>> in lowercase!!!!!
				Send($sCleanKey)
			EndIf
		Next
	EndIf

	Local $hNewLayout = _WinAPI_GetKeyboardLayout($hWnd)
	If $hNewLayout <> $hOldLayout Then
		_SendMessage(_WinAPI_GetForegroundWindow(), $WM_INPUTLANGCHANGEREQUEST, 0, $hOldLayout)
	EndIf

	; 4. CLOSE THE PROCESS
	If $iPID > 0 And ProcessExists($iPID) Then ProcessClose($iPID)

	; 5. EXIT
	Exit
EndFunc   ;==>_PowerToys_AlwaysOnTop_Cleanup

Func _FixAccelHotKeyLayout() ; @CreatoR (https://autoit-script.ru/threads/5745/)
	Static $iKbrdLayout, $aKbrdLayouts

	If Execute('@exitMethod') <> '' Then
		Local $iUnLoad = 1

		For $i = 1 To UBound($aKbrdLayouts) - 1
			If Hex($iKbrdLayout) = Hex('0x' & StringRight($aKbrdLayouts[$i], 4)) Then
				$iUnLoad = 0
				ExitLoop
			EndIf
		Next

		If $iUnLoad Then
			_WinAPI_UnloadKeyboardLayout($iKbrdLayout)
		EndIf

		Return
	EndIf

	$iKbrdLayout = 0x0409
	$aKbrdLayouts = _WinAPI_GetKeyboardLayoutList()
	_WinAPI_LoadKeyboardLayout($iKbrdLayout, $KLF_ACTIVATE)

	OnAutoItExitRegister('_FixAccelHotKeyLayout')
EndFunc   ;==>_FixAccelHotKeyLayout

; Disable interrupts
Func _LockingBREAKkey()
	; Redirect hotkeys to an empty function
	HotKeySet("^{BREAK}", "_Ignore_Hotkeys_With_Break")
	HotKeySet("^!{BREAK}", "_Ignore_Hotkeys_With_Break")
	HotKeySet("+^{BREAK}", "_Ignore_Hotkeys_With_Break")

	; Disable the system handler (Console Control Handler)
	DllCall("kernel32.dll", "bool", "SetConsoleCtrlHandler", "ptr", 0, "bool", 1)
EndFunc   ;==>_LockingBREAKkey

; Unlock interrupts
Func _ReleaseBREAKkey()
	; Restore hotkeys
	HotKeySet("^{BREAK}")
	HotKeySet("^!{BREAK}")
	HotKeySet("+^{BREAK}")

	; Return the system handler to normal mode
	DllCall("kernel32.dll", "bool", "SetConsoleCtrlHandler", "ptr", 0, "bool", 0)
EndFunc   ;==>_ReleaseBREAKkey

; Stub (empty function)
Func _Ignore_Hotkeys_With_Break()
	Return
EndFunc   ;==>_Ignore_Hotkeys_With_Break

Func MyCleanup()
	; RESET CURSORS: Return the system cursor if the pipette is “frozen”
	; SPI_SETCURSORS forces Windows to re-read the cursors from the registry
	DllCall("user32.dll", "bool", "SystemParametersInfo", "uint", $SPI_SETCURSORS, "uint", 0, "ptr", 0, "uint", 0)

	;If the settings window exists, remove the hooks
	If IsHWnd($hFormSettings) Then
		_WinAPI_SetWindowLong(GUICtrlGetHandle($idEditExceptions), $GWL_WNDPROC, $wProcOld_Edit)
		_WinAPI_SetWindowLong(GUICtrlGetHandle($idInputHotkeys), $GWL_WNDPROC, $wProcOld_Input)
		_GUICtrlMenu_DestroyMenu($hContextMenu_Edit)

		; Remove the Keyboard Hook if it is active
		_Unhook()
	EndIf

	; REMOVE WINDOWS: Close all windows (including the transparent background and the dialog box itself)
	; This ensures that the invisible window 1/255 won't block clicks on the desktop.
	GUIDelete()

	; Freeing the callback
	If $wProcHandle Then DllCallbackFree($wProcHandle)

	; GDI+ CLEANUP: If the Yashied library failed to close
	_GDIPlus_Shutdown()

	If $hStub_KeyProc Then DllCallbackFree($hStub_KeyProc)

	If $iPID > 0 And ProcessExists($iPID) Then ProcessClose($iPID)
EndFunc   ;==>MyCleanup

; LOCALIZATION
Func _GetStringFromResources($iStringID)
	Local $iString = _WinAPI_LoadString($hInstance, $iStringID)
	If @error Then
		MsgBox($MB_ICONERROR, "Error", "Failed to get string from program resources.")
		Exit
	EndIf
	Return $iString
EndFunc   ;==>_GetStringFromResources

; TRANSFORMATION FUNCTION (Called once at startup)
Func _InitAllStrings()
	_TranslateArray($asTrayMenu)
	_TranslateArray($asSettingsDialog)
	_TranslateArray($asAboutDialog)
	_TranslateArray($asColorDialog)
	_TranslateArray($asErrMsg)
	_TranslateArray($asMsg)
	_TranslateArray($asMenu)
EndFunc   ;==>_InitAllStrings

Func _TranslateArray(ByRef $aArray)
	For $i = 0 To UBound($aArray) - 1
		; Replace the string ID with the string itself
		$aArray[$i] = _GetStringFromResources($aArray[$i])
	Next
EndFunc   ;==>_TranslateArray

Func _ActivityContextMenuItem_Edit()
	ClipGet()
	If @error Then
		If _GUICtrlMenu_GetItemEnabled($hContextMenu_Edit, 2) Then
			_GUICtrlMenu_SetItemDisabled($hContextMenu_Edit, 2)           ;Paste
		EndIf
	Else
		If _GUICtrlMenu_GetItemDisabled($hContextMenu_Edit, 2) Then
			_GUICtrlMenu_SetItemEnabled($hContextMenu_Edit, 2)            ;Paste
		EndIf
	EndIf
	;-------------------------------------------------
	Local $aSel = _GUICtrlEdit_GetSel($idEditExceptions)
	Local $iSelect = $aSel[1] - $aSel[0]
	If $iSelect = 0 Or _GetCleanText($idEditExceptions) = "" Then
		If _GUICtrlMenu_GetItemEnabled($hContextMenu_Edit, 0) Then
			_GUICtrlMenu_SetItemDisabled($hContextMenu_Edit, 0)           ;Cut
		EndIf
		If _GUICtrlMenu_GetItemEnabled($hContextMenu_Edit, 1) Then
			_GUICtrlMenu_SetItemDisabled($hContextMenu_Edit, 1)           ;Copy
		EndIf
		If _GUICtrlMenu_GetItemEnabled($hContextMenu_Edit, 3) Then
			_GUICtrlMenu_SetItemDisabled($hContextMenu_Edit, 3)           ;Delete
		EndIf
	Else
		If _GUICtrlMenu_GetItemDisabled($hContextMenu_Edit, 0) Then
			_GUICtrlMenu_SetItemEnabled($hContextMenu_Edit, 0)            ;Cut
		EndIf
		If _GUICtrlMenu_GetItemDisabled($hContextMenu_Edit, 1) Then
			_GUICtrlMenu_SetItemEnabled($hContextMenu_Edit, 1)            ;Copy
		EndIf
		If _GUICtrlMenu_GetItemDisabled($hContextMenu_Edit, 3) Then
			_GUICtrlMenu_SetItemEnabled($hContextMenu_Edit, 3)            ;Delete
		EndIf
	EndIf
	;--------------------------------------------------
	Local $iAll = StringLen(GUICtrlRead($idEditExceptions))
	If $iAll = 0 Or $iAll = $iSelect Or _GetCleanText($idEditExceptions) = "" Then
		If _GUICtrlMenu_GetItemEnabled($hContextMenu_Edit, 5) Then
			_GUICtrlMenu_SetItemDisabled($hContextMenu_Edit, 5)           ;Select All
		EndIf
	Else
		If _GUICtrlMenu_GetItemDisabled($hContextMenu_Edit, 5) Then
			_GUICtrlMenu_SetItemEnabled($hContextMenu_Edit, 5)            ;Select All
		EndIf
	EndIf
EndFunc   ;==>_ActivityContextMenuItem_Edit
