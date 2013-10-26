//
//  LVTextView.m
//  Leviathan
//
//  Created by Steven Degutis on 10/17/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "LVTextView.h"

#import "atom.h"

#import "LVThemeManager.h"
#import "LVHighlighter.h"
#import "LVPreferences.h"




@interface LVShortcut : NSObject

@property id target;
@property SEL action;

@property NSString* title;
@property NSString* keyEquiv;
@property NSArray* mods;

@end

@implementation LVShortcut
@end

@interface LVTextView ()

@property NSUndoManager* myUndos; // TODO: unused?
@property NSMutableArray* shortcuts;

@end

@implementation LVTextView

- (BOOL) becomeFirstResponder {
    BOOL did = [super becomeFirstResponder];
    if (did) {
        [self.customDelegate textViewWasFocused:self];
    }
    return did;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) defaultsFontChanged:(NSNotification*)note {
    NSRange fullRange = NSMakeRange(0, [self.textStorage length]);
    [self.textStorage addAttribute:NSFontAttributeName
                             value:[LVPreferences userFont]
                             range:fullRange];
}

- (void) awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsFontChanged:) name:LVDefaultsFontChangedNotification object:nil];
    
    self.enclosingScrollView.verticalScroller.knobStyle = NSScrollerKnobStyleLight;
    self.enclosingScrollView.horizontalScroller.knobStyle = NSScrollerKnobStyleLight;
    
    self.font = [LVPreferences userFont];
    
    self.backgroundColor = [LVThemeManager sharedThemeManager].currentTheme.backgroundColor;
    self.insertionPointColor = [LVThemeManager sharedThemeManager].currentTheme.cursorColor;
    
    self.textColor = [LVThemeManager sharedThemeManager].currentTheme.symbol.color;
    
    {
        NSMutableDictionary* selectionAttrs = [NSMutableDictionary dictionary];
        
        if ([LVThemeManager sharedThemeManager].currentTheme.selection.foregroundColor)
            selectionAttrs[NSForegroundColorAttributeName] = [LVThemeManager sharedThemeManager].currentTheme.selection.foregroundColor;
        
        if ([LVThemeManager sharedThemeManager].currentTheme.selection.backgroundColor)
            selectionAttrs[NSBackgroundColorAttributeName] = [LVThemeManager sharedThemeManager].currentTheme.selection.backgroundColor;
        
        self.selectedTextAttributes = selectionAttrs;
    }
    
    
    
    
    
    [self sd_disableLineWrapping];
    [super setTextContainerInset:NSMakeSize(0.0f, 4.0f)];
    
    
    self.shortcuts = [NSMutableArray array];
    
    [self addParedit:self action:@selector(outBackwardSexp:) title:@"Out Backward" keyEquiv:@"u" mods:@[@"CTRL", @"ALT"]];
    [self addParedit:self action:@selector(forwardSexp:) title:@"Forward" keyEquiv:@"f" mods:@[@"CTRL", @"ALT"]];
    [self addParedit:self action:@selector(backwardSexp:) title:@"Backward" keyEquiv:@"b" mods:@[@"CTRL", @"ALT"]];
//    [self addParedit:^(NSEvent* event){ [_self outForwardSexp:event]; } title:@"Out Forward" keyEquiv:@"n" mods:NSControlKeyMask | NSAlternateKeyMask];
//    [self addParedit:^(NSEvent* event){ [_self inForwardSexp:event]; } title:@"In Forward" keyEquiv:@"d" mods:NSControlKeyMask | NSAlternateKeyMask];
//    [self addParedit:^(NSEvent* event){ [_self inBackwardSexp:event]; } title:@"In Backward" keyEquiv:@"p" mods:NSControlKeyMask | NSAlternateKeyMask];
    
//    [self addParedit:^(NSEvent* event){ [_self raiseSexp:event]; } title:@"Raise" keyEquiv:@"r" mods:NSControlKeyMask];
//    [self addParedit:^(NSEvent* event){ [_self spliceSexp:event]; } title:@"Splice" keyEquiv:@"s" mods:NSControlKeyMask];
//    [self addParedit:^(NSEvent* event){ [_self killNextSexp:event]; } title:@"Kill Next" keyEquiv:@"k" mods:NSControlKeyMask | NSAlternateKeyMask];
//    [self addParedit:^(NSEvent* event){ [_self wrapNextInParens:event]; } title:@"Wrap Next in Parens" keyEquiv:@"9" mods:NSControlKeyMask];
//    [self addParedit:^(NSEvent* event){ [_self wrapNextInBrackets:event]; } title:@"Wrap Next in Brackets" keyEquiv:@"[" mods:NSControlKeyMask];
//    [self addParedit:^(NSEvent* event){ [_self wrapNextInBraces:event]; } title:@"Wrap Next in Braces" keyEquiv:@"{" mods:NSControlKeyMask];
//    [self addParedit:^(NSEvent* event){ [_self extendSelectionToNext:event]; } title:@"Extend Seletion to Next" keyEquiv:@" " mods:NSControlKeyMask | NSAlternateKeyMask];
}



- (void) addParedit:(id)target action:(SEL)action title:(NSString*)title keyEquiv:(NSString*)keyEquiv mods:(NSArray*)mods {
    LVShortcut* shortcut = [[LVShortcut alloc] init];
    shortcut.title = title;
    shortcut.keyEquiv = keyEquiv;
    shortcut.target = target;
    shortcut.action = action;
    shortcut.mods = mods;
    [self.shortcuts addObject:shortcut];
    
    NSMenu* menu = [[[NSApp menu] itemWithTitle:@"Paredit"] submenu];
    NSMenuItem* item = [menu insertItemWithTitle:shortcut.title action:shortcut.action keyEquivalent:shortcut.keyEquiv atIndex:0];
    NSUInteger realMods = 0;
    if ([mods containsObject:@"CTRL"]) realMods |= NSControlKeyMask;
    if ([mods containsObject:@"ALT"]) realMods |= NSAlternateKeyMask;
    [item setKeyEquivalentModifierMask:realMods];
    
    // TODO: insert the target into the responder chain, between self and self.nextResponder
}

- (void) keyDown:(NSEvent *)theEvent {
    for (LVShortcut* shortcut in self.shortcuts) {
        if (![[theEvent charactersIgnoringModifiers] isEqualToString: shortcut.keyEquiv])
            continue;
        
        for (NSString* key in shortcut.mods) {
            if ([key isEqualToString: @"CTRL"] && ([theEvent modifierFlags] & NSControlKeyMask) == 0) continue;
            if ([key isEqualToString: @"ALT"] && ([theEvent modifierFlags] & NSAlternateKeyMask) == 0) continue;
        }
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [shortcut.target performSelector:shortcut.action
                              withObject:theEvent];
#pragma clang diagnostic pop
        
        return;
    }
    
    [super keyDown:theEvent];
}







- (void) insertNewline:(id)sender {
    [super insertNewline:sender];
    [self indentCurrentBody];
}

//- (IBAction) undo:(id)sender {
//    
//    [[self undoManager] undo];
//    
//    NSLog(@"undo");
//}
//
//- (IBAction) redo:(id)sender {
//    [[self undoManager] redo];
//    
//    NSLog(@"redo");
//}

- (void) sd_r:(NSRange)r str:(NSString*)str rehighlight:(BOOL)rehighlight {
    [[self undoManager] setActionIsDiscardable:YES];
      
    NSRange newrange = r;
    r.length = str.length;
    [[[self undoManager] prepareWithInvocationTarget:self] sd_r:newrange
                                                            str:[self.textStorage.string substringWithRange:newrange]
                                                    rehighlight:YES];
    
    [[[self textStorage] mutableString] replaceCharactersInRange:r withString:str];
    
    if (rehighlight)
        LVHighlight((void*)self.file.topLevelElement, self.textStorage, 0);
    
//    self.selectedRange = r;
//    [super delete:nil];
//    [super insertText:str];
}

- (void) insertText:(id)insertString {
    size_t childsIndex;
    size_t relativePos;
    LVColl* coll = LVFindDeepestColl(self.file.topLevelElement, 0, self.selectedRange.location, &childsIndex, &relativePos);
    
    
//    printf("coll=%p, idx=%lu, rel=%lu\n", coll, childsIndex, relativePos);
    size_t collPos = LVGetAbsolutePosition((void*)coll);
    printf("%ld\n", collPos);
    
//    LVElement* tmp = coll->children[childsIndex];
//    coll->children[childsIndex] = coll->children[childsIndex+2];
//    coll->children[childsIndex+2] = tmp;
    
    NSRange range = NSMakeRange(collPos, LVElementLength((void*)coll));
    
    LVAtom* atom = (void*)coll->children[childsIndex];
    atom->token->string->data[0]++;
//    binsertch(atom->token->string, 0, 1, 'a');
    
    NSRange oldSelection = self.selectedRange;
    
    bstring str = LVStringForColl(coll);
    NSString* newStr = [NSString stringWithUTF8String:(char*)str->data];
    
//    NSTextStorage* ts = [self textStorage];
//    [[ts mutableString] replaceCharactersInRange:range withString:newStr];
    
    [self sd_r:range str:newStr rehighlight:NO];
    
//    [self replaceRange:range withString:newStr];
    bdestroy(str);
    
    LVHighlightSomeChild((void*)coll, [self textStorage], collPos);
    
    self.selectedRange = oldSelection;
    
//    @autoreleasepool {
//        [super insertText:insertString];
//        [self indentCurrentBody];
//    }
}

- (void) deleteWordBackward:(id)sender {
    [super deleteWordBackward:sender];
    [self indentCurrentBody];
}

- (void) deleteBackward:(id)sender {
    [super deleteBackward:sender];
    [self indentCurrentBody];
}








//NSUInteger LVFirstNewlineBefore(NSString* str, NSUInteger pos) {
//    NSUInteger found = [str rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]
//                                            options:NSBackwardsSearch
//                                              range:NSMakeRange(0, pos)].location;
//    if (found == NSNotFound)
//        found = 0;
//    else
//        found++;
//    
//    return found;
//}

//BOOL LVIsFunctionLike(LVColl* coll) {
//    // we already assume its a coll with 2+ childs
//    id<LVElement> firstChild = [[coll childElements] objectAtIndex:0];
//    if (![firstChild isAtom])
//        return NO;
//    
//    LVAtom* atomChild = firstChild;
//    
//    static NSArray* functionLikes;
//    if (!functionLikes)
//        functionLikes = @[@"let", @"if", @"if-let", @"cond", @"case"
////    , @"let", @"describe"
//                          ];
//    
//    return ([functionLikes containsObject: [atomChild token].val]);
//}

NSRange LVExtendRangeToBeginningPos(NSRange r, NSUInteger pos) {
    return NSMakeRange(pos, r.length + (r.location - pos));
}

NSRange LVRangeWithNewAbsoluteLocationButSameEndPoint(NSRange r, NSUInteger absPosWithin) {
    // 1 [2 -3- 4 5]
    return NSMakeRange(absPosWithin, NSMaxRange(r) - absPosWithin);
}

- (void) indentCurrentBody {
//    return;
//    NSLog(@"indenting");
//    
//    NSRange selection = self.selectedRange;
//    NSUInteger childIndex;
//    LVColl* currentColl = [self.file.topLevelElement deepestCollAtPos:selection.location childsIndex:&childIndex];
//    LVColl* highestParentColl = [currentColl highestParentColl];
//    
//    NSString* wholeString = [[self textStorage] string];
//    
//    NSRange wholeBlockRange = highestParentColl.fullyEnclosedRange;
//    
//    NSUInteger firstNewlinePosition = LVFirstNewlineBefore(wholeString, wholeBlockRange.location);
//    
//    wholeBlockRange = LVExtendRangeToBeginningPos(wholeBlockRange, firstNewlinePosition);
//    
////    NSLog(@"[%@]", [wholeString substringWithRange:wholeBlockRange]);
//    
//    NSUInteger currentPos = wholeBlockRange.location;
//    
//    while (NSLocationInRange(currentPos, wholeBlockRange)) {
//        NSRange remainingRange = LVRangeWithNewAbsoluteLocationButSameEndPoint(wholeBlockRange, currentPos);
//        
//        NSUInteger nextNewlinePosition = [wholeString rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]
//                                                                      options:0
//                                                                        range:remainingRange].location;
//        
//        if (nextNewlinePosition == NSNotFound)
//            nextNewlinePosition = NSMaxRange(wholeBlockRange);
//        else
//            nextNewlinePosition++;
//        
//        NSRange currentLineRange = NSMakeRange(currentPos, nextNewlinePosition - currentPos);
//        
//        
//        // get first non-space char's pos (absolute)
//        
//        NSUInteger firstNonSpaceCharPos = [wholeString rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]
//                                                                       options:0
//                                                                         range:currentLineRange].location;
//        
//        if (firstNonSpaceCharPos == NSNotFound) {
//            firstNonSpaceCharPos = NSMaxRange(currentLineRange);
//        }
//        
//        // get that val relative
//        
//        NSUInteger firstNonSpaceCharPosRelative = firstNonSpaceCharPos - currentPos;
//        
//        // get coll parent for beginning of line (its type info and indentation info will be helpful soon)
//        
//        NSUInteger childIndexOfFirstElementOnLine;
//        LVColl* collParentForBeginningOfLine = [self.file.topLevelElement deepestCollAtPos:currentPos childsIndex:&childIndexOfFirstElementOnLine];
//        
//        
//        
//        // figure out proper indentation level
//        
//        
//        NSUInteger expectedStartSpaces;
//        
//        if (collParentForBeginningOfLine.collType == LVCollTypeTopLevel) {
//            expectedStartSpaces = 0;
//        }
//        else {
//            NSUInteger openingTokenRecentNewline = LVFirstNewlineBefore(wholeString, collParentForBeginningOfLine.openingToken.range.location);
//            NSUInteger prefixIndentation = collParentForBeginningOfLine.openingToken.range.location - openingTokenRecentNewline;
//            
//            if (collParentForBeginningOfLine.collType == LVCollTypeList) {
//                if ([collParentForBeginningOfLine isKindOfClass:[LVDefinition self]] || LVIsFunctionLike(collParentForBeginningOfLine)) {
//                    expectedStartSpaces = prefixIndentation + 2;
//                }
//                else if ([[collParentForBeginningOfLine childElements] count] >= 2 && childIndexOfFirstElementOnLine >= 2) {
//                    id<LVElement> secondChild = [[collParentForBeginningOfLine childElements] objectAtIndex: 1];
//                    NSUInteger childBeginning = [secondChild fullyEnclosedRange].location;
//                    NSUInteger newlineBeforeSecondChild = LVFirstNewlineBefore(wholeString, childBeginning);
//                    
//                    expectedStartSpaces = childBeginning - newlineBeforeSecondChild;
//                }
//                else {
//                    expectedStartSpaces = prefixIndentation + 2;
//                }
//            }
//            else {
//                expectedStartSpaces = prefixIndentation + 1;
//            }
//            
//        }
//        
//        NSInteger spacesToAdd = expectedStartSpaces - firstNonSpaceCharPosRelative;
//        
////        NSLog(@"%ld", spacesToAdd);
//        
//        if (spacesToAdd != 0) {
//            if (spacesToAdd > 0) {
//                NSString* spaces = [@"" stringByPaddingToLength:spacesToAdd withString:@" " startingAtIndex:0];
//                NSRange tempRange = NSMakeRange(currentPos, 0);
//                [self replaceRange:tempRange withString:spaces];
//            }
//            if (spacesToAdd < 0) {
//                // its really spaces to delete, now.
//                NSRange tempRange = NSMakeRange(currentPos, labs(spacesToAdd));
//                [self replaceRange:tempRange withString:@""];
//            }
//            
//            wholeBlockRange.length += spacesToAdd;
//            nextNewlinePosition += spacesToAdd;
//        }
//        
//        // done doing things, ready to loop again.
//        
//        currentPos = nextNewlinePosition;
//        
//    }
//    
//    
//    // TODO: thoughts on a new plan for indentation:
//    //       - edit the list of tokens itself
//    //       - after each child in a coll, search for next newline, before either next child or closing token (if you're at end of coll).
//    //       - if there is no newline, do nothing (you're on the same line!)
//    //       - but if there IS a newline:
//    //           - delete all whitespace BEFORE the newline (yay)
//    //           - calculate the proper number of whitespace after the newline and before the next non-space char
//    //               - if the next non-space char is a newline, erase all those spaces
//    //               - otherwise, add/delete whitespace to make it match
//    //           - OH WAIT: this adding/removing means rewriting the parse-tree :(
//    
//    
////    printf("\n");
}

//- (IBAction) raiseSexp:(id)sender {
//    NSRange selection = self.selectedRange;
//    NSUInteger childIndex;
//    LVColl* coll = [self.file.topLevelElement deepestCollAtPos:selection.location childsIndex:&childIndex];
//    
//    if (childIndex < [coll.childElements count]) {
//        id<LVElement> child = [coll.childElements objectAtIndex:childIndex];
//        
//        NSString* newStr = [[[self textStorage] string] substringWithRange:[child fullyEnclosedRange]];
//        
//        NSRange range = NSUnionRange(coll.openingToken.range, coll.closingToken.range);
//        
//        [self setSelectedRange:range];
//        [self delete:self];
//        
//        NSRange r = [self selectedRange];
//        [self insertText:newStr];
//        [self setSelectedRange:r];
//    }
//}

//- (void) insertText:(id)insertString {
//    NSDictionary* balancers = @{@"(": @")", @"[": @"]", @"{": @"}"};
//    NSString* origString = insertString;
//    NSString* toBalance = [balancers objectForKey:origString];
//    
//    if (toBalance) {
//        NSRange selection = self.selectedRange;
//        NSString* subString = [[[self textStorage] string] substringWithRange:selection];
//        
//        if (selection.length == 0) {
//            [super insertText:insertString];
//            [super insertText:toBalance];
//            [self moveBackward:self];
//        }
//        else {
//            NSString* newString = [NSString stringWithFormat:@"%@%@%@", origString, subString, toBalance];
//            [self insertText:newString];
//        }
//        
//        return;
//    }
//    
//    if ([[balancers allKeysForObject:origString] count] > 0) {
//        NSUInteger loc = self.selectedRange.location;
//        NSString* wholeString = [[self textStorage] string];
//        
//        if (loc < [wholeString length]) {
//            unichar c = [wholeString characterAtIndex:loc];
//            if (c == [origString characterAtIndex:0]) {
//                [self moveForward:self];
//            }
//        }
//        
//        return;
//    }
//    
//    [super insertText:insertString];
//}
//
//- (void) wrapNextInThing:(NSString*)thing {
//    NSRange selection = self.selectedRange;
//    NSUInteger childIndex;
//    LVColl* coll = [self.file.topLevelElement deepestCollAtPos:selection.location childsIndex:&childIndex];
//    
//    if (childIndex < [coll.childElements count]) {
//        id<LVElement> element = [coll.childElements objectAtIndex:childIndex];
//        
//        NSRange rangeToTempDelete = [element fullyEnclosedRange];
//        NSString* theStr = [[[self textStorage] string] substringWithRange:rangeToTempDelete];
//        
//        self.selectedRange = rangeToTempDelete;
//        [self delete:self];
//        [self insertText:[NSString stringWithFormat:thing, theStr]];
//        
//        NSRange rangeToSelect = NSMakeRange(rangeToTempDelete.location + 1, 0);
//        
//        self.selectedRange = rangeToSelect;
//        [self scrollRangeToVisible:self.selectedRange];
//    }
//}
//
//- (IBAction) spliceSexp:(id)sender {
//    NSRange selection = self.selectedRange;
//    NSUInteger childIndex;
//    LVColl* coll = [self.file.topLevelElement deepestCollAtPos:selection.location childsIndex:&childIndex];
//    
//    NSRange outerRange = coll.fullyEnclosedRange;
//    NSUInteger start = NSMaxRange(coll.openingToken.range);
//    NSRange innerRange = NSMakeRange(start, coll.closingToken.range.location - start);
//    
//    NSString* newStr = [[[self textStorage] string] substringWithRange:innerRange];
//    
//    self.selectedRange = outerRange;
//    [self delete:sender];
//    [self insertText:newStr];
//    
//    self.selectedRange = NSMakeRange(outerRange.location, 0);
//    [self scrollRangeToVisible:self.selectedRange];
//}
//
//- (IBAction) extendSelectionToNext:(id)sender {
//    NSRange selection = self.selectedRange;
//    NSUInteger childIndex;
//    LVColl* coll = [self.file.topLevelElement deepestCollAtPos:NSMaxRange(selection) childsIndex:&childIndex];
//    
//    if (childIndex < [coll.childElements count]) {
//        id<LVElement> child = [coll.childElements objectAtIndex:childIndex];
//        NSRange newRange = NSUnionRange(selection, [child fullyEnclosedRange]);
//        
//        self.selectedRange = newRange;
//        [self scrollRangeToVisible:self.selectedRange];
//    }
//}
//
//- (IBAction) cancelOperation:(id)sender {
//    self.selectedRange = NSMakeRange(self.selectedRange.location, 0);
//}
//
//- (IBAction) wrapNextInBrackets:(id)sender {
//    [self wrapNextInThing:@"[%@]"];
//}
//
//- (IBAction) wrapNextInBraces:(id)sender {
//    [self wrapNextInThing:@"{%@}"];
//}
//
//- (IBAction) wrapNextInParens:(id)sender {
//    [self wrapNextInThing:@"(%@)"];
//}

- (void) forwardSexp:(NSEvent*)event {
    NSRange selection = self.selectedRange;
    size_t childIndex;
    size_t relativePos;
    
    LVColl* coll = LVFindDeepestColl(self.file.topLevelElement, 0, selection.location, &childIndex, &relativePos);
    
    LVElement* elementToMoveToEndOf = NULL;
    size_t posAfterElement;
    
    while (YES) {
        if (childIndex == coll->children_len)
            break;
        
        LVElement* element = coll->children[childIndex];
        
        if (element->is_atom && !LVAtomIsSemantic((void*)element)) {
            childIndex++;
            continue;
        }
        // we're a semantic element!
        
        // TODO: tidy this up with LVGetSemanticDirectChildren(parent, startingPos, &array, &count) where array is a local var (size = parent->children_len)
        
        posAfterElement = LVGetAbsolutePosition(element) + LVElementLength(element);
        
        // are we in the middle of the semantic element?
        if (selection.location < posAfterElement) {
            // if so, great! we'll use this one
            elementToMoveToEndOf = element;
            break;
        }
        // guess we're at its end, check the next one maybe?
        
        childIndex++;
    }
    
    if (elementToMoveToEndOf) {
        self.selectedRange = NSMakeRange(posAfterElement, 0);
        [self scrollRangeToVisible:self.selectedRange];
    }
    else {
//        [self outForwardSexp:sender];
    }
}

- (void) backwardSexp:(NSEvent*)event {
//    NSRange selection = self.selectedRange;
//    NSUInteger childIndex;
//    LVColl* coll = [self.file.topLevelElement deepestCollAtPos:selection.location childsIndex:&childIndex];
//    
//    if (childIndex > 0) {
//        id<LVElement> element = [coll.childElements objectAtIndex:childIndex - 1];
//        self.selectedRange = NSMakeRange([element fullyEnclosedRange].location, 0);
//        [self scrollRangeToVisible:self.selectedRange];
//    }
//    else {
//        [self outBackwardSexp:sender];
//    }
}

- (void) outBackwardSexp:(NSEvent*)event {
    NSRange selection = self.selectedRange;
    size_t childIndex;
    size_t relativePos;
    
    LVColl* coll = LVFindDeepestColl(self.file.topLevelElement, 0, selection.location, &childIndex, &relativePos);
    size_t absPos = LVGetAbsolutePosition((void*)coll);
    
    self.selectedRange = NSMakeRange(absPos, 0);
    [self scrollRangeToVisible:self.selectedRange];
}

//- (IBAction) outForwardSexp:(id)sender {
//    NSRange selection = self.selectedRange;
//    NSUInteger childIndex;
//    LVColl* coll = [self.file.topLevelElement deepestCollAtPos:selection.location childsIndex:&childIndex];
//    
//    self.selectedRange = NSMakeRange(NSMaxRange([coll fullyEnclosedRange]), 0);
//    [self scrollRangeToVisible:self.selectedRange];
//}
//
//- (IBAction) inForwardSexp:(id)sender {
//    NSRange selection = self.selectedRange;
//    NSUInteger childIndex;
//    LVColl* coll = [self.file.topLevelElement deepestCollAtPos:selection.location childsIndex:&childIndex];
//    
//    if (childIndex < [coll.childElements count]) {
//        LVColl* childColl;
//        for (NSUInteger i = childIndex; i < [[coll childElements] count]; i++) {
//            id<LVElement> child = [[coll childElements] objectAtIndex:i];
//            if ([child isColl]) {
//                childColl = child;
//                break;
//            }
//        }
//        
//        if (childColl) {
//            self.selectedRange = NSMakeRange(NSMaxRange([childColl openingToken].range), 0);
//            [self scrollRangeToVisible:self.selectedRange];
//        }
//    }
//}
//
//- (IBAction) inBackwardSexp:(id)sender {
//    NSRange selection = self.selectedRange;
//    NSUInteger childIndex;
//    LVColl* coll = [self.file.topLevelElement deepestCollAtPos:selection.location childsIndex:&childIndex];
//    
//    if (childIndex > 0) {
//        LVColl* childColl;
//        for (NSInteger i = childIndex - 1; i >= 0; i--) {
//            id<LVElement> child = [[coll childElements] objectAtIndex:i];
//            if ([child isColl]) {
//                childColl = child;
//                break;
//            }
//        }
//        
//        if (childColl) {
//            self.selectedRange = NSMakeRange([childColl closingToken].range.location, 0);
//            [self scrollRangeToVisible:self.selectedRange];
//        }
//    }
//}
//
//- (IBAction) killNextSexp:(id)sender {
//    NSRange selection = self.selectedRange;
//    NSUInteger childIndex;
//    LVColl* coll = [self.file.topLevelElement deepestCollAtPos:selection.location childsIndex:&childIndex];
//    
//    if (childIndex < [coll.childElements count]) {
//        id<LVElement> element = [coll.childElements objectAtIndex:childIndex];
//        
//        NSRange rangeToDelete = [element fullyEnclosedRange];
//        self.selectedRange = rangeToDelete;
//        [self delete:sender];
//        self.selectedRange = NSMakeRange(rangeToDelete.location, 0);
//        [self scrollRangeToVisible:self.selectedRange];
//    }
//}
//
//- (void) deleteToEndOfParagraph:(id)sender {
//    NSRange selection = self.selectedRange;
//    NSUInteger childIndex;
//    LVColl* coll = [self.file.topLevelElement deepestCollAtPos:selection.location childsIndex:&childIndex];
//    
//    if (childIndex < [coll.childElements count]) {
//        //        NSArray* deleteChildren = [coll.childElements subarrayWithRange:NSMakeRange(childIndex, [coll.childElements count] - childIndex)];
//        //        id<SDElement> firstDeletableChild = [deleteChildren objectAtIndex:0];
//        //        NSRange range = NSUnionRange([firstDeletableChild fullyEnclosedRange], NSMakeRange([coll closingToken].range.location, 0));
//        
//        NSRange range = NSUnionRange(selection, NSMakeRange([coll closingToken].range.location, 0));
//        
//        if ([self shouldChangeTextInRange:range replacementString:@""]) {
//            [[self textStorage] replaceCharactersInRange:range withString:@""];
//            [self didChangeText];
//        }
//    }
//}

- (void) sd_disableLineWrapping {
    [[self enclosingScrollView] setHasHorizontalScroller:YES];
    [self setHorizontallyResizable:YES];
    NSSize layoutSize = [self maxSize];
    layoutSize.width = layoutSize.height;
    [self setMaxSize:layoutSize];
    [[self textContainer] setWidthTracksTextView:NO];
    [[self textContainer] setContainerSize:layoutSize];
}

@end
