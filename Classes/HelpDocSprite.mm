//
//  HelpDocSprite.m
//  Tan Chess
//
//  Created by Blue Bitch on 11-1-31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HelpDocSprite.h"
#import "HomeButton.h"

@implementation HelpDocSprite

- (void)moveTick:(ccTime)dt {
    float friction = 0.90f;
	if ( !isDragging )
	{
        //NSLog(@"vel : %f", yvel);
        yvel *= friction;
        CGPoint pos = self.position;
        pos.y += yvel;
        if(isMovingToUpBound) {
            if(yvel < 2) 
                yvel = 2;
            if(pos.y > 0) {
                isMovingToUpBound = NO;
                pos.y = 0;
                yvel = 0;
                NSLog(@"stopMovingToUpBound");
            }
            self.position = pos;
            return;
        }
        else if(isMovingToBottomBound) {
            if(yvel > -2) 
                yvel = -2;
            NSLog(@"vel : %f", yvel);
            if(pos.y < contentHeight) {
                isMovingToBottomBound = NO;
                pos.y = contentHeight;
                yvel = 0;
                NSLog(@"stopMovingToButtomBound");
            }
            self.position = pos;
            return;
        }
        
        // to bounce at bounds
		if ( pos.y < 0 ) {
            yvel = -pos.y / 5; 
            isMovingToUpBound = YES;
            NSLog(@"isMovingToUpBound");
        }
		if ( pos.y > contentHeight ) { 
            yvel = (contentHeight - pos.y) / 5;
            isMovingToBottomBound = YES;
            NSLog(@"isMovingToBottomBound");
        }
		self.position = pos;
	}
	else
	{
		yvel = ( self.position.y - lasty ) / 2;
		lasty = self.position.y;
	}
}

- (id)init
{
	self = [super init];
	if (self)
	{
		//CGSize screenSize = [CCDirector sharedDirector].winSize;
		HomeButton *homeButton;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
			homeButton = [HomeButton spriteWithFile:@"Home-ipad.png"];
			homeButton.anchorPoint = ccp( 0.5, 0.5);
			homeButton.position = ccp( 320, 120 );
            contentHeight = 960;
            maxInterval = 100;
		}
		else {
			homeButton = [HomeButton spriteWithFile:@"Home.png"];
			homeButton.anchorPoint = ccp( 0.5, 0.5);
			homeButton.position = ccp( 160, 60 );
            contentHeight = 480;
            maxInterval = 50;
		}
		[self addChild:homeButton z:99];
        [self schedule:@selector(moveTick:) interval:0.01f];
	}
	return self;
}

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

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	startTouchPosition = [touch locationInView:[touch view]];
	//NSLog(@"YES~~~~");
    isDragging = YES;
    isMovingToBottomBound = NO;
    isMovingToUpBound = NO;
	return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{   
	CGPoint currentTouchPosition = [touch locationInView:[touch view]];	
	float offset;   
    offset = self.position.y - ( currentTouchPosition.y - startTouchPosition.y );
    startTouchPosition.y = currentTouchPosition.y;
	if( offset < -maxInterval )
	{
		offset = -maxInterval;
	}
	int Bottom;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		Bottom = 960 + maxInterval;
	}
	else {
		Bottom = 480 + maxInterval;
	}
	if( offset > Bottom )
	{
		offset = Bottom;
	}
	[self setPosition:ccp(self.position.x, offset)];
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    isDragging = NO;
}

- (void) dealloc
{
	[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
	[super dealloc];
}

@end
