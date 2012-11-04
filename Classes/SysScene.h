//
//  SysScene.h
//  Tan Chess HD
//
//  Created by Bluebitch on 11-4-19.
//  Copyright 2011年 TJU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "SysMenu.h"



@interface SysScene : CCScene {
    
}

+ (SysScene *)sharedScene;

+ (SysMenu *)sysMenu;

+ (void)clearInstance;

@end
