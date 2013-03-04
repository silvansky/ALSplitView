//
//  AdditionalWindowController.h
//  ALSplitViewDemo
//
//  Created by Valentine Gorshkov on 27.02.13.
//  Copyright (c) 2013 silvansky. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WebView;
@class ALSplitView;

@interface AdditionalWindowController : NSWindowController <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (assign) IBOutlet ALSplitView *splitView;
@property (assign) IBOutlet WebView *webView;
@property (assign) IBOutlet NSOutlineView *outline;

@end
