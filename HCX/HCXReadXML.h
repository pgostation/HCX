//
//  HCXReadXML.h
//  HCX
//
//  Created by pgo on 2013/04/11.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXStackData.h"

@class StackEnv;

@interface HCXReadXML : NSObject <NSXMLParserDelegate>

- (HCXStackData *) read:(NSString *)dirPath stackEnv:(StackEnv *)StackEnv;

@end
