//
//  HCXScript.h
//  HCX
//
//  Created by pgo on 2013/04/20.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StackEnv.h"

@interface HCXScript : NSObject

+ (NSDictionary *) getGlobals;

- (HCXScript *) initWithStackEnv:(StackEnv *) stackEnv;
- (void) doMsg: (NSString *)msg force: (BOOL)force stackEnv:(StackEnv *) env;
- (NSInteger) currentCardId;

@end
