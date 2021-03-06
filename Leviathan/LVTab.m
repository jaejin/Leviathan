//
//  LVTabEntryViewController.m
//  Leviathan
//
//  Created by Steven Degutis on 10/17/13.;
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "LVTab.h"

@interface LVTab ()

@property (weak) IBOutlet NSSplitView* topLevelSplitView;

@property NSMutableArray* editors;

@property (weak) LVEditor* currentEditor;

@end

@implementation LVTab

@synthesize editors = sd_editors;

- (id) init {
    if (self = [super init]) {
        self.editors = [NSMutableArray array];
    }
    return self;
}

- (NSString*) nibName {
    return @"Tab";
}

- (void) startWithEditor:(LVEditor*)editor {
    [self view]; // force loading view :(
    
    editor.delegate = self;
    
    [self.editors addObject: editor];
    
    [self.topLevelSplitView addSubview: editor.view];
    [self.topLevelSplitView adjustSubviews];
    
    [self switchToEditor:editor];
}

- (void) switchToEditor:(LVEditor*)editor {
    self.currentEditor = editor;
    self.nextResponder = self.currentEditor;
    
    [self.currentEditor makeFirstResponder];
    [self.delegate currentEditorChanged: self];
    
    // TODO: uhh.. do more stuff here?
}

- (void) makeFirstResponder {
    [self.currentEditor makeFirstResponder];
}

- (void) addEditor:(LVEditor*)editor inDirection:(LVSplitDirection)dir {
    editor.delegate = self;
    
    [self.editors addObject: editor];
    
    [self.topLevelSplitView addSubview: editor.view];
    [self.topLevelSplitView adjustSubviews];
    
    NSUInteger numEditors = [self.editors count];
    
    for (int i = 0; i < numEditors - 1; i++) {
        CGFloat percent = ((i + 1.0f) / (CGFloat)numEditors);
        [self.topLevelSplitView setPosition:([self.topLevelSplitView frame].size.width * percent)
                           ofDividerAtIndex:i];
    }
    
    [self switchToEditor:editor];
}

- (IBAction) selectNextSplit:(id)sender {
    NSUInteger idx = [self.editors indexOfObject:self.currentEditor];
    idx++;
    if (idx == [self.editors count])
        idx = 0;
    
    [self switchToEditor:[self.editors objectAtIndex:idx]];
}

- (IBAction) selectPreviousSplit:(id)sender {
    NSUInteger idx = [self.editors indexOfObject:self.currentEditor];
    idx--;
    if (idx == -1)
        idx = [self.editors count] - 1;
    
    [self switchToEditor:[self.editors objectAtIndex:idx]];
}

- (void) closeCurrentSplit {
    [self.currentEditor.view removeFromSuperview];
    [self.editors removeObject:self.currentEditor];
    [self switchToEditor:[self.editors lastObject]];
    [self.currentEditor makeFirstResponder];
}

- (void) editorWasSelected:(LVEditor*)editor {
    self.currentEditor = editor;
    [self.delegate currentEditorChanged: self];
}

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex {
    CGFloat r = 6.0;
    
    proposedEffectiveRect.origin.x -= r;
    proposedEffectiveRect.size.width += (r * 2.0);
    return proposedEffectiveRect;
}

@end
