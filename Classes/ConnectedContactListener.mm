/*
 *  MyContactListener.cpp
 *  Tan Chess
 *
 *  Created by Blue Bitch on 10-12-6.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#import "ConnectedContactListener.h"
#import "ConnectedGameScene.h"


//添加碰撞单体
void ConnectedContactListener::addUpdateChessman(b2Contact* contact) {
    id userData = nil;
    userData = (id)contact->GetFixtureA()->GetBody()->GetUserData();
    if( [userData isMemberOfClass:[ConnectedChessmanSprite class]] ) {
        [[ConnectedGameScene gameLayer] addUpdateChessman:userData];
    }
    userData = (id)contact->GetFixtureB()->GetBody()->GetUserData();
    if( [userData isKindOfClass:[ConnectedChessmanSprite class]] ) {
        [[ConnectedGameScene gameLayer] addUpdateChessman:userData];
    }
}

void ConnectedContactListener::resetImpulsePlugin( b2Body *bodyA, b2Body *bodyB ) {
    ConnectedChessmanSprite *userData = nil;
    userData = (ConnectedChessmanSprite *)bodyA->GetUserData();
    [[ConnectedGameScene gameLayer] addUpdateChessman:userData];
    userData = (ConnectedChessmanSprite *)bodyB->GetUserData();
    [[ConnectedGameScene gameLayer] addUpdateChessman:userData];
}

void ConnectedContactListener::showExplosion(CGPoint pos, float scale) {
    [[ConnectedGameScene gameLayer] showExplosion:pos withScale:scale];
}
