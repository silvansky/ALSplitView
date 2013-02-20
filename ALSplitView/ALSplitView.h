//
//  ALSplitView.h
//  ALSplitView
//
//  Created by Valentine Silvansky on 19.02.13.
//  Copyright (c) 2013 silvansky. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum _ALSplitViewOrientation
{
	ALSplitViewOrientationHorizontal,
	ALSplitViewOrientationVertical
} ALSplitViewOrientation;

@interface ALSplitView : NSView

@property (assign) ALSplitViewOrientation orientation;
@property (retain) NSColor *handleColor;
@property (retain) NSImage *handleBackgroundImage;
@property (retain) NSColor *handleImage;
@property (assign) CGFloat handleWidth;

- (void)setMinimumWidth:(CGFloat)width forViewAtIndex:(NSInteger)index;
- (void)setMaximumWidth:(CGFloat)width forViewAtIndex:(NSInteger)index;

@end
