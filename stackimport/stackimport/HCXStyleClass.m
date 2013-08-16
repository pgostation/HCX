//
//  HCXStyleClass.m
//  stackimport
//
//  Created by pgo on 2013/04/04.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXStyleClass.h"

@implementation HCXStyleClass

- (HCXStyleClass *) init
{
	if(( self = [super init] ))
	{
        self.font = -1;
        self.size = -1;
        self.styleId = -1;
    }
    
	return self;
}

@end
