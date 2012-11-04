//
//  PauseButton.h
//  Tan Chess
//
//  Created by Blue Bitch on 11-2-2.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "MyButton.h"

@interface PauseButton : MyButton
{
	int _type;
}

@property (nonatomic,readwrite,assign) int _type;

- (void)Function;

@end
