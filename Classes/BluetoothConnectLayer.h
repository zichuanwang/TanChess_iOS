//  人生若只如初见，何事秋风悲画扇。
//  BluetoothConnectLayer.h
//  Tan Chess
//
//  Created by Blue Bitch on 11-2-3.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "ConnectedGameLayer.h"
#import "vector"

typedef enum {
	NETWORK_ACK,					// no packet
	NETWORK_COINTOSS,				// decide who is going to be the server
    RIVAL_DEVICE_TYPE,
	CHESSMAN_SELECT_EVENT,
	CHESSMAN_COLLISION_EVENT,
	CHESSMAN_MOVE_EVENT,			
	PLAY_SOUND_EVENT,
	CHESSMAN_CHANGE_EVENT,
	CHESSMAN_ENLARGE_EVENT,
	PROP_SHOW_EVENT,
    RESTART_REQUEST,
    REPLAY_REQUEST,
    RESTART_RESPOND,
    REPLAY_RESPOND,
    TOUCH_CANCEL_EVENT,
    CHANGE_TURN_EVENT
} packetCodes;

typedef struct
{
	int ChessmanID;
	CGPoint Position;
	float Angle;
}ChessmanCollisionStruct;

typedef struct tagPacketHeader
{
	int packetID;
} stPacketHeader;

typedef struct
{
	int ChessmanID;
	b2Vec2 ChessmanImpluse;
}ChessmanMoveStruct;

@interface BluetoothConnectLayer : CCLayer<GKPeerPickerControllerDelegate, GKSessionDelegate, UIAlertViewDelegate>
{
	int _state;
	int _uidHash;
	BOOL _isHost;
    UIUserInterfaceIdiom _rivalDeviceType;
	
	GKSession		*gameSession;
	NSString		*gamePeerId;
	UIAlertView		*connectionAlert;
    UIAlertView		*restartRequestAlert;
    UIAlertView		*replayRequestAlert;
    UIAlertView     *restartRequestRejectAlert;
    
    std::vector<CGPoint> _vWaitingUpdateData;
}

@property (nonatomic,readwrite,assign) BOOL isHost;
@property(nonatomic, retain) GKSession	 *gameSession;
@property(nonatomic, copy)	 NSString	 *gamePeerId;
@property(nonatomic, retain) UIAlertView *connectionAlert;
@property(nonatomic, retain) UIAlertView *restartRequestAlert;
@property(nonatomic, retain) UIAlertView *replayRequestAlert;
@property(nonatomic, retain) UIAlertView *restartRequestRejectAlert;
@property UIUserInterfaceIdiom rivalDeviceType;

- (void)startPicker;
- (void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length reliable:(BOOL)howtosend;
- (void)recvMsg:(int)packetID data:(char*)data length:(int)length;
- (void)dispatchData:(void *)data withType:(int)Type withIdentifier:(int)ID;
- (void)disConnect;
- (void)UpdateData;
- (void)replayAlert;
- (void)clearWaitingUpdateData;

@end

