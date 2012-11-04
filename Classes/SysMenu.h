//
//  SysMenu.h
//  Cocos2DSimpleGame
//
//  Created by Blue Bitch on 10-11-19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import <UIKit/UIKit.h>
#import "OFFriendPickerController.h"

typedef enum {
	INIT_STATE,
    CHALLENGE_CREATING_STATE,
    CHALLENGE_CREATED_STATE,
    TO_BE_HOST_STATE,
    TO_BE_GUEST_STATE,
    WAIT_AS_HOST_STATE,
    WAIT_AS_GUEST_STATE,
    REJECTING_STATE,
} OpenFeintState;

@interface SysMenu : CCLayer <OFFriendPickerDelegate, UIAlertViewDelegate> {
    CCMenuItem *soundButton;
    CCMenuItem *musicButton;
    CCMenuItem *connect;
    CCMenuItem *openfeint, *bluetooth;
    CCMenu *connectMenu;
    CCSprite *_MutePic[2];
    bool isShuffle;
    
    OpenFeintState openfeintState;
    UIAlertView *challengeAlert;
    UIAlertView *chooseOpponentAlert;
    NSString *opponentName;
}

@property (copy) NSString *userId;
@property (nonatomic, readwrite, copy) NSString *opponentName;

@property(nonatomic, retain) UIAlertView *challengeAlert;
@property(nonatomic, retain) UIAlertView *chooseOpponentAlert;

- (void)fadeIn;

@end
