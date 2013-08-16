//
//  HCXResource.h
//  HCX
//
//  Created by pgo on 2013/04/14.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXRes.h"

@interface HCXResource : NSObject

@property NSMutableDictionary *rsrcDic;

- (void) addMediaFromXML:(HCXRes *)media;

@end
