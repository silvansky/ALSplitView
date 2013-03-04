//
//  AdditionalWindowController.m
//  ALSplitViewDemo
//
//  Created by Valentine Gorshkov on 27.02.13.
//  Copyright (c) 2013 silvansky. All rights reserved.
//

#import "AdditionalWindowController.h"
#import "ALSplitView.h"

#import <WebKit/WebKit.h>

@interface AdditionalWindowController ()

@property (retain) NSMutableArray *outlineViewData;

@end

@implementation AdditionalWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	self = [super initWithWindowNibName:windowNibName];
	if (self)
	{
		self.outlineViewData = [NSMutableArray arrayWithCapacity:10000];
		for (NSInteger i = 0; i < 10000; i++)
		{
			[self.outlineViewData addObject:[NSString stringWithFormat:@"Element %ld", i]];
		}
	}
	return self;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	[self.webView setMainFrameURL:@"http://news.google.com"];
	[self.splitView setMinimumWidth:200.f forViewAtIndex:0];
	[self.splitView setMaximumWidth:400.f forViewAtIndex:0];
	[self.splitView setMinimumWidth:400.f forViewAtIndex:1];
	self.splitView.handleColor = [NSColor whiteColor];
	self.splitView.handleWidth = 1.f;
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (!item)
	{
		return [self.outlineViewData count];
	}
	else
	{
		return 0;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (!item)
	{
		return self.outlineViewData[index];
	}
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return NO;
}

#pragma mark - NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSTableCellView *view;
	view = [outlineView makeViewWithIdentifier:@"cell" owner:self];
	NSString *s = item;
	view.textField.stringValue = s;
	view.imageView.image = [NSImage imageNamed:@"dog"];
	return view;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	return 63.f;
}

@end
