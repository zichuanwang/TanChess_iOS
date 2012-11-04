//
//  GameScene.h
//  Tan Chess HD
//
//  Created by Bluebitch on 11-3-13.
//  Copyright 2011年 TJU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "ConnectedGameLayer.h"
#import "BackgroundLayer.h"
#import "BluetoothConnectLayer.h"



@interface ConnectedGameScene : CCScene {
   
}

+ (ConnectedGameScene*)sharedScene;

+ (BackgroundLayer*)backgroundLayer;

+ (ConnectedGameLayer*)gameLayer;

+ (BluetoothConnectLayer*)bluetoothConnectLayer;

+ (void)clearInstance;

@end
