	
	#ifndef APPNAME
	#include "shotgame.hsp"
	#endif
	
	#ifndef AS_CHAT
	#define AS_CHAT
	
	#define	makeChatWindow(%1=0, %2=-1)	makeChatWindow__ %1, %2
	
goto *_CHAT_AS_END

	// 特別なキーコードを監視
#deffunc chatSpecialKeys int _keycode
	
	if false == chatActhivedFlag :return 0
	
	defProcUncallFlag = true
	switch _keycode
	case VK_RETURN
		// チャット送信
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
		// チャットウィンドウ強制非表示
		immSetOpenStatus hImc, false
		chatAlpha = 0
		chatVisibleTime = 0
		chatInvisible
		
		pauseWait = 10
		swbreak
	
	case VK_TAB
		// Tab補完
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
	
	// ウィンドウクリックでチャットアクティブ
	if keyDowned(keys.K_SHOT) {
		if false == chatActhivedFlag :if chatVisible :setFocus hInputWnd
	}
	
	// チャットウィンドウアクティベート
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
	
	// ログ引用
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
	
	// ログ移動
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
	
	// Control+tabの検出
	if getkey(VK_CONTROL) && 0x8000 :if keyDowned(keys.K_TAB) {
		// Tab補完back
		complementCommand chatBuffer
		objprm inputId, chatBuffer
		sendmsg hInputWnd, EM_SETSEL, 0xFFFF, 0xFFFF
		chatActivateFlag = true
	}
	
	return
	
	// チャットウィンドウの作成
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
	
	// チャット描画
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
	
	
	// チャットログに追加
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
	
	// チャットウィンドウを無効化
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

	// チャットログを巻き戻す
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

	// チャットだけ送信主を playerId に設定
	putChat _chatType, _message, _playerId
	sendPacket clientSocketList._toPlayerId
	
	return
	
	
#deffunc addChat str _message, int _playerId
	
	findCommandEx _message, _playerId :st = stat
	if CMD_ERROR == st :return st
	chat st, _message, _playerId
	
	return st
	
	// チャット送信
#deffunc chat int _chatType, str _message, int _playerId
	
	// チャットだけ送信主を playerId に設定
	putChat _chatType, _message, _playerId
	
	switch bootmode
	case BM_SERVER
		// 全蔵に送信
		repeat playerCount
			if isBlankId(cnt, playerCount, player) || cnt == _playerId :continue	// 受信した蔵には送らない
			sendPacket clientSocketList.cnt, true
		loop
		DeletePacketData
		
		swbreak
		
	case BM_CLIENT
		// 鯖に送信
		sendPacket mainSocket
		swbreak
	swend
	
	return
	
	// チャット受信
#deffunc recvChat int _chatType, str _message, int _playerId
	
	findCommandEx _message, _playerId
	
	switch bootmode
	case BM_SERVER
		// 蔵から受信 _playerId が送信主
		chat _chatType, _message, _playerId
	
		chatAlpha = chatDefaultAlpha
		chatVisibleTime = chatDefaultVisibleTime
		addChatLog _message, _playerId
		
		swbreak
		
	case BM_CLIENT
		// 鯖から受信 _playerId が送信主
		if CMD_CHAT != _chatType :swbreak
		chatAlpha = chatDefaultAlpha
		chatVisibleTime = chatDefaultVisibleTime
		addChatLog _message, _playerId
		
		swbreak
	swend
	
	return
	
	// コマンドIDを文字列で検索
	#define ctype isNumber(%1)	('0' <= (%1) && (%1) <= '9')
	#define addCmd(%1, %2, %3, %4, %5=0)		_labelVar = %3 : addCmd__ %1, %2, _labelVar, %4, %5
#defcfunc findCmdId str _cmdName
	selId = -1
	repeat commandCount
		if isBlankId(cnt, commandCount, command) :continue
		if _cmdName == cmdList.cnt :selId = cnt :break
	loop
	if -1 == selId {
		addChatLog "指定したコマンドが見つかりませんでした", ID_SERVER
	}
	return selId
	
	// 権限のレベルを検索
#defcfunc findOPLevelId int _level
	selId = -1
	repeat opCount
		if isBlankId(cnt, opCount, op) :continue
		if _level == commandLevelId.cnt :selId = cnt :break
	loop
	if -1 == selId {
		addChatLog "指定したレベルが見つかりませんでした", ID_SERVER
	}
	return selId
	
	// OP権限をプレイヤーに付与
#deffunc addOP int _playerId, int _level
	if isBlankId(_level, opCount, op) {
		addChatLog "指定したレベルが見つかりませんでした", ID_SERVER
		return
	}
	playerCommandLevel._playerId = _level
	addChatLog ""+ getPlayerName(_playerId) +"にレベル"+ _level +"のコマンド権限を与えました", ID_SERVER
	return
	
	// プレイヤーからOP権限を剥奪
#deffunc removeOPFromPlayer int _playerId
	playerCommandLevel._playerId = COMMAND_DEFAULT_LEVEL
	addChatLog ""+ getPlayerName(_playerId) +"のコマンド権限を初期化しました", ID_SERVER
	return
	
	// OP権限を作成
#deffunc makeOPLevel int _level
	newId = getBlankId(opCount, op, opMax)
	commandLevel.newId = ""
	commandPlayer.newId = ID_SELF
	commandLevelId.newId = _level
	return newId
	
	// OP権限を削除
#deffunc deleteOPLevel int _levelId
	repeat playerCount
		if isBlankId(cnt, playerCount, player) :continue
		if playerCommandLevel.cnt != commandLevelId._levelId :continue
		removeOPFromPlayer cnt
	loop
	setBlankId _levelId, op
	addChatLog "レベル"+ commandLevelId._levelId +"のコマンド権限を削除しました", ID_SERVER
	return
	
	// コマンドレベル削除
#deffunc removeOPLevelFromCmdId int _levelId, int _commandId
	levelId_ = _levelId
	if isBlankId(_levelId, opCount, op) {
		makeOPLevel _levelId
		levelId_ = stat
	}
	ssFalse commandLevel.levelId_, _commandId
	return
	
	// コマンドレベル追加
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
		addChatLog "レベル"+ commandLevelId.levelId_ +"にすべてのコマンドの実行権限を付与しました", ID_SERVER
	} else {
		ssTrue commandLevel.levelId_, _commandId
		addChatLog "レベル"+ commandLevelId.levelId_ +"に"+ cmdList._commandId +"を実行できるようにしました", ID_SERVER
	}
	return
#deffunc setOPLevel int _level, str _command
	cmdId = findCmdId(_command)
	levelId_ = findOPLevelId(_level)
	if -1 == levelId_ :makeOPLevel _level :levelId_ = stat
	setOPLevelFromCmdId levelId_, cmdId
	return
	
	// プレイヤーが指定のコマンドの権限を持っているかどうか
#defcfunc hadCommandLevel int _playerId, str _command
	if ID_SERVER == _playerId :return true
	if _playerId < ID_SERVER :return false
	
	cmdId = findCmdId(_command)
	levelId_ = findOPLevelId(playerCommandLevel._playerId)
	if -1 == levelId_ {
		addChatLog "無効な権限レベルを使用して実行しました", ID_SERVER
		return false
	}
	return sbGet(commandLevel.levelId_, cmdId)
	
	// コマンドの対象にできるプレイヤーを設定
#deffunc setCommandLevelPlayer int _levelId, int _playerId
	levelId_ = _levelId
	if isBlankId(_levelId, opCount, op) {
		makeOPLevel _levelId
		levelId_ = stat
	}
	commandPlayer.levelId_ = _playerId
	
	addChatLog "レベル"+ commandLevelId.levelId_ +"が"+ getPlayerName(_playerId) +"に対して実行できるようにしました", ID_SERVER
	
	return
	
	// プレイヤーをコマンドの対象にできるかどうか
#defcfunc hadCommandLevelPlayer int _playerId, int _toPlayerId
	if ID_SERVER == _playerId :return true
	levelId_ = findOPLevelId(playerCommandLevel._playerId)
	if -1 == levelId_ {
		addChatLog "無効な権限レベルを使用して実行しました", ID_SERVER
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
			addChatLog "対象に対して実行する権限がありません", ID_SERVER
			id = -1
		}
		swbreak
	case "whiteplayer"	:id = findWhiteListId(_token)	:swbreak
	case "blackplayer"	:id = findBlackListId(_token)	:swbreak
	case "cmd"
		id = findCmdId(_token)
		if -1 != id :if false == hadCommandLevel(_playerId, cmdList.id) {
			addChatLog "コマンド"+ cmdList.id +"を実行する権限がありません", ID_SERVER
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
		// +hoge は hoge がtab補完に使用されるため
		// +hoge は hoge が number 以外は文字列を想定して指定されている
		swbreak
	swend
	
	return
	
	// コマンドの文法チェックと実行
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
		
		// 子条件を探索
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
				// 引数スタックに積む
				if strlen(matchParam) {
					chatParamList.chatParamCount = matchParam
					chatParamCount++
				}
			next
			
			if cmdChildParamLen && false == match {
				rollbackChatLog
			} else :if j == cmdChildParamLen {
				// すべての子条件に一致
				// 子条件がないものは無条件としてここにくる
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
						addChatLog "コマンド"+ cmdList.cnt +"を実行する権限がありません", ID_SERVER
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

	// コマンドの補完
#deffunc complementCommand str _message
	
	cmdBuffer = _message
	
	// complementCommandListには差分だけ格納
	sdim cmdToken
	split cmdBuffer, " ", cmdToken
	cmdTokenLen = length(cmdToken)
	
	if 0 == complementMax {
		sdim complementCommandList :complementCommandCount = 0
	}
	
	if complementMax {
		// 前回の候補参照
	} else :if "" == cmdBuffer {
		// 全親表示
		repeat commandCount
			if isBlankId(cnt, commandCount, command) :continue
			if false == hadCommandLevel(myPlayerId, cmdList.cnt) :continue
			pushComplementParam cmdList.cnt
		loop
	} else {
		sdim prevChildText
		switch cmdTokenLen
		case 1
			// 親探索
			repeat commandCount
				if isBlankId(cnt, commandCount, command) :continue
				if false == hadCommandLevel(myPlayerId, cmdList.cnt) :continue
				if 0 == instr(cmdList.cnt, 0, cmdBuffer) {
					pushComplementParam cmdList.cnt
				}
			loop
			swbreak
	
		default
			// 親+子探索
			cmdId = -1
			repeat commandCount
				if isBlankId(cnt, commandCount, command) :continue
				if false == hadCommandLevel(myPlayerId, cmdList.cnt) :continue
				if 0 == instr(cmdBuffer, 0, cmdList.cnt) :cmdId = cnt :break
			loop
			if -1 == cmdId :swbreak
	
			prmId = cmdTokenLen-2	// 最後の要素だけ見る
			prevChildText = cmdToken.0
			repeat limit(prmId, 0, INT_MAX), 1	// 最後の要素以外を結合
				prevChildText += " "+ cmdToken.cnt
			loop
			
			repeat cmdChildCountList.cmdId	// 子の数だけ探索
				childId = lpeek(cmdChildList.cmdId, cnt*4)
				
				sdim cmdChildParam
				split cmdParamList.childId, " ", cmdChildParam
				cmdChildParamLen = length(cmdChildParam)
				if cmdChildParamLen <= prmId :continue
	
				// それまでの子要素の条件が合致しているか
				match = true
				beginWatchChatLog
				repeat limit(cmdChildParamLen, 0, prmId)
					if false == matchChildParam(myPlayerId, cnt, cmdToken(cnt+1)) :match = false :break
				loop
				rollbackChatLog
				if false == match :continue
				
				tokenId	= prmId+1
				tokenBlankFlag = false
				if "" == cmdToken.tokenId :tokenBlankFlag = true	// 子条件の探索になにも入力されていないから全表示
				
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
	
	// / 続く文字列はコマンド
	sdim cmdList
	sdim cmdChildCountList
	sdim cmdChildList
	sdim cmdParamList
	sdim cmdHelpTextList
	sdim cmdResultList
	sdim cmdLogThroughtList
	complementCount = 0 :complementMax = 0
	
	parameterHelp = {"
	--tabでコマンドの補完ができます--
	--引数の説明--
	= 続く文字列に一致してるか
	? 続く文字列によって検索
	\t: [?type:デフォルト] 文字列がないとデフォルトを使用
	+ 続く文字列はタイプ
		name   文字列
		number 0-9 で構成されている数字
		[hoge] 指定されている何か
	& [?]と[+]を組み合わせたもの"}
	
	addCmd "/blacklist", "=remove ?blackplayer", *cmd_blacklist_remove, "ブラックリストに追加します", true
	addCmd "/blacklist", "=add +name", *cmd_blacklist_add, "ブラックリストに追加します", true
	addCmd "/blacklist", "?player", *cmd_blacklist_player, "ブラックリストに追加します", true
	addCmd "/blacklist", "=true", *cmd_blacklist_true, "ブラックリストを有効にします", true
	addCmd "/blacklist", "=false", *cmd_blacklist_false, "ブラックリストを無効にします", true
	
	addCmd "/cls", "+startIndex", *cmd_cls_index, "チャットログを消去します"
	addCmd "/cls", "", *cmd_cls_all, "チャットログを全消去します"
	
	addCmd "/color", "=player ?player +r +g +b", *cmd_color_player, "player の色を r, g, b に変更します"
	addCmd "/color", "=player ?player +rgb", *cmd_color_player_rgb, "player の色を rgb に変更します"
	addCmd "/color", "=team ?team +r +g +b", *cmd_color_team, "teamの色を r, g, b に変更します"
	addCmd "/color", "=team ?team +rgb", *cmd_color_team_rgb, "teamの色を rgb に変更します"
	
	addCmd "/fill", "=set +tipx +tipy +tipx +tipy +tipId", *cmd_fill_set, "マップチップを複数設置します", true
	addCmd "/fill", "=remove +tipx +tipy +tipx +tipy", *cmd_fill_remove, "マップチップを複数削除します", true
	
	addCmd "/help", "?cmd", *cmd_help_cmd, "cmd の詳細を見ます", true
	addCmd "/help", "", *cmd_help_help, parameterHelp, true
	
	addCmd "/kick", "?player", *cmd_player_kick, "プレイヤーをキックします", true
	
	addCmd "/kill", "?player", *cmd_kill_player, "player をころころします"
	addCmd "/kill", "", *cmd_kill_self, "自害します"
	
	addCmd "/mapedit", "=true", *cmd_mapedit_true, "マップ編集を有効にします", true
	addCmd "/mapedit", "=false", *cmd_mapedit_false, "マップの編集を無効にします", true
	
	addCmd "/op", "=add ?player ?level", *cmd_op_add, "プレイヤーに指定レベルのコマンドの権限を付与します"
	addCmd "/op", "=remove ?player", *cmd_op_remove, "プレイヤーのコマンド権限を初期化します"
	addCmd "/op", "=delete ?level", *cmd_op_delete, "対象の権限レベルを削除します"
	addCmd "/op", "=level ?level =list", *cmd_op_level_list, "対象レベルに付与されているコマンド権限を表示します"
	addCmd "/op", "=level &level ?cmd", *cmd_op_level_cmd, "レベルで扱えるコマンドを設定します、初期値は0"
	addCmd "/op", "=level &level =full", *cmd_op_level_full, "レベルで扱えるコマンドの権限を全コマンドにします"
	addCmd "/op", "=level &level =self", *cmd_op_level_player_self, "レベルで対象にできるプレイヤーを自身のみにします"
	addCmd "/op", "=level &level ?player", *cmd_op_level_player_player, "レベルで対象にできるプレイヤーを設定します"
	addCmd "/op", "=level &level =all", *cmd_op_level_player_all, "レベルで対象にできるプレイヤーをすべてにします"
	
	addCmd "/player", "=add ?player =whitelist", *cmd_whitelist_add, "ホワイトリストに追加します", true
	addCmd "/player", "=add ?player =blacklist", *cmd_blacklist_add, "ブラックリストに追加します", true
	addCmd "/player", "=add +name =AI", *cmd_player_add_ai, "AIを追加します"
	addCmd "/player", "=kick ?player", *cmd_player_kick, "プレイヤーをキックします", true
	addCmd "/player", "=target ?player", *cmd_player_target, "プレイヤーの視点に切り替えます", true
	addCmd "/player", "=target", *cmd_player_target_server, "自由視点に切り替えます", true
	
	addCmd "/team", "=add +name", *cmd_team_add, "name を作成します"
	addCmd "/team", "=remove ?team", *cmd_team_remove, "team を削除します"
	addCmd "/team", "=join ?team ?player", *cmd_team_join, "team に player を追加します"
	addCmd "/team", "=leave ?team ?player", *cmd_team_leave, "team から player を削除します"
	addCmd "/team", "=list", *cmd_team_list, "team 一覧を表示します", true
	
	addCmd "/tip", "=set +tipx +tipy +itemId", *cmd_tip_set, "マップチップを設置します", true
	addCmd "/tip", "=remove +tipx +tipy", *cmd_tip_remove, "マップチップを削除します", true
	
	addCmd "/tp", "?player ?player", *cmd_tp_toplayer, "指定のプレイヤーに転移しますします", true
	addCmd "/tp", "?player +x +y +mapx +mapy", *cmd_tp_pos, "プレイヤーの位置を変更します", true
	
	addCmd "/whitelist", "=remove ?whiteplayer", *cmd_whitelist_remove, "ホワイトリストに追加します", true
	addCmd "/whitelist", "=add +name", *cmd_whitelist_add, "ホワイトリストに追加します", true
	addCmd "/whitelist", "?player", *cmd_whitelist_player, "ホワイトリストに追加します", true
	addCmd "/whitelist", "=true", *cmd_whitelist_true, "ホワイトリストを有効にします", true
	addCmd "/whitelist", "=false", *cmd_whitelist_false, "ホワイトリストを無効にします", true
	
	addCmd "/worldspawn", "=list", *cmd_worldspawn_list, "リスポーン座標の一覧を表示します", true
	addCmd "/worldspawn", "=set +x +y +mapx +mapy ?team:無所属", *cmd_worldspawn_map_set, "リスポーン座標とマップ座標を変更します", true
	addCmd "/worldspawn", "=add +x +y +mapx +mapy ?team:無所属", *cmd_worldspawn_map_add, "リスポーン座標とマップ座標を追加します", true
	addCmd "/worldspawn", "=remove +x +y +mapx +mapy ?team:無所属", *cmd_worldspawn_map_remove, "リスポーン座標とマップ座標を削除します", true
	addCmd "/worldspawn", "=set +x +y", *cmd_worldspawn_set, "リスポーン座標を変更します", true
	addCmd "/worldspawn", "=add +x +y", *cmd_worldspawn_add, "リスポーン座標を追加します", true
	addCmd "/worldspawn", "=remove +x +y", *cmd_worldspawn_remove, "リスポーン座標を削除します", true
	addCmd "/worldspawn", "+x +y", *cmd_worldspawn_set, "リスポーン座標を変更します", true
	addCmd "/worldspawn", "", *cmd_worldspawn_set_self, "リスポーン座標を変更します", true
	
	
	return

*cmd_blacklist_true
	blackListFlag = true
	addChatLog "ブラックリストを有効にしました", ID_SERVER
	return true
*cmd_blacklist_false
	blackListFlag = false
	addChatLog "ブラックリストを無効にしました", ID_SERVER
	return true
*cmd_blacklist_remove
	setBlankId int(chatParamList.0), blackList
	addChatLog ""+ blackListName.int(chatParamList.0) +"をブラックリストから削除しました", ID_SERVER
	return true
*cmd_blacklist_add
	newId = getBlankId(blackListCount, blackList, blackListMax)
	blackListName.newId = chatParamList.0
	blackListIP.newId = 0
	addChatLog ""+ chatParamList.0 +"をブラックリストに追加しました", ID_SERVER
	return true
*cmd_blacklist_player
	newId = getBlankId(blackListCount, blackList, blackListMax)
	blackListName.newId = playerNameList.int(chatParamList.0)
	blackListIP.newId = playerIPList.int(chatParamList.0)
	addChatLog ""+ getPlayerName(int(chatParamList.0)) +"をブラックリストに追加しました", ID_SERVER
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
	addChatLog "コマンド:"+ cmdList.cmdId +"の詳細", ID_SERVER
	
	// 子列挙
	repeat cmdChildCountList.cmdId
		childId = lpeek(cmdChildList.cmdId, cnt*4)
		str_ = cmdList.cmdId +" "+ cmdParamList.childId
		addChatLog ""+ str_ + strloop( " ", limit(25-strlen(str_), 2, 25) ) + cmdHelpTextList.childId, ID_SERVER
	loop
	
	return true
*cmd_help_help
	if cmdPlayerId != myPlayerId :return true
	addChatLog "- コマンド一覧 -", ID_SERVER
	repeat commandCount
		if isBlankId(cnt, commandCount, command) :continue
		if false == hadCommandLevel(myPlayerId, cmdList.cnt) :continue
		addChatLog cmdList.cnt, ID_SERVER
	loop
	addChatLog "コマンドの詳細は /help [コマンド] と入力してください", ID_SERVER
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
	addChatLog "マップ編集をtrueに設定", ID_SERVER
	return true
*cmd_mapedit_false
	if BM_SERVER != bootmode :return CMD_ERROR
	mapeditmode = false
	addChatLog "マップ編集をfalseに設定", ID_SERVER
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
	addChatLog "- レベルの"+ int(chatParamList.0) +"コマンド一覧 -", ID_SERVER
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
	addChatLog "プレイヤー "+ getPlayerName(int(chatParamList.0)) +" をキックしました", ID_SERVER
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
	addChatLog "- チーム一覧 -", ID_SERVER
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
	addChatLog ""+ whiteListName.int(chatParamList.0) +"をブラックリストから削除しました", ID_SERVER
	return true
*cmd_whitelist_true
	whiteListFlag = true
	addChatLog "ホワイトリストを有効にしました", ID_SERVER
	return true
*cmd_whitelist_false
	whiteListFlag = false
	addChatLog "ホワイトリストを無効にしました", ID_SERVER
	return true
*cmd_whitelist_add
	newId = getBlankId(whiteListCount, whiteList, whiteListMax)
	whiteListName.newId = chatParamList.0
	whiteListIP.newId = 0
	addChatLog ""+ chatParamList.0 +"をホワイトリストに追加しました", ID_SERVER
	return true
*cmd_whitelist_player
	newId = getBlankId(whiteListCount, whiteList, whiteListMax)
	whiteListName.newId = playerNameList.int(chatParamList.0)
	whiteListIP.newId = playerIPList.int(chatParamList.0)
	addChatLog ""+ getPlayerName(int(chatParamList.0)) +"をホワイトリストに追加しました", ID_SERVER
	return true
*cmd_worldspawn_list
	if cmdPlayerId != myPlayerId :return true
	addChatLog "- 現在有効なリスポーン地点 -", ID_SERVER
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
	addChatLog "新しくリスポーン地点を登録しました("+ usedIdCount(respawnCount, respawn) +") ("+ x +"x"+ y +":"+ mx +"x"+ my +") ["+ teamNameList.int(chatParamList.4) +"]", ID_SERVER
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
			addChatLog "リスポーン地点"+ cnt +"を削除しました", ID_SERVER
		}
	loop
	return true
	
*_CHAT_AS_END
	
	#endif
	
