//
//  ConnectedChessmanSprite.m
//  Tan Chess
//
//  Created by Blue Bitch on 11-2-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ConnectedChessmanSprite.h"
#import "ConnectedGameScene.h"

@implementation ConnectedChessmanSprite

+ (id)chessmanWithImageFile:(NSString*)imgFile withFilename:(NSString*)filename withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type
{
	ConnectedChessmanSprite *sprite = [ConnectedChessmanSprite spriteWithFile:imgFile];
    if(type) {
        sprite.rotation = 180;
        sprite.isForbad = YES;
    }
    sprite.position = position;
    sprite.initPos = position;
	sprite.scale = scale;
    sprite.initScale = scale;
    sprite.type = type;	
    
    CCSprite *image = nil;
	image = [CCSprite spriteWithFile:filename];
	image.anchorPoint = ccp( 0, 0 );
	image.position = ccp( 0, 0 );
	sprite.Image = image;
	[sprite addChild:image z:1];
	
	return sprite;
}

- (void)connectPowerUp {
    [[ConnectedGameScene gameLayer] shutDownPowerUp];
}

- (void)connectChange {
    [[ConnectedGameScene gameLayer] spriteChange:self];
    [[ConnectedGameScene bluetoothConnectLayer] dispatchData:nil withType:CHESSMAN_CHANGE_EVENT withIdentifier:_ID];
    [[SimpleAudioEngine sharedEngine] playEffect:@"change_ef.wav"];
    [[ConnectedGameScene gameLayer] shutDownChange];
}

- (bool)connectEnlarge {
    if( self.scale == LARGE_SIZE )
    {
        return NO;
    }
    else if( self.scale == SMALL_SIZE )
    {
        self.scale = MEDIUM_SIZE;
        [[ConnectedGameScene gameLayer] spriteEnlarge:self];
    }
    else if( self.scale == MEDIUM_SIZE )
    {
        self.scale = LARGE_SIZE;
        [[ConnectedGameScene gameLayer] spriteEnlarge:self];
    }
    [[ConnectedGameScene bluetoothConnectLayer] dispatchData:nil withType:CHESSMAN_ENLARGE_EVENT withIdentifier:_ID];
    [[SimpleAudioEngine sharedEngine] playEffect:@"change_ef.wav"];
    return YES;
}

- (void)connectSelect {
    [[ConnectedGameScene bluetoothConnectLayer] dispatchData:nil withType:CHESSMAN_SELECT_EVENT withIdentifier:_ID];
    [ConnectedGameScene gameLayer].turnValid = NO;
    [[ConnectedGameScene gameLayer] setCurrentChessman:self];
}

- (void)connectEndTouch:(b2Vec2)impulse {
    
	[[ConnectedGameScene gameLayer] addUpdateChessman:self];
	//发送数据
	[[ConnectedGameScene bluetoothConnectLayer] dispatchData:&impulse withType:CHESSMAN_MOVE_EVENT withIdentifier:_ID];
    [ConnectedGameScene gameLayer].isValid = NO;
}

- (bool)connectTurnInvalid {
    return ![ConnectedGameScene gameLayer].turnValid;
}

- (float)getMaxLength:(int)radius {
    return [[ConnectedGameScene gameLayer] getLargestPermittedLength:_body withMax: radius * 2 * self.scale];
}

- (void) dealloc
{
    [super dealloc];
}

- (void)setImpulse:(b2Vec2)impulse
{
	if( self.NewBackColor == nil )
	{
		self.opacity = 255;
	}
	else
	{
		self.NewBackColor.opacity = 255;
	}
	self.Image.opacity = 255;
	
	if( impulse.x != 0 && impulse.y != 0 )
	{
		[[SimpleAudioEngine sharedEngine] playEffect:@"fire.wav"];
	}
	
	if( _body != nil )
	{
		_body->ApplyLinearImpulse( impulse, _body->GetPosition() );
	}
	
    _isSelected = NO;
    [[ConnectedGameScene gameLayer] addUpdateChessman:self];
    [ConnectedGameScene gameLayer].isValid = NO;
    [self createEmitter];
}

- (void)setEnlarged
{
	if( self.scale == SMALL_SIZE )
	{
		self.scale = MEDIUM_SIZE;
		[[ConnectedGameScene gameLayer] spriteEnlarge:self];
	}
	else if( self.scale == MEDIUM_SIZE )
	{
		self.scale = LARGE_SIZE;
		[[ConnectedGameScene gameLayer] spriteEnlarge:self];
	}
	[[SimpleAudioEngine sharedEngine] playEffect:@"change_ef.wav"];
}

- (void)setChanged
{
	[[ConnectedGameScene gameLayer] spriteChange:self];
	[[SimpleAudioEngine sharedEngine] playEffect:@"change_ef.wav"];
}

- (void)setSelected
{
	[[ConnectedGameScene gameLayer] setCurrentChessman:self];
	if( self.NewBackColor == nil )
	{
		self.opacity = 150;
	}
	else
	{
		self.NewBackColor.opacity = 150;
	}
	self.Image.opacity = 150;
	//NSLog(@"%f",self.rotation);
	[[SimpleAudioEngine sharedEngine] playEffect:@"select.wav"];
	[ConnectedGameScene gameLayer].turnValid = NO;
    _isSelected = YES;
}

- (bool)IsPropShowOn {
    if( [ConnectedGameScene gameLayer].nProp != -1 ) {
        return  YES;
    }
    else{
        return NO;
    }
}

- (void)cancelSelect {
    [super cancelSelect];
    [[ConnectedGameScene bluetoothConnectLayer] dispatchData:nil withType:TOUCH_CANCEL_EVENT withIdentifier:0];
}

@end

