//
//  AppDelegate.m
//  DemoForReachAbility
//
//  Created by DarkLinden on 3/11/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"
#import "CusomizeReachability.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    CusomizeReachability *r = [CusomizeReachability reachabilityWithHostName:@"www.google.com"];
    [CusomizeReachability startCheckWithReachability:r];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[ViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
