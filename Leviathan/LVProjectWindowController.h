//
//  LVProjectWindowController.h
//  Leviathan
//
//  Created by Steven Degutis on 10/17/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LVProject.h"

extern NSString* LVTabTitleChangedNotification;

@class LVProjectWindowController;
@protocol LVProjectWindowController <NSObject>

- (void) projectWindowClosed:(LVProjectWindowController*)controller;

@end



@interface LVProjectWindowController : NSWindowController <NSWindowDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate>

+ (LVProjectWindowController*) openWith:(NSURL*)url delegate:(id<LVProjectWindowController>)delegate;

@property LVProject* project;

- (BOOL) tryClosingCompletely;

- (void) editFileWithLongName:(NSString*)subpath;

@end
