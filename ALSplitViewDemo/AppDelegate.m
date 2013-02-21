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
	[self.imageView2 setWantsLayer:YES];
	[self.imageView3 setWantsLayer:YES];
	CALayer *layer = [self.imageView layer];
	[layer setContents:[NSImage imageNamed:@"dog"]];
	layer = [self.imageView2 layer];
	[layer setContents:[NSImage imageNamed:@"dog"]];
	layer = [self.imageView3 layer];
	[layer setContents:[NSImage imageNamed:@"dog"]];

	self.splitView.handleColor = [NSColor whiteColor];
	self.splitView.handleWidth = 5.f;
	self.splitView.handleBackgroundImage = [NSImage imageNamed:@"bg"];
	self.splitView.handleImage = [NSImage imageNamed:@"handle"];

	[self.splitView restorePositionsOfHandlesWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"splitView"]];

	[self.splitView setMinimumWidth:200.f forViewAtIndex:0];
	[self.splitView setMinimumWidth:250.f forViewAtIndex:1];
	[self.splitView setMaximumWidth:300.f forViewAtIndex:0];

}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	[[NSUserDefaults standardUserDefaults] setObject:[self.splitView savePositionsOfHandles] forKey:@"splitView"];
}

- (IBAction)onOrientation:(id)sender
{
	if ([self.orientationControl selectedSegment] == 0)
	{
		self.splitView.orientation = ALSplitViewOrientationVertical;
	}
	else
	{
		self.splitView.orientation = ALSplitViewOrientationHorizontal;
	}
}

- (IBAction)onAddView:(id)sender
{
	NSView *view = [[[NSView alloc] initWithFrame:NSMakeRect(0.f, 0.f, 100.f, 100.f)] autorelease];
	[view setWantsLayer:YES];
	view.layer.contents = [NSImage imageNamed:@"dog"];
	[self.splitView addSubview:view];
}

- (IBAction)onRemoveView:(id)sender
{
	if ([[self.splitView subviews] count])
	{
		NSView *firstSubview = [self.splitView subviews][0];
		[firstSubview removeFromSuperview];
	}
}

- (IBAction)onAddSizeLimits:(id)sender
{
	CGFloat availableSize;
	NSInteger count = [[self.splitView subviews] count];
	if (self.splitView.orientation == ALSplitViewOrientationHorizontal)
	{
		availableSize = self.splitView.frame.size.width;
	}
	else
	{
		availableSize = self.splitView.frame.size.height;
	}

	availableSize -= (self.splitView.handleWidth * (count - 1));

	CGFloat maximumSizePerView = availableSize / count;
	CGFloat minimumSizePerView = maximumSizePerView / 3.f;
	CGFloat diff = maximumSizePerView - minimumSizePerView;

	srandomdev();

	for (NSInteger i = 0; i < count - 1; i++)
	{
		double alt = (random() % 1001) / 1000.;
		CGFloat widthForView = minimumSizePerView + alt * diff;
		[self.splitView setMinimumWidth:widthForView forViewAtIndex:i];
		[self.splitView setMaximumWidth:maximumSizePerView forViewAtIndex:i];
	}
}

@end
