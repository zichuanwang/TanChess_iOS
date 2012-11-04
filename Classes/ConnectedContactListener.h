/*
 *  MyContactListener.h
 *  Tan Chess
 *
 *  Created by Blue Bitch on 10-12-6.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */
#import "MyContactListener.h"

class ConnectedContactListener : public MyContactListener 
{	
public:
	virtual void resetImpulsePlugin(b2Body *bodyA,b2Body *bodyB );
    virtual void showExplosion(CGPoint pos, float scale);
    virtual void addUpdateChessman(b2Contact* contact);
};

