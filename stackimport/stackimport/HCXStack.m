//
//  HCXStack.m
//  stackimport
//
//  Created by pgo on 2013/03/31.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXStack.h"

@implementation HCXStack

- (HCXStack *) init
{
	if(( self = [super init] ))
	{
        _rsrc = [[HCXResource alloc] init];
        _cardIdList = [[NSMutableArray alloc] init];
        _cardCacheList = [[NSMutableArray alloc] init];
        _cardMarkedList = [[NSMutableArray alloc] init];
        _bgList = [[NSMutableArray alloc] init];
        _fontList = [[NSMutableArray alloc] init];
        _styleList = [[NSMutableArray alloc] init];
        _pageIdList = [[NSMutableArray alloc] init];
        _pageEntryCountList = [[NSMutableArray alloc] init];
    }
    
	return self;
}


- (void) cdCacheListAdd:(HCXCard *)cd;
{
    [_cardCacheList addObject:cd];
}

- (void) AddNewBg:(HCXCard *)bg
{
    [_bgList addObject:bg];
}

- (HCXCard *) GetCardbyId:(int)cardid
{
    for(int i=0; i<[_cardCacheList count]; i++)
    {
        HCXCard *cd = [_cardCacheList objectAtIndex:i];
        if(cd.pid == cardid)
        {
            return cd;
        }
    }
    
    return nil;
}


- (int) GetCardIdList:(int)cardid
{
    for(int i=0; i<[_cardIdList count]; i++)
    {
        NSNumber *number = [_cardIdList objectAtIndex:i];
        if([number intValue] == cardid)
        {
            return [number intValue];
        }
    }
    
    return -1;
}


- (HCXCard *) GetBgbyId:(int)bgid
{
    for(int i=0; i<[_bgList count]; i++)
    {
        HCXCard *bg = [_bgList objectAtIndex:i];
        if(bg.pid == bgid)
        {
            return bg;
        }
    }
    
    return nil;
}

@end
