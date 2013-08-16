//
//  HCXDoMenu.h
//  HCX
//
//  Created by pgo on 2013/03/29.
//  Copyright (c) 2013 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HCXDoMenu : NSObject

+ (void) sendMessageToCurCard: (NSString *)msg force: (BOOL)force;

- (void) domenu: (NSString *)menuName;
- (void) open: (NSURL *)pathToFile;

@end
