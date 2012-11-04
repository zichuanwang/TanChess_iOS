//
//  OpenFeintGameLayer.h
//  Tan Chess HD
//
//  Created by Bluebitch on 11-5-22.
//  Copyright 2011年 TJU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConnectedGameLayer.h"
#import "OFMultiplayerDelegate.h"
#import "OpenFeintChessmanSprite.h"


@interface OpenFeintGameLayer : ConnectedGameLayer<OFMultiplayerDelegate, UIAlertViewDelegate> {
    std::vector<CGPoint> _vWaitingUpdateData;
    UIUserInterfaceIdiom _rivalDeviceType;
    bool _receivedRivalDeviceType;
    UIAlertView		*connectionAlert;
    UIAlertView		*restartRequestAlert;
    UIAlertView		*replayRequestAlert;
    UIAlertView     *restartRequestRejectAlert;
    bool _isHost, _isLogin;
}

@property bool isHost;
@property bool isLogin;
@property(nonatomic, retain) UIAlertView *connectionAlert;
@property(nonatomic, retain) UIAlertView *restartRequestAlert;
@property(nonatomic, retain) UIAlertView *replayRequestAlert;
@property(nonatomic, retain) UIAlertView *restartRequestRejectAlert;
@property UIUserInterfaceIdiom rivalDeviceType;

- (void)dispatchData:(void *)data withType:(int)Type withIdentifier:(int)ID;
- (void)leaveGame;

@end
