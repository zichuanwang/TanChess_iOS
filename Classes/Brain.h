//
//  Brain.h
//  Tan Chess HD
//
//  Created by Bluebitch on 11-5-17.
//  Copyright 2011年 TJU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "ChessmanSprite.h"
#import "PropSprite.h"

#define GROUP1 0
#define GROUP2 1
#define PLAYER1 0
#define PLAYER2 1

@interface Brain : NSObject {
    
    int _Player1Score;
	int _Player2Score;
	int _Player1Lives;
	int _Player2Lives;
    
    //int _movingChessmanCount; //当前移动的棋子数目
    bool _currentPlayer;
    
    NSMutableDictionary *_chessmans;
    NSMutableArray *_props;
    NSMutableArray *_toDestroy;
    
    ChessmanSprite *_currentChessman;
    id _hostLayer;
}

//@property int movingChessmanCount;
@property int Player1Lives, Player2Lives;
@property (nonatomic, readonly, assign) bool currentPlayer;
@property (nonatomic, readwrite, assign) ChessmanSprite *currentChessman;

- (void)addChessman:(ChessmanSprite *)sprite withID:(int)ID;

- (void)addProp:(PropSprite *)sprite;

- (void)update;

- (void)checkDrop;

- (bool)checkGameOver;

- (void)setHostLayer:(id)hostLayer;

- (void)removeEmitter;

- (bool)stopDestroyedChessman;

- (void)destroyChessmanBody;

- (void)changePlayer;

- (void)changePlayerWhenConnecting;

- (void)drawCDRect;

- (void)repositionAnimation;

- (void)repositionStandardPorcedure;

- (void)repositionExtraProcedure;

- (bool)checkValid;

- (void)turnOnPowerUp;
- (void)shutDownPowerUp;
- (void)shutDownForbid;
- (void)turnOnEnlarge;
- (void)shutDownEnlarge;
- (void)turnOnChange;
- (void)shutDownChange;

- (bool)testEnlargePropValid;

- (void)clearScore:(int)score;

- (bool)player1Win;

- (bool)player2Win;

- (void)setPropFading;

- (bool)setCollisionPosition:(CGPoint)point withID:(int)ID;

- (void)setConnectedChessmanImpulse:(b2Vec2)impulse withID:(int)ID;

- (void)setOpenFeintChessmanImpulse:(b2Vec2)impulse withID:(int)ID;

- (void)setPlayer1Forbad;

- (void)setConnectedChessmanSelected:(int)ID;

- (void)setConnectedChessmanEnlarged:(int)ID;

- (void)setConnectedChessmanChanged:(int)ID;

- (void)setOpenFeintChessmanSelected:(int)ID;

- (void)setOpenFeintChessmanEnlarged:(int)ID;

- (void)setOpenFeintChessmanChanged:(int)ID;

- (void)sendCollisionDataViaBluetooth;

- (void)sendCollisionDataViaOpenFeint;

- (void)shutDownCurrentChessmanEmitter;

- (void)checkChessmanSelected;

@end
