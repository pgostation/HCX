//
//  HCXPart.m
//  HCX
//
//  Created by pgo on 2013/04/13.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXPart.h"
#import "StackEnv.h"
#import "HCXBgPart.h"
#import "HCXField.h"
#import "HCXButton.h"

@implementation HCXPart

- (HCXCardBase *) getParentData
{
    HCXStackData *stack = [StackEnv stackById:self.stackId];
    if(self.parentType==ENUM_CARD)
    {
        return [stack getCardById:self.parentId];
    }
    else{
        return [stack getBgById:self.parentId];
    }
}

- (NSInteger) partNumberInParent
{
    HCXCardBase *cardbase = [self getParentData];
    
    int number = 1;
    for(HCXPart *part in cardbase.partsList)
    {
        if(part.pid == self.pid)
        {
            return number;
        }
        number++;
    }
    
    return -1;
}

- (HCXPart *) loadContent:(HCXCard *)cardData
{
    if(self.objectType==ENUM_FIELD)
    {
        if(((HCXField *)self).sharedText)
        {
            HCXField *part = [self copy];
            part.cardIdOfContent = cardData.pid;
            for(HCXBgPart *content in cardData.bgPartsList)
            {
                if(part.pid == content.pid)
                {
                    part.text = content.text;
                    break;
                }
            }
            return part;
        }
    }
    else if(self.objectType==ENUM_BUTTON)
    {
        if(((HCXButton *)self).sharedHighlight)
        {
            HCXButton *part = [self copy];
            part.cardIdOfContent = cardData.pid;
            for(HCXBgPart *content in cardData.bgPartsList)
            {
                if(part.pid == content.pid)
                {
                    part.highlight = content.highlight;
                    break;
                }
            }
            return part;
        }
    }
    
    return self;
}

@end
