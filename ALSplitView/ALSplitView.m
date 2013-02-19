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

@property (retain) NSMutableArray *internalConstraints;
@property (retain) NSMutableArray *sizingConstraints;
@property (retain) NSLayoutConstraint *draggingConstraint;
@property (retain) NSMutableArray *minimumSizeConstraints;

- (void)updateInternalConstraints;
- (void)addInternalConstraints:(NSMutableArray *)constraints;
- (void)updateSizingContstraintsForHandleIndex:(NSInteger)handleIndex;
- (void)addSizingConstrants:(NSMutableArray *)constraints;

- (NSInteger)handleIndexForPoint:(NSPoint)point;

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

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor redColor] set];
    NSRectFill(dirtyRect);
}

- (CGFloat)minimumWidthForViewAtIndex:(NSInteger)index
{
	return 0.f;
}

- (void)setMinimumWidth:(CGFloat)width forViewAtIndex:(NSInteger)index
{
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
	if (self.internalConstraints)
	{
		[self removeConstraints:self.internalConstraints];
	}
	self.internalConstraints = constraints;
	if (constraints)
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

    CGFloat spaceForAllDividers = [self handleWidth] * (numberOfViews - 1);
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

        NSLayoutConstraint *heightConstraint;
		if (self.orientation == ALSplitViewOrientationVertical)
		{
			heightConstraint = [NSLayoutConstraint constraintWithItem:currentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:percentOfTotalSpace constant:-spaceForAllDividers * percentOfTotalSpace];
		}
		else
		{
			heightConstraint = [NSLayoutConstraint constraintWithItem:currentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:percentOfTotalSpace constant:-spaceForAllDividers * percentOfTotalSpace];
		}

        if (handleIndex == -2)
		{
            [heightConstraint setPriority:NSLayoutPriorityDefaultLow];
        }
		else
		{
            [heightConstraint setPriority:NSLayoutPriorityDefaultLow + priorityIncrement * distanceOfViewWithIndexFromDividerWithIndex(i, handleIndex)];
        }

        [constraints addObject:heightConstraint];
    }

	[self addSizingConstrants:constraints];
}

- (void)addSizingConstrants:(NSMutableArray *)constraints
{
	if (self.sizingConstraints)
	{
		[self removeConstraints:self.sizingConstraints];
	}
	self.sizingConstraints = constraints;
	if (constraints)
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

#pragma mark - Overrides

+ (BOOL)requiresConstraintBasedLayout
{
	return YES;
}

- (void)updateConstraints
{
	[super updateConstraints];
	[self updateInternalConstraints];
}

- (void)didAddSubview:(NSView *)subview
{
	[subview setTranslatesAutoresizingMaskIntoConstraints:NO];
	[self addInternalConstraints:nil];
	[super didAddSubview:subview];
}

- (void)willRemoveSubview:(NSView *)subview
{
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
		[self updateSizingContstraintsForHandleIndex:handleIndex];

		NSView *viewAboveDivider = [self subviews][handleIndex];
		if (self.orientation == ALSplitViewOrientationVertical)
		{
			self.draggingConstraint = [[[NSLayoutConstraint constraintsWithVisualFormat:@"V:[viewAboveDivider]-100-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(viewAboveDivider)] lastObject] retain];
			self.draggingConstraint.constant = location.y + [self handleWidth] / 2.f;
		}
		else
		{
			self.draggingConstraint = [[[NSLayoutConstraint constraintsWithVisualFormat:@"H:[viewAboveDivider]-100-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(viewAboveDivider)] lastObject] retain];
			[self.draggingConstraint setConstant:(self.frame.size.width - location.x + [self handleWidth] / 2.f)];
		}
		[self.draggingConstraint setPriority:NSLayoutPriorityDefaultHigh];

		[self addConstraint:self.draggingConstraint];
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
		if (self.orientation == ALSplitViewOrientationVertical)
		{
			[self.draggingConstraint setConstant:location.y + [self handleWidth] / 2.f];
		}
		else
		{
			[self.draggingConstraint setConstant:(self.frame.size.width - location.x + [self handleWidth] / 2.f)];
		}
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
		[self removeConstraint:self.draggingConstraint];
		self.draggingConstraint = nil;

		[self updateSizingContstraintsForHandleIndex:-2];
		[self addInternalConstraints:nil];
	}
	else
	{
		[super mouseUp:theEvent];
	}
}

@end