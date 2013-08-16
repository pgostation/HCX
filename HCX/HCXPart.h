//
//  HCXPart.h
//  HCX
//
//  Created by pgo on 2013/04/13.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXObject.h"

@class HCXCardBase;
@class HCXCard;

@interface HCXPart : HCXObject

@property objectType parentType;
@property NSInteger parentId;
@property NSInteger stackId;
@property NSInteger cardIdOfContent; // bg partのコンテンツ識別用

@property bool visible;
@property NSInteger left;
@property NSInteger top;
//@property NSInteger width;
//@property NSInteger height;
@property NSInteger style;
@property NSString *textAlign;
@property NSString *textFontName;
@property NSInteger textSize;
@property NSInteger textStyle;
@property NSInteger textHeight;
@property NSInteger selectedLineStart;
@property NSInteger selectedLineEnd;

- (HCXCardBase *) getParentData;
- (NSInteger) partNumberInParent;
- (HCXPart *) loadContent:(HCXCard *)cardData;

@end
