//
//  AppDelegate.m
//  ALSplitViewDemo
//
//  Created by Valentine Silvansky on 19.02.13.
//  Copyright (c) 2013 silvansky. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@implementation AppDelegate

- (void)dealloc
{
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
	[self.imageView setWantsLayer:YES];
	CALayer *layer = [self.imageView layer];
	[layer setContents:[NSImage imageNamed:@"dog"]];
}

@end
