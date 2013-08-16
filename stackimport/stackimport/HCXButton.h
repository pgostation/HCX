//
//  HCXButton.h
//  stackimport
//
//  Created by pgo on 2013/04/03.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXObject.h"

@interface HCXButton : HCXObject

@property bool visible;
@property bool enabled;
@property int top;
@property int left;
@property int height;
@property int width;
@property bool showName;
@property bool hilite;
@property bool autoHilite;
@property bool sharedHilite;
@property int group;
@property int style;
@property int selectedLine;
@property int icon;
@property int textAlign;
@property int textSize;
@property int textStyle;
@property int titleWidth;
@property int textHeight;
@property NSString *textFont;

@end
