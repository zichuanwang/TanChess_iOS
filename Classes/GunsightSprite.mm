//
//  GunsightSprite.m
//  Cocos2DSimpleGame
//
//  Created by Blue Bitch on 10-11-28.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GunsightSprite.h"
#import "GameScene.h"

@implementation GunsightSprite

@synthesize _PowerUpMode;

+ (id)createGunsight
{	
    GunsightSprite *sprite;
    CCSprite *PUmode;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        sprite = [GunsightSprite spriteWithFile:@"GunSight2-ipad.png" rect:CGRectMake(0, 0, 180, 200)];
        PUmode = [CCSprite spriteWithFile:@"GunSight2-ipad.png" rect:CGRectMake(180, 0, 180, 200)];
    }
    else {
        sprite = [GunsightSprite spriteWithFile:@"GunSight2.png" rect:CGRectMake(0, 0, 90, 100)];
        PUmode = [CCSprite spriteWithFile:@"GunSight2.png" rect:CGRectMake(90, 0, 90, 100)];
    }
	PUmode.anchorPoint = CGPointZero;
	PUmode.position = CGPointZero;
	sprite._PowerUpMode = PUmode;
	[sprite addChild:PUmode];
	PUmode.opacity = 0;
	[sprite setVisible:NO];
	
	return sprite;
}


// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end
