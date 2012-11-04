//
//  OpenFeintGameLayer.m
//  Tan Chess HD
//
//  Created by Bluebitch on 11-5-22.
//  Copyright 2011年 TJU. All rights reserved.
//

#import "OpenFeintGameScene.h"
#import "gameLayer.h"
#import "OFMultiplayerService.h"
#import "OFMultiplayerService+Advanced.h"
#import "OpenFeintGameScene.h"
#import "OpenFeintContactListener.h"
#import "OpenFeintPropSprite.h"
#import "PauseButton.h"
#import "BluetoothConnectLayer.h"
#import "OFNotificationData.h"
#import "OFNotification.h"
#import "OpenFeint+UserOptions.h"

typedef enum {
	I_WIN,
    YOU_WIN,
    EVEN
} gameResult;

@interface OpenFeintGameLayer(Private) 
- (void)recvMsg:(int)packetID data:(char*)data length:(int)full_length;
- (void)sendNetworkPacketWithPacketID:(int)packetID withData:(void *)data ofLength:(int)length;
- (void)replayAlert;
- (void)adjustRotation;
@end

@implementation OpenFeintGameLayer

@synthesize isHost = _isHost;
@synthesize isLogin = _isLogin;
@synthesize connectionAlert, restartRequestAlert, replayRequestAlert, restartRequestRejectAlert;
@synthesize rivalDeviceType = _rivalDeviceType;

- (void)replayAlert {
    if(self.connectionAlert.visible) {
		[self.connectionAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}
    if(self.restartRequestAlert.visible) {
		[self.restartRequestAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}
    if(self.restartRequestRejectAlert.visible) {
		[self.restartRequestRejectAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}
    NSString *message = @"Wanna try again?";
    if(self.replayRequestAlert && self.replayRequestAlert.visible) {
        self.replayRequestAlert.message = message;
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Game Over" message:message delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:@"No", nil];
        self.replayRequestAlert = alert;
        [self adjustRotation];
        [alert show];
        [alert release];
    }
}

- (void)checkTurnTick:(ccTime)dt {
    if([self isInCharge] && ![OFMultiplayerService isItMyTurn]) {
        NSLog(@"not my turn yet");
        return;
    }
    if(!_receivedRivalDeviceType) {
        NSLog(@"has not receive rival device type");
        return;
    }
    [super checkTurnTick:dt];
}

- (void)showNotification:(NSString *)string {
    OFNotificationData *notification = [OFNotificationData dataWithText:string andCategory:kNotificationCategoryMultiplayer];
    [[OFNotification sharedInstance] showBackgroundNotice:notification andStatus:nil];
}

- (void)endTurn {
    [[OFMultiplayerService getGame] sendEndTurn];
}

- (void)didChangeTurn {
    if([self isInCharge])
        [self endTurn];
}

- (void)fadeInStandardProcedure {
    if(!_isHost) {
        [[CCDirector sharedDirector] setDeviceOrientation:CCDeviceOrientationPortraitUpsideDown];
        [self resetPauseButtonPos];
    }
    [super fadeInStandardProcedure];
}

- (void)fadeInTick:(ccTime)dt {
    [self unschedule:_cmd];
    [self restartWithMusic:YES];
}

- (void)sendCollisionChessman {
    [_brain sendCollisionDataViaOpenFeint];  
}


- (void)createPropwithFilename:(NSString*)filename withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type withScore:(int)score withCategory:(int)cat
{
	OpenFeintPropSprite *Prop = [OpenFeintPropSprite propWithImageFile:filename withPosition:position withScale:scale withType:type withScore:score withCategory:cat];
	[self createPropStandardProcedure:Prop];
}

- (void)createChessmanwithFilename:(NSString*)filename withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type
{
	OpenFeintChessmanSprite *Chessman;
	if( type == 1 )
	{
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			Chessman = [OpenFeintChessmanSprite chessmanWithImageFile:@"Green-ipad.png" withFilename:filename withPosition:position withScale:scale withType:type];
		}
		else {
			Chessman = [OpenFeintChessmanSprite chessmanWithImageFile:@"Green.png" withFilename:filename withPosition:position withScale:scale withType:type];
		}
	}
	else
	{
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			Chessman = [OpenFeintChessmanSprite chessmanWithImageFile:@"Red-ipad.png" withFilename:filename withPosition:position withScale:scale withType:type];
		}
		else {
			Chessman = [OpenFeintChessmanSprite chessmanWithImageFile:@"Red.png" withFilename:filename withPosition:position withScale:scale withType:type];
		}
	}
    [self createChessmanStandardProcedure:Chessman withScale:scale];
}

- (bool)changePlayer
{
    if([self isInCharge] || self.isForbidPropOn) 
        [self dispatchData:nil withType:CHANGE_TURN_EVENT withIdentifier:0];
    bool result = [self changePlayerStandardProcedure];
    if(result) {
        if([self isInCharge])
            [_brain changePlayerWhenConnecting];
        else
            [_brain changePlayer];
    }
    return result;
}

- (void)setPauseButtonType:(PauseButton *)button {
    [button set_type:2];
}

- (void)setPicNum:(int *)mainPicNum withStar:(int *)starPicNum {
    if( _isHost ) {
        if ([_brain player1Win]) {
            *mainPicNum = 0;
            *starPicNum = 0;
        }
        else if([_brain player2Win]){
            *mainPicNum = 2;
        }
        else{
            *mainPicNum = 4;
        }
    }
    else {
        if ([_brain player1Win]) {
            *mainPicNum = 3;
        }
        else if([_brain player2Win]){
            *mainPicNum = 1;
            *starPicNum = 1;
        }
        else{
            *mainPicNum = 4;
            _GameOverShow[*mainPicNum].rotation = 180;
        }
    }
}

- (id)init
{
	self = [super init];
	if (self)
	{
        if( _contactListener != nil ) {
            delete _contactListener;
            _contactListener = nil;
        }
        _contactListener = (MyContactListener *)(new OpenFeintContactListener());
		_world->SetContactListener(_contactListener);
        _contactListener->SetHingeFixture(FixtureA, FixtureB);
	}
	return self;
}

- (void)turnOnPowerUp
{
    [self dispatchData:nil withType:PROP_SHOW_EVENT withIdentifier:0];
	[self turnOnPowerUpStandardProcedure];
}

- (void)turnOnForbid
{
    [self dispatchData:nil withType:PROP_SHOW_EVENT withIdentifier:1];
	[self turnOnForbidStandardProcedure];
}

- (void)turnOnEnlarge
{
    [self dispatchData:nil withType:PROP_SHOW_EVENT withIdentifier:2];
	[self turnOnEnlargeStandardProcedure];
}

- (void)turnOnChange
{
	[self dispatchData:nil withType:PROP_SHOW_EVENT withIdentifier:3];
	[self turnOnChangeStandardProcedure];
}

- (void)dealloc
{
    if(self.connectionAlert.visible) {
		[self.connectionAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}
    if(self.restartRequestAlert.visible) {
		[self.restartRequestAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}
    if(self.replayRequestAlert.visible) {
		[self.replayRequestAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}
    if(self.restartRequestRejectAlert.visible) {
		[self.restartRequestRejectAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}
	self.connectionAlert = nil;
    self.restartRequestAlert = nil;
    self.replayRequestAlert = nil;
    self.restartRequestRejectAlert = nil;
    [super dealloc];
}

- (void)setChessmanImpulse:(b2Vec2)impulse withID:(int)ID
{
	[_brain setOpenFeintChessmanImpulse:impulse withID:ID];
}

- (void)reposition {
    [self repositionOriginProcedure];
    _vWaitingUpdateData.clear();
	if(!_isHost) {
        NSLog(@"set player 1 forbad");
        [_brain setPlayer1Forbad];
    }
}

- (void)sendDeviceTypeTick:(ccTime)dt {
    if([OFMultiplayerService isItMyTurn]) {
        UIUserInterfaceIdiom deviceType = UI_USER_INTERFACE_IDIOM();
        [self sendNetworkPacketWithPacketID:RIVAL_DEVICE_TYPE
                                   withData:&deviceType
                                   ofLength:sizeof(UIUserInterfaceIdiom)];
        [self endTurn];
        [self unschedule:_cmd];
    }
}

- (void)sendDeviceType {
    [self schedule:@selector(sendDeviceTypeTick:)];
}

- (void)setHost:(BOOL)isHost {
    _receivedRivalDeviceType = NO;
	if(!isHost) {
        NSLog(@"not host");
		[_brain setPlayer1Forbad];
	}
    else {
        [self sendDeviceType];
    }
    _isHost = isHost;
}

- (void)setChessmanSelected:(int)ID {
	[_brain setOpenFeintChessmanSelected:ID];
}

- (void)setChessmanEnlarged:(int)ID {
	[_brain setOpenFeintChessmanEnlarged:ID];
}


- (void)setChessmanChanged:(int)ID {
	[_brain setOpenFeintChessmanChanged:ID];
}

- (void)propShowWithNum:(int)num {
	_nProp = num;
	[self schedule:@selector(Proptick:)];
}

- (bool)isInCharge {
    bool result = NO;
    if( _brain.currentPlayer == PLAYER1 && _isHost ) {
        result = YES;
    }
    else if( _brain.currentPlayer == PLAYER2 && !_isHost ) {
        result = YES;
    }
    return result;
}

- (void)UpdateDataStandardProcedure {
    std::vector<CGPoint>::iterator it = _vWaitingUpdateData.begin();
    NSLog(@"OpenFeint _vWaitingUpdateData size %lu", _vWaitingUpdateData.size());
    bool isDifferent = NO;
    for( int i = 0; it != _vWaitingUpdateData.end(); it++, i++) {
        if([self setCollisionPosition:(*it) withID:i])
            isDifferent = YES;
    }
    if(isDifferent) {
        NSLog(@"different");
        [self setUpdateTimer];
    }
    else {
        NSLog(@"not different");
        [self setNoDifferentCollision];
    }
    _vWaitingUpdateData.clear();
}

- (void)WaitForDelayedDataTick:(ccTime)dt {
    static ccTime time = 0.0f;
    time += dt;
    if( time >= 3.0f || _vWaitingUpdateData.size() > 0 ) {
        // 超时或更新完毕
        [self unschedule:_cmd];
        if( time < 3.0f ) {
            NSLog(@"Now Good");
            [self UpdateDataStandardProcedure];
        }
        else {
            [self setNoDifferentCollision];
        }
        time = 0;
    }
}

- (void)UpdateData {
    _isUpdating = YES;
    [self schedule:@selector(WaitForDelayedDataTick:) interval:0.1];
}

- (void)updateCollisionChessmanData{
    if( [self isInCharge] ) {
        NSLog(@"in charge: send data");
        [self sendCollisionChessman];
        [self setNoDifferentCollision];
        if(self.isForbidPropOn) {
            [self dispatchData:nil withType:CHANGE_TURN_EVENT withIdentifier:0];
            [self endTurn];
        }
        else
            _rivalHasChangeTurn = YES;
    }
    else {
        NSLog(@"not in charge: update data");
        [self UpdateData];
    }
} 

- (void)commitGameResult:(int)iWin { 
    if(iWin == EVEN) {
        [OFMultiplayerService finishGameWithPlayerRanks:[NSArray arrayWithObjects:nil]];
        return;
    }
    OFMultiplayerGame *game = [OFMultiplayerService getGame];
    NSMutableArray *players = game.playerOFUserIds;
    BOOL firstIsMe = [[players objectAtIndex:0] 
                      isEqualToString:[OpenFeint lastLoggedInUserId]];
    NSNumber * me = iWin == I_WIN ? [NSNumber numberWithUnsignedInt:1] : [NSNumber 
                                                                 numberWithUnsignedInt:0];
    
    NSNumber * you = iWin == I_WIN ? [NSNumber numberWithUnsignedInt:0] : [NSNumber 
                                                                  numberWithUnsignedInt:1];
    
    if(firstIsMe) [OFMultiplayerService finishGameWithPlayerRanks:[NSArray 
                                                                        arrayWithObjects:me, you, nil]];
    else [OFMultiplayerService finishGameWithPlayerRanks:[NSArray 
                                                          arrayWithObjects:you, me, nil]];
}

- (void)playGameOverMusic {
    // Test if the current player is the winner
    int iWin = YOU_WIN;
    if( _isHost && [_brain player2Win] ) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"lose.wav"];
        
    }
    else if( !_isHost && [_brain player1Win] ) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"lose.wav"];
    }
    else {
        [[SimpleAudioEngine sharedEngine] playEffect:@"win.wav"];
        iWin = I_WIN;
    }
    if(![_brain player1Win] && ![_brain player2Win])
        iWin = EVEN;
    [self commitGameResult:iWin];
}

- (void)leaveGame {
    [self commitGameResult:YOU_WIN];
    [[OFMultiplayerService getGame] closeGame];
}

- (void)gotoSysMenu {
    // 询问玩家是否要再来一盘 如不需要才返回系统菜单
    [self replayAlert];
}

- (void)gotoSysMenuConfirmed {
    [self leaveGame];
    [self fadeOut];
}

// send message
- (void)sendNetworkPacketWithPacketID:(int)packetID withData:(void *)data ofLength:(int)length {
	// the packet we'll send is resued
	static unsigned char networkPacket[1024];
	const unsigned int packetHeaderSize = sizeof(stPacketHeader);
	
	if(length <= (int)(1024 - packetHeaderSize)) { // our networkPacket buffer size minus the size of the header info
		stPacketHeader* pPacketHeader = (stPacketHeader*)networkPacket;
		// header info
		pPacketHeader->packetID = packetID;
		// copy data in after the header
		memcpy(&networkPacket[packetHeaderSize], data, length); 
		
		NSData *packet = [NSData dataWithBytes: networkPacket length: (length+packetHeaderSize)];
        NSLog(@"send packet");
		[[OFMultiplayerService getGame] sendMove:packet];
	}
}

- (void)adjustRotation {
    if( !_isHost ) {
        [[CCDirector sharedDirector] setDeviceOrientation:CCDeviceOrientationPortrait];
        [[OpenFeintGameScene sharedScene] setRotation:180.0f];
    }
}

- (void)resetRotation {
    if( !_isHost ) {
        [[CCDirector sharedDirector] setDeviceOrientation:CCDeviceOrientationPortraitUpsideDown];
        [[OpenFeintGameScene sharedScene] setRotation:0.0f];
    }
}

- (void)gameLayerReposition {
    if(self.isHost)
        NSLog(@"host turn:%d",[OFMultiplayerService isItMyTurn]);
    else
        NSLog(@"guest turn:%d",[OFMultiplayerService isItMyTurn]);
    
    if(!self.isHost && [OFMultiplayerService isItMyTurn]) {
        [[OFMultiplayerService getGame] sendEndTurn];
        NSLog(@"guest end turn when reposition");
    }
    [self reposition];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self resetRotation];
    if( alertView == connectionAlert ) {
        if(buttonIndex == 0) {
            [self gotoSysMenuConfirmed];
        }
    }
    else if( alertView == restartRequestAlert ) {
        if(buttonIndex == 0) {
            [self gameLayerReposition];
        }
        [self dispatchData:nil withType:RESTART_RESPOND withIdentifier:buttonIndex];
    }
    else if( alertView == replayRequestAlert ) {
        if(buttonIndex == 0) {
            [[OFMultiplayerService getGame] requestRematch];
            [self showNotification:@"Waiting for rematch"];
        }
        else if( buttonIndex == 1 ){
            [self gotoSysMenuConfirmed];
        }
    }
    else if( alertView == restartRequestRejectAlert ) {
        if(buttonIndex == 0) {
            //Do nothing
        }
    }
}

- (void)restartRequest {
    NSLog(@"RESTART_REQUEST");
    if(self.connectionAlert.visible) {
        [self.connectionAlert dismissWithClickedButtonIndex:-1 animated:NO];
    }
    if(self.replayRequestAlert.visible) {
        [self.replayRequestAlert dismissWithClickedButtonIndex:-1 animated:NO];
    }
    if(self.restartRequestRejectAlert.visible) {
        [self.restartRequestRejectAlert dismissWithClickedButtonIndex:-1 animated:NO];
    }
    NSString *message = @"Your rival want to restart this game, and ask for your approval.";
    if(self.restartRequestAlert && self.restartRequestAlert.visible) {
        self.restartRequestAlert.message = message;
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restart Request" message:message delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:@"No", nil];
        self.restartRequestAlert = alert;
        [self adjustRotation];
        [alert show];
        [alert release];
    }
}

- (void)restartRequestTick:(ccTime)dt {
    if([[OFMultiplayerService getGame] isItMyTurn]) {
        [self unschedule:_cmd];
        [self restartRequest];
    }
}

///////////////////////////////////////////////////////////////////////////

- (void)recvMsg:(int)packetID data:(char*)data length:(int)full_length
{
	switch( packetID ) {
        case CHESSMAN_SELECT_EVENT:
		{
            //NSLog(@"Chessman select!!!!!");
			[self setChessmanSelected:*(int *)data];
			break;
		}
        case RIVAL_DEVICE_TYPE:
		{
            _rivalDeviceType = *((UIUserInterfaceIdiom*)data);
            _receivedRivalDeviceType = YES;
            if(_rivalDeviceType == UIUserInterfaceIdiomPhone)
                [self showNotification:@"Received Opponent Device Type: iPhone"];
            else 
                [self showNotification:@"Received Opponent Device Type: iPad"];
            if(!_isHost)
                [self sendDeviceType];
            break;
		}
		case CHESSMAN_MOVE_EVENT:
		{
			ChessmanMoveStruct cmStruct = *(ChessmanMoveStruct *)data;
			[self setChessmanImpulse:cmStruct.ChessmanImpluse withID:cmStruct.ChessmanID];
			break;
		}
		case CHESSMAN_COLLISION_EVENT:
		{ 
            int length = sizeof(CGPoint);
            int num = full_length / length;
            //NSLog(@"num %d",num);
            _vWaitingUpdateData.clear();
            for(int i = 0; i < num; i++) {
                CGPoint position;
                memcpy(&position, &data[i * length], length);
                _vWaitingUpdateData.push_back(position);
            }
			break;
		}
		case PLAY_SOUND_EVENT:
		{ 
			int NUM = *(int *)data;
			if(  NUM == 0 )
			{
				[[SimpleAudioEngine sharedEngine] playEffect:@"powerup.wav"];
			}
			else if( NUM == 1 )
			{
				[[SimpleAudioEngine sharedEngine] playEffect:@"change.wav"];
			}
			else if( NUM == 2 )
			{
				[[SimpleAudioEngine sharedEngine] playEffect:@"teleport.wav"];
			}
			else if( NUM == 3 )
			{
				[[SimpleAudioEngine sharedEngine] playEffect:@"teleport_ef.wav"];
				[self setIsForbidPropOn:YES];
			}
			else if( NUM == 4 )
			{
				[[SimpleAudioEngine sharedEngine] playEffect:@"hitstone.wav"];
			}
			else if( NUM == 5 )
			{
				[[SimpleAudioEngine sharedEngine] playEffect:@"hithinge.wav"];
			}
			break;
		}
		case CHESSMAN_ENLARGE_EVENT:
		{			
			[self setChessmanEnlarged:*(int *)data];
			break;
		}
		case CHESSMAN_CHANGE_EVENT:
		{
			[self setChessmanChanged:*(int *)data];
			break;
		}
		case PROP_SHOW_EVENT:
		{
			int num = *((int*)data);
			[self propShowWithNum:num];
            switch (num) {
                case 0:
                    [self clearScore:POWERUP_NEED_SCORE];
                    break;
                case 1:
                    [self clearScore:FORBID_NEED_SCORE];
                    break;
                case 2:
                    [self clearScore:ENLARGE_NEED_SCORE];
                    break;
                case 3:
                    [self clearScore:CHANGE_NEED_SCORE];
                    break;
                default:
                    break;
            }
            break;
		}
        case RESTART_REQUEST:
        {
            [self schedule:@selector(restartRequestTick:) interval:1.0f];
            break;
        }
        case RESTART_RESPOND:
        {
            NSLog(@"RESTART_RESPOND");
            int buttonIndex = *((int*)data);
            if( buttonIndex == 1 ) {
                if(self.connectionAlert.visible) {
                    [self.connectionAlert dismissWithClickedButtonIndex:-1 animated:NO];
                }
                if(self.restartRequestAlert.visible) {
                    [self.restartRequestAlert dismissWithClickedButtonIndex:-1 animated:NO];
                }
                if(self.replayRequestAlert.visible) {
                    [self.replayRequestAlert dismissWithClickedButtonIndex:-1 animated:NO];
                }
                NSString *message = @"Your rival do not want to restart this game.";
                if(self.restartRequestRejectAlert && self.restartRequestRejectAlert.visible) {
                    self.restartRequestRejectAlert.message = message;
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Rejected" message:message delegate:self cancelButtonTitle:@"Fine" otherButtonTitles:nil];
                    self.restartRequestRejectAlert = alert;
                    [self adjustRotation];
                    [alert show];
                    [alert release];
                }
            }
            else {
                [self gameLayerReposition];
            }
            break;
        }
        case TOUCH_CANCEL_EVENT: {
            [self checkChessmanSelectedWhenAppEnterBackground];
            break;
        }
        case CHANGE_TURN_EVENT: {
            [self setRivalHasChangeTurn:YES];
            break;
        }
		default:
			// error
			break;
    }
}

- (void)dispatchData:(void *)data withType:(int)Type withIdentifier:(int)ID
{
	if( Type == CHESSMAN_MOVE_EVENT )
	{
		ChessmanMoveStruct cmStruct;
		cmStruct.ChessmanID = ID;
		cmStruct.ChessmanImpluse = *(b2Vec2 *)data;
		[self sendNetworkPacketWithPacketID:Type
					   withData:&cmStruct
					   ofLength:sizeof(cmStruct)];
	}
	else if( Type == CHESSMAN_SELECT_EVENT )
	{
		[self sendNetworkPacketWithPacketID:Type
					   withData:&ID
					   ofLength:sizeof(ID)];
        //NSLog(@"select chessman");
	}
	else if( Type == CHESSMAN_COLLISION_EVENT )
	{   
        NSData *collisionData = (NSData *)data;
        [[OFMultiplayerService getGame] sendMove:collisionData];
	}
	else if( Type == PLAY_SOUND_EVENT )
	{
		int NUM = *(int *)data;
		[self sendNetworkPacketWithPacketID:Type
					   withData:&NUM
					   ofLength:sizeof(NUM)];		
	}
	else if( Type == CHESSMAN_CHANGE_EVENT )
	{
		[self sendNetworkPacketWithPacketID:Type
					   withData:&ID
					   ofLength:sizeof(ID)];
	}
	else if( Type == CHESSMAN_ENLARGE_EVENT )
	{
		[self sendNetworkPacketWithPacketID:Type
					   withData:&ID
					   ofLength:sizeof(ID)];
	}
	else if( Type == PROP_SHOW_EVENT )
	{
		[self sendNetworkPacketWithPacketID:Type
					   withData:&ID
					   ofLength:sizeof(ID)];
	}
    else if( Type == RESTART_REQUEST ) {
        if(![[OFMultiplayerService getGame] isItMyTurn])
            [self showNotification:@"Please send restart request in your turn"];
        else
            [self sendNetworkPacketWithPacketID:Type
                                       withData:nil
                                       ofLength:0];
    }
    else if( Type == RESTART_RESPOND )
    {
        [self sendNetworkPacketWithPacketID:Type
					   withData:&ID
					   ofLength:sizeof(ID)];
    }
    else if( Type == TOUCH_CANCEL_EVENT )
    {
        [self sendNetworkPacketWithPacketID:Type
					   withData:nil
					   ofLength:0];
    }
    else if( Type == CHANGE_TURN_EVENT )
    {
        [self sendNetworkPacketWithPacketID:Type
					   withData:nil
					   ofLength:0];
        if(![self isInCharge] && self.isForbidPropOn)
            [self endTurn];
    }
}

#pragma mark OFMultiplayerDelegate

//these are only required since the sample isn't using OpenGL and has to be manually updated
-(void)gameDidFinish:(OFMultiplayerGame *)game {
    NSLog(@"game did finish");
    if([[CCDirector sharedDirector] runningScene] != [OpenFeintGameScene sharedScene])
        return;
    if(![_brain checkGameOver]) {
        NSString *message = [NSString stringWithFormat:@"%@ has left game.",@"Your opponent"];
        if(self.restartRequestAlert.visible) {
            [self.restartRequestAlert dismissWithClickedButtonIndex:-1 animated:NO];
        }
        if(self.replayRequestAlert.visible) {
            [self.replayRequestAlert dismissWithClickedButtonIndex:-1 animated:NO];
        }
        if(self.restartRequestRejectAlert.visible) {
            [self.restartRequestRejectAlert dismissWithClickedButtonIndex:-1 animated:NO];
        }
        if(self.connectionAlert && self.connectionAlert.visible) {
            self.connectionAlert.message = message;
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You Win!" message:message delegate:self cancelButtonTitle:@"End Game" otherButtonTitles:nil];
            self.connectionAlert = alert;
            [self adjustRotation];
            [alert show];
            [alert release];
        }
        [self commitGameResult:I_WIN];
    }
    //[[MPClassRegistry gameController] refreshView];
}

-(void)playerLeftGame:(unsigned int)playerNumber {
    NSLog(@"player has left game");
}

//Called when the games are updated from the network.
- (void)networkDidUpdateLobby {
    if([OFMultiplayerService getNumberOfChallenges]) {
        OFLog(@"Outstanding challenges %d", [OFMultiplayerService getNumberOfChallenges]);
        //        for(int i=0; i<[OFMultiplayerService getNumberOfChallenges]; ++i) {
        //            OFMultiplayerGame *game = [OFMultiplayerService getChallengeAtIndex:i];
        //            //this functionality does not exist yet
        //            [game sendChallengeResponseWithAccept:YES];
        //        }
    }
    //[[MPClassRegistry lobbyController] refillList];
    //NSLog(@"843");
}

-(void)networkFailureWithReason:(NSUInteger)reason {
    NSLog(@"network fail");
}

//Called when a move was received.
- (BOOL)gameMoveReceived:(OFMultiplayerMove *)move {
    //NSLog(@"gameMoveReceived");
    if(move.code == OFMP_MC_DATA) {
        unsigned char *incomingPacket = (unsigned char *)[move.data bytes];
        stPacketHeader* pPacketHeader = (stPacketHeader*)&incomingPacket[0];
        
        [self recvMsg:pPacketHeader->packetID
                 data:(char*)(incomingPacket + sizeof(stPacketHeader))
               length:(int)move.data.length - sizeof(stPacketHeader)];
        NSLog(@"gameMoveReceived:%d",pPacketHeader->packetID);
    }

	return YES;
}

-(void)handlePushRequestGame:(OFMultiplayerGame*)game options:(NSDictionary*) options {
    const NSSet* gameLaunchTypes = [NSSet setWithObjects:@"accept", @"start", @"finish", @"turn", nil];
    const NSSet* gameLobbyTypes = [NSSet setWithObjects:@"challenge", nil];
    if([gameLaunchTypes containsObject:[options objectForKey:@"type"]]) 
        //[MPClassRegistry showGameControllerWithGame:game];
        NSLog(@"123");
    else if([gameLobbyTypes containsObject:[options objectForKey:@"type"]]) {
        NSLog(@"345");
        //[MPClassRegistry showLobbyForSlot:game.gameSlot];
    }
    
}

-(void)gameLaunchedFromPushRequest:(OFMultiplayerGame*)game withOptions:(NSDictionary*) options
{
    OFLog(@"This is where we would launch game for slot %d type %s", game.gameSlot, [options objectForKey:@"type"]);
    [self handlePushRequestGame:game options:options];
    NSLog(@"353");
}

-(void)gameRequestedFromPushRequest:(OFMultiplayerGame*)game withOptions:(NSDictionary*) options
{
    OFLog(@"Testing push notification response for slot %d type %s", game.gameSlot, [options objectForKey:@"type"]);
    [self handlePushRequestGame:game options:options];
    NSLog(@"125");
}

-(void)didLoginToMultiplayerServer {
    NSLog(@"didLoginToMultiplayerServer");
    [OFMultiplayerService startViewingGames];
    self.isLogin = YES;
}

- (void) didLogoutFromMultiplayerServer {
    NSLog(@"didLogoutFromMultiplayerServer");
    self.isLogin = NO;
}

- (void)rematchAccepted:(OFMultiplayerGame *)game {
    NSLog(@"rematch accepted");
    [self showNotification:@"Rematch accepted"];
    [self gameLayerReposition];
}

- (void)rematchRejected:(OFMultiplayerGame *)game {
    NSLog(@"rematch rejected");
    [self showNotification:@"Rematch failed"];
    [self gotoSysMenuConfirmed];
}

@end
