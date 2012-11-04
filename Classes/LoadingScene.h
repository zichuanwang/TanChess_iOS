//
//  LoadingScene.h
//  Tan Chess HD
//
//  Created by Bluebitch on 11-4-19.
//  Copyright 2011年 TJU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface LoadingScene : CCScene {
    id targetScene_;
}

+ (id)sceneWithTargetScene:(id)targetScene;

- (id)initWithTargetScene:(id)targetScene;

@end