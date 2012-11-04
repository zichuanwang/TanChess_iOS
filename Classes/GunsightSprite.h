//
//  GunsightSprite.h
//  Cocos2DSimpleGame
//
//  Created by Blue Bitch on 10-11-28.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GunsightSprite : CCSprite 
{	
	CCSprite *_PowerUpMode;
}

@property (nonatomic,readwrite,assign) CCSprite *_PowerUpMode;

+ (id)createGunsight;

@end
