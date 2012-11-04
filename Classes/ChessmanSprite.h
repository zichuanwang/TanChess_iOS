//
//  chessman.h
//  Cocos2DSimpleGame
//
//  Created by Blue Bitch on 10-11-27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"

#define SMALL_SIZE	0.35f
#define MEDIUM_SIZE 0.47f
#define LARGE_SIZE	0.67f

@interface ChessmanSprite : CCSprite<CCTargetedTouchDelegate> 
{	
	CCSprite *_Gunsight;
	
	CCSprite *_Image;
	
	CCSprite *_NewBackColor;
	
	CCParticleSystem *_emitter;
	
	b2Body *_body;
	
	bool _type;
    
    bool _isEmitterOn;
	
	float _Speed;
	
	bool _isDead;
	
	bool _isForbad;
	
	bool _isSelected;
	
	bool _isPowerUp;
	
	bool _isEnlarge;
	
	bool _isChange;
	
	int _value;
	
    CGPoint _initPos;
    
    float _initScale;
    
    bool _isBetray;
    
    int _ID;
    
    bool _isContactLock;
    
    //bool _isMoving;
    
    int _chessboardWidth;
    int _chessboardHeight;
}


@property bool type;
@property int ID;
@property bool isEmitterOn, isDead, isForbad, isSelected, isContactLock, isBetray;
@property bool isPowerUp, isEnlarge, isChange;
@property int value;
@property (nonatomic,readwrite,assign) CCSprite *Image, *NewBackColor, *Gunsight;
@property (nonatomic,readwrite,assign) b2Body *body;
@property CGPoint initPos;
@property float initScale;
//@property bool isMoving;

+ (id)chessmanWithImageFile:(NSString*) imgFile withFilename:(NSString*)filename withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type;

- (void)createEmitter;

- (void)removeEmitter;

- (void)shutDownEmitter;

- (bool)checkAlive;

- (bool)checkAlive:(CGPoint)point;

- (int)getOpacity;

+ (CGFloat)distanceBetweenTwoPoints:(CGPoint)fromPoint toPoint:(CGPoint)toPoint;

- (void)cancelSelect;

@end
