//
//  HCXButton.h
//  HCX
//
//  Created by pgo on 2013/04/13.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCXPart.h"

@interface HCXButton : HCXPart

@property bool enabled;
@property bool showName;
@property bool highlight;
@property bool autoHighlight;
@property bool sharedHighlight;
@property bool scaleIcon; //add
@property NSInteger family;
@property NSInteger titleWidth;
@property NSInteger icon;

- (NSInteger) buttonNumberInParent;

@end
