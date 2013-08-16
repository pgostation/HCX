//
//  HCXField.m
//  stackimport
//
//  Created by pgo on 2013/04/03.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXField.h"

@implementation HCXField

- (HCXField *) init
{
	if(( self = [super init] ))
	{
        self.objectType = @"field";
        _styleList = [[NSMutableArray alloc] init];
    }
    
	return self;
}

@end
