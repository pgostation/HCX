//
//  HCXField.m
//  HCX
//
//  Created by pgo on 2013/04/13.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXField.h"
#import "HCXCardBase.h"

@implementation HCXField

- (HCXField *) init
{
	if(( self = [super init] ))
	{
        self.objectType = ENUM_FIELD;
    }
    
	return self;
}

- (NSInteger) fieldNumberInParent
{
    HCXCardBase *cardbase = [self getParentData];
    
    int number = 1;
    for(HCXPart *part in cardbase.partsList)
    {
        if(part.pid == self.pid)
        {
            return number;
        }
        if(part.objectType==ENUM_FIELD) number++;
    }
    
    return -1;
}

- (HCXField *) copy
{
    HCXField *field = [[HCXField alloc] init];
    
    field.pid = self.pid;
    field.objectType = self.objectType;
    field.name = self.name;
    field.text = self.text;
    field.script = self.script;
    field.width = self.width;
    field.height = self.height;
    
    field.parentType = self.parentType;
    field.parentId = self.parentId;
    field.stackId = self.stackId;
    field.cardIdOfContent = self.cardIdOfContent;
    field.visible = self.visible;
    field.left = self.left;
    field.top = self.top;
    field.style = self.style;
    field.textAlign = self.textAlign;
    field.textFontName = self.textFontName;
    field.textSize = self.textSize;
    field.textStyle = self.textStyle;
    field.textHeight = self.textHeight;
    field.selectedLineStart = self.selectedLineStart;
    field.selectedLineEnd = self.selectedLineEnd;
    
    field.dontWrap = self.dontWrap;
    field.dontSearch = self.dontSearch;
    field.sharedText = self.sharedText;
    field.fixedLineHeight = self.fixedLineHeight;
    field.autoTab = self.autoTab;
    field.lockText = self.lockText;
    field.autoSelect = self.autoSelect;
    field.showLines = self.showLines;
    field.wideMargins = self.wideMargins;
    field.multipleLines = self.multipleLines;
    
    return field;
}

@end
