//
//  LoadingScene.m
//  Tan Chess HD
//
//  Created by Bluebitch on 11-4-19.
//  Copyright 2011年 TJU. All rights reserved.
//

#import "LoadingScene.h"
#import "GameScene.h"
#import "ConnectedGameScene.h"
#import "OpenFeintGameScene.h"
#import "HelpScene.h"
#import "SysScene.h"
#import "OFMultiplayerService.h"


@implementation LoadingScene

+ (id)sceneWithTargetScene:(id)targetScene
{
    CCScene *currentScene = [[CCDirector sharedDirector] runningScene];
    if([currentScene isMemberOfClass:[SysScene class]]) {
        NSLog(@"I'm a sys scene");
        [SysScene clearInstance];
    }
    else if([currentScene isMemberOfClass:[GameScene class]]) {
        NSLog(@"I'm a game scene");
        [GameScene clearInstance];
    }
    else if([currentScene isMemberOfClass:[ConnectedGameScene class]]) {
        NSLog(@"I'm a connect scene");
        [ConnectedGameScene clearInstance];
    }
    else if([currentScene isMemberOfClass:[OpenFeintGameScene class]]) {
        NSLog(@"I'm a openfeint scene");
        bool isLogin = [OpenFeintGameScene gameLayer].isLogin;
        [OpenFeintGameScene clearInstance];
        [OpenFeintGameScene sharedScene];
        [OFMultiplayerService setDelegate:[OpenFeintGameScene gameLayer]];
        [OpenFeintGameScene gameLayer].isLogin = isLogin;
    }
    else if([currentScene isMemberOfClass:[HelpScene class]]) {
        NSLog(@"I'm a help scene");
        [HelpScene clearInstance];
    }
    
    return[[[self alloc] initWithTargetScene:targetScene] autorelease];
}

- (void)updateTick:(ccTime)delta
{
    [self unschedule:_cmd];
    if ([targetScene_ isMemberOfClass:[GameScene class]]) {
        //[[GameScene gameLayer] newGame];
        [[GameScene gameLayer] fadeIn];
    }
    else if([targetScene_ isMemberOfClass:[ConnectedGameScene class]]) {
        //[[ConnectedGameScene gameLayer] newGame];
        [[ConnectedGameScene gameLayer] fadeIn];
    }
    else if([targetScene_ isMemberOfClass:[OpenFeintGameScene class]]) {
        //[[OpenFeintGameScene gameLayer] newGame];
        [[OpenFeintGameScene gameLayer] fadeIn];
    }
    else if([targetScene_ isMemberOfClass:[HelpScene class]]) {
        [[HelpScene helpLayer] fadeIn];
    }
    else if([targetScene_ isMemberOfClass:[SysScene class]]) {
        [[SysScene sysMenu] fadeIn];
    }
    [[CCDirector sharedDirector] replaceScene:targetScene_];
}

- (id)initWithTargetScene:(id)targetScene
{
    if ((self = [super init])) {
        
        targetScene_ = targetScene;
        BackgroundLayer *bLayer = [BackgroundLayer node];
        [self addChild:bLayer];
        [self schedule:@selector(updateTick:) interval:0.05];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}
@end
