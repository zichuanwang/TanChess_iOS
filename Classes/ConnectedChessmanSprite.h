//
//  ConnectedChessmanSprite.h
//  Tan Chess
//
//  Created by Blue Bitch on 11-2-4.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "ChessmanSprite.h"

#define SMALL_SIZE	0.35f
#define MEDIUM_SIZE 0.47f
#define LARGE_SIZE	0.67f

@interface ConnectedChessmanSprite : ChessmanSprite {	
		
}

- (void)setImpulse:(b2Vec2)impulse;

- (void)setEnlarged;

- (void)setChanged;

- (void)setSelected;

@end
