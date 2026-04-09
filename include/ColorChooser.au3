#Region Header

#cs

	Title:          Color Chooser Dialog UDF Library for AutoIt3
	Filename:       ColorChooser.au3
	Description:    Creates a "Color Chooser" dialog box to select a custom color
	Author:         Yashied
	Version:        1.1
	Requirements:   AutoIt v3.3 +, Developed/Tested on WindowsXP Pro Service Pack 2
	Uses:           Constants.au3, EditConstants.au3, GUIConstantsEx.au3, GDIPlus.au3, Memory.au3, StaticConstants.au3, WinAPI.au3, WindowsConstants.au3
	Notes:          The library registers (permanently) the following window message:

                    WM_COMMAND
                    WM_NCRBUTTONDOWN
                    WM_SETCURSOR
                    WM_SYSCOMMAND

    Available functions:

    _ColorChooserDialog

#ce

#Include-once

#Include <Constants.au3>
#Include <EditConstants.au3>
#Include <GUIConstantsEx.au3>
#Include <GDIPlus.au3>
#Include <Memory.au3>
#Include <StaticConstants.au3>
#Include <WinAPI.au3>
#Include <WindowsConstants.au3>
#Include <WinAPISys.au3>
#Include <WindowsConstants.au3>

#EndRegion Header

#Region Global Variables and Constants

Global Const $CC_FLAG_SOLIDCOLOR = 0x01
Global Const $CC_FLAG_CAPTURECOLOR = 0x02
Global Const $CC_FLAG_USERCOLOR = 0x40
Global Const $CC_FLAG_DEFAULT = BitOR($CC_FLAG_SOLIDCOLOR, $CC_FLAG_CAPTURECOLOR)

#EndRegion Global Variables and Constants

#Region Local Variables and Constants

Global Const $CC_REG_COMMONDATA = 'HKCU\SOFTWARE\Y''s\Common Data\Color Chooser\1.1\Palette'

Global Const $CC_WM_COMMAND = 0x0111
Global Const $CC_WM_NCRBUTTONDOWN = 0x00A4
Global Const $CC_WM_SETCURSOR = 0x0020
Global Const $CC_WM_SYSCOMMAND = 0x0112

Global Const $ghGDIPDll = @SystemDir & '\GdiPlus.dll'

Dim $ccData[29] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, Default, Default, 0, 0]
Local $hPickerCursor
$hPickerCursor = _WinAPI_LoadCursor($hInstance, 101); nbb cursor


#cs

DO NOT USE THIS ARRAY IN THE SCRIPT, INTERNAL USE ONLY!

$ccData[0 ] - Handle to the "Color Chooser" window
       [1 ] - The control ID of the main palette image control
       [2 ] - The control ID of the arrow image control (left)
       [3 ] - The control ID of the arrow image control (right)
       [4 ] - The control ID of the HSB palette image control
       [5 ] - The control ID of the solid color preview image control (left)
       [6 ] - The control ID of the solid color preview image control (right)
       [7 ] - The control ID of the picker image control
       [8 ] - Handle to the left/right arrow image (HImage)
       [9 ] - Handle to the cursor (uses ColorPicker.au3)
       [10] - The control ID of the "R" (RGB) input
       [11] - The control ID of the "G" (RGB) input
       [12] - The control ID of the "B" (RGB) input
       [13] - The control ID of the "H" (HSL) input
       [14] - The control ID of the "S" (HSL) input
       [15] - The control ID of the "L" (HSL) input
       [16] - The control ID of the "H" (HSB) input
       [17] - The control ID of the "S" (HSB) input
       [18] - The control ID of the "B" (HSB) input
       [19] - The control ID of the "#" (HEX) input
       [20] - Passed/Initialization update value
       [21] - Capture color, in RGB
       [22] - Update input control flag
       [23] - The control ID of the "OK" button control
       [24] - The control ID of the Dummy control (input)
       [25] - X-offset relative to the parent window (Optional)
       [26] - Y-offset relative to the parent window (Optional)
       [27] - The control ID of the Dummy control (dounle click item)
       [28] - Reserved

#ce

Dim $ccPalette[21][3] = [[0, 1, 0]]

For $i = 1 To UBound($ccPalette) - 1
	$ccPalette[$i][0] = -1
Next

#cs

DO NOT USE THIS ARRAY IN THE SCRIPT, INTERNAL USE ONLY!

$ccPalette[0][0] - Current selected item
          [0][1] - Tooltip control flag (Optional)
          [0][2] - Don't used

$ccPalette[i][0] - User color, in RGB
          [i][1] - The control ID of the "User Color" image control
          [i][2] - Reserved

#ce

Global $__CC_RGB[3], $__CC_HSL[3], $__CC_HSB[3]

Global $__CC_WM0111 = 0
Global $__CC_WM0020 = 0

#EndRegion Local Variables and Constants

#Region Initialization

; IMPORTANT! If you register the following window messages in your code, you should call handlers from this library until
; you return from your handlers, otherwise the Clor Chooser dialog box will not work properly. For example:
;
; Func MY_WM_SETCURSOR($hWnd, $iMsg, $wParam, $lParam)
;     Local $Result = CC_WM_SETCURSOR($hWnd, $iMsg, $wParam, $lParam)
;     If Not $Result Then
;         Return 0
;     EndIf
;     ...
;     Return $GUI_RUNDEFMSG
; EndFunc   ;==>MY_WM_SETCURSOR

GUIRegisterMsg($CC_WM_COMMAND, 'CC_WM_COMMAND')
GUIRegisterMsg($CC_WM_NCRBUTTONDOWN, 'CC_WM_NCRBUTTONDOWN')
GUIRegisterMsg($CC_WM_SETCURSOR, 'CC_WM_SETCURSOR')
GUIRegisterMsg($CC_WM_SYSCOMMAND, 'CC_WM_SYSCOMMAND')

#EndRegion Initialization

#Region Public Functions

; #FUNCTION# ====================================================================================================================
; Name...........: _ColorChooserDialog
; Description....: Creates a "Color Chooser" dialog box that enables the user to select a color.
; Syntax.........: _ColorChooserDialog ( [$iColor [, $hParent [, $iRefType [, $iReturnType [, $iFlags [, $sTitle]]]]]] )
; Parameters.....: $iColor      - Default selected color. Type of this parameter depends on the $iRefType value and
;                                 should be one of the following types.
;
;                                 RGB (Red, Green, Blue)
;                                 Value of RGB color, like 0xRRGGBB.
;
;                                 HSL (Hue, Saturation, Lightness)
;                                 3-item array of values for the Hue, Saturation, and Lightness, respectively.
;
;                                 [0] - H (0-240)
;                                 [1] - S (0-240)
;                                 [2] - L (0-240)
;
;                                 HSB (Hue, Saturation, Brightness)
;                                 3-item array of values for the Hue, Saturation, and Brightness, respectively.
;
;                                 [0] - H (0-360)°
;                                 [1] - S (0-100)%
;                                 [2] - B (0-100)%
;
;                  $hParent     - Handle to the window that owns the dialog box.
;                  $iRefType    - Type of $iColor passed in, valid values:
;                  |0 - RGB
;                  |1 - HSL
;                  |2 - HSB
;                  $iReturnType - Determines return type, valid values:
;                  |0 - RGB
;                  |1 - HSL
;                  |2 - HSB
;                  $iFlags      - The flags that defines a style of the "Color Chooser" dialog box. This parameter can be
;                                 a combination of the following values.
;
;                                 $CC_FLAG_SOLIDCOLOR
;                                 $CC_FLAG_CAPTURECOLOR
;                                 $CC_FLAG_USERCOLOR
;                                 $CC_FLAG_DEFAULT
;
;                                 (See constants section in this library)
;
;                                 If this parameter contains $CC_FLAG_USERCOLOR flag, you can save up to 20 color values (in RGB).
;                                 These values are in the following registry hive and will be available for other programs that
;                                 use _ColorChooserDialog() function.
;
;                                 HKEY_CURRENT_USER\SOFTWARE\Y's Common Data\Color Chooser\Palette
;
;                  $sTitle      - Title of the "Color Chooser" dialog box.
; Return values..: Success      - Selected color depending on value of the $iReturnType parameter (see above).
;                  Failure      - (-1)
; Author.........: Yashied
; Modified.......:
; Remarks........: This function is fully compatible with the ColorPicker.au3 UDF library (v1.5) and can be used as a custom
;                  function for a "Color Chooser" dialog box (see examples). Since both these libraries use the same window messages,
;                  when using these messages in your code, you should refer to only one message from any library (see above).
; Related........:
; Link...........:
; Example........: Yes
; ===============================================================================================================================

Func _ColorChooserDialog($iColor = 0, $hParent = 0, $iRefType = 0, $iReturnType = 0, $iFlags = -1, $sTitle = $asColorDialog[$eColorCooser])	; "Color Picker"

	_GDIPlus_Startup()

	If $iFlags < 0 Then
		$iFlags = $CC_FLAG_DEFAULT
	EndIf

	$ccData[8 ] = _Image_Arrow()

	Local $hPopup = 0, $Msg, $Xp, $Yp, $Pos, $Cursor, $Index, $H1 = 0, $H2 = 0, $Pressed = False, $Return = False
	Local $H1 = 69 * (BitAND($iFlags, $CC_FLAG_SOLIDCOLOR) = $CC_FLAG_SOLIDCOLOR)
	LocaL $H2 = 56 * (BitAND($iFlags, $CC_FLAG_USERCOLOR) = $CC_FLAG_USERCOLOR)
	Local $GUIOnEventMode = Opt('GUIOnEventMode', 0)
	Local $GUICloseOnESC = Opt('GUICloseOnESC', 1)

	GUISetState(@SW_DISABLE, $hParent)

	$ccData[0 ] = GUICreate($sTitle, 315, 351 + $H2, -1, -1, BitOR($WS_CAPTION, $WS_POPUP, $WS_SYSMENU), $WS_EX_DLGMODALFRAME, $hParent);nbb: -H1

	CC_SetChildPos($ccData[0], $hParent, $ccData[25], $ccData[26])

	GUISetFont(9, 400, 0, 'Segoe UI', $ccData[0])
	$ccData[23] = GUICtrlCreateButton('OK', 179, 307 + $H2, 85, 25);nbb: -H1
	GUICtrlSetFont(-1, 9, 400, 0, 'Segoe UI')
	GUICtrlSetState(-1, $GUI_DEFBUTTON)
	$ccData[1 ] = GUICtrlCreatePic('', 20 , 20 , 243, 243, BitOR($GUI_SS_DEFAULT_PIC, $SS_SUNKEN))
	If $ccData[9] Then
		GUICtrlSetState(-1, $GUI_DISABLE)
	EndIf
	$ccData[2 ] = GUICtrlCreatePic('', 264, 17 , 8  , 249)
	$ccData[3 ] = GUICtrlCreatePic('', 296, 17 , 8  , 249)
	$ccData[4 ] = GUICtrlCreatePic('', 273, 20 , 22 , 243, BitOR($GUI_SS_DEFAULT_PIC, $SS_SUNKEN))
	If BitAND($iFlags, $CC_FLAG_SOLIDCOLOR) Then
		GUICtrlCreatePic('', 20, 273, 78, 59, BitOR($GUI_SS_DEFAULT_PIC, $SS_SUNKEN))
		GUICtrlSetState(-1, $GUI_DISABLE)
		$ccData[5] = GUICtrlCreatePic('', 21 , 274, 76, 57)
		$ccData[6] = 0;
	Else
		$ccData[5] = 0
		$ccData[6] = 0
	EndIf
	If BitAND($iFlags, $CC_FLAG_CAPTURECOLOR) Then
		$ccData[7] = GUICtrlCreateIcon(@ScriptFullPath, 201, 273, 273, 24, 24) ; nbb icon
		GUICtrlSetTip(-1, $asColorDialog[$ePickerTip]) ; "Capture color from the screen" nbb-hint
		GUICtrlSetCursor(-1, 0) ; nbb hand-cursor
	Else
		$ccData[7] = 0
	EndIf
	$ccPalette[0][0] = 0
	If BitAND($iFlags, $CC_FLAG_USERCOLOR) Then
	Else
		For $i = 1 To 10
			$ccPalette[$i][1] = 0
		Next
	EndIf

	GUICtrlCreateLabel('#' , 191, 276  + $H2, 10, 14);nbb: -H1
	$ccData[19] = GUICtrlCreateInput('', 202, 274 + $H2, 61, 21);nbb: -H1
	GUICtrlSetLimit(-1, 6)
	$ccData[24] = GUICtrlCreateDummy()
	$ccData[27] = GUICtrlCreateDummy()

	For $i = 10 To 18
		GUICtrlSetLimit($ccData[$i], 3)
	Next

	CC_SetPalette()
	CC_ValidateColor($iColor, $iRefType)
	CC_Update($ccData[20])
	CC_SetColor($__CC_RGB)

	GUISetState(@SW_SHOW, $ccData[0])

	$ccData[22] = 0

	While 1
		$Msg = 0
		$Cursor = GUIGetCursorInfo($ccData[0])
		If (Not @error) And (BitAND(WinGetState($ccData[0]), 8)) Then
			If $Cursor[2] Then
				If $Cursor[4] = $ccData[1] Then
					If Not $Pressed Then
						$Msg = $GUI_EVENT_PRIMARYDOWN
					EndIf
				Else
					$Pressed = 1
				EndIf
			Else
				$Pressed = 0
			EndIf
		EndIf
		If Not $Msg Then
			$Msg = GUIGetMsg(1)
			If $Msg[1] = $ccData[0] Then
				$Msg = $Msg[0]
			Else
				ContinueLoop
			EndIf
			If $Msg = $GUI_EVENT_PRIMARYDOWN Then
				ContinueLoop
			EndIf
		EndIf
		Switch $Msg
			Case $GUI_EVENT_PRIMARYDOWN
				GUICtrlSetState($ccData[23], $GUI_FOCUS)
				$Xp = Default
				While CC_IsPressed(0x01)
					$Pos = CC_GetCursor($ccData[1])
					If Not @error Then
						If ($Pos[0] <> $Xp) Or ($Pos[1] <> $Yp) Then
							For $i = 1 To 2
								$__CC_HSB[$i] = Round($Pos[$i - 1] / 240 * 100)
								If $__CC_HSB[$i] > 100 Then
									$__CC_HSB[$i] = 100
								EndIf
								If $__CC_HSB[$i] < 0 Then
									$__CC_HSB[$i] = 0
								EndIf
							Next
							$__CC_HSB[2] = 100 - $__CC_HSB[2]
							CC_Update(3, 0)
							$Xp = $Pos[0]
							$Yp = $Pos[1]
						EndIf
					EndIf
					Sleep(10) ; <---
				WEnd
			Case 0
				ContinueLoop
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $ccData[2], $ccData[3], $ccData[4]
				GUICtrlSetState($ccData[23], $GUI_FOCUS)
				$Xp = Default
				While CC_IsPressed(0x01)
					$Pos = CC_GetCursor($ccData[2])
					If Not @error Then
						If $Pos[1] <> $Yp Then
							$__CC_HSB[0] = Round((240 - $Pos[1] + 4) / 240 * 359)
							If $__CC_HSB[0] > 359 Then
								$__CC_HSB[0] = 359
							EndIf
							If $__CC_HSB[0] < 0 Then
								$__CC_HSB[0] = 0
							EndIf
							CC_Update(3, 1)
							$Xp = $Pos[0]
							$Yp = $Pos[1]
						EndIf
					EndIf
					Sleep(20) ; <---
				WEnd

			Case $ccData[7] ; Click the dropper icon
				; 1. Temporarily disable closing a window with ESC
				Local $iOldEsc = Opt('GUICloseOnESC', 0)

				; 1. Wait until you release the left mouse button after clicking on the icon
				While _WinAPI_GetAsyncKeyState(0x01)
					Sleep(10)
				WEnd

				; 2. REPLACING THE SYSTEM CURSOR
				; Save a copy of the original arrow so you can restore it at the end
				Local $hCopyCursorArrow = _WinAPI_CopyCursor(_WinAPI_LoadCursor(0, 32512))
				; Load the dropper cursor and replace the system arrow with it
				Local $hCopyMyCursor = _WinAPI_CopyCursor($hPickerCursor)
				_WinAPI_SetSystemCursor($hCopyMyCursor, 32512) ; 32512 = OCR_NORMAL

				; 3. CREATING A "CUSTOM" SIZE THE BACKGROUND WINDOW (+1 pixel)
				; This tricks the Z-order calculation algorithm for taskbar
				Local $hCaptureWin = GUICreate("Color Picker", @DesktopWidth + 1, @DesktopHeight + 1, -1, -1, 0x80000000, 0x00080008)

				_WinAPI_SetLayeredWindowAttributes($hCaptureWin, 0, 1, 2) ; Transparency 1/255

				; Important: Display WITHOUT activation to avoid losing focus
				GUISetState(@SW_SHOWNOACTIVATE, $hCaptureWin)

				While 1
					Local $tPoint = _WinAPI_GetMousePos()

					; 4. COLOR CAPTURE AND MATHEMATICAL CORRECTION
					Local $hDC = _WinAPI_GetDC(0)
					Local $iRawColor = _WinAPI_GetPixel($hDC, $tPoint.X, $tPoint.Y)
					_WinAPI_ReleaseDC(0, $hDC)

					; We're breaking it down into channels to fix the transparency error +1
					Local $iR = BitAnd(BitShift($iRawColor, 16), 0xFF)
					Local $iG = BitAnd(BitShift($iRawColor, 8), 0xFF)
					Local $iB = BitAnd($iRawColor, 0xFF)

					; Smart correction (taking into account rounding) (0x010101 -> 0x000000)
					If $iR > 0 And $iR < 128 Then $iR -= 1
					If $iG > 0 And $iG < 128 Then $iG -= 1
					If $iB > 0 And $iB < 128 Then $iB -= 1

					Local $iCleanColor = BitOR(BitShift($iR, -16), BitShift($iG, -8), $iB)
					$__CC_RGB = CC_SplitColor($iCleanColor)
					CC_Update(1, 1, 1)

					; 5. KEYS CHECK
					If _WinAPI_GetAsyncKeyState(0x01) Then ; LMB - Select
						Sleep(200)
						ExitLoop
					ElseIf _WinAPI_GetAsyncKeyState(0x1B) Or _WinAPI_GetAsyncKeyState(0x02) Then ; ESC or RMB - Cancel
						ExitLoop
					EndIf

					Sleep(15)
				WEnd

				; 6. RESTORING THE ORIGINAL CURSOR AND REMOVING THE BACKGROUND WINDOW
				_WinAPI_SetSystemCursor($hCopyCursorArrow, 32512)
				GUIDelete($hCaptureWin)
				; RESET the ESC key to its default setting (so the window can close again)
				Opt('GUICloseOnESC', $iOldEsc)

			Case $ccData[23]
				$Return = 1
				ExitLoop
			Case $ccData[24]
				$Index = GUICtrlRead($ccData[24])
				If $Index Then
					CC_Update($Index, 1, 1)
				EndIf
			Case $ccData[27]
				$Index = GUICtrlRead($ccData[27])
				Switch $Index
					Case 0

					Case $ccData[1], $ccData[5]
						If $ccPalette[0][0] Then
							$ccPalette[$ccPalette[0][0]][0] = CC_RGB($__CC_RGB)
							CC_SetUserColor($ccPalette[0][0], 1)
						EndIf
					Case $ccData[6]
						CC_ValidateColor($iColor, $iRefType)
						CC_Update($ccData[20])
					Case Else
						For $i = 1 To 20
							If $Index = $ccPalette[$i][1] Then
								If ($ccPalette[$i][0] > -1) And ($ccPalette[$i][0] <> CC_RGB($__CC_RGB)) Then
									$__CC_RGB = CC_SplitColor($ccPalette[$i][0])
									CC_Update(1)
								EndIf
								ExitLoop
							EndIf
						Next
				EndSwitch
			Case Else
				For $i = 1 To 20
					If $Msg = $ccPalette[$i][1] Then
						If $i <> $ccPalette[0][0] Then
							CC_SetUserColor($ccPalette[0][0])
							CC_SetUserColor($i, 1)
							$ccPalette[0][0] = $i
						EndIf
						ExitLoop
					EndIf
				Next
		EndSwitch
	WEnd

	$ccData[22] = 1

	GUISetState(@SW_ENABLE, $hParent)
	GUIDelete($ccData[0])

	$ccData[0 ] = 0

	Opt('GUIOnEventMode', $GUIOnEventMode)
	Opt('GUICloseOnESC', $GUICloseOnESC)

	_GDIPlus_ImageDispose($ccData[8])
	_GDIPlus_Shutdown()

	;If BitAND($iFlags, $CC_FLAG_USERCOLOR) Then
		;CC_SaveUserColor()
	;EndIf

	If $Return Then
		Switch $iReturnType
			Case 1
				Return $__CC_HSL
			Case 2
				Return $__CC_HSB
			Case Else
				Return CC_RGB($__CC_RGB)
		EndSwitch
	Else
		Return -1
	EndIf
EndFunc   ;==>_ColorChooserDialog

#EndRegion Public Functions

#Region Internal Functions

Func CC_Beep()
	DllCall('user32.dll', 'int', 'MessageBeep', 'int', 0)
EndFunc   ;==>CC_Beep

Func CC_GetBValue($iRGB)
	Return BitAND($iRGB, 0x0000FF)
EndFunc   ;==>CC_GetBValue

Func CC_GetClientPos($hWnd)

	Local $Size = WinGetClientSize($hWnd)

	If Not IsArray($Size) Then
		Return SetError(1, 0, 0)
	EndIf

	Local $tPOINT = DllStructCreate($tagPOINT)

	For $i = 1 To 2
		DllStructSetData($tPOINT, $i, 0)
	Next
	_WinAPI_ClientToScreen($hWnd, $tPOINT)
	If @error Then
		Return SetError(1, 0, 0)
	EndIf

	Local $Pos[4]

	For $i = 0 To 1
		$Pos[$i] = DllStructGetData($tPOINT, $i + 1)
	Next
	For $i = 2 To 3
		$Pos[$i] = $Size[$i - 2]
	Next
	Return $Pos
EndFunc   ;==>CC_GetClientPos

Func CC_GetCursor($hWnd = 0)

	If Not IsHWnd($hWnd) Then
		$hWnd = GUICtrlGetHandle($hWnd)
	EndIf

	Local $tPOINT = _WinAPI_GetMousePos($hWnd, $hWnd)

	If @error Then
		Return SetError(1, 0, 0)
	EndIf

	Local $Pos[2]

	For $i = 0 To 1
		$Pos[$i] = DllStructGetData($tPOINT, $i + 1)
	Next
	Return $Pos
EndFunc   ;==>CC_GetCursor

Func CC_GetGValue($iRGB)
	Return BitShift(BitAND($iRGB, 0x00FF00), 8)
EndFunc   ;==>CC_GetGValue

Func CC_GetRValue($iRGB)
	Return BitShift(BitAND($iRGB, 0xFF0000), 16)
EndFunc   ;==>CC_GetRValue

Func CC_IsDark($iRGB)
	If CC_GetRValue($iRGB) + CC_GetGValue($iRGB) + CC_GetBValue($iRGB) < 3 * 255 / 2 Then
		Return 1
	Else
		Return 0
	EndIf
EndFunc   ;==>CC_IsDark

Func CC_IsPressed($iKey)

	Local $Ret = DllCall('user32.dll', 'short', 'GetAsyncKeyState', 'int', $iKey)

	If @error Then
		Return SetError(1, 0, 0)
	EndIf
	Return Number(BitAND($Ret[0], 0x8000) <> 0)
EndFunc   ;==>CC_IsPressed

Func CC_LoadImageFromMem(ByRef $bImage)

	Local $hImage, $hStream, $bData, $hData, $pData, $tData, $Lenght

	$bData = Binary($bImage)
	$Lenght = BinaryLen($bData)
	$hData = _MemGlobalAlloc($Lenght, 2)
	$pData = _MemGlobalLock($hData)
	$tData = DllStructCreate('byte[' & $Lenght & ']', $pData)
	DllStructSetData($tData, 1, $bData)
	_MemGlobalUnlock($hData)
	$hStream = DllCall('ole32.dll', 'int', 'CreateStreamOnHGlobal', 'ptr', $hData, 'int', 1, 'ptr*', 0)
	$hImage = __GDIPlus_BitmapCreateFromStream($hStream[3])

	Return $hImage
EndFunc   ;==>CC_LoadImageFromMem

Func CC_RGB($aRGB)
	Return BitOR(BitShift($aRGB[0], -16), BitShift($aRGB[1], -8), $aRGB[2])
EndFunc   ;==>CC_RGB

Func CC_SetBitmap($hWnd, $hBitmap)

	If Not IsHWnd($hWnd) Then
		$hWnd = GUICtrlGetHandle($hWnd)
		If $hWnd = 0 Then
			Return
		EndIf
	EndIf

	Local $hObj

	$hObj = _SendMessage($hWnd, 0x0172, 0, $hBitmap)
	If $hObj Then
		_WinAPI_DeleteObject($hObj)
	EndIf
	_WinAPI_InvalidateRect($hWnd)
	$hObj = _SendMessage($hWnd, 0x0173)
	If $hObj <> $hBitmap Then
		_WinAPI_DeleteObject($hBitmap)
	EndIf
EndFunc   ;==>CC_SetBitmap

Func CC_SetChildPos($hChild, $hParent, $iX = Default, $iY = Default)

	Local $Pos1, $Pos2 = CC_GetClientPos($hParent)
	Local $tRECT, $Ret, $X, $Y, $Height

	$Pos1 = WinGetPos($hChild)
	If (@error) Or (Not IsArray($Pos2)) Then
		Return SetError(1, 0, 0)
	EndIf
	If $iX = Default Then
		$X = $Pos2[0] + ($Pos2[2] - $Pos1[2]) / 2
	Else
		$X = $Pos2[0] + $iX
	EndIf
	If $iY = Default Then
		$Y = $Pos2[1] + ($Pos2[3] - $Pos1[3]) / 2
	Else
		$Y = $Pos2[1] + $iY
	EndIf
	$tRECT = DllStructCreate($tagRECT)
	$Ret = DllCall('user32.dll', 'int', 'SystemParametersInfo', 'int', 48, 'int', 0, 'ptr', DllStructGetPtr($tRECT), 'int', 0)
	If (@error) Or ($Ret[0] = 0) Then
		$Height = @DesktopHeight
	Else
		$Height = DllStructGetData($tRECT, 4)
	EndIf
	If $X < 0 Then
		$X = 0
	EndIf
	If $X > @DesktopWidth - $Pos1[2] Then
		$X = @DesktopWidth - $Pos1[2]
	EndIf
	If $Y < 0 Then
		$Y = 0
	EndIf
	If $Y > $Height - $Pos1[3] Then
		$Y = $Height - $Pos1[3]
	EndIf
	If Not WinMove($hChild, '', $X, $Y) Then
		Return SetError(1, 0, 0)
	EndIf
	Return 1
EndFunc   ;==>CC_SetChildPos

Func CC_SetColor($RGB)

	Local $hGraphics, $hBrush, $hImage, $hBitmap

	$hBitmap = _WinAPI_CreateBitmap(118, 57, 1, 32)
	$hImage = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)
	_WinAPI_DeleteObject($hBitmap)
	$hGraphics = _GDIPlus_ImageGetGraphicsContext($hImage)
	$hBrush = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, CC_RGB($RGB)))
	_GDIPlus_GraphicsFillRect($hGraphics, 0, 0, 118, 57, $hBrush)
	_GDIPlus_BrushDispose($hBrush)
	_GDIPlus_GraphicsDispose($hGraphics)
	$hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hImage)
	_GDIPlus_ImageDispose($hImage)
	CC_SetBitmap($ccData[6], $hBitmap)
EndFunc   ;==>CC_SetColor

Func CC_SetPalette()

	Local $hGraphics, $hPen, $hImage, $hBitmap
	Local $ARGB, $RGB, $HSB[3]

	$hBitmap = _WinAPI_CreateBitmap(20, 241, 1, 32)
	$hImage = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)
	_WinAPI_DeleteObject($hBitmap)
	$hGraphics = _GDIPlus_ImageGetGraphicsContext($hImage)
	$HSB[1] = 100
	$HSB[2] = 100
	For $i = 0 To 240
		$HSB[0] = (240 - $i) * 359 / 240
		$RGB = _HSB2RGB($HSB)
		$hPen = _GDIPlus_PenCreate(BitOR(0xFF000000, CC_RGB($RGB)), 1)
		_GDIPlus_GraphicsDrawLine($hGraphics, 0, $i, 19, $i, $hPen)
		_GDIPlus_PenDispose($hPen)
	Next
	_GDIPlus_GraphicsDispose($hGraphics)
	$hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hImage)
	_GDIPlus_ImageDispose($hImage)
	CC_SetBitmap($ccData[4], $hBitmap)
EndFunc   ;==>CC_SetPalette

Func CC_SetUserColor($iIndex, $fSelect = 0)

	Local $hGraphics, $hBrush, $hPen, $hImage, $hBitmap

	$hBitmap = _WinAPI_CreateBitmap(22, 22, 1, 32)
	$hImage = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)
	_WinAPI_DeleteObject($hBitmap)
	$hGraphics = _GDIPlus_ImageGetGraphicsContext($hImage)
	$hBrush = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, CC_SwitchColor(_WinAPI_GetSysColor($COLOR_3DFACE))))
	_GDIPlus_GraphicsFillRect($hGraphics, 0, 0, 22, 22, $hBrush)
	$hPen = _GDIPlus_PenCreate(0xFFA7A7A7)
	_GDIPlus_GraphicsDrawRect($hGraphics, 2, 2, 17, 17, $hPen)
	If $fSelect Then
		_GDIPlus_PenSetColor($hPen, 0xFF606060)
		_GDIPlus_GraphicsDrawRect($hGraphics, 0, 0, 21, 21, $hPen)
	EndIf
	If $ccPalette[$iIndex][0] > -1 Then
		_GDIPlus_BrushSetSolidColor($hBrush, BitOR(0xFF000000, $ccPalette[$iIndex][0]))
		_GDIPlus_GraphicsFillRect($hGraphics, 3, 3, 16, 16, $hBrush)
		If $ccPalette[0][1] Then
			GUICtrlSetTip($ccPalette[$iIndex][1], '#' & Hex($ccPalette[$iIndex][0], 6))
		EndIf
	Else
		If $ccPalette[0][1] Then
			GUICtrlSetTip($ccPalette[$iIndex][1], 'None')
		EndIf
	EndIf
	_GDIPlus_BrushDispose($hBrush)
	_GDIPlus_PenDispose($hPen)
	_GDIPlus_GraphicsDispose($hGraphics)
	$hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hImage)
	_GDIPlus_ImageDispose($hImage)
	CC_SetBitmap($ccPalette[$iIndex][1], $hBitmap)
EndFunc   ;==>CC_SetUserColor

Func CC_SplitColor($iColor)

	Local $RGB[3]

	$RGB[0] = CC_GetRValue($iColor)
	$RGB[1] = CC_GetGValue($iColor)
	$RGB[2] = CC_GetBValue($iColor)

	Return $RGB
EndFunc   ;==>CC_SplitColor

Func CC_SwitchColor($iColor)
	Return BitOR(BitAND($iColor, 0x00FF00), BitShift(BitAND($iColor, 0x0000FF), -16), BitShift(BitAND($iColor, 0xFF0000), 16))
EndFunc   ;==>CC_SwitchColor

Func CC_Update($iIndex, $fPalette = 1, $fSkip = 0)

	Local $hGraphics, $hBrush, $hPen, $hImage, $hBitmap
	Local $X, $Y, $ARGB, $RGB, $HSB

	Switch $iIndex
		Case 4 ; HEX
			ContinueCase
		Case 1 ; RGB
			$__CC_HSL = _RGB2HSL($__CC_RGB)
			$__CC_HSB = _RGB2HSB($__CC_RGB)
		Case 2 ; HSL
			$__CC_RGB = _HSL2RGB($__CC_HSL)
			$__CC_HSB = _RGB2HSB($__CC_RGB)
		Case 3 ; HSB
			$__CC_RGB = _HSB2RGB($__CC_HSB)
			$__CC_HSL = _RGB2HSL($__CC_RGB)
	EndSwitch

	If $fPalette Then
		$hBitmap = _WinAPI_CreateBitmap(8, 249, 1, 32)
		$hImage = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)
		_WinAPI_DeleteObject($hBitmap)
		$hGraphics = _GDIPlus_ImageGetGraphicsContext($hImage)
		$hBrush = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, CC_SwitchColor(_WinAPI_GetSysColor($COLOR_3DFACE))))
		_GDIPlus_GraphicsFillRect($hGraphics, 0, 0, 8, 249, $hBrush)
		_GDIPlus_BrushDispose($hBrush)
		_GDIPlus_GraphicsDrawImageRect($hGraphics, $ccData[8], 0, Round((359 - $__CC_HSB[0]) / 359 * 240), 8, 9)
		_GDIPlus_GraphicsDispose($hGraphics)
		$hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hImage)
		CC_SetBitmap($ccData[2], $hBitmap)
		__GDIPlus_ImageRotateFlip($hImage, 4)
		$hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hImage)
		_GDIPlus_ImageDispose($hImage)
		CC_SetBitmap($ccData[3], $hBitmap)
	EndIf
	$HSB = $__CC_HSB
	$HSB[1] = 100
	$HSB[2] = 100
	$RGB = _HSB2RGB($HSB)
	$hBitmap = _WinAPI_CreateBitmap(241, 241, 1, 32)
	$hImage = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)
	_WinAPI_DeleteObject($hBitmap)
	$hGraphics = _GDIPlus_ImageGetGraphicsContext($hImage)
	$hBrush = __GDIPlus_LineBrushCreate(0, 0, 241, 0, 0xFFFFFFFF, BitOR(0xFF000000, CC_RGB($RGB)))
	_GDIPlus_GraphicsFillRect($hGraphics, 0, 0, 241, 241, $hBrush)
	_GDIPlus_BrushDispose($hBrush)
	$hBrush = __GDIPlus_LineBrushCreate(0, 0, 0, 241, 0, 0xFF000000)
	_GDIPlus_GraphicsFillRect($hGraphics, 0, 0, 241, 241, $hBrush)
	_GDIPlus_BrushDispose($hBrush)
	$X = Round($__CC_HSB[1] / 100 * 241)
	$Y = Round((1 - $__CC_HSB[2] / 100) * 241)
	If CC_IsDark(CC_RGB($__CC_RGB)) Then
		$ARGB = 0xFFFFFFFF
	Else
		$ARGB = 0xFF000000
	EndIf
	$hPen = _GDIPlus_PenCreate($ARGB, 2)
	_GDIPlus_GraphicsDrawLine($hGraphics, $X - 7, $Y, $X - 3, $Y, $hPen)
	_GDIPlus_GraphicsDrawLine($hGraphics, $X + 3, $Y, $X + 7, $Y, $hPen)
	_GDIPlus_GraphicsDrawLine($hGraphics, $X, $Y - 7, $X, $Y - 3, $hPen)
	_GDIPlus_GraphicsDrawLine($hGraphics, $X, $Y + 3, $X, $Y + 7, $hPen)
	_GDIPlus_PenDispose($hPen)
	_GDIPlus_GraphicsDispose($hGraphics)
	$hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hImage)
	_GDIPlus_ImageDispose($hImage)
	CC_SetBitmap($ccData[1], $hBitmap)
	If $ccData[5] Then
		$hBitmap = _WinAPI_CreateBitmap(76, 57, 1, 32)
		$hImage = _GDIPlus_BitmapCreateFromHBITMAP($hBitmap)
		_WinAPI_DeleteObject($hBitmap)
		$hGraphics = _GDIPlus_ImageGetGraphicsContext($hImage)
		$hBrush = _GDIPlus_BrushCreateSolid(BitOR(0xFF000000, CC_RGB($__CC_RGB)))
		_GDIPlus_GraphicsFillRect($hGraphics, 0, 0, 76, 57, $hBrush)
		_GDIPlus_BrushDispose($hBrush)
		_GDIPlus_GraphicsDispose($hGraphics)
		$hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hImage)
		_GDIPlus_ImageDispose($hImage)
		CC_SetBitmap($ccData[5], $hBitmap)
	EndIf
	$ccData[22] = 1
	If ($iIndex <> 1) Or (Not $fSkip) Then;------------------------------------->>>correct start
		For $i = 10 To 12
			; We check if the control exists (indices 10, 11, 12)
			If $ccData[$i] <> 0 Then GUICtrlSetData($ccData[$i], $__CC_RGB[$i - 10])
		Next
	EndIf

	If ($iIndex <> 2) Or (Not $fSkip) Then
		For $i = 13 To 15
			; We check if the control exists (indices 13, 14, 15)
			If $ccData[$i] <> 0 Then GUICtrlSetData($ccData[$i], $__CC_HSL[$i - 13])
		Next
	EndIf

	If ($iIndex <> 3) Or (Not $fSkip) Then
		For $i = 16 To 18
			; We check if the control exists (indices 16, 17, 18)
			If $ccData[$i] <> 0 Then GUICtrlSetData($ccData[$i], $__CC_HSB[$i - 16])
		Next
	EndIf;---------------------------------------------------------------------->>>correct end
	If ($iIndex <> 4) Or (Not $fSkip) Then
		GUICtrlSetData($ccData[19], Hex(CC_RGB($__CC_RGB), 6))
	EndIf
	$ccData[22] = 0
	If Not $fSkip Then
		GUICtrlSetState($ccData[23], $GUI_FOCUS)
	EndIf
EndFunc   ;==>CC_Update

Func CC_ValidateColor($iColor, $iType)
	For $i = 0 To 2
		$__CC_RGB[$i] = 0
		$__CC_HSL[$i] = 0
		$__CC_HSB[$i] = 0
	Next
	$__CC_HSL[0] = 160
	Switch $iType
		Case 0
			$__CC_RGB = CC_SplitColor($iColor)
			$ccData[20] = 1
		Case 1
			If (UBound($iColor) = 3) And (Not UBound($iColor, 2)) Then
				For $i = 0 To 2
					$__CC_HSL[$i] = Round($iColor[$i])
					If ($__CC_HSL[$i] < 0) Or ($__CC_HSL[$i] > 240) Then
						$__CC_HSL = $__CC_RGB
						ExitLoop
					EndIf
				Next
				If Not $__CC_HSL[1] Then
					$__CC_HSL[0] = 160
				EndIf
			EndIf
			$ccData[20] = 2
		Case 2
			If (UBound($iColor) = 3) And (Not UBound($iColor, 2)) Then
				$__CC_HSB[0] = Round($iColor[0])
				If Abs($__CC_HSB[0]) >= 360 Then
					$__CC_HSB[0] = Mod($__CC_HSB[0], 360)
				EndIf
				If $__CC_HSB[0] < 0 Then
					$__CC_HSB[0] += 360
				EndIf
				For $i = 1 To 2
					$__CC_HSB[$i] = Round($iColor[$i])
					If ($__CC_HSB[$i] < 0) Or ($__CC_HSB[$i] > 100) Then
						$__CC_HSB = $__CC_RGB
						ExitLoop
					EndIf
				Next
			EndIf
			$ccData[20] = 3
		Case Else
			$ccData[20] = 1
	EndSwitch
EndFunc   ;==>CC_ValidateColor

#EndRegion Internal Functions

#Region Color Convertion Functions

Func _HSL2RGB($aHSL)

	If Not $aHSL[1] Then
		$aHSL[0] = 160
	EndIf

	Local $Ret = DllCall('shlwapi.dll', 'dword', 'ColorHLSToRGB', 'dword', $aHSL[0], 'dword', $aHSL[2], 'dword', $aHSL[1])
	Local $RGB[3] = [0, 0, 0]

	If IsArray($Ret) Then
		$RGB = CC_SplitColor(CC_SwitchColor($Ret[0]))
	EndIf
	Return $RGB
EndFunc   ;==>_HSL2RGB

Func _HSB2RGB($aHSB)

	Local $RGB[3], $H, $L, $F, $P, $Q, $T

	For $i = 1 To 2
		$aHSB[$i] /= 100
	Next
	If $aHSB[1] = 0 Then
		For $i= 0 To 2
			$RGB[$i] = $aHSB[2]
		Next
	Else
		$H = $aHSB[0] / 60
		$L = Floor($H)
		$F = $H - $L
		$P = $aHSB[2] * (1 - $aHSB[1])
		$Q = $aHSB[2] * (1 - $aHSB[1] * $F)
		$T = $aHSB[2] * (1 - $aHSB[1] * (1 - $F))
		Switch $L
			Case 1
				$RGB[0] = $Q
				$RGB[1] = $aHSB[2]
				$RGB[2] = $P
			Case 2
				$RGB[0] = $P
				$RGB[1] = $aHSB[2]
				$RGB[2] = $T
			Case 3
				$RGB[0] = $P
				$RGB[1] = $Q
				$RGB[2] = $aHSB[2]
			Case 4
				$RGB[0] = $T
				$RGB[1] = $P
				$RGB[2] = $aHSB[2]
			Case 5
				$RGB[0] = $aHSB[2]
				$RGB[1] = $P
				$RGB[2] = $Q
			Case Else
				$RGB[0] = $aHSB[2]
				$RGB[1] = $T
				$RGB[2] = $P
		EndSwitch
	EndIf
	For $i = 0 To 2
		$RGB[$i] = Round($RGB[$i] * 255)
	Next
	Return $RGB
EndFunc   ;==>_HSB2RGB

Func _RGB2HSL($aRGB)

	Local $Ret = DllCall('shlwapi.dll', 'none', 'ColorRGBToHLS', 'dword', CC_SwitchColor(CC_RGB($aRGB)), 'dword*', 0, 'dword*', 0, 'dword*', 0)
	Local $HSL[3] = [160, 0, 0]

	If IsArray($Ret) Then
		$HSL[0] = $Ret[2]
		$HSL[1] = $Ret[4]
		$HSL[2] = $Ret[3]
	EndIf
	Return $HSL
EndFunc   ;==>_RGB2HSL

Func _RGB2HSB($aRGB)

	Local $Min = 255, $Max = 0
    Local $HSB[3], $D, $H

	For $i = 0 To 2
		If $aRGB[$i] > $Max Then
			$Max = $aRGB[$i]
		EndIf
		If $aRGB[$i] < $Min Then
			$Min = $aRGB[$i]
		EndIf
	Next
    If $Min = $Max Then
        $HSB[0] = 0
        $HSB[1] = 0
        $HSB[2] = $Max / 255
    Else
        If $aRGB[0] = $Min Then
            $D = $aRGB[1] - $aRGB[2]
            $H = 3
        Else
			If $aRGB[1] = $Min Then
				$D = $aRGB[2] - $aRGB[0]
				$H = 5
			Else
				$D = $aRGB[0] - $aRGB[1]
				$H = 1
			EndIf
		EndIf
        $HSB[0] = ($H - ($D / ($Max - $Min))) / 6
        $HSB[1] = ($Max - $Min) / $Max
        $HSB[2] = $Max / 255
    EndIf
	$HSB[0] = Round($HSB[0] * 360)
	If $HSB[0] = 360 Then
		$HSB[0] = 0
	EndIf
	For $i = 1 To 2
		$HSB[$i] = Round($HSB[$i] * 100)
	Next
    Return $HSB
EndFunc   ;==>_RGB2HSB

#EndRegion Color Convertion Functions

#Region GDI+ Functions

Func __GDIPlus_BitmapCreateFromStream($hStream)

	Local $aResult = DllCall($ghGDIPDll, 'uint', 'GdipCreateBitmapFromStream', 'ptr', $hStream, 'int*', 0)

	If @error Then
		Return SetError(@error, @extended, 0)
	EndIf
	Return $aResult[2]
EndFunc   ;==>__GDIPlus_BitmapCreateFromStream

Func __GDIPlus_BitmapGetPixel($hBitmap, $iX, $iY)

	Local $aResult = DllCall($ghGDIPDll, 'uint', 'GdipBitmapGetPixel', 'hwnd', $hBitmap, 'int', $iX, 'int', $iY, 'uint*', 0)

	If @error Then
		Return SetError(@error, @extended, 0)
	EndIf
	Return $aResult[4]
EndFunc   ;==>__GDIPlus_BitmapGetPixel

Func __GDIPlus_ImageRotateFlip($hImage, $iRotateFlip)

	Local $aResult = DllCall($ghGDIPDll, 'uint', 'GdipImageRotateFlip', 'hwnd', $hImage, 'int', $iRotateFlip)

	If @error Then
		Return SetError(@error, @extended, False)
	EndIf
	Return $aResult[0] = 0
EndFunc   ;==>__GDIPlus_ImageRotateFlip

Func __GDIPlus_LineBrushCreate($nX1, $nY1, $nX2, $nY2, $iARGB1, $iARGB2, $iWrap = 0)

	Local $tPoint1 = DllStructCreate('float;float')
	Local $tPoint2 = DllStructCreate('float;float')

	DllStructSetData($tPoint1, 1, $nX1)
	DllStructSetData($tPoint1, 2, $nY1)
	DllStructSetData($tPoint2, 1, $nX2)
	DllStructSetData($tPoint2, 2, $nY2)

	Local $aResult = DllCall($ghGDIPDll, 'uint', 'GdipCreateLineBrush', 'ptr', DllStructGetPtr($tPoint1), 'ptr', DllStructGetPtr($tPoint2), 'uint', $iARGB1, 'uint', $iARGB2, 'int', $iWrap, 'int*', 0)

	If @error Then
		Return SetError(@error, @extended, 0)
	EndIf
	Return $aResult[6]
EndFunc   ;==>__GDIPlus_LineBrushCreate

Func __GDIPlus_LineBrushSetTransform($hBrush, $hMatrix)

	Local $aResult = DllCall($ghGDIPDll, 'uint', 'GdipSetLineTransform', 'hwnd', $hBrush, 'hwnd', $hMatrix)

	If @error Then
		Return SetError(@error, @extended, False)
	EndIf
	Return $aResult[0] = 0
EndFunc   ;==>__GDIPlus_LineBrushSetTransform

#EndRegion GDI+ Functions

#Region Internal Image Functions

Func _Image_Arrow()

	Local $bArrow = _
		 '0x89504E470D0A1A0A0000000D49484452000000080000000908060000000F536D' & _
		   '2E000000097048597300000B1300000B1301009A9C180000000467414D410000' & _
		   'B18E7CFB5193000000206348524D00007A25000080830000F9FF000080E90000' & _
		   '75300000EA6000003A980000176F925FC546000000474944415478DA8490410A' & _
		   'C0300804C77C7CDD97DB4B0A364DDA010FB283C2465561BB98480A3A99599DB9' & _
		   '73CF6041D2E3E24B58A5ADD0A5A3601B4931BEC2ED8B1E02C45F0FD70083FA3C' & _
		   'F26952F43C0000000049454E44AE426082'

	Return CC_LoadImageFromMem($bArrow)
EndFunc   ;==>_Image_Arrow

#EndRegion Internal Image Functions

#Region Windows Message Functions

Func CC_WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)

	; Handler from ColorPicker.au3
	If (IsDeclared('__CP_WM0111')) And (Not Eval('__CP_WM0111')) Then
		$__CC_WM0111 = 1
		Call('CP' & '_WM_COMMAND', $hWnd, $iMsg, $wParam, $lParam)
		$__CC_WM0111 = 0
	EndIf

	If (Not $ccData[0]) Or ($ccData[22]) Then
		Return $GUI_RUNDEFMSG
	EndIf

	Local $ID = BitAND($wParam, 0xFFFF)

	Switch $hWnd
		Case $ccData[0]

			Local $Val, $Data = GUICtrlRead($ID)

			Switch BitShift($wParam, 16)
				Case 1 ; STN_DBLCLK
					GUICtrlSendToDummy($ccData[27], $ID)
				Case $EN_CHANGE
					Switch $ID
						Case $ccData[19]
							$Val = StringRegExpReplace($Data, '[^[:xdigit:]]', '')
						Case Else
							$Val = StringRegExpReplace($Data, '[^0-9]', '')
					EndSwitch
					If $Data <> $Val Then
						GUICtrlSetData($ID, $Val)
						CC_Beep()
					EndIf
					Switch $ID
						Case $ccData[19]
							$Val = Number('0x' & $Val)
						Case Else
							$Val = Number($Val)
					EndSwitch
					Switch $ID
						Case $ccData[10] ; R
							If $Val > 255 Then
								$Val = 255
							EndIf
							If $Val <> $__CC_RGB[0] Then
								$__CC_RGB[0] = $Val
								GUICtrlSendToDummy($ccData[24], 1)
							EndIf
						Case $ccData[11] ; G
							If $Val > 255 Then
								$Val = 255
							EndIf
							If $Val <> $__CC_RGB[1] Then
								$__CC_RGB[1] = $Val
								GUICtrlSendToDummy($ccData[24], 1)
							EndIf
						Case $ccData[12] ; B
							If $Val > 255 Then
								$Val = 255
							EndIf
							If $Val <> $__CC_RGB[2] Then
								$__CC_RGB[2] = $Val
								GUICtrlSendToDummy($ccData[24], 1)
							EndIf
						Case $ccData[13] ; H
							If $Val > 240 Then
								$Val = 240
							EndIf
							If $Val <> $__CC_HSL[0] Then
								$__CC_HSL[0] = $Val
								GUICtrlSendToDummy($ccData[24], 2)
							EndIf
						Case $ccData[14] ; S
							If $Val > 240 Then
								$Val = 240
							EndIf
							If $Val <> $__CC_HSL[1] Then
								$__CC_HSL[1] = $Val
								GUICtrlSendToDummy($ccData[24], 2)
							EndIf
						Case $ccData[15] ; L
							If $Val > 240 Then
								$Val = 240
							EndIf
							If $Val <> $__CC_HSL[2] Then
								$__CC_HSL[2] = $Val
								GUICtrlSendToDummy($ccData[24], 2)
							EndIf
						Case $ccData[16] ; H
							If $Val >= 360 Then
								$Val = Mod($Val, 360)
							EndIf
							If $Val <> $__CC_HSB[0] Then
								$__CC_HSB[0] = $Val
								GUICtrlSendToDummy($ccData[24], 3)
							EndIf
						Case $ccData[17] ; S
							If $Val > 100 Then
								$Val = 100
							EndIf
							If $Val <> $__CC_HSB[1] Then
								$__CC_HSB[1] = $Val
								GUICtrlSendToDummy($ccData[24], 3)
							EndIf
						Case $ccData[18] ; B
							If $Val > 100 Then
								$Val = 100
							EndIf
							If $Val <> $__CC_HSB[2] Then
								$__CC_HSB[2] = $Val
								GUICtrlSendToDummy($ccData[24], 3)
							EndIf
						Case $ccData[19] ; #
							If $Val <> CC_RGB($__CC_RGB) Then
								$__CC_RGB = CC_SplitColor($Val)
								GUICtrlSendToDummy($ccData[24], 4)
							EndIf
					EndSwitch
				Case $EN_KILLFOCUS
					Switch $ID
						Case $ccData[10] ; R
							GUICtrlSetData($ID, $__CC_RGB[0])
						Case $ccData[11] ; G
							GUICtrlSetData($ID, $__CC_RGB[1])
						Case $ccData[12] ; B
							GUICtrlSetData($ID, $__CC_RGB[2])
						Case $ccData[13] ; H
							If Not $__CC_HSL[1] Then
								$__CC_HSL[0] = 160
							EndIf
							GUICtrlSetData($ID, $__CC_HSL[0])
						Case $ccData[14] ; S
							If Not $__CC_HSL[1] Then
								$__CC_HSL[0] = 160
								GUICtrlSetData($ccData[13], $__CC_HSL[0])
							EndIf
							GUICtrlSetData($ID, $__CC_HSL[1])
						Case $ccData[15] ; L
							GUICtrlSetData($ID, $__CC_HSL[2])
						Case $ccData[16] ; H
							GUICtrlSetData($ID, $__CC_HSB[0])
						Case $ccData[17] ; S
							GUICtrlSetData($ID, $__CC_HSB[1])
						Case $ccData[18] ; B
							GUICtrlSetData($ID, $__CC_HSB[2])
						Case $ccData[19] ; #
							GUICtrlSetData($ID, Hex(CC_RGB($__CC_RGB), 6))
					EndSwitch
;				Case $EN_SETFOCUS
;					GUICtrlSetState($ID, $GUI_FOCUS)
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>CC_WM_COMMAND

Func CC_WM_NCRBUTTONDOWN($hWnd, $iMsg, $wParam, $lParam)

	If Not $ccData[0] Then
		Return $GUI_RUNDEFMSG
	EndIf

	Switch $hWnd
		Case $ccData[0]
			Switch $wParam
				Case 0x08, 0x09, 0x14, 0x15 ; HTMINBUTTON, HTMAXBUTTON, HTCLOSE, HTHELP
					Return 0
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>CC_WM_NCRBUTTONDOWN

Func CC_WM_SETCURSOR($hWnd, $iMsg, $wParam, $lParam)

	Local $Result

	; Handler from ColorPicker.au3
	If (IsDeclared('__CP_WM0020')) And (Not Eval('__CP_WM0020')) Then
		$__CC_WM0020 = 1
		$Result = Call('CP' & '_WM_SETCURSOR', $hWnd, $iMsg, $wParam, $lParam)
		$__CC_WM0020 = 0
		If Not $Result Then
			Return 0
		EndIf
	EndIf

	If Not $ccData[0] Then
		Return $GUI_RUNDEFMSG
	EndIf

	Switch $hWnd
		Case $ccData[0]
			If $ccData[9] Then

				Local $Cursor = GUIGetCursorInfo($ccData[0])

				If (Not @error) And ($Cursor[4] = $ccData[1]) Then
					_WinAPI_SetCursor($ccData[9])
					Return 0
				EndIf
			EndIf
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>CC_WM_SETCURSOR

Func CC_WM_SYSCOMMAND($hWnd, $iMsg, $wParam, $lParam)

	If Not $ccData[0] Then
		Return $GUI_RUNDEFMSG
	EndIf

	Switch $hWnd
		Case $ccData[0]
			Switch $wParam
				Case 0xF100 ; SC_KEYMENU
					Return 0
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>CC_WM_SYSCOMMAND

#EndRegion Windows Message Functions
