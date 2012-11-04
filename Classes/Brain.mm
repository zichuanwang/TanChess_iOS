//
//  Brain.m
//  Tan Chess HD
//
//  Created by Bluebitch on 11-5-17.
//  Copyright 2011年 TJU. All rights reserved.
//

#import "Brain.h"
#import "SimpleAudioEngine.h"
#import "ConnectedGameScene.h"
#import "OpenFeintGameScene.h"


@interface Brain(Private)
- (void)initData;
@end

@implementation Brain

//@synthesize movingChessmanCount = _movingChessmanCount;
@synthesize currentPlayer = _currentPlayer;
@synthesize Player1Lives = _Player1Lives;
@synthesize Player2Lives = _Player2Lives;
@synthesize currentChessman = _currentChessman;

- (id)init {
    if((self = [super init])) {
        _chessmans = [[NSMutableDictionary alloc] init];
        _props = [[NSMutableArray alloc] init];
        _toDestroy = [[NSMutableArray alloc] init];
        [self initData];
    }
    return self;
}

- (void)initData {
    _Player1Lives = 16;
    _Player2Lives = 16;
    _Player1Score = 0;
    _Player1Score = 0;
}

- (void)addChessman:(ChessmanSprite *)sprite withID:(int)ID {
    [_chessmans setObject:sprite forKey:[NSNumber numberWithInt:ID]];
}

- (void)addProp:(PropSprite *)sprite {
    [_props addObject:sprite];
}
                      
- (void)update {
}

- (void)checkPropValid {
    for(PropSprite *sprite in _props) {
        if(sprite.type == GROUP1) {
            [sprite checkValid:_Player1Score];
        }
        else {
            [sprite checkValid:_Player2Score];
        }
    }
}

- (void)shutDownCurrentChessmanEmitter {
    if(_currentChessman.isEmitterOn == NO) {
        return;
    }
    if( _currentChessman != nil && _currentChessman.body != nil )
	{
		b2Vec2 linear_speed_vec = _currentChessman.body->GetLinearVelocity();
		float linear_speed = linear_speed_vec.x * linear_speed_vec.x + linear_speed_vec.y * linear_speed_vec.y;
		if( linear_speed < 0.4 )
		{
			[_currentChessman shutDownEmitter];
		}
	}
}

- (void)checkDrop {
    [self shutDownCurrentChessmanEmitter];
    bool isDrop = NO;
	for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
		//Check whether a chessman is droped of not
		if(sprite.isDead == NO && [sprite checkAlive] == NO)
		{
            isDrop = YES;
            //NSLog(@"%f,%f",sprite.position.x,sprite.position.y);
            [[SimpleAudioEngine sharedEngine] playEffect:@"drop.wav"];
            if(sprite.isBetray) {
                [sprite.NewBackColor runAction:[CCFadeOut actionWithDuration:0.3]];
            }
            else {
                [sprite runAction:[CCFadeOut actionWithDuration:0.3]];
            }
            [sprite.Image runAction:[CCFadeOut actionWithDuration:0.3]];
            sprite.isDead = YES;
            if(sprite.type == GROUP1) { 
                _Player1Score += sprite.value;
                _Player1Lives --;
                if(_currentPlayer == PLAYER2)
                {
                    _Player2Score += sprite.value / 2;
                }
            }
            else {
                _Player2Score += sprite.value;
                _Player2Lives --;
                if(_currentPlayer == PLAYER1)
                {
                    _Player1Score += sprite.value / 2;
                }
            }
            [self checkPropValid];
            [_toDestroy addObject:sprite];
        }
		//If the linear speed of a chessman is too small, stop it
		if(sprite.body != nil)
		{
			b2Vec2 linear_speed_vec = sprite.body->GetLinearVelocity();
			float linear_speed = linear_speed_vec.x * linear_speed_vec.x + linear_speed_vec.y * linear_speed_vec.y;
            if( linear_speed == 0 )
            {
                //sprite.isMoving = NO;
                sprite.body->SetAngularVelocity(0);
                //_movingChessmanCount--;
                //NSLog(@"- %d ID: %d",_movingChessmanCount, sprite.ID);
            }
			else if( linear_speed <= 0.08f )
			{
				sprite.body->SetLinearVelocity(b2Vec2(0, 0));
                //sprite.isMoving = NO;
                sprite.body->SetAngularVelocity(0);
                //_movingChessmanCount--;
                //NSLog(@"- %d ID: %d",_movingChessmanCount, sprite.ID);
			}
		}
	}
    if(isDrop)
        [_hostLayer stopDestroyChessman];
}

- (void)setHostLayer:(id)hostLayer {
    _hostLayer = hostLayer;
}

- (bool)checkGameOver {
    return _Player1Lives <= 0 || _Player2Lives <= 0;
}

- (bool)stopDestroyedChessman {
    for(ChessmanSprite *sprite in _toDestroy) {
        if([sprite getOpacity] != 0) {
            return NO;
        }
        else {
            b2Body *body = sprite.body;
            body->SetLinearVelocity(b2Vec2(0, 0));
            body->SetAngularVelocity(0);
            //sprite.isMoving = NO;
            //_movingChessmanCount--;
            //NSLog(@"- %d ID: %d",_movingChessmanCount, sprite.ID);
        }
    }
    return YES;
}

- (void)removeEmitter {
    for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
        [sprite removeEmitter];
    }
}

- (void)destroyChessmanBody
{
    for(ChessmanSprite *sprite in _toDestroy) {
        b2Body *body = sprite.body;
        if(body != nil) {
            body->SetActive(NO);
            sprite.body = nil;
            [_hostLayer destroyBody:body];
        }
    }
    [_toDestroy removeAllObjects];
}

- (void)changePlayer {
	if( _currentPlayer == PLAYER2 ) {
		for(id key in _chessmans) {
            ChessmanSprite *sprite = [_chessmans objectForKey:key];
            if(sprite.type == GROUP1)
                sprite.isForbad = NO;
            else
                sprite.isForbad = YES;
        }
        for(PropSprite *sprite in _props) {
            if(sprite.type == GROUP1)
                sprite.isForbad = NO;
            else
                sprite.isForbad = YES;
        }
		_currentPlayer = PLAYER1;
	}
	else {
		for(id key in _chessmans) {
            ChessmanSprite *sprite = [_chessmans objectForKey:key];
            if(sprite.type == GROUP1)
                sprite.isForbad = YES;
            else
                sprite.isForbad = NO;
        }
        for(PropSprite *sprite in _props) {
            if(sprite.type == GROUP1)
                sprite.isForbad = YES;
            else
                sprite.isForbad = NO;
        }
		_currentPlayer = PLAYER2;
	}
    NSLog(@"inner change player to %d", _currentPlayer);
}

- (void)changePlayerWhenConnecting {
	if( _currentPlayer == PLAYER2 ) {
		_currentPlayer = PLAYER1;
	}
	else {		
		_currentPlayer = PLAYER2;
	}
    for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
        if(sprite.type == GROUP1)
            sprite.isForbad = YES;
        else
            sprite.isForbad = YES;
    }
    for(PropSprite *sprite in _props) {
        if(sprite.type == GROUP1)
            sprite.isForbad = YES;
        else
            sprite.isForbad = YES;
    }
    NSLog(@"connect inner change player to %d", _currentPlayer);
}

- (void)drawCDRect {
    for(PropSprite *sprite in _props) {
        if(sprite.type == GROUP1)
            [sprite drawCDRect:_Player1Score];
        else
            [sprite drawCDRect:_Player2Score];
    }
}

- (void)repositionAnimation {
    for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
        if(sprite.position.x != sprite.initPos.x || sprite.position.y != sprite.initPos.y) {
            [sprite runAction:[CCMoveTo actionWithDuration:0.7 position:sprite.initPos]];
        }
        if([sprite getOpacity] == 0) {
            [sprite.Image runAction:[CCFadeIn actionWithDuration:0.4]];
            [sprite runAction:[CCFadeIn actionWithDuration:0.4]];
        }
    }
}

- (void)repositionStandardPorcedure {
    [self removeEmitter];
    for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
        // 叛逃棋子
        if( sprite.isBetray) {
            sprite.isBetray = NO;
            sprite.opacity = 255;
            if(sprite.NewBackColor != nil) {
                [sprite removeChild:sprite.NewBackColor cleanup:YES];
                sprite.NewBackColor = nil;
            }
            if(sprite.type == GROUP1)
                sprite.type = GROUP2;
            else
                sprite.type = GROUP1;
        }
        // 修正角度
        if( sprite.type == GROUP2 ) {
            sprite.rotation = 180;
        }
        else {
            sprite.rotation = 0;
        }
        // 重设线速度和角速度
        if( sprite.body != nil ) {
            (sprite.body)->SetLinearVelocity(b2Vec2(0, 0));
            (sprite.body)->SetAngularVelocity(0);
        }
        //sprite.isMoving = NO;
        // Clean up
        [self destroyChessmanBody];
        // Enlarged chessman
        if(sprite.initScale != sprite.scale) {
            [_hostLayer spriteDiminish:sprite];
        }
        if([sprite getOpacity] == 0) {
            // add body for dead chessman
            if( sprite.body != nil ) {
                [_hostLayer destroyBody:sprite.body];
                sprite.body = nil;
            }
            b2Body *body = [_hostLayer addBoxBodyForChessman:sprite withRadius:26.0f];
            b2MassData massData;
            body->GetMassData( &massData );
            massData.mass = 3.0f;
            body->SetMassData( &massData);
            if( sprite.scale == LARGE_SIZE ) {
                body->SetLinearDamping( 4.0f );
                sprite.value = 8;
            }
            else if( sprite.scale == MEDIUM_SIZE ) {
                body->SetLinearDamping( 2.5f );
                sprite.value = 4;
            }
            else if( sprite.scale == SMALL_SIZE ) {
                body->SetLinearDamping( 1.0f );
                sprite.value = 2;
            }
            sprite.isDead = NO;
            sprite.body = body;
        }
    }
}

- (void)repositionExtraProcedure {
    _currentPlayer = PLAYER1;
    NSLog(@"attention please ! change player to init 0");
    for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
        sprite.isSelected = NO;
        //sprite.isMoving = NO;
        sprite.Image.opacity = 255;
        sprite.opacity = 255;
        sprite.position = sprite.initPos;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            (sprite.body)->SetTransform(b2Vec2([GameLayer PadCoorx2Phone:sprite.position.x] / PTM_RATIO, 
                                               [GameLayer PadCoory2Phone:sprite.position.y] / PTM_RATIO ),
                                        (-1) * CC_DEGREES_TO_RADIANS(sprite.rotation));
        }
        else {
            (sprite.body)->SetTransform(b2Vec2(sprite.position.x / PTM_RATIO, 
                                               sprite.position.y / PTM_RATIO ),
                                        (-1) * CC_DEGREES_TO_RADIANS(sprite.rotation));
        }
        if(sprite.type == GROUP1)
            sprite.isForbad = NO;
        else
            sprite.isForbad = YES;
        
        
    }
    for(PropSprite *sprite in _props) {
        [sprite propInit];
    }
    [self setPropFading];
    _Player1Lives = 16;
    _Player2Lives = 16;
    _Player1Score = 0;
    _Player2Score = 0;
    //_movingChessmanCount = 0;
}

- (void)dealloc {
    [super dealloc];
    [_chessmans release];
    [_props release];
    [_toDestroy release];
}

- (bool)checkValid {
    b2Vec2 linear_speed_vec;
	float linear_speed;
	for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
		if( sprite.body == nil )
		{
			continue;
		}
		//不可以同时选中两个棋子
		if( sprite.isSelected )
		{
			return NO;
		}
        linear_speed_vec = sprite.body->GetLinearVelocity();
		linear_speed = linear_speed_vec.x * linear_speed_vec.x + linear_speed_vec.y * linear_speed_vec.y;
		if( linear_speed != 0 )
		{
			return NO;
		}
		int opacity = [sprite getOpacity];
		if( opacity != 255 && opacity != 0 )
		{
			return NO;
		}
	}
	
	for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
		if( sprite.body != nil ){
            sprite.body->SetAngularVelocity(0);
		}
	}
	return YES;
}

- (void)turnOnPowerUp
{
	
    for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
        if(_currentPlayer == PLAYER2) {
            if(sprite.type == GROUP2)
                sprite.isPowerUp = YES;
        }
        else {
            if(sprite.type == GROUP1)
                sprite.isPowerUp = YES;
        }
    }
}


- (void)shutDownPowerUp
{
	for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
            sprite.isPowerUp = NO;
    }
}

- (void)shutDownForbid
{
	for(PropSprite *sprite in _props) {
        if( _currentPlayer == PLAYER2 )
        {
            if(sprite.type == GROUP2)
            {
                sprite.isForbad = NO;
            }
        }
        else
        {
            if(sprite.type == GROUP1)
            {
                sprite.isForbad = NO;
            }
        }
    }
}

- (void)turnOnEnlarge {
    for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
        if(_currentPlayer == PLAYER2) {
            if(sprite.type == GROUP2)
                sprite.isEnlarge = YES;
        }
        else {
            if(sprite.type == GROUP1)
                sprite.isEnlarge = YES;
        }
    }
}

- (void)shutDownEnlarge
{
	for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
        sprite.isEnlarge = NO;
    }
}

- (bool)testEnlargePropValid {
    bool result = YES;
    for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
        if(_currentPlayer == PLAYER1) {
            if(_Player1Lives == 1)
                if(sprite.type == GROUP1 && sprite.isDead == NO)
                    if(sprite.scale == LARGE_SIZE)
                        result = NO;
        }
        else {
            if(_Player2Lives == 1)
                if(sprite.type == GROUP2 && sprite.isDead == NO)
                    if(sprite.scale == LARGE_SIZE)
                        result = NO;

        }
    }
    return result;
}

- (void)turnOnChange {	
	for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
        sprite.isChange = YES;
    }
}

- (void)shutDownChange {	
	for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
        sprite.isChange = NO;
    }
}

- (void)clearScore:(int)score {
    //清除分数
	if( _currentPlayer == PLAYER1 )
	{
		_Player1Score -= score;
	}
	else
	{
		_Player2Score -= score;
	}
	[self checkPropValid];
}

- (bool)player1Win {
    return _Player1Lives > _Player2Lives;
}

- (bool)player2Win {
    return _Player2Lives > _Player1Lives;
}

- (void)setPropFading {
    for(PropSprite *sprite in _props) {
        sprite.isFading = YES;
   }
}

- (void)sendCollisionDataViaOpenFeint {
    unsigned int length = sizeof(CGPoint);
    unsigned int full_length = 32 * length;
    static unsigned char dataPacket[512];
    const unsigned int packetHeaderSize = sizeof(stPacketHeader);
    stPacketHeader* pPacketHeader = (stPacketHeader *)dataPacket;
    pPacketHeader->packetID = CHESSMAN_COLLISION_EVENT;
	
	if(length <= 512) {
        CGPoint position;
        for(int i = 0; i < 32; i++) {
            ChessmanSprite *sprite = [_chessmans objectForKey:[NSNumber numberWithInt:i]];
            position = sprite.position;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad 
                && [OpenFeintGameScene gameLayer].rivalDeviceType == UIUserInterfaceIdiomPhone){
                position.x = [ConnectedGameLayer PadCoorx2Phone:position.x];
                position.y = [ConnectedGameLayer PadCoory2Phone:position.y];
                
            }
            else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone 
                     && [OpenFeintGameScene gameLayer].rivalDeviceType == UIUserInterfaceIdiomPad){
                position.x = [ConnectedGameLayer PhoneCoorx2Pad:position.x];
                position.y = [ConnectedGameLayer PhoneCoory2Pad:position.y];
            }
            memcpy(&dataPacket[packetHeaderSize + i * length], &position, length);
        }
        NSData *collisionData = [NSData dataWithBytes:dataPacket length:packetHeaderSize + full_length];
        [[OpenFeintGameScene gameLayer] dispatchData:collisionData withType:CHESSMAN_COLLISION_EVENT withIdentifier:0];
        NSLog(@"send data by openfeint");
	}
}

- (void)sendCollisionDataViaBluetooth {
    unsigned int length = sizeof(CGPoint);
    unsigned int full_length = 32 * length;
    static unsigned char dataPacket[512];
    const unsigned int packetHeaderSize = sizeof(stPacketHeader);
    stPacketHeader* pPacketHeader = (stPacketHeader *)dataPacket;
    pPacketHeader->packetID = CHESSMAN_COLLISION_EVENT;
	
	if(length <= 512) {
        CGPoint position;
        for(int i = 0; i < 32; i++) {
            ChessmanSprite *sprite = [_chessmans objectForKey:[NSNumber numberWithInt:i]];
            position = sprite.position;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad 
                && [ConnectedGameScene bluetoothConnectLayer].rivalDeviceType == UIUserInterfaceIdiomPhone){
                position.x = [ConnectedGameLayer PadCoorx2Phone:position.x];
                position.y = [ConnectedGameLayer PadCoory2Phone:position.y];
                
            }
            else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone 
                     && [ConnectedGameScene bluetoothConnectLayer].rivalDeviceType == UIUserInterfaceIdiomPad){
                position.x = [ConnectedGameLayer PhoneCoorx2Pad:position.x];
                position.y = [ConnectedGameLayer PhoneCoory2Pad:position.y];
            }
            memcpy(&dataPacket[packetHeaderSize + i * length], &position, length);
        }
        NSData *collisionData = [NSData dataWithBytes:dataPacket length:packetHeaderSize + full_length];
        
        [[ConnectedGameScene bluetoothConnectLayer] dispatchData:collisionData withType:CHESSMAN_COLLISION_EVENT withIdentifier:0];
        NSLog(@"send data by bluetooth");
	}
}

- (bool)setCollisionPosition:(CGPoint)point withID:(int)ID {
    ChessmanSprite *sprite = [_chessmans objectForKey:[NSNumber numberWithInt:ID]];
    if( point.x != sprite.position.x || point.y != sprite.position.y ) {
        // 检测是否复活了死亡的棋子
        if( ![sprite checkAlive] && [sprite checkAlive:point] ) {
            NSLog(@"fu huo le");
            sprite.isDead = NO;
            if(sprite.body != nil) {
                [_toDestroy removeObject:sprite];
            }
            if( sprite.isBetray ) {
                [sprite.NewBackColor runAction:[CCFadeIn actionWithDuration:0.3]];
            }
            else {
                [sprite runAction:[CCFadeIn actionWithDuration:0.3]];
            }
            [sprite.Image runAction:[CCFadeIn actionWithDuration:0.3]];
            if( sprite.type == GROUP1) { 
                _Player1Score -= sprite.value;
                _Player1Lives ++;

                if(_currentPlayer == PLAYER2)
                {
                    _Player2Score -= sprite.value / 2;
                }
            }
            else {
                _Player2Score -= sprite.value;
                _Player2Lives ++;
                if(_currentPlayer == PLAYER1 )
                {
                    _Player1Score -= sprite.value / 2;
                }
            }
            [self checkPropValid];
        }
        // 如果棋子已经死掉，continue
        else if(![sprite checkAlive]) {
            return NO;
        }
        // 检查是否杀死了棋子
        else if( ![sprite checkAlive:point] ) {
            NSLog(@"sha si le");
            if( sprite.isBetray ) {
                [sprite.NewBackColor runAction:[CCFadeOut actionWithDuration:0.3]];
            }
            else {
                [sprite runAction:[CCFadeOut actionWithDuration:0.3]];
            }
            [sprite.Image runAction:[CCFadeOut actionWithDuration:0.3]];
            sprite.isDead = YES;
            if( (sprite.type == GROUP1 && sprite.isBetray == NO) || (sprite.type == GROUP2 && sprite.isBetray == YES) ) { 
                _Player1Score += sprite.value;
                _Player1Lives --;

                if(_currentPlayer == PLAYER2)
                {
                    _Player2Score += sprite.value / 2;
                }
            }
            else {
                _Player2Score += sprite.value;
                _Player2Lives --;
                if(_currentPlayer == PLAYER1)
                {
                    _Player1Score += sprite.value / 2;
                }
            }
            [self checkPropValid];
            [_toDestroy addObject:sprite];
        }
        NSLog(@"really different");
        NSLog(@"point.x :%f, point.y %f",point.x, point.y);
        NSLog(@"self.x :%f, self.y %f",sprite.position.x, sprite.position.y);
        [sprite runAction:[CCMoveTo actionWithDuration:1.0f position:point]];
        float angle = sprite.rotation;
        if( sprite.body != nil ) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
                sprite.body->SetTransform( b2Vec2([GameLayer PadCoorx2Phone:point.x] / PTM_RATIO,
                                                   [GameLayer PadCoory2Phone:point.y] / PTM_RATIO),
                                           -1 * CC_DEGREES_TO_RADIANS(angle));
            }
            else {
                sprite.body->SetTransform( b2Vec2(point.x / PTM_RATIO,
                                                   point.y / PTM_RATIO),
                                           -1 * CC_DEGREES_TO_RADIANS(angle));
            }
            sprite.body->SetLinearVelocity(b2Vec2(0, 0));
            sprite.body->SetAngularVelocity(0);
        }
        return YES;
    }
    else
        return NO;
}

- (void)setConnectedChessmanImpulse:(b2Vec2)impulse withID:(int)ID
{
	ConnectedChessmanSprite *sprite = [_chessmans objectForKey:[NSNumber numberWithInt:ID]];
	[sprite setImpulse:impulse];
}

- (void)setOpenFeintChessmanImpulse:(b2Vec2)impulse withID:(int)ID
{
	OpenFeintChessmanSprite *sprite = [_chessmans objectForKey:[NSNumber numberWithInt:ID]];
	[sprite setImpulse:impulse];
}

- (void)setPlayer1Forbad {
    for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
        sprite.isForbad = YES;
    }
}

- (void)setConnectedChessmanSelected:(int)ID
{
	ConnectedChessmanSprite *sprite = [_chessmans objectForKey:[NSNumber numberWithInt:ID]];
	[sprite setSelected];
}

- (void)setConnectedChessmanEnlarged:(int)ID {
	ConnectedChessmanSprite *sprite = [_chessmans objectForKey:[NSNumber numberWithInt:ID]];
	[sprite setEnlarged];
}

- (void)setConnectedChessmanChanged:(int)ID
{
	ConnectedChessmanSprite *sprite = [_chessmans objectForKey:[NSNumber numberWithInt:ID]];
	[sprite setChanged];
}

- (void)setOpenFeintChessmanSelected:(int)ID
{
	OpenFeintChessmanSprite *sprite = [_chessmans objectForKey:[NSNumber numberWithInt:ID]];
	[sprite setSelected];
}

- (void)setOpenFeintChessmanEnlarged:(int)ID {
	OpenFeintChessmanSprite *sprite = [_chessmans objectForKey:[NSNumber numberWithInt:ID]];
	[sprite setEnlarged];
}

- (void)setOpenFeintChessmanChanged:(int)ID
{
	OpenFeintChessmanSprite *sprite = [_chessmans objectForKey:[NSNumber numberWithInt:ID]];
	[sprite setChanged];
}

- (void)checkChessmanSelected {
    for(id key in _chessmans) {
        ChessmanSprite *sprite = [_chessmans objectForKey:key];
        if(sprite.isSelected == YES)
            [sprite cancelSelect];
    }
}

@end
