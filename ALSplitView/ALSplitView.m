//
//  ALSplitView.m
//  ALSplitView
//
//  Created by Valentine Silvansky on 19.02.13.
//  Copyright (c) 2013 silvansky. All rights reserved.
//

#import "ALSplitView.h"

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

- (void)updateInternalConstraints;
- (void)addInternalConstraints:(NSMutableArray *)constraints;
- (void)updateSizingContstraintsForHandleIndex:(NSInteger)handleIndex;
- (void)addSizingConstrants:(NSMutableArray *)constraints;

- (NSInteger)handleIndexForPoint:(NSPoint)point;
- (NSInteger)numberOfHandles;
- (NSRect)rectOfHandleAtIndex:(NSInteger)index;

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
		NSLog(@"ALSplitView: setMinimumWidth:forViewAtIndex: index out of boundaries!");
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
		NSLog(@"ALSplitView: setMaximumWidth:forViewAtIndex: index out of boundaries!");
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
	//NSLog(@"updateSizingContstraintsForHandleIndex:%ld", handleIndex);
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
		NSLog(@"ALSplitView: rectOfHandleAtIndex: index out of boundaries!");
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
	NSLog(@"updateConstraints");
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
		NSLog(@"mouseDown: (%f, %f), handleIndex: %ld", location.x, location.y, handleIndex);
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
		NSLog(@"mouseDragged: (%f, %f)", location.x, location.y);
		if (self.orientation == ALSplitViewOrientationVertical)
		{
			self.draggingConstraint.constant = location.y + self.handleWidth / 2.f;
		}
		else
		{
			self.draggingConstraint.constant = (self.frame.size.width - location.x + self.handleWidth / 2.f);
		}
//		NSLog(@"self.draggingConstraint.constant == %f", self.draggingConstraint.constant);
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
		NSLog(@"mouseUp");
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

@end
