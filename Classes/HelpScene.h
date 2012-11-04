//
//  SysScene.h
//  Tan Chess HD
//
//  Created by Bluebitch on 11-4-19.
//  Copyright 2011年 TJU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "HelpLayer.h"


@interface HelpScene : CCScene {
    
}

+ (HelpScene *)sharedScene;

+ (HelpLayer *)helpLayer;

+ (void)clearInstance;

@end