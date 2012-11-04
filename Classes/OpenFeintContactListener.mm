/*
 *  MyContactListener.cpp
 *  Tan Chess
 *
 *  Created by Blue Bitch on 10-12-6.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#import "OpenFeintContactListener.h"
#import "OpenFeintGameScene.h"


//添加碰撞单体
void OpenFeintContactListener::addUpdateChessman(b2Contact* contact) {
    id userData = nil;
    userData = (id)contact->GetFixtureA()->GetBody()->GetUserData();
    if( [userData isMemberOfClass:[ConnectedChessmanSprite class]] ) {
        [[OpenFeintGameScene gameLayer] addUpdateChessman:userData];
    }
    userData = (id)contact->GetFixtureB()->GetBody()->GetUserData();
    if( [userData isKindOfClass:[ConnectedChessmanSprite class]] ) {
        [[OpenFeintGameScene gameLayer] addUpdateChessman:userData];
    }
}

void OpenFeintContactListener::resetImpulsePlugin( b2Body *bodyA, b2Body *bodyB ) {
    OpenFeintChessmanSprite *userData = nil;
    userData = (OpenFeintChessmanSprite *)bodyA->GetUserData();
    [[OpenFeintGameScene gameLayer] addUpdateChessman:userData];
    userData = (OpenFeintChessmanSprite *)bodyB->GetUserData();
    [[OpenFeintGameScene gameLayer] addUpdateChessman:userData];
}

void OpenFeintContactListener::showExplosion(CGPoint pos, float scale) {
    [[OpenFeintGameScene gameLayer] showExplosion:pos withScale:scale];
}
