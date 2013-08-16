//
//  HCXCard.h
//  stackimport
//
//  Created by pgo on 2013/04/01.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXObject.h"

@interface HCXCard : HCXObject

@property NSMutableArray *partsList;
//@property NSMutableArray *bgbtnList;
@property NSMutableArray *bgfldList;
@property NSString *bitmapName;
@property int dontSearch;
@property int showPict;
@property int cantDelete;
@property int bgid;
@property bool marked;


- (HCXObject *) getPartById:(int)pid;

@end
