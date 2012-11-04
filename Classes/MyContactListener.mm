/*
 *  MyContactListener.cpp
 *  Tan Chess
 *
 *  Created by Blue Bitch on 10-12-6.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#import "MyContactListener.h"
#import "cocos2d.h"
#import "GameScene.h"

void MyContactListener::SetHingeFixture(  b2Fixture *fixtureA,  b2Fixture *fixtureB )
{
	_hingeFixtureA = fixtureA;
	_hingeFixtureB = fixtureB;
}

void MyContactListener::BeginContact(b2Contact* contact) 
{
    _bodyAMove = NO;
    _bodyBMove = NO;
    if( contact->GetFixtureA() != _hingeFixtureA && contact->GetFixtureA() != _hingeFixtureB )
	{
        [[SimpleAudioEngine sharedEngine] playEffect:@"hitstone.wav"];
        _vContactChessman.push_back( (ChessmanSprite *)contact->GetFixtureA()->GetBody()->GetUserData() );
        _vContactChessman.push_back( (ChessmanSprite *)contact->GetFixtureB()->GetBody()->GetUserData() );
        b2Body *body = contact->GetFixtureB()->GetBody();
        b2Vec2 impulse_vec = body->GetLinearVelocity();
        if( impulse_vec.x != 0 || impulse_vec.y != 0 ) {
            _bodyBMove = YES;
            _waitingPos = contact->GetFixtureB()->GetBody()->GetPosition();
        }
        float b_vel = impulse_vec.x * impulse_vec.x + impulse_vec.y * impulse_vec.y;
        CGPoint b_pos = [(CCSprite *)body->GetUserData() position];
        body = contact->GetFixtureA()->GetBody();
        impulse_vec = body->GetLinearVelocity();
        if( impulse_vec.x != 0 || impulse_vec.y != 0 ) {
            _bodyAMove = YES;
            _waitingPos = contact->GetFixtureA()->GetBody()->GetPosition();
        }
        float a_vel = impulse_vec.x * impulse_vec.x + impulse_vec.y * impulse_vec.y;
        CGPoint a_pos = [(CCSprite *)body->GetUserData() position];
        //NSLog(@"a:%f, b:%f",a, b);
        float scale = 1.0f;
        if(a_vel == 0 && b_vel > 100) {
            scale += (b_vel - 100) / 1000;
            showExplosion(a_pos, scale);
        }
        else if(b_vel == 0 && a_vel > 100) {
            scale += (a_vel - 100) / 1000;
            showExplosion(b_pos, scale);
        }
    }
	else
	{
        [[SimpleAudioEngine sharedEngine] playEffect:@"hithinge.wav"];
	}
    addUpdateChessman(contact);
}

void MyContactListener::EndContact(b2Contact* contact)
{
    addUpdateChessman(contact);
    // 解决边缘穿越问题咯～～
    // FixtureB对应穿越物体
    b2Body *body;
    b2Vec2 impulse_vec;
    if( contact->GetFixtureA() != _hingeFixtureA && contact->GetFixtureA() != _hingeFixtureB )
	{
        _vContactChessman.erase(find(_vContactChessman.begin(),_vContactChessman.end(), (ChessmanSprite *)contact->GetFixtureA()->GetBody()->GetUserData()));
        _vContactChessman.erase(find(_vContactChessman.begin(),_vContactChessman.end(), (ChessmanSprite *)contact->GetFixtureB()->GetBody()->GetUserData()));
        //NSLog( @"Erase:%d", [(ChessmanSprite *)contact->GetFixtureA()->GetBody()->GetUserData() _ID] );
        //NSLog( @"Erase:%d", [(ChessmanSprite *)contact->GetFixtureB()->GetBody()->GetUserData() _ID] );
        if (_bodyAMove) {
            body = contact->GetFixtureB()->GetBody();
            impulse_vec = body->GetLinearVelocity();
            if ( impulse_vec.x == 0 && impulse_vec.y == 0 ) {
                if( _isResetImpulseLock == NO ) {
                    NSLog( @"Here" );
                    resetImpulse( contact->GetFixtureA()->GetBody(), contact->GetFixtureB()->GetBody() );
                }
            }
        }
        else if(_bodyBMove){
            body = contact->GetFixtureA()->GetBody();
            impulse_vec = body->GetLinearVelocity();
            if( impulse_vec.x == 0 && impulse_vec.y == 0 ) {
                if( _isResetImpulseLock == NO ) {
                    NSLog( @"Here2" );
                    resetImpulse( contact->GetFixtureB()->GetBody(), contact->GetFixtureA()->GetBody() );
                }
            }
        }
        else {
            NSLog( @"I'm Here" );
        }
        SetContactUnlock( contact );
	}
    body = contact->GetFixtureA()->GetBody();
    impulse_vec = body->GetLinearVelocity();
	body->SetLinearVelocity(0.85f * impulse_vec);
	body = contact->GetFixtureB()->GetBody();
	impulse_vec = body->GetLinearVelocity();
	body->SetLinearVelocity(0.85f * impulse_vec);
    _isResetImpulseLock = YES;
}

void MyContactListener::PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
{

}

void MyContactListener::PostSolve(b2Contact* contact, const b2ContactImpulse* impulse)
{
	
}

void MyContactListener::SetContactUnlock( b2Contact* contact ) {
    [(ChessmanSprite *)contact->GetFixtureA()->GetBody()->GetUserData() setIsContactLock:NO];
    [(ChessmanSprite *)contact->GetFixtureB()->GetBody()->GetUserData() setIsContactLock:NO];
}

void MyContactListener::resetImpulse( b2Body *bodyA, b2Body *bodyB )
{
    //NSLog( @"Here" );
    resetImpulsePlugin(bodyA, bodyB);
    if( [(ChessmanSprite *)bodyA->GetUserData() isContactLock] ) {
        NSLog( @"Lock1" );
        _isResetImpulseLock = YES;
        [(ChessmanSprite *)bodyA->GetUserData() setIsContactLock:NO];
        [(ChessmanSprite *)bodyB->GetUserData() setIsContactLock:NO];
        return;
    }
    if( [(ChessmanSprite *)bodyB->GetUserData() isContactLock] ) {
        NSLog( @"Lock2" );
        _isResetImpulseLock = YES;
        [(ChessmanSprite *)bodyA->GetUserData() setIsContactLock:NO];
        [(ChessmanSprite *)bodyB->GetUserData() setIsContactLock:NO];
        return;
    }
    
    float r = [(ChessmanSprite *)bodyA->GetUserData() scale] * 26 / 32;
    float R = [(ChessmanSprite *)bodyB->GetUserData() scale] * 26 / 32;
    
    b2Body *body = bodyA;
	b2Vec2 impulse_vec = body->GetLinearVelocity();
    
    b2Vec2 FixtureAPos = _waitingPos;
    //FixtureAPos.x -=  - impulse_vec.x / fabsf( impulse_vec.x ) * R;
    //FixtureAPos.y -=  - impulse_vec.y / fabsf( impulse_vec.y ) * R;
    b2Vec2 FixtureBPos = bodyB->GetPosition();
    
    float angle = acosf( r / ( R + r ) );
    
    //float k1 = impulse_vec.y / impulse_vec.x;
    
    
    b2Vec2 newImpulse;
    float direction;
    if( impulse_vec.x != 0 ) {
        float tan = impulse_vec.y / impulse_vec.x ;
        direction = atanf( fabsf( tan ) );
    }
    else {
        direction = b2_pi / 2;
    }
    
    //NSLog(@"x:%f, y:%f,dir:%f",impulse_vec.x, impulse_vec.y,direction);
    if( direction > b2_pi / 4 ) {
        if( FixtureBPos.x - FixtureAPos.x < 0 ) {
            angle *= -1.0;
            //NSLog( @"FixtureBPos.x - FixtureAPos.x < 0" );
        }
        if( impulse_vec.y < 0 ) {
            angle *= -1.0;
            //NSLog( @"impulse_vec.y < 0" );
        }
    }
    else {
        if( FixtureBPos.y - FixtureAPos.y < 0 ) {
            angle *= -1.0;
            //NSLog( @"FixtureBPos.y - FixtureAPos.y < 0" );
        }
        if( impulse_vec.x > 0 ) {
            angle *= -1.0;
            //NSLog( @"impulse_vec.x > 0" );
        }
    }
    //NSLog( @"angle: %f", angle );
    newImpulse.x = impulse_vec.x * cosf( angle ) + impulse_vec.y * sinf( angle );
    newImpulse.y = impulse_vec.x * sinf( angle ) * ( -1 ) + impulse_vec.y * cosf( angle );
    //NSLog( @"new impulse x: %f, y: %f",newImpulse.x, newImpulse.y  );

    //float k2 = ( FixtureAPos.y - FixtureBPos.y ) / ( FixtureAPos.x - FixtureBPos.x );  
    //float angle = atan(abs( (k1 - k2) / (1 + k1 * k2) ));
    // 两直线夹角 θ = arctan|(k1-k2)/(1+k1k2)|
    //b2Vec2 FixtureAImpulse = b2Vec2( 0, 0 );
    //b2Vec2 FixtureBImpulse = b2Vec2( 0, 0 );
    bodyB->SetLinearVelocity( newImpulse );
    bodyB->ApplyAngularImpulse( 3 );
    bodyA->SetLinearVelocity( 0.6 * impulse_vec );
    //NSLog( @"Caught:%f, %f",newImpulse.x, newImpulse.y  );
    //contact->GetFixtureB()->GetBody()->SetAngularVelocity();
    //contact->GetFixtureB()->GetBody()->SetLinearVelocity(FixtureBImpulse);
}

void MyContactListener::resetImpulsePlugin( b2Body *bodyA, b2Body *bodyB )
{
    ChessmanSprite *userData = nil;
    userData = (ChessmanSprite *)bodyA->GetUserData();
    [[GameScene gameLayer] addUpdateChessman:userData];
    userData = (ChessmanSprite *)bodyB->GetUserData();
    [[GameScene gameLayer] addUpdateChessman:userData];
}

void MyContactListener::showExplosion(CGPoint pos, float scale) {
    [[GameScene gameLayer] showExplosion:pos withScale:scale];
}

void MyContactListener::addUpdateChessman(b2Contact* contact) 
{
    //添加碰撞单体
    id userData = nil;
    userData = (id)contact->GetFixtureA()->GetBody()->GetUserData();
    if( [userData isMemberOfClass:[ChessmanSprite class]] )
    {
        [[GameScene gameLayer] addUpdateChessman:userData];
    }
    userData = (id)contact->GetFixtureB()->GetBody()->GetUserData();
    if( [userData isMemberOfClass:[ChessmanSprite class]] )
    {
        [[GameScene gameLayer] addUpdateChessman:userData];
    }
}
