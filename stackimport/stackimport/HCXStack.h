//
//  HCXStack.h
//  stackimport
//
//  Created by pgo on 2013/03/31.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXResource.h"
#import "HCXCard.h"

@interface HCXStack : NSObject

@property NSString *dirPath;
@property HCXResource *rsrc;
@property NSMutableArray *cardIdList;
@property NSMutableArray *cardCacheList;
@property NSMutableArray *bgList;
@property NSMutableArray *cardMarkedList;
@property NSMutableArray *fontList;
@property NSMutableArray *styleList;
@property int stackid;
@property int totalSize;
@property int backgroundCount;
@property int firstBg;
@property int firstCard;
@property int listId;
@property int passwordHash;
@property int userLevel;
@property bool cantPeek;
@property bool cantAbort;
@property bool privateAccess;
@property bool cantDelete;
@property bool cantModify;
@property NSString *createdByVersion;
@property NSString *lastCompactedVersion;
@property NSString *lastEditedVersion;
@property NSString *firstEditedVersion;
@property CGRect windowRect;
@property CGRect screenRect;
@property CGPoint scroll;
@property int fontTableID;
@property int styleTableID;
@property int height;
@property int width;
@property NSArray *Pattern;
@property NSString *scriptStr;
@property int nextStyleID;

@property NSMutableArray *pageIdList;
@property NSMutableArray *pageEntryCountList;
@property int pageEntrySize;


- (void) cdCacheListAdd:(HCXCard *)cd;
- (void) AddNewBg:(HCXCard *)bg;
- (HCXCard *) GetCardbyId:(int)cardid;
- (int) GetCardIdList:(int)cardid;
- (HCXCard *) GetBgbyId:(int)bgid;

@end
