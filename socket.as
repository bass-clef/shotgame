	
	
	#ifndef APPNAME
	#include "shotgame.hsp"
	#endif
	
	#ifndef AS_SOCKET
	#define AS_SOCKET
	
	sdim packetBuffer
	packetSize = 0
	

goto *_SOCKET_AS_END

#deffunc popPacketString var _dest, var _index
	
	len = 0
	tcpRecv len, 0, 4, socketId
	
	memexpand _dest, len+1
	tcpRecv _dest, 0, len, socketId
	poke _dest, len, 0
	
	_index -= 4+len
	return
	
#deffunc popPacketInt var _dest, var _index
	tcpRecv _dest, 0, 4, socketId
	_index -= 4
	return
#deffunc popPacketDouble var _dest, var _index
	tcpRecv _dest, 0, 8, socketId
	_index -= 8
	return
	
	// �\�P�b�g�ɑ��M�����p�P�b�g��҂��ď�������
#deffunc checkSocketPacket
	
	waitSocket :st = stat
	if st :return
	dataSize = ret
	packetIndex = dataSize
	
	while 0 < packetIndex
		recvSocketPacket
	wend
	
	return
	
#deffunc recvSocketPacket
	
	// �p�P�b�g�̎�ނ��擾
	packetType = PACKET_TYPE_BEGIN
	popPacketInt packetType, packetIndex
	
	if packetType <= PACKET_TYPE_BEGIN || PACKET_TYPE_END <= packetType {
		logmes "invalid packet type "+packetType
		return true
	}
	
	playerId = 0
	popPacketInt playerId, packetIndex
	
	logmes "recv pid["+ playerId +"] packetT["+ packetType +"]"
	
	switch packetType
	case PACKET_TYPE_SETPOS		// ��/�I ���� �ʒu�����X�V
		p = 0 :mp = 0
		popPacketInt p, packetIndex
		popPacketInt mp, packetIndex
		
		setPos playerId, p, mp, true
		swbreak
	
	/*
	case PACKET_TYPE_GETPLAYERINFO	// �I �v���C���[�����擾
		sdim playerName, PLAYER_NAME_SIZE+1
		tcpRecv playerName, 0, PLAYER_NAME_SIZE, socketId
		tcpRecv udpPortList.playerId, 0, 4, socketId
		
		playerNameList.playerId = playerName
		
		loadPlayerInfo playerId	// �v���C���[���ǂݍ���
		if -1 == stat :swbreak
		
		logmes "joined player ["+ playerName +"] id["+ playerId +"]"
		
		swbreak
		
	case PACKET_TYPE_GETPLAYERSINFO	// �����v���C���[�����擾
		repeat playerCount
			setBlankId cnt, player
		loop
	
		tcpRecv count, 0, 4, socketId
		repeat count
			tcpRecv pid, 0, 4, socketId
			allocId pid, playerCount, player
			spawnPlayer pid
			
			tcpRecv playerPosList.pid, 0, 4, socketId
			tcpRecv playerMapPosList.pid, 0, 4, socketId
			
			len = 0
			tcpRecv len, 0, 4, socketId
			memexpand playerNameList.pid, len+1
			tcpRecv playerNameList.pid, 0, len, socketId
			poke playerNameList.pid, len, 0
		loop
		playerCount = length(playerPosList)
		
		if -1 == myPlayerId {
			logmes "recive my player id ["+ playerId +"]"
			
			myPlayerId = playerId
			spawnPlayer myPlayerId
			// ���񂾂����[�U�[�����I�ɒʒm
			socketId = mainSocket
			
			sendPlayerInfo myPlayerId
		}
		
		swbreak
		/**/
	
	case PACKET_TYPE_RECVCHAT		// ��/�I ���ʃ`���b�g��M
		popPacketInt chatType, packetIndex
		popPacketString chatBuffer, packetIndex
		
		recvChat chatType, chatBuffer, playerId
		sdim chatBuffer
		
		swbreak
	
	case PACKET_TYPE_GETGUNANGLE	// ��/�I ���ʊp�x��M
	
		angle = 0.0
		popPacketDouble angle, packetIndex
	
		newShot playerId, playerGunTypeList.playerId, angle
		
		swbreak
	
	case PACKET_TYPE_GETGUNCHANGE	// �I/�� ���ʏe��ޕύX
	
		popPacketInt playerGunTypeList.playerId, packetIndex
		switch bootmode
		case BM_SERVER
			sendGunType playerId
			swbreak
			
		case BM_CLIENT
			shotBarWidth = windowWidth/2 / gunDefaultRestCount.playerGunTypeList(myPlayerId)
			swbreak
		swend
		swbreak
		
	case PACKET_TYPE_SUBWEAPON		// �I/�� ���ʕ��e���C
	
		angle = 0.0
		popPacketInt type, packetIndex
		popPacketDouble angle, packetIndex
	
		newShot playerId, type, angle
		
		swbreak
		
	case PACKET_TYPE_GETHITINFO		// ����HP�����擾
	
		oldMyHp = playerHPList.myPlayerId
		popPacketInt playerHPList.myPlayerId, packetIndex
		
		if playerHPList.myPlayerId <= 0 {
			playerHPList.myPlayerId = 0
			spawnWaitTime.myPlayerId = respawnWaitTime
		}
		hpBarCount = hpBarDefaultCount
		logmes "hited "+ playerHPList.myPlayerId
		
		swbreak
	
	case PACKET_TYPE_PLAYERKILL		// �I/�� ���ʎ��S�ʒm���󂯎�� (�I���󂯎��̂̓R�}���h�ɂ��kill�̂�)
	
		killerId = -1
		deaderId = -1
		popPacketInt killerId, packetIndex
		popPacketInt deaderId, packetIndex
	
		killPlayer killerId, deaderId
		if deaderId == myPlayerId {
			myKillerId = killerId
		}
		
		swbreak
	
	case PACKET_TYPE_MAPCHANGE		// �����}�b�v�ύX����M
		
		x = 0
		y = 0
		selId = 0
		popPacketInt x, packetIndex
		popPacketInt y, packetIndex
		popPacketInt selId, packetIndex
		
		editMapTip x, y, selId
		
		swbreak
	
	case PACKET_TYPE_MAPDATA	// �����}�b�v�S�̂��擾
		
		recvMapData
		
		packetIndex -= stat
		swbreak
	
	case PACKET_TYPE_CHANGECOLOR	// �I/�� ���ʐF�ύX��M
	
		popPacketInt type, packetIndex
		popPacketInt clr, packetIndex
		
		changeColor playerId, type, clr, BM_SERVER == bootmode
		
		swbreak
	
	case PACKET_TYPE_TEAM			// �`�[���̓���
		
		popPacketInt type, packetIndex
		switch type
		case TEAM_TYPE_ADD
			popPacketString teamName, packetIndex
			
			addTeam teamName
			swbreak
			
		default
			popPacketInt teamId, packetIndex
			switch type
			case TEAM_TYPE_REMOVE	:removeTeam teamId			:swbreak
			case TEAM_TYPE_JOIN		:joinTeam teamId, playerId	:swbreak
			case TEAM_TYPE_LEAVE	:leaveTeam teamId, playerId	:swbreak
			swend
			swbreak
			
		swend
		
		swbreak
	
	case PACKET_TYPE_LOGIN			// �I ����V�v���C���[�̒ʒm
		
		allocId playerId, playerCount, player
		spawnPlayer playerId
		
		if -1 != myPlayerId :swbreak
		
		myPlayerId = playerId
		playerNameList.myPlayerId = playerName
		changePlayerName myPlayerId
		
		udpPort myUDPPort, udpServerSocket
		
		putPacketRule PACKET_TYPE_UDPSOCKET, myPlayerId
		putPacketInt myUDPPort
		sendPacket socketId
		
		swbreak
		
	case PACKET_TYPE_LOGOUT			// �I ����v���C���[�̍폜
		setBlankId playerId, player
		swbreak
	
	case PACKET_TYPE_PLAYERNAME
		newNameFlag = false
		if "" == playerNameList.playerId :newNameFlag = true
		
		popPacketString playerNameList.playerId, packetIndex
		
		if BM_SERVER != bootmode :swbreak
	
		logmes "recv playerName "
		changePlayerName playerId
		if newNameFlag :loadPlayerInfo playerId
		
		swbreak
	
	case PACKET_TYPE_UDPSOCKET		// �� ����UDP�|�[�g��M
		popPacketInt udpPortList.playerId, packetIndex
		initUserUDPSocket playerId
		swbreak
	swend
	
	return
	
#deffunc checkUDPSocketPacket
	
	switch bootmode
	case BM_SERVER
		waitUDPSocket udpServerSocket :st = stat
		if 0 == st :swbreak
		
		repeat playerCount
			if isBlankId(cnt, playerCount, player) :continue
			waitUDPSocket udpSocketList.cnt :st = stat
			if 0 == st :recvUDPSocketPacket
		loop
		swbreak
		
	case BM_CLIENT
		waitUDPSocket udpServerSocket :st = stat
		swbreak
	swend
	if st :return
	
	recvPacketSize = 0
	udpCount recvPacketSize, udpSocket
	if 0 == recvPacketSize :return
	
	sdim udpPacketBuffer, recvPacketSize+1
	udpRecv udpPacketBuffer, 0, recvPacketSize, udpSocket
	udpPacketIndex = 0
	
	repeat
		recvUDPSocketPacket
		if stat < 0 :break
		if recvPacketSize <= udpPacketIndex :break
	loop
	
	return
	
#deffunc recvUDPSocketPacket
	
	// �p�P�b�g�̎�ނ��擾
	packetType = lpeek(udpPacketBuffer, udpPacketIndex) :udpPacketIndex += 4
	if packetType <= PACKET_TYPE_BEGIN || PACKET_TYPE_END <= packetType {
		logmes "invalid packet type "+packetType
		return -1
	}
	
	duplicateFlag = false
	udpPlayerId = lpeek(udpPacketBuffer, udpPacketIndex) :udpPacketIndex += 4
	if udpPlayerId == myPlayerId {
		duplicateFlag = true
		// udprecv duplication playerid
	}
	
	switch packetType
	case PACKET_TYPE_GETPOS		// �I���ʒu�����X�V
		if false == duplicateFlag {
			setPos udpPlayerId, lpeek(udpPacketBuffer, udpPacketIndex), lpeek(udpPacketBuffer, udpPacketIndex+4), true
		}
		udpPacketIndex += 8
		swbreak
		
	case PACKET_TYPE_GETGUNANGLE	// ��/�I ���ʊp�x��M
		if duplicateFlag {
			udpPacketIndex += 8
			swbreak
		}
		
		angle = 0.0
		memcpy angle, udpPacketBuffer, 8, 0, udpPacketIndex :udpPacketIndex += 8
	
		newShot udpPlayerId, playerGunTypeList.udpPlayerId, angle
		
		if BM_SERVER == bootmode {
			sendShot udpPlayerId, angle, true
		}
		swbreak
		
	case PACKET_TYPE_SUBWEAPON		// �I/�� ���ʕ��e���C
		if duplicateFlag {
			udpPacketIndex += 4+8
			swbreak
		}
	
		angle = 0.0
		memcpy type, udpPacketBuffer, 4, 0, udpPacketIndex :udpPacketIndex += 4
		memcpy angle, udpPacketBuffer, 8, 0, udpPacketIndex :udpPacketIndex += 8
	
		newShot udpPlayerId, type, angle
		
		if BM_SERVER == bootmode {
			sendSubShot udpPlayerId, type, angle, true
		}
		swbreak
	swend
	
	return 0
	
	// �p�P�b�g���l�߂�
#deffunc putPacket var _var, int _index, int _size, int _socketId, int _sendFlag
	
	if _size {
		memexpand packetBuffer, packetSize+_size+1
		
		memcpy packetBuffer, _var, _size, packetSize, _index
		packetSize += _size
	}
	
	if _sendFlag :sendPacket _socketId
	
	return packetSize-_size
	
	// �p�P�b�g���[���𑗐M
#deffunc putPacketRule int _packetType, int _playerId
	
	packetTypeIndex = packetSize
	putPacketInt _packetType
	
	packetPlayerIdIndex = packetSize
	putPacketInt _playerId
	
	return
	
#deffunc changePacketPlayerId int _playerId
	
	lpoke packetBuffer, packetPlayerIdIndex, _playerId
	
	return
	
#deffunc changePacketDataInt int _index, int _value
	
	lpoke packetBuffer, _index, _value
	
	return
	
	// �p�P�b�g���l�߂�
#deffunc putPacketInt int _value, int _socketId, int _sendFlag
	
	memexpand packetBuffer, packetSize+4+1
		
	lpoke packetBuffer, packetSize, _value
	packetSize += 4
	
	if _sendFlag :sendPacket _socketId
	
	return packetSize-4
	
	// �p�P�b�g���l�߂�
#deffunc putPacketDouble double _value, int _socketId, int _sendFlag
	
	value_ = _value
	putPacket value_, 0, 8, _socketId, _sendFlag
	
	return packetSize-8

#deffunc sendPacket int _socketId, int _noDeleteFlag
	
	if 0 != _socketId {
		logmes "sP ["+ packetBuffer +"] sz:"+ packetSize +" sid:"+ _socketId
		tcpSend packetBuffer, 0, packetSize, _socketId
	}
	
	if _noDeleteFlag :return
	DeletePacketData
	
	return

#deffunc sendUDPPacket int _socketId, int _noDeleteFlag
	
	if 0 != _socketId {
		udpIsCon _socketId :st = stat
		if 1 != st :return
	
//		logmes "sP ["+ packetBuffer +"] sz:"+ packetSize +" sid:"+ _socketId
		udpSend packetBuffer, 0, packetSize, _socketId
	}
	
	if _noDeleteFlag :return
	deletePacketData
	
	return
	
#deffunc deletePacketData
	sdim packetBuffer
	packetSize = 0
	return

#defcfunc getIpNameFromInfo int _playerId
	
	if -1 != instr(playerInfoList._playerId, 0, "[::1]") {
		ownip ip
		strrep playerInfoList._playerId, "[::1]", ip
		strrep playerInfoList._playerId, "127.0.0.1", ip
		strrep playerInfoList._playerId, "localhost", ip
	}
	sdim prms
	split playerInfoList._playerId, ":", prms
	ipName = prms.0
	
	return ipName

#defcfunc getIpFromInfo int _playerId
	return ipToInt(getIpNameFromInfo(_playerId))
	
#defcfunc ipToInt str _ip
	ip_ = _ip
	sdim prms
	split ip_, ".", prms
	
	ip_ = 0
	repeat 4
		poke ip_, cnt, int(prms.cnt)
	loop
	
	return ip_
	
	// �f�[�^�̓����𒲂ׂ�
#deffunc waitSocket

	ret = 0
	
	switch bootmode
	case BM_SERVER
		// �N���C�A���g���璅�M��҂�
		tcpWait mainSocket :st = stat
		if 2 == st :socketErrorDialog :end
		if st {
			tcpAccept newSocket, mainSocket
			loginPlayer newSocket
		}
	
		// �m�F
		if 0 == playerCount :st = -1
		repeat playerCount
			if isBlankId(cnt, playerCount, player) :continue
			if 0 == clientSocketList.cnt :continue
			
			tcpFail clientSocketList.cnt :st = stat
			if st :closeSocket cnt :continue
			
			tcpCount ret, clientSocketList.cnt :st = stat
			if stat :closeSocket cnt :continue
			if ret :socketId = clientSocketList.cnt :break
		loop
		swbreak
	
	case BM_CLIENT
		tcpFail mainSocket :st = stat
		if st :reConnect
		
		tcpCount ret, mainSocket :st = stat
		socketId = mainSocket
		swbreak
	swend
	
	if 0 == ret :return 1
	return st
	
#deffunc waitUDPSocket int _socketId

	if 0 == _socketId :return 1
	
	udpError errorCode, _socketId :st = stat

	udpFail _socketId :st = stat
	if st :return 1
	
	udpCheck ret, _socketId :st = stat
	if 0 == ret || st :return 1
	
	udpSocket = _socketId
	
	return 0
	
#deffunc closeSocket int _playerId
	
	if clientSocketList._playerId	:tcpClose clientSocketList._playerId
	if udpSocketList._playerId		:udpClose udpSocketList._playerId
	
	clientSocketList._playerId = 0
	udpSocketList._playerId = 0
	
	// ���O�A�E�g����
	logoutPlayer _playerId
	
	return
	
	// �Đڑ�����
#deffunc reConnect
	
	oncmd 0
	dialog "�T�[�o�[�Ƃ̐ڑ�������܂����B\n�Đڑ����܂����H", 2, APPNAME+" - �ڑ��G���["
	if 7 == stat :end
	tcpClose mainSocket
	udpClose udpServerSocket
	myPlayerId = -1
	initSocket
	initUDPSocket
	oncmd 1
	
	return
	
	// �\�P�b�g�̏�����
#deffunc initSocket
	
	modalDialog dlgWndId, 250, 20
	
	switch bootmode
	case BM_SERVER
		// �\�P�b�g�ł̃T�[�o�[�̏�����
		title APPNAME+" - �쐬��..."
		tcpmake mainSocket, port
		if stat :dialog "�\�P�b�g�̍쐬�Ɏ��s���܂����B", 1 :end
		natInitForSocket mainSocket
		gsel dlgWndId, -1
		
		swbreak
	
	case BM_CLIENT
		// �\�P�b�g�ł̐ڑ�
		title APPNAME+" - �ڑ���..."
	
		*reTCPOpen
		tcpOpen mainSocket, hostip, port :st = stat
		natInitForSocket mainSocket
		if st :logmes "tcpOpen" :socketErrorDialog :swbreak
		repeat
			wait 1
			tcpIsCon mainSocket :st = stat
			if 2 == st :st = -1 :break
			if 1 == st :break
		loop
		if -1 == st :tcpClose mainSocket :goto *reTCPOpen
		gsel dlgWndId, -1
		socketId = mainSocket
		
		swbreak
	swend
	
	return
	
#deffunc initUDPSocket
	
	switch bootmode
	case BM_SERVER
		// �����炭��M��p
		udpSock udpServerSocket, usingUDPPort :st = stat
		natInitForSocket udpServerSocket
		swbreak
		
	case BM_CLIENT
		ownip ip
		if hostip == ip {
			udpSock udpServerSocket :st = stat
		} else {
			udpSock udpServerSocket, /**/usingUDPPort/**/ :st = stat
		}
		natInitForSocket udpServerSocket
		udpSendTo udpServerSocket, hostip, usingUDPPort
		swbreak
	swend
	
	if st :dialog "�\�P�b�g�̍쐬�Ɏ��s���܂����B", 1 :end
	return st
	
#deffunc initUserUDPSocket int _playerId

	logmes "make user udp socket"
	udpSock udpSocketList._playerId :st = stat
	natInitForSocket udpSocketList._playerId
	
	ownip ip
	if ip == playerIPNameList._playerId {
		udpSendTo udpSocketList._playerId, playerIPNameList._playerId, udpPortList._playerId
	} else {
		udpSendTo udpSocketList._playerId, playerIPNameList._playerId, usingUDPPort/**udpPortList._playerId/**/
	}
	logmes "s:"+ udpSocketList._playerId +" ip["+ playerIPNameList._playerId +"] port["+ udpPortList._playerId +"]"
	
	if st :dialog "�\�P�b�g�̍쐬�Ɏ��s���܂����B", 1 :end
	return st
	
	
	// NAT �̏�����
#deffunc natInitForSocket int _socketId
	
	if 0 == _socketId :return
	
	sdim ip
	ownip ip
	isip ip
	if 2 == stat :priv = 1

	if priv {
		logmes "�v���C�x�[�g�A�h���X�ł�."
		logmes "�C���^�[�l�b�g�Q�[�g�E�F�C�̌��o��..."
		
		repeat
			natinit :st_ = stat
			if st_ :break
			wait 1
		loop
		
		if 1 == st {
			logmes "�C���^�[�l�b�g�Q�[�g�E�F�C�����o����܂���."
			logmes "�|�[�g�}�b�s���O��o�^���Ă��܂�..."
			
			natbind _socketId, port
			repeat
				natcheck _socketId :st_ = stat
				if st_ :break
				wait 1
			loop
			
			if 1 < st_ {
				logmes "Bind�Ɏ��s���܂���."
			} else {
				exaddr = refstr
				getstr exaddr, exaddr, 0, ':'
				logmes refstr +"�����蓖�Ă��܂���."
			}
		} else {
			logmes "�C���^�[�l�b�g�Q�[�g�E�F�C�����o�ł��܂���ł���."
		}
	}

	return	
	

	// �N���ݒ�
#deffunc bootOption
	
	sdim serverPropertyFiles
	
	currentDirectory = dir_cur
	chdir "server"
	dirlist serverPropertyFiles, "*.dat", 1
	
	// GUI
	initGUI blackWndId, whiteWndId, workWndId, fSize, xMargin, yMargin
	
	wx = 400
	modalDialog dlgWndId, 600, 400
	title APPNAME+" - �N���ݒ�"
	
	font msgothic, fSize*2
	objmode 2
	pos xMargin, yMargin
	
	objsize wx-xMargin*2-100, 20
	mes "�ڑ���IP�A�h���X:"
	y = ginfo_cy
	input hostip :hostipId = stat
	font msgothic, fSize*2
	
	guiOption 100, 20, GUI_S_SHOW
	pos ginfo_cx+winfo(31)+xMargin, y
	makeButton "���g��IP�g�p" :useThisSelfPCIPBtnId = stat
	
	pos xMargin, y+20
	objsize (wx-xMargin*2)/2, 20
	mes ""
	y = ginfo_cy
	str_ = "�|�[�g�ԍ�"
	pos (wx-strlen(str_)*8)/2, y	:mes str_
	pos xMargin, y :mes "TCP"
	pos (wx-fSize*3-xMargin*2), y :mes "UDP"
	y = ginfo_cy
	pos xMargin, y				:input port
	pos winfo(31)+xMargin*2, y	:input usingUDPPort
	pos xMargin, y+20
	
	mes ""
	mes "�v���C���[��"
	input playerName, wx-xMargin, 20
	font msgothic, fSize
	mes "���I�𗧂Ă�ꍇ�͓��͂͂���܂���"
	font msgothic, fSize*2
	
	mes ""
	xx = (wx-xMargin*2)/2
	guiOption xx, 60, GUI_S_SHOW
	y = ginfo_cy
	makeButton "�N���C�A���g�ŋN��" :bootClientBtnId = stat
	pos ginfo_cx+xx+xMargin, y
	makeButton "�T�[�o�[�ŋN��" :bootServerBtnId = stat
	
	width ginfo(12), ginfo_cy+yMargin
	
	guiOption 200-xMargin*2, ginfo(13)-yMargin*3-fSize*2-yMargin*2, GUI_S_SHOW
	pos wx+xMargin, yMargin :makeList serverPropertyFiles :loadFileListId = stat
	guiOption 200-xMargin*2, fSize*2+yMargin*2, GUI_S_SHOW
	pos wx+xMargin, ginfo(13)-yMargin*3-fSize*2 :makeButton "�ݒ��ۑ�" :makeLoadFileBtnId = stat
	
	setListSelected loadFileListId, 0
	
	repeat
		if BM_NULL != bootmode :break
		w = mousew
		calcGUI mousex, mousey, getkey(1) & 0x8000, getkey(1) & 0x8000, w < 0, 0 < w
	
		if downedButton(useThisSelfPCIPBtnId) :ipToDefault
		if downedButton(bootClientBtnId) :bootOptionForClient
		if downedButton(bootServerBtnId) :bootOptionForServer
		if downedButton(makeLoadFileBtnId) :makeLoadingUserFile
		
		redraw 0
		drawGUI
		redraw 1
		wait 1
	loop
	
	chdir currentDirectory
	
	notesel@hsp serverPropertyFiles
	noteget@hsp userDataFile, getListSelected(loadFileListId)
	loadUserData "server\\"+userDataFile
	
	destroyGUIObject useThisSelfPCIPBtnId = stat
	destroyGUIObject bootClientBtnId
	destroyGUIObject bootServerBtnId
	destroyGUIObject loadFileListId
	destroyGUIObject makeLoadFileBtnId
	
	if BM_NULL == bootmode :end
	
	return
	
#deffunc makeLoadingUserFile
	fileName = playerName +"_"+ ipToInt(hostip) +"_"
	urlencode fileName, fileName
	
	userDataFile = fileName + USER_DATA_FILE
	saveUserData userDataFile, true
	
	sdim serverPropertyFiles
	dirlist serverPropertyFiles, "*.dat", 1
	changeGUIText loadFileListId, serverPropertyFiles
	notesel@hsp serverPropertyFiles
	repeat notemax
		if noteget(cnt) == userDataFile {
			setListSelected loadFileListId, cnt
			break
		}
	loop
	
	return
	
#deffunc ipToDefault
	
	ownip hostip
	objprm hostipId, hostip
	
	return
	
#deffunc bootOptionForClient
	
	bootmode = BM_CLIENT
	gsel dlgWndId, -1
	
	return
	
#deffunc bootOptionForServer
	
	bootmode = BM_SERVER
	gsel dlgWndId, -1
	
	return
	
*_SOCKET_AS_END
	
	#endif
