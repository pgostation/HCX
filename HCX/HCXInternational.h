//
//  HCXInternational.h
//  HCX
//
//  Created by pgo on 2013/04/23.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>

#define INTR(_english,_japanese) [HCXInternational switchString:(_english) japanese:(_japanese)]
#define MENUNAME(_english) [HCXInternational menuName:(_english)]
#define MENUCOMP(_str,_english) [HCXInternational menuCompare:(_str) comp:(_english)]

@interface HCXInternational : NSObject

+ (BOOL) useJapanese;
+ (NSString *) switchString:(NSString *)engStr japanese:(NSString *)jpnStr;
+ (NSString *) menuName:(NSString *)engStr;
+ (BOOL) menuCompare:(NSString *)str comp:(NSString *)engStr;

@end
