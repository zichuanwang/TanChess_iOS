//
//  GameControlLayer.h
//  Tan Chess
//
//  Created by Blue Bitch on 10-12-26.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "PropSprite.h"

@interface GameControlLayer : CCLayer<CCTargetedTouchDelegate>
{
	CCSprite *_image;
	
	int _type;
}

@property (nonatomic,readwrite,assign) int _type;

- (void)fadeIn;

@end
