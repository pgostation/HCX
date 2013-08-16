//
//  HCXCardBase.m
//  HCX
//
//  Created by pgo on 2013/04/13.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXCardBase.h"
#import "HCXPart.h"

@implementation HCXCardBase

- (HCXCardBase *) init
{
	if(( self = [super init] ))
	{
        self.partsList = [[NSMutableArray alloc] init];
    }
    
	return self;
}

- (void) setContentFromXML:(HCXObject *)contentObj
{
    if( [contentObj.text length] > 0 )
    {
        for(HCXPart *part in _partsList)
        {
            if(part.pid == contentObj.pid)
            {
                part.text = contentObj.text;
                contentObj.text = nil;
            }
        }
    }
}

- (NSInteger) nextPartId
{
    NSInteger maxPid = 0;
    for(HCXPart *part in _partsList)
    {
        if(part.pid > maxPid)
        {
            maxPid = part.pid;
        }
    }
    
    return maxPid+1;
}

- (HCXPart *) getPartById: (NSInteger) partId
{
    for(HCXPart *part in _partsList)
    {
        if(part.pid == partId)
        {
            return part;
        }
    }
    
    return nil;
}

@end
