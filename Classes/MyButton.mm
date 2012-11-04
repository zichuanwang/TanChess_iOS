//
//  HomeButton.m
//  Tan Chess
//
//  Created by Blue Bitch on 11-2-2.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MyButton.h"
#import "SysMenu.h"
#import "SimpleAudioEngine.h"


@implementation MyButton

//注册
- (void)onEnter
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:1 swallowsTouches:YES];
	[super onEnter];
}

//注销
- (void)onExit
{
	[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
	[super onExit];
}	

- (CGRect)rect
{
	// NSLog([self description]);
	return CGRectMake(-rect_.size.width / 2, -rect_.size.height / 2, rect_.size.width, rect_.size.height);
}

- (BOOL)containsTouchLocation:(UITouch *)touch
{
	//CGPoint pt = [self convertTouchToNodeSpaceAR:touch];
	//NSLog([NSString stringWithFormat:@"Rect x=%.2f, y=%.2f, width=%.2f, height=%.2f, Touch point: x=%.2f, y=%.2f", self.rect.origin.x, self.rect.origin.y, self.rect.size.width, self.rect.size.height, pt.x, pt.y]); 
	return CGRectContainsPoint(self.rect, [self convertTouchToNodeSpaceAR:touch]);
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if ( ![self containsTouchLocation:touch] ) 
	{
		return NO;
	}
    self.scale = 0.9;
	return YES;
} 

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    if ( ![self containsTouchLocation:touch] ) {
        self.scale = 1;
	}
    else {
        self.scale = 0.9;
    }
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {  
    if ( self.scale == 1 ) {
		return;
	}
    self.scale = 1;
//	if ( ![self containsTouchLocation:touch] ) 
//	{
//		return;
//	}
	[[SimpleAudioEngine sharedEngine] playEffect:@"click.wav"];
	[self Function];
}

- (void)Function
{
	;
}

- (void) dealloc
{
    [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
    [super dealloc];
}


@end
