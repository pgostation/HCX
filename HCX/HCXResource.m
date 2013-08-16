//
//  HCXResource.m
//  HCX
//
//  Created by pgo on 2013/04/14.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXResource.h"

@implementation HCXResource

- (HCXResource *) init
{
	if(( self = [super init] ))
	{
        self.rsrcDic = [[NSMutableDictionary alloc] init];
    }
    
	return self;
}

- (void) addMediaFromXML:(HCXRes *)media
{
    NSMutableDictionary *typeDic = [_rsrcDic objectForKey:media.type];
    if(typeDic == nil)
    {
        typeDic = [[NSMutableDictionary alloc] init];
        [_rsrcDic setObject:typeDic forKey:media.type];
    }
    
    [typeDic setObject:media forKey:media.nsid];
}

@end
