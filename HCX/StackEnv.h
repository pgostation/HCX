//
//  StackEnv.h
//  HCX
//
//  Created by pgo on 2013/04/18.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXStackData.h"
#import "CardView.h"

@interface StackEnv : NSObject <NSWindowDelegate>

@property NSInteger pid;
@property NSWindow *cardWindow;
@property HCXStackData *stack;
@property CardView *cardView;
@property CGContextRef offBitmap;
@property BOOL redrawFlag; //透明ボタンの色反転描画用

+ (NSArray *) getStackEnvList;
+ (StackEnv *) currentStackEnv;
- (void) preOpen:(HCXStackData *)stack;
- (void) open:(HCXStackData *)stack;
- (void) sendMessageToCurCard: (NSString *)msg force: (BOOL)force;
+ (StackEnv *) stackEnvById: (NSInteger)stackEnvId;
- (void) showToolWindow;
- (NSInteger) getCurrentCardId;
+ (HCXStackData *) stackById: (NSInteger)stackId;
- (void) setChangeFlag:(BOOL)flag;

@end
