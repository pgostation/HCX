//
//  HCXButton.m
//  stackimport
//
//  Created by pgo on 2013/04/03.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXButton.h"

@implementation HCXButton

- (HCXButton *) init
{
	if(( self = [super init] ))
	{
        self.objectType = @"button";
    }
    
	return self;
}

@end
