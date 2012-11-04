//
//  GameScene.m
//  Tan Chess HD
//
//  Created by Bluebitch on 11-3-13.
//  Copyright 2011年 TJU. All rights reserved.
//

#import "GameScene.h"

typedef enum {
    BackgroundLayerTag,
    GameLayerTag,
}GameSceneTags;


@implementation GameScene

static GameScene* gameSceneInstance = nil;

+ (GameScene*)sharedScene {
    if ( gameSceneInstance == nil ) {
        NSLog(@"New Game Scene Created");
        gameSceneInstance = [[GameScene alloc] init];
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
        GameLayer *gLayer = [GameLayer node];
        [self addChild:gLayer z:1 tag:GameLayerTag];
        BackgroundLayer *bLayer = [BackgroundLayer node];
        [self addChild:bLayer z:0 tag:BackgroundLayerTag];
    }   
    return self;
}

+ (BackgroundLayer*)backgroundLayer {
    return (BackgroundLayer*)[gameSceneInstance getChildByTag:BackgroundLayerTag];
}

+ (GameLayer*)gameLayer {    
    return (GameLayer*)[gameSceneInstance getChildByTag:GameLayerTag];
}

- (void)dealloc {
    //NSLog(@"game scene dealloc");
    [super dealloc];
}

@end
