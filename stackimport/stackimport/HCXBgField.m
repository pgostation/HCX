//
//  HCXBgField.m
//  stackimport
//
//  Created by pgo on 2013/04/04.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXBgField.h"

@implementation HCXBgField

- (HCXBgField *) init
{
	if(( self = [super init] ))
	{
        self.objectType = @"field";
        _styleList = [[NSMutableArray alloc] init];
    }
    
	return self;
}

@end
