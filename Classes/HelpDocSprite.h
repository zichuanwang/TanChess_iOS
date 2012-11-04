//
//  HelpDocSprite.h
//  Tan Chess
//
//  Created by Blue Bitch on 11-1-31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface HelpDocSprite : CCSprite<CCTargetedTouchDelegate>
{
	CGPoint startTouchPosition;
    bool isDragging;
    float lasty;
	float yvel;
	int contentHeight, maxInterval;
    bool isMovingToUpBound, isMovingToBottomBound;
}

@end
