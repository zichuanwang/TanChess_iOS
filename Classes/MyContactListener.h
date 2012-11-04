/*
 *  MyContactListener.h
 *  Tan Chess
 *
 *  Created by Blue Bitch on 10-12-6.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */
#import "Box2D.h"
#import <vector>
#import <algorithm>
#import "SimpleAudioEngine.h"
#import "ChessmanSprite.h"

struct MyContact
{
    b2Fixture *fixtureA;
    b2Fixture *fixtureB;
    bool operator == (const MyContact& other) const
    {
        return (fixtureA == other.fixtureA) && (fixtureB == other.fixtureB);
    }
};

class MyContactListener : public b2ContactListener 
{
protected:
	b2Fixture *_hingeFixtureA;
    b2Fixture *_hingeFixtureB;
    bool _bodyAMove;
    bool _bodyBMove;
    b2Vec2 _waitingPos;
    
protected:
    void resetImpulse( b2Body *bodyA, b2Body *bodyB );
    void SetContactLock( b2Contact* contact );
    void SetContactUnlock( b2Contact* contact );
    
public:
	//std::vector<MyContact>_contacts;
	void SetHingeFixture(b2Fixture *fixtureA,  b2Fixture *fixtureB);
    virtual void BeginContact(b2Contact* contact);
    virtual void EndContact(b2Contact* contact);
    virtual void PreSolve(b2Contact* contact, const b2Manifold* oldManifold);    
    virtual void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse);
    virtual void resetImpulsePlugin(b2Body *bodyA, b2Body *bodyB);    
    virtual void showExplosion(CGPoint pos, float scale);
    virtual void addUpdateChessman(b2Contact* contact);
public:
    bool _isResetImpulseLock;
    std::vector<ChessmanSprite *> _vContactChessman;
};

