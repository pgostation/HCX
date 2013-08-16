//
//  CardView.h
//  HCX
//
//  Created by pgo on 2013/04/18.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StackEnv;

@interface CardView : NSView

- (void) openFirstCard: (StackEnv *) stack;
- (void) openCard: (StackEnv *) stack cardId: (NSInteger) cardId;

@end
