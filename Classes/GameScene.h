//
//  GameScene.h
//  Tan Chess HD
//
//  Created by Bluebitch on 11-3-13.
//  Copyright 2011年 TJU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameLayer.h"
#import "BackgroundLayer.h"


@interface GameScene : CCScene {
   
}

+ (GameScene*)sharedScene;

+ (BackgroundLayer*)backgroundLayer;

+ (GameLayer*)gameLayer;

+ (void)clearInstance;

@end
