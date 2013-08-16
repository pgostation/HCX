//
//  HCXUIField.h
//  HCX
//
//  Created by pgo on 2013/04/20.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HCXField;
@class HCXStackData;

@interface HCXUIField : NSTextView

@property NSInteger partId;

- (void) setStackEnv: (NSInteger)in_stackEnvId;
- (void) setStyle: (HCXField *)fldData stack:(HCXStackData *)stack isBg:(BOOL) in_isBg;

+ (void) setDrawBorder: (BOOL) b;
+ (void) setHover: (BOOL) b;
+ (void) clearSelectedField;

@end
