//
//  AppDelegate.h
//  ALSplitViewDemo
//
//  Created by Valentine Silvansky on 19.02.13.
//  Copyright (c) 2013 silvansky. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "ALSplitView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet ALSplitView *splitView;
@property (assign) IBOutlet NSView *imageView;
@property (assign) IBOutlet NSView *imageView2;
@property (assign) IBOutlet NSView *imageView3;
@property (assign) IBOutlet NSSegmentedControl *orientationControl;

- (IBAction)onOrientation:(id)sender;
- (IBAction)onAddView:(id)sender;
- (IBAction)onRemoveView:(id)sender;
- (IBAction)onAddSizeLimits:(id)sender;

@end
