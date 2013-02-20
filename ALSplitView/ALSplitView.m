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
	if (index >= [[self subviews] count])
	{
		NSLog(@"ALSplitView: setMinimumWidth:forViewAtIndex: index out of boundaries!");
		return;
	}
	NSView *view = [self subviews][index];
	NSDictionary *metrics = @{ @"minWidth" : @(width) };
	NSArray *newConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[view(>=minWidth)]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(view)];
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
	}
	else
	{
		[super mouseUp:theEvent];
	}
}

@end
