//
//  PropSprite.m
//  Tan Chess
//
//  Created by Blue Bitch on 10-12-26.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PropSprite.h"
#import "GameLayer.h"
#import "GameScene.h"

@implementation PropSprite;

@synthesize isForbad = _isForbad;
@synthesize score = _score;
@synthesize category = _category;
@synthesize type = _type;
@synthesize isFading = _isFading;


+ (id)propWithImageFile:(NSString*)imgFile withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type withScore:(int)score withCategory:(int)cat {	
	PropSprite *sprite = [PropSprite spriteWithFile:imgFile];
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

- (id)init {
    if((self = [super init]) == nil)
        return nil;
	[self propInit];
    return self;
}

- (void)propInit {
    _isForbad = YES;
	_currentPer = 1;
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

- (CGFloat)distanceBetweenTwoPoints:(CGPoint)fromPoint toPoint:(CGPoint)toPoint
{
	float x = toPoint.x - fromPoint.x; 
	float y = toPoint.y - fromPoint.y; 
	return sqrt(x * x + y * y);
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

- (bool)connectTurnInvalid {
    return ![GameScene gameLayer].turnValid;
}

- (void)connectClearScore {
    [[GameScene gameLayer] clearScore:_score];
}

- (bool)IsPropShowOn {
    if( [GameScene gameLayer].nProp != -1 ) {
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if ( ![self containsTouchLocation:touch] ) 
	{
		return NO;
	}
	if( _isForbad )
	{
		return NO;
	}
	if( !_isValid )
	{
		return NO;
	}
    if( [self connectTurnInvalid] ) {
        return NO;
    }
    if( [self IsPropShowOn] ) {
        return NO;
    }
    self.opacity = 150;
	return YES;
}

- (bool)testEnlargeInvalid {
    return ![[GameScene gameLayer] testEnlargePropValid];
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    if ( ![self containsTouchLocation:touch] ) {
        self.opacity = 255;
	}
    else {
        self.opacity = 150;
    }
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    if ( self.opacity == 255 ) {
		return;
	}
    self.opacity = 255;
	if( self.category == ENLARGE ) {
        if( [self testEnlargeInvalid] ) {
            return;
        }
    }
	[self func];
	//清空分数并检测
	[self connectClearScore];
	//NSLog(@"%d",_value);
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	//NSLog(@"canceled");
}

- (void)checkValid:(int)newScore {
	if( newScore >= _score ) {
		_isValid = YES;
	}
	else {
		_isValid = NO;
	}
}
- (void)func
{
    self.isForbad = YES;
	switch (_category) 
	{
		case POWERUP:
		{
            [[GameScene gameLayer] turnOnPowerUp];
            [[SimpleAudioEngine sharedEngine] playEffect:@"powerup.wav"];
			break;
		}
		case FORBID:
		{
			[[GameScene gameLayer] turnOnForbid];
			[[SimpleAudioEngine sharedEngine] playEffect:@"teleport_ef.wav"];
			break;
		}
		case ENLARGE:
		{
			[[SimpleAudioEngine sharedEngine] playEffect:@"change.wav"];
			[[GameScene gameLayer] turnOnEnlarge];
			break;
		}
		case CHANGE:
		{
			[[SimpleAudioEngine sharedEngine] playEffect:@"teleport.wav"];
			[[GameScene gameLayer] turnOnChange];
			break;
		}
		default:
			break;
	};
}

- (void)drawCDRect:(int)have
{		
    static bool isRetina = [[CCDirector sharedDirector] enableRetinaDisplay:YES];
	int need = self.score;
	float per = (float)have / (float)need;
	if( per > 1 )
	{
		per = 1;
	}

	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	if( per - _currentPer < 0.01 && per - _currentPer > -0.01 )
	{
		_currentPer = per;
	}
	else if( _currentPer < per )
	{
        if(_isFading) {
            _currentPer += 0.045;
        }
        else {
            _currentPer += 0.01;
        }
	}
	else if( _currentPer > per )
	{
		if(_isFading) {
            _currentPer -= 0.045;
        }
        else {
            _currentPer -= 0.01;
        }
	}
	if( _currentPer > 1 )
	{
		_currentPer = 1;
	}
	if( _currentPer <= 0 )
	{
        _isFading = NO;
		_currentPer = 0;
	}
	per = _currentPer;
	
	
	int shadow_width;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		shadow_width = 34;
	}
	else {
		shadow_width = 17;
	}
	
	if( per != 1 && _isFading == NO) {
		glColor4f(0.1, 0.1, 0.1, 0.35);
		CGPoint fullfill[4] = { ccp( self.position.x - shadow_width, self.position.y - shadow_width ), 
			ccp( self.position.x - shadow_width, self.position.y + shadow_width ),
			ccp( self.position.x + shadow_width, self.position.y + shadow_width ),
			ccp( self.position.x + shadow_width, self.position.y - shadow_width )};
        if( isRetina )
        {
            for( int i = 0; i < 4; i++ )
            {
                fullfill[ i ].x *= 2;
                fullfill[ i ].y *= 2;
            }
        }
		glVertexPointer(2, GL_FLOAT, 0, fullfill);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	}
	
	float radius = shadow_width * 1.414;
	int points = 0;
	
	CGPoint* vertices = nil;
	if( !_type )
	{
		static CGPoint currentPos = ccp(0, 0);
        if(currentPos.x != self.position.x + radius * sin(2 * b2_pi * per) || currentPos.y != self.position.y + radius * cos(2 * b2_pi * per)) {
            currentPos = ccp( self.position.x + radius * sin(2 * b2_pi * per), self.position.y + radius * cos(2 * b2_pi * per) );

            currentPos = ccp( self.position.x + radius * sin(2 * b2_pi * per), self.position.y + radius * cos(2 * b2_pi * per) );
            if( per < 0.125f )
            {
                temp1[0] = self.position;
                temp1[1] = currentPos;
                temp1[2] = ccp( self.position.x + shadow_width, self.position.y + shadow_width );
                temp1[3] = ccp( self.position.x + shadow_width, self.position.y - shadow_width );
                temp1[4] = ccp( self.position.x, self.position.y - shadow_width );
                vertices = temp1;
                points = 5;
            }
            else if( per < 0.375f )
            {
                temp2[0] = self.position;
                temp2[1] = currentPos;
                temp2[2] = ccp( self.position.x + shadow_width, self.position.y - shadow_width );
                temp2[3] = ccp( self.position.x, self.position.y - shadow_width );
                vertices = temp2;
                points = 4;
            }
            else if( per < 0.5f )
            {
                temp3[0] = self.position;
                temp3[1] = currentPos;
                temp3[2] = ccp( self.position.x, self.position.y - shadow_width );
                vertices = temp3;
                points = 3;
            }
            else if( per < 0.625 )
            {
                
                temp4[0] = ccp( self.position.x, self.position.y + shadow_width );
                temp4[1] = self.position;
                temp4[2] = currentPos;
                temp4[3] = ccp( self.position.x - shadow_width, self.position.y - shadow_width );
                temp4[4] = ccp( self.position.x - shadow_width, self.position.y + shadow_width );
                vertices = temp4;
                points = 5;
            }
            else if( per < 0.875f )
            {
                temp5[0] = ccp( self.position.x, self.position.y + shadow_width );
                temp5[1] = self.position;
                temp5[2] = currentPos;
                temp5[3] = ccp( self.position.x - shadow_width, self.position.y + shadow_width );
                vertices = temp5;
                points = 4;
            }
            else
            {
                temp6[0] = ccp( self.position.x, self.position.y + shadow_width );
                temp6[1] = self.position;
                temp6[2] = currentPos;
                vertices = temp6;
                points = 3;
            }
		
        }
		if( per < 0.5f )
		{
            temp0[0] = ccp( self.position.x, self.position.y + shadow_width );
            temp0[1] = ccp( self.position.x, self.position.y - shadow_width );
            temp0[2] = ccp( self.position.x - shadow_width, self.position.y - shadow_width );
            temp0[3] = ccp( self.position.x - shadow_width, self.position.y + shadow_width );
			glColor4f(0.1, 0.1, 0.1, 0.4);
			if( isRetina )
			{
				for( int i = 0; i < 4; i++ )
				{
					temp0[ i ].x *= 2;
					temp0[ i ].y *= 2;
				}
			}
			glVertexPointer(2, GL_FLOAT, 0, temp0);
			glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
		}
    }
	
	else
	{
		static CGPoint currentPos = ccp(0 , 0);
        if(currentPos.x != self.position.x + radius * sin(2 * b2_pi * per) || currentPos.y != self.position.y + radius * cos(2 * b2_pi * per)) {
            currentPos = ccp( self.position.x - radius * sin(2 * b2_pi * per), self.position.y - radius * cos(2 * b2_pi * per) );
            currentPos = ccp( self.position.x - radius * sin(2 * b2_pi * per), self.position.y - radius * cos(2 * b2_pi * per) );
            if( per < 0.125f )
            {
                temp1[0] = self.position;
                temp1[1] = currentPos;
                temp1[2] = ccp( self.position.x - shadow_width, self.position.y - shadow_width );
                temp1[3] = ccp( self.position.x - shadow_width, self.position.y + shadow_width );
                temp1[4] = ccp( self.position.x, self.position.y + shadow_width );
                vertices = temp1;
                points = 5;
            }
            else if( per < 0.375f )
            {
                temp2[0] = self.position;
                temp2[1] = currentPos;
                temp2[2] = ccp( self.position.x - shadow_width, self.position.y + shadow_width );
                temp2[3] = ccp( self.position.x, self.position.y + shadow_width );
                vertices = temp2;
                points = 4;
            }
            else if( per < 0.5f )
            {
                temp3[0] = self.position;
                temp3[1] = currentPos;
                temp3[2] = ccp( self.position.x, self.position.y + shadow_width );
                vertices = temp3;
                points = 3;
            }
            else if( per < 0.625 )
            {
                
                temp4[0] = ccp( self.position.x, self.position.y - shadow_width );
                temp4[1] = self.position;
                temp4[2] = currentPos;
                temp4[3] = ccp( self.position.x + shadow_width, self.position.y + shadow_width );
                temp4[4] = ccp( self.position.x + shadow_width, self.position.y - shadow_width );
                vertices = temp4;
                points = 5;
            }
            else if( per < 0.875f )
            {
                temp5[0] = ccp( self.position.x, self.position.y - shadow_width );
                temp5[1] = self.position;
                temp5[2] = currentPos;
                temp5[3] = ccp( self.position.x + shadow_width, self.position.y - shadow_width );
                vertices = temp5;
                points = 4;
            }
            else
            {
                temp6[0] = ccp( self.position.x, self.position.y - shadow_width );
                temp6[1] = self.position;
                temp6[2] = currentPos;
                vertices = temp6;
                points = 3;
            }
        }
		
		if( per < 0.5f )
		{
            temp0[0] = ccp( self.position.x, self.position.y - shadow_width ); 
            temp0[1] = ccp( self.position.x, self.position.y + shadow_width );
            temp0[2] = ccp( self.position.x + shadow_width, self.position.y + shadow_width);
            temp0[3] = ccp( self.position.x + shadow_width, self.position.y - shadow_width);
			glColor4f(0.1, 0.1, 0.1, 0.4);
			if( isRetina )
			{
				for( int i = 0; i < 4; i++ )
				{
					temp0[ i ].x *= 2;
					temp0[ i ].y *= 2;
				}
			}
			glVertexPointer(2, GL_FLOAT, 0, temp0);
			glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
		}
    }
	
	
	//glLineWidth(0.0f);
	glColor4f(0.1, 0.1, 0.1, 0.4);
	//glColor4f(1.0, 1.0, 1.0, 0.1);
	if( isRetina ) {
		for( int i = 0; i < points; i++ ) {
			vertices[ i ].x *= 2;
			vertices[ i ].y *= 2;
		}
	}
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glDrawArrays(GL_TRIANGLE_FAN, 0, points);
	
	// restore default state
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
}

- (void) dealloc {
	[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
	[super dealloc];
}

@end
