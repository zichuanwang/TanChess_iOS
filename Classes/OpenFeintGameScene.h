//
//  OpenFeintGameScene.h
//  Tan Chess HD
//
//  Created by Bluebitch on 11-5-23.
//  Copyright 2011年 TJU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "OpenFeintGameLayer.h"
#import "BackgroundLayer.h"

@interface OpenFeintGameScene : CCScene {
    
}

+ (OpenFeintGameScene*)sharedScene;

+ (BackgroundLayer*)backgroundLayer;

+ (OpenFeintGameLayer*)gameLayer;

+ (void)clearInstance;

@end
