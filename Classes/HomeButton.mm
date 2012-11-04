//
//  HomeButton.m
//  Tan Chess
//
//  Created by Blue Bitch on 11-2-2.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HomeButton.h"
#import "HelpScene.h"

@implementation HomeButton

- (void)Function
{
    [[HelpScene helpLayer] fadeOut];
}

- (void) dealloc
{
    [super dealloc];
}

@end
