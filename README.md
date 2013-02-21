# ALSplitView - an autolayout based NSSplitView replacement

ALSplitView custom view requires autolayout enabled in a xib it is added to. Note that autolayout is available since OS X 10.7 and not supported on 10.6 or older.

NSSplitView is a buggy thing when it comes to autolayout, so I've decided to write my own split view based on autolayout features. This repo contains also a demo project, which shows a typical ALSplitView use cases.

The source code of ALSplitView is distributed under [MIT License](http://en.wikipedia.org/wiki/MIT_License). See file LICENSE for more information.

Horizontal oriented:

![horizontal](https://raw.github.com/silvansky/ALSplitView/master/screenshot_h.png)

Vertical oriented:

![vertical](https://raw.github.com/silvansky/ALSplitView/master/screenshot_v.png)

## Main features:

- unlimited number of subviews
- both vertical and horizontal orientations
- on-the-fly properties handling
- styling handles with background color, background image and handle image
- minimum and maximum size limits support for subviews
- save/restore subview sizes with plist-ready NSDictionary

## Usage example:

``` obj-c
// assuming splitView, leftView and rightView are IBOutlets
self.splitView.orientation = ALSplitViewOrientationHorizontal;
self.splitView.handleWidth = 10.f;
self.splitView.handleBackgroundImage = [NSImage imageNamed:@"handle-background"];
[self.splitView addSubview:self.leftView];
[self.splitView addSubview:self.rightView];
[self.splitView setMinimumWidth:200.f forViewAtIndex:0];
[self.splitView setMinimumWidth:250.f forViewAtIndex:1];
```

## Known bugs:

- sometimes constraints throw strange exceptions
- in some cases handles can stuck
- can be unpredictable if too many scrollviews added
- size limits are lost on split view orientation changed
