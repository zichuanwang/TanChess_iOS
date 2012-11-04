//
//  BluetoothConnectLayer.m
//  Tan Chess
//
//  Created by Blue Bitch on 11-2-3.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BluetoothConnectLayer.h"
#import "SysMenu.h"
#import "ConnectedGameScene.h"

typedef enum {
	kStateStartGame,
	kStatePicker,
	kStateMultiplayer,
	kStateMultiplayerCointoss,
	kStateMultiplayerReconnect
} gameStates;

#define kGameSessionID @"TanChessBluetoothConnect"

@interface BluetoothConnectLayer()

- (void)gameLayerReposition;
- (void)dispatchData:(void *)data withType:(int)Type withIdentifier:(int)ID;
    
@end

@implementation BluetoothConnectLayer

@synthesize gameSession, gamePeerId, connectionAlert, restartRequestAlert, replayRequestAlert, restartRequestRejectAlert;
@synthesize isHost = _isHost;
@synthesize rivalDeviceType = _rivalDeviceType;

- (id) init 
{
    self = [super init];
    if (self != nil) 
    {
		// 我们的代码
		NSString* uid = [[UIDevice currentDevice] uniqueIdentifier];
		_uidHash = [uid hash];
		_state = kStateStartGame;
        _isHost = YES;
    }
    return self;
}

-(void)startPicker
{
    GKPeerPickerController *peerPicker;
	_state = kStatePicker;
    peerPicker = [[GKPeerPickerController alloc] init];
    peerPicker.delegate = self;
    //peerPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
    [peerPicker show];
    [[CCDirector sharedDirector] pause];
}

//辅助函数 用于废弃gameSession
- (void)invalidateSession:(GKSession *)session {
	if(session != nil) {
		[session disconnectFromAllPeers]; 
		session.available = NO; 
		[session setDataReceiveHandler: nil withContext: NULL]; 
		session.delegate = nil; 
	}
}

//回调函数
- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker { 
	// Peer Picker automatically dismisses on user cancel. No need to programmatically dismiss.
	// autorelease the picker. 
	picker.delegate = nil;
    [picker autorelease]; 
	
	// go back to start mode
	_state = kStateStartGame;
	
    [[ConnectedGameScene gameLayer] gotoSysMenuConfirmed];
	[[CCDirector sharedDirector] resume];
	
}

- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type { 
	GKSession *session = [[GKSession alloc] initWithSessionID:kGameSessionID displayName:nil sessionMode:GKSessionModePeer]; 
	return [session autorelease]; // peer picker retains a reference, so autorelease ours so we don't leak.
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session { 
	// Remember the current peer.
	self.gamePeerId = peerID;  // copy
	
	// Make sure we have a reference to the game session and it is set up
	self.gameSession = session; // retain
	self.gameSession.delegate = self; 
	[self.gameSession setDataReceiveHandler:self withContext:NULL];
	
	// Done with the Peer Picker so dismiss it.
	[picker dismiss];
	picker.delegate = nil;
	[picker autorelease];
	
	// Start Multiplayer game by entering a cointoss state to determine who is server/client.
	_state = kStateMultiplayerCointoss;
	
	[self sendNetworkPacket:self.gameSession
				   packetID:NETWORK_COINTOSS
				   withData:&_uidHash
				   ofLength:sizeof(_uidHash)
				   reliable:YES];
    
	_state = kStateMultiplayer; // we only want to be in the cointoss state for one loop
} 

- (void)adjustRotation {
    if( !_isHost ) {
        //[connectionAlert setTransform:CGAffineTransformMakeRotation(b2_pi)];
        [[CCDirector sharedDirector] setDeviceOrientation:CCDeviceOrientationPortrait];
        [[ConnectedGameScene sharedScene] setRotation:180.0f];
    }
}

- (void)resetRotation {
    if( !_isHost ) {
        //[connectionAlert setTransform:CGAffineTransformMakeRotation(b2_pi)];
        [[CCDirector sharedDirector] setDeviceOrientation:CCDeviceOrientationPortraitUpsideDown];
        [[ConnectedGameScene sharedScene] setRotation:0.0f];
    }
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state { 
	//NSLog(@"session:%@, %d", peerID, state);
	
    
	if(_state == kStatePicker) {
		return;				// only do stuff if we're in multiplayer, otherwise it is probably for Picker
	}
	
	if(state == GKPeerStateDisconnected) {
		// We've been disconnected from the other peer.
		if( [ConnectedGameScene sharedScene] != [[CCDirector sharedDirector] runningScene] ) {
            return;
        }
        else if([[ConnectedGameScene gameLayer] isGameOverShowing]) {
            return;
        }
		// Update user alert or throw alert if it isn't already up

		NSString *message = [NSString stringWithFormat:@"Could not reconnect with %@.", [session displayNameForPeer:peerID]];
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
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lost Connection" message:message delegate:self cancelButtonTitle:@"End Game" otherButtonTitles:nil];
            self.connectionAlert = alert;
            [self adjustRotation];
			[alert show];
			[alert release];
		}
	} 
} 

- (void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length reliable:(BOOL)howtosend {
	// the packet we'll send is resued
	static unsigned char networkPacket[1024];
	const unsigned int packetHeaderSize = sizeof(stPacketHeader); // we have two "ints" for our header
	
	if(length <= (int)(1024 - packetHeaderSize)) { // our networkPacket buffer size minus the size of the header info
		stPacketHeader* pPacketHeader = (stPacketHeader*)networkPacket;
		// header info
		pPacketHeader->packetID = packetID;
		// copy data in after the header
		memcpy( &networkPacket[packetHeaderSize], data, length ); 
		
		NSData *packet = [NSData dataWithBytes: networkPacket length: (length+packetHeaderSize)];
		if(howtosend == YES) { 
			[session sendData:packet toPeers:[NSArray arrayWithObject:gamePeerId] withDataMode:GKSendDataReliable error:nil];
		} else {
			[session sendData:packet toPeers:[NSArray arrayWithObject:gamePeerId] withDataMode:GKSendDataUnreliable error:nil];
		}
	}
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context { 
	unsigned char *incomingPacket = (unsigned char *)[data bytes];
	stPacketHeader* pPacketHeader = (stPacketHeader*)&incomingPacket[0];
	
	[self recvMsg:pPacketHeader->packetID
			 data:(char*)(incomingPacket + sizeof(stPacketHeader))
		   length:(int)data.length - sizeof(stPacketHeader)];
}

///////////////////////////////////////////////////////////////////////////

- (void)recvMsg:(int)packetID data:(char*)data length:(int)full_length
{
	switch( packetID ) {
		case NETWORK_COINTOSS:
		{
			int coinToss = *((int*)data);
			_isHost = (coinToss > _uidHash);
			[[ConnectedGameScene gameLayer] setHost:_isHost];
            if(!_isHost)
                [[ConnectedGameScene gameLayer] rotationTransfer];
            UIUserInterfaceIdiom deviceType = UI_USER_INTERFACE_IDIOM();
            [self sendNetworkPacket:self.gameSession
                           packetID:RIVAL_DEVICE_TYPE
                           withData:&deviceType
                           ofLength:sizeof(UIUserInterfaceIdiom)
                           reliable:YES];
			break;
		}
        case RIVAL_DEVICE_TYPE:
		{
            _rivalDeviceType = *((UIUserInterfaceIdiom*)data);
            NSLog(@"rival device type: %d", _rivalDeviceType);
            break;
		}
		case CHESSMAN_SELECT_EVENT:
		{
			[[ConnectedGameScene gameLayer] setChessmanSelected:*(int *)data];
			break;
		}
		case CHESSMAN_MOVE_EVENT:
		{
			ChessmanMoveStruct cmStruct = *(ChessmanMoveStruct *)data;
			[[ConnectedGameScene gameLayer] setChessmanImpulse:cmStruct.ChessmanImpluse withID:cmStruct.ChessmanID];
			break;
		}
		case CHESSMAN_COLLISION_EVENT:
		{ 
            int length = sizeof(CGPoint);
            int num = full_length / length;
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
				[[ConnectedGameScene gameLayer] setIsForbidPropOn:YES];
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
			[[ConnectedGameScene gameLayer] setChessmanEnlarged:*(int *)data];
			break;
		}
		case CHESSMAN_CHANGE_EVENT:
		{
			[[ConnectedGameScene gameLayer] setChessmanChanged:*(int *)data];
			break;
		}
		case PROP_SHOW_EVENT:
		{
			int num = *((int*)data);
			[[ConnectedGameScene gameLayer] propShowWithNum:num];
            switch (num) {
                case 0:
                    [[ConnectedGameScene gameLayer] clearScore:POWERUP_NEED_SCORE];
                    break;
                case 1:
                    [[ConnectedGameScene gameLayer] clearScore:FORBID_NEED_SCORE];
                    break;
                case 2:
                    [[ConnectedGameScene gameLayer] clearScore:ENLARGE_NEED_SCORE];
                    break;
                case 3:
                    [[ConnectedGameScene gameLayer] clearScore:CHANGE_NEED_SCORE];
                    break;
                default:
                    break;
            }
            break;
		}
        case RESTART_REQUEST:
        {
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
            break;
        }
        case RESTART_RESPOND:
        {
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
            [[ConnectedGameScene gameLayer] checkChessmanSelectedWhenAppEnterBackground];
            break;
        }
        case CHANGE_TURN_EVENT: {
            NSLog(@"change turn event");
            [[ConnectedGameScene gameLayer] setRivalHasChangeTurn:YES];
            break;
        }
		default:
            // error
			NSLog(@"received a unrecognized package");
			break;
	}	
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self resetRotation];
    if( alertView == connectionAlert ) {
        if(buttonIndex == 0) {
            [[ConnectedGameScene gameLayer] gotoSysMenuConfirmed];
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
            [self gameLayerReposition];
        }
        else if( buttonIndex == 1 ){
            [[ConnectedGameScene gameLayer] gotoSysMenuConfirmed];
        }
    }
    else if( alertView == restartRequestRejectAlert ) {
        if(buttonIndex == 0) {
            //Do nothing
        }
    }
}

- (void)disConnect
{
	if( gameSession != nil )
	{
		[self invalidateSession:self.gameSession];
		self.gameSession = nil;
	}
}

/////////////////////////////////////////////////////////////////////////////

- (void)dispatchData:(void *)data withType:(int)Type withIdentifier:(int)ID
{
	if( Type == CHESSMAN_MOVE_EVENT )
	{
		ChessmanMoveStruct cmStruct;
		cmStruct.ChessmanID = ID;
		cmStruct.ChessmanImpluse = *(b2Vec2 *)data;
		[self sendNetworkPacket:self.gameSession
					   packetID:Type
					   withData:&cmStruct
					   ofLength:sizeof(cmStruct)
					   reliable:YES];
	}
	else if( Type == CHESSMAN_SELECT_EVENT )
	{
		[self sendNetworkPacket:self.gameSession
					   packetID:Type
					   withData:&ID
					   ofLength:sizeof(ID)
					   reliable:YES];
	}
	else if( Type == CHESSMAN_COLLISION_EVENT )
	{   
        NSData *collisionData = (NSData *)data;
        [self.gameSession sendData:collisionData toPeers:[NSArray arrayWithObject:gamePeerId] withDataMode:GKSendDataReliable error:nil];
	}
	else if( Type == PLAY_SOUND_EVENT )
	{
		int NUM = *(int *)data;
		[self sendNetworkPacket:self.gameSession
					   packetID:Type
					   withData:&NUM
					   ofLength:sizeof(NUM)
					   reliable:YES];
		
	}
	else if( Type == CHESSMAN_CHANGE_EVENT )
	{
		[self sendNetworkPacket:self.gameSession
					   packetID:Type
					   withData:&ID
					   ofLength:sizeof(ID)
					   reliable:YES];
	}
	else if( Type == CHESSMAN_ENLARGE_EVENT )
	{
		[self sendNetworkPacket:self.gameSession
					   packetID:Type
					   withData:&ID
					   ofLength:sizeof(ID)
					   reliable:YES];
	}
	else if( Type == PROP_SHOW_EVENT )
	{
		[self sendNetworkPacket:self.gameSession
					   packetID:Type
					   withData:&ID
					   ofLength:sizeof(ID)
					   reliable:YES];
	}
    else if( Type == RESTART_REQUEST ) {
        if(_state != kStateMultiplayer) {
            [self gameLayerReposition];
            return;
        }
        [self sendNetworkPacket:self.gameSession
					   packetID:Type
					   withData:nil
					   ofLength:0
					   reliable:YES];
    }
    else if( Type == RESTART_RESPOND )
    {
        [self sendNetworkPacket:self.gameSession
					   packetID:Type
					   withData:&ID
					   ofLength:sizeof(ID)
					   reliable:YES];
    }
    else if( Type == TOUCH_CANCEL_EVENT )
    {
        [self sendNetworkPacket:self.gameSession
					   packetID:Type
					   withData:nil
					   ofLength:0
					   reliable:YES];
    }
    else if( Type == CHANGE_TURN_EVENT )
    {
        [self sendNetworkPacket:self.gameSession
					   packetID:Type
					   withData:nil
					   ofLength:0
					   reliable:YES];
    }
}

- (void)UpdateDataStandardProcedure {
    std::vector<CGPoint>::iterator it = _vWaitingUpdateData.begin();
    NSLog(@"BlueTooth _vWaitingUpdateData size %lu", _vWaitingUpdateData.size());
    bool isDifferent = NO;
    for( int i = 0; it != _vWaitingUpdateData.end(); it++, i++) {
        if([[ConnectedGameScene gameLayer] setCollisionPosition:(*it) withID:i])
            isDifferent = YES;
    }
    if(isDifferent) {
        NSLog(@"different");
        [[ConnectedGameScene gameLayer] setUpdateTimer];
    }
    else {
        NSLog(@"not different");
        [[ConnectedGameScene gameLayer] setNoDifferentCollision];
    }
    _vWaitingUpdateData.clear();
}

- (void)WaitForDelayedDataTick:(ccTime)dt {
    static ccTime time = 0.0f;
    time += dt;
    if( time >= 3.0f || _vWaitingUpdateData.size() > 0 ) {
        // 超时或更新完毕
        [self unschedule:_cmd];
        if(time < 3.0f && _vWaitingUpdateData.size() > 0) {
            NSLog(@"Now Good");
            [self UpdateDataStandardProcedure];
        }
        else {
           [[ConnectedGameScene gameLayer] setNoDifferentCollision]; 
        }
        time = 0;
    }
}

- (void)UpdateData {
    [ConnectedGameScene gameLayer].isUpdating = YES;
    [self schedule:@selector(WaitForDelayedDataTick:) interval:0.3f];
}

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

- (void)gameLayerReposition {
    [[ConnectedGameScene gameLayer] reposition];
}

- (void) dealloc
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

- (void)clearWaitingUpdateData {
    _vWaitingUpdateData.clear();
}

@end
