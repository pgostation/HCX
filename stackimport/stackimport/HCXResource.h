//
//  HCXResource.h
//  stackimport
//
//  Created by pgo on 2013/03/31.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXXcmd.h"
#import "HCXRes.h"

@interface HCXResource : NSObject

@property NSMutableArray *list;
@property NSMutableArray *xcmdList;

- (void) addResource:(int)resid type:(NSString *)type name:(NSString *)name path:(NSString *)path;

- (void) addCursorResource:(int)resid type:(NSString *)type name:(NSString *)name path:(NSString *)path point:(CGPoint) point;
- (void) addXcmd:(HCXXcmd *)xcmd;

@end
