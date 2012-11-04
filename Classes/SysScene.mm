//
//  SysScene.m
//  Tan Chess HD
//
//  Created by Bluebitch on 11-4-19.
//  Copyright 2011年 TJU. All rights reserved.
//

#import "SysScene.h"
#import "BackgroundLayer.h"

typedef enum {
    SysMenuLayerTag,
}SysSceneTags;

@implementation SysScene

static SysScene *sysSceneInstance = nil;

+ (SysScene *)sharedScene {
    if ( sysSceneInstance == nil ) {
        NSLog(@"New Sys Scene created");
        sysSceneInstance = [[SysScene alloc] init];
    }
    return sysSceneInstance;
}

+ (void)clearInstance {
    [sysSceneInstance release];
    sysSceneInstance = nil;
}

- (id)init {
    if ((self = [super init])) {
        sysSceneInstance = self;
        SysMenu *sLayer = [SysMenu node];
        [self addChild:sLayer z:1 tag:SysMenuLayerTag];
        BackgroundLayer *bLayer = [BackgroundLayer node];
        [self addChild:bLayer z:0];
    }   
    return self;
}

+ (SysMenu *)sysMenu {    
    return (SysMenu *)[sysSceneInstance getChildByTag:SysMenuLayerTag];
}

- (void)dealloc {
    NSLog(@"SysScene dealloc");
    [super dealloc];
}

@end
