//
//  BackgroundLayer.m
//  Tan Chess
//
//  Created by Blue Bitch on 11-1-30.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BackgroundLayer.h"


@implementation BackgroundLayer

- (id)init
{
	self = [super init];
	if (self)
	{
		CGSize screenSize = [CCDirector sharedDirector].winSize;
		//Background
		CCSprite *background;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			background = [CCSprite spriteWithFile:@"Background-ipad.png"];
		}
		else {
			background = [CCSprite spriteWithFile:@"Background.png"];
		}

		background.anchorPoint = ccp( 0.5, 0.5 );
		background.position = ccp( screenSize.width/2, screenSize.height/2 );
		[self addChild:background z:0 tag:0];
	}
	return self;
}

- (void)rotateBackground:(int) angle {
    [self getChildByTag:0].rotation = angle;
}

- (void) dealloc
{
    [super dealloc];
}

@end
