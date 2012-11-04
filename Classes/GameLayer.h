//
//  GameLayer.h
//  Cocos2DSimpleGame
//
//  Created by Blue Bitch on 10-11-19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "MyContactListener.h"
#import "Brain.h"

#define PTM_RATIO 32

@interface GameLayer : CCLayer
{
    Brain *_brain;
    
    // box2d stuff
	b2World *_world;
	MyContactListener *_contactListener;
	
    //cocoas2D stuff
	CCSprite *_GameOverShow[5];
	CCSprite *_Star[2];
    CCSprite *_turnMark[2];
	CCSprite *_PropShow[4];
    int _nProp;
    
    bool _isValid;      //当前棋子是否都静止 且满足各种要求
    bool _isForbidPropOn; //禁手道具是否开启
    bool _turnValid;    //允许下一轮进行
    
    NSMutableArray *_needFadeSprites;
    NSMutableArray *_explosions;
    bool _isGameOverShow;
    bool _isExplosionShow;
    bool _isFadingOut;
    bool _isFirstTime;
    bool _hasSentUpdateData;
    bool _isSendingUpdateData;
    bool _rivalHasChangeTurn;
    
    b2Fixture *FixtureA, *FixtureB; 
}

@property (nonatomic,readwrite,assign) bool turnValid;
@property (nonatomic,readwrite,assign) bool isValid;
@property (nonatomic,readwrite,assign) bool isForbidPropOn;
@property (nonatomic,readwrite,assign) int nProp;

+ (float)PadCoorx2Phone:(float)src;
+ (float)PadCoory2Phone:(float)src;
+ (float)PhoneCoorx2Pad:(float)src;
+ (float)PhoneCoory2Pad:(float)src;

- (void)destroyBody:(b2Body *)body;
//检查棋子是否停下和删除出局棋子
- (bool)checkValid;
//取得最大优化距离
- (float)getLargestPermittedLength:(b2Body *)body withMax:(float)max_length;

- (b2Body *)addBoxBodyForChessman:(CCSprite *)sprite withRadius:(float)radius;

- (bool)changePlayerStandardProcedure;

- (void)turnOnPowerUp;
- (void)turnOnPowerUpStandardProcedure;
- (void)shutDownPowerUp;
- (void)turnOnForbid;
- (void)turnOnForbidStandardProcedure;
- (void)shutDownForbid;
- (void)turnOnEnlarge;
- (void)turnOnEnlargeStandardProcedure;
- (void)shutDownEnlarge;
- (void)turnOnChange;
- (void)turnOnChangeStandardProcedure;
- (void)shutDownChange;

- (void)spriteEnlarge:(id)sender;

- (void)spriteDiminish:(id)sender;

- (void)spriteChange:(id)sender;

- (void)clearScore:(int)score;

- (void)playGameOverMusic;

- (void)restartWithMusic:(bool)playMusic;

- (void)reposition;

- (void)repositionOriginProcedure;

- (void)createPropStandardProcedure:(id)pr;

- (void)createChessmanStandardProcedure:(id)ch withScale:(float)scale;

//- (void)newGame;

- (void)ContactListenerIssue;

- (void)checkTurnTick:(ccTime)dt;

- (void)tick:(ccTime)dt;

- (bool)isGameOverShowing;

- (bool)testEnlargePropValid;

- (void)gotoSysMenu;

- (void)showExplosion:(CGPoint)aPoint withScale:(float)scale;

- (void)fadeIn;

- (void)fadeOut;

- (void)addUpdateChessman:(ChessmanSprite *)aChessman;

- (void)fadeOutStandardProcedure;

- (void)fadeInStandardProcedure;

- (void)shutDownExplosion;

- (void)shutDownEmitter;

- (void)stopDestroyChessman;

- (void)setCurrentChessman:(ChessmanSprite *)sprite;

- (void)checkChessmanSelectedWhenAppEnterBackground;

- (void)fadeOutTick:(ccTime)dt;

@end
