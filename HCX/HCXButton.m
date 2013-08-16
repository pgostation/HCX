//
//  HCXButton.m
//  HCX
//
//  Created by pgo on 2013/04/13.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXButton.h"
#import "HCXCardBase.h"

@implementation HCXButton

- (HCXButton *) init
{
	if(( self = [super init] ))
	{
        self.objectType = ENUM_BUTTON;
    }
    
	return self;
}

- (NSInteger) buttonNumberInParent
{
    HCXCardBase *cardbase = [self getParentData];
    
    int number = 1;
    for(HCXPart *part in cardbase.partsList)
    {
        if(part.pid == self.pid)
        {
            return number;
        }
        if(part.objectType==ENUM_BUTTON) number++;
    }
    
    return -1;
}

- (HCXButton *) copy
{
    HCXButton *button = [[HCXButton alloc] init];
    
    button.pid = self.pid;
    button.objectType = self.objectType;
    button.name = self.name;
    button.text = self.text;
    button.script = self.script;
    button.width = self.width;
    button.height = self.height;
    
    button.parentType = self.parentType;
    button.parentId = self.parentId;
    button.stackId = self.stackId;
    button.cardIdOfContent = self.cardIdOfContent;
    button.visible = self.visible;
    button.left = self.left;
    button.top = self.top;
    button.style = self.style;
    button.textAlign = self.textAlign;
    button.textFontName = self.textFontName;
    button.textSize = self.textSize;
    button.textStyle = self.textStyle;
    button.textHeight = self.textHeight;
    button.selectedLineStart = self.selectedLineStart;
    button.selectedLineEnd = self.selectedLineEnd;
    
    button.enabled = self.enabled;
    button.showName = self.showName;
    button.highlight = self.highlight;
    button.autoHighlight = self.autoHighlight;
    button.scaleIcon = self.scaleIcon;
    button.family = self.family;
    button.titleWidth = self.titleWidth;
    button.icon = self.icon;
    
    return button;
}

@end
