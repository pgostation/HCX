//
//  HCXBackground.m
//  HCX
//
//  Created by pgo on 2013/04/13.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXBackground.h"
#import "HCXStackData.h"
#import "StackEnv.h"

@implementation HCXBackground

- (HCXBackground *) init
{
	if(( self = [super init] ))
	{
        self.objectType = ENUM_BACKGROUND;
    }
    
	return self;
}

- (NSInteger) numberInStack
{
    HCXStackData *stack = [StackEnv stackById:self.parentStackId];
    
    int number = 1;
    for(int i=0; i<[stack.bgList count]; i++)
    {
        if(((HCXBackground *)[stack.bgList objectAtIndex:i]).pid==self.pid)
        {
            return number;
        }
        number++;
    }
    
    return -1;
}

@end
