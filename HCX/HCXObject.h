//
//  HCXObject.h
//  HCX
//
//  Created by pgo on 2013/04/13.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum 
{
    ENUM_STACK = 1,
    ENUM_BACKGROUND,
    ENUM_CARD,
    ENUM_BUTTON,
    ENUM_FIELD,
    ENUM_WINDOW,
    ENUM_PALETTE,
    ENUM_VECTOR
} objectType;

@interface HCXObject : NSObject

@property NSInteger pid;
@property objectType objectType;
@property NSString *name;
@property NSString *text;
@property NSString *script;
@property NSInteger width;
@property NSInteger height;
@property bool isBgLayer; //content
@property bool content_highlight; //content

- (NSString *) string;

@end
