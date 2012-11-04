//
//  HelpLayer.m
//  Tan Chess
//
//  Created by Blue Bitch on 11-1-31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HelpLayer.h"
#import "SysScene.h"
#import "LoadingScene.h"

typedef enum {
    BackgroundSpriteTag,
    HelpDocSpriteTag,
}HelpLayerTags; 

@implementation HelpLayer

- (id)init
{
	self = [super init];
	if (self)
	{
		CGSize screenSize = [CCDirector sharedDirector].winSize;
		//Background
		CCSprite *helpDoc;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			helpDoc = [HelpDocSprite spriteWithFile:@"HelpDoc-ipad.png"];
		}
		else {
			helpDoc = [HelpDocSprite spriteWithFile:@"HelpDoc.png"];
		}

		helpDoc.anchorPoint = ccp( 0.5, 0.5 );
		helpDoc.position = ccp( screenSize.width / 2, 0 );
		[self addChild:helpDoc z:1 tag:HelpDocSpriteTag];
	}
	return self;
}

- (void)fadeIn {
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    CCArray *children = [self children];
    for(CCSprite *sprite in children) {
        if(sprite == [self getChildByTag:HelpDocSpriteTag]) {
            sprite.position = ccp( screenSize.width / 2, 0 );
            CCArray *subChildren = [sprite children];
            for(CCSprite *subSprite in subChildren) {
                subSprite.opacity = 255;
            }
        }
        sprite.opacity = 0;
        [sprite runAction:[CCFadeIn actionWithDuration:0.3]];
    }
}

- (void)fadeOutTick:(ccTime)dt {
    [self unscheduleAllSelectors];
    [[CCDirector sharedDirector] replaceScene:[LoadingScene sceneWithTargetScene:[SysScene sharedScene]]];
}

- (void)fadeOut {
    CCArray *children = [self children];
    for(CCSprite *sprite in children) {
        if(sprite == [self getChildByTag:HelpDocSpriteTag]) {
            CCArray *subChildren = [sprite children];
            for(CCSprite *subSprite in subChildren) {
                [subSprite runAction:[CCFadeOut actionWithDuration:0.3]];
            }
        }
        [sprite runAction:[CCFadeOut actionWithDuration:0.3]];
    }
    [self schedule:@selector(fadeOutTick:) interval:0.4];
}

- (void) dealloc
{
    [super dealloc];
}


@end
