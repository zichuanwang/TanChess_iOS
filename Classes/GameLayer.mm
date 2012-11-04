//
//  GameLayer.m
//  Cocos2DSimpleGame
//
//  Created by Blue Bitch on 10-11-19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import "GameLayer.h"
#import "SysScene.h"
#import "LoadingScene.h"
#import "PauseButton.h"
#import "SimpleAudioEngine.h"
#import "GameScene.h"
#import "PropSprite.h"
#import "ConnectedGameLayer.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.

@interface GameLayer()

- (b2Fixture *)addBoxBodyForHinge:(CCSprite *)sprite;
- (void)stopDestroyChessmanTick:(ccTime)dt;
- (void)gameOver;
- (void)drawTrunMark;
- (void)load;
- (bool)changePlayer;
- (void)updateCollisionChessmanData;


@end

@implementation GameLayer

@synthesize isForbidPropOn = _isForbidPropOn;
@synthesize turnValid = _turnValid;
@synthesize isValid = _isValid;
@synthesize nProp = _nProp;


// iPad与iPhone间棋盘坐标转换函数
+ (float)PadCoorx2Phone:(float)src {
	return ( src - 64 ) / 2;
}

+ (float)PadCoory2Phone:(float)src {
	return ( src - 32 ) / 2; 
}

+ (float)PhoneCoorx2Pad:(float)src {
	return src * 2 + 64; 
}

+ (float)PhoneCoory2Pad:(float)src {
	return src * 2 + 32; 
}

- (b2Body *)addBoxBodyForChessman:(CCSprite *)sprite withRadius:(float)radius
{
	
    b2BodyDef spriteBodyDef;
    // 设定为子弹
    spriteBodyDef.bullet = YES;
    spriteBodyDef.type = b2_dynamicBody;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		spriteBodyDef.position.Set([GameLayer PadCoorx2Phone:sprite.position.x]/PTM_RATIO, 
								   [GameLayer PadCoory2Phone:sprite.position.y]/PTM_RATIO);
	}
	else {
		spriteBodyDef.position.Set(sprite.position.x/PTM_RATIO, 
								   sprite.position.y/PTM_RATIO);
	}

	spriteBodyDef.angle = -1 * sprite.rotation / 180 * b2_pi;
    spriteBodyDef.userData = sprite;
	spriteBodyDef.angularDamping = 2.0f;
	spriteBodyDef.allowSleep = YES;
    b2Body *spriteBody = _world->CreateBody(&spriteBodyDef);
	
	b2CircleShape circle;
	circle.m_radius = radius * sprite.scale / PTM_RATIO;
	
	b2FixtureDef spriteShapeDef;
	spriteShapeDef.shape = &circle;
	spriteShapeDef.density = 10.0f;
	spriteShapeDef.friction = 20.0f;
	spriteShapeDef.restitution = 1.0f;
	spriteBody->CreateFixture(&spriteShapeDef);
	
	return spriteBody;
}

- (b2Fixture *)addBoxBodyForHinge:(CCSprite *)sprite
{
	
    b2BodyDef spriteBodyDef;
    spriteBodyDef.type = b2_staticBody;
    spriteBodyDef.position.Set(sprite.position.x/PTM_RATIO, 
							   sprite.position.y/PTM_RATIO);
    spriteBodyDef.userData = sprite;
	b2Body *spriteBody = _world->CreateBody(&spriteBodyDef);
	
	b2PolygonShape spriteShape;
    spriteShape.SetAsBox(sprite.contentSize.width * sprite.scale /PTM_RATIO/2,
                         sprite.contentSize.height * sprite.scale /PTM_RATIO/2);
	b2FixtureDef spriteShapeDef;
	spriteShapeDef.shape = &spriteShape;
    b2Fixture *tempFixture = spriteBody->CreateFixture(&spriteShapeDef);
	
	return tempFixture;
}

- (void)ContactListenerIssue {
    _contactListener->_isResetImpulseLock = NO;
    if( _contactListener->_vContactChessman.size() != 0 ) {
        std::vector<ChessmanSprite *>::iterator it;
        for( it = _contactListener->_vContactChessman.begin(); it != _contactListener->_vContactChessman.end(); it++ ) {
            [(*it) setIsContactLock:YES];
        }
    }
}

- (void)didChangeTurn {
    // Do Nothing;
}

- (void)confirmChangeTurn {
    // 游戏是否结束
    if([_brain checkGameOver]) {
        [self gameOver];
        return;
    }
    if(!_isFirstTime) {
        if(!_hasSentUpdateData) {
            NSLog(@"has not sent");
            if(!_isSendingUpdateData) {
                NSLog(@"is sending data");
                _isSendingUpdateData = YES;
                [self updateCollisionChessmanData];
            }
            _isValid = NO;
            return;
        }
        // 判断对手是否已经change turn
        if(!_rivalHasChangeTurn) {
            _isValid = NO;
            return;
        }
        NSLog(@"has sent");
        _hasSentUpdateData = NO;
        _isSendingUpdateData = NO;
        _rivalHasChangeTurn = NO;
        [self changePlayer];
    }
    else {
        NSLog(@"it is the first time");
        _isFirstTime = NO;
    }
    [[SimpleAudioEngine sharedEngine] playEffect:@"myturn.wav"];
    _turnValid = YES;
    [self ContactListenerIssue];
    
    if(_brain.currentPlayer == PLAYER1) {
        [_turnMark[0] setVisible:YES];
        [_turnMark[1] setVisible:NO];
    }
    else {
        [_turnMark[0] setVisible:NO];
        [_turnMark[1] setVisible:YES];
    }
}

- (void)confirmChangeTurnTick:(ccTime)dt {
    _isValid = [self checkValid];
    if(!_isValid)
        return;
    [self unschedule:_cmd];
    [self confirmChangeTurn];

}

- (void)checkTurnTick:(ccTime)dt {

	bool temp = _isValid;
	_isValid = [self checkValid];
	if( temp == NO && _isValid == YES )	{
        [self schedule:@selector(confirmChangeTurnTick:) interval:0.05];
	}
}

- (void)updateBoxBody {
    for(b2Body *b = _world->GetBodyList(); b; b = b->GetNext()) 
	{    
        if (b->GetUserData() != nil) 
		{
            CCSprite *ballData = (CCSprite *)b->GetUserData();
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
				ballData.position = ccp([GameLayer PhoneCoorx2Pad:b->GetPosition().x  * PTM_RATIO],
										[GameLayer PhoneCoory2Pad:b->GetPosition().y  * PTM_RATIO]);
			}
			else {
				ballData.position = ccp(b->GetPosition().x * PTM_RATIO,
										b->GetPosition().y * PTM_RATIO);
			}
            ballData.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
        }        
    }
}

- (void)standardProcedure {
    _world->Step(1.0f / 30.0f, 1, 0);
    [self updateBoxBody];
    
}

- (void)stopDestroyChessman {
    [self schedule:@selector(stopDestroyChessmanTick:) interval:0.4];
}

- (void)stopDestroyChessmanTick:(ccTime)dt {
    if([_brain stopDestroyedChessman])
        [self unschedule:_cmd];
}

- (void)tick:(ccTime)dt {
	// 提高性能
	if( _isValid ) {
        return;
	}
    [self standardProcedure];
    [_brain checkDrop];
}

- (float)getLargestPermittedLength:(b2Body *)body withMax:(float)max_length {
    int radius;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        radius = 50;
    }
    else{
        radius = 25;
    }
	float x,y,distance,R,r;
	r = ((CCSprite *)(body->GetUserData())).scale * radius;
	for(b2Body *b = _world->GetBodyList(); b; b=b->GetNext()) 
	{    
        if (b->GetUserData() != nil) 
		{
			if( b == body )
			{
				continue;
			}
			x = ((CCSprite *)(b->GetUserData())).position.x - ((CCSprite *)(body->GetUserData())).position.x; 
			y = ((CCSprite *)(b->GetUserData())).position.y - ((CCSprite *)(body->GetUserData())).position.y;
			R = ((CCSprite *)(b->GetUserData())).scale * radius;
			distance = sqrt(x * x + y * y);
			if( distance < max_length + 2 * R )
			{
				max_length = (r + ( distance - r - R ) / 2 ) ? max_length : ( r + ( distance - r - R ) / 2 ) < max_length;
			}
		}        
    }
	return max_length;
}

- (void)createPropStandardProcedure:(id)pr {
    
    PropSprite *Prop = (PropSprite *)pr;
	[_brain addProp:Prop];
    [self addChild:Prop z:0];
    [_needFadeSprites addObject:Prop];
}

- (void)createPropwithFilename:(NSString*)filename withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type withScore:(int)score withCategory:(int)cat {
    PropSprite *Prop = [PropSprite propWithImageFile:filename withPosition:position withScale:scale withType:type withScore:score withCategory:cat];
    [self createPropStandardProcedure:Prop];
}

- (void)createChessmanStandardProcedure:(id)ch withScale:(float)scale{
    ChessmanSprite *Chessman = (ChessmanSprite *)ch;
    b2Body *body;
    // 分配ID
    static int ID = 0;
	if( ID >= 32 ) {
		ID = 0;	
	}
	Chessman.ID = ID;
	ID++;
    
    // 绑定body
	body = [self addBoxBodyForChessman:Chessman withRadius:26.0f];
    // 设定质量为统一值
	b2MassData massData;
	body->GetMassData( &massData );
	massData.mass = 3.0f;
	body->SetMassData( &massData);
    
	if( scale == SMALL_SIZE ) {
		body->SetLinearDamping( 1.0f );
		Chessman.value = 2;
	}
	else if( scale == LARGE_SIZE ) {
		body->SetLinearDamping( 4.0f );
		Chessman.value = 8;
	}
	else if( scale == MEDIUM_SIZE )	{
		body->SetLinearDamping( 2.5f );
		Chessman.value = 4;
	}
	
	Chessman.body = body;
    [_needFadeSprites addObject:Chessman];
    [_needFadeSprites addObject:Chessman.Image];
    [self addChild:Chessman z:99];
    [self addChild:Chessman.Gunsight z:100];
    [_brain addChessman:Chessman withID:Chessman.ID];
}

- (void)createChessmanwithFilename:(NSString*)filename withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type
{
    ChessmanSprite *Chessman;
	if( type == 1 )
	{
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			Chessman = [ChessmanSprite chessmanWithImageFile:@"Green-ipad.png" withFilename:filename withPosition:position withScale:scale withType:type];
		}
		else {
			Chessman = [ChessmanSprite chessmanWithImageFile:@"Green.png" withFilename:filename withPosition:position withScale:scale withType:type];
		}
	}
	else
	{
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			Chessman = [ChessmanSprite chessmanWithImageFile:@"Red-ipad.png" withFilename:filename withPosition:position withScale:scale withType:type];
		}
		else {
			Chessman = [ChessmanSprite chessmanWithImageFile:@"Red.png" withFilename:filename withPosition:position withScale:scale withType:type];
		}
	}
    [self createChessmanStandardProcedure:Chessman withScale:scale];
}

- (void)destroyBody:(b2Body *)body {
    _world->DestroyBody(body);
}

- (void)shutDownExplosion {
    for(CCParticleSystem *expl in _explosions) {
        [expl stopSystem];
        [self removeChild:expl cleanup:YES];
    }
    [_explosions removeAllObjects];

}

- (bool)changePlayerStandardProcedure {
    [self shutDownExplosion];
	[_brain destroyChessmanBody];
    [_brain removeEmitter];
    if(_isForbidPropOn) {
		[self shutDownForbid];
		return NO;
	}
    [self didChangeTurn];
    return YES;
}

- (bool)changePlayer
{
    bool result = [self changePlayerStandardProcedure];
    if(result) {
        [_brain changePlayer];
    }
    return result;
}


- (void)draw
{
    if(_isFadingOut)
        return;
    [_brain drawCDRect];
    [self drawTrunMark];
	
}

- (void)drawTrunMark {
    static int opacity = 0;
	static bool flag = NO;
	if( flag )
	{
		opacity -= 15;
	}
	else
	{
		opacity += 15;
	}
	if( opacity <= 0 )
	{
		flag = NO;
	}
	if( opacity >= 255 )
	{
		flag = YES;
	}	
	if( _brain.currentPlayer == 0 )
	{
        if([_turnMark[0] visible]) {
            [_turnMark[0] setOpacity:opacity];
        }
	}
	else
	{
        if([_turnMark[1] visible]) {
            [_turnMark[1] setOpacity:opacity];
        }
	}
}

- (void)gameLayerInit {
    NSLog(@"game layer init"); 
    _isFirstTime = YES;
    _hasSentUpdateData = NO;
    _isSendingUpdateData = NO;
    _rivalHasChangeTurn = NO;
    _turnValid = NO;
    _isValid = NO;
    _isForbidPropOn = NO;
}

- (id)init
{
	self = [super init];
	if (self)
	{		
		// enable touches
		self.isTouchEnabled = YES;
		// disable accelerometer
		self.isAccelerometerEnabled = NO;
		
		b2Vec2 gravity = b2Vec2(0.0f, 0.0f);
		bool doSleep = YES;
		_world = new b2World(gravity, doSleep);
		
		//Create contact listener
		_contactListener = new MyContactListener();
		_world->SetContactListener(_contactListener);
        
        std::vector<ChessmanSprite *>::iterator it;
        for( it = _contactListener->_vContactChessman.begin(); it != _contactListener->_vContactChessman.end(); it++ ) {
            [(*it) setIsContactLock:NO];
		}
		_isValid = NO;
        _needFadeSprites = [[NSMutableArray alloc] init];
        _explosions = [[NSMutableArray alloc] init];
        _brain = [[Brain alloc] init];
        [_brain setHostLayer:self];
        _nProp = -1;
        [self load];
        NSLog(@"init : game layer init");
        [self gameLayerInit];
	}
	return self;
}

- (void)startTick {
    [self schedule:@selector(tick:) interval:1.0f / 100.0f];
    [self schedule:@selector(checkTurnTick:) interval:0.5f];
}

- (void)stopTick {
    [self unscheduleAllSelectors];
}

- (void)restartWithMusic:(bool)playMusic{
    if(playMusic) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"start.wav"];
    }
    [self startTick];
    _isValid = NO;
}

- (void)repositionOriginProcedure {
    NSLog(@"repositionOriginProcedure : game layer init");
    [self gameLayerInit];
    [self stopTick];
    [_brain repositionStandardPorcedure];
    [_brain repositionAnimation];
    [self schedule:@selector(repositionTick:) interval:1];
}

- (void)reposition {
    [self repositionOriginProcedure];
}


- (void)repositionTick:(ccTime)dt {
    [self unschedule:_cmd];
    [_brain repositionExtraProcedure];
    [self restartWithMusic:YES];
}

- (void)setPauseButtonType:(PauseButton *)button {
    [button set_type:0];
}

- (void)load
{
	CGSize screenSize = [CCDirector sharedDirector].winSize;
	CCLOG(@"Screen width %0.2f screen height %0.2f",screenSize.width,screenSize.height);
	
	CCSprite *chessboard;
    CCSprite *chessboardcover;
	//Chessboard
    int CHESSBOARD_LATTICE_WIDTH;
    int CHESSBOARD_LATTICE_HEIGHT;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		
		chessboard = [CCSprite spriteWithFile:@"ChessBoard-ipad.png"];
        chessboardcover = [CCSprite spriteWithFile:@"ChessBoardCover-ipad.png"];
		CHESSBOARD_LATTICE_WIDTH = 60;
		CHESSBOARD_LATTICE_HEIGHT = 80;
	}
	else {
		chessboard = [CCSprite spriteWithFile:@"ChessBoard6.png"];
        chessboardcover = [CCSprite spriteWithFile:@"ChessBoardCover.png"];
        CHESSBOARD_LATTICE_WIDTH = 30;
		CHESSBOARD_LATTICE_HEIGHT = 40;
	}
    chessboard.anchorPoint = ccp( 0.5, 0.5 );
    chessboardcover.anchorPoint = ccp( 0.5, 0.5 );
	chessboard.position = ccp( screenSize.width/2, screenSize.height/2 );
    chessboardcover.position = ccp( screenSize.width/2, screenSize.height/2 );
	[self addChild:chessboard z:1 tag:405];
    [self addChild:chessboardcover z:1 tag:406];
    [_needFadeSprites addObject:chessboard];
	//Hinge	
	CCSprite *hingeA = [CCSprite spriteWithFile:@"Hinge4.png"];
	CCSprite *hingeB = [CCSprite spriteWithFile:@"Hinge4.png"];
	int hinge_interval = 75;
	hingeA.anchorPoint = ccp( 0.5, 0.5 );
	hingeA.position = ccp( 160 - hinge_interval, 240 );
	[self addChild:hingeA z:1 tag:2];
    FixtureA = [self addBoxBodyForHinge:hingeA];
	
	hingeB.anchorPoint = ccp( 0.5, 0.5 );
	hingeB.position = ccp( 160 + hinge_interval, 240 );
	[self addChild:hingeB z:1 tag:3];
    FixtureB = [self addBoxBodyForHinge:hingeB];
	_contactListener->SetHingeFixture(FixtureA, FixtureB);
	[_needFadeSprites addObject:hingeA];
    [_needFadeSprites addObject:hingeB];
	
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad){
		// Group1
		[self createChessmanwithFilename:@"David's Deer.png" withPosition:ccp(screenSize.width / 2,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 3.5) withScale:LARGE_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Crutch.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:SMALL_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Crutch.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:SMALL_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Hat.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Hat.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Sock.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Sock.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Hat.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Hat.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Bell.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 2.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Bell.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH  * 3,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 2.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Snow.png" withPosition:ccp(screenSize.width / 2,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Snow.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Snow.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Snow.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Snow.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP1];
		// Group2
        [self createChessmanwithFilename:@"Horse.png" withPosition:ccp(screenSize.width / 2,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 3.5) withScale:LARGE_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Crutch.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:SMALL_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Crutch.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:SMALL_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Leaf.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Leaf.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Present.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Present.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Leaf.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Leaf.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Cookie Man.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 2.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Cookie Man.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 2.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Snow.png" withPosition:ccp(screenSize.width / 2,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Snow.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Snow.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Snow.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Snow.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP2];
        
		//Props
		[self createPropwithFilename:@"PowerUp.png" withPosition:ccp(55,25) withScale:0.85 withType:GROUP1 withScore:POWERUP_NEED_SCORE withCategory:1];
		[self createPropwithFilename:@"Forbid.png" withPosition:ccp(125,25) withScale:0.85 withType:GROUP1 withScore:FORBID_NEED_SCORE withCategory:2];
		[self createPropwithFilename:@"Enlarge.png" withPosition:ccp(195,25) withScale:0.85 withType:GROUP1 withScore:ENLARGE_NEED_SCORE withCategory:3];
		[self createPropwithFilename:@"Change.png" withPosition:ccp(265,25) withScale:0.85 withType:GROUP1 withScore:CHANGE_NEED_SCORE withCategory:4];
		[self createPropwithFilename:@"PowerUp.png" withPosition:ccp(265,455) withScale:0.85 withType:GROUP2 withScore:POWERUP_NEED_SCORE withCategory:1];
		[self createPropwithFilename:@"Forbid.png" withPosition:ccp(195,455) withScale:0.85 withType:GROUP2 withScore:FORBID_NEED_SCORE withCategory:2];
		[self createPropwithFilename:@"Enlarge.png" withPosition:ccp(125,455) withScale:0.85 withType:GROUP2 withScore:ENLARGE_NEED_SCORE withCategory:3];
		[self createPropwithFilename:@"Change.png" withPosition:ccp(55,455) withScale:0.85 withType:GROUP2 withScore:CHANGE_NEED_SCORE withCategory:4];
		
		_PropShow[0] = [CCSprite spriteWithFile:@"PowerUp-show.png"];
		_PropShow[0].position = ccp( 160, 240 );
		_PropShow[0].opacity = 0;
		[self addChild:_PropShow[0] z:100];
		_PropShow[1] = [CCSprite spriteWithFile:@"Forbid-show.png"];
		_PropShow[1].position = ccp( 160, 240 );
		_PropShow[1].opacity = 0;
		[self addChild:_PropShow[1] z:100];
		_PropShow[2] = [CCSprite spriteWithFile:@"Enlarge-show.png"];
		_PropShow[2].position = ccp( 160, 240 );
		_PropShow[2].opacity = 0;
		[self addChild:_PropShow[2] z:100];
		_PropShow[3] = [CCSprite spriteWithFile:@"Change-show.png"];
		_PropShow[3].position = ccp( 160, 240 );
		_PropShow[3].opacity = 0;
		[self addChild:_PropShow[3] z:100];
		
		
		_turnMark[0] = [CCSprite spriteWithFile:@"TurnMark.png"];
		[_turnMark[0] setVisible:NO];
		[_turnMark[0] setPosition:ccp( 160,57 )];
		[self addChild:_turnMark[0] z:0];
		_turnMark[1] = [CCSprite spriteWithFile:@"TurnMark.png"];
		[_turnMark[1] setVisible:NO];
		[_turnMark[1] setPosition:ccp( 160,423 )];
		[self addChild:_turnMark[1] z:0];
		
		PauseButton *button = [PauseButton spriteWithFile:@"Pause.png"];
		[self setPauseButtonType:button];
		button.position = ccp( 305, 18 );
		[self addChild:button z:2 tag:101];
        [_needFadeSprites addObject:button];
	}
	else {
        // Group1
		[self createChessmanwithFilename:@"David's Deer-ipad.png" withPosition:ccp(screenSize.width / 2,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 3.5) withScale:LARGE_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Crutch-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:SMALL_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Crutch-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:SMALL_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Hat-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Hat-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Sock-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Sock-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Hat-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Hat-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Bell-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 2.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Bell-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH  * 3,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 2.5) withScale:MEDIUM_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Snow-ipad.png" withPosition:ccp(screenSize.width / 2,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Snow-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Snow-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Snow-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP1];
		[self createChessmanwithFilename:@"Snow-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 - CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP1];
        // Group2
        [self createChessmanwithFilename:@"Horse-ipad.png" withPosition:ccp(screenSize.width / 2,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 3.5) withScale:LARGE_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Crutch-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:SMALL_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Crutch-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:SMALL_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Leaf-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Leaf-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Present-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Present-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Leaf-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Leaf-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 4.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Cookie Man-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 2.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Cookie Man-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 3,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 2.5) withScale:MEDIUM_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Snow-ipad.png" withPosition:ccp(screenSize.width / 2,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Snow-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Snow-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 2,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Snow-ipad.png" withPosition:ccp(screenSize.width / 2 + CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP2];
		[self createChessmanwithFilename:@"Snow-ipad.png" withPosition:ccp(screenSize.width / 2 - CHESSBOARD_LATTICE_WIDTH * 4,screenSize.height / 2 + CHESSBOARD_LATTICE_HEIGHT * 1.5) withScale:SMALL_SIZE withType:GROUP2];
		
		//Props
		[self createPropwithFilename:@"PowerUp-ipad.png" withPosition:ccp(screenSize.width/2 - 105 * 2,screenSize.height/2 - 215 * 2) withScale:0.85 withType:GROUP1 withScore:POWERUP_NEED_SCORE withCategory:1];
		[self createPropwithFilename:@"Forbid-ipad.png" withPosition:ccp(screenSize.width/2 - 35 * 2,screenSize.height/2 - 215 * 2) withScale:0.85 withType:GROUP1 withScore:FORBID_NEED_SCORE withCategory:2];
		[self createPropwithFilename:@"Enlarge-ipad.png" withPosition:ccp(screenSize.width/2 + 35 * 2,screenSize.height/2 - 215 * 2) withScale:0.85 withType:GROUP1 withScore:ENLARGE_NEED_SCORE withCategory:3];
		[self createPropwithFilename:@"Change-ipad.png" withPosition:ccp(screenSize.width/2 + 105 * 2,screenSize.height/2 - 215 * 2) withScale:0.85 withType:GROUP1 withScore:CHANGE_NEED_SCORE withCategory:4];
		[self createPropwithFilename:@"PowerUp-ipad.png" withPosition:ccp(screenSize.width/2 + 105 * 2,screenSize.height/2 + 215 * 2) withScale:0.85 withType:GROUP2 withScore:POWERUP_NEED_SCORE withCategory:1];
		[self createPropwithFilename:@"Forbid-ipad.png" withPosition:ccp(screenSize.width/2 + 35 * 2,screenSize.height/2 + 215 * 2) withScale:0.85 withType:GROUP2 withScore:FORBID_NEED_SCORE withCategory:2];
		[self createPropwithFilename:@"Enlarge-ipad.png" withPosition:ccp(screenSize.width/2 - 35 * 2,screenSize.height/2 + 215 * 2) withScale:0.85 withType:GROUP2 withScore:ENLARGE_NEED_SCORE withCategory:3];
		[self createPropwithFilename:@"Change-ipad.png" withPosition:ccp(screenSize.width/2 - 105 * 2,screenSize.height/2 + 215 * 2) withScale:0.85 withType:GROUP2 withScore:CHANGE_NEED_SCORE withCategory:4];
		
		_PropShow[0] = [CCSprite spriteWithFile:@"PowerUp-show-ipad.png"];
		_PropShow[0].position = ccp( screenSize.width/2, screenSize.height/2 );
		_PropShow[0].opacity = 0;
		[self addChild:_PropShow[0] z:100];
		_PropShow[1] = [CCSprite spriteWithFile:@"Forbid-show-ipad.png"];
		_PropShow[1].position = ccp( screenSize.width/2, screenSize.height/2 );
		_PropShow[1].opacity = 0;
		[self addChild:_PropShow[1] z:100];
		_PropShow[2] = [CCSprite spriteWithFile:@"Enlarge-show-ipad.png"];
		_PropShow[2].position = ccp( screenSize.width/2, screenSize.height/2 );
		_PropShow[2].opacity = 0;
		[self addChild:_PropShow[2] z:100];
		_PropShow[3] = [CCSprite spriteWithFile:@"Change-show-ipad.png"];
		_PropShow[3].position = ccp( screenSize.width/2, screenSize.height/2 );
		_PropShow[3].opacity = 0;
		[self addChild:_PropShow[3] z:100];
		
		_turnMark[0] = [CCSprite spriteWithFile:@"TurnMark-ipad.png"];
		[_turnMark[0] setVisible:NO];
		[_turnMark[0] setPosition:ccp( screenSize.width/2, screenSize.height/2 - 183 * 2 )];
		[self addChild:_turnMark[0] z:0];
		_turnMark[1] = [CCSprite spriteWithFile:@"TurnMark-ipad.png"];
		[_turnMark[1] setVisible:NO];
		[_turnMark[1] setPosition:ccp( screenSize.width/2, screenSize.height/2 + 183 * 2 )];
		[self addChild:_turnMark[1] z:0];
		
		PauseButton *button = [PauseButton spriteWithFile:@"Pause-ipad.png"];
		[self setPauseButtonType:button];
		button.position = ccp( screenSize.width - 50, 50 );
		[self addChild:button z:2 tag:101];
        [_needFadeSprites addObject:button];
	}
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _GameOverShow[0] = [CCSprite spriteWithFile:@"GameOver-ipad.png" rect:CGRectMake(0, 0, 400, 400)];
        _GameOverShow[1] = [CCSprite spriteWithFile:@"GameOver-ipad.png" rect:CGRectMake(400, 0, 400, 400)];
        _GameOverShow[2] = [CCSprite spriteWithFile:@"GameOver-ipad.png" rect:CGRectMake(0, 400, 400, 400)];
        _GameOverShow[3] = [CCSprite spriteWithFile:@"GameOver-ipad.png" rect:CGRectMake(400, 400, 400, 400)];
        _GameOverShow[4] = [CCSprite spriteWithFile:@"GameOver-ipad.png" rect:CGRectMake(0, 800, 400, 400)];
        _Star[0] = [CCSprite spriteWithFile:@"Star-ipad.png" rect:CGRectMake(0, 0, 400, 400)];
        _Star[1] = [CCSprite spriteWithFile:@"Star-ipad.png" rect:CGRectMake(400, 0, 400, 400)];
        
    }
    else {
        _GameOverShow[0] = [CCSprite spriteWithFile:@"GameOver.png" rect:CGRectMake(0, 0, 200, 200)];
        _GameOverShow[1] = [CCSprite spriteWithFile:@"GameOver.png" rect:CGRectMake(200, 0, 200, 200)];
        _GameOverShow[2] = [CCSprite spriteWithFile:@"GameOver.png" rect:CGRectMake(0, 200, 200, 200)];
        _GameOverShow[3] = [CCSprite spriteWithFile:@"GameOver.png" rect:CGRectMake(200, 200, 200, 200)];
        _GameOverShow[4] = [CCSprite spriteWithFile:@"GameOver.png" rect:CGRectMake(0, 400, 200, 200)];
        _Star[0] = [CCSprite spriteWithFile:@"Star.png" rect:CGRectMake(0, 0, 200, 200)];
        _Star[1] = [CCSprite spriteWithFile:@"Star.png" rect:CGRectMake(200, 0, 200, 200)];
        
    }
    for(int i = 0; i < 5; i++) {
        _GameOverShow[i].anchorPoint = ccp(0.5, 0.5);
        _GameOverShow[i].position = ccp(screenSize.width / 2,screenSize.height / 2);
        _GameOverShow[i].visible = NO;
        [self addChild:_GameOverShow[i] z:199];
        
    }
    for(int i = 0; i < 2; i++) {
        _Star[i].anchorPoint = ccp(0.5, 0.5);
        _Star[i].position = ccp(screenSize.width / 2,screenSize.height / 2);
        _Star[i].visible = NO;
        [self addChild:_Star[i] z:199];
    }
}

- (void)updateCollisionChessmanData{
    _hasSentUpdateData = YES;
    _rivalHasChangeTurn = YES;
}

//检查棋子是否停下和删除出局棋子
- (bool)checkValid {
    return [_brain checkValid];
}

//Prop

- (void)Proptick:(ccTime)dt
{
	if(_brain.currentPlayer == PLAYER2) {
		_PropShow[_nProp].rotation = 180;
	}
	else {
		_PropShow[_nProp].rotation = 0;
	}
	if( _nProp == -1 ) {
		return;
	}
	static bool flag = 0;
	if( flag == 0 )
	{
		_PropShow[_nProp].opacity += 51;
		if( _PropShow[_nProp].opacity >= 255 )
		{
			_PropShow[_nProp].opacity -= 51;
			static ccTime time = 0;
			time += dt;
			if( time >= 1 )
			{
				flag = 1;
				time = 0;
				_PropShow[_nProp].opacity = 255;
			}
		}
	}
	else
	{
		_PropShow[_nProp].opacity -= 17;
		if( _PropShow[_nProp].opacity <= 0 )
		{
			flag = 0;
			_nProp = -1;
			[self unschedule:_cmd];
		}
	}
    
}

- (void)turnOnPowerUpStandardProcedure {
    [_brain turnOnPowerUp];
    _nProp = 0;
    [self schedule:@selector(Proptick:)];
}

- (void)turnOnPowerUp {
	[self turnOnPowerUpStandardProcedure];
}


- (void)shutDownPowerUp {
	[_brain shutDownPowerUp];
}

- (void)turnOnForbidStandardProcedure {
    _isForbidPropOn = YES;
	_nProp = 1;
	[self schedule:@selector(Proptick:)];
}

- (void)turnOnForbid
{
	[self turnOnForbidStandardProcedure];
}

- (void)shutDownForbid
{
	_isForbidPropOn = NO;
    [_brain shutDownForbid];
}

- (void)turnOnEnlargeStandardProcedure {
    [_brain turnOnEnlarge];
	_nProp = 2;
	[self schedule:@selector(Proptick:)];
}

- (void)turnOnEnlarge
{
	[self turnOnEnlargeStandardProcedure];
}

- (void)shutDownEnlarge
{
    [_brain shutDownEnlarge];
}

- (bool)testEnlargePropValid {
    return [_brain testEnlargePropValid];
}

- (void)ChessmanEnlargeFixTick:(ccTime)dt {
    static ccTime time = 0;
    time += dt;
    _world->Step(1.0f / 30.0f, 10, 10);
    [self updateBoxBody];
    if(time >= 0.2) {
        [self unschedule:_cmd];
        time = 0;
        [self shutDownEnlarge];
    }
}

- (void)spriteEnlarge:(id)sender 
{
    ChessmanSprite* sprite = (ChessmanSprite*)sender;
	//float pre_rotation = sprite.rotation;
	b2Body* spriteBody = sprite.body;
	
    if (spriteBody != nil) 
	{
        b2Body *spriteBody = sprite.body;
		_world->DestroyBody(spriteBody);
    }
	
	b2Body* body = [self addBoxBodyForChessman:sprite withRadius:26.0f];
	b2MassData massData;
	body->GetMassData( &massData );
	massData.mass = 3.0f;
	body->SetMassData( &massData);
	if( sprite.scale == LARGE_SIZE )
	{
		body->SetLinearDamping( 4.0f );
		sprite.value = 8;
	}
	else if( sprite.scale == MEDIUM_SIZE )
	{
		body->SetLinearDamping( 2.5f );
		sprite.value = 4;
	}
	sprite.body = body;
    
    [self schedule:@selector(ChessmanEnlargeFixTick:) interval:0.01];
}

- (void)spriteDiminish:(id)sender 
{
	
    ChessmanSprite* sprite = (ChessmanSprite*)sender;
	//float pre_rotation = sprite.rotation;
	b2Body* spriteBody = sprite.body;
	
    if (spriteBody != nil) 
	{
        b2Body *spriteBody = sprite.body;
		_world->DestroyBody(spriteBody);
    }
    
    sprite.scale = sprite.initScale;
	
	b2Body* body = [self addBoxBodyForChessman:sprite withRadius:26.0f];
	b2MassData massData;
	body->GetMassData( &massData );
	massData.mass = 3.0f;
	body->SetMassData( &massData);
    if( sprite.scale == MEDIUM_SIZE )
	{
		body->SetLinearDamping( 2.5f );
		sprite.value = 4;
	}
    else if( sprite.scale == SMALL_SIZE )
	{
		body->SetLinearDamping( 1.0f );
		sprite.value = 2;
	}
	sprite.body = body;
}

- (void)turnOnChangeStandardProcedure {
    [_brain turnOnChange];
	_nProp = 3;
	[self schedule:@selector(Proptick:)];

}

- (void)turnOnChange {
    [self turnOnChangeStandardProcedure];
}

- (void)shutDownChange
{
	[_brain shutDownChange];
}

- (void)spriteChange:(id)sender 
{
	ChessmanSprite* sprite = (ChessmanSprite*)sender;
	if(_brain.currentPlayer == PLAYER2) {
		//NSLog(@"Red Betray");
        if(sprite.type == GROUP1) {
            if(sprite.NewBackColor == nil) {
                sprite.opacity = 0;
                CCSprite *BackColor;
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
                    BackColor = [CCSprite spriteWithFile:@"Green-ipad.png"];
                }
                else {
                    BackColor = [CCSprite spriteWithFile:@"Green.png"];
                }
                sprite.NewBackColor = BackColor;
                BackColor.anchorPoint = ccp(0, 0);
                BackColor.position = ccp(0, 0);
                [sprite addChild:BackColor z:0];
                sprite.isBetray = YES;
            }
            else {
                sprite.opacity = 255;
                [sprite removeChild:sprite.NewBackColor cleanup:YES];
                sprite.NewBackColor = nil;
                sprite.isBetray = NO;
            }
            sprite.isChange = NO;
            sprite.isForbad = NO;
            sprite.type = GROUP2;
            _brain.Player1Lives--;
            _brain.Player2Lives++;
        }
    }
    else {
        //NSLog(@"Green Betray");
        if(sprite.type == GROUP2) {
            if(sprite.NewBackColor == nil) {
                sprite.opacity = 0;
                CCSprite *BackColor;
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
                    BackColor = [CCSprite spriteWithFile:@"Red-ipad.png"];
                }
                else {
                    BackColor = [CCSprite spriteWithFile:@"Red.png"];
                }
                sprite.NewBackColor = BackColor;
                BackColor.anchorPoint = ccp( 0, 0 );
                BackColor.position = ccp( 0, 0 );
                [sprite addChild:BackColor z:0];
                sprite.isBetray = YES;
            }
            else {
                sprite.opacity = 255;
                [sprite removeChild:sprite.NewBackColor cleanup:YES];
                sprite.NewBackColor = nil;
                sprite.isBetray = NO;
            }
            sprite.isChange = NO;
            sprite.isForbad = NO;
            sprite.type = GROUP1;
            _brain.Player1Lives++;
            _brain.Player2Lives--;
        }
    }
    if([_brain checkGameOver]) {
        [self gameOver];
    }
}

- (void)clearScore:(int)score
{
    [_brain clearScore:score];
}

- (void)playGameOverMusic {
    [[SimpleAudioEngine sharedEngine] playEffect:@"win.wav"];
}

- (void)gameOver
{
    _isGameOverShow = YES;
    [_brain removeEmitter];
    [self playGameOverMusic];
    [self stopTick];
    [self schedule:@selector(gameOverTick:) interval:0.03];
}

//- (void)newGame {
//    [self gameLayerInit];
//    [_brain repositionStandardPorcedure];
//    [_brain repositionExtraProcedure];
//}

- (void)setPicNum:(int *)mainPicNum withStar:(int *)starPicNum {
    if ([_brain player1Win]) {
        *mainPicNum = 0;
        *starPicNum = 0;
    }
    else if([_brain player2Win]){
        *mainPicNum = 1;
        *starPicNum = 1;
    }
    else{
        *mainPicNum = 4;
    }
}

- (void)gotoSysMenu {
    [self fadeOut];
}

- (void)gameOverTick:(ccTime)dt {
	static ccTime time = 0;
    int game_over_pic_num = -1;
    int star_pic_num = -1;
    
    [self setPicNum:&game_over_pic_num withStar:&star_pic_num];
    
	if( time == 0 )
	{
		_GameOverShow[game_over_pic_num].visible = YES;
        _GameOverShow[game_over_pic_num].opacity = 255;
        if( star_pic_num != -1 )
        {
            _Star[star_pic_num].visible = YES;
            _Star[star_pic_num].opacity = 255;
        }
	}
	static float angularSpeed = 10;
    static float scale = 0.1;
    if( star_pic_num != -1 ){
        _Star[star_pic_num].rotation += angularSpeed;
        _Star[star_pic_num].scale = scale;
    }
    
    _GameOverShow[game_over_pic_num].scale = scale;
    
	angularSpeed -= 0.15;
    scale *= 1.2; 
	if( angularSpeed < 0 )
	{
		angularSpeed = 0;
	}
    if (scale > 1) {
        scale = 1;
    }
	time += dt;
	if (time >= 4) {
        [self gotoSysMenu];
        [self unschedule:_cmd];
        [_GameOverShow[game_over_pic_num] runAction:[CCFadeOut actionWithDuration:0.3]];
        if( star_pic_num != -1 )
        {
            [_Star[star_pic_num] runAction:[CCFadeOut actionWithDuration:0.3]];
        }
        _isGameOverShow = NO;
		time = 0;
		angularSpeed = 10;
        scale = 0.1;
	}	
}

- (bool)isGameOverShowing {
    return _isGameOverShow;
}

- (void)showExplosion:(CGPoint)aPoint withScale:(float)scale {
    CCParticleSystem *emitter = [[CCParticleExplosion alloc] initWithTotalParticles:20 * scale * scale];
    [self addChild:emitter z:100 tag:155];
    emitter.position = aPoint;
    emitter.posVar = ccp(3, 3);
	emitter.speed = 80 * scale;
	emitter.speedVar = 10 * scale; //喷发速度变化范围
	emitter.startSize = 10 * scale;
	emitter.startSizeVar = 5;
	emitter.endSize = 1;
	emitter.endSizeVar = 1;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		emitter.speed *= 2;
		emitter.speedVar *= 2; //喷发速度变化范围
		emitter.startSize *= 2;
		emitter.startSizeVar *= 2;
		emitter.endSize *= 2;
		emitter.endSizeVar *= 2;
	}
	emitter.life = 1;
	emitter.lifeVar = 0;

    ccColor4F startColor = {0.8f, 0.6f, 0.3f, 0.6f};
    ccColor4F colorVar = {0.0f, 0.0f, 0.0f, 0.0f};
	ccColor4F endColor = {0.2f, 0.4f, 0.7f, 0.0f};
    
    emitter.startColor = startColor;
    emitter.startColorVar = colorVar;
	emitter.endColor = endColor;
    emitter.endColorVar = colorVar;
    [emitter release];
    [_explosions addObject:emitter];
    _isExplosionShow = YES;
    
}

- (void)fadeInTick:(ccTime)dt {
    [self unschedule:_cmd];
    [self restartWithMusic:YES];
}

- (void)fadeInStandardProcedure {
    [_brain setPropFading];
    for(CCSprite *sprite in _needFadeSprites) {
        sprite.opacity = 0;
        [sprite runAction:[CCFadeIn actionWithDuration:0.3]];
    }
}

- (void)fadeIn {
    _isFadingOut = NO;
    [self fadeInStandardProcedure];
    [self schedule:@selector(fadeInTick:) interval:1.0];
}

- (void)fadeOutTick:(ccTime)dt {
    [self unscheduleAllSelectors];
    for (int i = 0; i < 5; i++) {
        [_GameOverShow[i] setVisible:NO];
    }
    for (int i = 0; i < 2; i++) {
        [_Star[i] setVisible:NO];
    }
    [[CCDirector sharedDirector] setDeviceOrientation:CCDeviceOrientationPortrait];
    [[CCDirector sharedDirector] replaceScene:[LoadingScene sceneWithTargetScene:[SysScene sharedScene]]];
}

- (void)fadeOutStandardProcedure {
    [_turnMark[0] setVisible:NO];
    [_turnMark[1] setVisible:NO];
    for(CCSprite *sprite in _needFadeSprites) {
        if([sprite isKindOfClass:[ChessmanSprite class]]) {
            ChessmanSprite *chessman = (ChessmanSprite *)sprite;
            if(chessman.isBetray && chessman.NewBackColor.opacity != 0) {
                [chessman.NewBackColor runAction:[CCFadeOut actionWithDuration:0.3]];
                continue;
            }
        }
        if(sprite.opacity == 0) continue;
        [sprite runAction:[CCFadeOut actionWithDuration:0.3]];
    }
}

- (void)fadeOut {
    [self stopTick];
    [self fadeOutStandardProcedure];
    _isFadingOut = YES;
    [self schedule:@selector(fadeOutTick:) interval:0.4];
}

- (void)addUpdateChessman:(ChessmanSprite *)aChessman {
    
//    if(aChessman.isMoving == NO) {
//        _brain.movingChessmanCount++;
//        //NSLog(@"+ %d ID: %d",_brain.movingChessmanCount, aChessman.ID);
//    }
//    aChessman.isMoving = YES;
}

- (void)setCurrentChessman:(ChessmanSprite *)sprite {
    _brain.currentChessman = sprite;
}

- (void)shutDownEmitter {
    [_brain shutDownCurrentChessmanEmitter];
}

- (void)checkChessmanSelectedWhenAppEnterBackground {
    [_brain checkChessmanSelected];
}

- (void)dealloc
{
    [_needFadeSprites release];
    [_explosions release];
    [_brain release];
	delete _world;
    _world = nil;
	delete _contactListener;
	_contactListener = nil;
    [super dealloc];
}

@end

