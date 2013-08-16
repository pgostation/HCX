//
//  HCXXcmd.h
//  stackimport
//
//  Created by pgo on 2013/03/31.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HCXXcmd : NSObject

@property int xcmdid;
@property NSString *type;
@property NSString *platform;
@property NSString *name;
@property NSString *filename;
@property int size;

- (HCXXcmd *) initWithId: (int)resid type:(NSString *)funcStr name:(NSString *)name filename:(NSString *)filename platform:(NSString *)platform length:(int)datalen;

@end
