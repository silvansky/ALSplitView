//
//  ALSplitView.m
//  ALSplitView
//
//  Created by Valentine Silvansky on 19.02.13.
//  Copyright (c) 2013 silvansky. All rights reserved.
//
//  Original code stored at https://github.com/silvansky/ALSplitView
//

#import "ALSplitView.h"

#define ALSPLITVIEW_DEBUG    0

static int distanceOfViewWithIndexFromDividerWithIndex(NSInteger viewIndex, NSInteger dividerIndex)
{
    return ABS(viewIndex - (dividerIndex + 0.5)) - 0.5;
}

@interface ALSplitView ()
{
	ALSplitViewOrientation _orientation;
	NSColor *_handleColor;
	NSImage *_handleBackgroundImage;
	NSImage *_handleImage;
	CGFloat _handleWidth;
}

@property (retain) NSMutableArray *internalConstraints;
@property (retain) NSMutableArray *sizingConstraints;
@property (retain) NSLayoutConstraint *draggingConstraint;
@property (retain) NSMutableArray *minimumSizeConstraints;
@property (retain) NSTrackingArea *trackingArea;

- (void)updateInternalConstraints;
- (void)addInternalConstraints:(NSMutableArray *)constraints;
- (void)updateSizingContstraintsForHandleIndex:(NSInteger)handleIndex;
- (void)addSizingConstrants:(NSMutableArray *)constraints;

- (NSInteger)handleIndexForPoint:(NSPoint)point;
- (NSInteger)numberOfHandles;
- (NSRect)rectOfHandleAtIndex:(NSInteger)index;

- (void)setResizingCursor;
- (void)setNormalCursor;

- (void)onFrameChanged:(NSNotification *)notification;

@end

@implementation ALSplitView

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		self.handleWidth = 9.f;
		self.orientation = ALSplitViewOrientationHorizontal;
		self.minimumSizeConstraints = [NSMutableArray array];
		self.trackingArea = [[[NSTrackingArea alloc] initWithRect:frame options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingInVisibleRect) owner:self userInfo:nil] autorelease];
		[self addTrackingArea:self.trackingArea];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFrameChanged:) name:NSViewFrameDidChangeNotification object:self];
	}

	return self;
}

- (void)awakeFromNib
{
	// removing constraints loaded from xib, we'll make our own
	[self removeConstraints:[self constraints]];
	[super awakeFromNib];
}

- (void)dealloc
{
	self.handleColor = nil;
	self.handleBackgroundImage = nil;
	self.handleImage = nil;
	self.internalConstraints = nil;
	self.sizingConstraints = nil;
	self.draggingConstraint = nil;
	self.minimumSizeConstraints = nil;
	[self removeTrackingArea:self.trackingArea];
	self.trackingArea = nil;
	[super dealloc];
}

- (CGFloat)minimumWidthForViewAtIndex:(NSInteger)index
{
	return 0.f;
}

- (void)setMinimumWidth:(CGFloat)width forViewAtIndex:(NSInteger)index
{
	if (index >= [[self subviews] count])
	{
#if ALSPLITVIEW_DEBUG
		NSLog(@"ALSplitView: setMinimumWidth:forViewAtIndex: index out of boundaries!");
#endif
		return;
	}
	NSView *view = [self subviews][index];
	NSDictionary *metrics = @{ @"minWidth" : @(width) };
	NSString *format;
	if (self.orientation == ALSplitViewOrientationHorizontal)
	{
		format = @"H:[view(>=minWidth)]";
	}
	else
	{
		format = @"V:[view(>=minWidth)]";
	}
	NSArray *newConstraints = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:NSDictionaryOfVariableBindings(view)];
	[self addConstraints:newConstraints];
	[self setNeedsUpdateConstraints:YES];
}

- (void)setMaximumWidth:(CGFloat)width forViewAtIndex:(NSInteger)index
{
	if (index >= [[self subviews] count])
	{
#if ALSPLITVIEW_DEBUG
		NSLog(@"ALSplitView: setMaximumWidth:forViewAtIndex: index out of boundaries!");

#endif
		return;
	}
	NSView *view = [self subviews][index];
	NSDictionary *metrics = @{ @"maxWidth" : @(width) };
	NSString *format;
	if (self.orientation == ALSplitViewOrientationHorizontal)
	{
		format = @"H:[view(<=maxWidth)]";
	}
	else
	{
		format = @"V:[view(<=maxWidth)]";
	}
	NSArray *newConstraints = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:NSDictionaryOfVariableBindings(view)];
	[self addConstraints:newConstraints];
	[self setNeedsUpdateConstraints:YES];
}

- (NSDictionary *)savePositionsOfHandles;
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	dict[@"handlesCount"] = @([self numberOfHandles]);
	dict[@"orientation"] = @(self.orientation);
	NSRect frame = self.frame;
	dict[@"frame"] = @{ @"x" : @(frame.origin.x), @"y" : @(frame.origin.y), @"width" : @(frame.size.width), @"height" : @(frame.size.height) };
	NSMutableArray *views = [NSMutableArray arrayWithCapacity:[self numberOfHandles] + 1];
	for (NSInteger i = 0; i < [self numberOfHandles] + 1; i++)
	{
		NSView *view = [self subviews][i];
		NSRect frame = view.frame;
		[views addObject:@{ @"x" : @(frame.origin.x), @"y" : @(frame.origin.y), @"width" : @(frame.size.width), @"height" : @(frame.size.height) }];
	}
	dict[@"views"] = views;
	return dict;
}

- (void)restorePositionsOfHandlesWithDictionary:(NSDictionary *)dictionary
{
	if (!dictionary)
	{
		return;
	}
	NSNumber *handlesCountNumber = dictionary[@"handlesCount"];
	NSInteger handlesCount = [handlesCountNumber integerValue];
	ALSplitViewOrientation orientation = (ALSplitViewOrientation)[dictionary[@"orientation"] integerValue];
	if (orientation != self.orientation)
	{
#if ALSPLITVIEW_DEBUG
		NSLog(@"ALSplitView: restorePositionsOfHandlesWithDictionary: restoring with incorrect orientation!");
#endif
		return;
	}
	if (handlesCount != [self numberOfHandles])
	{
#if ALSPLITVIEW_DEBUG
		NSLog(@"ALSplitView: restorePositionsOfHandlesWithDictionary: restoring with incorrect handle number!");
#endif
		return;
	}
	[self removeConstraints:[self constraints]];
	NSArray *views = dictionary[@"views"];
	for (NSInteger i = 0; i < handlesCount + 1; i++)
	{
		NSView *view = [self subviews][i];
		NSDictionary *viewDict = views[i];
		CGFloat x = [viewDict[@"x"] floatValue];
		CGFloat y = [viewDict[@"y"] floatValue];
		CGFloat w = [viewDict[@"width"] floatValue];
		CGFloat h = [viewDict[@"height"] floatValue];
		NSRect frame = view.frame;
		if (self.orientation == ALSplitViewOrientationHorizontal)
		{
			frame.origin.x = x;
			frame.size.width = w;
		}
		else
		{
			frame.origin.y = y;
			frame.size.height = h;
		}
		[view setFrame:frame];
	}
	[self addInternalConstraints:nil];
	[self addSizingConstrants:nil];
	[self setNeedsDisplay:YES];
}

#pragma mark - Private

- (void)updateInternalConstraints
{
	NSArray *views = [self subviews];
	NSInteger viewsCount = [views count];
	NSMutableArray *newConstraints = [NSMutableArray arrayWithCapacity:viewsCount];
	NSDictionary *metrics = @{ @"handleWidth" : @(self.handleWidth) };
	NSMutableDictionary *viewsDict = [NSMutableDictionary dictionary];
	NSView *previousView = nil;
	for (NSInteger i = 0; i < viewsCount; i++)
	{
		NSView *currentView = [views objectAtIndex:i];

		viewsDict[@"currentView"] = currentView;
		if (!previousView)
		{
			NSString *format;
			if (self.orientation == ALSplitViewOrientationVertical)
			{
				format = @"V:|[currentView]";
			}
			else
			{
				format = @"H:|[currentView]";
			}
			[newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewsDict]];
		}
		else
		{
			NSString *format;
			if (self.orientation == ALSplitViewOrientationVertical)
			{
				format = @"V:[previousView]-handleWidth-[currentView]";
			}
			else
			{
				format = @"H:[previousView]-handleWidth-[currentView]";
			}
			viewsDict[@"previousView"] = previousView;
			[newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewsDict]];
		}

		NSString *format;
		if (self.orientation == ALSplitViewOrientationVertical)
		{
			format = @"H:|[currentView]|";
		}
		else
		{
			format = @"V:|[currentView]|";
		}
		[newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewsDict]];

		previousView = currentView;
	}

	if (viewsCount)
	{
		NSString *format;
		if (self.orientation == ALSplitViewOrientationVertical)
		{
			format = @"V:[currentView]|";
		}
		else
		{
			format = @"H:[currentView]|";
		}
		[newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:metrics views:viewsDict]];
	}

	[self addInternalConstraints:newConstraints];
}

- (void)addInternalConstraints:(NSMutableArray *)constraints
{
	if (constraints == self.internalConstraints)
	{
		return;
	}
	if (self.internalConstraints)
	{
		[self removeConstraints:self.internalConstraints];
	}
	self.internalConstraints = constraints;
	if (self.internalConstraints)
	{
		[self addConstraints:self.internalConstraints];
	}
	else
	{
		[self setNeedsUpdateConstraints:YES];
	}
}

- (void)updateSizingContstraintsForHandleIndex:(NSInteger)handleIndex
{
	NSMutableArray *constraints = [NSMutableArray array];

    NSArray *views = [self subviews];
    NSInteger numberOfViews = [views count];

    CGFloat spaceForAllDividers = self.handleWidth * (numberOfViews - 1);
    CGFloat spaceForAllViews;
	if (self.orientation == ALSplitViewOrientationVertical)
	{
		spaceForAllViews = NSHeight([self bounds]) - spaceForAllDividers;
	}
	else
	{
		spaceForAllViews = NSWidth([self bounds]) - spaceForAllDividers;
	}
    CGFloat priorityIncrement = 1.0 / numberOfViews;

    for (NSInteger i = 0; i < numberOfViews; i++)
	{
        NSView *currentView = views[i];
        CGFloat percentOfTotalSpace;
		if (self.orientation == ALSplitViewOrientationVertical)
		{
			percentOfTotalSpace = NSHeight([currentView frame]) / spaceForAllViews;
		}
		else
		{
			percentOfTotalSpace = NSWidth([currentView frame]) / spaceForAllViews;
		}

        NSLayoutConstraint *newConstraint;
		if (self.orientation == ALSplitViewOrientationVertical)
		{
			newConstraint = [NSLayoutConstraint constraintWithItem:currentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:percentOfTotalSpace constant:-spaceForAllDividers * percentOfTotalSpace];
		}
		else
		{
			newConstraint = [NSLayoutConstraint constraintWithItem:currentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:percentOfTotalSpace constant:-spaceForAllDividers * percentOfTotalSpace];
		}

        if (handleIndex == -2)
		{
            [newConstraint setPriority:NSLayoutPriorityDefaultLow];
        }
		else
		{
            [newConstraint setPriority:NSLayoutPriorityDefaultLow + priorityIncrement * distanceOfViewWithIndexFromDividerWithIndex(i, handleIndex)];
        }

        [constraints addObject:newConstraint];
    }

	[self addSizingConstrants:constraints];
}

- (void)addSizingConstrants:(NSMutableArray *)constraints
{
	if (self.sizingConstraints == constraints)
	{
		return;
	}
	if (self.sizingConstraints)
	{
		[self removeConstraints:self.sizingConstraints];
	}
	self.sizingConstraints = constraints;
	if (self.sizingConstraints)
	{
		[self addConstraints:self.sizingConstraints];
	}
	else
	{
		[self setNeedsUpdateConstraints:YES];
	}
}

- (NSInteger)handleIndexForPoint:(NSPoint)point
{
	__block NSInteger handleIndex = -1;
	[[self subviews] enumerateObjectsUsingBlock:^(id subview, NSUInteger i, BOOL *stop) {
		NSRect subviewFrame = [subview frame];
		if (NSPointInRect(point, subviewFrame))
		{
			*stop = YES;
		}
		if (self.orientation == ALSplitViewOrientationVertical)
		{
			if (point.y > NSMaxY(subviewFrame))
			{
				handleIndex = i - 1;
				*stop = YES;
			}
			else if (point.y > NSMinY(subviewFrame))
			{
				handleIndex = -1;
				*stop = YES;
			}
		}
		else
		{
			if (point.x < NSMinX(subviewFrame))
			{
				handleIndex = i - 1;
				*stop = YES;
			}
			else if (point.x < NSMaxX(subviewFrame))
			{
				handleIndex = -1;
				*stop = YES;
			}
		}
	}];
	return handleIndex;
}

- (NSInteger)numberOfHandles
{
	return [[self subviews] count] - 1;
}

- (NSRect)rectOfHandleAtIndex:(NSInteger)index
{
	if (index >= [self numberOfHandles])
	{
#if ALSPLITVIEW_DEBUG
		NSLog(@"ALSplitView: rectOfHandleAtIndex: index out of boundaries!");
#endif
		return NSZeroRect;
	}

	NSRect handleRect;
	NSView *view = [self subviews][index];

	if (self.orientation == ALSplitViewOrientationHorizontal)
	{
		handleRect.origin.x = view.frame.origin.x + view.frame.size.width;
		handleRect.origin.y = 0.f;
		handleRect.size.height = self.frame.size.height;
		handleRect.size.width = [self handleWidth];
	}
	else
	{
		handleRect.origin.x = 0.f;
		handleRect.origin.y = view.frame.origin.y - [self handleWidth];
		handleRect.size.height = [self handleWidth];
		handleRect.size.width = self.frame.size.width;
	}

	return handleRect;
}

- (void)setResizingCursor
{
	[super resetCursorRects];
	NSCursor *newCursor;
	if (self.orientation == ALSplitViewOrientationHorizontal)
	{
		newCursor = [NSCursor resizeLeftRightCursor];
	}
	else
	{
		newCursor = [NSCursor resizeUpDownCursor];
	}
	[self addCursorRect:[self bounds] cursor:newCursor];
	[newCursor set];
}

- (void)setNormalCursor
{
	[super resetCursorRects];
	NSCursor *newCursor = [NSCursor arrowCursor];
	[self addCursorRect:[self bounds] cursor:newCursor];
	[newCursor set];
}

- (void)onFrameChanged:(NSNotification *)notification
{
	[self removeTrackingArea:self.trackingArea];
	self.trackingArea = [[[NSTrackingArea alloc] initWithRect:self.frame options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingInVisibleRect) owner:self userInfo:nil] autorelease];
	[self addTrackingArea:self.trackingArea];
}

#pragma mark - Properties

- (ALSplitViewOrientation)orientation
{
	@synchronized(self)
	{
		return _orientation;
	}
}

- (void)setOrientation:(ALSplitViewOrientation)orientation
{
	@synchronized(self)
	{
		_orientation = orientation;
		[self setNeedsDisplay:YES];
		[self removeConstraints:[self constraints]];
		[self addInternalConstraints:nil];
		[self addSizingConstrants:nil];
	}
}

- (NSColor *)handleColor
{
	@synchronized(self)
	{
		return _handleColor;
	}
}

- (void)setHandleColor:(NSColor *)handleColor
{
	@synchronized(self)
	{
		[handleColor retain];
		[_handleColor release];
		_handleColor = handleColor;
		[self setNeedsDisplay:YES];
	}
}

- (NSImage *)handleBackgroundImage
{
	@synchronized(self)
	{
		return _handleBackgroundImage;
	}
}

- (void)setHandleBackgroundImage:(NSImage *)handleBackgroundImage
{
	@synchronized(self)
	{
		[handleBackgroundImage retain];
		[_handleBackgroundImage release];
		_handleBackgroundImage = handleBackgroundImage;
		[self setNeedsDisplay:YES];
	}
}

- (NSImage *)handleImage
{
	@synchronized(self)
	{
		return _handleImage;
	}
}

- (void)setHandleImage:(NSImage *)handleImage
{
	@synchronized(self)
	{
		[handleImage retain];
		[_handleImage release];
		_handleImage = handleImage;
		[self setNeedsDisplay:YES];
	}
}

- (CGFloat)handleWidth
{
	@synchronized(self)
	{
		return _handleWidth;
	}
}

- (void)setHandleWidth:(CGFloat)handleWidth
{
	@synchronized(self)
	{
		_handleWidth = handleWidth;
		[self addInternalConstraints:nil];
	}
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	for (NSInteger i = 0; i < [self numberOfHandles]; i++)
	{
		NSRect handleRect = [self rectOfHandleAtIndex:i];
		if (NSIntersectsRect(dirtyRect, handleRect))
		{
			if (self.handleColor)
			{
				[self.handleColor set];
				NSRectFill(handleRect);
			}
			if (self.handleBackgroundImage)
			{
				[self.handleBackgroundImage drawInRect:handleRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.f respectFlipped:YES hints:nil];
			}
			if (self.handleImage)
			{
				NSRect centeredRect;
				centeredRect.origin.x = handleRect.origin.x + (handleRect.size.width - [self.handleImage size].width) / 2.f;
				centeredRect.origin.y = handleRect.origin.y + (handleRect.size.height - [self.handleImage size].height) / 2.f;
				centeredRect.size = self.handleImage.size;
				[self.handleImage drawInRect:centeredRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.f respectFlipped:YES hints:nil];
			}
		}
	}
}

#pragma mark - Overrides

+ (BOOL)requiresConstraintBasedLayout
{
	return YES;
}

- (void)updateConstraints
{
	[super updateConstraints];
	if (!self.internalConstraints)
	{
		[self updateInternalConstraints];
	}
	if (!self.sizingConstraints)
	{
		[self updateSizingContstraintsForHandleIndex:-2];
	}
}

- (void)didAddSubview:(NSView *)subview
{
	[subview setTranslatesAutoresizingMaskIntoConstraints:NO];
	[self addInternalConstraints:nil];
	[super didAddSubview:subview];
}

- (void)willRemoveSubview:(NSView *)subview
{
	NSMutableArray *constraintsToRemove = [NSMutableArray array];
	for (NSLayoutConstraint *c in [self constraints])
	{
		if (([c secondItem] == subview) || ([c firstItem] == subview))
		{
			[constraintsToRemove addObject:c];
		}
	}
	[self removeConstraints:constraintsToRemove];
	[self addInternalConstraints:nil];
	[super willRemoveSubview:subview];
}

#pragma mark - Dragging overrides

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSInteger handleIndex = [self handleIndexForPoint:location];

	if (handleIndex != -1)
	{
#if ALSPLITVIEW_DEBUG
		NSLog(@"mouseDown: (%f, %f), handleIndex: %ld", location.x, location.y, handleIndex);
#endif
		[self updateSizingContstraintsForHandleIndex:handleIndex];

		NSView *viewAboveDivider = [self subviews][handleIndex];
		if (self.orientation == ALSplitViewOrientationVertical)
		{
			self.draggingConstraint = [[NSLayoutConstraint constraintsWithVisualFormat:@"V:[viewAboveDivider]-100-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(viewAboveDivider)] lastObject];
			self.draggingConstraint.constant = location.y + self.handleWidth / 2.f;
		}
		else
		{
			self.draggingConstraint = [[NSLayoutConstraint constraintsWithVisualFormat:@"H:[viewAboveDivider]-100-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(viewAboveDivider)] lastObject];
			self.draggingConstraint.constant = (self.frame.size.width - location.x + self.handleWidth / 2.f);
		}
		[self.draggingConstraint setPriority:NSLayoutPriorityDragThatCannotResizeWindow];

		[self addConstraint:self.draggingConstraint];
		[self setNeedsDisplay:YES];
	}
	else
	{
		[super mouseDown:theEvent];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if (self.draggingConstraint)
	{
		NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
#if ALSPLITVIEW_DEBUG
		NSLog(@"mouseDragged: (%f, %f)", location.x, location.y);
#endif
		if (self.orientation == ALSplitViewOrientationVertical)
		{
			self.draggingConstraint.constant = location.y + self.handleWidth / 2.f;
		}
		else
		{
			self.draggingConstraint.constant = (self.frame.size.width - location.x + self.handleWidth / 2.f);
		}
#if ALSPLITVIEW_DEBUG
		NSLog(@"self.draggingConstraint.constant == %f", self.draggingConstraint.constant);
#endif
		[self setNeedsDisplay:YES];
	}
	else
	{
		[super mouseDragged:theEvent];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (self.draggingConstraint)
	{
#if ALSPLITVIEW_DEBUG
		NSLog(@"mouseUp");
#endif
		[self removeConstraint:self.draggingConstraint];
		self.draggingConstraint = nil;

		[self updateSizingContstraintsForHandleIndex:-2];
		[self setNeedsDisplay:YES];
	}
	else
	{
		[super mouseUp:theEvent];
	}
}

#pragma mark - Mouse tracking

- (void)mouseMoved:(NSEvent *)theEvent
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	BOOL resizingCursor = NO;
	for (NSInteger i = 0; i < [self numberOfHandles]; i++)
	{
		NSRect handleRect = [self rectOfHandleAtIndex:i];
		if (NSPointInRect(location, handleRect))
		{
			resizingCursor = YES;
			break;
		}
	}
	if (resizingCursor)
	{
		[self setResizingCursor];
	}
	else
	{
		[self setNormalCursor];
	}
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	[self mouseMoved:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[self setNormalCursor];
}

@end
