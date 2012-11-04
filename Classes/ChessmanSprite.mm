//
//  chessman.m
//  Cocos2DSimpleGame
//
//  Created by Blue Bitch on 10-11-27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ChessmanSprite.h"
#import "GunsightSprite.h"
#import "SimpleAudioEngine.h"
#import "GameScene.h"


@implementation ChessmanSprite

@synthesize type = _type;
@synthesize isEmitterOn = _isEmitterOn;
@synthesize isDead = _isDead;
@synthesize isForbad = _isForbad;
@synthesize isSelected = _isSelected;
@synthesize isPowerUp = _isPowerUp;
@synthesize isEnlarge = _isEnlarge;
@synthesize isChange = _isChange;
@synthesize value = _value;
@synthesize Image = _Image;
@synthesize NewBackColor = _NewBackColor;
@synthesize body = _body;
@synthesize initPos = _initPos;
@synthesize initScale = _initScale;
@synthesize isBetray = _isBetray;
@synthesize ID = _ID;
@synthesize isContactLock = _isContactLock;
//@synthesize isMoving = _isMoving;
@synthesize Gunsight = _Gunsight;

+ (id)chessmanWithImageFile:(NSString*)imgFile withFilename:(NSString*)filename withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type {
	ChessmanSprite *sprite = [ChessmanSprite spriteWithFile:imgFile];
    if(type == GROUP2) {
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

- (id)init {
    if((self = [super init]) == nil) {
        return nil;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _chessboardWidth = 500;
        _chessboardHeight = 740;
    }
    else {
        _chessboardWidth = 250;
        _chessboardHeight = 370;
    }
    _Gunsight = [GunsightSprite createGunsight];
    return self;
}

- (void)removeEmitter {
    if(_emitter != nil) {
        [self removeChild:_emitter cleanup:YES];
        _emitter = nil;
    }
    _isEmitterOn = NO;
}

- (void)createEmitter {
    [self removeEmitter];
    _emitter = [[CCParticleSun alloc] initWithTotalParticles:100];
    _emitter.posVar = ccp(3, 3);
    _emitter.speed = 20;
    _emitter.speedVar = 40; //喷发速度变化范围
    _emitter.startSize = 15;
    _emitter.startSizeVar = 12.5;
    _emitter.endSize = 2.5;
    _emitter.endSizeVar = 1;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        _emitter.speed *= 2;
        _emitter.speedVar *= 2; //喷发速度变化范围
        _emitter.startSize *= 2;
        _emitter.startSizeVar *= 2;
        _emitter.endSize *= 2;
        _emitter.endSizeVar *= 2;
    }
    _emitter.life = 1;
    _emitter.lifeVar = 0.5;
    if(_type == 0) {
        ccColor4F startColor = {0.2f, 0.4f, 0.7f, 1.0f};
        //ccColor4F startColor = {1.0f, 0.0f, 0.0f, 1.0f};
        _emitter.startColor = startColor;
    }
    else {
        //NSLog(@"> = <");
        ccColor4F startColor = {0.8f, 0.6f, 0.3f, 1.0f};
        _emitter.startColor = startColor;
    }
    
    ccColor4F endColor = {0.0f, 0.0f, 0.0f, 0.1f};
    _emitter.endColor = endColor;
    [self addChild:_emitter z:1];
    [_emitter release];
    
    _emitter.position = ccp(self.contentSize.width / 2, self.contentSize.height / 2);
    _isEmitterOn = YES;
	_emitter.rotation = -self.rotation;
}

- (void)shutDownEmitter
{
	[_emitter stopSystem];
    _isEmitterOn = NO;
}

- (CGRect)rect
{
	// NSLog([self description]);
	return CGRectMake(-rect_.size.width / 2, -rect_.size.height / 2, rect_.size.width, rect_.size.height);
}

//注册
- (void)onEnter
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:1 swallowsTouches:NO];
	[super onEnter];
}

//注销
- (void)onExit
{
	[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
	[super onExit];
}	

+ (CGFloat)distanceBetweenTwoPoints:(CGPoint)fromPoint toPoint:(CGPoint)toPoint
{
	float x = toPoint.x - fromPoint.x; 
	float y = toPoint.y - fromPoint.y; 
	return sqrt(x * x + y * y);
}

- (BOOL)containsTouchLocation:(UITouch *)touch
{
	//CGPoint pt = [self convertTouchToNodeSpaceAR:touch];
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	float distance = [ChessmanSprite distanceBetweenTwoPoints:self.position toPoint:touchPoint];
	return distance <= 25 * self.scale;
}

- (float)getMaxLength:(int)radius {
    return [[GameScene gameLayer] getLargestPermittedLength:_body withMax: radius * 2 * self.scale];
}

- (BOOL)containsTouchLocationEx:(UITouch *)touch
{
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	float distance = [ChessmanSprite distanceBetweenTwoPoints:self.position toPoint:touchPoint];
    int radius;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        radius = 50;
    }
    else{
        radius = 25;
    }
	float result = [self getMaxLength:radius];
	if( distance > result - 0.01 )
	{
		return NO;
	}
    //NSLog(@"touchPoint %f,%f",touchPoint.x,touchPoint.y);
	return YES;
}

- (void)connectPowerUp {
    [[GameScene gameLayer] shutDownPowerUp];
}

- (void)connectChange {
    [[GameScene gameLayer] spriteChange:self];
    [[SimpleAudioEngine sharedEngine] playEffect:@"change_ef.wav"];
    [[GameScene gameLayer] shutDownChange];
}

- (bool)connectEnlarge {
    if( self.scale == LARGE_SIZE )
    {
        return NO;
    }
    else if( self.scale == SMALL_SIZE )
    {
        self.scale = MEDIUM_SIZE;
        [[GameScene gameLayer] spriteEnlarge:self];
    }
    else if( self.scale == MEDIUM_SIZE )
    {
        self.scale = LARGE_SIZE;
        [[GameScene gameLayer] spriteEnlarge:self];
    }
    [[SimpleAudioEngine sharedEngine] playEffect:@"change_ef.wav"];
    return YES;
}

- (void)connectSelect {
    [GameScene gameLayer].turnValid = NO;
    [[GameScene gameLayer] setCurrentChessman:self];
}

- (void)connectEndTouch:(b2Vec2)impulse {
    [[GameScene gameLayer] addUpdateChessman:self];
    [GameScene gameLayer].isValid = NO;
}

- (bool)connectTurnInvalid {
    return ![GameScene gameLayer].turnValid;
}

- (bool)IsPropShowOn {
    if( [GameScene gameLayer].nProp != -1 ) {
        return  YES;
    }
    else {
        return NO;
    }
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if( _isForbad && !_isChange )
	{
		return NO;
	}
	//点了change却没有交换的情况
	if( !_isForbad && _isChange )
	{
		return NO;
	}
	if( _isDead )
	{
		return NO;
	}
	if( [self connectTurnInvalid] )
	{
		return NO;
	}
    if( [self IsPropShowOn] ) {
        return  NO;
    }
	if ( ![self containsTouchLocationEx:touch] ) 
	{
		return NO;
	}
	if( _isChange )
	{
        [self connectChange];
		return NO;
	}
	if( _isEnlarge )
	{
        [self connectEnlarge];
		return NO;
	}
	_Gunsight.scale = 0;
	if( _isPowerUp )
	{
		_Gunsight.opacity = 0;
		[[(GunsightSprite *)_Gunsight _PowerUpMode] setOpacity:255];
	}
	[_Gunsight setVisible:YES];
    _Gunsight.position = self.position;
	_Speed = 0;
	//NSLog(@"opacity:%d",self.opacity);
	if( self.NewBackColor == nil )
	{
		self.opacity = 150;
	}
	else
	{
		self.NewBackColor.opacity = 150;
	}
	self.Image.opacity = 150;
    [self connectSelect];
	[[SimpleAudioEngine sharedEngine] playEffect:@"select.wav"];
	self.isSelected = YES;
	return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	float distance = [ChessmanSprite distanceBetweenTwoPoints:self.position toPoint:touchPoint];
	
	//rotate
	float angle;
	if( touchPoint.x >= self.position.x )
	{
		angle = 180 + acos( ( touchPoint.y - self.position.y ) / distance ) / 2 / b2_pi * 360;
	}
	else 
	{
		angle = 180 - acos( ( touchPoint.y - self.position.y ) / distance ) / 2 / b2_pi * 360;
	}
    _Gunsight.rotation = angle;
	
	//zoom
	if( distance <= 33.0f && distance >= 13.0f )
	{
		_Gunsight.scale = distance / 33.0f;
		_Speed = distance - 13.0f;

	}
    else if(distance < 13.0f) {
        _Gunsight.scale = 0;
        _Speed = 0;
    }
	else
	{
		_Gunsight.scale = 1;
		_Speed = 20.0f;
	}
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
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
    float angle = _Gunsight.rotation;	
	if( _isPowerUp )
	{
		_Speed *= 1.4;
		//NSLog(@"is power up");
		_Gunsight.opacity = 255;
		[[(GunsightSprite *)_Gunsight _PowerUpMode] setOpacity:0];
		[self connectPowerUp];
	}
	
	if( self.scale == SMALL_SIZE )
	{
		_Speed *= 0.63f / 20 * 45;
	}
	else if( self.scale == LARGE_SIZE )
	{
		_Speed *= 1.6f / 20 * 45;
	}
	else if( self.scale == MEDIUM_SIZE )
	{
		_Speed *= 1.3f / 20 * 45;
	}

	b2Vec2 impulse = b2Vec2( _Speed * sin( angle / 180 * b2_pi ), _Speed * cos( angle / 180 * b2_pi ) );
	//CCLOG(@"Angle = %f", angle);
	//CCLOG(@"Speed = ( %f, %f )", _Speed * sin( angle / 360 * b2_pi ), _Speed * cos( angle / 360 * b2_pi ));
    
	_body->ApplyLinearImpulse( impulse, _body->GetPosition() );
    [self connectEndTouch:impulse];
	[_Gunsight setVisible:NO];
	
	if( _Speed > 0 )
	{
		//_body->SetBullet(YES);
		[[SimpleAudioEngine sharedEngine] playEffect:@"fire.wav"];
	}
	
	_Speed = 0;
	_Gunsight.rotation = 0;
	
    [self createEmitter];	

	self.isSelected = NO;
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	//NSLog(@"canceled");
}

- (bool)checkAlive {
	CGSize screenSize = [CCDirector sharedDirector].winSize;
	if( self.position.x < screenSize.width / 2 - _chessboardWidth / 2 || self.position.x > screenSize.width / 2 + _chessboardWidth / 2 )
	{
		return NO;
	}
	if( self.position.y < screenSize.height / 2 - _chessboardHeight / 2 || self.position.y > screenSize.height / 2 + _chessboardHeight / 2 )
	{
		return NO;
	}
	return YES;
}

- (bool)checkAlive:(CGPoint)point
{
	CGSize screenSize = [CCDirector sharedDirector].winSize;
	if( point.x < screenSize.width / 2 - _chessboardWidth / 2 || point.x > screenSize.width / 2 + _chessboardWidth / 2 )
	{
		return NO;
	}
	if( point.y < screenSize.height / 2 - _chessboardHeight / 2 || point.y > screenSize.height / 2 + _chessboardHeight / 2 )
	{
		return NO;
	}
	return YES;
}

- (int)getOpacity {
    return _Image.opacity;
}

- (void)cancelSelect {
    if( self.NewBackColor == nil )
	{
		self.opacity = 255;
	}
	else
	{
		self.NewBackColor.opacity = 255;
	}
	self.Image.opacity = 255;
    _isSelected = NO;
    [_Gunsight setVisible:NO];
}

- (void) dealloc {
	[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
	[super dealloc];
}


@end
