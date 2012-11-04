//
//  Tan_Chess_HDAppDelegate.m
//  Tan Chess HD
//
//  Created by Blue Bitch on 11-2-6.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import "cocos2d.h"
#import "Tan_Chess_HDAppDelegate.h"
#import "GameConfig.h"
#import "SimpleAudioEngine.h"
#import "RootViewController.h"
#import "GameScene.h"
#import "ConnectedGameScene.h"
#import "SysScene.h"
#import "HelpScene.h"
#import "OpenFeintGameScene.h"
#import "OpenFeint.h"
#import "OFMultiplayerService.h"
#import "OFMultiplayerService+Advanced.h"

@implementation Tan_Chess_HDAppDelegate

@synthesize window;

- (void)initializeOpenfeint
{
    NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithInt:UIInterfaceOrientationPortrait], OpenFeintSettingDashboardOrientation,
							  @"SampleApp", OpenFeintSettingShortDisplayName,
							  [NSNumber numberWithBool:YES], OpenFeintSettingEnablePushNotifications,
  							  [NSNumber numberWithBool:NO], OpenFeintSettingAlwaysAskForApprovalInDebug,
							  window, OpenFeintSettingPresentationWindow,
							  nil];
    //ofDelegate = [SampleOFDelegate new];
    OFDelegatesContainer* delegates = [OFDelegatesContainer containerWithOpenFeintDelegate:self];
    
    [OpenFeint initializeWithProductKey:@"4Q8ys53ciqrFDgjnmM1MRQ"
							  andSecret:@"SidnQvR4PuXRtuTOVYPLuk3AMGJEnqdNwOLW7RrKH4I"
						 andDisplayName:@"Tan Chess HD"
							andSettings:settings
						   andDelegates:delegates];
    
    [OFMultiplayerService setSlotArraySize:1];
    [OpenFeintGameScene sharedScene];
    [OFMultiplayerService setDelegate:[OpenFeintGameScene gameLayer]];
}


- (void) removeStartupFlicker
{
	//
	// THIS CODE REMOVES THE STARTUP FLICKER
	//
	// Uncomment the following code if you Application only supports landscape mode
	//
#if GAME_AUTOROTATION == kGameAutorotationUIViewController
	
	//	CC_ENABLE_DEFAULT_GL_STATES();
	//	CCDirector *director = [CCDirector sharedDirector];
	//	CGSize size = [director winSize];
	//	CCSprite *sprite = [CCSprite spriteWithFile:@"Default.png"];
	//	sprite.position = ccp(size.width/2, size.height/2);
	//	sprite.rotation = -90;
	//	[sprite visit];
	//	[[director openGLView] swapBuffers];
	//	CC_ENABLE_DEFAULT_GL_STATES();
	
#endif // GAME_AUTOROTATION == kGameAutorotationUIViewController	
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions: (NSDictionary*) launchOptions
{
	// Init the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// Try to use CADisplayLink director
	// if it fails (SDK < 3.1) use the default director
	if( ! [CCDirector setDirectorType:kCCDirectorTypeDisplayLink] )
		[CCDirector setDirectorType:kCCDirectorTypeDefault];
	
	
	CCDirector *director = [CCDirector sharedDirector];
	
	// Init the View Controller
	viewController = [[RootViewController alloc] initWithNibName:nil bundle:nil];
	viewController.wantsFullScreenLayout = YES;
	
	//
	// Create the EAGLView manually
	//  1. Create a RGB565 format. Alternative: RGBA8
	//	2. depth format of 0 bit. Use 16 or 24 bit for 3d effects, like CCPageTurnTransition
	//
	//
	EAGLView *glView = [EAGLView viewWithFrame:[window bounds]
								   pixelFormat:kEAGLColorFormatRGB565	// kEAGLColorFormatRGBA8
								   depthFormat:0						// GL_DEPTH_COMPONENT16_OES
						];
	
	// attach the openglView to the director
	[director setOpenGLView:glView];
	
//	// Enables High Res mode (Retina Display) on iPhone 4 and maintains low res on all other devices
	if( ! [director enableRetinaDisplay:YES] )
		CCLOG(@"Retina Display Not supported");
	
	//
	// VERY IMPORTANT:
	// If the rotation is going to be controlled by a UIViewController
	// then the device orientation should be "Portrait".
	//
	// IMPORTANT:
	// By default, this template only supports Landscape orientations.
	// Edit the RootViewController.m file to edit the supported orientations.
	//
#if GAME_AUTOROTATION == kGameAutorotationUIViewController
	[director setDeviceOrientation:kCCDeviceOrientationPortrait];
#else
	[director setDeviceOrientation:kCCDeviceOrientationLandscapeLeft];
#endif
	
	[director setAnimationInterval:1.0f / 30.0f];
	[director setDisplayFPS:NO];
	
	
	// make the OpenGLView a child of the view controller
	[viewController setView:glView];
    [glView setMultipleTouchEnabled:YES];
	
	// make the View Controller a child of the main window
	[window addSubview: viewController.view];
	
	[window makeKeyAndVisible];
    
    // OpenFeint
    [self initializeOpenfeint];
    [OpenFeint respondToApplicationLaunchOptions:launchOptions];
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];

	
	// Removes the startup flicker
	[self removeStartupFlicker];
	
	//Sound
    [CDSoundEngine setMixerSampleRate:CD_SAMPLE_RATE_MID];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"select.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"drop.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"fire.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"hitstone.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"hithinge.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"start.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"powerup.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"lose.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"win.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"teleport.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"teleport_ef.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"change.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"change_ef.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"click.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"myturn.wav"];
    [[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:@"BGM.mp3"];
        
	CCScene *sc = [SysScene sharedScene];
    [[CCDirector sharedDirector] runWithScene:sc];
    [[SysScene sysMenu] fadeIn];
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	[OpenFeint applicationDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	[OpenFeint applicationDidFailToRegisterForRemoteNotifications];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	[OpenFeint applicationDidReceiveRemoteNotification:userInfo];
}

- (void)checkSelectChessman {
    CCScene *currentScene = [[CCDirector sharedDirector] runningScene];
    if([currentScene isMemberOfClass:[GameScene class]])
        [[GameScene  gameLayer] checkChessmanSelectedWhenAppEnterBackground];
    else if([currentScene isMemberOfClass:[ConnectedGameScene class]]) {
        [[ConnectedGameScene  gameLayer] checkChessmanSelectedWhenAppEnterBackground];
        if([ConnectedGameScene gameLayer].isWaitingForPlayer)
            [[CCDirector sharedDirector] pause];
    }
    else if([currentScene isMemberOfClass:[OpenFeintGameScene class]])
        [[OpenFeintGameScene  gameLayer] checkChessmanSelectedWhenAppEnterBackground];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	[[CCDirector sharedDirector] pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[CCDirector sharedDirector] resume];
    [self checkSelectChessman];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[CCDirector sharedDirector] purgeCachedData];
}

-(void) applicationDidEnterBackground:(UIApplication*)application {
	[[CCDirector sharedDirector] stopAnimation];
}

-(void) applicationWillEnterForeground:(UIApplication*)application {
	[[CCDirector sharedDirector] startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
    [OpenFeint shutdown];
    [OFMultiplayerService unsetDelegate:[OpenFeintGameScene gameLayer]];
	CCDirector *director = [CCDirector sharedDirector];
	[[director openGLView] removeFromSuperview];
	[viewController release];
	[window release];
	[director end];	
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

- (void)dealloc {
    //[ofDelegate release];
    [[GameScene sharedScene] release];
    [[ConnectedGameScene sharedScene] release];
    [[SysScene sharedScene] release];
    [[HelpScene sharedScene] release];
	[[CCDirector sharedDirector] release];
	[window release];
	[super dealloc];
}

- (void)dashboardWillAppear
{
}

- (void)dashboardDidAppear
{
}

- (void)dashboardWillDisappear
{
}

- (void)dashboardDidDisappear
{
}

- (void)offlineUserLoggedIn:(NSString*)userId
{
	NSLog(@"User logged in, but OFFLINE. UserId: %@", userId);
    [SysScene sysMenu].userId = nil;
}

- (void)userLoggedIn:(NSString*)userId
{
	NSLog(@"User logged in. UserId: %@", userId);
    [OFMultiplayerService internalLogout];
    [SysScene sysMenu].userId = userId;
    //NSLog([SysScene sysMenu].userId);
}

- (BOOL)showCustomOpenFeintApprovalScreen
{
	return NO;
}

@end
