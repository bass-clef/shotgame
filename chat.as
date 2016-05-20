	
	#ifndef APPNAME
	#include "shotgame.hsp"
	#endif
	
	#ifndef AS_CHAT
	#define AS_CHAT
	
	#define	makeChatWindow(%1=0, %2=-1)	makeChatWindow__ %1, %2
	
goto *_CHAT_AS_END

	// ���ʂȃL�[�R�[�h���Ď�
#deffunc chatSpecialKeys int _keycode
	
	if false == chatActhivedFlag :return 0
	
	defProcUncallFlag = true
	switch _keycode
	case VK_RETURN
		// �`���b�g���M
		if "" != chatInputLog :chatInputLog += "\n"
		chatBuffer = gtext(hInputWnd)
		chatInputLog += chatBuffer
		
		addChat chatBuffer, myPlayerId :chatType = stat
		if CMD_CHAT == chatType :addChatLog chatBuffer, myPlayerId, true
		logmes "chat type :"+ chatType
		
		chatAlpha = chatDefaultAlpha
		chatInvisible chatDefaultVisibleTime
		swbreak
		
	case VK_ESCAPE
		// �`���b�g�E�B���h�E������\��
		immSetOpenStatus hImc, false
		chatAlpha = 0
		chatVisibleTime = 0
		chatInvisible
		
		pauseWait = 10
		swbreak
	
	case VK_TAB
		// Tab�⊮
		complementCommand chatBuffer
		objprm inputId, chatBuffer
		sendmsg hInputWnd, EM_SETSEL, 0xFFFF, 0xFFFF
		chatActivateFlag = true
		swbreak
	
	default
		complementMax = 0
		defProcUncallFlag = false
		swbreak
	swend
	
	return defProcUncallFlag

#deffunc chatCalc int _wheel
	
	if CVS_MAIN != getSelectCanvasId() :return
	
	if chatVisible {
		chatVisibleTime = chatDefaultVisibleTime
	}
	if false == chatVisible :if chatVisibleTime {
		chatVisibleTime--
	} else :if chatAlpha {
		chatAlpha -= chatAlphaSpeed
	}
	
	// �E�B���h�E�N���b�N�Ń`���b�g�A�N�e�B�u
	if keyDowned(keys.K_SHOT) {
		if false == chatActhivedFlag :if chatVisible :setFocus hInputWnd
	}
	
	// �`���b�g�E�B���h�E�A�N�e�B�x�[�g
	if keyDowned(keys.K_CMD) :if false == chatVisible {
		chatActivateFlag = true
		chatBuffer = "/"
		objprm inputId, chatBuffer
		sendmsg hInputWnd, EM_SETSEL, 0xFFFF, 0xFFFF
	}
	if keyDowned(keys.K_CHAT) :chatActivateFlag = true
	if chatActivateFlag {
		#ifndef TARGET_64BIT
		onkey 1
		#endif
		
		chatActivateFlag = false
		smove xMargin, windowHeight-fSize*2-2-yMargin, hInputWnd
		setFocus hInputWnd
		chatVisible = true
		chatAlpha = chatDefaultAlpha
		
		notesel chatInputLog
		chatIndex = notemax
		makeChatWindow
	}
	
	// ���O���p
	if keyDowned(keys.K_ALLOW_UP) {
		chatAlpha = chatDefaultAlpha
		notesel chatInputLog
		chatIndex = limit(chatIndex-1, 0, notemax)
		noteget@hsp chatBuffer, chatIndex
		objprm inputId, chatBuffer
		sendmsg hInputWnd, EM_SETSEL, 0xFFFF, 0xFFFF
		makeChatWindow
	}
	if keyDowned(keys.K_ALLOW_DOWN) {
		chatAlpha = chatDefaultAlpha
		notesel chatInputLog
		chatIndex = limit(chatIndex+1, 0, notemax)
		noteget@hsp chatBuffer, chatIndex
		objprm inputId, chatBuffer
		sendmsg hInputWnd, EM_SETSEL, 0xFFFF, 0xFFFF
		makeChatWindow
	}
	
	// ���O�ړ�
	if _wheel < 0 :if chatScrollIndex {
		chatScrollIndex--
		chatAlpha = chatDefaultAlpha
		chatVisibleTime = chatDefaultVisibleTime
		makeChatWindow
	}
	if 0 < _wheel :if chatScrollIndex < chatScrollMax {
		chatScrollIndex++
		chatAlpha = chatDefaultAlpha
		chatVisibleTime = chatDefaultVisibleTime
		makeChatWindow
	}
	
	// Control+tab�̌��o
	if getkey(VK_CONTROL) && 0x8000 :if keyDowned(keys.K_TAB) {
		// Tab�⊮back
		complementCommand chatBuffer
		objprm inputId, chatBuffer
		sendmsg hInputWnd, EM_SETSEL, 0xFFFF, 0xFFFF
		chatActivateFlag = true
	}
	
	return
	
	// �`���b�g�E�B���h�E�̍쐬
#deffunc makeChatWindow__ int _make, int _partActivate
	
	if _make {
		chatScrollIndex = 0
	}
	count = -chatScrollIndex
	x = loword(chatPos)
	y = hiword(chatPos)
	chatTmpCount = getListEnd(chat)
	while -1 != chatTmpCount
		if isBlankId(chatTmpCount, chatCount, chat) :chatTmpCount = getListBack(chatTmpCount, chat) :_continue
		if 0 <= count && count < chatHeightLength {
			if _make :chatScrollMax = chatTmpCount
			
			y -= hiword(getGUIObjectSize(chatIdList.chatTmpCount)) + chatLineMargin
			pos x, y :moveGUIObject chatIdList.chatTmpCount
			guiState chatIdList.chatTmpCount, GUI_S_SHOW
		} else {
			guiState chatIdList.chatTmpCount, GUI_S_HIDE
		}
		count += hiword(getGUIObjectSize(chatIdList.chatTmpCount)) / (fSize*2)
		if -1 == _partActivate || chatTmpCount == _partActivate {
			setGUIBackAlpha chatIdList.chatTmpCount, chatAlpha
			setGUItextAlpha chatIdList.chatTmpCount, double(chatAlpha) / chatDefaultAlpha * (255-(255-chatDefaultAlpha))
		}
		chatTmpCount = getListBack(chatTmpCount, chat)
	wend
	
	return
	
	// �`���b�g�`��
#deffunc chatDraw
	
	repeat chatCount
		if isBlankId(cnt, chatCount, chat) :continue
		if getGUIBackAlpha(chatIdList.cnt) <= 0 {
			guiState chatIdList.cnt, GUI_S_HIDE
		} else :if 0 == chatVisibleTime {
			subGUIBackAlpha chatIdList.cnt, chatAlphaSpeed
			subGUITextAlpha chatIdList.cnt, chatAlphaSpeed
		}
	loop
	
	return
	
	
	// �`���b�g���O�ɒǉ�
#deffunc addChatLog str _message, int _playerId, int _allRedraw

	if chatLogThrought :return
	
	sdim chatInfo
	
	logmes "addChatLog ["+_playerId+"] my["+ myPlayerId +"] n["+ getPlayerName(_playerId) +"]"
	chatInfo = "["+ getPlayerName(_playerId) +"] "
	
	if "" != chatLog :if strmid(chatLog, strlen(chatLog)-2, 2) != "\n" :chatLog += "\n"
	chatLog += chatInfo + _message
	logmes ""+ chatInfo + _message
	
	selectCanvas CVS_MAIN
	chatId = pushListFront(getListEnd(chat), chat)
	guiOption chatWidth, chatHeight, GUI_S_HIDE
	pos loword(chatPos), hiword(chatPos)
	makeText ""+ chatInfo + _message :chatIdList.chatId = stat
	
	if _allRedraw {
		makeChatWindow true
	} else {
		makeChatWindow true, chatId
	}
	
	if false == chatVisible {
		chatInvisible chatDefaultVisibleTime
	}
	
	return
	
	// �`���b�g�E�B���h�E�𖳌���
#deffunc chatInvisible int _chatVisibleTime

	if false == chatVisible :return
	
	#ifndef TARGET_64BIT
	onkey 0
	#endif
	
	complementMax = 0
	
	chatDeleteFlag = false
	chatVisibleTime = _chatVisibleTime
	chatVisible = false
	setFocus hMainWnd
	smove 0, -viewMainHeight, hInputWnd
	
	makeChatWindow true, -2
	
	sdim chatBuffer
	
	return
	
#deffunc beginWatchChatLog
	
	notesel@hsp chatLog
	beginChatLogLength = notemax
	
	return beginChatLogLength

	// �`���b�g���O�������߂�
#deffunc rollbackChatLog__ int _length

	if -1 != _length {
		beginChatLogLength = _length
	}
	
	notesel@hsp chatLog
	if notemax == beginChatLogLength :return
	len = notemax-beginChatLogLength
	
	logmes "chatRollback : "+ len +"/"+ notemax
	if len == notemax {
		chatLog = ""
		repeat len
			chatId = getListEnd(chat)
			destroyGUIObject chatIdList.chatId
			eraseList chatId, chat
		loop
	} else {
		repeat len
			notesel@hsp chatLog
			notedel@hsp notemax-1
			chatId = getListEnd(chat)
			destroyGUIObject chatIdList.chatId
			eraseList chatId, chat
		loop
	}
	
	len = strlen(chatLog)
	if strmid(chatLog, len-2, 2) == "\n" :poke chatLog, len-2, 0
	
	beginWatchChatLog
	
	makeChatWindow true
	
	return

#deffunc putChat int _chatType, str _message, int _playerId
	
	message = _message
	len = strlen(message)
	
	putPacketRule PACKET_TYPE_RECVCHAT, _playerId
	putPacketInt _chatType
	putPacketInt len
	putPacket message, 0, len, socketId
	
	return
	
#deffunc sendChatToClient int _chatType, str _message, int _playerId, int _toPlayerId

	// �`���b�g�������M��� playerId �ɐݒ�
	putChat _chatType, _message, _playerId
	sendPacket clientSocketList._toPlayerId
	
	return
	
	
#deffunc addChat str _message, int _playerId
	
	findCommandEx _message, _playerId :st = stat
	if CMD_ERROR == st :return st
	chat st, _message, _playerId
	
	return st
	
	// �`���b�g���M
#deffunc chat int _chatType, str _message, int _playerId
	
	// �`���b�g�������M��� playerId �ɐݒ�
	putChat _chatType, _message, _playerId
	
	switch bootmode
	case BM_SERVER
		// �S���ɑ��M
		repeat playerCount
			if isBlankId(cnt, playerCount, player) || cnt == _playerId :continue	// ��M�������ɂ͑���Ȃ�
			sendPacket clientSocketList.cnt, true
		loop
		DeletePacketData
		
		swbreak
		
	case BM_CLIENT
		// �I�ɑ��M
		sendPacket mainSocket
		swbreak
	swend
	
	return
	
	// �`���b�g��M
#deffunc recvChat int _chatType, str _message, int _playerId
	
	findCommandEx _message, _playerId
	
	switch bootmode
	case BM_SERVER
		// �������M _playerId �����M��
		chat _chatType, _message, _playerId
	
		chatAlpha = chatDefaultAlpha
		chatVisibleTime = chatDefaultVisibleTime
		addChatLog _message, _playerId
		
		swbreak
		
	case BM_CLIENT
		// �I�����M _playerId �����M��
		if CMD_CHAT != _chatType :swbreak
		chatAlpha = chatDefaultAlpha
		chatVisibleTime = chatDefaultVisibleTime
		addChatLog _message, _playerId
		
		swbreak
	swend
	
	return
	
	// �R�}���hID�𕶎���Ō���
	#define ctype isNumber(%1)	('0' <= (%1) && (%1) <= '9')
	#define addCmd(%1, %2, %3, %4, %5=0)		_labelVar = %3 : addCmd__ %1, %2, _labelVar, %4, %5
#defcfunc findCmdId str _cmdName
	selId = -1
	repeat commandCount
		if isBlankId(cnt, commandCount, command) :continue
		if _cmdName == cmdList.cnt :selId = cnt :break
	loop
	if -1 == selId {
		addChatLog "�w�肵���R�}���h��������܂���ł���", ID_SERVER
	}
	return selId
	
	// �����̃��x��������
#defcfunc findOPLevelId int _level
	selId = -1
	repeat opCount
		if isBlankId(cnt, opCount, op) :continue
		if _level == commandLevelId.cnt :selId = cnt :break
	loop
	if -1 == selId {
		addChatLog "�w�肵�����x����������܂���ł���", ID_SERVER
	}
	return selId
	
	// OP�������v���C���[�ɕt�^
#deffunc addOP int _playerId, int _level
	if isBlankId(_level, opCount, op) {
		addChatLog "�w�肵�����x����������܂���ł���", ID_SERVER
		return
	}
	playerCommandLevel._playerId = _level
	addChatLog ""+ getPlayerName(_playerId) +"�Ƀ��x��"+ _level +"�̃R�}���h������^���܂���", ID_SERVER
	return
	
	// �v���C���[����OP�����𔍒D
#deffunc removeOPFromPlayer int _playerId
	playerCommandLevel._playerId = COMMAND_DEFAULT_LEVEL
	addChatLog ""+ getPlayerName(_playerId) +"�̃R�}���h���������������܂���", ID_SERVER
	return
	
	// OP�������쐬
#deffunc makeOPLevel int _level
	newId = getBlankId(opCount, op, opMax)
	commandLevel.newId = ""
	commandPlayer.newId = ID_SELF
	commandLevelId.newId = _level
	return newId
	
	// OP�������폜
#deffunc deleteOPLevel int _levelId
	repeat playerCount
		if isBlankId(cnt, playerCount, player) :continue
		if playerCommandLevel.cnt != commandLevelId._levelId :continue
		removeOPFromPlayer cnt
	loop
	setBlankId _levelId, op
	addChatLog "���x��"+ commandLevelId._levelId +"�̃R�}���h�������폜���܂���", ID_SERVER
	return
	
	// �R�}���h���x���폜
#deffunc removeOPLevelFromCmdId int _levelId, int _commandId
	levelId_ = _levelId
	if isBlankId(_levelId, opCount, op) {
		makeOPLevel _levelId
		levelId_ = stat
	}
	ssFalse commandLevel.levelId_, _commandId
	return
	
	// �R�}���h���x���ǉ�
#deffunc setOPLevelFromCmdId int _levelId, int _commandId
	levelId_ = _levelId
	if isBlankId(_levelId, opCount, op) {
		makeOPLevel _levelId
		levelId_ = stat
	}
	if -1 == _commandId {
		repeat commandCount
			if isBlankId(cnt, commandCount, command) :continue
			ssTrue commandLevel.levelId_, cnt
		loop
		addChatLog "���x��"+ commandLevelId.levelId_ +"�ɂ��ׂẴR�}���h�̎��s������t�^���܂���", ID_SERVER
	} else {
		ssTrue commandLevel.levelId_, _commandId
		addChatLog "���x��"+ commandLevelId.levelId_ +"��"+ cmdList._commandId +"�����s�ł���悤�ɂ��܂���", ID_SERVER
	}
	return
#deffunc setOPLevel int _level, str _command
	cmdId = findCmdId(_command)
	levelId_ = findOPLevelId(_level)
	if -1 == levelId_ :makeOPLevel _level :levelId_ = stat
	setOPLevelFromCmdId levelId_, cmdId
	return
	
	// �v���C���[���w��̃R�}���h�̌����������Ă��邩�ǂ���
#defcfunc hadCommandLevel int _playerId, str _command
	if ID_SERVER == _playerId :return true
	if _playerId < ID_SERVER :return false
	
	cmdId = findCmdId(_command)
	levelId_ = findOPLevelId(playerCommandLevel._playerId)
	if -1 == levelId_ {
		addChatLog "�����Ȍ������x�����g�p���Ď��s���܂���", ID_SERVER
		return false
	}
	return sbGet(commandLevel.levelId_, cmdId)
	
	// �R�}���h�̑Ώۂɂł���v���C���[��ݒ�
#deffunc setCommandLevelPlayer int _levelId, int _playerId
	levelId_ = _levelId
	if isBlankId(_levelId, opCount, op) {
		makeOPLevel _levelId
		levelId_ = stat
	}
	commandPlayer.levelId_ = _playerId
	
	addChatLog "���x��"+ commandLevelId.levelId_ +"��"+ getPlayerName(_playerId) +"�ɑ΂��Ď��s�ł���悤�ɂ��܂���", ID_SERVER
	
	return
	
	// �v���C���[���R�}���h�̑Ώۂɂł��邩�ǂ���
#defcfunc hadCommandLevelPlayer int _playerId, int _toPlayerId
	if ID_SERVER == _playerId :return true
	levelId_ = findOPLevelId(playerCommandLevel._playerId)
	if -1 == levelId_ {
		addChatLog "�����Ȍ������x�����g�p���Ď��s���܂���", ID_SERVER
		return false
	}
	
	if ID_SERVER == commandPlayer.levelId_ :return true
	if ID_SELF == commandPlayer.levelId_ :return _playerId == _toPlayerId
	
	return commandPlayer.levelId_ == _toPlayerId

	
#defcfunc matchChildParam int _playerId, int _childId, str _token
	front = peek(cmdChildParam._childId, 0)
	cmdChildParamText = strmid(cmdChildParam._childId, 1, INT_MAX)
	match_ = true
	switch front
	case '='
		if cmdChildParamText == _token :swbreak
		match_ = false
		swbreak
	
	case '?'
		token_ = _token
		if -1 != instr(cmdChildParamText, 0, ":") {
			sdim defaultParam
			split cmdChildParamText, ":", defaultParam
			if 2 == length(defaultParam) {
				cmdChildParamText = defaultParam.0
				if "" == token_ :token_ = defaultParam.1
			}
		}
		matchChildParamQuestion _playerId, _toPlayerId, token_
		swbreak

	case '+'
		matchChildParamAdd _playerId, _toPlayerId, _token
		swbreak
		
	case '&'
		beginWatchChatLog
		matchChildParamQuestion _playerId, _toPlayerId, _token
		if match_ :swbreak
		rollbackChatLog
		
		match_ = true
		matchChildParamAdd _playerId, _toPlayerId, _token
		swbreak
		
	swend
	return match_
	
#deffunc matchChildParamQuestion int _playerId, int _childId, str _token
	id = -1
	switch cmdChildParamText
	case "team"		:id = findTeamId(_token)		:swbreak
	case "player"
		id = findPlayerId(_token)
		if -1 != id :if false == hadCommandLevelPlayer(_playerId, id) {
			addChatLog "�Ώۂɑ΂��Ď��s���錠��������܂���", ID_SERVER
			id = -1
		}
		swbreak
	case "whiteplayer"	:id = findWhiteListId(_token)	:swbreak
	case "blackplayer"	:id = findBlackListId(_token)	:swbreak
	case "cmd"
		id = findCmdId(_token)
		if -1 != id :if false == hadCommandLevel(_playerId, cmdList.id) {
			addChatLog "�R�}���h"+ cmdList.id +"�����s���錠��������܂���", ID_SERVER
			id = -1
		}
		swbreak
	case "level"	:id = findOPLevelId(int(_token))	:swbreak
	swend
	if -1 == id {
		match_ = false
		return
	}
	matchParam = str(id)
	return
	
#deffunc matchChildParamAdd int _playerId, int _childId, str _token
	matchParam = _token
	switch cmdChildParamText
	case "number"
		l = strlen(_token)
		repeat l
			if not( isNumber(peek(matchParam, cnt)) ) :match_ = false :break
		loop
		swbreak
		
	default
		// +hoge �� hoge ��tab�⊮�Ɏg�p����邽��
		// +hoge �� hoge �� number �ȊO�͕������z�肵�Ďw�肳��Ă���
		swbreak
	swend
	
	return
	
	// �R�}���h�̕��@�`�F�b�N�Ǝ��s
#deffunc findCommandEx str _message, int _playerId
	
	cmdBuffer = _message
	if '/' != peek(cmdBuffer, 0) :return CMD_CHAT
	
	cmd_result = CMD_ERROR
	
	sdim cmdToken
	split cmdBuffer, " ", cmdToken
	cmdTokenLen = length(cmdToken)
	
	logmes "find from:"+ _playerId +" cmd["+ _message +"]"
	repeat commandCount
		if isBlankId(cnt, commandCount, command) :continue
		
		if cmdList.cnt != cmdToken.0 :continue
		
		// �q������T��
		for i, 0, cmdChildCountList.cnt, 1
			childId = lpeek(cmdChildList.cnt, i*4)
			
			sdim cmdChildParam
			split cmdParamList.childId, " ", cmdChildParam
			cmdChildParamLen = length(cmdChildParam)
			if "" == cmdChildParam :cmdChildParamLen = 0
			if cmdTokenLen-1 != cmdChildParamLen :_continue
			match = false
			
			beginWatchChatLog
			if _playerId != myPlayerId :chatLogThrought = cmdLogThroughtList.childId
			
			sdim chatParamList :chatParamCount = 0
			for j, 0, cmdChildParamLen, 1
				match = false
				matchParam = ""
				tokenId = j+1
				if matchChildParam(_playerId, j, cmdToken.tokenId) :match = true
				if false == match :_break
				// �����X�^�b�N�ɐς�
				if strlen(matchParam) {
					chatParamList.chatParamCount = matchParam
					chatParamCount++
				}
			next
			
			if cmdChildParamLen && false == match {
				rollbackChatLog
			} else :if j == cmdChildParamLen {
				// ���ׂĂ̎q�����Ɉ�v
				// �q�������Ȃ����͖̂������Ƃ��Ă����ɂ���
				if hadCommandLevel(_playerId, cmdList.cnt) {
					cmdPlayerId = _playerId
					gosub cmdLabelList.childId
					if CMD_ERROR == stat {
						cmd_result = CMD_ERROR
						logmes "error ["+ cmdList.cnt +"] child["+ childId +"] pid["+ _playerId +"] ["+ _message +"]"
					} else {
						cmd_result = CMD_ANY + cnt
						logmes "run ["+ cmdList.cnt +"] child["+ childId +"] pid["+ _playerId +"] ["+ _message +"]"
					}
				} else {
					if _playerId == myPlayerId {
						addChatLog "�R�}���h"+ cmdList.cnt +"�����s���錠��������܂���", ID_SERVER
					}
					cmd_result = CMD_ERROR
				}
				chatLogThrought = false
				_break
			}
			chatLogThrought = false
		next
		if CMD_ERROR != cmd_result :break
	loop
	
	return cmd_result
	
#deffunc addCmd__ str _cmdName, str _cmdParam, var _jumpLabel, str _helpText, int _throughtFlag
	
	newFlag = false
	cmdId = -1
	repeat commandCount
		if isBlankId(cnt, commandCount, command) :continue
		if _cmdName == cmdList.cnt :cmdId = cnt :break
	loop
	if -1 == cmdId {
		cmdId = getBlankId(commandCount, command, commandMax)
		newFlag = true
	
		cmdList.cmdId = _cmdName
		cmdChildCountList.cmdId = 0
		cmdChildList.cmdId = ""
	}
	
	cmdChildId = getBlankId(commandChildCount, commandChild, commandChildMax)
	
	memexpand cmdChildList.cmdId, (cmdChildCountList.cmdId+1)*4+1
	lpoke cmdChildList.cmdId, cmdChildCountList.cmdId*4, cmdChildId
	cmdChildCountList.cmdId++
	
	cmdParamList.cmdChildId			= _cmdParam
	cmdLabelList.cmdChildId			= _jumpLabel
	cmdHelpTextList.cmdChildId		= _helpText
	cmdLogThroughtList.cmdChildId	= _throughtFlag
	
	return
	
#deffunc pushComplementParam str _str
	
	found = false
	repeat complementCommandCount
		if _str == complementCommandList.cnt :found = true :break
	loop
	if found :return
	
	complementCommandList.complementCommandCount = _str
	complementCommandCount++
	return

	// �R�}���h�̕⊮
#deffunc complementCommand str _message
	
	cmdBuffer = _message
	
	// complementCommandList�ɂ͍��������i�[
	sdim cmdToken
	split cmdBuffer, " ", cmdToken
	cmdTokenLen = length(cmdToken)
	
	if 0 == complementMax {
		sdim complementCommandList :complementCommandCount = 0
	}
	
	if complementMax {
		// �O��̌��Q��
	} else :if "" == cmdBuffer {
		// �S�e�\��
		repeat commandCount
			if isBlankId(cnt, commandCount, command) :continue
			if false == hadCommandLevel(myPlayerId, cmdList.cnt) :continue
			pushComplementParam cmdList.cnt
		loop
	} else {
		sdim prevChildText
		switch cmdTokenLen
		case 1
			// �e�T��
			repeat commandCount
				if isBlankId(cnt, commandCount, command) :continue
				if false == hadCommandLevel(myPlayerId, cmdList.cnt) :continue
				if 0 == instr(cmdList.cnt, 0, cmdBuffer) {
					pushComplementParam cmdList.cnt
				}
			loop
			swbreak
	
		default
			// �e+�q�T��
			cmdId = -1
			repeat commandCount
				if isBlankId(cnt, commandCount, command) :continue
				if false == hadCommandLevel(myPlayerId, cmdList.cnt) :continue
				if 0 == instr(cmdBuffer, 0, cmdList.cnt) :cmdId = cnt :break
			loop
			if -1 == cmdId :swbreak
	
			prmId = cmdTokenLen-2	// �Ō�̗v�f��������
			prevChildText = cmdToken.0
			repeat limit(prmId, 0, INT_MAX), 1	// �Ō�̗v�f�ȊO������
				prevChildText += " "+ cmdToken.cnt
			loop
			
			repeat cmdChildCountList.cmdId	// �q�̐������T��
				childId = lpeek(cmdChildList.cmdId, cnt*4)
				
				sdim cmdChildParam
				split cmdParamList.childId, " ", cmdChildParam
				cmdChildParamLen = length(cmdChildParam)
				if cmdChildParamLen <= prmId :continue
	
				// ����܂ł̎q�v�f�̏��������v���Ă��邩
				match = true
				beginWatchChatLog
				repeat limit(cmdChildParamLen, 0, prmId)
					if false == matchChildParam(myPlayerId, cnt, cmdToken(cnt+1)) :match = false :break
				loop
				rollbackChatLog
				if false == match :continue
				
				tokenId	= prmId+1
				tokenBlankFlag = false
				if "" == cmdToken.tokenId :tokenBlankFlag = true	// �q�����̒T���ɂȂɂ����͂���Ă��Ȃ�����S�\��
				
				front = peek(cmdChildParam.prmId, 0)
				cmdChildParamText = strmid(cmdChildParam.prmId, 1, INT_MAX)
				switch front
				case '='
					if tokenBlankFlag || -1 != instr(cmdChildParamText, 0, cmdToken.tokenId) {
						pushComplementParam cmdChildParamText
					}
					swbreak
	
				case '?'
					if -1 != instr(cmdChildParamText, 0, ":") {
						sdim defaultParam
						split cmdChildParamText, ":", defaultParam
						if 2 == length(defaultParam) {
							cmdChildParamText = defaultParam.0
							pushComplementParam defaultParam.1
						}
					}
					complementCommandChildQuestion
					swbreak
	
				case '+'
					complementCommandChildAdd
					swbreak
					
				case '&'
					complementCommandChildQuestion
					complementCommandChildAdd
					swbreak
				swend
				
			loop
		swend
	}
	
	if complementCommandCount {
		if complementMax {
			if getkey(VK_CONTROL) & 0x8000 {
				complementCount = (complementCount+(complementMax-1))\complementMax
			} else {
				complementCount = (complementCount+1)\complementMax
			}
		}else {
			str_ = complementCommandList.0
			repeat limit(complementCommandCount-1, 0, INT_MAX), 1
				str_ += " "+ complementCommandList.cnt
			loop
	
			chatLogSender = ""+ cmdBuffer +"]["+ complementCommandCount +""
			addChatLog ""+ str_, ID_TEXT
			complementCount = 0
			complementMax = length(complementCommandList)
		}
		if strlen(prevChildText) {
			chatBuffer = prevChildText +" "+ complementCommandList.complementCount
		} else {
			chatBuffer = complementCommandList.complementCount
		}
	}
	
	return
	
#deffunc complementCommandChildQuestion
	switch cmdChildParamText
	case "team"
		repeat teamCount
			if isBlankId(cnt, teamCount, team) :continue
			if tokenBlankFlag || -1 != instr(teamNameList.cnt, 0, cmdToken.tokenId) {
				pushComplementParam teamNameList.cnt
			}
		loop
		swbreak
	case "whiteplayer"
		repeat whiteListCount
			if isBlankId(cnt, whiteListCount, whiteList) :continue
			if tokenBlankFlag || -1 != instr(whiteListName.cnt, 0, cmdToken.tokenId) {
				pushComplementParam whiteListName.cnt
			}
		loop
		swbreak
	case "blackplayer"
		repeat blackListCount
			if isBlankId(cnt, blackListCount, blackList) :continue
			if tokenBlankFlag || -1 != instr(blackListName.cnt, 0, cmdToken.tokenId) {
				pushComplementParam blackListName.cnt
			}
		loop
		swbreak
	case "player"
		repeat playerCount
			if isBlankId(cnt, playerCount, player) :continue
			if false == hadCommandLevelPlayer(myPlayerId, cnt) :continue
			if tokenBlankFlag || -1 != instr(playerNameList.cnt, 0, cmdToken.tokenId) {
				pushComplementParam playerNameList.cnt
			}
		loop
		swbreak
	case "cmd"
		repeat commandCount
			if isBlankId(cnt, commandCount, command) :continue
			if false == hadCommandLevel(myPlayerId, cmdList.cnt) :continue
			if tokenBlankFlag || -1 != instr(cmdList.cnt, 0, cmdToken.tokenId) {
				pushComplementParam cmdList.cnt
			}
		loop
		swbreak
	case "level"
		repeat opCount
			if isBlankId(cnt, opCount, op) :continue
			str_ = str(commandLevelId.cnt)
			if tokenBlankFlag || -1 != instr(str_, 0, cmdToken.tokenId) {
				pushComplementParam str_
			}
		loop
		swbreak
	swend
	return
	
#deffunc complementCommandChildAdd
	switch cmdChildParamText
	case "x" :pushComplementParam ""+limit(mousex-xBase, 0, INT_MAX) :swbreak
	case "y" :pushComplementParam ""+limit(mousey-yBase, 0, INT_MAX) :swbreak
	case "tipx"
		emx = (mousex-xBase)/mapTipWidth+xMapEditBase
		pushComplementParam ""+emx
		swbreak
	case "tipy"
		emy = (mousey-yBase)/mapTipHeight+yMapEditBase
		pushComplementParam ""+emy
		swbreak
	case "mapx"	:pushComplementParam str(myMapXPos)	:swbreak
	case "mapy"	:pushComplementParam str(myMapYPos)	:swbreak
	default
		if tokenBlankFlag {
			pushComplementParam "+"+ cmdChildParamText
		}
	swend
	return
	
#deffunc initCommandEx
	
	// / ����������̓R�}���h
	sdim cmdList
	sdim cmdChildCountList
	sdim cmdChildList
	sdim cmdParamList
	sdim cmdHelpTextList
	sdim cmdResultList
	sdim cmdLogThroughtList
	complementCount = 0 :complementMax = 0
	
	parameterHelp = {"
	--tab�ŃR�}���h�̕⊮���ł��܂�--
	--�����̐���--
	= ����������Ɉ�v���Ă邩
	? ����������ɂ���Č���
	\t: [?type:�f�t�H���g] �����񂪂Ȃ��ƃf�t�H���g���g�p
	+ ����������̓^�C�v
		name   ������
		number 0-9 �ō\������Ă��鐔��
		[hoge] �w�肳��Ă��鉽��
	& [?]��[+]��g�ݍ��킹������"}
	
	addCmd "/blacklist", "=remove ?blackplayer", *cmd_blacklist_remove, "�u���b�N���X�g�ɒǉ����܂�", true
	addCmd "/blacklist", "=add +name", *cmd_blacklist_add, "�u���b�N���X�g�ɒǉ����܂�", true
	addCmd "/blacklist", "?player", *cmd_blacklist_player, "�u���b�N���X�g�ɒǉ����܂�", true
	addCmd "/blacklist", "=true", *cmd_blacklist_true, "�u���b�N���X�g��L���ɂ��܂�", true
	addCmd "/blacklist", "=false", *cmd_blacklist_false, "�u���b�N���X�g�𖳌��ɂ��܂�", true
	
	addCmd "/cls", "+startIndex", *cmd_cls_index, "�`���b�g���O���������܂�"
	addCmd "/cls", "", *cmd_cls_all, "�`���b�g���O��S�������܂�"
	
	addCmd "/color", "=player ?player +r +g +b", *cmd_color_player, "player �̐F�� r, g, b �ɕύX���܂�"
	addCmd "/color", "=player ?player +rgb", *cmd_color_player_rgb, "player �̐F�� rgb �ɕύX���܂�"
	addCmd "/color", "=team ?team +r +g +b", *cmd_color_team, "team�̐F�� r, g, b �ɕύX���܂�"
	addCmd "/color", "=team ?team +rgb", *cmd_color_team_rgb, "team�̐F�� rgb �ɕύX���܂�"
	
	addCmd "/fill", "=set +tipx +tipy +tipx +tipy +tipId", *cmd_fill_set, "�}�b�v�`�b�v�𕡐��ݒu���܂�", true
	addCmd "/fill", "=remove +tipx +tipy +tipx +tipy", *cmd_fill_remove, "�}�b�v�`�b�v�𕡐��폜���܂�", true
	
	addCmd "/help", "?cmd", *cmd_help_cmd, "cmd �̏ڍׂ����܂�", true
	addCmd "/help", "", *cmd_help_help, parameterHelp, true
	
	addCmd "/kick", "?player", *cmd_player_kick, "�v���C���[���L�b�N���܂�", true
	
	addCmd "/kill", "?player", *cmd_kill_player, "player �����낱�낵�܂�"
	addCmd "/kill", "", *cmd_kill_self, "���Q���܂�"
	
	addCmd "/mapedit", "=true", *cmd_mapedit_true, "�}�b�v�ҏW��L���ɂ��܂�", true
	addCmd "/mapedit", "=false", *cmd_mapedit_false, "�}�b�v�̕ҏW�𖳌��ɂ��܂�", true
	
	addCmd "/op", "=add ?player ?level", *cmd_op_add, "�v���C���[�Ɏw�背�x���̃R�}���h�̌�����t�^���܂�"
	addCmd "/op", "=remove ?player", *cmd_op_remove, "�v���C���[�̃R�}���h���������������܂�"
	addCmd "/op", "=delete ?level", *cmd_op_delete, "�Ώۂ̌������x�����폜���܂�"
	addCmd "/op", "=level ?level =list", *cmd_op_level_list, "�Ώۃ��x���ɕt�^����Ă���R�}���h������\�����܂�"
	addCmd "/op", "=level &level ?cmd", *cmd_op_level_cmd, "���x���ň�����R�}���h��ݒ肵�܂��A�����l��0"
	addCmd "/op", "=level &level =full", *cmd_op_level_full, "���x���ň�����R�}���h�̌�����S�R�}���h�ɂ��܂�"
	addCmd "/op", "=level &level =self", *cmd_op_level_player_self, "���x���őΏۂɂł���v���C���[�����g�݂̂ɂ��܂�"
	addCmd "/op", "=level &level ?player", *cmd_op_level_player_player, "���x���őΏۂɂł���v���C���[��ݒ肵�܂�"
	addCmd "/op", "=level &level =all", *cmd_op_level_player_all, "���x���őΏۂɂł���v���C���[�����ׂĂɂ��܂�"
	
	addCmd "/player", "=add ?player =whitelist", *cmd_whitelist_add, "�z���C�g���X�g�ɒǉ����܂�", true
	addCmd "/player", "=add ?player =blacklist", *cmd_blacklist_add, "�u���b�N���X�g�ɒǉ����܂�", true
	addCmd "/player", "=add +name =AI", *cmd_player_add_ai, "AI��ǉ����܂�"
	addCmd "/player", "=kick ?player", *cmd_player_kick, "�v���C���[���L�b�N���܂�", true
	addCmd "/player", "=target ?player", *cmd_player_target, "�v���C���[�̎��_�ɐ؂�ւ��܂�", true
	addCmd "/player", "=target", *cmd_player_target_server, "���R���_�ɐ؂�ւ��܂�", true
	
	addCmd "/team", "=add +name", *cmd_team_add, "name ���쐬���܂�"
	addCmd "/team", "=remove ?team", *cmd_team_remove, "team ���폜���܂�"
	addCmd "/team", "=join ?team ?player", *cmd_team_join, "team �� player ��ǉ����܂�"
	addCmd "/team", "=leave ?team ?player", *cmd_team_leave, "team ���� player ���폜���܂�"
	addCmd "/team", "=list", *cmd_team_list, "team �ꗗ��\�����܂�", true
	
	addCmd "/tip", "=set +tipx +tipy +itemId", *cmd_tip_set, "�}�b�v�`�b�v��ݒu���܂�", true
	addCmd "/tip", "=remove +tipx +tipy", *cmd_tip_remove, "�}�b�v�`�b�v���폜���܂�", true
	
	addCmd "/tp", "?player ?player", *cmd_tp_toplayer, "�w��̃v���C���[�ɓ]�ڂ��܂����܂�", true
	addCmd "/tp", "?player +x +y +mapx +mapy", *cmd_tp_pos, "�v���C���[�̈ʒu��ύX���܂�", true
	
	addCmd "/whitelist", "=remove ?whiteplayer", *cmd_whitelist_remove, "�z���C�g���X�g�ɒǉ����܂�", true
	addCmd "/whitelist", "=add +name", *cmd_whitelist_add, "�z���C�g���X�g�ɒǉ����܂�", true
	addCmd "/whitelist", "?player", *cmd_whitelist_player, "�z���C�g���X�g�ɒǉ����܂�", true
	addCmd "/whitelist", "=true", *cmd_whitelist_true, "�z���C�g���X�g��L���ɂ��܂�", true
	addCmd "/whitelist", "=false", *cmd_whitelist_false, "�z���C�g���X�g�𖳌��ɂ��܂�", true
	
	addCmd "/worldspawn", "=list", *cmd_worldspawn_list, "���X�|�[�����W�̈ꗗ��\�����܂�", true
	addCmd "/worldspawn", "=set +x +y +mapx +mapy ?team:������", *cmd_worldspawn_map_set, "���X�|�[�����W�ƃ}�b�v���W��ύX���܂�", true
	addCmd "/worldspawn", "=add +x +y +mapx +mapy ?team:������", *cmd_worldspawn_map_add, "���X�|�[�����W�ƃ}�b�v���W��ǉ����܂�", true
	addCmd "/worldspawn", "=remove +x +y +mapx +mapy ?team:������", *cmd_worldspawn_map_remove, "���X�|�[�����W�ƃ}�b�v���W���폜���܂�", true
	addCmd "/worldspawn", "=set +x +y", *cmd_worldspawn_set, "���X�|�[�����W��ύX���܂�", true
	addCmd "/worldspawn", "=add +x +y", *cmd_worldspawn_add, "���X�|�[�����W��ǉ����܂�", true
	addCmd "/worldspawn", "=remove +x +y", *cmd_worldspawn_remove, "���X�|�[�����W���폜���܂�", true
	addCmd "/worldspawn", "+x +y", *cmd_worldspawn_set, "���X�|�[�����W��ύX���܂�", true
	addCmd "/worldspawn", "", *cmd_worldspawn_set_self, "���X�|�[�����W��ύX���܂�", true
	
	
	return

*cmd_blacklist_true
	blackListFlag = true
	addChatLog "�u���b�N���X�g��L���ɂ��܂���", ID_SERVER
	return true
*cmd_blacklist_false
	blackListFlag = false
	addChatLog "�u���b�N���X�g�𖳌��ɂ��܂���", ID_SERVER
	return true
*cmd_blacklist_remove
	setBlankId int(chatParamList.0), blackList
	addChatLog ""+ blackListName.int(chatParamList.0) +"���u���b�N���X�g����폜���܂���", ID_SERVER
	return true
*cmd_blacklist_add
	newId = getBlankId(blackListCount, blackList, blackListMax)
	blackListName.newId = chatParamList.0
	blackListIP.newId = 0
	addChatLog ""+ chatParamList.0 +"���u���b�N���X�g�ɒǉ����܂���", ID_SERVER
	return true
*cmd_blacklist_player
	newId = getBlankId(blackListCount, blackList, blackListMax)
	blackListName.newId = playerNameList.int(chatParamList.0)
	blackListIP.newId = playerIPList.int(chatParamList.0)
	addChatLog ""+ getPlayerName(int(chatParamList.0)) +"���u���b�N���X�g�ɒǉ����܂���", ID_SERVER
	return true
*cmd_cls_index
	rollbackChatLog int(chatParamList.0)
	return true
*cmd_cls_all
	rollbackChatLog 0
	return true
*cmd_color_player
	chatParamList.1 = str(RGB(int(chatParamList.1), int(chatParamList.2), int(chatParamList.3)))
*cmd_color_player_rgb
	changeColor int(chatParamList.0), COLOR_TYPE_PLAYER, int(chatParamList.1)//, true
	return true
*cmd_color_team
	chatParamList.1 = str(RGB(int(chatParamList.1), int(chatParamList.2), int(chatParamList.3)))
*cmd_color_team_rgb
	changeColor int(chatParamList.0), COLOR_TYPE_TEAM, int(chatParamList.1)//, true
	return true
	
*cmd_fill_set
	mapLoading = true
	gsel backWndId
	gmode 4,,, 255 :color 0, 117, 117
	for i, int(chatParamList.1), int(chatParamList.3)+1, 1
		repeat int(chatParamList.2)-int(chatParamList.0)+1, int(chatParamList.0)
			map(cnt, i) = int(chatParamList.4)
			mapTipDraw cnt, i, map(cnt, i)
		loop
	next
	gsel mainWndId
	mapLoading = false
	return true
*cmd_fill_remove
	mapLoading = true
	gsel backWndId
	gmode 4,,, 255 :color 0, 117, 117
	for i, int(chatParamList.1), int(chatParamList.3)+1, 1
		repeat int(chatParamList.2)-int(chatParamList.0)+1, int(chatParamList.0)
			map(cnt, i) = ASTAR_WALL
			mapTipDraw cnt, i, map(cnt, i)
		loop
	next
	gsel mainWndId
	mapLoading = false
	return true
*cmd_help_cmd
	if cmdPlayerId != myPlayerId :return true
	cmdId = int(chatParamList.0)
	addChatLog "�R�}���h:"+ cmdList.cmdId +"�̏ڍ�", ID_SERVER
	
	// �q��
	repeat cmdChildCountList.cmdId
		childId = lpeek(cmdChildList.cmdId, cnt*4)
		str_ = cmdList.cmdId +" "+ cmdParamList.childId
		addChatLog ""+ str_ + strloop( " ", limit(25-strlen(str_), 2, 25) ) + cmdHelpTextList.childId, ID_SERVER
	loop
	
	return true
*cmd_help_help
	if cmdPlayerId != myPlayerId :return true
	addChatLog "- �R�}���h�ꗗ -", ID_SERVER
	repeat commandCount
		if isBlankId(cnt, commandCount, command) :continue
		if false == hadCommandLevel(myPlayerId, cmdList.cnt) :continue
		addChatLog cmdList.cnt, ID_SERVER
	loop
	addChatLog "�R�}���h�̏ڍׂ� /help [�R�}���h] �Ɠ��͂��Ă�������", ID_SERVER
	return true
*cmd_kill_player
	killPlayer ID_SERVER, int(chatParamList.0)//, true
	return true
*cmd_kill_self
	if BM_SERVER == bootmode :return CMD_ERROR
	killPlayer ID_SERVER, cmdPlayerId//, true
	return true
*cmd_mapedit_true
	if BM_SERVER != bootmode :return CMD_ERROR
	mapeditmode = true
	addChatLog "�}�b�v�ҏW��true�ɐݒ�", ID_SERVER
	return true
*cmd_mapedit_false
	if BM_SERVER != bootmode :return CMD_ERROR
	mapeditmode = false
	addChatLog "�}�b�v�ҏW��false�ɐݒ�", ID_SERVER
	return true
*cmd_op_add
	addOP int(chatParamList.0), int(chatParamList.1)
	return true
*cmd_op_remove
	removeOPFromPlayer int(chatParamList.0)
	return true
*cmd_op_delete
	deleteOPLevel int(chatParamList.0)
	return true
*cmd_op_level_list
	if cmdPlayerId != myPlayerId :return true
	addChatLog "- ���x����"+ int(chatParamList.0) +"�R�}���h�ꗗ -", ID_SERVER
	repeat commandCount
		if isBlankId(cnt, commandCount, command) :continue
		if sbGet(commandLevel.int(chatParamList.0), cnt) {
			addChatLog cmdList.cnt, ID_SERVER
		}
	loop
	return true
*cmd_op_level_cmd
	setOPLevelFromCmdId int(chatParamList.0), int(chatParamList.1)
	return true
*cmd_op_level_full
	setOPLevelFromCmdId int(chatParamList.0), -1
	return true
*cmd_op_level_player_self
	setCommandLevelPlayer int(chatParamList.0), ID_SELF
	return true
*cmd_op_level_player_player
	setCommandLevelPlayer int(chatParamList.0), int(chatParamList.1)
	return true
*cmd_op_level_player_all
	setCommandLevelPlayer int(chatParamList.0), ID_SERVER
	return true
*cmd_player_add_ai
	if BM_SERVER != bootmode :return true
	
	loginPlayer 0
	playerNameList.newId = chatParamList.0
	playerIsAIList.newId = true
	playerReadyList.newId = true
	playerHPList.newId = playerDefaultHP
	changePlayerName newId
	
	return true
*cmd_player_kick
	addChatLog "�v���C���[ "+ getPlayerName(int(chatParamList.0)) +" ���L�b�N���܂���", ID_SERVER
	if BM_SERVER != bootmode :return true
	closeSocket int(chatParamList.0)
	return true
*cmd_player_target
	if BM_SERVER != bootmode || cmdPlayerId != myPlayerId :return CMD_ERROR
	targetPlayerId = int(chatParamList.0)
	return true
*cmd_player_target_server
	if BM_SERVER != bootmode || cmdPlayerId != myPlayerId :return CMD_ERROR
	targetPlayerId = ID_SERVER
	return true
*cmd_team_add
	addTeam chatParamList.0 :teamId = stat
	return true
*cmd_team_remove
	removeTeam int(chatParamList.0)
	return true
*cmd_team_join
	joinTeam int(chatParamList.0), int(chatParamList.1)
	return true
*cmd_team_leave
	leaveTeam int(chatParamList.0), int(chatParamList.1)
	return true
*cmd_team_list
	if cmdPlayerId != myPlayerId :return true
	addChatLog "- �`�[���ꗗ -", ID_SERVER
	repeat teamCount
		if isBlankId(cnt, teamCount, team) :continue
		addChatLog ""+ teamNameList.cnt, ID_SERVER
	loop
	return true
*cmd_tip_set
	editMapTip int(chatParamList.0), int(chatParamList.1), int(chatParamList.2)
	return true
*cmd_tip_remove
	editMapTip int(chatParamList.0), int(chatParamList.1), ASTAR_WALL
	return true
*cmd_tp_toplayer
	tpPlayer int(chatParamList.0), playerPosList.int(chatParamList.1), playerMapPosList.int(chatParamList.1)
	return true
*cmd_tp_pos
	p = makelong(int(chatParamList.1), int(chatParamList.2))
	mp = makelong(int(chatParamList.3), int(chatParamList.4))
	tpPlayer int(chatParamList.0), p, mp
	return true
*cmd_whitelist_remove
	setBlankId int(chatParamList.0), whiteList
	addChatLog ""+ whiteListName.int(chatParamList.0) +"���u���b�N���X�g����폜���܂���", ID_SERVER
	return true
*cmd_whitelist_true
	whiteListFlag = true
	addChatLog "�z���C�g���X�g��L���ɂ��܂���", ID_SERVER
	return true
*cmd_whitelist_false
	whiteListFlag = false
	addChatLog "�z���C�g���X�g�𖳌��ɂ��܂���", ID_SERVER
	return true
*cmd_whitelist_add
	newId = getBlankId(whiteListCount, whiteList, whiteListMax)
	whiteListName.newId = chatParamList.0
	whiteListIP.newId = 0
	addChatLog ""+ chatParamList.0 +"���z���C�g���X�g�ɒǉ����܂���", ID_SERVER
	return true
*cmd_whitelist_player
	newId = getBlankId(whiteListCount, whiteList, whiteListMax)
	whiteListName.newId = playerNameList.int(chatParamList.0)
	whiteListIP.newId = playerIPList.int(chatParamList.0)
	addChatLog ""+ getPlayerName(int(chatParamList.0)) +"���z���C�g���X�g�ɒǉ����܂���", ID_SERVER
	return true
*cmd_worldspawn_list
	if cmdPlayerId != myPlayerId :return true
	addChatLog "- ���ݗL���ȃ��X�|�[���n�_ -", ID_SERVER
	repeat respawnCount
		if isBlankId(cnt, respawnCount, respawn) :continue
		x = wordtoint(loword(respawnPos.cnt))
		y = wordtoint(hiword(respawnPos.cnt))
		mx = wordtoint(loword(respawnMapPos.cnt))
		my = wordtoint(hiword(respawnMapPos.cnt))
		addChatLog "pos:"+ x +"x"+ y +" mappos:"+ mx +"x"+ my +" team:"+ teamNameList.respawnTeamList(cnt) , ID_SERVER
	loop
	return true
*cmd_worldspawn_set_self
	if BM_SERVER == bootmode :return CMD_ERROR
	chatParamList.0 = ""+wordtoint(loword(playerPosList.myPlayerId))
	chatParamList.1 = ""+wordtoint(hiword(playerPosList.myPlayerId))
	gosub *cmd_worldspawn_set
	return true
*cmd_worldspawn_set
	chatParamList.2 = ""
	chatParamList.3 = ""
	chatParamList.4 = ""+ TEAM_NEUTRAL
	gosub *cmd_worldspawn_map_set
	return true
*cmd_worldspawn_add
	chatParamList.2 = ""
	chatParamList.3 = ""
	chatParamList.4 = ""+ TEAM_NEUTRAL
	gosub *cmd_worldspawn_map_add
	return true
*cmd_worldspawn_remove
	chatParamList.2 = "-1"
	chatParamList.3 = "-1"
	chatParamList.4 = ""+ TEAM_NEUTRAL
	gosub *cmd_worldspawn_map_remove
	return true
*cmd_worldspawn_map_set
	repeat respawnCount
		setBlankId cnt, respawn
	loop
	gosub *cmd_worldspawn_map_add
	return true
*cmd_worldspawn_map_add
	newId = getBlankId(respawnCount, respawn, respawnPosMax)
	x = int(chatParamList.0)
	y = int(chatParamList.1)
	mx = int(chatParamList.2)
	my = int(chatParamList.3)
	setRespawnPos newId, makelong(x, y), makelong(mx, my), int(chatParamList.4)
	addChatLog "�V�������X�|�[���n�_��o�^���܂���("+ usedIdCount(respawnCount, respawn) +") ("+ x +"x"+ y +":"+ mx +"x"+ my +") ["+ teamNameList.int(chatParamList.4) +"]", ID_SERVER
	return true
*cmd_worldspawn_map_remove
	p = makelong(int(chatParamList.0), int(chatParamList.1))
	mp = makelong(int(chatParamList.2), int(chatParamList.3))
	repeat respawnCount
		if isBlankId(cnt, respawnCount, respawn) :continue
		mp = makelong(int(chatParamList.2), int(chatParamList.3))
		if 0xFFFFFFFF == mp :mp = respawnMapPos.cnt
		if p == respawnPos.cnt && mp == respawnMapPos.cnt && int(chatParamList.3) == teamNameList.cnt {
			setBlankId cnt, respawn
			addChatLog "���X�|�[���n�_"+ cnt +"���폜���܂���", ID_SERVER
		}
	loop
	return true
	
*_CHAT_AS_END
	
	#endif
	
