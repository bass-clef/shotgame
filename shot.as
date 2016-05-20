	
	
	#ifndef APPNAME
	#include "shotgame.hsp"
	#endif
	
	#ifndef AS_SHOT
	#define AS_SHOT
	
goto *_SHOT_AS_END
	

	// �e���v�Z
#deffunc shotCalc
	
	sdim hitInfo :index = 0
	
	repeat shotCount
		if isBlankId(cnt, shotCount, shot) :continue
	
		prevX = shotXPosList.cnt
		prevY = shotYPosList.cnt
	
		calcWallHit cnt		// �Ǔ����蔻��
		if stat :setBlankId cnt, shot :continue
		
		if shotMaxRange.shotTypeList(cnt) < shotRangeList.cnt {
			// ���̋��������i�߂Ȃ�
			switch shotTypeList.cnt
			case GUN_TYPE_H_E	// ��֒e�͔����𐶐�
				newShot shotPlayerMasterList.cnt, GUN_TYPE_EXPLOSION, 0 :newId = stat
				shotXPosList.newId = double(shotXPosList.cnt)
				shotYPosList.newId = double(shotYPosList.cnt)
				swbreak
			swend
			
			setBlankId cnt, shot
		}
		
		if BM_SERVER == bootmode :calcPlayerHit cnt	// �l�����蔻��
	loop
	
	if index {
		sendHitInfo
	}
	
	return
	
	// �e�̕`��
#deffunc shotsDraw
	
	color
	repeat shotCount
		if isBlankId(cnt, shotCount, shot) :continue
		x = shotXPosList.cnt + myMapXPos
		y = shotYPosList.cnt + myMapYPos
		if x < 0 || y < 0 || viewMainWidth <= x || viewMainHeight <= y :continue
		x += xBase
		y += yBase
		
		switch shotTypeList.cnt
		case GUN_TYPE_EXPLOSION
			gmode 2
			xSize = loword(explosionSize)
			ySize = hiword(explosionSize)
			pos x-xSize/2, y-ySize/2 :gcopy explosionWndId, shotRangeList.cnt*xSize, 0, xSize, ySize
			gmode 0
			swbreak
			
		default
			r = shotRadius.shotTypeList(cnt)
			circle x-r, y-r, x+r, y+r
			swbreak
		swend
	loop
	
	return
	
	// �v���C���[�����蔻��v�Z �I�̂�
#deffunc calcPlayerHit int _shotId

	switch shotTypeList._shotId
	case GUN_TYPE_H_E
		// ��֒e�͒��ڂ̓����蔻��͍s��Ȃ�
		return
	swend
	
	for i, 0, playerCount, 1
		if isBlankId(i, playerCount, player) :_continue
		if spawnWaitTime.i :_continue	// �����ҋ@����
	
		x = wordtoint(loword(playerPosList.i))-wordtoint(loword(playerMapPosList.i))
		y = wordtoint(hiword(playerPosList.i))-wordtoint(hiword(playerMapPosList.i))
		hit = 0
		
		switch shotTypeList._shotId
		case GUN_TYPE_EXPLOSION
			if shotMaxRange.shotTypeList(_shotId)/2 != shotRangeList._shotId :swbreak
			hit = abs( limit(shotRadius.shotTypeList(_shotId) - dis2pt(x, y, prevX, prevY), 0, INT_MAX) )
			
			swbreak
			
		default
			if shotPlayerMasterList._shotId == i :_continue	// ���e
			// �t�����h���[�t�@�C�A
			if teamNeutralId != playerTeamList.i :if playerTeamList.shotPlayerMasterList(_shotId) == playerTeamList.i :_continue
			
			hit = pointerOnLine(prevX, prevY, shotXPosList._shotId, shotYPosList._shotId, x, y, playerRadius+shotRadius.shotTypeList(shotId))
			swbreak
		swend
		
		if hit {
			switch shotTypeList._shotId
			case GUN_TYPE_EXPLOSION
				// �����͓����蔻��ɂ���ď����Ȃ�
				playerHPList.i -= shotAttackList.shotTypeList(_shotId) * int(hit)
				swbreak
			default
				playerHPList.i -= shotAttackList.shotTypeList(_shotId)
				setBlankId _shotId, shot
				swbreak
			swend
	
			logmes "hit:"+ i +" from:"+ shotPlayerMasterList.shotId +" t:"+ playerTeamList.i +" != "+ playerTeamList.shotPlayerMasterList(_shotId)
			sendHitInfo i
			
			if playerHPList.i <= 0 {
				logmes "dead "+i
				killPlayer shotPlayerMasterList._shotId, i
			}
			_break
		}
	next

	return
	
	// �������񑗐M(�I������)
#deffunc sendHitInfo int _playerId
	
	socketId = clientSocketList._playerId
	putPacketRule PACKET_TYPE_GETHITINFO, ID_SERVER
	putPacket playerHPList._playerId, 0, 4, socketId, true
	
	return
	
	// �Ǔ����蔻��v�Z & ���Z
#deffunc calcWallHit int _shotId
	
	
	repeat shotSpeed.shotTypeList(_shotId)
		if shotXPosList._shotId < 0 || shotYPosList._shotId < 0 :clr = 0 :break	// vpget�̊֌W
		if mainWidth <= shotXPosList._shotId || mainHeight <= shotYPosList._shotId :clr = 0 :break
		
		clr = vpgetex(shotXPosList._shotId, shotYPosList._shotId)
		
		switch shotTypeList(_shotId)
		case GUN_TYPE_EXPLOSION
			if 0 == clr :clr = 1 :swbreak
			swbreak
			
		case GUN_TYPE_H_E
			if 0 == clr :clr = 1 :swbreak
			r = limitf( sin(M_PI/2.0 / double(shotMaxRange.shotTypeList(_shotId)) * double(shotMaxRange.shotTypeList(_shotId)-shotRangeList._shotId)) , 0, 1)
			shotXPosList._shotId += cos(shotAngleList._shotId)*r
			shotYPosList._shotId += sin(shotAngleList._shotId)*r
			swbreak
			
		default:
			shotXPosList._shotId += cos(shotAngleList._shotId)
			shotYPosList._shotId += sin(shotAngleList._shotId)
			swbreak
		swend
		shotRangeList._shotId++
		
		if 0 == clr :break
	loop
	
	if 0 == clr :return true
	
	return false	
	
	// �����C
#deffunc subGunFire int _type
	
	x = wordtoint(loword(playerPosList.myPlayerId)) + xBase
	y = wordtoint(hiword(playerPosList.myPlayerId)) + yBase
	angle = atan(mousey-y, mousex-x) - shotBlurAngle.playerSubWeaponTypeList(myPlayerId)/2.0
	rndf_get drnd
	angle += shotBlurAngle.playerSubWeaponTypeList(myPlayerId) * drnd
	
	sendSubShot myPlayerId, _type, angle
	
	newShot myPlayerId, _type, angle
	
	return
	
	// ���C
#deffunc gunFire int _id, int _x, int _y, int _mx, int _my
	
	angle = atan(_my - _y, _mx - _x) - shotBlurAngle.playerGunTypeList(_id)/2.0
	rndf_get drnd
	angle += shotBlurAngle.playerGunTypeList(_id) * drnd
	
	sendShot _id, angle
	
	newShot _id, playerGunTypeList._id, angle
	
	return
	
	// �e��ނ̑��M
#deffunc sendGunType int _playerId, int _sendFlag
	
	putPacketRule PACKET_TYPE_GETGUNCHANGE, _playerId
	putPacket playerGunTypeList._playerId, 0, 4
	
	switch bootmode
	case BM_SERVER	// �I�͑S���ɑ��M
		repeat playerCount
			if isBlankId(cnt, playerCount, player) || (false == _sendFlag && cnt == _playerId) :continue	// ��M�������ɂ͑���Ȃ�
			sendPacket clientSocketList.cnt, true
		loop
		DeletePacketData
		
		swbreak
		
	case BM_CLIENT	// ���͎I�ɑ��M
		sendPacket mainSocket
		swbreak
	swend
	
	return
	
	// ���e���̑��M
#deffunc sendSubShot int _playerId, int _type, double _angle, int _recvFlag
	
	putPacketRule PACKET_TYPE_SUBWEAPON, _playerId
	putPacketInt _type
	putPacketDouble _angle
	
	switch bootmode
	case BM_SERVER
		repeat playerCount
			if isBlankId(cnt, playerCount, player) || (_recvFlag && _playerId == cnt) :continue
			sendUDPPacket udpSocketList.cnt, true
		loop
		DeletePacketData
		swbreak
		
	case BM_CLIENT
		sendUDPPacket udpServerSocket
		swbreak
	swend
	
	return
	
	// �e���̑��M
#deffunc sendShot int _playerId, double _angle, int _recvFlag
	
	putPacketRule PACKET_TYPE_GETGUNANGLE, _playerId
	putPacketDouble _angle
	
	switch bootmode
	case BM_SERVER
		repeat playerCount
			if isBlankId(cnt, playerCount, player) || (_recvFlag && _playerId == cnt) :continue
			sendUDPPacket udpSocketList.cnt, true
		loop
		DeletePacketData
		swbreak
		
	case BM_CLIENT
		sendUDPPacket udpServerSocket
		swbreak
	swend
	
	return
	
	// �e�̔��s
#deffunc newShot int _playerId, int _type, double _angle
	
	if BM_CLIENT == bootmode {
		volume = double(masterVolume) / masterVolumeMax * soundVolumeList._type
		mx = loword(playerPosList.myPlayerId)+abs(wordtoint(loword(playerMapPosList.myPlayerId)))
		my = hiword(playerPosList.myPlayerId)+abs(wordtoint(hiword(playerMapPosList.myPlayerId)))
		ex = loword(playerPosList._playerId)+abs(wordtoint(loword(playerMapPosList._playerId)))
		ey = hiword(playerPosList._playerId)+abs(wordtoint(hiword(playerMapPosList._playerId)))
		r = sqrt(powf(mx-ex, 2) + powf(my-ey, 2))
		r = volume / limitf(r, 10.0, 1000.0)
		mciplay soundList._type, r
	}
	
	newId = getBlankId(shotCount, shot, shotMax)
	shotXPosList.newId = double( wordtoint(loword(playerPosList._playerId)) - wordtoint(loword(playerMapPosList._playerId)) )
	shotYPosList.newId = double( wordtoint(hiword(playerPosList._playerId)) - wordtoint(hiword(playerMapPosList._playerId)) )
	shotRangeList.newId = 0
	shotAngleList.newId = _angle
	shotTypeList.newId = _type
	shotPlayerMasterList.newId = _playerId
	
	return newId
	
	
*_SHOT_AS_END
	#endif
