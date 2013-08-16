//
//  HCXXcmd.m
//  stackimport
//
//  Created by pgo on 2013/03/31.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXXcmd.h"

@implementation HCXXcmd

- (HCXXcmd *) initWithId: (int)resid type:(NSString *)type name:(NSString *)name filename:(NSString *)filename platform:(NSString *)platform length:(int)datalen
{
	if(( self = [super init] ))
	{
        self.xcmdid = resid;
        self.type = type;
        self.name = name;
        self.filename = filename;
        self.platform = platform;
        self.size = datalen;
        return self;
    }
    
    return nil;
}

@end
