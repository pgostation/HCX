//
//  HCXField.h
//  stackimport
//
//  Created by pgo on 2013/04/03.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXObject.h"

@interface HCXField : HCXObject

@property NSMutableArray *styleList;

@property bool visible;
@property bool dontWrap;
@property bool dontSearch;
@property bool sharedText;
@property bool fixedLineHeight;
@property bool autoTab;
@property bool autoSelect;
@property bool showLines;
@property bool wideMargins;
@property bool multipleLines;
@property bool lockText;
@property int top;
@property int left;
@property int height;
@property int width;
@property int style;
@property int selectedLine;
@property int textAlign;
@property int textSize;
@property int textStyle;
@property int textHeight;
@property int selectedEnd;
@property int selectedStart;
@property NSString *textFont;

@end
