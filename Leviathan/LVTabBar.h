//
//  LVTabBar.h
//  Leviathan
//
//  Created by Steven Degutis on 10/17/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol LVTabBarDelegate <NSObject>

- (void) movedTab:(NSUInteger)from to:(NSUInteger)to;
- (void) selectedTab:(NSUInteger)tabIndex;

@end

@interface LVTabBar : NSView

@property (weak) id<LVTabBarDelegate> delegate;

- (void) addTab:(NSString*)title;
- (void) closeCurrentTab;

- (void) manuallySelectTab:(NSUInteger)tabIndex;

@end
