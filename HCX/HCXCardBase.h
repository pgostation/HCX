//
//  HCXCardBase.h
//  HCX
//
//  Created by pgo on 2013/04/13.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXObject.h"

@class HCXPart;

@interface HCXCardBase : HCXObject

@property NSInteger parentStackId; //add
@property NSMutableArray *partsList;
@property NSString *bitmapName;
@property bool showPict;
@property bool cantDelete;
@property bool dontSearch;

- (void) setContentFromXML:(HCXObject *)obj;
- (NSInteger) nextPartId;
- (HCXPart *) getPartById: (NSInteger) partId;

@end
