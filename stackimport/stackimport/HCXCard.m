//
//  HCXCard.m
//  stackimport
//
//  Created by pgo on 2013/04/01.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXCard.h"

@implementation HCXCard

- (HCXCard *) init
{
	if(( self = [super init] ))
	{
        _partsList = [[NSMutableArray alloc] init];
        //_bgbtnList = [[NSMutableArray alloc] init];
        _bgfldList = [[NSMutableArray alloc] init];
    }
    
	return self;
}

- (HCXObject *) getPartById:(int)pid
{
    for(int i=0; i<[_partsList count]; i++)
    {
        HCXObject *part = [_partsList objectAtIndex:i];
        if(part.pid == pid)
        {
            return part;
        }
    }
    
    return nil;
}


@end
