//
//  SysScene.m
//  Tan Chess HD
//
//  Created by Bluebitch on 11-4-19.
//  Copyright 2011年 TJU. All rights reserved.
//

#import "HelpScene.h"
#import "BackgroundLayer.h"

typedef enum {
    HelpLayerTag,
}HelpSceneTags;

@implementation HelpScene

static HelpScene * helpSceneInstance = nil;

+ (HelpScene *)sharedScene {
    if ( helpSceneInstance == nil ) {
        helpSceneInstance = [[HelpScene alloc] init];
    }
    return helpSceneInstance;
}

+ (void)clearInstance {
    [helpSceneInstance release];
    helpSceneInstance = nil;
}

- (id)init {
    if ((self = [super init])) {
        helpSceneInstance = self;
        HelpLayer *hLayer = [HelpLayer node];
        [self addChild:hLayer z:1 tag:HelpLayerTag];
        BackgroundLayer *bLayer = [BackgroundLayer node];
        [self addChild:bLayer z:0];
    }   
    return self;
}

+ (HelpLayer *)helpLayer {    
    return (HelpLayer *)[helpSceneInstance getChildByTag:HelpLayerTag];
}

- (void)dealloc {
    //NSLog(@"game scene dealloc");
    [super dealloc];
}

@end
