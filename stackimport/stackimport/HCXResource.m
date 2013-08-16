//
//  HCXResource.m
//  stackimport
//
//  Created by pgo on 2013/03/31.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXResource.h"

@implementation HCXResource

- (HCXResource *) init
{
	if(( self = [super init] ))
	{
        _list = [[NSMutableArray alloc] init];
        _xcmdList = [[NSMutableArray alloc] init];
    }
    
	return self;
}

- (void) addResource:(int)resid type:(NSString *)type name:(NSString *)name path:(NSString *)path
{
    HCXRes *rsrc = [[HCXRes alloc ] init];
    rsrc.resid = resid;
    rsrc.type = type;
    rsrc.name = name;
    NSString* theFileName = [path lastPathComponent];
    rsrc.filename = theFileName;
    
    [_list addObject:rsrc];
}

- (void) addCursorResource:(int)resid type:(NSString *)type name:(NSString *)name path:(NSString *)path point:(CGPoint) point
{
    HCXRes *rsrc = [[HCXRes alloc ] init];
    rsrc.resid = resid;
    rsrc.type = type;
    rsrc.name = name;
    NSString* theFileName = [path lastPathComponent];
    rsrc.filename = theFileName;
    rsrc.hotspotleft = point.x;
    rsrc.hotspottop = point.y;
    
    [_list addObject:rsrc];
}

- (void) addXcmd:(HCXXcmd *)xcmd
{
    [_xcmdList addObject:xcmd];
}

@end
