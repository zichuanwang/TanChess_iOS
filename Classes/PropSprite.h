//
//  PropSprite.h
//  Tan Chess
//
//  Created by Blue Bitch on 10-12-26.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#define POWERUP 1
#define FORBID	2
#define ENLARGE	3
#define CHANGE	4

#define POWERUP_NEED_SCORE  10
#define FORBID_NEED_SCORE	18
#define ENLARGE_NEED_SCORE	26
#define CHANGE_NEED_SCORE	40

@interface PropSprite : CCSprite<CCTargetedTouchDelegate>
{	
    
	bool _isForbad;
	
	bool _isValid;
	
	int	_score;

	int _category;
	
	bool _type;
	
	float _currentPer;
	
    bool _isFading;
    
    CGPoint temp0[4];
    CGPoint temp1[5];
    CGPoint temp2[4];
    CGPoint temp3[3];
    CGPoint temp4[5];
    CGPoint temp5[4];
    CGPoint temp6[3];
}

@property bool isForbad;
@property int score;
@property int category;
@property bool type;
@property bool isFading;

+ (id)propWithImageFile:(NSString*)imgFile withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type withScore:(int)score withCategory:(int)cat;

- (void)checkValid:(int)score;

- (void)func;

- (void)propInit;

- (void)drawCDRect:(int)have;


@end
