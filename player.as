
	
	#ifndef APPNAME
	#include "shotgame.hsp"
	#endif
	
	#ifndef AS_PLAYER
	#define AS_PLAYER
	
	// AIの行動(ビット/32)
	#enum	AI_MODE_PATROL		= 0	// 適当に巡回
	#enum	AI_MODE_ROUTE			// 対象へ近づく
	#enum	AI_MODE_ATTACK			// 単純に攻撃, 対象/自身 の HP が 0 になると AI_MODE_PATROL へ
	#enum	AI_MODE_DEFENCE			// よける / 隠れる
	#enum	AI_MODE_COUNTER			// よけた後に攻撃
	
	// AI計算
	#define	ctype isEnemy(%1, %2)		(%1 != %2 && (teamNeutralId == playerTeamList(%2) || playerTeamList(%1) != playerTeamList(%2)) && 0 < playerHPList(%2))
	
goto *_PLAYER_AS_END
	
#deffunc aiCalc
	
	repeat playerCount
		if isBlankId(cnt, playerCount, player) :continue
		if false == playerIsAIList.cnt :continue
		if playerHPList.cnt <= 0 :continue
	
		if bGet(playerIsAIList.cnt, AI_MODE_PATROL) {
			aiModePatrol cnt
		}
		if bGet(playerIsAIList.cnt, AI_MODE_ROUTE) {
			aiModeRoute cnt
		}
		if bGet(playerIsAIList.cnt, AI_MODE_ATTACK) {
			aiModeAttack cnt
		}
	loop
	
	return
	
#deffunc aiModeAttack int _id
	
	if gunWaitTime._id {
		gunWaitTime._id--
		if 0 == gunWaitTime._id {
			gunRestCount._id = gunDefaultRestCount.playerGunTypeList(_id)
		}
		return
	}
	
	gunWaitTime._id = gunDefaultRestCount.playerGunTypeList(_id)
	gunRestCount._id--
	if gunRestCount._id <= 0 {
		// 残数0の自動リロード
		gunWaitTime._id += reloadDefaultTime.playerGunTypeList(_id)
	}
	
	if ID_SERVER == playerTargetList._id {
		sFalse playerIsAIList._id, AI_MODE_ATTACK
		sTrue playerIsAIList._id, AI_MODE_PATROL
		return
	} else {
		if playerHPList.playerTargetList(_id) <= 0 {
			sFalse playerIsAIList._id, AI_MODE_ATTACK
			sTrue playerIsAIList._id, AI_MODE_PATROL
		} else {
			r = sqrt(powf(loword(playerPosList._id)-loword(playerPosList.playerTargetList(_id)), 2) + powf(hiword(playerPosList._id)-hiword(playerPosList.playerTargetList(_id)), 2))
			if r < shotMaxRange.playerGunTypeList(playerTargetList(_id)) {
				initPosition _id
				if rnd(2) :moveRight
				if rnd(2) :moveLeft
				if rnd(2) :moveUp
				if rnd(2) :moveDown
				moveApply _id
			}
		}
	}
	
	ex = loword(playerPosList.playerTargetList(_id)) + abs(wordtoint(loword(playerMapPosList.playerTargetList(_id))))
	ey = hiword(playerPosList.playerTargetList(_id)) + abs(wordtoint(hiword(playerMapPosList.playerTargetList(_id))))
	mx = loword(playerPosList._id) + abs(wordtoint(loword(playerMapPosList._id)))
	my = hiword(playerPosList._id) + abs(wordtoint(hiword(playerMapPosList._id)))
	
	gunFire _id, mx, my, ex, ey
	
	return
	
#deffunc aiModeRoute int _id
	
	max = lpeek(playerRouteList._id, 0)
	count = lpeek(playerRouteList._id, 4)
	p = lpeek(playerRouteList._id, count*4+8)
	if ASTAR_WALL == map(loword(p), hiword(p)) {
		sFalse playerIsAIList._id, AI_MODE_ROUTE
		sTrue playerIsAIList._id, AI_MODE_PATROL
		logmes "ai : wall lost"
		return
	}
	px = loword(p) * mapTipWidth
	py = hiword(p) * mapTipHeight
	
	initPosition _id
	
	mp = makelong(loword(playerPosList._id) + abs(wordtoint(loword(playerMapPosList._id))), hiword(playerPosList._id) + abs(wordtoint(hiword(playerMapPosList._id))))
	x = loword(mp)
	y = hiword(mp)
	if px+moveSpeed <= x && x <= px+mapTipWidth-moveSpeed && py+moveSpeed <= y && y <= py+mapTipHeight-moveSpeed {
		count++
		if count == max {
			sFalse playerIsAIList._id, AI_MODE_ROUTE
	
			if ID_SERVER != playerTargetList._id {
				if 0 < playerHPList.playerTargetList(_id) {
					sTrue playerIsAIList._id, AI_MODE_PATROL
				}
			} else {
				sTrue playerIsAIList._id, AI_MODE_PATROL
			}
		} else :if max/2 <= count {
			if ID_SERVER != playerIsAIList._id :if bGet(playerIsAIList._id, AI_MODE_ATTACK) {
				sFalse playerIsAIList._id, AI_MODE_ROUTE
				sTrue playerIsAIList._id, AI_MODE_PATROL
//				logmes "ai : target refind"
			}
		}
		lpoke playerRouteList._id, 4, count
	} else {
		if x <= px+moveSpeed {
			moveRight
		} else :if px+mapTipWidth-moveSpeed <= x {
			moveLeft
		}
		if y <= py+moveSpeed {
			moveDown
		} else :if py+mapTipHeight-moveSpeed <= y {
			moveUp
		}
	}
	
	moveApply _id
	
	if ID_SERVER == playerTargetList._id {
		enemyId = -1
		enemyDistance = viewMainWidth/2
		// 巡回 & プレイヤーに AI以外,違うチーム を発見次第 AI_MODE_FIND_ROUTE へ
		for i, 0, playerCount, 1
			if isBlankId(i, playerCount, player) :_continue
			if isEnemy(_id, i) {
				r = sqrt(powf(loword(playerPosList._id)-loword(playerPosList.i), 2) + powf(hiword(playerPosList._id)-hiword(playerPosList.i), 2))
				if enemyDistance > r {
					enemyDistance = r
					enemyId = i
				}
			}
		next
		if -1 != enemyId {
			aiDecideRoute _id
			return
		}
	} else {
		if isBlankId(playerTargetList._id, playerCount, player) {
			sFalse playerIsAIList._id, AI_MODE_ROUTE
			sFalse playerIsAIList._id, AI_MODE_ATTACK
			sTrue playerIsAIList._id, AI_MODE_PATROL
			logmes "ai : target lost"
		} else {
		}
	}
	
	return
	
#deffunc aiModePatrol int _id
	
	enemyId = -1
	enemyDistance = viewMainWidth/2
	// 巡回 & プレイヤーに AI以外,違うチーム を発見次第 AI_MODE_FIND_ROUTE へ
	for i, 0, playerCount, 1
		if isBlankId(i, playerCount, player) :_continue
		if isEnemy(_id, i) {
			r = sqrt(powf(loword(playerPosList._id)-loword(playerPosList.i), 2) + powf(hiword(playerPosList._id)-hiword(playerPosList.i), 2))
			if r < enemyDistance {
				enemyDistance = r
				enemyId = i
			}
		}
	next
	
	*rePatrol
	if -1 == enemyId {
		// 巡回
		count = 10
		*reMap
		x = rnd(mapWidth)
		y = rnd(mapHeight)
		if count {
			if ASTAR_WALL == map(x, y) {
				count--
				goto *reMap
			}
		} else {
			logmes "ai : can't patrol"
			return
		}
		
		mp = makelong(loword(playerPosList._id) + abs(wordtoint(loword(playerMapPosList._id))), hiword(playerPosList._id) + abs(wordtoint(hiword(playerMapPosList._id))))
		startPos = makelong(x, y)
		endPos = makelong( loword(mp)/mapTipWidth, hiword(mp)/mapTipHeight )
		astar map, route, startPos, endPos :n = stat
		if n < 0 {
			
			return
		}
		
		playerTargetList._id = ID_SERVER
		memexpand playerRouteList._id, 8+n*4+1
		lpoke playerRouteList._id, 0, n
		lpoke playerRouteList._id, 4, 0
		memcpy playerRouteList._id, route, n*4, 8
		
		sFalse playerIsAIList._id, AI_MODE_PATROL
		sTrue playerIsAIList._id, AI_MODE_ROUTE
	} else {
		// 目的地設定
		aiDecideRoute _id
	}

	
	return
	
#deffunc aiDecideRoute int _id

	// 目的地設定
	ep = makelong(loword(playerPosList.enemyId) + abs(wordtoint(loword(playerMapPosList.enemyId))), hiword(playerPosList.enemyId) + abs(wordtoint(hiword(playerMapPosList.enemyId))))
	mp = makelong(loword(playerPosList._id) + abs(wordtoint(loword(playerMapPosList._id))), hiword(playerPosList._id) + abs(wordtoint(hiword(playerMapPosList._id))))
	startPos = makelong( loword(ep)/mapTipWidth, hiword(ep)/mapTipHeight )
	endPos = makelong( loword(mp)/mapTipWidth, hiword(mp)/mapTipHeight )
	if startPos == endPos {
		sTrue playerIsAIList._id, AI_MODE_ATTACK
		return
	}
	astar map, route, startPos, endPos :n = stat
	if n < 0 {
		logmes "ai : unreachable "+ loword(startPos) +"x"+ hiword(startPos) +" - "+ loword(endPos) +"x"+ hiword(endPos)
		enemyId = -1
		goto *rePatrol
	}
	playerTargetList._id = enemyId
	memexpand playerRouteList._id, 8+n*4+1
	lpoke playerRouteList._id, 0, n
	lpoke playerRouteList._id, 4, 0
	memcpy playerRouteList._id, route, n*4, 8
		
	sFalse playerIsAIList._id, AI_MODE_PATROL
	sTrue playerIsAIList._id, AI_MODE_ROUTE
	sTrue playerIsAIList._id, AI_MODE_ATTACK
	
	return
	
	// 移動
#deffunc initPosition int _id
	
	addXPos = 0 :addMapXPos = 0
	addYPos = 0 :addMapYPos = 0
	myMapXPos = wordtoint(loword(playerMapPosList._id))
	myMapYPos = wordtoint(hiword(playerMapPosList._id))
	myXPos = wordtoint(loword(playerPosList._id))
	myYPos = wordtoint(hiword(playerPosList._id))
		
	return
#deffunc moveLeft
	if myMapXPos < 0 && myXPos < viewMainWidth/2 {
		addMapXPos += moveSpeed+runFlag*runSpeed
	} else {
		if myXPos-moveSpeed+runFlag*runSpeed :addXPos -= moveSpeed+runFlag*runSpeed
	}
	return
#deffunc moveUp
	if myMapYPos < 0 && myYPos < viewMainHeight/2 {
		addMapYPos += moveSpeed+runFlag*runSpeed
	} else {
		if myYPos-moveSpeed+runFlag*runSpeed :addYPos -= moveSpeed+runFlag*runSpeed
	}
	return
#deffunc moveRight
	if -(mainWidth-viewMainWidth) < myMapXPos && viewMainWidth/2 < myXPos {
		addMapXPos -= moveSpeed+runFlag*runSpeed
	} else {
		if myXPos+moveSpeed+runFlag*runSpeed < mainWidth :addXPos += moveSpeed+runFlag*runSpeed
	}
	return
#deffunc moveDown
	if -(mainHeight-viewMainHeight) < myMapYPos && viewMainHeight/2 < myYPos {
		addMapYPos -= moveSpeed+runFlag*runSpeed
	} else {
		if myYPos+moveSpeed+runFlag*runSpeed < mainHeight :addYPos += moveSpeed+runFlag*runSpeed
	}
	return
#deffunc moveApply int _id

	if 0 == addXPos && 0 == addYPos && 0 == addMapXPos && 0 == addMapYPos {
		return
	}
	myXPos += addXPos
	myYPos += addYPos
	myMapXPos += addMapXPos
	myMapYPos += addMapYPos
	
	setPos _id, makelong(myXPos, myYPos), makelong(myMapXPos, myMapYPos)
	
	return
	
	// プレイヤー/チーム色変更
#deffunc changeColor int _id, int _type, int _color, int _sendFlag
	
	switch _type
	case COLOR_TYPE_PLAYER
		if _color == playerColorList._id :swbreak
		playerColorList._id = _color
		
		addChatLog "プレイヤー["+ getPlayerName(_id) +"]の色を"+ RR(_color) +","+ GG(_color) +","+ BB(_color) +"に変更しました", ID_SERVER
		swbreak
		
	case COLOR_TYPE_TEAM
		if _color == teamColorList._id :swbreak
		teamColorList._id = _color
		
		addChatLog "チーム["+ teamNameList._id +"]の色を"+ RR(_color) +","+ GG(_color) +","+ BB(_color) +"に変更しました", ID_SERVER
		swbreak
	swend

	return
	
	// kill情報送信
#deffunc killPlayer int _killerId, int _deaderId, int _sendFlag
	
	logmes "killed:"+ _killerId +" deaded:"+ _deaderId
	
	playerHPList._deaderId = 0
	spawnWaitTime._deaderId = respawnWaitTime
	
	putPacketRule PACKET_TYPE_PLAYERKILL, ID_SERVER
	putPacketInt _killerId
	putPacketInt _deaderId
	
	switch bootmode
	case BM_SERVER
		repeat playerCount
			if isBlankId(cnt, playerCount, player) :continue
			sendPacket clientSocketList.cnt, true
		loop
		DeletePacketData
	
		swbreak
		
	case BM_CLIENT
		if _sendFlag {
			sendPacket mainSocket
		} else {
			DeletePacketData
		}
		swbreak
	swend
	if _sendFlag :return
	
	killerName = getPlayerName(_killerId)
	if _deaderId == _killerId {
		str_ = ""+ killerName +"は自分で命を絶った..."
	} else {
		deaderName = getPlayerName(_deaderId)
		str_ = ""+ deaderName +"は"+ killerName +"に風穴あけられた"
	}
	addChatLog str_, ID_SERVER
	
	return
	
	// プレイヤー位置確定
#deffunc tpPlayer int _playerId, int newPos, int newMapPos
	
	playerPosList._playerId		= newPos
	playerMapPosList._playerId	= newMapPos
	
	putPacketRule PACKET_TYPE_SETPOS, _playerId
	putPacketInt newPos
	putPacketInt newMapPos
	
	switch bootmode
	case BM_SERVER
		repeat playerCount
			if isBlankId(cnt, playerCount, player) || _playerId == cnt :continue
			sendPacket clientSocketList.cnt, true
		loop
		swbreak
		
	case BM_CLIENT
			sendPacket mainSocket, true
		swbreak
	swend
	DeletePacketData
	
	return
	
	// プレイヤー位置送信
#deffunc setPos int _playerId, int newPos, int newMapPos, int _recvFlag
	
	switch _recvFlag
	case true
		// プレイヤーデータを処理し、蔵に送信
		playerPosList._playerId		= newPos
		playerMapPosList._playerId	= newMapPos
	
/*		if BM_SERVER == bootmode {
			putPacketRule PACKET_TYPE_GETPOS, _playerId
			putPacketInt newPos
			putPacketInt newMapPos
			repeat playerCount
				if isBlankId(cnt, playerCount, player) || _playerId == cnt :continue	// 受信元蔵には送らない
				sendUDPPacket udpSocketList.cnt, true
			loop
			DeletePacketData
		}
		/**/
		swbreak
	
	case false
		// 壁当たり判定
		x = wordtoint(loword(newPos))
		y = wordtoint(hiword(newPos))
		mx = wordtoint(loword(newMapPos))
		my = wordtoint(hiword(newMapPos))
		mapWallHit x-mx, y-my
		if stat :swbreak
		playerPosList._playerId		= newPos
		playerMapPosList._playerId	= newMapPos
		
		// 座標を送信
		putPacketRule PACKET_TYPE_GETPOS, _playerId
		putPacketInt newPos
		putPacketInt newMapPos
		switch bootmode
		case BM_SERVER
		/*
			repeat playerCount
				if isBlankId(cnt, playerCount, player) :continue
				sendUDPPacket udpSocketList.cnt, true
			loop
			/**/
			DeletePacketData
			swbreak
			
		case BM_CLIENT
			sendUDPPacket udpServerSocket
			swbreak
		swend
		
		swbreak
	swend
	
	return
	
	// 壁当たり判定
#deffunc mapWallHit int _x, int _y
	
	if _x < 0 || _y < 0 :return true
	if mainWidth <= _x || mainHeight <= _y :clr = 0 :return true
	
	clr = vpgetex(_x, _y)
	
	if 0 == clr :return true
	return false
	
	/*
#deffunc putPlayersInfo int _playerId
	
	putPacketInt _playerId
	// PlayerPosList
	putPacketInt playerPosList._playerId
	putPacketInt playerMapPosList._playerId
		
	// PlayerNameList
	len = strlen(playerNameList._playerId)
	putPacketInt len
	putPacket playerNameList._playerId, 0, len
	
	return
	
	// 蔵にプレイヤー情報を送信
#deffunc sendPlayersInfo
	
	putPacketRule PACKET_TYPE_GETPLAYERSINFO, 0
	putPacketInt usedIdCount(playerCount, player)
	
	repeat playerCount
		if isBlankId(cnt, playerCount, player) :continue
		putPlayersInfo cnt
	loop
	
	repeat playerCount
		if isBlankId(cnt, playerCount, player) :continue
		changePacketPlayerId cnt
		sendPacket clientSocketList.cnt, true
	loop
	DeletePacketData
	
	return
	
#deffunc sendPlayerInfo int _playerId
	
	switch bootmode
	case BM_SERVER
		// 蔵にプレイヤー情報を送信
		putPacketRule PACKET_TYPE_GETPLAYERSINFO, _playerId
		putPacketInt usedIdCount(playerCount, player)
		
		repeat playerCount
			if isBlankId(cnt, playerCount, player) :continue
			putPlayersInfo cnt
		loop
		sendPacket socketId
		
		swbreak
		
	case BM_CLIENT
		// 鯖にプレイヤー情報を送信
		putPacketRule PACKET_TYPE_GETPLAYERINFO, _playerId
		
		// 名前 32byteまで
		sdim ptData, PLAYER_NAME_SIZE+1
		memcpy ptData, playerName, PLAYER_NAME_SIZE, 0, 0
		putPacket ptData, 0, PLAYER_NAME_SIZE, socketId
	
		// UDPポートも送る
		udpPort myUDPPort, udpServerSocket
		putPacketInt myUDPPort, socketId, true
		
		swbreak
		
	swend
	
	return
	/**/
	
	#define UD_INDEX_POS		0
	#define UD_INDEX_MAPPOS		4
	#define UD_INDEX_GUNTYPE	8
	#define UD_INDEX_SWTYPE		12
	#define UD_INDEX_COLOR		16
	#define UD_INDEX_CMDLEVEL	20
	#define UD_INDEX_TEAMLEN	24
	#define UD_INDEX_TEAMNAME	28
	#define UD_INDEX_SIZE		28
	
	// 鯖にプレイヤー情報を保存
#deffunc savePlayerInfo int _playerId
	
	if BM_CLIENT == bootmode :return
	
	fileName = getPlayerName(_playerId) +"_"+ playerIPList._playerId
	urlencode fileName, fileName
	fileName	= "data\\"+ fileName +".dat"
	
	saveFileName fileName
	pushFileData playerPosList._playerId
	pushFileData playerMapPosList._playerId
	pushFileData playerGunTypeList._playerId
	pushFileData playerSubWeaponTypeList._playerId
	pushFileData playerColorList._playerId
	pushFileData playerCommandLevel._playerId
	pushFileData teamNameList.playerTeamList(_playerId)
	saveToFile
	
	return
	
#deffunc loadPlayerInfoData int _playerId
	
	fileName	= getPlayerName(_playerId) +"_"+ playerIPList._playerId
	urldecode fileName, fileName
	fileName	= "data\\"+ fileName +".dat"
	
	loadFile fileName
	if -1 == stat {
		logmes "joined new player"
		teamId = 0
		
		return
	}
	
	logmes "load player info"
	
	playerPosList._playerId				= popFileData()
	playerMapPosList._playerId			= popFileData()
	playerGunTypeList._playerId			= popFileData()
	playerSubWeaponTypeList._playerId	= popFileData()
	playerColorList._playerId			= popFileData()
	playerCommandLevel._playerId		= popFileData()
	teamName = popFileData("str")
	
	addChat "/tp "+ getPlayerName(_playerId) +" "+ loword(playerPosList._playerId) +" "+ hiword(playerPosList._playerId) +" "+ loword(playerMapPosList._playerId) +" "+ hiword(playerMapPosList._playerId), ID_SERVER
	sendGunType _playerId, true
	
	teamId = findTeamId(teamName)
	if -1 == teamId {
		addChat "/team add "+teamName, ID_SERVER
		teamId = findTeamId(teamName)
	} else {
		sendChatToClient findCmdId("/team")+CMD_ANY, "/team add "+teamName, ID_SERVER, _playerId
	}
	
	return

	// 鯖にプレイヤー情報を読み込み
#deffunc loadPlayerInfo int _playerId
	
	logmes "joined player ["+ playerNameList._playerId +"] id["+ _playerId +"]"
	
	playerIPList._playerId = getIpFromInfo(_playerId)
	playerIPNameList._playerId = getIpNameFromInfo(_playerId)
	
	// ブラック/ホワイトリスト判定
	if blackListFlag {
		isBlackList = false
		repeat blackListCount
			if isBlankId(cnt, blackListCount, blackList) :continue
			if getPlayerName(_playerId) == blackListName.cnt || playerIPList._playerId == blackListIP.cnt {
				isBlackList = true
				break
			}
		loop
		if isBlackList {
			logmes "blacklisted ["+ getPlayerName(_playerId) +"] IP["+ playerIPNameList._playerId +"]"
			closeSocket _playerId
			return -1
		}
	}
	if whiteListFlag {
		isWhiteList = true
		repeat blackListCount
			if isBlankId(cnt, whiteListCount, whiteList) :continue
			if getPlayerName(_playerId) == whiteListName.cnt || playerIPList._playerId == whiteListIP.cnt {
				isWhiteList = false
				break
			}
		loop
		if isWhiteList {
			logmes "whitelisted ["+ getPlayerName(_playerId) +"] IP["+ playerIPNameList._playerId +"]"
			closeSocket _playerId
			return -1
		}
	}
	
	// 同期
	// プレイヤー / 座標
	repeat playerCount
		if isBlankId(cnt, playerCount, player) || cnt == _playerId :continue
		putPacketRule PACKET_TYPE_LOGIN, cnt
		putPacketRule PACKET_TYPE_PLAYERNAME, cnt
		len = strlen(playerNameList.cnt)
		putPacketInt len
		putPacket playerNameList.cnt, 0, len
	loop
	sendPacket clientSocketList._playerId
	
	// チーム / 色
	repeat teamCount
		if isBlankId(cnt, teamCount, team) :continue
		sendChatToClient findCmdId("/team")+CMD_ANY, "/team add "+ teamNameList.cnt, ID_SERVER, _playerId
		sendChatToClient findCmdId("/color")+CMD_ANY, "/color team "+ teamNameList.cnt +" "+ teamColorList.cnt, ID_SERVER, _playerId
	loop
	repeat playerCount
		if isBlankId(cnt, playerCount, player) || cnt == _playerId :continue
		sendChatToClient findCmdId("/team")+CMD_ANY, "/team join "+ teamNameList(playerTeamList.cnt) +" "+ playerNameList.cnt, ID_SERVER, _playerId
		sendChatToClient findCmdId("/color")+CMD_ANY, "/color player "+ playerNameList.cnt +" "+ playerColorList.cnt, ID_SERVER, _playerId
	loop
	
	// リスポーン地点
	repeat respawnCount
		if isBlankId(cnt, respawnCount, respawn) :continue
		x = wordtoint(loword(respawnPos.cnt))
		y = wordtoint(hiword(respawnPos.cnt))
		mx = wordtoint(loword(respawnMapPos.cnt))
		my = wordtoint(hiword(respawnMapPos.cnt))
		if 0 == cnt {
			sendChatToClient findCmdId("/worldspawn")+CMD_ANY, "/worldspawn set "+ x +" "+ y +" "+ mx +" "+ my +" "+ teamNameList.respawnTeamList(cnt), ID_SERVER, _playerId
		} else {
			sendChatToClient findCmdId("/worldspawn")+CMD_ANY, "/worldspawn add "+ x +" "+ y +" "+ mx +" "+ my +" "+ teamNameList.respawnTeamList(cnt), ID_SERVER, _playerId
		}
	loop
	
	// OP権限
	for i, 0, opCount, 1
		if isBlankId(i, opCount, op) :_continue
		switch commandPlayer.i
		case ID_SERVER
			sendChatToClient findCmdId("/op")+CMD_ANY, "/op level "+ commandLevelId.i +" all", ID_SERVER, _playerId
			swbreak
		case ID_SELF
			sendChatToClient findCmdId("/op")+CMD_ANY, "/op level "+ commandLevelId.i +" self", ID_SERVER, _playerId
			swbreak
		default
			sendChatToClient findCmdId("/op")+CMD_ANY, "/op level "+ commandLevelId.i +" "+ getPlayerName(commandPlayer.i), ID_SERVER, _playerId
			swbreak
		swend
		repeat commandCount
			if isBlankId(cnt, commandCount, command) :continue
			if false == sbGet(commandLevel.i, cnt) :continue
			sendChatToClient findCmdId("/op")+CMD_ANY, "/op level "+ commandLevelId.i +" "+ cmdList.cnt, ID_SERVER, _playerId
		loop
	next
	
	// ユーザー設定読み込み
	loadPlayerInfoData _playerId
	addChat "/color player "+ getPlayerName(_playerId) +" "+playerColorList._playerId, ID_SERVER
	addChat "/team join "+teamNameList.teamId+" "+getPlayerName(_playerId), ID_SERVER
	sendChatToClient findCmdId("/op")+CMD_ANY, "/op add "+ getPlayerName(_playerId) +" "+ playerCommandLevel._playerId, ID_SERVER, _playerId
	
	sendMapData _playerId	// マップ同期
	
	chatInvisible
	
	addChat ""+ getPlayerName(_playerId) +"がログインしました", ID_SERVER
		
	sendChatToClient findCmdId("/cls")+CMD_ANY, "/cls", ID_SERVER, _playerId
	
	playerHPList._playerId = playerDefaultHP
	playerReadyList._playerId = true
	
	return
	
#deffunc loginPlayer int _socketId

	if BM_SERVER != bootmode :return
	
	sdim info, 64
	if _socketId {
		tcpinfo info, _socketId
		logmes "accept socket "+ info
	} else {
		logmes "not accept. this is AI?"
	}
	
	newId = getBlankId(playerCount, player, playerMax)
	spawnPlayer newId
	
	playerHPList.newId		= 0
	clientSocketList.newId	= _socketId
	playerInfoList.newId	= info
	
	socketId = _socketId
	
	putPacketRule PACKET_TYPE_LOGIN, newId
	repeat playerCount
		if isBlankId(cnt, playerCount, player) :continue
		sendPacket clientSocketList.cnt, true
	loop
	deletePacketData
	
	return
	
#deffunc logoutPlayer int _playerId
	
	logmes "disconnected ["+ getPlayerName(_playerId) +"]"
	
	// プレイヤー情報保存
	addChatLog ""+ getPlayerName(_playerId) +"がログアウトしました", ID_SERVER
	
	switch bootmode
	case BM_SERVER

		putPacketRule PACKET_TYPE_LOGOUT, _playerId
		repeat playerCount
			if isBlankId(cnt, playerCount, player) || _playerId == cnt :continue
			sendPacket clientSocketList.cnt, true
		loop
		deletePacketData
		
		savePlayerInfo _playerId
		swbreak
	swend
	
	setBlankId _playerId, player
	
	return
	
#deffunc changePlayerName int _playerId
	
	putPacketRule PACKET_TYPE_PLAYERNAME, _playerId
	
	// PlayerNameList
	len = strlen(playerNameList._playerId)
	putPacketInt len
	putPacket playerNameList._playerId, 0, len
	
	switch bootmode
	case BM_SERVER
		repeat playerCount
			if isBlankId(cnt, playerCount, player) || _playerId == cnt :continue
			sendPacket clientSocketList.cnt, true
		loop
		deletePacketData
	
		swbreak
		
	case BM_CLIENT
		sendPacket socketId
		swbreak
	swend
	
	return
	
	// プレイヤーを設置する
#deffunc spawnPlayer int _playerId
	
	udpPortList._playerId		= 0
	udpSocketList._playerId		= 0
	clientSocketList._playerId	= 0
	playerIPList._playerId		= 0
	playerIPNameList._playerId	= ""
	playerInfoList._playerId	= ""
	playerCommandLevel._playerId	= DEFAULT_COMMAND_LEVEL
	playerReadyList._playerId	= false
	
	playerIsAIList._playerId	= false
	playerRouteList._playerId	= ""
	playerTargetList._playerId	= ID_SERVER
	
	switch bootmode
	case BM_SERVER
		gunWaitTime._playerId		= 0
		gunRestCount._playerId		= 0
		swbreak
	swend
	
	spawnWaitTime._playerId		= 0
	playerPosList._playerId		= respawnPos
	playerMapPosList._playerId	= respawnMapPos
	playerNameList._playerId	= ""
	playerGunTypeList._playerId	= GUN_TYPE_HANDGUN
	playerHPList._playerId		= playerDefaultHP
	playerTeamList._playerId	= TEAM_NEUTRAL
	playerColorList._playerId	= playerDefaultColor
	playerSubWeaponTypeList._playerId	= GUN_TYPE_H_E
	
	return
	
	// プレイヤー再設置
#deffunc respawnPlayer int _playerId
	
	playerHPList._playerId	= playerDefaultHP
	
	if playerIsAIList._playerId {
		playerIsAIList._playerId = 1
	}
	
	switch bootmode
	case BM_SERVER
		if false == playerIsAIList._playerId :return
		swbreak
		
	case BM_CLIENT
		if _playerId != myPlayerId :return
		swbreak
	swend
	
	resId = getRespawnId(_playerId)
	if -1 == resId :return
	addChat "/tp "+ getPlayerName(_playerId) +" "+ loword(respawnPos.resId) +" "+ hiword(respawnPos.resId) +" "+ loword(respawnMapPos.resId) +" "+ hiword(respawnMapPos.resId), ID_SERVER
	logmes "respawn "+ _playerId +":"+ respawnPos.resId +"-"+ respawnMapPos.resId
	
	return
	
#defcfunc getPlayerName int _playerId
	
	if _playerId <= ID_UNKNOWN :return "unknown name"
	
	switch _playerId
	case ID_SERVER
		return "Server"
	case ID_TEXT
		return chatLogSender
	case ID_SELF
		return "自身"
	swend
	
	return playerNameList._playerId
	
#defcfunc getRespawnId int _playerId
	
	neutralId = findTeamId("無所属")
	max = 0
	repeat respawnCount
		if isBlankId(cnt, respawnCount, respawn) :continue
		if respawnTeamList.cnt == playerTeamList._playerId || respawnTeamList.cnt == neutralId :max++
	loop
	if 0 == max {
		addChat "リスポーン地点が見つかりませんでした。", ID_SERVER
		addChat "/kick "+ playerNameList._playerId, ID_SERVER
		return -1
	} else {
		rn = rnd(max)
	}
	
	id = 0
	repeat respawnCount
		if isBlankId(cnt, respawnCount, respawn) :continue
		if respawnTeamList.cnt == playerTeamList._playerId || respawnTeamList.cnt == neutralId {
			if 0 < rn :rn-- :continue
			id = cnt
			break
		}
	loop
	return id
	
	// プレイヤーIDを検索
#defcfunc findBlackListId str _playerName
	selId = -1
	repeat blackListCount
		if isBlankId(cnt, blackListCount, blackList) :continue
		if _playerName == blackListName.cnt :selId = cnt :break
	loop
	
	if -1 == selId {
		addChatLog "指定したプレイヤーが見つかりませんでした", ID_SERVER
	}
	return selId
	
	// プレイヤーIDを検索
#defcfunc findWhiteListId str _playerName
	selId = -1
	repeat whiteListCount
		if isBlankId(cnt, whiteListCount, whiteList) :continue
		if _playerName == whiteListName.cnt :selId = cnt :break
	loop
	
	if -1 == selId {
		addChatLog "指定したプレイヤーが見つかりませんでした", ID_SERVER
	}
	return selId
	
	// プレイヤーIDを検索
#defcfunc findPlayerId str _playerName
	
	selId = -1
	repeat playerCount
		if isBlankId(cnt, playerCount, player) :continue
		if _playerName == playerNameList.cnt :selId = cnt :break
	loop
	
	if -1 == selId {
		addChatLog "指定したプレイヤーが見つかりませんでした", ID_SERVER
	}
	return selId
	
	
	// チームIDを検索
#defcfunc findTeamId str _teamName
	
	selId = -1
	repeat teamCount
		if isBlankId(cnt, teamCount, team) :continue
		if _teamName == teamNameList.cnt :selId = cnt :break
	loop
	
	if -1 == selId {
		addChatLog "指定したチームが見つかりませんでした", ID_SERVER
	}
	return selId
	
	
	// チーム変更を送信
#deffunc sendTeam int _type, int _teamId, int _playerId
	
	switch bootmode
	case BM_SERVER
		repeat playerCount
			if isBlankId(cnt, playerCount, player) :continue
			socketId = clientSocketList.cnt
			sendTeam_ _type, _teamId, _playerId
		loop
		swbreak
		
	case BM_CLIENT
		sendTeam_ _type, _teamId, _playerId
		swbreak
	swend
	
	return
	
#deffunc sendTeam_ int _type, int _teamId, int _playerId
	
	putPacketRule PACKET_TYPE_TEAM, _playerId
	putPacketInt _type
	switch _type
	case TEAM_TYPE_ADD
		len = strlen(teamNameList._teamId)
		putPacketInt len
		putPacket teamNameList._teamId, 0, len, socketId, true
		swbreak
		
	default
		putPacketInt _teamId, socketId, true
		swbreak
		
	swend
	
	return
	
	// 鯖専用 チームを作成させる
#deffunc sendTeams int _playerId
	
	repeat teamCount
		if isBlankId(cnt, teamCount, team) :continue
		socketId = clientSocketList._playerId
		sendTeam_ TEAM_TYPE_ADD, cnt, ID_SERVER
	loop
	
	return
	
	// チーム作成
#deffunc addTeam str _teamName

	newId = getBlankId(teamCount, team, teamMax)
	teamColorList.newId = teamDefaultColor
	teamNameList.newId = _teamName
	addChatLog "チーム["+ _teamName +"]を作成", ID_SERVER
	
	return newId
	
	// チーム解体
#deffunc removeTeam int _teamId
	
	repeat playerCount
		if isBlankId(cnt, playerCount, player) :continue
		if _teamId == playerTeamList.cnt {
			// 無所属へ
			playerTeamList.cnt = TEAM_NEUTRAL
		}
	loop
	setBlankId _teamId, team
	addChatLog "チーム["+ teamNameList._teamId +"]を解体", ID_SERVER
	
	return
	
	// チーム参加
#deffunc joinTeam int _teamId, int _playerId
	
	playerTeamList._playerId = _teamId
	addChatLog "チーム["+ teamNameList._teamId +"]に["+ getPlayerName(_playerId) +"]が参加", ID_SERVER
	
	return
	
	// チーム脱退
#deffunc leaveTeam int _teamId, int _playerId
	
	playerTeamList.cnt = TEAM_NEUTRAL
	addChatLog "チーム["+ teamNameList._teamId +"]から["+ getPlayerName(_playerId) +"]が脱退", ID_SERVER
	
	return
	
	
*_PLAYER_AS_END
	
	#endif
	
