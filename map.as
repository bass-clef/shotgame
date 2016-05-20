	
	
	#ifndef APPNAME
	#include "shotgame.hsp"
	#endif
	
	#ifndef AS_MAP
	#define AS_MAP
	
	
	
goto *_MAP_AS_END

	// マップ編集
#deffunc editMap
	
	if chatActhivedFlag :return
	
	if mapBaseWaitTime {
		mapBaseWaitTime--
	} else {
		if keyDowned(keys.K_LEFT)	|| keyJustBeforeDown(keys.K_LEFT)	{
			mapBaseWaitTime = mapBaseInitWaitTime
			if xMapEditBase :xMapEditBase--
		}
		if keyDowned(keys.K_UP)		|| keyJustBeforeDown(keys.K_UP)		{
			mapBaseWaitTime = mapBaseInitWaitTime
			if yMapEditBase :yMapEditBase--
		}
		if keyDowned(keys.K_RIGHT)	|| keyJustBeforeDown(keys.K_RIGHT)	{
			mapBaseWaitTime = mapBaseInitWaitTime
			if xMapEditBase < (mainWidth-viewMainWidth)/mapTipWidth :xMapEditBase++
		}
		if keyDowned(keys.K_DOWN)	|| keyJustBeforeDown(keys.K_DOWN)	{
			mapBaseWaitTime = mapBaseInitWaitTime
			if yMapEditBase < (mainHeight-viewMainHeight)/mapTipHeight :yMapEditBase++
		}
	}
	
	if false == mapeditmode :return
	
	emx = (mousex-xBase)/mapTipWidth+xMapEditBase
	emy = (mousey-yBase)/mapTipHeight+yMapEditBase
	if emx < 0 || emy < 0 || mainWidth/mapTipWidth <= emx || mainHeight/mapTipHeight <= emy :return
	if keyDowning(keys.K_SHOT)		:editMapTip emx, emy, mapSelId
	if keyDowning(keys.K_SUBSHOT)	:editMapTip emx, emy, ASTAR_WALL
	
	return
	
#deffunc editMapTip int _x, int _y, int _value, int _playerId
	
	if _x < 0 || _y < 0 || mainWidth/mapTipWidth <= _x || mainHeight/mapTipHeight <= _y :return
	if _value == map(_x, _y) :return
	map(_x, _y) = _value
	
	gsel backWndId
	gmode 4,,, 255 :color 0, 117, 117
	mapTipDraw _x, _y, map(_x, _y)
	gmode 0
	gsel mainWndId
	
	if BM_SERVER == bootmode :sendMaptipData _x, _y, _value
	
	return
	
#deffunc mapTipDraw int _x, int _y, int _md
	
	if ASTAR_WALL == _md {
		color
		boxf _x * mapTipWidth, _y * mapTipHeight, _x * mapTipWidth +mapTipWidth, _y * mapTipHeight +mapTipHeight
		color 117, 117, 117
	} else {
		pos _x * mapTipWidth, _y * mapTipHeight
		gcopy mapWndId, loword(_md)*mapTipWidth, hiword(_md)*mapTipHeight, mapTipWidth, mapTipHeight
	}
	
	return
	
#deffunc allMapTipRedraw
	
	gsel backWndId
	color :boxf
	gmode 4,,, 255 :color 0, 117, 117
	for i, 0, mapHeight, 1
		repeat mapWidth
			mapTipDraw cnt, i, map(cnt, i)
		loop
	next
	gsel mainWndId
	
	return
	
#deffunc sendMaptipData int _x, int _y, int _value
	
	putPacketRule PACKET_TYPE_MAPCHANGE, ID_SERVER
	putPacketInt _x
	putPacketInt _y
	putPacketInt _value
		
	repeat playerCount
		if isBlankId(cnt, playerCount, player) :continue
		sendPacket clientSocketList.cnt, true
	loop
	DeletePacketData
	
	return
	
#deffunc sendMapData int _playerId
	
	huffmanEncoding map, mapWidth*mapHeight*4, mapDataHuffman :huffmanSize = stat
	logmes "mapsize "+ huffmanSize
	
	putPacketRule PACKET_TYPE_MAPDATA, ID_SERVER
	putPacketInt huffmanSize, socketId
	
	putPacket mapDataHuffman, 0, huffmanSize
	sendPacket clientSocketList._playerId
	logmes "send mapData"
	
	return
	
#deffunc recvMapData
	
	mapLoading = true
	tcpRecv huffmanSize, 0, 4, socketId
	sdim mapDataHuffman, huffmanSize+1
	logmes "mapDataSize "+huffmanSize
	recivedMapDataSize = huffmanSize
	mapIndex = 0
	
	repeat
		tcpRecv mapDataHuffman, mapIndex, recivedMapDataSize, socketId :st = stat
		recivedMapDataSize -= st
		mapIndex += st
		logmes "recv mapSize "+st
		if 0 == recvMapDataSize :break
	
		// マップデータが足りないと待機
		repeat
			waitSocket
			if 0 == stat :break
			wait 1
		loop
	loop
	
	huffmanDecoding mapDataHuffman, mapData
	memcpy map, mapData, mapWidth*mapHeight*4
	
	allMapTipRedraw
	mapLoading = false
	
	return 4+huffmanSize


*_MAP_AS_END
	
	
	#endif
