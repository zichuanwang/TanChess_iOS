//
//  PauseButton.m
//  Tan Chess
//
//  Created by Blue Bitch on 11-2-2.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PauseButton.h"
#import "GameControlLayer.h"
#import "ConnectedGameScene.h"
#import "OpenFeintGameScene.h"


@implementation PauseButton

@synthesize _type;

- (void)Function
{
	CCScene *sc = [[CCDirector sharedDirector] runningScene];
	GameControlLayer *gcLayer = [GameControlLayer node];
	if( _type == 0 )
	{
		[gcLayer set_type:0];
	}
	else if(_type == 1)
	{
		[gcLayer set_type:1];
        if (![ConnectedGameScene bluetoothConnectLayer].isHost) {
            gcLayer.rotation = 180;
        }
	}	
	else if(_type == 2) {
        [gcLayer set_type:2];
        if (![OpenFeintGameScene gameLayer].isHost) {
            gcLayer.rotation = 180;
        }
    }
	[sc addChild:gcLayer z:2 tag:99];
    [gcLayer fadeIn];
}

- (void) dealloc
{
    [super dealloc];
}

@end
