//
//  HCXCard.h
//  HCX
//
//  Created by pgo on 2013/04/13.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXCardBase.h"
//#import "HCXBackground.h"

@class HCXBackground;

@interface HCXCard : HCXCardBase

@property NSMutableArray *bgPartsList;
@property NSInteger bgId;
@property bool marked;

- (NSInteger) numberInStack;

@end
