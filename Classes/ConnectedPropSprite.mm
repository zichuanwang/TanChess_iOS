//
//  ConnectedPropSprite.m
//  Tan Chess
//
//  Created by Blue Bitch on 11-2-5.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ConnectedPropSprite.h"
#import "ConnectedGameScene.h"
#import "SimpleAudioEngine.h"

@implementation ConnectedPropSprite


+ (id)propWithImageFile:(NSString*)imgFile withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type withScore:(int)score withCategory:(int)cat
{	
	ConnectedPropSprite *sprite = [ConnectedPropSprite spriteWithFile:imgFile];
    if(type)
	{
		[sprite setRotation:180];
		sprite.isForbad = YES;
	}
    sprite.position = position;
    sprite.scale = scale;
    sprite.type = type;
    sprite.score = score;
    sprite.category = cat;
    return sprite;
}

- (bool)connectTurnInvalid {
    return ![ConnectedGameScene gameLayer].turnValid;
}

- (void)connectClearScore {
    [[ConnectedGameScene gameLayer] clearScore:_score];
}

- (bool)testEnlargeInvalid {
    return ![[ConnectedGameScene gameLayer] testEnlargePropValid];
}

- (void)func
{
    self.isForbad = YES;
	int i;
	switch (_category) {
		case POWERUP:
		{
			[[ConnectedGameScene gameLayer] turnOnPowerUp];
			i = 0;
			[[ConnectedGameScene bluetoothConnectLayer] dispatchData:&i withType:PLAY_SOUND_EVENT withIdentifier:-1];
			[[SimpleAudioEngine sharedEngine] playEffect:@"powerup.wav"];
			break;
		}
		case FORBID:
		{
			[[ConnectedGameScene gameLayer] turnOnForbid];
            i = 3;
			[[ConnectedGameScene bluetoothConnectLayer] dispatchData:&i withType:PLAY_SOUND_EVENT withIdentifier:-1];
            [[SimpleAudioEngine sharedEngine] playEffect:@"teleport_ef.wav"];
			break;
		}
		case ENLARGE:
		{
			i = 1;
			[[ConnectedGameScene bluetoothConnectLayer] dispatchData:&i withType:PLAY_SOUND_EVENT withIdentifier:-1];
			[[SimpleAudioEngine sharedEngine] playEffect:@"change.wav"];
			[[ConnectedGameScene gameLayer] turnOnEnlarge];
			break;
		}
		case CHANGE:
		{
			i = 2;
			[[ConnectedGameScene bluetoothConnectLayer] dispatchData:&i withType:PLAY_SOUND_EVENT withIdentifier:-1];
			[[SimpleAudioEngine sharedEngine] playEffect:@"teleport.wav"];
			[[ConnectedGameScene gameLayer] turnOnChange];
			break;
		}
		default:
			break;
	};
}

- (void) dealloc
{
	[super dealloc];
}

- (bool)IsPropShowOn {
    if( [ConnectedGameScene gameLayer].nProp != -1 ) {
        return  YES;
    }
    else{
        return NO;
    }
}

@end

