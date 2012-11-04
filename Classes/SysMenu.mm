//
//  SysMenu.m
//  Cocos2DSimpleGame
//
//  Created by Blue Bitch on 10-11-19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SysMenu.h"

#import "HelpLayer.h"
#import "BluetoothConnectLayer.h"
#import "BackgroundLayer.h"
#import "SimpleAudioEngine.h"
#import "GameScene.h"
#import "ConnectedGameScene.h"
#import "OpenFeintGameScene.h"
#import "HelpScene.h"
#import "LoadingScene.h"

#import "OpenFeint.h"
#import "OFMultiplayer.h"
#import "OFMultiplayerGame.h"
#import "OFMultiplayerService.h"
#import "OFMultiplayerService+Advanced.h"
#import "OFResource.h"
#import "OFNotification.h"
#import "OFUser.h"

#define OF_GAME_DEFINITION_ID @"TAN CHESS HD"
#define TAN_CHESS_SOUND_MUTE_DEFAULT @"TAN CHESS SOUND"
#define TAN_CHESS_MUSIC_MUTE_DEFAULT @"TAN CHESS MUSIC"

@interface SysMenu()
- (void)fadeOut;
- (void)challengeGame;
- (void)startOpenFeintGame;
- (void)showNotification:(NSString *)string;
- (void)stopOpenFeintGame;
@end

@implementation SysMenu

static NSString* staticUserId = nil;

@synthesize opponentName, challengeAlert, chooseOpponentAlert;

- (void)gameIdTick:(ccTime)dt {
     [self showNotification:[NSString stringWithFormat:@"gameId:%llu",[OFMultiplayerService getGame].gameId]];
}

- (id)init 
{
	if ((self = [super init])) 
	{
        [self schedule:@selector(gameIdTick:) interval:3.0f];
		CGSize screenSize = [CCDirector sharedDirector].winSize;
        
        CCSprite *bg;
		CCSprite *title;
		
		CCMenuItem *newGame;
		CCMenuItem *helpGame;
        CCMenuItem *dashBoard;
		
		int menuitem_interval;
		int menuitem_begin;
        CGPoint soundButtonPos;
        CGPoint musicButtonPos;
        CGPoint dashBoardPos;
        
        NSUserDefaults *info = [NSUserDefaults standardUserDefaults];
        if([info valueForKey:TAN_CHESS_MUSIC_MUTE_DEFAULT] == nil) {
            NSLog(@"shit!");
            [info setBool:YES forKey:TAN_CHESS_MUSIC_MUTE_DEFAULT];
        }
        if([info valueForKey:TAN_CHESS_SOUND_MUTE_DEFAULT] == nil) {
            NSLog(@"fuck!");
            [info setBool:NO forKey:TAN_CHESS_SOUND_MUTE_DEFAULT];
        }
        [info synchronize];
        openfeintState = INIT_STATE;
        //isShuffle = NO;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			bg = [CCSprite spriteWithFile:@"Background-ipad.png"];
			title = [CCSprite spriteWithFile:@"Title-ipad.png"];
			newGame	= [CCMenuItemImage itemFromNormalImage:@"Play-ipad.png" selectedImage:@"Play-select-ipad.png" target:self selector:@selector(newGame:)];
			helpGame	= [CCMenuItemImage itemFromNormalImage:@"Help-ipad.png" selectedImage:@"Help-select-ipad.png"  target:self selector:@selector(helpGame:)];
			connect	= [CCMenuItemImage itemFromNormalImage:@"Connect-ipad.png" selectedImage:@"Connect-select-ipad.png"  target:self selector:@selector(connectGame:)];
            openfeint = [CCMenuItemImage itemFromNormalImage:@"Openfeint-ipad.png" selectedImage:@"Openfeint-select-ipad.png"  target:self selector:@selector(openfeint:)];
            bluetooth = [CCMenuItemImage itemFromNormalImage:@"Bluetooth-ipad.png" selectedImage:@"Bluetooth-select-ipad.png"  target:self selector:@selector(bluetooth:)];
			menuitem_interval = 120;
			menuitem_begin = 432;
            
            soundButton = [CCMenuItemImage itemFromNormalImage:@"MuteSound-ipad.png" selectedImage:@"MuteSound-ipad.png" target:self selector:@selector(muteSound:)];
            musicButton = [CCMenuItemImage itemFromNormalImage:@"MuteMusic-ipad.png" selectedImage:@"MuteMusic-ipad.png" target:self selector:@selector(muteMusic:)];
            soundButtonPos = ccp( screenSize.width - 100, 70 );
            musicButtonPos = ccp( screenSize.width - 160, 70 );
            
            _MutePic[0] = [CCSprite spriteWithFile:@"ShutDown-ipad.png"];
            _MutePic[1] = [CCSprite spriteWithFile:@"ShutDown-ipad.png"];
            
            dashBoard = [CCMenuItemImage itemFromNormalImage:@"DashBoard-ipad.png" selectedImage:@"DashBoard-ipad.png"  target:self selector:@selector(dashboard:)];
            dashBoardPos = ccp( screenSize.width - 220, 70 );
		}
		else{
			bg = [CCSprite spriteWithFile:@"Background.png"];
			title = [CCSprite spriteWithFile:@"Title4.png"];
			newGame	= [CCMenuItemImage itemFromNormalImage:@"Play.png" selectedImage:@"Play-select.png" target:self selector:@selector(newGame:)];
			helpGame = [CCMenuItemImage itemFromNormalImage:@"Help.png" selectedImage:@"Help-select.png"  target:self selector:@selector(helpGame:)];
			connect	= [CCMenuItemImage itemFromNormalImage:@"Connect.png" selectedImage:@"Connect-select.png"  target:self selector:@selector(connectGame:)];
            openfeint = [CCMenuItemImage itemFromNormalImage:@"Openfeint.png" selectedImage:@"Openfeint-select.png"  target:self selector:@selector(openfeint:)];
            bluetooth = [CCMenuItemImage itemFromNormalImage:@"Bluetooth.png" selectedImage:@"Bluetooth-select.png"  target:self selector:@selector(bluetooth:)];
			menuitem_interval = 60;
			menuitem_begin = 200;
            soundButton = [CCMenuItemImage itemFromNormalImage:@"MuteSound.png" selectedImage:@"MuteSound.png" target:self selector:@selector(muteSound:)];
            musicButton = [CCMenuItemImage itemFromNormalImage:@"MuteMusic.png" selectedImage:@"MuteMusic.png" target:self selector:@selector(muteMusic:)];
            soundButtonPos = ccp( screenSize.width - 25, 20 );
            musicButtonPos = ccp( screenSize.width - 55, 20 );
            _MutePic[0] = [CCSprite spriteWithFile:@"ShutDown.png"];
            _MutePic[1] = [CCSprite spriteWithFile:@"ShutDown.png"];
            
            dashBoard = [CCMenuItemImage itemFromNormalImage:@"DashBoard.png" selectedImage:@"DashBoard.png"  target:self selector:@selector(dashboard:)];
            dashBoardPos = ccp( screenSize.width - 85, 20 );
		}
        
        _MutePic[0].position = musicButtonPos;
        _MutePic[1].position = soundButtonPos;
        if( ![info boolForKey:TAN_CHESS_MUSIC_MUTE_DEFAULT] ){
            _MutePic[0].opacity = 0;
        }
        if( ![info boolForKey:TAN_CHESS_SOUND_MUTE_DEFAULT] ){
            _MutePic[1].opacity = 0;
        }

        
		bg.anchorPoint = ccp( 0.5, 0.5 );
		bg.position = ccp( screenSize.width / 2, screenSize.height / 2 );
		// 既然是背景,Z 值尽量小。
		[self addChild:bg z:0 tag:1];
		// 用一个图片做画面的标题
		title.anchorPoint = ccp( 0.5, 0.5 );
		title.position = ccp( screenSize.width / 2, screenSize.height / 2 );
		[self addChild:title z:1 tag:2];
		
		// 将 4 个菜单子项加入菜单对象。
		CCMenu *menu = [CCMenu menuWithItems:newGame, helpGame, connect, soundButton, musicButton, dashBoard, nil];
		int i = 0;
		for(CCNode *child in [menu children])
		{
            if(child == soundButton){
                child.position = soundButtonPos;
                continue;
            }
            else if(child == musicButton) {
                child.position = musicButtonPos;
                continue;
            }
            else if(child == dashBoard) {
                child.position = dashBoardPos;
                continue;
            }
            child.position = ccp( screenSize.width / 2, menuitem_begin - i * menuitem_interval );
			i++;
        }
		[menu setPosition:CGPointZero];
        connectMenu = [CCMenu menuWithItems:bluetooth, openfeint, nil];
        bluetooth.position = ccp(connect.position.x - [connect contentSize].width / 4,
                                 connect.position.y);
        openfeint.position = ccp(connect.position.x + [connect contentSize].width / 4,
                                 connect.position.y);
        
        [bluetooth setVisible:NO];
        [openfeint setVisible:NO];
        
        [connectMenu setPosition:CGPointZero];
        [self addChild:connectMenu z:2];
		[self addChild:menu z:1];
        [self addChild:_MutePic[0] z:2];
        [self addChild:_MutePic[1] z:2]; 
        
	}
	return self;
}

- (void)newGameTick:(ccTime)dt {
    [self unscheduleAllSelectors];
    [[CCDirector sharedDirector] replaceScene:[LoadingScene sceneWithTargetScene:[GameScene sharedScene]]];
}

- (void)newGame:(id)sender 
{
    
	[[SimpleAudioEngine sharedEngine] playEffect:@"click.wav"];
    [self fadeOut];
	[self schedule:@selector(newGameTick:) interval:0.4];
}

- (void)helpGameTick:(ccTime)dt {
    [self unscheduleAllSelectors];
    [[CCDirector sharedDirector] replaceScene:[LoadingScene sceneWithTargetScene:[HelpScene sharedScene]]];
}

- (void)helpGame:(id)sender
{
	[[SimpleAudioEngine sharedEngine] playEffect:@"click.wav"];
    [self fadeOut];
	[self schedule:@selector(helpGameTick:) interval:0.4];
}

- (void)connectGame:(id)sender
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"click.wav"];
	[connect runAction:[CCFadeOut actionWithDuration:0.3]];
    [bluetooth runAction:[CCFadeIn actionWithDuration:0.3]];
    [openfeint runAction:[CCFadeIn actionWithDuration:0.3]];
    [bluetooth setVisible:YES];
    [openfeint setVisible:YES];
    [connect setVisible:NO];
    
}

- (void)dashboard:(id)sender {
    [OpenFeint launchDashboard];
}

- (void)challengeGame {
    openfeintState = CHALLENGE_CREATING_STATE;
    [self stopOpenFeintGame];
}

- (void)openFeintGameTick:(ccTime)dt {
    [self unscheduleAllSelectors];
    [[CCDirector sharedDirector] replaceScene:[LoadingScene sceneWithTargetScene:[OpenFeintGameScene sharedScene]]];
    [OFMultiplayerService enterGame:[OFMultiplayerService getGame]];
    if(![[OFMultiplayerService getGame] isItMyTurn]) {
        [[OpenFeintGameScene gameLayer] setHost:NO];
    }
    else
        [[OpenFeintGameScene gameLayer] setHost:YES];
}

- (void)startOpenFeintGame {
    [self unscheduleAllSelectors];
    [self fadeOut];
	[self schedule:@selector(openFeintGameTick:) interval:0.4];
}

- (void)stopOpenFeintGame {
    OFMultiplayerGame* game = [OFMultiplayerService getGame];
    if(game.gameId)
	{
		switch(game.state) {
			case OFMultiplayer::GS_WAITING_TO_START: {
                if([game hasBeenChallenged]) {
                    [game sendChallengeResponseWithAccept:NO];
                }
                else{
                    [game cancelGame];
                }
                break;
            }
            case OFMultiplayer::GS_PLAYING: {
				[game closeGame];
                break;
            }
			default:
				break;
		}
	}
}

- (void)pickerFinishedWithSelectedUser:(OFUser*)selectedUser {
    self.opponentName = selectedUser.name;
    OFMultiplayerGame* game = [OFMultiplayerService getGame];
    NSLog(@"New Game Created");
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"GAME CONFIG", OFMultiplayer::LOBBY_OPTION_CONFIG,
                             [NSNumber numberWithUnsignedInt:2], 
                                                         OFMultiplayer::LOBBY_OPTION_MAX_PLAYERS,
                             [NSNumber numberWithUnsignedInt:2], 
                                                         OFMultiplayer::LOBBY_OPTION_MIN_PLAYERS,
                             [NSString stringWithString:self.userId], 
                                                         OFMultiplayer::LOBBY_OPTION_CHALLENGER_OF_ID,
                             [NSArray arrayWithObject:[selectedUser resourceId]], 
                                                         OFMultiplayer::LOBBY_OPTION_CHALLENGE_OF_IDS,
                             nil];
    [game createGame:OF_GAME_DEFINITION_ID withOptions:options];
    NSLog(@"challenge:%llu",[[OFMultiplayerService getGame] gameId]);
    [self showNotification:[NSString stringWithFormat:@"%@%@", @"Waiting for ", self.opponentName]];
}

- (void)createOpenFeintGame {
    OFMultiplayerGame* game = [OFMultiplayerService getGame];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"GAME CONFIG", OFMultiplayer::LOBBY_OPTION_CONFIG,
                             [NSNumber numberWithUnsignedInt:2], 
                                                         OFMultiplayer::LOBBY_OPTION_MAX_PLAYERS,
                             [NSNumber numberWithUnsignedInt:2], 
                                                         OFMultiplayer::LOBBY_OPTION_MIN_PLAYERS,
                             nil];
    
    [game createGame:OF_GAME_DEFINITION_ID withOptions:options];
    NSLog(@"create:%llu",[[OFMultiplayerService getGame] gameId]);
}

- (NSString *)userId {
    return staticUserId;
}

- (void)setUserId:(NSString *)Id {
    staticUserId = Id;
}

- (void)findOpenFeintGame {
    static bool toBeHost = NO;
    toBeHost = !toBeHost;
    if(toBeHost) {
        [self stopOpenFeintGame];
        openfeintState = TO_BE_HOST_STATE;
        
    }
    else {
        [self stopOpenFeintGame];
        openfeintState = TO_BE_GUEST_STATE;
    }
}

- (NSString*)buildTitleForGame:(OFMultiplayerGame*)game
{
	if(game.gameId)
	{
		switch(game.state) {
			case OFMultiplayer::GS_WAITING_TO_START:
                if([game hasBeenChallenged])
                    return @"Challenge";
                else
                    return @"Waiting";
			case OFMultiplayer::GS_PLAYING:
				if([game isItMyTurn])
					return @"Playing - Your Turn";
				else 
					return @"Playing - Opponent's Turn";
                
			case OFMultiplayer::GS_FINISHED:
			{
				BOOL rematch = [game hasRequestedRematch];
				BOOL won = [game getRankWithPlayerNumber:game.player];  //for demonstration, rank is a BOOL 1=win, 0=lost
				if(rematch)
				{
					return won ? @"Finished - Won! Rematch req." : @"Finished - Lost :( Rematch req.";
				}
				else {
					return won ? @"Finished - Won!" : @"Finished - Lost :(";
				}
			}
			default:
				return @"Unknown";
		}
	}
	else
	{
		return @"Empty";
	}
}

- (void)challengeDelayTick:(ccTime)dt {
    [self unscheduleAllSelectors];
    [self schedule:@selector(waitForChallengeTick:) interval:1.0f];
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView == challengeAlert) {
        if(buttonIndex == 0) {
            NSLog(@"gameId:%llu",[OFMultiplayerService getGame].gameId);
            [[OFMultiplayerService getGame] sendChallengeResponseWithAccept:YES];
            [self startOpenFeintGame];
            NSLog(@"accept challenge");
        }
        else {
            [[OFMultiplayerService getGame] sendChallengeResponseWithAccept:NO];
            openfeintState = REJECTING_STATE;
            NSLog(@"reject challenge");
        }
    }
    else if(alertView == chooseOpponentAlert) {
        if([OpenFeintGameScene gameLayer].isLogin == NO) {
            [self showNotification:@"You are offline"];
            return;
        }
        if(buttonIndex == 0) {
            [self findOpenFeintGame];
        }
        else {
            [self challengeGame];
        }
    }
}

- (void)showNotification:(NSString *)string {
    OFNotificationData *notification = [OFNotificationData dataWithText:string andCategory:kNotificationCategoryMultiplayer];
    [[OFNotification sharedInstance] showBackgroundNotice:notification andStatus:nil];
}

- (void)showChallengeAlert {
    NSString *message = @"Receive a challenge from OpenFeint";
    if(self.chooseOpponentAlert.visible) {
        [self.chooseOpponentAlert dismissWithClickedButtonIndex:-1 animated:NO];
    }
    if(self.challengeAlert && self.challengeAlert.visible) {
        self.challengeAlert.message = message;
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Challenger!" message:message delegate:self cancelButtonTitle:@"Approve" otherButtonTitles:@"Reject", nil];
        self.challengeAlert = alert;
        [alert show];
        [alert release];
    }
}

- (void)waitForChallengeTick:(ccTime)dt {
    
    OFMultiplayerGame *game = [OFMultiplayerService getGame]; 
    NSLog(@"%@",[self buildTitleForGame:game]);
    NSLog(@"state:%d",openfeintState);
    //[self showNotification:[self buildTitleForGame:game]];
    switch(openfeintState) {
        case INIT_STATE:
            // 初始状态 无条件退出游戏
            if(game.gameId)
                [self stopOpenFeintGame];
            break;
        case CHALLENGE_CREATING_STATE:
            if(game.gameId == 0) {
                [OFFriendPickerController launchPickerWithDelegate:self promptText:@"Choose an opponent" mustHaveApplicationId:nil];
                openfeintState = CHALLENGE_CREATED_STATE;
            }
            break;
        case CHALLENGE_CREATED_STATE:
            break;
        case TO_BE_HOST_STATE:
            if(game.gameId == 0) {
                [self createOpenFeintGame];
                [self showNotification:@"Waiting for random player(as host)"];
                openfeintState = WAIT_AS_HOST_STATE;
            }
            break;
        case TO_BE_GUEST_STATE:
            if(game.gameId == 0) {
                [[OFMultiplayerService getGame] findGame:OF_GAME_DEFINITION_ID withOptions:nil];
                [self showNotification:@"Waiting for random player(as guest)"];
                openfeintState = WAIT_AS_GUEST_STATE;
            }
            break;
        case WAIT_AS_HOST_STATE:
            break;
        case WAIT_AS_GUEST_STATE:
            break;
        case REJECTING_STATE:
            // 请测试拒绝挑战
            if(game.gameId == 0)
                openfeintState = INIT_STATE;
            break;
        default:
            break;
    }
    // 根据游戏状态改变自身状态
    if(game.gameId)
	{
		switch(game.state) {
			case OFMultiplayer::GS_WAITING_TO_START: {
                if([game hasBeenChallenged]) {
                    // 如果不是已经点击不接受挑战的状态 则显示被挑战对话框
                    if(openfeintState != REJECTING_STATE)
                        [self showChallengeAlert];
                }
                break;
            }
            case OFMultiplayer::GS_PLAYING: {
                if(openfeintState != INIT_STATE) {
                    [self startOpenFeintGame];
                }
                break;
            }
            case OFMultiplayer::GS_FINISHED: {
                [game closeGame];
                break;
            }
			default:
				break;
		}
	}
    else {
        if(openfeintState == CHALLENGE_CREATED_STATE) {
            [self showNotification:[NSString stringWithFormat:@"%@%@", @"Rejected by ", self.opponentName]];
            openfeintState = INIT_STATE;
        }
    }
}

- (void)openfeint:(id)sender {
    [[SimpleAudioEngine sharedEngine] playEffect:@"click.wav"];
    NSString *message = @"Please choose your opponent";
    if(self.challengeAlert.visible) {
        [self.challengeAlert dismissWithClickedButtonIndex:-1 animated:NO];
    }
    if(self.chooseOpponentAlert && self.chooseOpponentAlert.visible) {
        self.chooseOpponentAlert.message = message;
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OpenFeint Online Game" message:message delegate:self cancelButtonTitle:@"Random" otherButtonTitles:@"Friends", nil];
        self.chooseOpponentAlert = alert;
        [alert show];
        [alert release];
    }
}

- (void)bluetoothTick:(ccTime)dt {
    [self unscheduleAllSelectors];
    [[CCDirector sharedDirector] replaceScene:[LoadingScene sceneWithTargetScene:[ConnectedGameScene sharedScene]]];
    
}

- (void)bluetooth:(id)sender {
    [[SimpleAudioEngine sharedEngine] playEffect:@"click.wav"];
    [self fadeOut];
	[self schedule:@selector(bluetoothTick:) interval:0.4];
}

- (void)muteMusic:(id)sender
{
    if ([[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying]) {  
        [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    }
    else{
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"BGM.mp3" loop:YES];
    }
    NSUserDefaults *info = [NSUserDefaults standardUserDefaults];
    if( [info boolForKey:TAN_CHESS_MUSIC_MUTE_DEFAULT] ){
        [info setBool:NO forKey:TAN_CHESS_MUSIC_MUTE_DEFAULT];
        _MutePic[0].opacity = 0;
    }
    else{
        [info setBool:YES forKey:TAN_CHESS_MUSIC_MUTE_DEFAULT];
        _MutePic[0].opacity = 255;
    }
    [info synchronize];
}

- (void)muteSound:(id)sender
{
    NSUserDefaults *info = [NSUserDefaults standardUserDefaults];
    if( [info boolForKey:TAN_CHESS_SOUND_MUTE_DEFAULT] ){
        [info setBool:NO forKey:TAN_CHESS_SOUND_MUTE_DEFAULT];
        _MutePic[1].opacity = 0;
        [[SimpleAudioEngine sharedEngine] SetMyMute:NO];
    }
    else{
        [info setBool:YES forKey:TAN_CHESS_SOUND_MUTE_DEFAULT];
        _MutePic[1].opacity = 255;
        [[SimpleAudioEngine sharedEngine] SetMyMute:YES];
    }
    [info synchronize];
}

- (void)fadeOut {
    CCArray *children = [self children];
    NSUserDefaults *info = [NSUserDefaults standardUserDefaults];
    for(CCSprite *sprite in children) {
        if( sprite == _MutePic[0] && ![info boolForKey:TAN_CHESS_MUSIC_MUTE_DEFAULT] ) continue;
        if( sprite == _MutePic[1] && ![info boolForKey:TAN_CHESS_SOUND_MUTE_DEFAULT] ) continue;
        if(sprite.visible)
            [sprite runAction:[CCFadeOut actionWithDuration:0.3]];
    }
}

- (void)fadeIn {
    [connect setVisible:YES];
    [bluetooth setVisible:NO];
    [openfeint setVisible:NO];
    CCArray *children = [self children];
    NSUserDefaults *info = [NSUserDefaults standardUserDefaults];
    for(CCSprite *sprite in children) {
        if( sprite == _MutePic[0] && ![info boolForKey:TAN_CHESS_MUSIC_MUTE_DEFAULT] ) continue;
        if( sprite == _MutePic[1] && ![info boolForKey:TAN_CHESS_SOUND_MUTE_DEFAULT] ) continue;
        sprite.opacity = 0;
        if(sprite.visible)
            [sprite runAction:[CCFadeIn actionWithDuration:0.3]];
    }
    [self schedule:@selector(waitForChallengeTick:) interval:2.0f];
}

- (void)dealloc
{
    if(self.challengeAlert.visible) {
		[self.challengeAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}
	self.challengeAlert = nil;
    if(self.chooseOpponentAlert.visible) {
		[self.chooseOpponentAlert dismissWithClickedButtonIndex:-1 animated:NO];
	}
	self.chooseOpponentAlert = nil;
	[super dealloc];
}

@end
