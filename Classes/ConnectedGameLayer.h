//
//  ConnectedGameLayer.h
//  Tan Chess
//
//  Created by Blue Bitch on 11-2-3.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Box2D.h"
#import "GameLayer.h"
#import "ConnectedChessmanSprite.h"

@interface ConnectedGameLayer : GameLayer {
    int _nCollisionNum;
    bool _isUpdating;
    bool _isWaitingForPlayer;
}

@property bool isUpdating;
@property bool isWaitingForPlayer;

- (void)setChessmanImpulse:(b2Vec2)impulse withID:(int)ID;

- (bool)setCollisionPosition:(CGPoint)point withID:(int)ID;

- (void)setHost:(BOOL)isHost;

- (void)setChessmanSelected:(int)ID;

- (void)setChessmanEnlarged:(int)ID;

- (void)setChessmanChanged:(int)ID;

- (void)propShowWithNum:(int)num;

- (bool)isInCharge;

- (void)resetPauseButtonPos;

- (void)gotoSysMenuConfirmed;

- (void)rotationTransfer;

- (void)setUpdateTimer;

- (void)setNoDifferentCollision;

- (void)setRivalHasChangeTurn:(bool)isChange;


@end
