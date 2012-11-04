//
//  GameControlLayer.m
//  Tan Chess
//
//  Created by Blue Bitch on 10-12-26.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GameControlLayer.h"
#import "SysMenu.h"
#import "GameScene.h"
#import "ConnectedGameScene.h"
#import "OpenFeintGameScene.h"
#import "SimpleAudioEngine.h"
#import "OFMultiplayerService.h"


@implementation GameControlLayer

@synthesize _type;

- (id)init {
	self = [super init];
	if (self) {
		CGSize screenSize = [CCDirector sharedDirector].winSize;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			_image = [CCSprite spriteWithFile:@"GameControl-ipad.png"];
		}
		else {
			_image = [CCSprite spriteWithFile:@"GameControl.png"];
		}

		[_image setPosition:ccp( screenSize.width/2, screenSize.height/2 )];
		[self addChild: _image z:0];
        
    }
	return self;
}

- (void)fadeOutTick:(ccTime)dt {
    [self unscheduleAllSelectors];
    [[[CCDirector sharedDirector] runningScene] removeChild:self cleanup:YES];
}

- (void)fadeIn {
    [_image runAction:[CCFadeIn actionWithDuration:0.12]];
}

- (void)fadeOut {
    [self schedule:@selector(fadeOutTick:) interval:0.16];
    [_image runAction:[CCFadeOut actionWithDuration:0.15]];
}

//注册
- (void)onEnter
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
	[super onEnter];
}

//注销
- (void)onExit
{
	[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
	[super onExit];
}	

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	return YES;
} 

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{  
	CGSize screenSize = [CCDirector sharedDirector].winSize;
	int button_left_edge,button_right_edge;
	int button1_up_edge,button1_down_edge;
	int button2_up_edge,button2_down_edge;
	int button3_up_edge,button3_down_edge;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		button_left_edge = screenSize.width/2 - 80;
		button_right_edge = screenSize.width/2 + 80;
		button1_up_edge = screenSize.height/2 + 100 * 2;
		button1_down_edge = screenSize.height/2 + 180 * 2;
		button2_up_edge = screenSize.height/2 - 80;
		button2_down_edge = screenSize.height/2 + 80;
		button3_up_edge = screenSize.height/2 - 180 * 2;
		button3_down_edge = screenSize.height/2 - 100 * 2;
	}
	else {
		button_left_edge = 120;
		button_right_edge = 200;
		button1_up_edge = 340;
		button1_down_edge = 420;
		button2_up_edge = 200;
		button2_down_edge = 280;
		button3_up_edge = 60;
		button3_down_edge = 140;
	}

	CGPoint point = [touch locationInView: [touch view]];
	if( point.x < button_left_edge || point.x > button_right_edge )
	{
		return;
	}
	if( point.y < button1_down_edge && point.y > button1_up_edge )
	{
		//NSLog(@"Home");
        [self fadeOut];
        if(_type == 2) {
            [[OpenFeintGameScene gameLayer] leaveGame];
            [[OpenFeintGameScene gameLayer] fadeOut];
        }
        else if( _type == 1 ) {
            [[ConnectedGameScene bluetoothConnectLayer] disConnect];
            [[ConnectedGameScene gameLayer] fadeOut];
        }
		else {
            [[GameScene gameLayer] fadeOut];
        }
	}
	else if( point.y < button2_down_edge && point.y > button2_up_edge )
	{
		//NSLog(@"Retry");
        [self fadeOut];
        if(_type == 2) {
            [[OpenFeintGameScene gameLayer] dispatchData:nil withType:RESTART_REQUEST withIdentifier:0];
        }
        else if( _type == 0 )
		{
            [[GameScene gameLayer] reposition];
		}
		else
		{
            [[ConnectedGameScene bluetoothConnectLayer] dispatchData:nil withType:RESTART_REQUEST withIdentifier:0];
		}
	}
	else if( point.y < button3_down_edge && point.y > button3_up_edge )
	{
		//NSLog(@"Continue");
        [self fadeOut];
	}
	else
	{
		return;
	}
	[[SimpleAudioEngine sharedEngine] playEffect:@"click.wav"];
}


- (void) dealloc
{
    [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
	[super dealloc];
}

@end
