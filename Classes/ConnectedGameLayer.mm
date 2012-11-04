//
//  ConnectedGameLayer.m
//  Tan Chess
//
//  Created by Blue Bitch on 11-2-3.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#import "ConnectedGameLayer.h"
#import "ConnectedContactListener.h"
#import "PauseButton.h"
#import "SimpleAudioEngine.h"
#import "ConnectedGameScene.h"
#import "ConnectedPropSprite.h"
#import "OpenFeintGameScene.h"


//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32

@implementation ConnectedGameLayer

@synthesize isUpdating = _isUpdating, isWaitingForPlayer = _isWaitingForPlayer;

- (void)tick:(ccTime)dt {
    if( _isUpdating ) {
        return;
    }
    [super tick:dt];
}

- (void)sendCollisionChessman {
    [_brain sendCollisionDataViaBluetooth];  
}

- (void)createPropwithFilename:(NSString*)filename withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type withScore:(int)score withCategory:(int)cat
{
	ConnectedPropSprite *Prop = [ConnectedPropSprite propWithImageFile:filename withPosition:position withScale:scale withType:type withScore:score withCategory:cat];
	[self createPropStandardProcedure:Prop];
     }

- (void)createChessmanwithFilename:(NSString*)filename withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type
{
	ConnectedChessmanSprite *Chessman;
	if( type == 1 )
	{
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			Chessman = [ConnectedChessmanSprite chessmanWithImageFile:@"Green-ipad.png" withFilename:filename withPosition:position withScale:scale withType:type];
		}
		else {
			Chessman = [ConnectedChessmanSprite chessmanWithImageFile:@"Green.png" withFilename:filename withPosition:position withScale:scale withType:type];
		}
	}
	else
	{
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			Chessman = [ConnectedChessmanSprite chessmanWithImageFile:@"Red-ipad.png" withFilename:filename withPosition:position withScale:scale withType:type];
		}
		else {
			Chessman = [ConnectedChessmanSprite chessmanWithImageFile:@"Red.png" withFilename:filename withPosition:position withScale:scale withType:type];
		}
	}
    [self createChessmanStandardProcedure:Chessman withScale:scale];
}

- (bool)changePlayer {
    if([self isInCharge] || self.isForbidPropOn)
        [[ConnectedGameScene bluetoothConnectLayer] dispatchData:nil withType:CHANGE_TURN_EVENT withIdentifier:0];
    bool result = [self changePlayerStandardProcedure];
    if(result) {
        if([self isInCharge]) {
            NSLog(@"is in charge");
            [_brain changePlayerWhenConnecting];
        }
        else {
            NSLog(@"is not in charge");
            [_brain changePlayer];
        }
        NSLog(@"Change Player to %d",_brain.currentPlayer);
    }
    else
        NSLog(@"not change player");
    return result;
}

- (void)setPauseButtonType:(PauseButton *)button {
    [button set_type:1];
}

- (void)setPicNum:(int *)mainPicNum withStar:(int *)starPicNum {
    if( [ConnectedGameScene bluetoothConnectLayer].isHost ) {
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
	if (self) {
        _nCollisionNum = 0;
        if( _contactListener != nil ) {
            delete _contactListener;
            _contactListener = nil;
        }
        _contactListener = (MyContactListener *) (new ConnectedContactListener());
		_world->SetContactListener(_contactListener);
        _contactListener->SetHingeFixture(FixtureA, FixtureB);
	}
	return self;
}

- (void)turnOnPowerUp
{
    [[ConnectedGameScene bluetoothConnectLayer] dispatchData:nil withType:PROP_SHOW_EVENT withIdentifier:0];
	[super turnOnPowerUp];
}

- (void)turnOnForbid
{
    [[ConnectedGameScene bluetoothConnectLayer] dispatchData:nil withType:PROP_SHOW_EVENT withIdentifier:1];
	[super turnOnForbid];
}

- (void)turnOnEnlarge
{
    [[ConnectedGameScene bluetoothConnectLayer] dispatchData:nil withType:PROP_SHOW_EVENT withIdentifier:2];
	[super turnOnEnlarge];
}

- (void)turnOnChange
{
	[[ConnectedGameScene bluetoothConnectLayer] dispatchData:nil withType:PROP_SHOW_EVENT withIdentifier:3];
	[super turnOnChange];
}

- (void)dealloc
{
    [super dealloc];
}

- (void)setChessmanImpulse:(b2Vec2)impulse withID:(int)ID
{
	[_brain setConnectedChessmanImpulse:impulse withID:ID];
}

- (void)setUpdateTimer {
    [self schedule:@selector(updateTimer:) interval:1.0f];
}

- (void)setNoDifferentCollision {
    _hasSentUpdateData = YES;
    _isUpdating = NO;
    NSLog(@"set no different");
}

- (void)updateTimer:(ccTime)dt {
    [self unschedule:_cmd];
    [self setNoDifferentCollision];
    NSLog(@"unschedule update timer");
}

- (bool)setCollisionPosition:(CGPoint)point withID:(int)ID {
    return [_brain setCollisionPosition:point withID:ID];
}

- (void)reposition {
    [super reposition];
    [[ConnectedGameScene bluetoothConnectLayer] clearWaitingUpdateData];
	if( ![ConnectedGameScene bluetoothConnectLayer].isHost )
        [_brain setPlayer1Forbad];
}

- (void)resumeGame {
    [[SimpleAudioEngine sharedEngine] playEffect:@"start.wav"];
}

- (void)resumeGameTick:(ccTime)dt {
    [self unschedule:_cmd];
    self.isWaitingForPlayer = NO;
    [[CCDirector sharedDirector] resume];
    [[SimpleAudioEngine sharedEngine] playEffect:@"start.wav"];
}

- (void)setHost:(BOOL)isHost {
	if(!isHost) {
		[_brain setPlayer1Forbad];
	}
    else {
        [self resumeGame];
    }
    [[CCDirector sharedDirector] resume];
}

- (void)setChessmanSelected:(int)ID {
	[_brain setConnectedChessmanSelected:ID];
}

- (void)setChessmanEnlarged:(int)ID {
	[_brain setConnectedChessmanEnlarged:ID];
}


- (void)setChessmanChanged:(int)ID {
	[_brain setConnectedChessmanChanged:ID];
}

- (void)propShowWithNum:(int)num
{
	_nProp = num;
	[self schedule:@selector(Proptick:)];
}

- (bool)isInCharge {
    bool result = NO;
    if( _brain.currentPlayer == PLAYER1 && [ConnectedGameScene bluetoothConnectLayer].isHost ) {
        result = YES;
    }
    else if( _brain.currentPlayer == PLAYER2 && ![ConnectedGameScene bluetoothConnectLayer].isHost ) {
        result = YES;
    }
    return result;
}

- (void)updateCollisionChessmanData{
    if( [self isInCharge] ) {
        [self sendCollisionChessman];
        [self setNoDifferentCollision];
        if(self.isForbidPropOn)
            [[ConnectedGameScene bluetoothConnectLayer] dispatchData:nil withType:CHANGE_TURN_EVENT withIdentifier:0];
        else
            _rivalHasChangeTurn = YES;
    }
    else {
        [[ConnectedGameScene bluetoothConnectLayer] UpdateData];
    }
} 


- (void)playGameOverMusic {
    if( [ConnectedGameScene bluetoothConnectLayer].isHost && [_brain player2Win] ) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"lose.wav"];
    }
    else if( ![ConnectedGameScene bluetoothConnectLayer].isHost && [_brain player1Win] ) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"lose.wav"];
    }
    else {
        [[SimpleAudioEngine sharedEngine] playEffect:@"win.wav"];
    }
}

- (void)resetPauseButtonPos {
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    CCSprite *sprite = (CCSprite *)[self getChildByTag:101];
    sprite.rotation = 180;
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad){
        [sprite setPosition:ccp( screenSize.width - 305, screenSize.height - 18 )];
    }
    else {
        [sprite setPosition:ccp( 50, screenSize.height - 50 )];
    }
    CCSprite *chessboard = (CCSprite *)[self getChildByTag:405];
    chessboard.rotation = 180;
    CCSprite *chessboardCover = (CCSprite *)[self getChildByTag:406];
    chessboardCover.rotation = 180;
    if([[[CCDirector sharedDirector] runningScene] isMemberOfClass:[ConnectedGameScene class]]) {
        [[ConnectedGameScene backgroundLayer] rotateBackground:180];
        NSLog(@"connected game scene background rotate");
    }
    else {
        [[OpenFeintGameScene backgroundLayer] rotateBackground:180];
        NSLog(@"openfeint game scene background rotate");
    }
}

- (void)setInitPauseButtonPos {
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    CCSprite *sprite = (CCSprite *)[self getChildByTag:101];
    sprite.rotation = 0;
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad){
        [sprite setPosition:ccp( 305, 18 )];
    }
    else {
        [sprite setPosition:ccp( screenSize.width - 50, 50 )];
    }
    CCSprite *chessboard = (CCSprite *)[self getChildByTag:405];
    chessboard.rotation = 0;
    CCSprite *chessboardCover = (CCSprite *)[self getChildByTag:405];
    chessboardCover.rotation = 0;
    if([[[CCDirector sharedDirector] runningScene] isMemberOfClass:[ConnectedGameScene class]])
        [[ConnectedGameScene backgroundLayer] rotateBackground:0];
    else if([[[CCDirector sharedDirector] runningScene] isMemberOfClass:[OpenFeintGameScene class]])
        [[OpenFeintGameScene backgroundLayer] rotateBackground:0];
}


- (void)gotoSysMenu {
    // 询问玩家是否要再来一盘 如不需要才返回系统菜单
    [[ConnectedGameScene bluetoothConnectLayer] replayAlert];
}

- (void)gotoSysMenuConfirmed {
    self.isWaitingForPlayer = NO;
    [[ConnectedGameScene bluetoothConnectLayer] disConnect];
    [super gotoSysMenu];
}

- (void)fadeInTick:(ccTime)dt {
    [self unschedule:_cmd];
    [self restartWithMusic:NO];
    self.isWaitingForPlayer = YES;
    [[ConnectedGameScene bluetoothConnectLayer] startPicker];
}

- (void)rotationTransferTick:(ccTime)dt {
    [self unschedule:_cmd];
    [[CCDirector sharedDirector] setDeviceOrientation:CCDeviceOrientationPortraitUpsideDown];
    [[ConnectedGameScene gameLayer] resetPauseButtonPos];
    [super fadeInStandardProcedure];
    [self schedule:@selector(resumeGameTick:) interval:0.3];
}

- (void)rotationTransfer {
    [super fadeOutStandardProcedure];
    [self schedule:@selector(rotationTransferTick:) interval:0.3];
    
}

- (void)fadeOutTick:(ccTime)dt {
    [self setInitPauseButtonPos];
    [super fadeOutTick:dt];
}

- (void)setRivalHasChangeTurn:(bool)isChange {
    _rivalHasChangeTurn = isChange;
}

@end

