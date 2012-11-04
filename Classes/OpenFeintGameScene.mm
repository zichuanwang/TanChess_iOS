//
//  OpenFeintGameScene.m
//  Tan Chess HD
//
//  Created by Bluebitch on 11-5-23.
//  Copyright 2011年 TJU. All rights reserved.
//

#import "OpenFeintGameScene.h"

typedef enum {
    BackgroundLayerTag,
    GameLayerTag,
}OpenFeintGameSceneTags;

@implementation OpenFeintGameScene

static OpenFeintGameScene *gameSceneInstance = nil;

+ (OpenFeintGameScene *)sharedScene {
    if ( gameSceneInstance == nil ) {
        gameSceneInstance = [[OpenFeintGameScene alloc] init];
    }
    return gameSceneInstance;
}

+ (void)clearInstance {
    [gameSceneInstance release];
    gameSceneInstance = nil;
}

- (id)init {
    if ((self = [super init])) {
        gameSceneInstance = self;
        OpenFeintGameLayer *gLayer = [OpenFeintGameLayer node];
        [self addChild:gLayer z:1 tag:GameLayerTag];
        BackgroundLayer *bLayer = [BackgroundLayer node];
        [self addChild:bLayer z:0 tag:BackgroundLayerTag];
    }   
    return self;
}

+ (BackgroundLayer*)backgroundLayer {
    return (BackgroundLayer*)[gameSceneInstance getChildByTag:BackgroundLayerTag];
}

+ (OpenFeintGameLayer*)gameLayer {    
    return (OpenFeintGameLayer*)[gameSceneInstance getChildByTag:GameLayerTag];
}

- (void)dealloc {
    [super dealloc];
}

@end
