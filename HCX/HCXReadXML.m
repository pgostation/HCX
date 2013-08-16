//
//  HCXReadXML.m
//  HCX
//
//  Created by pgo on 2013/04/11.
//  Copyright (c) 2013年 pgostation. All rights reserved.
//

#import "HCXReadXML.h"
#import "HCXStackData.h"
#import "HCXBackground.h"
#import "HCXCard.h"
#import "HCXField.h"
#import "HCXButton.h"
#import "HCXRes.h"
#import "HCXExternal.h"
#import "StackEnv.h"

@implementation HCXReadXML
{
    StackEnv *stackEnv;
    HCXStackData *stack;
    HCXCardBase *cardbase;
    HCXObject *currentObj;
    HCXRes *mediaObj;
    HCXExternal *xcmdObj;
    NSMutableArray *selectedLines;
    
    NSMutableString *mutableText;
    bool boolValue;
    
    bool inStack;
    bool inBackground;
    bool inCard;
    bool inPart;
    bool inContent;
    bool inMedia;
}

- (HCXStackData *) read:(NSString *)dirPath stackEnv:(StackEnv *)in_stackEnv
{
    stackEnv = in_stackEnv;
    
    stack = [[HCXStackData alloc] init];
    stack.name = [dirPath lastPathComponent];
    stack.dirPath = dirPath;
    
    NSString *xmlFilePath = [dirPath stringByAppendingPathComponent:@"_stack.xml"];
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlFilePath];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xmlData];
    
    [parser setDelegate:self];
	[parser parse];
    
    NSLog(@"parse end");
    
    return stack;
}


// XMLのパース開始
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	// 初期化処理
    NSLog(@"parserDidStartDocument");
    
    mutableText = [NSMutableString string];
    
    inStack = false;
    inBackground = false;
    inCard = false;
    inPart = false;
    inContent = false;
    inMedia = false;
}

// XMLのパース終了
- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    NSLog(@"parserDidEndDocument");
}

// 要素の開始タグを読み込み
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    [mutableText setString:@""];
    
	if ([elementName isEqualToString:@"stack"]) {
        currentObj = stack;
        inStack = true;
    }
	else if (inCard==false && [elementName isEqualToString:@"background"]) {
        cardbase = [[HCXBackground alloc] init];
        currentObj = cardbase;
        inBackground = true;
    }
	else if ([elementName isEqualToString:@"card"]) {
        cardbase = [[HCXCard alloc] init];
        currentObj = cardbase;
        inCard = true;
    }
	else if ([elementName isEqualToString:@"part"]) {
        currentObj = [[HCXPart alloc] init];
        inPart = true;
    }
	else if ([elementName isEqualToString:@"font"]) {
        currentObj = [[HCXObject alloc] init];
    }
	else if ([elementName isEqualToString:@"content"]) {
        currentObj = [[HCXObject alloc] init];
        inContent = true;
    }
	else if ([elementName isEqualToString:@"media"]) {
        mediaObj = [[HCXRes alloc] init];
        inMedia = true;
    }
	else if ([elementName isEqualToString:@"externalcommand"]) {
        xcmdObj = [[HCXExternal alloc] init];
        for(id key in attributeDict)
        {
            NSString *value = [attributeDict objectForKey:key];
            if ( [key isEqualToString:@"id"] ) {
                xcmdObj.nsid = [NSNumber numberWithInt:[value integerValue]];
            } else if ( [key isEqualToString:@"type"] ) {
                xcmdObj.type = value;
            } else if ( [key isEqualToString:@"name"] ) {
                xcmdObj.name = value;
            } else if ( [key isEqualToString:@"file"] ) {
                xcmdObj.filename = value;
            } else if ( [key isEqualToString:@"platform"] ) {
                xcmdObj.platform = value;
            } else if ( [key isEqualToString:@"size"] ) {
                xcmdObj.size = [value integerValue];
            }
        }
    }
	else if ([elementName isEqualToString:@"selectedLines"]) {
        selectedLines = [[NSMutableArray alloc] init];
    }
}

// 要素の閉じタグを読み込み
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if( inMedia ){
        if ([elementName isEqualToString:@"id"]) {
            mediaObj.nsid = [NSNumber numberWithInt:[mutableText integerValue]];
        } else if ([elementName isEqualToString:@"type"]) {
            mediaObj.type = [mutableText copy];
        } else if ([elementName isEqualToString:@"name"]) {
            mediaObj.name = [mutableText copy];
        } else if ([elementName isEqualToString:@"file"]) {
            mediaObj.filename = [mutableText copy];
        } else if ([elementName isEqualToString:@"left"]) {
            mediaObj.point = CGPointMake([mutableText intValue], 0);
        } else if ([elementName isEqualToString:@"top"]) {
            mediaObj.point = CGPointMake(mediaObj.point.x, [mutableText intValue]);
        } else if ([elementName isEqualToString:@"media"]) {
            [stack.rsrc addMediaFromXML:mediaObj];
            mediaObj = nil;
            inMedia = false;
        }
        return;
    }
    if ([elementName isEqualToString:@"stackfile"]) {
        //
    } else if ([elementName isEqualToString:@"true"]) {
        boolValue = true;
    } else if ([elementName isEqualToString:@"false"]) {
        boolValue = false;
    } else if ([elementName isEqualToString:@"stack"]) {
        stack.pid = arc4random(); //スタックのIDは毎回自動生成
        [stackEnv preOpen:stack];
        inStack = false;
    } else if (inCard==false && [elementName isEqualToString:@"background"]) {
        cardbase.parentStackId = stack.pid;
        [stack.bgList addObject:cardbase];
        cardbase = nil;
        inBackground = false;
    } else if ([elementName isEqualToString:@"card"]) {
        cardbase.parentStackId = stack.pid;
        [stack.cardList addObject:cardbase];
        cardbase = nil;
        inCard = false;
    } else if ([elementName isEqualToString:@"part"]) {
        ((HCXPart *)currentObj).parentType = cardbase.objectType;
        ((HCXPart *)currentObj).parentId = cardbase.pid;
        ((HCXPart *)currentObj).stackId = stack.pid;
        [cardbase.partsList addObject:currentObj];
        currentObj = cardbase;
        inPart = false;
    } else if ([elementName isEqualToString:@"font"]) {
        [stack.fontArray addObject:currentObj];
        currentObj = nil;
    } else if ([elementName isEqualToString:@"content"]) {
        [cardbase setContentFromXML:currentObj];
        currentObj = cardbase;
        inContent = false;
    } else if ([elementName isEqualToString:@"width"]) {
        currentObj.width = [mutableText intValue];
    } else if ([elementName isEqualToString:@"height"]) {
        currentObj.height = [mutableText intValue];
    } else if ([elementName isEqualToString:@"id"]) {
        currentObj.pid = [mutableText intValue];
    } else if ([elementName isEqualToString:@"name"]) {
        currentObj.name = [mutableText copy];
    } else if ([elementName isEqualToString:@"script"]) {
        currentObj.script = [mutableText copy];
    } else if ([elementName isEqualToString:@"text"]) {
        currentObj.text = [mutableText copy];
    } else if ([elementName isEqualToString:@"nextStyleID"]) {
        stack.nextStyleID = [mutableText intValue];
    }
    else if ( inStack ) {
        if ([elementName isEqualToString:@"stackID"]) {
            stack.pid = [mutableText intValue];
        } else if ([elementName isEqualToString:@"format"]) {
            stack.format = [mutableText intValue];
        } else if ([elementName isEqualToString:@"backgroundCount"]) {
            stack.backgroundCount = [mutableText intValue];
        } else if ([elementName isEqualToString:@"firstBackgroundID"]) {
            stack.firstBackgroundID = [mutableText intValue];
        } else if ([elementName isEqualToString:@"cardCount"]) {
            stack.cardCount_forReadXml = [mutableText intValue];
        } else if ([elementName isEqualToString:@"firstCardID"]) {
            stack.firstCardID = [mutableText intValue];
        } else if ([elementName isEqualToString:@"listID"]) {
            stack.listID = [mutableText intValue];
        } else if ([elementName isEqualToString:@"password"]) {
            stack.password = [mutableText intValue];
        } else if ([elementName isEqualToString:@"userLevel"]) {
            stack.userLevel = [mutableText intValue];
        } else if ([elementName isEqualToString:@"pattern"]) {
            if(stack.pattern == nil){ stack.pattern = [[NSMutableArray alloc] init]; }
            [stack.pattern addObject:mutableText];
        } else if ([elementName isEqualToString:@"privateAccess"]) {
            stack.privateAccess = boolValue;
        } else if ([elementName isEqualToString:@"cantDelete"]) {
            stack.cantDelete = boolValue;
        } else if ([elementName isEqualToString:@"cantAbort"]) {
            stack.cantAbort = boolValue;
        } else if ([elementName isEqualToString:@"cantPeek"]) {
            stack.cantPeek = boolValue;
        } else if ([elementName isEqualToString:@"cantModify"]) {
            stack.cantModify = boolValue;
        } else if ([elementName isEqualToString:@"createdByVersion"]) {
            stack.createdByVersion = [mutableText copy];
        } else if ([elementName isEqualToString:@"lastCompactedVersion"]) {
            stack.lastCompactedVersion = [mutableText copy];
        } else if ([elementName isEqualToString:@"modifyVersion"]) {
            stack.modifyVersion = [mutableText copy];
        } else if ([elementName isEqualToString:@"openVersion"]) {
            stack.openVersion = [mutableText copy];
        } else if ([elementName isEqualToString:@"fontTableID"]) {
            stack.fontTableID = [mutableText intValue];
        } else if ([elementName isEqualToString:@"styleTableID"]) {
            stack.styleTableID = [mutableText intValue];
        }
    } else if ( inContent ) {
        if ([elementName isEqualToString:@"layer"]) {
            currentObj.isBgLayer = [mutableText isEqualToString:@"background"];
        } else if ([elementName isEqualToString:@"highlight"]) {
            currentObj.content_highlight = boolValue;
        }
	} else if ( inPart ) {
        if ([elementName isEqualToString:@"type"]) {
            if( [mutableText isEqualToString:@"button"] ) {
                HCXButton *newObj = [[HCXButton alloc] init];
                newObj.pid = currentObj.pid;
                currentObj = newObj;
            } else {
                HCXField *newObj = [[HCXField alloc] init];
                newObj.pid = currentObj.pid;
                currentObj = newObj;
            }
        }
        HCXButton *btn = (HCXButton *)currentObj;
        HCXField *fld = (HCXField *)currentObj;
        HCXPart *part = (HCXPart *)currentObj;
        if ([elementName isEqualToString:@"visible"]) {
            part.visible = boolValue;
        } else if ([elementName isEqualToString:@"dontWrap"]) {
            fld.dontWrap = boolValue;
        } else if ([elementName isEqualToString:@"dontSearch"]) {
            fld.dontSearch = boolValue;
        } else if ([elementName isEqualToString:@"sharedText"]) {
            fld.sharedText = boolValue;
        } else if ([elementName isEqualToString:@"fixedLineHeight"]) {
            fld.fixedLineHeight = boolValue;
        } else if ([elementName isEqualToString:@"autoTab"]) {
            fld.autoTab = boolValue;
        } else if ([elementName isEqualToString:@"lockText"]) {
            fld.lockText = boolValue;
        } else if ([elementName isEqualToString:@"left"]) {
            part.left = [mutableText intValue];
        } else if ([elementName isEqualToString:@"top"]) {
            part.top = [mutableText intValue];
        } else if ([elementName isEqualToString:@"right"]) {
            part.width = [mutableText intValue] - part.left;
        } else if ([elementName isEqualToString:@"bottom"]) {
            part.height = [mutableText intValue] - part.top;
        } else if ([elementName isEqualToString:@"style"]) {
            NSString *str = [mutableText copy];
            if(currentObj.objectType==ENUM_BUTTON){
                if([str isEqualToString:@"standard"]) part.style = 0;
                else if([str isEqualToString:@"transparent"]) part.style = 1;
                else if([str isEqualToString:@"opaque"]) part.style = 2;
                else if([str isEqualToString:@"rectangle"]) part.style = 3;
                else if([str isEqualToString:@"shadow"]) part.style = 4;
                else if([str isEqualToString:@"roundrect"]) part.style = 5;
                else if([str isEqualToString:@"default"]) part.style = 6;
                else if([str isEqualToString:@"oval"]) part.style = 7;
                else if([str isEqualToString:@"popup"]) part.style = 8;
                else if([str isEqualToString:@"checkbox"]) part.style = 9;
                else if([str isEqualToString:@"radio"]) part.style = 10;
            }
            else
            {
                if([str isEqualToString:@"standard"]) part.style = 0;
                else if([str isEqualToString:@"transparent"]) part.style = 1;
                else if([str isEqualToString:@"opaque"]) part.style = 2;
                else if([str isEqualToString:@"rectangle"]) part.style = 3;
                else if([str isEqualToString:@"shadow"]) part.style = 4;
                else if([str isEqualToString:@"scrolling"]) part.style = 5;
            }
        } else if ([elementName isEqualToString:@"autoSelect"]) {
            fld.autoSelect = boolValue;
        } else if ([elementName isEqualToString:@"showLines"]) {
            fld.showLines = boolValue;
        } else if ([elementName isEqualToString:@"wideMargins"]) {
            fld.wideMargins = boolValue;
        } else if ([elementName isEqualToString:@"multipleLines"]) {
            fld.multipleLines = boolValue;
        } else if ([elementName isEqualToString:@"textAlign"]) {
            part.textAlign = [mutableText copy];
        } else if ([elementName isEqualToString:@"textFontID"]) {
            part.textFontName = [stack fontNameFromId:[mutableText intValue]];
        } else if ([elementName isEqualToString:@"textSize"]) {
            part.textSize = [mutableText intValue];
        } else if ([elementName isEqualToString:@"textStyle"]) {
            NSString *str = [mutableText copy];
            NSInteger styleMask = 0;
            if([str isEqualToString:@"plain"]){}
            else{
                if([str rangeOfString:@"bold"].location != NSNotFound) styleMask += 1;
                if([str rangeOfString:@"italic"].location != NSNotFound) styleMask += 2;
                if([str rangeOfString:@"shadow"].location != NSNotFound) styleMask += 4;
                if([str rangeOfString:@"underline"].location != NSNotFound) styleMask += 8;
                if([str rangeOfString:@"outline"].location != NSNotFound) styleMask += 16;
                if([str rangeOfString:@"condensed"].location != NSNotFound) styleMask += 32;
                if([str rangeOfString:@"extend"].location != NSNotFound) styleMask += 64;
                if([str rangeOfString:@"group"].location != NSNotFound) styleMask += 128;
            }
            part.textStyle = styleMask;
        } else if ([elementName isEqualToString:@"textHeight"]) {
            part.textHeight = [mutableText intValue];
        } else if ([elementName isEqualToString:@"enabled"]) {
            btn.enabled = boolValue;
        } else if ([elementName isEqualToString:@"showName"]) {
            btn.showName = boolValue;
        } else if ([elementName isEqualToString:@"highlight"] || [elementName isEqualToString:@"hilite"]) {
            btn.highlight = boolValue;
        } else if ([elementName isEqualToString:@"autoHighlight"] || [elementName isEqualToString:@"autoHilite"]) {
            btn.autoHighlight = boolValue;
        } else if ([elementName isEqualToString:@"sharedHighlight"] || [elementName isEqualToString:@"sharedHilite"]) {
            btn.sharedHighlight = boolValue;
        } else if ([elementName isEqualToString:@"family"]) {
            btn.family = [mutableText intValue];
        } else if ([elementName isEqualToString:@"titleWidth"]) {
            btn.titleWidth = [mutableText intValue];
        } else if ([elementName isEqualToString:@"icon"]) {
            btn.icon = [mutableText intValue];
        } else if ([elementName isEqualToString:@"selectedLines"]) {
            part.selectedLineStart = [[selectedLines objectAtIndex:0] intValue];
            part.selectedLineEnd = [[selectedLines objectAtIndex:[selectedLines count]-1] intValue];
        } else if ([elementName isEqualToString:@"integer"]) {
            [selectedLines addObject:[NSNumber numberWithInt:[mutableText intValue]]];
        }
    } else if ( inCard || inBackground ) {
        if ([elementName isEqualToString:@"bitmap"]) {
            cardbase.bitmapName = [mutableText copy];
        } else if ([elementName isEqualToString:@"showPict"]) {
            cardbase.showPict = boolValue;
        } else if ([elementName isEqualToString:@"cantDelete"]) {
            cardbase.cantDelete = boolValue;
        } else if ([elementName isEqualToString:@"dontSearch"]) {
            cardbase.dontSearch = boolValue;
        } else if (inCard && [elementName isEqualToString:@"background"]) {
            ((HCXCard *)cardbase).bgId = [mutableText intValue];
        } else if (inCard && [elementName isEqualToString:@"marked"]) {
            ((HCXCard *)cardbase).marked = boolValue;
        }
    }
}

// テキストデータ読み込み
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[mutableText appendString:string];
}

@end
