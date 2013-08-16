//
//  HCXRes.h
//  stackimport
//
//  Created by pgo on 2013/04/01.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HCXRes : NSObject

@property int resid;
@property NSString *type;
@property NSString *name;
@property NSString *filename;

//CURS
@property int hotspotleft;
@property int hotspottop;

@end
