//
//  HCXObject.m
//  HCX
//
//  Created by pgo on 2013/04/13.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXObject.h"
#import "HCXStackData.h"
#import "HCXBackground.h"
#import "HCXCard.h"
#import "HCXButton.h"
#import "HCXField.h"

@implementation HCXObject

- (NSString *) string
{
    NSString *str;
    switch(self.objectType)
    {
        case  ENUM_STACK:
            str = [NSString stringWithFormat:@"stack \"%@\"", ((HCXStackData *)self).dirPath];
            break;
        case  ENUM_BACKGROUND:
            str = [NSString stringWithFormat:@"background id %ld", self.pid];
            break;
        case  ENUM_CARD:
            str = [NSString stringWithFormat:@"card id %ld", self.pid];
            break;
        case  ENUM_FIELD:
            if(((HCXPart *)self).parentType==ENUM_BACKGROUND)
            {
                str = [NSString stringWithFormat:@"bg field id %ld", self.pid];
            }
            else
            {
                str = [NSString stringWithFormat:@"card field id %ld", self.pid];
            }
            break;
        case  ENUM_BUTTON:
            if(((HCXPart *)self).parentType==ENUM_BACKGROUND)
            {
                str = [NSString stringWithFormat:@"bg button id %ld", self.pid];
            }
            else
            {
                str = [NSString stringWithFormat:@"card button id %ld", self.pid];
            }
            break;
        default:
            break;
    }
    
    return str;
}

@end
