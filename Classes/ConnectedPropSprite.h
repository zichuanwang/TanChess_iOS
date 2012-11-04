//
//  ConnectedPropSprite.h
//  Tan Chess
//
//  Created by Blue Bitch on 11-2-5.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "PropSprite.h"

@interface ConnectedPropSprite : PropSprite {
}


+ (id)propWithImageFile:(NSString*)imgFile withPosition:(CGPoint)position withScale:(float)scale withType:(bool)type withScore:(int)score withCategory:(int)cat;

- (void)func;

@end

