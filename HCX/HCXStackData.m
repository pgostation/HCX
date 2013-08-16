//
//  HCXStackData.m
//  HCX
//
//  Created by pgo on 2013/04/11.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXStackData.h"

@implementation HCXStackData

- (HCXStackData *) init
{
	if(( self = [super init] ))
	{
        self.objectType = ENUM_STACK;
        self.fontArray = [[NSMutableArray alloc] init];
        self.pattern = [[NSMutableArray alloc] init];
        self.cardList = [[NSMutableArray alloc] init];
        self.bgList = [[NSMutableArray alloc] init];
        self.rsrc = [[HCXResource alloc] init];
    }
    
	return self;
}

- (HCXCard *) getCardById: (NSInteger) cardId
{
    for( HCXCard *card in _cardList)
    {
        if ( card.pid == cardId )
        {
            return card;
        }
    }
    
    return nil;
}

- (HCXBackground *) getBgById: (NSInteger) bgId
{
    for( HCXBackground *bg in _bgList)
    {
        if ( bg.pid == bgId )
        {
            return bg;
        }
    }
    
    return nil;
}

- (NSString *) fontNameFromId: (NSInteger) fontId
{
    for( HCXObject *fontObj in _fontArray)
    {
        if ( fontObj.pid == fontId )
        {
            return fontObj.name;
        }
    }
    
    return nil;
}

@end
