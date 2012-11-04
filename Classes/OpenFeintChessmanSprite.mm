//
//  OpenFeintChessmanSprite.m
//  Tan Chess HD
//
//  Created by Bluebitch on 11-5-23.
//  Copyright 2011年 TJU. All rights reserved.
//

#import "OpenFeintChessmanSprite.h"
#import "OFMultiplayerService.h"
#import "OFMultiplayerService+Advanced.h"
#import "OpenFeintGameScene.h"
#import "BluetoothConnectLayer.h"

@implementation OpenFeintChessmanSprite

+ (id)chessmanWithImageFile:(NSString*)imgFile withFilename:(NSString*)filename withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type
{
	OpenFeintChessmanSprite *sprite = [OpenFeintChessmanSprite spriteWithFile:imgFile];
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
    [[OpenFeintGameScene gameLayer] shutDownPowerUp];
}

- (void)connectChange {
    [[OpenFeintGameScene gameLayer] spriteChange:self];
    [[OpenFeintGameScene gameLayer] dispatchData:nil withType:CHESSMAN_CHANGE_EVENT withIdentifier:_ID];
    [[SimpleAudioEngine sharedEngine] playEffect:@"change_ef.wav"];
    [[OpenFeintGameScene gameLayer] shutDownChange];
}

- (bool)connectEnlarge {
    if( self.scale == LARGE_SIZE )
    {
        return NO;
    }
    else if( self.scale == SMALL_SIZE )
    {
        self.scale = MEDIUM_SIZE;
        [[OpenFeintGameScene gameLayer] spriteEnlarge:self];
    }
    else if( self.scale == MEDIUM_SIZE )
    {
        self.scale = LARGE_SIZE;
        [[OpenFeintGameScene gameLayer] spriteEnlarge:self];
    }
    [[OpenFeintGameScene gameLayer] dispatchData:nil withType:CHESSMAN_ENLARGE_EVENT withIdentifier:_ID];
    [[SimpleAudioEngine sharedEngine] playEffect:@"change_ef.wav"];
    return YES;
}

- (void)connectSelect {
    [[OpenFeintGameScene gameLayer] dispatchData:nil withType:CHESSMAN_SELECT_EVENT withIdentifier:_ID];
    [OpenFeintGameScene gameLayer].turnValid = NO;
    [[OpenFeintGameScene gameLayer] setCurrentChessman:self];
}

- (void)connectEndTouch:(b2Vec2)impulse {
	[[OpenFeintGameScene gameLayer] addUpdateChessman:self];
	//发送数据
	[[OpenFeintGameScene gameLayer] dispatchData:&impulse withType:CHESSMAN_MOVE_EVENT withIdentifier:_ID];
    [OpenFeintGameScene gameLayer].isValid = NO;
}

- (bool)connectTurnInvalid {
    return ![OpenFeintGameScene gameLayer].turnValid;
}

- (float)getMaxLength:(int)radius {
    return [[OpenFeintGameScene gameLayer] getLargestPermittedLength:_body withMax: radius * 2 * self.scale];
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
    [[OpenFeintGameScene gameLayer] addUpdateChessman:self];
    [self createEmitter];
}

- (void)setEnlarged
{
	if( self.scale == SMALL_SIZE )
	{
		self.scale = MEDIUM_SIZE;
		[[OpenFeintGameScene gameLayer] spriteEnlarge:self];
	}
	else if( self.scale == MEDIUM_SIZE )
	{
		self.scale = LARGE_SIZE;
		[[OpenFeintGameScene gameLayer] spriteEnlarge:self];
	}
	[[SimpleAudioEngine sharedEngine] playEffect:@"change_ef.wav"];
}

- (void)setChanged
{
	[[OpenFeintGameScene gameLayer] spriteChange:self];
	[[SimpleAudioEngine sharedEngine] playEffect:@"change_ef.wav"];
}

- (void)setSelected
{
	[[OpenFeintGameScene gameLayer] setCurrentChessman:self];
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
	[OpenFeintGameScene gameLayer].turnValid = NO;
    _isSelected = YES;
}

- (bool)IsPropShowOn {
    if( [OpenFeintGameScene gameLayer].nProp != -1 ) {
        return  YES;
    }
    else{
        return NO;
    }
}

- (void)cancelSelect {
    [super cancelSelect];
    [[OpenFeintGameScene gameLayer] dispatchData:nil withType:TOUCH_CANCEL_EVENT withIdentifier:0];
}


@end
