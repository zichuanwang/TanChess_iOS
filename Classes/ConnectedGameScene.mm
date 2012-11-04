//
//  GameScene.m
//  Tan Chess HD
//
//  Created by Bluebitch on 11-3-13.
//  Copyright 2011年 TJU. All rights reserved.
//

#import "ConnectedGameScene.h"

typedef enum {
    BackgroundLayerTag,
    GameLayerTag,
    BluetoothConnectLayerTag
}ConnectedGameSceneTags;

@implementation ConnectedGameScene

static ConnectedGameScene* gameSceneInstance = nil;

+ (ConnectedGameScene*)sharedScene {
    if ( gameSceneInstance == nil ) {
        gameSceneInstance = [[ConnectedGameScene alloc] init];
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
        ConnectedGameLayer *gLayer = [ConnectedGameLayer node];
        [self addChild:gLayer z:1 tag:GameLayerTag];
        BackgroundLayer *bLayer = [BackgroundLayer node];
        [self addChild:bLayer z:0 tag:BackgroundLayerTag];
        BluetoothConnectLayer *bcLayer = [BluetoothConnectLayer node];
        [self addChild:bcLayer z:2 tag:BluetoothConnectLayerTag];
    }   
    return self;
}

+ (BackgroundLayer*)backgroundLayer {
    return (BackgroundLayer*)[gameSceneInstance getChildByTag:BackgroundLayerTag];
}

+ (BluetoothConnectLayer*)bluetoothConnectLayer {
    return (BluetoothConnectLayer*)[gameSceneInstance getChildByTag:BluetoothConnectLayerTag];
}

+ (ConnectedGameLayer*)gameLayer {    
    return (ConnectedGameLayer*)[gameSceneInstance getChildByTag:GameLayerTag];
}

- (void)dealloc {
    [super dealloc];
}

@end
