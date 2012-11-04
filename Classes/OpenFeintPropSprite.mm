//
//  OpenFeintPropSprite.m
//  Tan Chess HD
//
//  Created by Bluebitch on 11-5-23.
//  Copyright 2011年 TJU. All rights reserved.
//

#import "OpenFeintPropSprite.h"
#import "OpenFeintGameScene.h"
#import "SimpleAudioEngine.h"
#import "BluetoothConnectLayer.h"


@implementation OpenFeintPropSprite

+ (id)propWithImageFile:(NSString*)imgFile withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type withScore:(int)score withCategory:(int)cat
{	
	OpenFeintPropSprite *sprite = [OpenFeintPropSprite spriteWithFile:imgFile];
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
    return ![OpenFeintGameScene gameLayer].turnValid;
}

- (void)connectClearScore {
    [[OpenFeintGameScene gameLayer] clearScore:_score];
}

- (bool)testEnlargeInvalid {
    return ![[OpenFeintGameScene gameLayer] testEnlargePropValid];
}

- (void)func
{
    self.isForbad = YES;
	int i;
	switch (_category) {
		case POWERUP:
		{
			[[OpenFeintGameScene gameLayer] turnOnPowerUp];
			i = 0;
			[[OpenFeintGameScene gameLayer] dispatchData:&i withType:PLAY_SOUND_EVENT withIdentifier:-1];
			[[SimpleAudioEngine sharedEngine] playEffect:@"powerup.wav"];
			break;
		}
		case FORBID:
		{
			[[OpenFeintGameScene gameLayer] turnOnForbid];
            i = 3;
			[[OpenFeintGameScene gameLayer] dispatchData:&i withType:PLAY_SOUND_EVENT withIdentifier:-1];
            [[SimpleAudioEngine sharedEngine] playEffect:@"teleport_ef.wav"];
			break;
		}
		case ENLARGE:
		{
			i = 1;
			[[OpenFeintGameScene gameLayer] dispatchData:&i withType:PLAY_SOUND_EVENT withIdentifier:-1];
			[[SimpleAudioEngine sharedEngine] playEffect:@"change.wav"];
			[[OpenFeintGameScene gameLayer] turnOnEnlarge];
			break;
		}
		case CHANGE:
		{
			i = 2;
			[[OpenFeintGameScene gameLayer] dispatchData:&i withType:PLAY_SOUND_EVENT withIdentifier:-1];
			[[SimpleAudioEngine sharedEngine] playEffect:@"teleport.wav"];
			[[OpenFeintGameScene gameLayer] turnOnChange];
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
    if( [OpenFeintGameScene gameLayer].nProp != -1 ) {
        return  YES;
    }
    else{
        return NO;
    }
}

@end
