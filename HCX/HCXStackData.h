//
//  HCXStackData.h
//  HCX
//
//  Created by pgo on 2013/04/11.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXObject.h"
#import "HCXBackground.h"
#import "HCXCard.h"
#import "HCXResource.h"

@interface HCXStackData : HCXObject

@property NSString *dirPath;

@property HCXResource *rsrc;
@property NSMutableArray *fontArray;
@property NSMutableArray *pattern;
@property NSMutableArray *cardList;
@property NSMutableArray *bgList;
@property NSInteger nextStyleID;
@property NSInteger format;
@property NSInteger backgroundCount;
@property NSInteger firstBackgroundID;
@property NSInteger cardCount_forReadXml;
@property NSInteger firstCardID;
@property NSInteger listID;
@property NSInteger password;
@property NSInteger userLevel;
@property bool privateAccess;
@property bool cantDelete;
@property bool cantAbort;
@property bool cantPeek;
@property bool cantModify;
@property bool resizable; //add
@property NSString *createdByVersion;
@property NSString *lastCompactedVersion;
@property NSString *modifyVersion;
@property NSString *openVersion;
@property NSInteger fontTableID;
@property NSInteger styleTableID;
@property NSString *systemFontName;

- (HCXCard *) getCardById: (NSInteger) cardId;
- (HCXBackground *) getBgById: (NSInteger) cardId;
- (NSString *) fontNameFromId: (NSInteger) fontId;

@end
