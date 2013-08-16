//
//  HCXCard.m
//  HCX
//
//  Created by pgo on 2013/04/13.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXCard.h"
#import "HCXBackground.h"
#import "StackEnv.h"

@implementation HCXCard

- (HCXCard *) init
{
	if(( self = [super init] ))
	{
        self.objectType = ENUM_CARD;
        self.bgPartsList = [[NSMutableArray alloc] init];
    }
    
	return self;
}

- (NSInteger) numberInStack
{
    HCXStackData *stack = [StackEnv stackById:self.parentStackId];
    
    int number = 1;
    for(int i=0; i<[stack.cardList count]; i++)
    {
        if(((HCXCard *)[stack.cardList objectAtIndex:i]).pid==self.pid)
        {
            return number;
        }
        number++;
    }
    
    return -1;
}

@end
