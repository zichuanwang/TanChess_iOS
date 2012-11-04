//
//  Tan_Chess_HDAppDelegate.h
//  Tan Chess HD
//
//  Created by Blue Bitch on 11-2-6.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OpenFeint.h"

@class RootViewController;

@interface Tan_Chess_HDAppDelegate : NSObject <UIApplicationDelegate, OpenFeintDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
    //SampleOFDelegate *ofDelegate;
}

@property (nonatomic, retain) UIWindow *window;

@end
