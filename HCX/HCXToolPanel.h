//
//  HCXToolPanel.h
//  HCX
//
//  Created by pgo on 2013/04/20.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class StackEnv;
@class HCXToolBtn;

@interface HCXToolPanel : NSPanel <NSWindowDelegate>

+ (void) selectTool: (NSString *)toolName;
+ (NSPanel *) getPanel;
+ (void) clearAllHighlight:(HCXToolBtn *)btn;
- (void) init2;
- (void) change: (StackEnv *) stackEnv;

@end
