	
	
	#ifndef APPNAME
	#include "shotgame.hsp"
	#endif
	
	#ifndef AS_MENU
	#define AS_MENU
	
goto *_MENU_AS_END

#deffunc initMenu
	
	xx = windowWidth/8
	yy = windowHeight/8
	
	// �|�[�Y���
	makeCanvas CVS_PAUSE
	guiOption xx*2, fSize*2 + yMargin*2, GUI_S_SHOW
	pos (windowWidth-xx*2)/2, yy*2*3
	makeButton "�ݒ�" :optionBtnId = stat
	makeButton "�I��" :quitBtnId = stat
	
	// �ݒ���
	makeCanvas CVS_OPTION
	guiOption 100, fSize*2 + yMargin*2, GUI_S_DISABLE
	yy = windowHeight/8
	pos xx*3, yy
	makeButton "�L�[�ݒ�" :keyOptionBtnId = stat
	cy = ginfo_cy
	
	pos xx, cy
	str_ = "��", "��", "�E", "��", "���C", "�T�u���C", "����1", "����2", "����3", "�����[�h", "�_�b�V��"
	keyChangeLen = length(str_)
	repeat keyChangeLen
		pos xx, cy+(yy+yMargin)*cnt
		makeButton str_.cnt
		if 0 == cnt :keysTextBeginBtnId = stat
	loop
	
	guiOption 100, fSize*2 + yMargin*2, GUI_S_SHOW
	pos xx*3, cy
	repeat keyChangeLen
		pos xx*3, cy+(yy+yMargin)*cnt
		makeButton getKeyName(keys.cnt)
		if 0 == cnt :keysBeginBtnId = stat
	loop
	
	yy = fSize*2 + yMargin*2
	guiOption 200, yy, GUI_S_SHOW
	yy = windowHeight/8
	pos xx*5, yy
	makeTrackBar "����", 0, 1000, masterVolume :volumeBtnId = stat
	
	pos xx*5, ginfo_cy + hiword(getGUIObjectSize(optionBtnId))
	makeTrackBar "chat���ߓx", 0, 255, chatDefaultAlpha :chatAlphaBtnId = stat
	
	yy = fSize*2 + yMargin*2
	guiOption 100, yy, GUI_S_DISABLE
	pos xx*5, ginfo_cy + hiword(getGUIObjectSize(optionBtnId))
	makeButton "�w�i�F" :colorBtnId = stat
	
	oldConfigColor = configColor
	yy = fSize*2 + yMargin*2
	guiOption 200, yy, GUI_S_SHOW
	makeTrackBar "��", 0, 255, RR(configColor) :rColorBtnId = stat
	makeTrackBar "��", 0, 255, GG(configColor) :gColorBtnId = stat
	makeTrackBar "��", 0, 255, BB(configColor) :bColorBtnId = stat
	
	selectCanvas CVS_MAIN
	
	return
	
#deffunc resizeMenu
	
	xx = windowWidth/10
	yy = windowHeight/8
	
	width_ = loword(getGUIObjectSize(optionBtnId))
	pos (windowWidth-width_)/2, yy*2*3
	moveGUIObject optionBtnId
	moveGUIObject quitBtnId
	
	pos xx, yy
	moveGUIObject keyOptionBtnId
	cy = ginfo_cy
	
	pos xx, cy
	repeat keyChangeLen
		moveGUIObject keysTextBeginBtnId+cnt
	loop
	pos xx*3, cy
	repeat keyChangeLen
		moveGUIObject keysBeginBtnId+cnt
	loop
	
	pos xx*5, yy
	moveGUIObject volumeBtnId
	
	pos xx*5, ginfo_cy + hiword(getGUIObjectSize(optionBtnId))
	moveGUIObject chatAlphaBtnId
	
	pos xx*5, ginfo_cy + hiword(getGUIObjectSize(optionBtnId))
	moveGUIObject colorBtnId
	moveGUIObject rColorBtnId
	moveGUIObject gColorBtnId
	moveGUIObject bColorBtnId
	
	return
	
#deffunc menuCalc
	
	if hMainWnd != getForegroundWindow() {
		if WINDOW_ACTIVE == pauseFlag :pauseFlag = WINDOW_BACKGROUND
	} else :if WINDOW_BACKGROUND == pauseFlag {
		pauseFlag = WINDOW_ACTIVE
	}
	
	if pauseWait :pauseWait-- :return
	
	if keyDowned(keys.K_ESCAPE) {
		switch pauseFlag
		case WINDOW_ACTIVE
		case WINDOW_OPTION
			pauseFlag = WINDOW_PAUSE
			swbreak
			
		case WINDOW_PAUSE
			pauseFlag = WINDOW_ACTIVE
			swbreak
		swend
	}
	
	if downedButton(optionBtnId)	{
		if WINDOW_OPTION == pauseFlag {
			pauseFlag = WINDOW_PAUSE
		} else {
			pauseFlag = WINDOW_OPTION
		}
	}
	if downedButton(quitBtnId)		:end
	
	// �L�[�R���t�B�O
	repeat keyChangeLen
		if downedButton(keysBeginBtnId+cnt)	{
			if isSelecting(keysBeginBtnId+cnt) {
				if 0 == invalidTime :guiState keysBeginBtnId+cnt, GUI_S_SHOW, false
			} else {
				guiState keysBeginBtnId+cnt, GUI_S_SHOW, true
				invalidTime = 10
				
			}
		}
		if 0 == invalidTime :if isSelecting(keysBeginBtnId+cnt) {
			selKey = getDownedKey()
			if -1 != selKey {
				guiState keysBeginBtnId+cnt, GUI_S_SHOW, false
				keys.cnt = selKey
				registoryKey keys.cnt, 1, 1
				changeGUIText keysBeginBtnId+cnt, getKeyName(keys.cnt)
			}
		}
	loop
	if invalidTime {
		invalidTime--
		if 0 == invalidTime :initKeyboard
	}
	
	// ����
	if downedButton(volumeBtnId) {
		masterVolume = getTrackBarValue(volumeBtnId)
	}
	
	// �`���b�g���ߓx
	if downedButton(chatAlphaBtnId) {
		chatDefaultAlpha = getTrackBarValue(chatAlphaBtnId)
	}
	
	// ��{�F
	if downedButton(rColorBtnId) :configColor = RGB(getTrackBarValue(rColorBtnId), GG(configColor), BB(configColor))
	if downedButton(gColorBtnId) :configColor = RGB(RR(configColor), getTrackBarValue(gColorBtnId), BB(configColor))
	if downedButton(bColorBtnId) :configColor = RGB(RR(configColor), GG(configColor), getTrackBarValue(bColorBtnId))
	if oldClr != clr {
		oldConfigColor = configColor
		gsel blackWndId
		color RR(configColor), GG(configColor), BB(configColor) :boxf
		gsel mainWndId
	}
	
	if oldPauseFlag == pauseFlag :return
	oldPauseFlag = pauseFlag
	
	switch pauseFlag
	case WINDOW_ACTIVE
		selectCanvas CVS_MAIN
		swbreak
		
	case WINDOW_PAUSE
		selectCanvas CVS_PAUSE
		changeGUIText optionBtnId, "�ݒ�"
		changeCanvasId optionBtnId, CVS_PAUSE
		swbreak
		
	case WINDOW_OPTION
		selectCanvas CVS_OPTION
		changeCanvasId optionBtnId, CVS_OPTION
		changeGUIText optionBtnId, "�߂�"
		
		gsel blackWndId
		pget 0, 0
		configColor = RGB(ginfo_r, ginfo_g, ginfo_b)
		oldConfigColor = configColor
		gsel mainWndId
		setTrackBarValue rColorBtnId, RR(configColor)
		setTrackBarValue gColorBtnId, GG(configColor)
		setTrackBarValue bColorBtnId, BB(configColor)
		swbreak
	swend
	
	return
	
	
*_MENU_AS_END
	
	#endif
