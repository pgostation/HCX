//
//  HCXField.h
//  HCX
//
//  Created by pgo on 2013/04/13.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXPart.h"

@interface HCXField : HCXPart

@property bool dontWrap;
@property bool dontSearch;
@property bool sharedText;
@property bool fixedLineHeight;
@property bool autoTab;
@property bool lockText;
@property bool autoSelect;
@property bool showLines;
@property bool wideMargins;
@property bool multipleLines;

- (NSInteger) fieldNumberInParent;

@end
