//
//  HCXstackimport.m
//  stackimport
//
//  Created by pgo on 2013/03/30.
//  Copyright (c) 2013 pgostation. All rights reserved.
//

#import "HCXstackimport.h"
#import "HCXStack.h"
#import "HCXCard.h"
#import "HCXButton.h"
#import "HCXField.h"
#import "HCXBgButton.h"
#import "HCXBgField.h"
#import "HCXstyleClass.h"

@implementation HCXstackimport
{
    NSWindow *window;
    NSTextField *fld1;
    NSProgressIndicator *progressIndicator;
    NSString *tarPath;
    NSString *dirPath;
    NSString *filepath;
    HCXStack *stack;
    int mode; // 0==rsrc, 1==data fork
    int rsrcEntry;
    int rsrcTypeIndex;
    NSData *dataForkData;
    int dataForkOffset;
}

- (BOOL) stackimport: (NSString *) in_filepath
{
    filepath = in_filepath;
    
    NSLog(@"stackimport path=%@", filepath);
    
    {
        // make a window
        window = [[NSWindow alloc] initWithContentRect:NSMakeRect(80,[NSScreen mainScreen].frame.size.height-300,320,180)
                        styleMask: NSTitledWindowMask
                        backing:NSBackingStoreBuffered defer:YES];
        [window setTitle:@"Importing HyperCard Stack"];
        [window makeKeyAndOrderFront:nil];
        [window center];
        
        // make a text field 1
        fld1 = [[NSTextField alloc]initWithFrame:CGRectMake(10,10,300,100)];
        [fld1 setEditable:NO];
        [fld1 setBezeled:NO];
        [fld1 setDrawsBackground:NO];
        fld1.stringValue = [NSString stringWithFormat:@"path: %@", filepath];
        [[window contentView] addSubview:fld1];
        
        // make a progress indicator
        progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(10, 135, 300, 30)];
        [progressIndicator setMaxValue:100.0];
        [progressIndicator setMinValue:0.0];
        [[window contentView] addSubview:progressIndicator];
    }
    
    // is the file exist?
    NSFileManager* manager = [NSFileManager defaultManager];
    if([manager fileExistsAtPath:filepath isDirectory:nil]==NO)
    {
        [self alert:[NSString stringWithFormat:@"File '%@' is not exist", filepath]];
        return NO;
    }
    
    // make tmp directory
    NSString *tmpPath;
    {
        NSString * tempDir = NSTemporaryDirectory();
        if (tempDir == nil)
            tempDir = @"/tmp";
        tmpPath = [NSString stringWithFormat:@"%@/tmpStack", tempDir];
    }
    
    // copy to tmp dir
    {
        NSLog(@"set bundle bit");
        NSTask *task = [[NSTask alloc] init];
        NSPipe *pipe = [[NSPipe alloc] init];
        [task setLaunchPath:@"/bin/cp"];
        NSArray *args = [NSArray arrayWithObjects: filepath, tmpPath, nil]; // set bundle bit
        [task setArguments: args];
        [task setStandardOutput:pipe];
        [task launch];
        [task waitUntilExit];
    }
    
    // archive tar ( to split resource fork )
    tarPath = [tmpPath stringByAppendingString:@".tar"];
    {
        fld1.stringValue = [NSString stringWithFormat:@"make %@.tar", filepath];
        NSLog(@"archive to tar file");
        NSTask *task = [[NSTask alloc] init];
        NSPipe *pipe = [[NSPipe alloc] init];
        [task setLaunchPath:@"/usr/bin/tar"];
        NSArray *args = [NSArray arrayWithObjects: @"-cf", tarPath, tmpPath, nil];
        [task setArguments: args];
        [task setStandardOutput:pipe];
        [task launch];
        [task waitUntilExit];
        
        if([manager fileExistsAtPath:tarPath isDirectory:nil]==NO)
        {
            [self alert:@"make a tar archive failure."];
            return NO;
        }
    }
    
    // make a stack package
    dirPath = [NSString stringWithFormat:@"%@.hcxs", filepath];
    {
        // oops, this name is conflict.
        for(int i=1;[manager fileExistsAtPath:dirPath isDirectory:nil]==YES; i++)
        {
            dirPath = [NSString stringWithFormat:@"%@_%d.hcxs", filepath, i];
        }
        
        // create directory
        {
            NSLog(@"create directory");
            [manager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        // set bundle bit
        {
            NSLog(@"set bundle bit");
            NSTask *task = [[NSTask alloc] init];
            NSPipe *pipe = [[NSPipe alloc] init];
            [task setLaunchPath:@"/usr/bin/xattr"];
            NSArray *args = [NSArray arrayWithObjects: @"-wx", @"com.apple.FinderInfo", @"0000000000000000200000000000000000000000000000000000000000000000", dirPath, nil]; // set bundle bit
            [task setArguments: args];
            [task setStandardOutput:pipe];
            [task launch];
            [task waitUntilExit];
        }
    }
    
    stack = [[HCXStack alloc] init];
    stack.dirPath = dirPath;
    
    mode = 0;
    rsrcEntry = 0;
    rsrcTypeIndex = 0;
    dataForkOffset = 0;
    
    // exec dalay
    [self performSelector:@selector(dataImport:) withObject:nil afterDelay:0.01f];
    
    return YES;
}

- (void)dataImport: (id) arg
{
    if(mode==0){
        // import resource fork
        if([self readTarFile]==NO){
            [[NSApplication sharedApplication] terminate:self];
            return;
        }
    }
    else if(mode==1){
        // read data fork data
        NSFileHandle* input = [NSFileHandle fileHandleForReadingAtPath:filepath];
        dataForkData =[input readDataToEndOfFile];
        [input closeFile];
        mode = 2;
    }
    else if(mode==2){
        // import data fork
        if([self readDataFork]==NO){
            [[NSApplication sharedApplication] terminate:self];
            return;
        }
    }
    else if(mode==3){
        [progressIndicator setIndeterminate:YES];
        mode = 4;
    }
    else if(mode==4){
        // output XML
        [self outputXML];
        printf("%s", [dirPath cStringUsingEncoding:NSUTF8StringEncoding]);
        
        NSArray* apps = [NSRunningApplication
                         runningApplicationsWithBundleIdentifier:@"pgostation.HCX"];
        if([apps count]>0){
            NSRunningApplication *app = (NSRunningApplication*)[apps objectAtIndex:0];
            
            // end
            if(app!=nil){
                // send notification
                NSDictionary *dic = @{@"dirPath": dirPath};
                NSDistributedNotificationCenter *notificationCenter = [NSDistributedNotificationCenter defaultCenter];
                [notificationCenter postNotificationName:@"endStackImport" object:nil userInfo:dic];
                
                // activate
                [app activateWithOptions: NSApplicationActivateAllWindows];
                
                // terminate
                [[NSApplication sharedApplication] terminate:self];
            }
        }
        return;
    }
    
    // next exec
    [self performSelector:@selector(dataImport:) withObject:nil afterDelay:0.01f];
}

- (void)alert: (NSString *) msg
{
    if(window!=nil){
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:msg, nil];
        
        [alert beginSheetModalForWindow:window
                          modalDelegate:[NSApp delegate]//self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:nil];
    }
    
    NSLog(@"### alert: %@ ###", msg);
}

//-------------------------------------------------------
// read resource fork
//-------------------------------------------------------
struct tarHeader
{
    char name[100];
    long long mode;
    long long uid;
    long long gid;
    long long size;
    char mtime[12];
    long long chksum;
    unsigned char typeflag;
    char linkname[100];
    char magic[6];
    char version[2];
    char uname[32];
    char gname[32];
    long long devmajor;
    long long devminor;
    char prefix[155];
};

- (BOOL)readTarFile
{
    fld1.stringValue = @"readTarFile";
    NSFileHandle* input = [NSFileHandle fileHandleForReadingAtPath:tarPath];
    NSData *dat =[input readDataToEndOfFile];
    [input closeFile];
    
    const unsigned char *bytes = [dat bytes];
    NSUInteger length = [dat length];
    
    NSLog(@"tar - length: %ld", length);
    
    // 1 block = 512 byte
    BOOL find = NO;
    for(int block=0; block<length/512; )
    {
        // read header
        struct tarHeader header;
        [self readHeader:&bytes[block*512] block:block header:&header];
        block++;
        
        // read data
        NSLog(@"tar - file name: %s", header.name);
        if( strlen(header.name)>=2 && strstr(header.name, "/._")!=NULL )
        {
            const unsigned char *fileData = &bytes[block*512];
            [self readAppleDoubleData:fileData length:header.size];
            find = YES;
        }
        block += (header.size+511)/512;
    }
    
    if(find==NO){
        mode = 1; // no rsrc fork, next data fork.
    }
    
    return YES;
}

- (void)readHeader: (const unsigned char *)bytes block: (int)block header: (struct tarHeader *)header
{
    int offset = 0;
    strncpy(header->name, (const char *)&bytes[offset], 100);
    offset = 100;
    header->mode = longlongFromBytes(&bytes[offset], 8);
    offset = 108;
    header->uid = longlongFromBytes(&bytes[offset], 8);
    offset = 116;
    header->gid = longlongFromBytes(&bytes[offset], 8);
    offset = 124;
    header->size = longlongFromBytes(&bytes[offset], 12);
    NSLog(@"header.size: %lld", header->size);
    offset = 136;
    strncpy(header->mtime, (const char *)&bytes[offset], 12);
    offset = 148;
    header->chksum = longlongFromBytes(&bytes[offset], 8);
    offset = 156;
    header->typeflag = bytes[offset];
    offset = 157;
    strncpy(header->linkname, (const char *)&bytes[offset], 100);
    offset = 257;
    strncpy(header->magic, (const char *)&bytes[offset], 6);
    offset = 263;
    strncpy(header->version, (const char *)&bytes[offset], 2);
    offset = 265;
    strncpy(header->uname, (const char *)&bytes[offset], 32);
    offset = 297;
    strncpy(header->gname, (const char *)&bytes[offset], 32);
    offset = 329;
    header->devmajor = longlongFromBytes(&bytes[offset],8);
    offset = 337;
    header->devminor = longlongFromBytes(&bytes[offset],8);
    offset = 345;
    strncpy(header->prefix, (const char *)&bytes[offset], 155);
}

long long longlongFromBytes(const unsigned char *bytes, int len)
{
    long long value = 0;
    
    for(int i=0; i<len-1; i++)
    {
        value *= 8; // octal ascii
        value += bytes[i]-'0';
    }
    
    return value;
}

- (BOOL)readAppleDoubleData: (const unsigned char *)bytes length: (long long)length
{
    fld1.stringValue = @"readAppleDoubleData";
    NSLog(@"readAppleDoubleData");
    
    int offset = 0;
    
    int magic = [self readCode:bytes size:4]; offset+=4;
    if (magic != 0x51607) {
        NSLog(@"magic!= 0x51607");
        return NO;
    }
    /*int version =*/ [self readCode:&bytes[offset] size:4]; offset+=4;
    /*NSString * homefilesystem =*/ [self readStr:&bytes[offset] size:16]; offset+=16;
    int numberOfEntryies = [self readCode:&bytes[offset] size:2]; offset+=2;
    
    for (int i=0; i < numberOfEntryies; i++) {
        int entryId = [self readCode:&bytes[offset] size:4]; offset+=4;
        int entryOffset = [self readCode:&bytes[offset] size:4]; offset+=4;
        int entryLength = [self readCode:&bytes[offset] size:4]; offset+=4;
        if (entryId == 2) {
            int length = (entryOffset - offset);
            
            offset+=length;
            
            unsigned char *b = malloc(entryLength);
            if(!b){
                NSLog(@"cant malloc");
                return NO;
            }
            
            for (int j = 0; j < entryLength; j++) {
                b[j] = (char)bytes[offset+j];
            }
            
            [self readResourceFork:b length:entryLength];
            
            free(b);
            b = NULL;
            
            break;
        }
        else {
        }
    }
    
    return YES;
}

- (NSString *) readStr: (const unsigned char *)bytes size: (int)length
{
    char cstr[length+1];
    memset(cstr, 0x00, length+1);
    
    for(int i=0; i<length; i++)
    {
        cstr[i] = bytes[i];
    }
    
    return [NSString stringWithCString:cstr encoding:NSUTF8StringEncoding];
}

- (int) readCode: (const unsigned char *)bytes size: (int)length
{
    int value = 0;
    
    for(int i=0; i<length; i++)
    {
        value *= 256;
        value += bytes[i];
    }
    
    return value;
}

- (BOOL) readResourceFork:(const unsigned char *)b length: (int)length
{
    fld1.stringValue = @"readResourceFork";
    NSLog(@"readResourceFork");
    
    if (length == 0)
        return YES;
    unsigned long dataOffset = [self u4:b offset:0];
    unsigned long mapOffset = [self u4:b offset:4];
    NSLog(@"mapOffset = %ld", mapOffset);
    /*unsigned long dataLength =*/ [self u4:b offset:8];
    /*unsigned long mapLength =*/ [self u4:b offset:12];
    unsigned long offset = mapOffset + 16 + 4 + 2;
    /*unsigned long attrs =*/ [self u2:b offset:offset];
    offset += 2;
    unsigned long typeListOffset = [self u2:b offset:offset] + mapOffset + 2;
    offset += 2;
    unsigned long nameListOffset = [self u2:b offset:offset] + mapOffset;
    offset += 2;
    unsigned long typesCount = [self u2:b offset:offset] + 1;
    offset += 2;
    
    NSLog(@"typesCount = %ld", typesCount);
    if(rsrcTypeIndex < typesCount && offset + 8 <= length) {
        [progressIndicator setIndeterminate:NO];
        [progressIndicator setDoubleValue:(25 * rsrcTypeIndex) / typesCount];
        
        offset = typeListOffset + 8 * rsrcTypeIndex;
        NSString *type = [self str4:b offset:offset];
        NSLog(@"type = %@", type);
        NSLog(@"%d %d %d %d", b[offset], b[offset+1], b[offset+2], b[offset+3]);
        offset += 4;
        unsigned long count = [self u2:b offset:offset] + 1;
        NSLog(@"count = %ld", count);
        offset += 2;
        unsigned long rsrcoffset = [self u2:b offset:offset] + typeListOffset - 2;
        //offset += 2;
        offset = rsrcoffset;
        
        fld1.stringValue = [NSString stringWithFormat:@"Converting %@ resource", type];
        NSLog(@"Converting %@ resource", type);
        
        for (int j = 0; j < count; j++) {
            int resid = [self s2:b offset:offset];
            offset += 2;
            int nameoffset = [self s2:b offset:offset];
            offset += 2;
            if (nameoffset >= 0)
                nameoffset += nameListOffset;
            /*unsigned char rsrcAttr =*/ [self u1:b offset:offset];
            offset += 1;
            unsigned long dataoffset = [self u3:b offset:offset] + dataOffset;
            offset += 3;
            offset += 4;
            NSString * name = @"";
            if (nameoffset >= 0) {
                int namelen = [self u1:b offset:nameoffset];
                name = [self strn:b offset:nameoffset + 1 length:namelen];
            }
            int datalen = (int)[self u4:b offset:dataoffset];
            if(dataoffset + datalen > length){
                NSLog(@"### error read resource item length ###");
                return NO;
            }
            BOOL result = [self readResourceData: b start:(int)dataoffset + 4 datalen:datalen type:type resid:resid name:name];
            if(result == NO)
            {
                NSLog(@"### error read resource item ###");
            }
        }
    }
    
    rsrcTypeIndex++;
    if(rsrcTypeIndex >= typesCount) {
        mode = 1; // next data fork
    }
    
    return YES;
}

- (short) s2: (const unsigned char *)bytes offset: (unsigned long)offset
{
    short value = 0;
    
    for(int i=0; i<2; i++)
    {
        value *= 256;
        value += bytes[offset+i];
    }
    
    return value;
}

- (unsigned char) u1: (const unsigned char *)bytes offset: (unsigned long)offset
{
    return bytes[offset];
}

- (unsigned short) u2: (const unsigned char *)bytes offset: (unsigned long)offset
{
    unsigned short value = 0;
    
    for(int i=0; i<2; i++)
    {
        value *= 256;
        value += bytes[offset+i];
    }
    
    return value;
}

- (unsigned long) u3: (const unsigned char *)bytes offset: (unsigned long)offset
{
    unsigned long value = 0;
    
    for(int i=0; i<3; i++)
    {
        value *= 256;
        value += bytes[offset+i];
    }
    
    return value;
}

- (unsigned long) u4: (const unsigned char *)bytes offset: (unsigned long)offset
{
    unsigned long value = 0;
    
    for(int i=0; i<4; i++)
    {
        value *= 256;
        value += bytes[offset+i];
    }
    
    return value;
}

- (NSString *) str4: (const unsigned char *)bytes offset: (unsigned long)offset
{
    char b2[5];
    memset(b2, 0x00, 5);
    memcpy(b2, &bytes[offset], 4);
    return [NSString stringWithCString:b2 encoding:NSMacOSRomanStringEncoding];
}

- (NSString *) strn:(const unsigned char *)bytes offset:(int)offset length:(int)length {
    //if ([PCARD.pc.lang isEqualTo:@"Japanese"]) {
        char b2[length+1];
        memset(b2, 0x00, length+1);
        memcpy(b2, &bytes[offset], length);
        return [NSString stringWithCString:b2 encoding:NSShiftJISStringEncoding];
    //}
    //else {
    //    return [[[NSString alloc] init:b param1:offset param2:length] autorelease];
    //}
}

- (BOOL) readResourceData:(const unsigned char *)in_b start:(int)start datalen:(int)datalen type:(NSString *)type resid:(int)resid name:(NSString *)name
{
    NSString * parentPath = dirPath;
    unsigned char *b = malloc(datalen);
    if(b==NULL) return NO;
    memcpy(b, &in_b[start], datalen);
    NSString * filename = nil;
    NSString * mytype = type;
    if ([type isEqualToString:@"ICON"]) {
        filename = [self convertICON2PNG:b parentPath:parentPath resid:resid];
        mytype = @"icon";
    }
    else if ([type isEqualToString:@"cicn"]) {
        filename = [self convertcicn2PNG:b datalen:datalen parentPath:parentPath resid:resid];
        mytype = @"cicn";
    }
    else if ([type isEqualToString:@"PICT"] || [type isEqualToString:@"pict"] || [type isEqualToString:@"Pdat"]) {
        filename = [self convertPICT2PICTfile:b datalen:datalen parentPath:parentPath resid:resid];
        mytype = @"picture";
    }
    else if ([type isEqualToString:@"snd "]) {
        filename = [self convertSND2AIFF:b datalen:datalen parentPath:parentPath resid:resid];
        mytype = @"sound";
    }
    else if ([type isEqualToString:@"CURS"]) {
        CGPoint point;
        filename = [self convertCURS2Cursor:b datalen:datalen parentPath:parentPath resid:resid name:name point:&point];
        [stack.rsrc addCursorResource:resid type:mytype name:name path:filename point:point];
        filename = nil;
    }
    else if ([type isEqualToString:@"ppat"]) {
        filename = [self convertppat2PNG:b datalen:datalen parentPath:parentPath resid:resid];
        mytype = @"ppat";
    }
    else if ([type isEqualToString:@"icl8"]) {
        filename = [self converticl82PNG:b datalen:datalen parentPath:parentPath resid:resid];
        mytype = @"icl8";
    }
    else if ([type isEqualToString:@"FONT"] || [type isEqualToString:@"NFNT"]) {
        //[self convertFONT2PNG:b parentPath:parentPath resid:resid name:name rsrc:stack.rsrc];
    }
    /*else if ([type isEqualToString:@"HCcd"] || [type isEqualToString:@"HCbg"]) {
        addcolorClass * addColorOwner;
        addColorOwner = [[[addcolorClass alloc] init:[Integer description:resid] param1:[type isEqualToString:@"HCbg"]] autorelease];
        [self convertAddColorResource:addColorOwner b:b];
        [stack.rsrc.addcolorList add:addColorOwner];
    }
    else if ([type isEqualToString:@"PLTE"]) {
        PlteClass * plteOwner;
        plteOwner = [[[PlteClass alloc] init:resid param1:name param2:0 param3:YES param4:0 param5:0 param6:[[[Point alloc] init:0 param1:0] autorelease]] autorelease];
        [self convertPLTEResource:plteOwner b:b rsrc:stack.rsrc];
        [stack.rsrc.plteList add:plteOwner];
    }*/
    else if ([type isEqualToString:@"XCMD"] || [type isEqualToString:@"xcmd"] || [type isEqualToString:@"XFCN"] || [type isEqualToString:@"xfcn"]) {
        [self convertXCMD2file:b datalen:datalen type:type parentPath:parentPath resid:resid name:name];
    }
    else {
        filename = [self convertRsrc2file:b datalen:datalen type:type parentPath:parentPath resid:resid name:name];
        mytype = type;
    }
    if (filename != nil) {
        [stack.rsrc addResource:resid type:mytype name:name path:filename];
    }
    
    free(b);
    return YES;
}


- (NSString *) convertICON2PNG:(const unsigned char *)b parentPath:(NSString *)parentPath resid:(int)resid
{
    const int height = 32;
    const int width = 32;
    
    // make ARGB CGImage
    CGContextRef context = NULL;
    CGColorSpaceRef imageColorSpace = CGColorSpaceCreateDeviceRGB();    
    context = CGBitmapContextCreate (NULL, width, height, 8, width * 4,
                                     imageColorSpace, kCGImageAlphaPremultipliedLast);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    // get data-buffer
    CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
    CFDataRef data = CGDataProviderCopyData(dataProvider);
    //UInt8* db = (UInt8*)CFDataGetBytePtr(data);
    UInt32 *db = (UInt32*)CFDataGetBytePtr(data);
    
    // set white&black
    for (int y = 0; y < 32; y++) {
        for (int x = 0; x < 32; x++) {
            int c = b[y*4 + x/8];
            c = 0x01 & (c >> (7 - x % 8));
            db[x + y * 32] = (c == 0) ? 0xFFFFFFFF : 0xFF000000;
        }
    }
    
    // outside transparent (vertical scan)
    for (int y = 0; y < 32; y++) {
        int x = 0;
        if (db[y * 32 + x] == 0xFFFFFFFF) {
            [self clearPixel:x y:y db:db];
        }
        x = 31;
        if (db[y * 32 + x] == 0xFFFFFFFF) {
            [self clearPixel:x y:y db:db];
        }
    }
    
    // outside transparent (horizontal scan)
    for (int x = 0; x < 32; x++) {
        int y = 0;
        if (db[y * 32 + x] == 0xFFFFFFFF) {
            [self clearPixel:x y:y db:db];
        }
        y = 31;
        if (db[y * 32 + x] == 0xFFFFFFFF) {
            [self clearPixel:x y:y db:db];
        }
    }
    
    CFDataRef dstData = CFDataCreate(NULL, (UInt8*)db, CFDataGetLength(data));
    CGDataProviderRef dstDataProvider = CGDataProviderCreateWithCFData(dstData);
    
    CGImageRef dstCGImage = CGImageCreate(
                                    width, height,
                                    8, 8*4, width*4,
                                    imageColorSpace, CGImageGetBitmapInfo(cgImage), dstDataProvider,
                                    NULL, CGImageGetShouldInterpolate(cgImage), CGImageGetRenderingIntent(cgImage));
    
    // save as PNG file
    NSString *path = [NSString stringWithFormat:@"%@/ICON_%d.png", parentPath, resid];
    if(exportCGImage2PNGFileWithDestination(dstCGImage, path)==NO)
    {
        path = nil;
    }
    
    // release CGImage
    CGColorSpaceRelease(imageColorSpace);
    CGContextRelease(context);
    CGImageRelease(cgImage);

    return path;
}

- (void) clearPixel:(int)x y:(int)y db:(UInt32*)db
{
    db[x + y * 32] = 0x00FFFFFF;
    if (x > 0) {
        if (db[y * 32 + x - 1] == 0xFFFFFFFF) {
            [self clearPixel:x - 1 y:y db:db];
        }
    }
    if (x + 1 < 32) {
        if (db[y * 32 + x + 1] == 0xFFFFFFFF) {
            [self clearPixel:x + 1 y:y db:db];
        }
    }
    if (y > 0) {
        if (db[(y - 1) * 32 + x] == 0xFFFFFFFF) {
            [self clearPixel:x y:y - 1 db:db];
        }
    }
    if (y + 1 < 32) {
        if (db[(y + 1) * 32 + x] == 0xFFFFFFFF) {
            [self clearPixel:x y:y + 1 db:db];
        }
    }
}

BOOL exportCGImage2PNGFileWithDestination(CGImageRef image,NSString *path){
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL(url,kUTTypePNG,1,NULL);
    if(imageDestination == NULL){
        return NO;
    }
    
    CGImageDestinationAddImage(imageDestination,image,NULL);
    
    BOOL flag = CGImageDestinationFinalize(imageDestination);
    CFRelease(imageDestination);
    return flag;
}

- (NSString *) convertcicn2PNG:(const unsigned char *)b datalen:(int)datalen parentPath:(NSString *)parentPath resid:(int)resid
{
    int offset = 0;
    
    // iconPMap
    //int baseAddr = [self u4:b offset:offset];
    offset += 4;
    int rowBytes = 0x7FFF & [self u2:b offset:offset];
    offset += 2;
    //int top = [self u2:b offset:offset];
    offset += 2;
    //int left = [self u2:b offset:offset];
    offset += 2;
    int bottom = [self u2:b offset:offset];
    offset += 2;
    int right = [self u2:b offset:offset];
    offset += 2;
    //int pmVersion = [self u2:b offset:offset];
    offset += 2;
    int packType = [self u2:b offset:offset];
    offset += 2;
    unsigned long packSize = [self u4:b offset:offset];
    offset += 4;
    //int hRes = [self u4:b offset:offset];
    offset += 4;
    //int vRes = [self u4:b offset:offset];
    offset += 4;
    //int pixelType = [self u2:b offset:offset];
    offset += 2;
    int pixelSize = [self u2:b offset:offset];
    offset += 2;
    //int cmpCount = [self u2:b offset:offset];
    offset += 2;
    //int cmpSize = [self u2:b offset:offset];
    offset += 2;
    //int planeBytes = [self u4:b offset:offset];
    offset += 4;
    //int ctabhandle = [self u4:b offset:offset];
    offset += 4;
    //int pmreserved = [self u4:b offset:offset];
    offset += 4;
    
    //maskBMap
    //int mbaseAddr = [self u4:b offset:offset];
    offset += 4;
    int mrowBytes = 0x7FFF & [self u2:b offset:offset];
    offset += 2;
    //int mtop = [self u2:b offset:offset];
    offset += 2;
    //int mleft = [self u2:b offset:offset];
    offset += 2;
    //int mbottom = [self u2:b offset:offset];
    offset += 2;
    //int mright = [self u2:b offset:offset];
    offset += 2;
    
    //iconBMap
    //int ibaseAddr = [self u4:b offset:offset];
    offset += 4;
    int irowBytes = 0x7FFF & [self u2:b offset:offset];
    offset += 2;
    //int itop = [self u2:b offset:offset];
    offset += 2;
    //int ileft = [self u2:b offset:offset];
    offset += 2;
    //int ibottom = [self u2:b offset:offset];
    offset += 2;
    //int iright = [self u2:b offset:offset];
    offset += 2;
    
    // -- MASK --
    // make ARGB CGImage
    CGContextRef maskcontext = NULL;
    CGColorSpaceRef maskimageColorSpace = CGColorSpaceCreateDeviceRGB();
    maskcontext = CGBitmapContextCreate (NULL, right, bottom, 8, right * 4,
                                     maskimageColorSpace, kCGImageAlphaPremultipliedLast);
    CGImageRef maskcgImage = CGBitmapContextCreateImage(maskcontext);
    
    // get data-buffer
    CGDataProviderRef maskdataProvider = CGImageGetDataProvider(maskcgImage);
    //CFDataRef maskdata = CGDataProviderCopyData(maskdataProvider);
    //UInt32 *maskdb = (UInt32*)CFDataGetBytePtr(maskdata);
    CFDataRef masktmpData = CGDataProviderCopyData(maskdataProvider);
    CFMutableDataRef maskdata = CFDataCreateMutableCopy(0, 0, masktmpData);
    UInt32 *maskdb = (UInt32 *)CFDataGetMutableBytePtr(maskdata);
    
    for (int y = 0; y < bottom; y++) {
        UInt32 data[right];
        
        for (int i = 0; i < mrowBytes; i++) {
            data[i] = b[offset];
            offset++;
        }
        
        for (int x = 0; x < right && x * 1 / 8 < mrowBytes; x++) {
            int idx = data[x * 1 / 8] & 0x00FF;
            idx = (idx >> (7 - x % 8)) & 0x01;
            maskdb[(y * right) + x] = (idx == 0)? 0xFF000000 : 0xFFFFFFFF;
        }
        
    }
    
    // -- Black & White --
    // make ARGB CGImage
    CGContextRef monocontext = NULL;
    CGColorSpaceRef monoimageColorSpace = CGColorSpaceCreateDeviceRGB();
    monocontext = CGBitmapContextCreate (NULL, right, bottom, 8, right * 4,
                                         monoimageColorSpace, kCGImageAlphaPremultipliedLast);
    CGImageRef monocgImage = CGBitmapContextCreateImage(monocontext);
    
    // get data-buffer
    CGDataProviderRef monodataProvider = CGImageGetDataProvider(monocgImage);
    //CFDataRef monodata = CGDataProviderCopyData(monodataProvider);
    //UInt32 *monodb = (UInt32*)CFDataGetBytePtr(monodata);
    CFDataRef monotmpData = CGDataProviderCopyData(monodataProvider);
    CFMutableDataRef monodata = CFDataCreateMutableCopy(0, 0, monotmpData);
    UInt32 *monodb = (UInt32 *)CFDataGetMutableBytePtr(monodata);
    
    for (int y = 0; y < bottom; y++) {
        UInt32 data[right];
        
        for (int i = 0; i < irowBytes; i++) {
            data[i] = b[offset];
            offset++;
        }
        
        
        for (int x = 0; x < right && x * 1 / 8 < irowBytes; x++) {
            int idx = data[x * 1 / 8] & 0x00FF;
            idx = (idx >> (x % 8)) & 0x01;
            monodb[(y * right) + x] = (idx == 0)? 0xFF000000 : 0xFFFFFFFF;
        }
        
    }
    
    NSString *path = nil;
    
    // --COLOR--
    if (offset + 1 < datalen) {
        //int iconData = [self u4:b offset:offset];
        offset += 4;
        //int ctSeed = [self u4:b offset:offset];
        offset += 4;
        //int ctFlag = [self u2:b offset:offset];
        offset += 2;
        int ctSize = [self u2:b offset:offset];
        offset += 2;
        UInt32 palette[256];
        int paletteLength = 0;
        if (ctSize == 0) {
            palette[0] = 0xFF000000;
            palette[1] = 0xFFFFFFFF;
            paletteLength = 2;
        }
        else {
            for (int i = 0; i < ctSize + 1; i++) {
                int value = 0x00FF & [self u2:b offset:offset];
                offset += 2;
                int red = [self u2:b offset:offset];
                offset += 2;
                int green = [self u2:b offset:offset];
                offset += 2;
                int blue = [self u2:b offset:offset];
                offset += 2;
                palette[value] = (UInt32)0xFF000000 | (((blue / 256) << 16) + ((green / 256) << 8) + ((red / 256)));
                paletteLength++;
            }
        }
        
        // make ARGB CGImage
        CGContextRef maincontext = NULL;
        CGColorSpaceRef mainimageColorSpace = CGColorSpaceCreateDeviceRGB();
        maincontext = CGBitmapContextCreate (NULL, right, bottom, 8, right * 4,
                                             mainimageColorSpace, kCGImageAlphaPremultipliedLast);
        CGImageRef maincgImage = CGBitmapContextCreateImage(maincontext);
        
        // get data-buffer
        CGDataProviderRef maindataProvider = CGImageGetDataProvider(maincgImage);
        //CFDataRef maindata = CGDataProviderCopyData(maindataProvider);
        //UInt32 *maindb = (UInt32*)CFDataGetBytePtr(maindata);
        CFDataRef maintmpData = CGDataProviderCopyData(maindataProvider);
        CFMutableDataRef maindata = CFDataCreateMutableCopy(0, 0, maintmpData);
        UInt32 *maindb = (UInt32 *)CFDataGetMutableBytePtr(maindata);
        
        for (int y = 0; y < bottom; y++) {
            int data_length = right;
            UInt32 data[data_length];
            if (packType == 0) {
                // no pack
                for (int i = 0; i < rowBytes && offset < datalen; i++) {
                    data[i] = b[offset];
                    offset++;
                }
            }
            else {
                // unpack packBits
                for (int i = 0; i < packSize; i++) {
                    int dsize = 0x00FF & b[offset];
                    offset++;
                    int doffset = 0;
                    if (dsize >= 128) {
                        // continuous data
                        dsize = 256 - dsize + 1;
                        int src = b[offset];
                        offset++;
                        i++;
                        
                        for (int j = 0; j < dsize && j + doffset < data_length; j++) {
                            data[j + doffset] = (char)src;
                        }
                        
                        //doffset += dsize;
                    }
                    else {
                        // direct data
                        dsize++;
                        
                        for (int j = 0; j < dsize; j++) {
                            if (rowBytes <= j + doffset) {
                                continue;
                            }
                            data[j + doffset] = b[offset];
                            offset++;
                            i++;
                        }
                        
                        //doffset += dsize;
                    }
                }
                
            }
            
            for (int x = 0; x < right && x * pixelSize / 8 < rowBytes; x++) {
                int idx = data[x * pixelSize / 8] & 0x00FF;
                if (pixelSize == 1)
                    idx = (idx >> (7 - x % 8)) & 0x01;
                if (pixelSize == 2)
                    idx = (idx >> (6 - 2*(x % 4))) & 0x03;
                if (pixelSize == 4)
                    idx = (idx >> (4 - 4*(x % 2))) & 0x0F;
                if (idx >= paletteLength){
                    maindb[(y * right) + x] = 0xFF000000;
                    continue;
                }
                UInt32 pixel = palette[idx];
                maindb[(y * right) + x] = pixel;
            }
            
        }
        
        [self makeAlphaImage:maindb mask:maskdb width:right height:bottom];
                
        CFDataRef dstData = CFDataCreate(NULL, (UInt8*)maindb, CFDataGetLength(maindata));
        CGDataProviderRef dstDataProvider = CGDataProviderCreateWithCFData(dstData);
        
        CGImageRef dstCGImage = CGImageCreate(
                                              right, bottom,
                                              8, 8*4, right*4,
                                              mainimageColorSpace, CGImageGetBitmapInfo(maincgImage), dstDataProvider,
                                              NULL, CGImageGetShouldInterpolate(maincgImage), CGImageGetRenderingIntent(maincgImage));
        
        // save as PNG file
        NSString *path = [NSString stringWithFormat:@"%@/cicn_%d.png", parentPath, resid];
        if(exportCGImage2PNGFileWithDestination(dstCGImage, path)==NO)
        {
            path = nil;
        }
        
        CGImageRelease(dstCGImage);
        CFRelease(dstDataProvider);
        CFRelease(dstData);
        
        CGColorSpaceRelease(mainimageColorSpace);
        CGContextRelease(maincontext);
        CGImageRelease(maincgImage);
        CFRelease(maindata);
        CFRelease(maintmpData);
    }
    
    // release CGImage
    CGColorSpaceRelease(maskimageColorSpace);
    CGContextRelease(maskcontext);
    CGImageRelease(maskcgImage);
    CFRelease(maskdata);
    CFRelease(masktmpData);
    
    CGColorSpaceRelease(monoimageColorSpace);
    CGContextRelease(monocontext);
    CGImageRelease(monocgImage);
    CFRelease(monodata);
    CFRelease(monotmpData);
    
    return path;
}

- (void) makeAlphaImage:(UInt32*)maindb mask:(UInt32*)maskdb width:(int)width height:(int)height
{
    for(int y=0; y<height; y++)
    {
        for(int x=0; x<width; x++)
        {
            if((maskdb[y*width+x]&0xFF000000)==0x00000000)
            {
                maindb[y*width+x] &= 0x00FFFFFF;
            }
        }
    }
}

- (NSString *) convertCURS2Cursor:(const unsigned char *)b datalen:(int)datalen parentPath:(NSString *)parentPath resid:(int)resid name:(NSString *)name point:(CGPoint *)point
{
    // make CGImage
    const int width = 16;
    const int height = 16;
    
    CGColorSpaceRef imageColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate (NULL, width, height, 8, width * 4,
                                         imageColorSpace, kCGImageAlphaPremultipliedLast);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    // get data-buffer
    CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
    CFDataRef tmpData = CGDataProviderCopyData(dataProvider);
    CFMutableDataRef data = CFDataCreateMutableCopy(0, 0, tmpData);
    UInt32 *db = (UInt32 *)CFDataGetMutableBytePtr(data);
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int c = b[y*2+x/8]; //black&white
            c = 0x01&(c>>(7-x%8));
            int m = b[(y+16)*2+x/8]; //mask
            m = 0x01&(m>>(7-x%8));
            int v = 0;
            if(c==0&&m!=0) v = 0xFFFFFFFF;
            if(c!=0&&m!=0) v = 0xFF000000;
            if(c==0&&m==0) v = 0x00000000;
            
            db[x+y*16] = v;
        }
    }
    
    point->x = [self u2:b offset:16*2];
    point->y = [self u2:b offset:16*2+2];
    
    CFDataRef dstData = CFDataCreate(NULL, (UInt8*)db, CFDataGetLength(data));
    CGDataProviderRef dstDataProvider = CGDataProviderCreateWithCFData(dstData);
    
    CGImageRef dstCGImage = CGImageCreate(
                                          width, height,
                                          8, 8*4, width*4,
                                          imageColorSpace, CGImageGetBitmapInfo(cgImage), dstDataProvider,
                                          NULL, CGImageGetShouldInterpolate(cgImage), CGImageGetRenderingIntent(cgImage));
    
    // save as PNG file
    NSString *path = [NSString stringWithFormat:@"%@/CURS_%d.png", parentPath, resid];
    if(exportCGImage2PNGFileWithDestination(dstCGImage, path)==NO)
    {
        path = nil;
    }
    
    CGColorSpaceRelease(imageColorSpace);
    CGContextRelease(context);
    CGImageRelease(cgImage);
    CFRelease(data);
    CFRelease(tmpData);
    
    return path;
}

- (NSString *) convertppat2PNG:(const unsigned char *)b datalen:(int)datalen parentPath:(NSString *)parentPath resid:(int)resid
{
    int offset = 0;
    
    // --COLOR--
    // PixPat
    int patType = [self u2:b offset:offset];
    offset+=2;
    unsigned long patMap = [self u4:b offset:offset];
    offset+=4;
    unsigned long patData = [self u4:b offset:offset];
    offset+=4;
    /*int patXData =*/ [self u4:b offset:offset];
    offset+=4;
    /*int patXValid =*/ [self u2:b offset:offset];
    offset+=2;
    /*int patXMap =*/ [self u4:b offset:offset];
    //offset+=4;
    
    if(patType!=1){ //PixMap型以外は非対応
        return nil;
    }
    
    //PixMap
    offset=(int)patMap;
    /*int baseAddr =*/ [self u4:b offset:offset];
    offset+=4;
    int rowBytes = 0x7FFF & [self u2:b offset:offset];
    offset+=2;
    
    /*int top =*/ [self u2:b offset:offset];
    offset+=2;
    /*int left =*/ [self u2:b offset:offset];
    offset+=2;
    int bottom = [self u2:b offset:offset];
    offset+=2;
    int right = [self u2:b offset:offset];
    offset+=2;
    /*int pmVersion =*/ [self u2:b offset:offset];
    offset+=2;
    int packType = [self u2:b offset:offset];
    offset+=2;
    unsigned long packSize = [self u4:b offset:offset];
    offset+=4;
    /*int hRes =*/ [self u4:b offset:offset];
    offset+=4;
    /*int vRes =*/ [self u4:b offset:offset];
    offset+=4;
    /*int pixelType =*/ [self u2:b offset:offset];
    offset+=2;
    int pixelSize = [self u2:b offset:offset];
    offset+=2;
    /*int cmpCount =*/ [self u2:b offset:offset];
    offset+=2;
    /*int cmpSize =*/ [self u2:b offset:offset];
    offset+=2;
    /*int planeBytes =*/ [self u4:b offset:offset];
    offset+=4;
    
    unsigned long ctabhandle = [self u4:b offset:offset];
    offset+=4;
    /*int pmreserved =*/ [self u4:b offset:offset];
    //offset+=4;
    
    //colorPalette
    offset=(int)ctabhandle;
    //cTableヘッダ
    /*int ctSeed =*/ [self u4:b offset:offset];
    offset+=4;
    /*int ctFlag =*/ [self u2:b offset:offset];
    offset+=2;
    int ctSize = [self u2:b offset:offset];
    offset+=2;
    
    //palette
    UInt32 palette[256];
    int paletteLength = 0;
    if (ctSize == 0) {
        palette[0] = 0xFF000000;
        palette[1] = 0xFFFFFFFF;
        paletteLength = 2;
    }
    else {
        for (int i = 0; i < ctSize + 1; i++) {
            int value = 0x00FF & [self u2:b offset:offset];
            offset += 2;
            int red = [self u2:b offset:offset];
            offset += 2;
            int green = [self u2:b offset:offset];
            offset += 2;
            int blue = [self u2:b offset:offset];
            offset += 2;
            palette[value] = (UInt32)0xFF000000 | (((blue / 256) << 16) + ((green / 256) << 8) + ((red / 256)));
            paletteLength++;
        }
    }
    
    offset=(int)patData;
    
    // make CGImage
    CGColorSpaceRef imageColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate (NULL, right, bottom, 8, right * 4,
                                                  imageColorSpace, kCGImageAlphaPremultipliedLast);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    // get data-buffer
    CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
    CFDataRef tmpData = CGDataProviderCopyData(dataProvider);
    CFMutableDataRef data = CFDataCreateMutableCopy(0, 0, tmpData);
    UInt32 *db = (UInt32 *)CFDataGetMutableBytePtr(data);
    
    for (int y = 0; y < bottom; y++) {
        int data_length = right;
        UInt32 data[data_length];
        if (packType == 0) {
            // no pack
            for (int i = 0; i < rowBytes && offset < datalen; i++) {
                data[i] = b[offset];
                offset++;
            }
        }
        else {
            // unpack packBits
            for (int i = 0; i < packSize; i++) {
                int dsize = 0x00FF & b[offset];
                offset++;
                int doffset = 0;
                if (dsize >= 128) {
                    // continuous data
                    dsize = 256 - dsize + 1;
                    int src = b[offset];
                    offset++;
                    i++;
                    
                    for (int j = 0; j < dsize && j + doffset < data_length; j++) {
                        data[j + doffset] = (char)src;
                    }
                    
                    //doffset += dsize;
                }
                else {
                    // direct data
                    dsize++;
                    
                    for (int j = 0; j < dsize; j++) {
                        if (rowBytes <= j + doffset) {
                            continue;
                        }
                        data[j + doffset] = b[offset];
                        offset++;
                        i++;
                    }
                    
                    //doffset += dsize;
                }
            }
            
        }
        
        for (int x = 0; x < right && x * pixelSize / 8 < rowBytes; x++) {
            int idx = data[x * pixelSize / 8] & 0x00FF;
            if (pixelSize == 1)
                idx = (idx >> (7 - x % 8)) & 0x01;
            if (pixelSize == 2)
                idx = (idx >> (6 - 2*(x % 4))) & 0x03;
            if (pixelSize == 4)
                idx = (idx >> (4 - 4*(x % 2))) & 0x0F;
            if (idx >= paletteLength){
                db[(y * right) + x] = 0xFF000000;
                continue;
            }
            UInt32 pixel = palette[idx];
            db[(y * right) + x] = pixel;
        }
    }
    
    CFDataRef dstData = CFDataCreate(NULL, (UInt8*)db, CFDataGetLength(data));
    CGDataProviderRef dstDataProvider = CGDataProviderCreateWithCFData(dstData);
    
    CGImageRef dstCGImage = CGImageCreate(
                                          right, bottom,
                                          8, 8*4, right*4,
                                          imageColorSpace, CGImageGetBitmapInfo(cgImage), dstDataProvider,
                                          NULL, CGImageGetShouldInterpolate(cgImage), CGImageGetRenderingIntent(cgImage));
    
    // save as PNG file
    NSString *path = [NSString stringWithFormat:@"%@/ppat_%d.png", parentPath, resid];
    if(exportCGImage2PNGFileWithDestination(dstCGImage, path)==NO)
    {
        path = nil;
    }
    
    CGImageRelease(dstCGImage);
    CFRelease(dstDataProvider);
    CFRelease(dstData);
    
    CGColorSpaceRelease(imageColorSpace);
    CGContextRelease(context);
    CGImageRelease(cgImage);
    CFRelease(data);
    CFRelease(tmpData);
    
    return path;
}

// (icon-large-8bit)
- (NSString *) converticl82PNG:(const unsigned char *)b datalen:(int)datalen parentPath:(NSString *)parentPath resid:(int)resid
{
    int offset = 0;
    
    const int right = 32;
    const int bottom = 32;
    
    // default colorPalette
    UInt32 palette[256];
    const int paletteLength = 256;
    {
        for(int i=0; i<216; i++){
            int red = 0xFF*(5-(i/36)%6)/5;
            int green = 0xFF*(5-(i/6)%6)/5;
            int blue = 0xFF*(5-i%6)/5;
            palette[i] = 0xFF000000 | (((blue)<<16) + ((green)<<8) + ((red)));
        }
        for(int i=0; i<10; i++){
            int red = 0xFF*(9-i%10)/9;
            int green = 0;
            int blue = 0;
            palette[216+i] = 0xFF000000 | (((blue)<<16) + ((green)<<8) + ((red)));
        }
        for(int i=0; i<10; i++){
            int red = 0;
            int green = 0xFF*(9-i%10)/9;
            int blue = 0;
            palette[226+i] = 0xFF000000 | (((blue)<<16) + ((green)<<8) + ((red)));
        }
        for(int i=0; i<10; i++){
            int red = 0;
            int green = 0;
            int blue = 0xFF*(9-i%10)/9;
            palette[236+i] = 0xFF000000 | (((blue)<<16) + ((green)<<8) + ((red)));
        }
        for(int i=0; i<10; i++){
            int red = 0xFF*(9-i%10)/9;
            int green = 0xFF*(9-i%10)/9;
            int blue = 0xFF*(9-i%10)/9;
            palette[246+i] = 0xFF000000 | (((blue)<<16) + ((green)<<8) + ((red)));
        }
    }
    
    // make CGImage
    CGColorSpaceRef imageColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate (NULL, right, bottom, 8, right * 4,
                                                  imageColorSpace, kCGImageAlphaPremultipliedLast);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    // get data-buffer
    CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
    CFDataRef tmpData = CGDataProviderCopyData(dataProvider);
    CFMutableDataRef data = CFDataCreateMutableCopy(0, 0, tmpData);
    UInt32 *db = (UInt32 *)CFDataGetMutableBytePtr(data);
    
    offset=0;
    for(int y=0; y<32; y++){
        unsigned char data[32];
        for(int i=0; i<32 && offset<datalen; i++){
            data[i] = b[offset];offset++;
        }
        
        //パレットを元に画像イメージ作成
        for(int x=0; x<32; x++){
            int idx = data[x]&0x00FF;
            if(idx>=paletteLength) idx = 0;
            int pixel = palette[idx];
            db[(y*32)+x] = pixel;
        }
    }
    
    CFDataRef dstData = CFDataCreate(NULL, (UInt8*)db, CFDataGetLength(data));
    CGDataProviderRef dstDataProvider = CGDataProviderCreateWithCFData(dstData);
    
    CGImageRef dstCGImage = CGImageCreate(
                                          right, bottom,
                                          8, 8*4, right*4,
                                          imageColorSpace, CGImageGetBitmapInfo(cgImage), dstDataProvider,
                                          NULL, CGImageGetShouldInterpolate(cgImage), CGImageGetRenderingIntent(cgImage));
    
    // save as PNG file
    NSString *path = [NSString stringWithFormat:@"%@/icl8_%d.png", parentPath, resid];
    if(exportCGImage2PNGFileWithDestination(dstCGImage, path)==NO)
    {
        path = nil;
    }
    
    CGColorSpaceRelease(imageColorSpace);
    CGContextRelease(context);
    CGImageRelease(cgImage);
    CFRelease(data);
    CFRelease(tmpData);
    
    return path;
}

- (NSString *) convertPICT2PICTfile:(const unsigned char *)b datalen:(int)datalen parentPath:(NSString *)parentPath resid:(int)resid
{
    unsigned char header[512] = {0};
    NSString *path = [NSString stringWithFormat:@"%@/PICT_%d.pict", parentPath, resid];
    
    NSMutableData* data = [NSMutableData dataWithBytes:header length:512];
    [data appendBytes:b length:datalen];
    
    if([data writeToFile:path atomically:YES] == NO)
    {
        return nil;
    }
    
    return path;
}

const long soundCmd = 80;
const long bufferCmd = 81;

const long sampledSynth = 5;

const long initMono = 0x0080;
const long initStereo = 0x00C0;
const long initMACE3 = 0x0300;
const long initMACE6 = 0x0400;

- (NSString *) convertSND2AIFF: (const unsigned char *)b datalen:(int)datalen parentPath:(NSString *)parentPath resid:(int)resid
{
    NSString *path = [NSString stringWithFormat:@"%@/SND_%d.aiff", parentPath, resid];
    
    int offset = 0;
    if (datalen < 2) {
        return nil;
    }
    int format = [self u2:b offset:offset];
    offset += 2;
    if (format == 1) {
        int initMACE = 0;
        [self u2:b offset:offset];
        offset += 2;
        int modNumber = [self u2:b offset:offset];
        offset += 2;
        if (modNumber == sampledSynth) {
        }
        unsigned long modInit = [self u4:b offset:offset];
        offset += 4;
        int channel = 1;
        if ((modInit & initMono) == initMono) {
            channel = 1;
        }
        if ((modInit & initStereo) == initStereo) {
            channel = 2;
        }
        if ((modInit & initMACE3) == initMACE3) {
            initMACE = 3;
        }
        if ((modInit & initMACE6) == initMACE6) {
            initMACE = 6;
        }
        int numCommands = [self u2:b offset:offset];
        offset += 2;
        
        for (int n = 0; n < numCommands; n++) {
            int sndcmd_cmd = [self s2:b offset:offset];
            offset += 2;
            if ((0x00FF & sndcmd_cmd) == bufferCmd) {
            }
            [self u2:b offset:offset];
            offset += 2;
            unsigned long sndcmd_param2 = [self u4:b offset:offset];
            offset += 4;
            if ((0x00FF & sndcmd_cmd) == bufferCmd) {
                int in_offset = (int)sndcmd_param2;
                [self u4:b offset:in_offset];
                in_offset += 4;
                unsigned long length = [self u4:b offset:in_offset];
                in_offset += 4;
                unsigned long sampleRate = [self u4:b offset:in_offset];
                in_offset += 4;
                [self u4:b offset:in_offset];
                in_offset += 4;
                [self u4:b offset:in_offset];
                in_offset += 4;
                [self u1:b offset:in_offset];
                in_offset += 1;
                [self u1:b offset:in_offset];
                in_offset += 1;
                int dataOffset = in_offset;
                [self createAIFFFile:sampleRate /65536.0f bit:8 channel:channel buffer:b offset:dataOffset length:length path:path];
                //AudioFormat * af = [[[AudioFormat alloc] init:sampleRate / 65536.0f param1:8 param2:channel param3:NO param4:YES] autorelease];
                //InputStream * in = [[[ByteArrayInputStream alloc] init:b param1:dataOffset param2:length] autorelease];
                //AudioInputStream * ais = [[[AudioInputStream alloc] init:in param1:af param2:length] autorelease];
                //Type * type = AudioFileFormat.Type.AIFF;
                
                //@try {
                    //[AudioSystem write:ais param1:type param2:ofile];
                    //[ais close];
                //}
                //@catch (IOException * e) {
                    //[e printStackTrace];
                //}
            }
            if (initMACE > 0) {
                int sampleRate = 11025 * 65536;
                int dataOffset = 54;
                int length = datalen - dataOffset;
                [self createAIFFFile:sampleRate/ 65536.0f bit:8 channel:channel buffer:b offset:dataOffset length:length path:path];
                //AudioFormat * af = [[[AudioFormat alloc] init:sampleRate / 65536.0f param1:8 param2:channel param3:NO param4:YES] autorelease];
                //InputStream * in = [[[ByteArrayInputStream alloc] init:b param1:dataOffset param2:length] autorelease];
                //AudioInputStream * ais = [[[AudioInputStream alloc] init:in param1:af param2:length] autorelease];
                //Type * type = AudioFileFormat.Type.AIFF;
                
                //@try {
                    //[AudioSystem write:ais param1:type param2:ofile];
                    //[ais close];
                //}
                //@catch (IOException * e) {
                    //[e printStackTrace];
                //}
                
                {
                    //RandomAccessFile * raf = [[[RandomAccessFile alloc] init:ofile param1:@"rw"] autorelease];
                    //[raf seek:4];
                    UInt8 ckSizeByte[4];
                    //[raf read:ckSizeByte param1:0 param2:4];
                    int ckSize = (((int)(0x00FF & ckSizeByte[0])) << 24) + (((int)(0x00FF & ckSizeByte[1])) << 16) + (((int)(0x00FF & ckSizeByte[2])) << 8) + (((int)(0x00FF & ckSizeByte[3])) << 0);
                    ckSize += 16;
                    //[raf seek:4];
                    UInt8 ckSizeByte2[4] = {(char)(0xFF & (ckSize >> 24)), (char)(0xFF & (ckSize >> 16)), (char)(0xFF & (ckSize >> 8)), (char)(0xFF & ckSize)};
                    //[raf write:ckSizeByte2 param1:0 param2:4];
                    //[raf seek:11];
                    //[raf write:(char)'C'];
                    //[raf seek:12 + 4];
                    UInt8 cmSizeByte[4];
                    //[raf read:cmSizeByte param1:0 param2:4];
                    int cmSize = (((int)(0x00FF & cmSizeByte[0])) << 24) + (((int)(0x00FF & cmSizeByte[1])) << 16) + (((int)(0x00FF & cmSizeByte[2])) << 8) + (((int)(0x00FF & cmSizeByte[3])) << 0);
                    cmSize += 16;
                    //[raf seek:12 + 4];
                    UInt8 cmSizeByte2[4] = {(char)(0xFF & (cmSize >> 24)), (char)(0xFF & (cmSize >> 16)), (char)(0xFF & (cmSize >> 8)), (char)(0xFF & cmSize)};
                    //[raf write:cmSizeByte2 param1:0 param2:4];
                    //[raf seek:38];
                    NSArray * saveHeader = [NSArray array];
                    //[raf read:saveHeader param1:0 param2:16];
                    //[raf seek:38];
                    char *typebyte;
                    if (initMACE == 3) {
                        typebyte = "MAC3MACE 3-to-1\0";
                    }
                    else {
                        typebyte = "MAC6MACE 6-to-1\0";
                    }
                    //[raf write:typebyte];
                    //[raf write:saveHeader];
                    //[raf write:b param1:dataOffset param2:datalen - dataOffset];
                    //[raf close];
                }
                //@catch (FileNotFoundException * e) {
                //    [e printStackTrace];
                //}
                //@catch (IOException * e) {
                //    [e printStackTrace];
                //}
            }
        }
        
    }
    else {
        [self u2:b offset:offset];
        offset += 2;
        int numCommands = [self u2:b offset:offset];
        offset += 2;
        
        for (int n = 0; n < numCommands; n++) {
            int sndcmd_cmd = [self s2:b offset:offset];
            offset += 2;
            if ((0x00FF & sndcmd_cmd) == soundCmd) {
            }
            [self u2:b offset:offset];
            offset += 2;
            if ((0x00FF & sndcmd_cmd) == soundCmd) {
                [self u4:b offset:offset];
                offset += 4;
                [self u4:b offset:offset];
                offset += 4;
                unsigned long numofSamples = [self u4:b offset:offset];
                offset += 4;
                unsigned long sampleRate = [self u4:b offset:offset];
                offset += 4;
                [self u4:b offset:offset];
                offset += 4;
                unsigned long endByte = [self u4:b offset:offset];
                offset += 4;
                int baseNote = [self u2:b offset:offset];
                offset += 2;
                if (baseNote > 32767) {
                    numofSamples = endByte;
                }
                int dataOffset = offset;
                int channel = 1;
                unsigned long length = numofSamples;
                [self createAIFFFile:sampleRate /65536.0f bit:8 channel:channel buffer:b offset:dataOffset length:length path:path];
                //AudioFormat * af = [[[AudioFormat alloc] init:sampleRate / 65536.0f param1:8 param2:channel param3:NO param4:YES] autorelease];
                //InputStream * in = [[[ByteArrayInputStream alloc] init:b param1:dataOffset param2:length] autorelease];
                //AudioInputStream * ais = [[[AudioInputStream alloc] init:in param1:af param2:length] autorelease];
                //Type * type = AudioFileFormat.Type.AIFF;
                if (baseNote > 32767) {
                }
                
                {
                    //[AudioSystem write:ais param1:type param2:ofile];
                    //[ais close];
                }
                //@catch (IOException * e) {
                //    [e printStackTrace];
                //}
                if (baseNote > 32767) {
                    
                    {
                        //RandomAccessFile * raf = [[[RandomAccessFile alloc] init:ofile param1:@"rw"] autorelease];
                        //[raf seek:4];
                        UInt8 ckSizeByte[4];
                        //[raf read:ckSizeByte param1:0 param2:4];
                        int ckSize = (((int)(0x00FF & ckSizeByte[0])) << 24) + (((int)(0x00FF & ckSizeByte[1])) << 16) + (((int)(0x00FF & ckSizeByte[2])) << 8) + (((int)(0x00FF & ckSizeByte[3])) << 0);
                        ckSize += 16;
                        //[raf seek:4];
                        UInt8 ckSizeByte2[4] = {(char)(0xFF & (ckSize >> 24)), (char)(0xFF & (ckSize >> 16)), (char)(0xFF & (ckSize >> 8)), (char)(0xFF & ckSize)};
                        //[raf write:ckSizeByte2 param1:0 param2:4];
                        //[raf seek:11];
                        //[raf write:(char)'C'];
                        //[raf seek:12 + 4];
                        UInt8 cmSizeByte[4];
                        //[raf read:cmSizeByte param1:0 param2:4];
                        int cmSize = (((int)(0x00FF & cmSizeByte[0])) << 24) + (((int)(0x00FF & cmSizeByte[1])) << 16) + (((int)(0x00FF & cmSizeByte[2])) << 8) + (((int)(0x00FF & cmSizeByte[3])) << 0);
                        cmSize += 16;
                        //[raf seek:12 + 4];
                            UInt8 cmSizeByte2[4] = {(char)(0xFF & (cmSize >> 24)), (char)(0xFF & (cmSize >> 16)), (char)(0xFF & (cmSize >> 8)), (char)(0xFF & cmSize)};
                        //[raf write:cmSizeByte2 param1:0 param2:4];
                        //[raf seek:38];
                        NSArray * saveHeader = [NSArray array];
                        //[raf read:saveHeader param1:0 param2:16];
                        //[raf seek:38];
                        char *typebyte;
                        if (baseNote == 65084) {
                            typebyte = "MAC3MACE 3-to-1\0";
                        }
                        else {
                            typebyte = "MAC6MACE 6-to-1\0";
                        }
                        //[raf write:typebyte];
                        //[raf write:saveHeader];
                        unsigned long length2 = datalen - dataOffset;
                        if(length2<length) length = length2;
                        //[raf write:b param1:dataOffset param2:length];
                        //[raf close];
                    }
                    //@catch (FileNotFoundException * e) {
                    //    [e printStackTrace];
                    //}
                    //@catch (IOException * e) {
                    //    [e printStackTrace];
                    //}
                }
            }
        }
    }
    
    return path;
}

struct AIFF1
{
    UInt32 ckID; //FORM
    UInt32 ckSize;
    UInt32 formType; //AIFF
    //common chunk
    UInt32 ckID3; //COMM
    UInt32 ckDataSize3;
    UInt16 numChannels;
};

struct AIFF2
{
    UInt32 numSampleFrames;
    UInt16 sampleSize;
};

struct AIFF3
{
    NSSwappedDouble sampleRate;
    UInt16 dummy;
};

struct AIFF4
{
    //sound data chunk
    UInt32 ckID4; //SSND
    UInt32 ckDataSize4;
    UInt32 offset;
    UInt32 blockSize;
};

- (NSString *) createAIFFFile:(double)sampleRate bit:(int)bit channel:(int)channel buffer:(const unsigned char *)b offset:(int)offset length:(long)length path:(NSString *)path
{
    struct AIFF1 header1 = {0};
    struct AIFF2 header2 = {0};
    //struct AIFF3 header3 = {0};
    struct AIFF4 header4 = {0};
    
    header1.ckID = convEndian('FORM');
    header1.ckSize = convEndian((UInt32)length+8+38);
    header1.formType = convEndian('AIFF');
    header1.ckID3 = convEndian('COMM');
    header1.ckDataSize3 = convEndian(18);
    header1.numChannels = convShortEndian(channel);
    header2.numSampleFrames = convEndian((UInt32)(length+8)*bit/8-8);
    header2.sampleSize = convShortEndian(bit);
    //header3.sampleRate = NSSwapHostDoubleToBig(sampleRate);
    char header3[10] = {0x40, 0x0D, 0xAD, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    header4.ckID4 = convEndian('SSND');
    header4.ckDataSize4 = convEndian((UInt32)length+8);
    header4.offset = 0;
    header4.blockSize = 0;
    
    NSMutableData* data = [NSMutableData dataWithBytes:&header1 length:22];
    [data appendBytes:&header2 length:6];
    [data appendBytes:&header3 length:10];
    [data appendBytes:&header4 length:sizeof(header4)];
    unsigned char bx[length];
    for(int i=0; i<length; i++)
    {
        bx[i] = b[i]^0x80;
    }
    [data appendBytes:&bx[offset] length:length];
    
    if([data writeToFile:path atomically:YES] == NO)
    {
        return nil;
    }
    
    return path;
}

/*struct AIFC
{
    long ckID;
    long ckSize;
    long formType;
    //version chunk
    long ckID2;
    long ckDataSize2;
    long timeStamp;
    //common chunk
    long ckID3;
    long ckDataSize3;
    short numChannels;
    long numSampleFrames;
    short sampleSize;
    NSSwappedDouble sampleRate;
    long compressionType;
    unsigned char compressionNameLen;
    char compressionName[15];
    //sound data chunk
    long ckID4;
    long ckDataSize4;
    long offset;
    long blockSize;
};

- (NSString *) createAIFCFile:(double)sampleRate bit:(int)bit channel:(int)channel buffer:(const unsigned char *)b offset:(int)offset length:(long)length path:(NSString *)path
{
    struct AIFC header = {0};
    
    header.ckID = convEndian('FORM');
    header.ckSize = convEndian(length+145);
    header.formType = convEndian('AIFC');
    header.ckID2 = convEndian('FVER');
    header.ckDataSize2 = convEndian(4);
    header.timeStamp = convEndian(2726318400);
    header.ckID3 = convEndian('COMM');
    header.ckDataSize3 = convEndian(38);
    header.numChannels = convShortEndian(channel);
    header.numSampleFrames = convEndian(length*bit/8-8);
    header.sampleSize = convShortEndian(bit);
    header.sampleRate = NSSwapHostDoubleToBig(sampleRate);
    header.compressionType = convEndian('NONE');
    header.compressionNameLen = 14;
    strncpy(header.compressionName, "not compressed", sizeof(header.compressionName));
    header.ckID4 = convEndian('SSND');
    header.ckDataSize4 = convEndian(length);
    header.offset = 0;
    header.blockSize = 0;
    
    NSMutableData* data = [NSMutableData dataWithBytes:&header length:sizeof(header)];
    [data appendBytes:b length:length];
    
    if([data writeToFile:path atomically:YES] == NO)
    {
        return nil;
    }
    
    return path;
}*/

UInt32 convEndian(UInt32 x)
{
#if __LITTLE_ENDIAN__
    UInt32 y;
    y = ((x&0x000000FF)<<24) | ((x&0x0000FF00)<<8) | ((x&0x00FF0000)>>8) | (x>>24);
    return y;
#else
    return x;
#endif
}

unsigned short convShortEndian(unsigned short x)
{
#if __LITTLE_ENDIAN__
    unsigned short y;
    y = ((x&0xFF)<<8) | (x>>8);
    return y;
#else
    return x;
#endif
}

- (void) convertXCMD2file:(const unsigned char *)b datalen:(int)datalen type:(NSString *)type parentPath:(NSString *)parentPath resid:(int)resid name:(NSString *)name
{
    NSString * funcStr = @"";
    if ([type isEqualToString:@"XCMD"] || [type isEqualToString:@"xcmd"]) {
        funcStr = @"command";
    }
    else if ([type isEqualToString:@"XFCN"] || [type isEqualToString:@"xfcn"]) {
        funcStr = @"function";
    }
    NSString * platform = @"";
    if ([type isEqualToString:@"XCMD"] || [type isEqualToString:@"XFCN"]) {
        platform = @"68k";
    }
    else if ([type isEqualToString:@"xcmd"] || [type isEqualToString:@"xfcn"]) {
        platform = @"ppc";
    }
    
    NSString *rsrcfilename = [NSString stringWithFormat:@"%@_%@_%d_%@.data", type, platform, resid, name];
    NSString *path = [NSString stringWithFormat:@"%@/%@", parentPath, rsrcfilename];
    
    NSMutableData* data = [NSMutableData dataWithBytes:b length:datalen];
    
    if([data writeToFile:path atomically:YES] == NO)
    {
        return;
    }
    
    HCXXcmd *xcmd = [[HCXXcmd alloc] initWithId:resid type:funcStr name:name filename:rsrcfilename platform:[@"mac" stringByAppendingString:platform] length:datalen];
    [stack.rsrc addXcmd:xcmd];
}

- (NSString *) convertRsrc2file:(const unsigned char *)b datalen:(int)datalen type:(NSString *)type parentPath:(NSString *)parentPath resid:(int)resid name:(NSString *)name
{
    NSString *path = [NSString stringWithFormat:@"%@/%@_%d.data", parentPath, type, resid];
    
    NSMutableData* data = [NSMutableData dataWithBytes:b length:datalen];
    
    if([data writeToFile:path atomically:YES] == NO)
    {
        return nil;
    }
    
    return path;
}

//-------------------------------------------------------
// read data fork
//-------------------------------------------------------
- (BOOL)readDataFork
{
    UInt8 *b = (UInt8 *)[dataForkData bytes];
    long datalen = [dataForkData length];
    
    return [self readDataFork:b datalen:datalen];
    
    //NSString *outPath = [NSString stringWithFormat:@"%@/_stack.xml", dirPath];
}

static void HCStackDebug_write(NSString *str);


- (BOOL) readDataFork:(const UInt8 *)b datalen:(long)datalen
{
    NSLog(@"==readDataFork== datalen:%ld", datalen);
    //System.out.println("==readDataFork==");
    
    bool result = false;
    bool isReadStack = false;
    int errCount = 0;
    
    {
        if(dataForkOffset+1<datalen){
            [progressIndicator setDoubleValue:25 + 75*(dataForkOffset/(datalen+0.1))];
            
            int blockSize = readCode(&b[dataForkOffset], 4); //int blockSize = readCode(b, 4);ずれるので2個しか読まないようにしてやった
            dataForkOffset+=4;
            int typeCode = readCode(&b[dataForkOffset], 4);
            dataForkOffset+=4;
            HCStackDebug_write([NSString stringWithFormat:@"\n blockSize:0x%x",(blockSize)]);
            HCStackDebug_write([NSString stringWithFormat:@"\n typeCode:0x%x",(typeCode)]);
            HCStackDebug_write([NSString stringWithFormat:@"\n"]);
            
            while(true){
                char typeStr[5] = {0};
                typeStr[0] = (char)(0xFF&(typeCode>>24));
                typeStr[1] = (char)(0xFF&(typeCode>>16));
                typeStr[2] = (char)(0xFF&(typeCode>>8));
                typeStr[3] = (char)(0xFF&(typeCode>>0));
                
                fld1.stringValue = [NSString stringWithFormat:@"Importing %s block", typeStr];
                NSLog(@"typeStr:%s blockSize:%d", typeStr, blockSize);
                
                if(0==strcmp(typeStr,"STAK")){
                    if(isReadStack){
                        break;
                    }
                    //HCStackDebug.blockstart(typeStr);
                    //isReadStack = true;
                    readStackBlock(stack, &b[dataForkOffset], blockSize);
                    dataForkOffset+=blockSize-8;
                }
                else if(0==strcmp(typeStr,"STBL")){
                    //HCStackDebug.blockstart(typeStr);
                    readStyleBlock(stack, &b[dataForkOffset], blockSize);
                    dataForkOffset+=blockSize-8;
                }
                else if(0==strcmp(typeStr,"FTBL")){
                    //HCStackDebug.blockstart(typeStr);
                    readFontBlock(stack, &b[dataForkOffset], blockSize);
                    dataForkOffset+=blockSize-8;
                }
                else if(0==strcmp(typeStr,"LIST")){
                    //HCStackDebug.blockstart(typeStr);
                    readListBlock(stack, &b[dataForkOffset], blockSize);
                    dataForkOffset+=blockSize-8;
                }
                else if(0==strcmp(typeStr,"PAGE")){
                    //HCStackDebug.blockstart(typeStr);
                    readPageBlock(stack, &b[dataForkOffset], blockSize);
                    dataForkOffset+=blockSize-8;
                }
                else if(0==strcmp(typeStr,"CARD")){
                    //HCStackDebug.blockstart(typeStr);
                    HCXCard *cd = [[HCXCard alloc] init];
                    if(readCardBlock(stack, cd ,&b[dataForkOffset] ,blockSize)){
                        [stack cdCacheListAdd:cd];
                    }
                    else{
                        errCount++;
                    }
                    dataForkOffset+=blockSize-8;
                }
                else if(0==strcmp(typeStr,"BKGD")){
                    //HCStackDebug.blockstart(typeStr);
                    HCXCard *bg = [[HCXCard alloc] init];
                    if(readBackgroundBlock(stack, bg ,&b[dataForkOffset] ,blockSize)){
                        [stack AddNewBg:bg];
                    }else{
                        errCount++;
                    }
                    dataForkOffset+=blockSize-8;
                }
                else if(0==strcmp(typeStr,"MAST")){
                    //HCStackDebug.blockstart(typeStr);
                    //readNullBlock(&b[offset], blockSize);
                    dataForkOffset+=blockSize-8;
                }
                else if(0==strcmp(typeStr,"BMAP")){
                    //HCStackDebug.blockstart(typeStr);
                    readPictureBlock(stack, &b[dataForkOffset], blockSize);
                    dataForkOffset+=blockSize-8;
                }
                else if(0==strcmp(typeStr,"FREE")){
                    //HCStackDebug.blockstart(typeStr);
                    //readNullBlock(&b[offset], blockSize);
                    dataForkOffset+=blockSize-8;
                }
                else if(0==strcmp(typeStr,"PRNT")){
                    //HCStackDebug.blockstart(typeStr);
                    //readNullBlock(&b[offset], blockSize);
                    dataForkOffset+=blockSize-8;
                }
                else if(0==strcmp(typeStr,"PRST")){
                    //HCStackDebug.blockstart(typeStr);
                    //readNullBlock(&b[offset], blockSize);
                    dataForkOffset+=blockSize-8;
                }
                else if(0==strcmp(typeStr,"PRFT")){
                    //HCStackDebug.blockstart(typeStr);
                    //readNullBlock(&b[offset], blockSize);
                    dataForkOffset+=blockSize-8;
                }
                else if(0==strcmp(typeStr,"TAIL")){
                    //HCStackDebug.blockstart(typeStr);
                    if(isReadStack){
                        result = true;
                    }
                    dataForkOffset+=blockSize-8;
                    break;
                }
                else{
                    int acnt = 0;
                    while(true){
                        //アライメントをどうにか合わせてみる
                        blockSize = (0x00FFFFFF&blockSize)<<8;
                        blockSize += (0x00FF&(typeCode>>24));
                        //HCStackDebug_write("\n<blockSize:"+blockSize);
                        
                        typeCode = typeCode<<8;
                        int read = readCode(b, 1);
                        dataForkOffset += 1;
                        //if(read == -1) throw new IOException();
                        //HCStackDebug_write(" read:"+((read>=32)?Character.toString((char)read):read));
                        typeCode += read;
                        //HCStackDebug_write("<typeCode:"+typeCode);
                        
                        acnt++;
                        if(acnt==32000){
                            //System.out.println("!");
                            break;
                        }
                        
                        if((typeCode&0xFF000000)!=0x00000000){
                            break;
                        }
                    }
                }
                //HCStackDebug.debuginfo("<<end of "+typeStr+">>");
                //HCStackDebug.debuginfo("size:"+Integer.toString(blockSize));
                //System.out.println("blockSize:"+blockSize);
                //System.out.println("typeStr:"+typeStr);
                //aligncnt=0;
                break;
            }
            if(result == true){
                mode = 3;
                //break;
            }
            
        }
    }
    
    if(mode<3 && dataForkOffset+1<datalen){
        return YES;
    }
    mode = 3;
    
    for(int i=0; i<[stack.cardIdList count]; i++){
        int cdid = [[stack.cardIdList objectAtIndex:i] intValue];
        HCXCard *cd = [stack GetCardbyId:cdid];
        if(cd!=nil){
            cd.marked = [[stack.cardMarkedList objectAtIndex:i] intValue];
        }
    }
    
    if([stack GetCardbyId:stack.firstCard]!=nil && [stack.cardIdList count]>0 && ((NSNumber *)[stack.cardIdList objectAtIndex:0]).intValue!=stack.firstCard){
        //firstCardをリストの先頭にする
        NSMutableArray *newList = [[NSMutableArray alloc] init];
        int i=0;
        for(; i<[stack.cardIdList count]; i++){
            if(((NSNumber *)[stack.cardIdList objectAtIndex:i]).intValue==stack.firstCard)
            {
                break;
            }
        }
        for(int j=0; j<[stack.cardIdList count]; j++){
            [newList addObject:
             [stack.cardIdList objectAtIndex:((j+i)%[stack.cardIdList count])]
             ];
        }
        stack.cardIdList = newList;
    }
    
    if([stack.cardIdList count]>0)
    {
        NSMutableArray *newList = [[NSMutableArray alloc] init];
        // cdCacheListをcardIdListの順に並び替える
        for(int i=0; i<[stack.cardIdList count]; i++){
            int cardid = ((NSNumber *)[stack.cardIdList objectAtIndex:i]).intValue;
            HCXCard *cd = [stack GetCardbyId:cardid];
            if(cd!=nil){
                [newList addObject:cd];
            }
        }
        stack.cardCacheList = newList;
    }
    
    /*
    if(result==true){
        //カードの枚数チェック
        if(stack.optionStr.contains("debugchk")){
            System.out.println(stack.cdCacheList.size()+","+stack.cardIdList.size());
            if(stack.cdCacheList.size()!=stack.cardIdList.size()){
                System.out.println("number of cards check error.");
                //result = false;
            }
        }
        if(errCount>0){
            System.out.println("errCount="+errCount);
            //result = false;
        }
    }
    HCStackDebug_write("--\n");
    for(int i=0; i<stack.cdCacheList.size();i++){
        HCStackDebug_write("card data "+i+" id:"+stack.cdCacheList.get(i).id+"\n");
    }
    HCStackDebug_write("--\n");
    for(int i=0; i<stack.cardIdList.size();i++){
        HCStackDebug_write("card id "+i+" id:"+stack.cardIdList.get(i)+"\n");
    }
    
    //デバッグ情報出力
    if(stack.optionStr.contains("debugchk")){
        File f = new File(new File(stack.path).getParent()+File.separatorChar+"debug_"+stack.name+".txt");
        try {
            FileOutputStream stream = new FileOutputStream(f);
            stream.write(HCStackDebug.allStr.toString().getBytes());
            stream.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }*/
    
    return YES;
}

static int readCode(const UInt8 *b, int size){
    int iop = 0;
    if(size==1){
        iop = (b[0])&0xff;
        //System.out.println("code1:"+opcode[0]);
    }
    else if(size==2) {
        iop = (short)((b[0]&0xff)<<8)+(b[1]&0xff);
        //System.out.println("code2:"+opcode[0]+" "+opcode[1]);
    }
    else if(size==4) {
        iop = ((b[0]&0xff)<<24)+((b[1]&0xff)<<16)
        +((b[2]&0xff)<<8)+(b[3]&0xff);
        //System.out.println("code4:"+opcode[0]+" "+opcode[1]+" "+opcode[2]+" "+opcode[3]);
    }
    else{
        //System.out.println("!!!");
    }
    return iop;
}

static NSString *readStr(const UInt8 *b, int size){
    NSMutableString *str = [NSMutableString stringWithCapacity:size];
    //String debugStr = "";
    for(int i=0; i<size; i++){
        {
            int v = b[i];
            //HCStackDebug.read(v);
            [str appendFormat:@"%c", (char)v];
            //debugStr += " "+v;
        }
    }
    //if(debugStr.length()<40){
    //System.out.println("str:"+debugStr);
    //}else{
    //System.out.println("str/:"+debugStr.substring(0,40));
    //System.out.println("/str"+debugStr.substring(debugStr.length()-40));
    //}
    return str;
}

static NSString *readText(const UInt8 *data, int maxLen, int *length_in_src){
    *length_in_src = 0;
    if(maxLen<0) {
        return @"";
    }
    UInt8 bb[maxLen];
    memset(bb, 0x00, maxLen);
    
    int i=0;
    int i2 = 0;
    {
        for(; i+i2<maxLen; i++){
            int c = data[i];
            //HCStackDebug.read(c);
            (*length_in_src)++;
            if(c<0) break;
            if((c>=0x00 && c<=0x1f && c!=0x0a && c!=0x0d && c!=0x09) || c==0x7F) {
                i2++;
                i--;
                continue;
            }
            bb[i] = (UInt8)c;
        }
    }
    {
        NSString *str = @"";
        //if(stack.optionStr.contains("Japanese")){
        str = [NSString stringWithCString:(char *)bb encoding:NSShiftJISStringEncoding];
            str = macSJIS(str, bb, i);
        //}else{
        //    str = new String(bb, 0, i, "x-MacRoman");
        //}
        //改行コード変更
        /*for(int j=0;j<[str length]; j++){
            if([str characterAtIndex:j]=='\r'){
                NSString *str2 = [str substringWithRange:NSMakeRange(0,j)];
                [str2 stringByAppendingString:@"\n"];
                [str2 stringByAppendingString:[str substringFromIndex:j+1]];
                str = str2;
            }
        }*/
        str = [str stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
        str = [str stringByReplacingOccurrencesOfString:@"\x01" withString:@""];
        return str;
    }
    
    return @"";
}

static NSString *readTextToZero(const UInt8 *data, int maxLen, int *length_in_src){
    *length_in_src = 0;
    if(maxLen<0) {
        return @"";
    }
    UInt8 bb[maxLen];
    memset(bb, 0x00, maxLen);
    
    int i=0;
    {
        for(; i<maxLen; i++){
            int c = data[i];
            //HCStackDebug.read(c);
            (*length_in_src)++;
            if(c<=0) break;
            bb[i] = (UInt8)c;
        }
    }
    
    {
        NSString *str = @"";
        //if(stack.optionStr.contains("Japanese")){
        str = [NSString stringWithCString:(char *)bb encoding:NSShiftJISStringEncoding];
        str = macSJIS(str, bb, i);
        //}else{
        //    result.str = new String(b, 0, i, "x-MacRoman");
        //}
        //改行コード変更
        /*for(int j=0;j<[str length]; j++){
            if([str characterAtIndex:j]=='\r'){
                NSString *str2 = [str substringWithRange:NSMakeRange(0,j)];
                [str2 stringByAppendingString:@"\n"];
                [str2 stringByAppendingString:[str substringFromIndex:j+1]];
                str = str2;
            }
        }*/
        [str stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
        return str;
    }
    
    return @"";
}

static NSString *macSJIS(NSString *str, UInt8 *sjis, int length)
{
    /*
    bool notAsciiFlag = false;
    bool hankakuFlag = false;
    long strlen = [str length];
    for(int i=0;i<strlen;i++){
        unichar uc = [str characterAtIndex:i];
        if(uc>=[@"ｦ" characterAtIndex:0]&&
           uc<=[@"ﾟ" characterAtIndex:0]){
            hankakuFlag = true;
        }else if(uc>=128){
            if(notAsciiFlag)break;//asciiの範囲外の文字が連続して出てくるなら日本語でOK
            notAsciiFlag=true;
        }else{
            notAsciiFlag=false;
        }
        if(i+1==[str length]&&hankakuFlag){
            return [NSString stringWithCString: (char *)sjis encoding: NSMacOSRomanStringEncoding];
        }
    }
     */
    return str;
}


//HCのスタックを変換
static bool readStackBlock(HCXStack *stack, const UInt8 *b, int blockSize)
{
    ////System.out.println("readStackBlock");
    
    int offset = 0;
    
    //ブロックのデータを順次読み込み
    stack.stackid = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("blockId:"+id); //always -1
    /*String tygersStr =*/ readStr(&b[offset], 4);
    offset += 4;
    //System.out.println("tygersStr:"+tygersStr);
    /*int format =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("format:"+format);
    stack.totalSize = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("totalSize:"+totalSize);
    /*blockSize =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("stackSize:"+stackSize);
    /*int something =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("something:"+something); //wingsでは2、南方では0、鳥でも0、うにょでも0
    /*int tygers1Str =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("tygersStr:"+tygers1Str); //鳥では0、うにょでも0
    stack.backgroundCount = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("numofBgs:"+numofBgs);
    stack.firstBg = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("firstBg:"+firstBg);
    /*int numofCards =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("numofCards:"+numofCards);
    stack.firstCard = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("firstCard:"+firstCard);
    stack.listId = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("listBlockId:"+listId);
    /*int numofFree =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("numofFree:"+numofFree);
    /*int freeSize =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("freeSize:"+freeSize);
    /*int printId =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("printId:"+printId);
    stack.passwordHash = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("passwordHash:"+passwordHash);
    stack.userLevel = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("userLevel:"+userLevel);
    /*String tygers3Str =*/ readStr(&b[offset], 2);
    offset += 2;
    //System.out.println("tygers3Str:"+tygers3Str);
    int flags = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("flags:"+flags);
    stack.cantPeek = ((flags>>10)&0x01)!=0;
    stack.cantAbort = ((flags>>11)&0x01)!=0;
    stack.privateAccess = ((flags>>13)&0x01)!=0;
    stack.cantDelete = ((flags>>14)&0x01)!=0;
    stack.cantModify = ((flags>>15)&0x01)!=0;
    /*String tygers4Str =*/ readStr(&b[offset], 18);
    offset += 18;
    //System.out.println("tygers4Str:"+tygers4Str);
    
    int createdByV = readCode(&b[offset], 4);
    offset += 4;
    stack.createdByVersion = getVers(createdByV);
    //System.out.println("createdVer:"+createdByVersion);
    
    int compactedV = readCode(&b[offset], 4);
    offset += 4;
    stack.lastCompactedVersion = getVers(compactedV);
    //System.out.println("compactedVer:"+lastCompactedVersion);
    
    int lastEditedV = readCode(&b[offset], 4);
    offset += 4;
    stack.lastEditedVersion = getVers(lastEditedV);
    //System.out.println("lastEditedVer:"+lastEditedVersion);
    
    int lastOpenedV = readCode(&b[offset], 4);
    offset += 4;
    stack.firstEditedVersion = getVers(lastOpenedV);
    //System.out.println("lastOpenedVer:"+firstEditedVersion);
    
    /*int checksum =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("checksum:"+checksum);
    /*String tygers41Str =*/ readStr(&b[offset], 4);
    offset += 4;
    //System.out.println("tygers41Str:"+tygers41Str);
    //stack.windowRect = [[CGRect alloc] init];
    int rx = readCode(&b[offset], 2);
    offset += 2;
    int ry = readCode(&b[offset], 2);
    offset += 2;
    int rwidth = readCode(&b[offset], 2) - rx;
    offset += 2;
    int rheight = readCode(&b[offset], 2) - ry;
    offset += 2;
    stack.windowRect = CGRectMake(rx, ry, rwidth, rheight);
    //stack.screenRect = new Rectangle();
    int sx = readCode(&b[offset], 2);
    offset += 2;
    int sy = readCode(&b[offset], 2);
    offset += 2;
    int swidth = readCode(&b[offset], 2) - sx;
    offset += 2;
    int sheight = readCode(&b[offset], 2) - sy;
    offset += 2;
    stack.screenRect = CGRectMake(sx, sy, swidth, sheight);
    //stack.scroll = new Point();
    int scx = readCode(&b[offset], 2);
    offset += 2;
    int scy = readCode(&b[offset], 2);
    offset += 2;
    stack.scroll = CGPointMake(scx, scy);
    /*String tygers5Str =*/ readStr(&b[offset], 292);
    offset += 292;
    //System.out.println("tygers5Str:"+tygers5Str);
    stack.fontTableID = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("fontTableId:"+fontTableID);
    stack.styleTableID = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("styleTableId:"+styleTableID);
    stack.height = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("height:"+height);
    stack.width = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("width:"+width);
    /*String tygers6Str =*/ readStr(&b[offset], 260);
    offset += 260;
    //System.out.println("tygers6Str:"+tygers6Str);
    stack.Pattern = readPatterns(stack, &b[offset], stack.dirPath);
    offset += 320;
    //System.out.println("Patterns ok");
    /*String tygers7Str =*/ readStr(&b[offset], 512);
    offset += 512;
    //System.out.println("tygers7Str:"+tygers7Str);
    int remainLength1 = blockSize - ((1538));
    int strlen;
    stack.scriptStr = readTextToZero(&b[offset], remainLength1, &strlen);
    offset += strlen;
    if(strlen<=1){
        stack.scriptStr = readTextToZero(&b[offset], remainLength1, &strlen);
    }
    ////System.out.println("scriptStr:"+scriptStr);
    int remainLength = blockSize - ((1538)+(strlen));
    //System.out.println("remainLength:"+remainLength);
    if(remainLength>0){
        /*String padding =*/ readStr(&b[offset], remainLength);
        //System.out.println("padding:"+padding);
    }
    /*if((result.length_in_src+1)%2 != 0){
     String padding = readStr(&b[offset], 1);
     //System.out.println("padding:"+padding);
     }*/
    
    //スクリプト
    /*String[] scriptAry = scriptStr.split("\n");
    for(int i=0; i<scriptAry.length; i++)
    {
        stack.scriptList.add(scriptAry[i]);
    }*/
    
    return true;
}

static NSString *getVers(int ver){
    NSString * str;
    if((0xFF&(ver>>16))/16>0){
        str = [NSString stringWithFormat:@"%d.%d.%d",(0xFF&(ver>>24)), (0xFF&(ver>>16))/16, (0xFF&(ver>>16))%16];
    }else{
        str = [NSString stringWithFormat:@"%d.%d",(0xFF&(ver>>24)), ((0xFF&(ver>>16))%16)];
    }
    if((0xFF&(ver>>8)) == 0x20) [str stringByAppendingString:@"d"];
    if((0xFF&(ver>>8)) == 0x40) [str stringByAppendingString:@"a"];
    if((0xFF&(ver>>8)) == 0x60) [str stringByAppendingString:@"b"];
    if((0xFF&(ver>>0))/16>0){
        str = [NSString stringWithFormat:@"%@.%d%d",str, (0xFF&(ver>>0))/16, (0xFF&(ver>>0))%16];
    }else if(((0xFF&(ver>>0))%16)>0){
        str = [NSString stringWithFormat:@"%@.%d",str, (0xFF&(ver>>0))%16];
    }
    return str;
}

static NSArray *readPatterns(HCXStack *stack, const UInt8 *b, NSString *parentPath)
{
    NSMutableArray *patAry = [[NSMutableArray alloc] init];
    const int right = 8;
    const int bottom = 8;
    int offset = 0;
    
    for(int i=0; i<40; i++){
        // make CGImage
        CGColorSpaceRef imageColorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate (NULL, right, bottom, 8, right * 4,
                                                      imageColorSpace, kCGImageAlphaPremultipliedLast);
        CGImageRef cgImage = CGBitmapContextCreateImage(context);
        
        // get data-buffer
        CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
        CFDataRef tmpData = CGDataProviderCopyData(dataProvider);
        CFMutableDataRef data = CFDataCreateMutableCopy(0, 0, tmpData);
        UInt32 *db = (UInt32 *)CFDataGetMutableBytePtr(data);
        
        {
            for(int y=0; y<bottom; y++){
                int c = b[offset];offset++;
                //HCStackDebug.read(c);
                for(int x=0; x<right; x++){
                    if(((c>>(7-x))&0x01)==0){
                        db[(y*right)+x] = 0xFFFFFFFF;
                    }else{
                        db[(y*right)+x] = 0xFF000000;
                    }
                }
            }
        }
        
        //PNG形式に変換してファイルに保存
        CFDataRef dstData = CFDataCreate(NULL, (UInt8*)db, CFDataGetLength(data));
        CGDataProviderRef dstDataProvider = CGDataProviderCreateWithCFData(dstData);
        
        CGImageRef dstCGImage = CGImageCreate(
                                              right, bottom,
                                              8, 8*4, right*4,
                                              imageColorSpace, CGImageGetBitmapInfo(cgImage), dstDataProvider,
                                              NULL, CGImageGetShouldInterpolate(cgImage), CGImageGetRenderingIntent(cgImage));
        
        // save as PNG file
        NSString *path = [NSString stringWithFormat:@"%@/PAT_%d.png", stack.dirPath, i+1];
        if(exportCGImage2PNGFileWithDestination(dstCGImage, path)==NO)
        {
            path = nil;
        }
        
        CGColorSpaceRelease(imageColorSpace);
        CGContextRelease(context);
        CGImageRelease(cgImage);
        CFRelease(data);
        CFRelease(tmpData);
        
        [patAry setObject:[path lastPathComponent] atIndexedSubscript:i];
    }
    return patAry;
}
                        
static bool readCardBlock(HCXStack *stack, HCXCard *card, const UInt8 *b, int blockSize){
    //System.out.println("====readCardBlock====");
    
    if(blockSize>2000000 || blockSize<50){
        return false;
    }
    
    int offset = 0;
    
    //ブロックのデータを順次読み込み
    card.pid = readCode(&b[offset], 4);
    offset += 4;
    //HCStackDebug.debuginfo("id:"+Integer.toString(id));
    //System.out.println("id:"+id);
    if(card.pid<0 || card.pid >= 2265535){
        //System.out.println("!");
    }
    /*String tygersStr =*/ readStr(&b[offset], 4);
    offset += 4;
    //HCStackDebug.debuginfo("tygersStr:"+tygersStr);
    //System.out.println("tygersStr:"+tygersStr);
    int bitmapId = readCode(&b[offset], 4);
    offset += 4;
    //HCStackDebug.debuginfo("bitmapId:"+Integer.toString(bitmapId));
    //System.out.println("bitmapId:"+bitmapId);
    if(bitmapId>0){
        card.bitmapName = [NSString stringWithFormat:@"BMAP_%d.png", bitmapId];
    }
    int flags = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("flags:0x"+Integer.toHexString(flags));
    //System.out.println("flags:"+flags);
    card.dontSearch = ((flags>>11)&0x01)!=0;
    card.showPict = !( ((flags>>13)&0x01)!=0);
    card.cantDelete = ((flags>>14)&0x01)!=0;
    /*String tygers2Str =*/ readStr(&b[offset], 10);
    offset += 10;
    //System.out.println("tygers2Str:"+tygers2Str);
    /*int pageId =*/ readCode(&b[offset], 4);
    offset += 4;
    //HCStackDebug.debuginfo("pageId:"+Integer.toString(pageId));
    //System.out.println("pageId:"+pageId);
    card.bgid = readCode(&b[offset], 4);
    offset += 4;
    //HCStackDebug.debuginfo("bgid:"+Integer.toString(bgid));
    //System.out.println("bgid:"+bgid);
    int numofParts = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("numofParts:"+Integer.toString(numofParts));
    //System.out.println("numofParts:"+numofParts);
    /*String tygers3Str =*/ readStr(&b[offset], 6);
    offset += 6;
    //System.out.println("tygers3Str:"+tygers3Str);
    int numofContents = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("numofContents:"+Integer.toString(numofContents));
    //System.out.println("numofContents:"+numofContents);
    /*int scriptType =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("scriptType:"+scriptType);
    
    for(int i=0; i<numofParts; i++){
        //System.out.println("==part "+i+"==");
        //HCStackDebug.debuginfo("==part "+i+"==");
        int dataLen = readCode(&b[offset], 2);
        offset += 2;
        //System.out.println("dataLen:"+dataLen);
        //HCStackDebug.debuginfo("dataLen:"+Integer.toString(dataLen));
        if(dataLen<30){
            //System.out.println("!");
            /*if(dataLen>=0){
             dataLen = (dataLen<<8) + readCode(&b[offset], 1);
             }*/
        }
        int pid = readCode(&b[offset], 2);
        offset += 2;
        //System.out.println("part id:"+pid);
        //HCStackDebug.debuginfo("partid:"+Integer.toString(pid));
        if(offset > blockSize){
            //System.out.println("!");
        }
        if(pid<0 || pid >= 32768){
            //System.out.println("!");
        }
        int partType = readCode(&b[offset], 1);
        offset += 1;
        //System.out.println("partType:"+partType);
        //HCStackDebug.debuginfo("partType:"+Integer.toString(partType));
        if(partType==1){
            HCXButton *btn = [[HCXButton alloc] init];
            btn.pid = pid;
            readButtonBlock(stack, btn, &b[offset], dataLen);
            offset += dataLen-4-1;
            [card.partsList addObject:btn];
        }
        else if(partType==2){
            HCXField *fld = [[HCXField alloc] init];
            fld.pid = pid;
            readFieldBlock(stack, fld, &b[offset], dataLen);
            offset += dataLen-4-1;
            [card.partsList addObject:fld];
        }
        else return false;
        
        //System.out.println("==end of part==");
    }
    
    for(int i=0; i<numofContents; i++){
        if(blockSize - offset<0){
            break;
        }
        //System.out.println("==cd content "+i+"==");
        //HCStackDebug.debuginfo("==cd content "+i+"==");
        
        int pid;
        /*{//アライメント調整
         pid = readCode(&b[offset], 1);
         while(pid<=0 || (pid==255 && i<255) || (pid==254 && i<255)){
         pid = (pid<<8) + readCode(&b[offset], 1);
         }
         }*/
        {
            pid = (int)(0x0000FFFF&readCode(&b[offset], 2));
            offset += 2;
        }
        //System.out.println("pid:"+pid);
        //HCStackDebug.debuginfo("partid:"+Integer.toString(pid));
        if((pid<0 || pid >= 32768) && pid < 6500){
            //System.out.println("!");
        }
        HCXBgField *bgfld = nil;
        if(pid<32768){
            //bg part
            bgfld = [[HCXBgField alloc] init];
            bgfld.pid = pid;
            
            if(readCode(&b[offset], 2)==1){
                // bg buttonの可能性がある
                bgfld.forBgButtonHilite =readCode(&b[offset+2], 1);
            }
            else{
                bgfld.forBgButtonHilite = -1;
            }
        }
        int contLen = (int)(0x0000FFFF & readCode(&b[offset], 2));
        offset += 2;
        int orgcontLen = contLen;
        //System.out.println("contLen:"+contLen);
        //HCStackDebug.debuginfo("contLen:"+Integer.toString(contLen));
        if(offset+contLen+4 > blockSize){
            //HCStackDebug.debuginfo("!!!");
            //HCStackDebug.debuginfo("(offset:"+Integer.toString(offset));
            //HCStackDebug.debuginfo("+contLen:"+Integer.toString(contLen));
            //HCStackDebug.debuginfo(">blockSize):"+Integer.toString(blockSize));
            //System.out.println("!");
            contLen=blockSize-offset-4-2;
            if(contLen<0) contLen = 0;
            //break;
        }
        int isStyledText = (int)(0x0000FF&readCode(&b[offset], 1));
        offset += 1;
        if(isStyledText<128){
            //offset += contLen;
            contLen-=1;
        }
        else if(isStyledText>=128){
            int formattingLength = (int)((0x007F&isStyledText)<<8)+readCode(&b[offset], 1);
            offset += 1;
            //System.out.println("formattingLength:"+formattingLength);
            //HCStackDebug.debuginfo("formattingLength:"+Integer.toString(formattingLength));
            if(formattingLength>100){
                //System.out.println("!");
            }
            for(int j=0; j<formattingLength/4; j++){
                HCXStyleClass *styleC = [[HCXStyleClass alloc] init];
                styleC.textPosition = readCode(&b[offset], 2);
                offset += 2;
                styleC.styleId = readCode(&b[offset], 2);
                offset += 2;
                if(pid>32768){
                    //cd part
                    int inpid = 65536-pid;
                    for(int k=0; k<[card.partsList count]; k++){
                        HCXObject *obj = [card.partsList objectAtIndex:k];
                        if(obj.pid == inpid){
                            if([obj.objectType isEqualToString:@"field"]==YES){
                                HCXField *fld = (HCXField *)obj;
                                if(fld.styleList==nil) fld.styleList = [[NSMutableArray alloc] init];
                                [fld.styleList addObject:styleC];
                                break;
                            }
                        }
                    }
                }
                else{
                    //bg part
                    if(bgfld.styleList==nil) bgfld.styleList = [[NSMutableArray alloc] init];
                    [bgfld.styleList addObject:styleC];
                }
            }
            //offset += contLen;
            contLen -= formattingLength;
        }
        
        //テキスト
        NSString *contentResult = @"";
        int resultLength = 0;
        if(orgcontLen%2==1){
            //System.out.println("readText(contLen+1="+(contLen+1)+")");
            contentResult = readText(&b[offset], contLen+1, &resultLength);
            offset += resultLength;
        }
        else {
            if(contLen>0){
                //System.out.println("readText(contLen="+(contLen)+")");
                contentResult = readText(&b[offset], contLen, &resultLength);
                offset += resultLength;
            }
        }
        //System.out.println("contentResult:"+contentResult.str);
        //HCStackDebug.debuginfo("contentResult:"+contentResult.str);
        if(pid>=32768){
            //cd part
            pid = 65536-pid;
            bool isFound = false;
            for(int k=0; k<[card.partsList count]; k++){
                HCXObject *obj = [card.partsList objectAtIndex:k];
                if(obj.pid == pid){
                    obj.text = contentResult;
                    isFound = true;
                    break;
                }
            }
            if(!isFound){
                //System.out.println("cd part "+pid+" not found.");
            }
        }
        else{
            bgfld.text = contentResult;
            [card.bgfldList addObject:bgfld];
        }
        
        int remainLength = contLen - (resultLength);
        //System.out.println("contentResult.length_in_src:"+contentResult.length_in_src);
        //System.out.println("content-remainLength:"+remainLength);
        //HCStackDebug.debuginfo("content-remainLength:"+remainLength);
        if(remainLength<0 || remainLength > 32){
            //System.out.println("!");
        }
        if(remainLength-1>0){
            /*String padding =*/ readStr(&b[offset], remainLength-1);
            offset += remainLength-1;
            //System.out.println("padding:"+padding);
            //HCStackDebug.debuginfo("padding:"+padding);
        }
    }
    
    /*if(offset%2==0){
     String paddingx = readStr(&b[offset], 1);
     offset++;
     System.out.println("paddingx:"+paddingx);
     HCStackDebug.debuginfo("paddingx:"+paddingx);
     }*/
    
    int nameResultLength;
    NSString *nameResult = readTextToZero(&b[offset], blockSize-offset, &nameResultLength);
    offset += nameResultLength;
    card.name = nameResult;
    //if(id==12332&&name.equals("")){
        //name = "DATAX"; //秘密結社ゲーム対策(暫定)
    //}
    //System.out.println("name:"+name);
    //HCStackDebug.debuginfo("name:"+name);
    
    int scriptStrLength;
    NSString *scriptStr = readTextToZero(&b[offset], blockSize-offset-nameResultLength, &scriptStrLength);
    offset += scriptStrLength;
    //System.out.println("scriptStr:"+scriptStr);
    //HCStackDebug.debuginfo("scriptStr:"+scriptStr);
    
    int remainLength = blockSize - (offset+(nameResultLength)+(scriptStrLength));
    //System.out.println("remainLength:"+remainLength);
    //HCStackDebug.debuginfo("remainLength:"+remainLength);
    if(remainLength > 100){
        //System.out.println("!");
    }
    if(remainLength<0){
        //System.out.println("!");
    }
    if(blockSize==800){
        //System.out.println("!");
    }
    if(remainLength-1>0){
        if(remainLength-1>30 && nameResultLength == 0){
            int scriptResult2Length;
            NSString *scriptResult2 = readText(&b[offset], remainLength-1, &scriptResult2Length);
            //offset += scriptResult2Length;
            scriptStr = scriptResult2;
            //HCStackDebug.debuginfo("set to script.");
        }else{
            /*String padding =*/ readStr(&b[offset], remainLength-1);
            //System.out.println("padding:"+padding);
            //HCStackDebug.debuginfo("padding:"+padding);
        }
        if(nameResultLength == 0 && scriptStrLength<100){
            card.name = scriptStr;
        }
    }
    
    //スクリプト
    card.scriptStr = scriptStr;
    
    return true;
}

                        
static bool readBackgroundBlock(HCXStack *stack, HCXCard *bg, const UInt8 *b, int blockSize){
    //System.out.println("====readBackgroundBlock====");
    
    if(blockSize>2000000 || blockSize<50){
        return false;
    }
    
    int offset = 0;
    
    //ブロックのデータを順次読み込み
    bg.pid = readCode(&b[offset], 4);
    offset += 4;
    //HCStackDebug.debuginfo("bkgndId:"+Integer.toString(bg.pid));
    //System.out.println("id:"+id);
    if(bg.pid<0 || bg.pid >= 2265535){
        //System.out.println("!");
    }
    /*String tygersStr =*/ readStr(&b[offset], 4);
    offset += 4;
    //System.out.println("tygersStr:"+tygersStr);
    int bitmapId = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("bitmapId:"+bitmapId);
    if(bitmapId>0){
        bg.bitmapName = [NSString stringWithFormat:@"BMAP_%d.png", bitmapId];
    }
    int flags = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("flags:"+flags);
    bg.dontSearch = ((flags>>11)&0x01)!=0;
    bg.showPict = !( ((flags>>13)&0x01)!=0);
    bg.cantDelete = ((flags>>14)&0x01)!=0;
    /*String tygers2Str =*/ readStr(&b[offset], 6);
    offset += 6;
    //System.out.println("tygers2Str:"+tygers2Str);
    /*int nextBkgndId =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("nextBkgndId:"+nextBkgndId);
    /*int prevBkgndId =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("prevBkgndId:"+prevBkgndId);
    int numofParts = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("numofParts:"+numofParts);
    /*String tygers3Str =*/ readStr(&b[offset], 6);
    offset += 6;
    //System.out.println("tygers3Str:"+tygers3Str);
    int numofContents = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("numofContents:"+numofContents);
    /*int scriptType =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("scriptType:"+scriptType);
    
    for(int i=0; i<numofParts; i++){
        //System.out.println("==part "+i+"==");
        int dataLen = readCode(&b[offset], 2);
        offset += 2;
        //System.out.println("dataLen:"+dataLen);
        if(dataLen<30){
            //System.out.println("!");
            /*if(dataLen>=0){
             dataLen = (dataLen<<8) + readCode(&b[offset], 1);
             }*/
            dataLen = 30;
        }
        //offset += dataLen;
        int pid = readCode(&b[offset], 2);
        offset += 2;
        //System.out.println("part id:"+pid);
        if((pid<0 || pid >= 32768) && pid < 6500){
            //System.out.println("!");
        }
        int partType = readCode(&b[offset], 1);
        offset += 1;
        //System.out.println("partType:"+partType);
        if(partType==1){
            HCXButton *btn = [[HCXButton alloc] init];
            btn.pid = pid;
            readButtonBlock(stack, btn, &b[offset], dataLen);
            offset += dataLen-4-1;
            [bg.partsList addObject:btn];
        }
        else if(partType==2){
            HCXField *fld = [[HCXField alloc] init];
            fld.pid = pid;
            readFieldBlock(stack, fld, &b[offset], dataLen);
            offset += dataLen-4-1;
            [bg.partsList addObject:fld];
        }
        //else return false;
        
        //System.out.println("==end of part==");
    }
    
    for(int i=0; i<numofContents; i++){
        //System.out.println("==content "+i+"==");
        
        int pid;
        {//アライメント調整
            pid = readCode(&b[offset], 1);
            offset+=1;
            while(pid<=i){
                if(pid<0) pid=0;
                pid = (pid<<8) + readCode(&b[offset], 1);
                offset+=1;
                if(offset>blockSize) return true;//false;
            }
        }
        //{
        //	pid = readCode(&b[offset], 2);
        //}
        //System.out.println("pid:"+pid);
        int contLen = readCode(&b[offset], 2);
        offset+=2;
        int orgcontLen = contLen;
        //System.out.println("contLen:"+contLen);
        //offset += contLen+4;
        if(pid >= 32768){
            /*String padding =*/ readStr(&b[offset], contLen);
            offset+=contLen;
            continue;
        }
        int isStyledText = (int)(0x0000FF&readCode(&b[offset], 1));
        offset+=1;
        if(isStyledText<128){
            contLen-=1;
        }
        else if(isStyledText>=128){
            int formattingLength = (int)((0x007F&isStyledText)<<8)+readCode(&b[offset], 1);
            offset += 1;
            //offset += 2;
            //System.out.println("formattingLength:"+formattingLength);
            if(formattingLength>100){
                //System.out.println("!");
            }
            for(int j=0; j<formattingLength/4; j++){
                HCXStyleClass *styleC = [[HCXStyleClass alloc] init];
                styleC.textPosition = readCode(&b[offset], 2);
                offset += 2;
                styleC.styleId = readCode(&b[offset], 2);
                offset += 2;
                {
                    //cd part
                    int inpid = pid;
                    for(int k=0; k<[bg.partsList count]; k++){
                        HCXObject *obj = [bg.partsList objectAtIndex:k];
                        if(obj.pid == inpid){
                            if([obj.objectType isEqualToString:@"field"]==YES){
                                HCXField *fld = (HCXField *)obj;
                                if(fld.styleList==nil) fld.styleList = [[NSMutableArray alloc] init];
                                [fld.styleList addObject:styleC];
                                break;
                            }
                        }
                    }
                }
            }
            //offset += contLen+4;
            contLen -= formattingLength;
        }
        
        //テキスト
        int contentResultLength = 0;
        NSString *contentResult = @"";
        if(orgcontLen%2==1){
            //System.out.println("readText(contLen+1="+(contLen+1)+")");
            contentResult = readText(&b[offset], contLen+1, &contentResultLength);
            offset += contentResultLength;
        }
        else
            if(contLen>0){
                //System.out.println("readText(contLen="+(contLen)+")");
                contentResult = readText(&b[offset], contLen, &contentResultLength);
                offset += contentResultLength;
            }
        //System.out.println("contentResult:"+contentResult.str);
        //HCStackDebug.debuginfo("contentResult:"+contentResult.str);
        for(int k=0; k<[bg.partsList count]; k++){
            HCXObject *obj = [bg.partsList objectAtIndex:k];
            if(obj.pid == pid){
                obj.text = contentResult;
                break;
            }
        }
        
        int remainLength = contLen - (contentResultLength);
        //System.out.println("content-remainLength:"+remainLength);
        if(remainLength<0 || remainLength > 16){
            //System.out.println("!");
        }
        if(remainLength-1>0){
            /*String padding =*/ readStr(&b[offset], remainLength-1);
            //System.out.println("padding:"+padding);
        }
    }
    
    int nameResultLength;
    NSString *nameResult = readTextToZero(&b[offset], blockSize-offset, &nameResultLength);
    offset += nameResultLength;
    bg.name = nameResult;
    //System.out.println("name:"+name);
    
    int scriptResultLength;
    NSString *scriptResult = readTextToZero(&b[offset], blockSize-offset-nameResultLength, &scriptResultLength);
    offset += scriptResultLength;
    //System.out.println("scriptStr:"+scriptStr);
    
    int remainLength = blockSize - (offset+(nameResultLength)+(scriptResultLength));
    //System.out.println("remainLength:"+remainLength);
    if(remainLength > 100){
        //System.out.println("!");
    }
    if(remainLength<0){
        //System.out.println("!");
    }
    if(remainLength-1>0){
        if(remainLength-1>30 && nameResultLength == 0){
            int scriptResult2Length;
            NSString *scriptResult2 = readText(&b[offset], remainLength-1, &scriptResult2Length);
            //offset += scriptResult2Length;
            scriptResult = scriptResult2;
        }else{
            /*String padding =*/ readStr(&b[offset], remainLength-1);
            //offset += remainLength-1;
            //System.out.println("padding:"+padding);
        }
        if(nameResultLength == 0 && scriptResultLength<200){
            bg.name = scriptResult;
        }
    }
    /*if((nameResult.length_in_src+1+scriptResult.length_in_src+1)%2 != 0){
     String padding = readStr(&b[offset], 1);
     System.out.println("padding:"+padding);
     }*/
    
    //スクリプト
    bg.scriptStr = scriptResult;
    
    return true;
}
                        

static bool readButtonBlock(HCXStack *stack, HCXButton *btn, const UInt8 *b, int partSize){
    //System.out.println("====readButtonBlock====");
    //ブロックのデータを順次読み込み
    int offset = 0;
    int flags = readCode(&b[offset], 1);
    offset += 1;
    //System.out.println("flags:"+flags);
    btn.visible = (((flags>>7)&0x01)==0);
    //dontWrap = !( ((flags>>5)&0x01)!=0);
    //dontSearch = ((flags>>4)&0x01)!=0;
    //sharedText = ((flags>>3)&0x01)!=0;
    //fixedLineHeight = ! (((flags>>2)&0x01)!=0);
    //autoTab = ((flags>>1)&0x01)!=0;
    btn.enabled = ! (((flags>>0)&0x01)!=0);
    btn.top = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("top:"+top);
    btn.left = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("left:"+left);
    int bottom = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("bottom:"+bottom);
    btn.height = bottom - btn.top;
    int right = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("right:"+right);
    btn.width = right - btn.left;
    int flags2 = readCode(&b[offset], 1);
    offset += 1;
    btn.showName = ((flags2>>7)&0x01)!=0;
    btn.hilite = ((flags2>>6)&0x01)!=0;
    btn.autoHilite = ((flags2>>5)&0x01)!=0;
    btn.sharedHilite = !(((flags2>>4)&0x01)!=0);
    btn.group = (flags2)&0x0F;
    int style = readCode(&b[offset], 1);
    offset += 1;
    //0標準 1透明 2不透明 3長方形 4シャドウ 5丸みのある長方形 6省略時設定 7楕円 8ポップアップ 9チェックボックス 10ラジオ
    switch(style){
        case 0: btn.style = 1; break;//transparent
        case 1: btn.style = 2; break;//opaque
        case 2: btn.style = 3; break;//rectangle
        case 3: btn.style = 5; break;//roundRect
        case 4: btn.style = 4; break;//shadow
        case 5: btn.style = 9; break;//checkBox
        case 6: btn.style = 10; break;//radioButton
            //case 7: this.style = 0; break;//scrolling
        case 8: btn.style = 0; break;//standard
        case 9: btn.style = 6; break;//default
        case 10: btn.style = 7; break;//oval
        case 11: btn.style = 8; break;//popup
    }
    btn.titleWidth = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("titleWidth:"+titleWidth);
    if(btn.style == 8){
        btn.selectedLine = readCode(&b[offset], 2);
        offset += 2;
        //System.out.println("selectedLine:"+selectedLine);
    }
    else{
        btn.icon = readCode(&b[offset], 2);
        offset += 2;
        //System.out.println("icon:"+icon);
    }
    int inTextAlign = readCode(&b[offset], 2);
    offset += 2;
    switch(inTextAlign){
        case 0: btn.textAlign = 0; break;
        case 1: btn.textAlign = 1; break;
        case -1: btn.textAlign = 2; break;
    }
    //System.out.println("inTextAlign:"+inTextAlign);
    int textFontID = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("textFontID:"+textFontID);
    btn.textSize = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("textSize:"+textSize);
    btn.textStyle = readCode(&b[offset], 1);
    offset += 1;
    //System.out.println("textStyle:"+textStyle);
    /*int filler =*/ readCode(&b[offset], 1);
    offset += 1;
    //System.out.println("filler:"+filler);
    btn.textHeight = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("textHeight:"+textHeight);
    int nameResultLength;
    NSString *nameResult = readTextToZero(&b[offset], partSize - 30, &nameResultLength);
    offset += nameResultLength;
    btn.name = nameResult;
    //HCStackDebug.debuginfo("name:"+name);
    //System.out.println("name:"+name);
    /*int filler2 =*/// readCode(&b[offset], 1);
    //System.out.println("filler2:"+filler2);
    int scriptResultLength;
    offset++; //####
    NSString *scriptResult = readText(&b[offset], partSize - 30 - nameResultLength, &scriptResultLength);
    offset += scriptResultLength;
    NSString *scriptStr = scriptResult;
    //System.out.println("scriptStr:"+scriptStr);
    
    //フォント名をテーブルから検索
    for(int i=0; i<[stack.fontList count];i++){
        HCXObject *obj = [stack.fontList objectAtIndex:i];
        if(obj.pid ==textFontID){
            btn.textFont = obj.name;
            break;
        }
    }
    
    int remainLength = partSize - (30+(nameResultLength)+(scriptResultLength));
    //System.out.println("remainLength:"+remainLength);
    //HCStackDebug.debuginfo("remainLength:"+remainLength);
    if(remainLength<0 || remainLength > 1000){
        //System.out.println("!");
    }
    if(remainLength>0){
        /*String padding =*/ readStr(&b[offset], remainLength);
        //offset += remainLength;
        //System.out.println("padding:"+padding);
        //HCStackDebug.debuginfo("padding:"+padding);
    }
    /*if((nameResult.length_in_src+1+scriptResult.length_in_src+1)%2 != 0){
     String padding = readStr(&b[offset], 1);
     System.out.println("padding:"+padding);
     }*/
    
    //スクリプト
    btn.scriptStr = scriptStr;
    
    return true;
}

static bool readFieldBlock(HCXStack *stack, HCXField *fld, const UInt8 *b, int partSize){
    //System.out.println("====readFieldBlock====");
    //ブロックのデータを順次読み込み
    int offset = 0;
    int flags = readCode(&b[offset], 1);
    offset += 1;
    //System.out.println("flags:"+flags);
    fld.visible = (((flags>>7)&0x01)==0);
    fld.dontWrap = ((flags>>5)&0x01)!=0;
    fld.dontSearch = ((flags>>4)&0x01)!=0;
    fld.sharedText = ((flags>>3)&0x01)!=0;
    fld.fixedLineHeight = ! (((flags>>2)&0x01)!=0);
    fld.autoTab = ((flags>>1)&0x01)!=0;
    fld.lockText = (((flags>>0)&0x01)!=0);
    fld.top = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("top:"+top);
    fld.left = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("left:"+left);
    int bottom = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("bottom:"+bottom);
    fld.height = bottom - fld.top;
    int right = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("right:"+right);
    fld.width = right - fld.left;
    int flags2 = readCode(&b[offset], 1);
    offset += 1;
    fld.autoSelect = ((flags2>>7)&0x01)!=0;
    fld.showLines = ((flags2>>6)&0x01)!=0;
    fld.wideMargins = ((flags2>>5)&0x01)!=0;
    fld.multipleLines = ((flags2>>4)&0x01)!=0;
    //group = (flags2)&0x0F;
    int style = readCode(&b[offset], 1);
    offset += 1;
    //0標準 1透明 2不透明 3長方形 4シャドウ 5丸みのある長方形 6省略時設定 7楕円 8ポップアップ 9チェックボックス 10ラジオ
    switch(style){
        case 0: fld.style = 1; break;//transparent
        case 1: fld.style = 2; break;//opaque
        case 2: fld.style = 3; break;//rectangle
            //case 3: this.style = 5; break;//roundRect
        case 4: fld.style = 4; break;//shadow
            //case 5: this.style = 9; break;//checkBox
            //case 6: this.style = 10; break;//radioButton
        case 7: fld.style = 5; break;//scrolling
            //case 8: this.style = 0; break;//standard
            //case 9: this.style = 6; break;//default
            //case 10: this.style = 7; break;//oval
            //case 11: this.style = 8; break;//popup
    }
    fld.selectedEnd = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("selectedEnd:"+selectedEnd);
    fld.selectedStart = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("selectedStart:"+selectedStart);
    fld.selectedLine = fld.selectedStart;
    int inTextAlign = readCode(&b[offset], 2);
    offset += 2;
    switch(inTextAlign){
        case 0: fld.textAlign = 0; break;
        case 1: fld.textAlign = 1; break;
        case -1: fld.textAlign = 2; break;
    }
    //System.out.println("inTextAlign:"+inTextAlign);
    int textFontID = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("textFontID:"+textFontID);
    fld.textSize = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("textSize:"+textSize);
    fld.textStyle = readCode(&b[offset], 1);
    offset += 1;
    //System.out.println("textStyle:"+textStyle);
    /*int filler =*/ readCode(&b[offset], 1);
    offset += 1;
    //System.out.println("filler:"+filler);
    fld.textHeight = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("textHeight:"+textHeight);
    int nameResultLength;
    NSString *nameResult = readTextToZero(&b[offset], partSize - 30, &nameResultLength);
    offset += nameResultLength;
    fld.name = nameResult;
    //System.out.println("name:"+name);
    //HCStackDebug.debuginfo("name:"+name);
    /*int filler2 =*/ //readCode(&b[offset], 1);
    //System.out.println("filler2:"+filler2);
    int scriptResultLength;
    offset++; //####
    NSString *scriptResult = readText(&b[offset], partSize - 30 - nameResultLength, &scriptResultLength);
    offset += scriptResultLength;
    NSString *scriptStr = scriptResult;
    //System.out.println("scriptStr:"+scriptStr);
    
    //フォント名をテーブルから検索
    for(int i=0; i<[stack.fontList count];i++){
        HCXObject *obj = [stack.fontList objectAtIndex:i];
        if(obj.pid ==textFontID){
            fld.textFont = obj.name;
            break;
        }
    }
    
    int remainLength = partSize - (30+(nameResultLength)+(scriptResultLength));
    //System.out.println("remainLength:"+remainLength);
    //HCStackDebug.debuginfo("remainLength:"+remainLength);
    if(remainLength<0 || remainLength > 10){
        //System.out.println("!");
    }
    if(remainLength>0){
        /*String padding =*/ readStr(&b[offset], remainLength);
        //offset += remainLength;
        //System.out.println("padding:"+padding);
        //HCStackDebug.debuginfo("padding:"+padding);
    }
    /*if((nameResult.length_in_src+1+scriptResult.length_in_src+1)%2 != 0){
     String padding = readStr(&b[offset], 1);
     System.out.println("padding:"+padding);
     }*/
    
    //スクリプト
    fld.scriptStr = scriptStr;
    
    return true;
}

static bool readStyleBlock(HCXStack *stack, const UInt8 *b, int blockSize)
{
    //System.out.println("readStyleBlock");
    
    if(blockSize>200000 || blockSize<24){
        return false;
    }
    
    int offset = 0;
    
    //ブロックのデータを順次読み込み
    /*int blockId =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("blockId:"+blockId);
    /*int filler =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("filler:"+filler);
    int styleCount = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("styleCount:"+styleCount);
    stack.nextStyleID = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("nextStyleID:"+nextStyleID);
    
    for(int i=0; i<styleCount; i++){
        int styleId = readCode(&b[offset], 4);
        offset += 4;
        //System.out.println("styleId:"+styleId);
        /*int something1 =*/ readCode(&b[offset], 4);
        offset += 4;
        //System.out.println("something1:"+something1);
        /*int something2 =*/ readCode(&b[offset], 4);
        offset += 4;
        //System.out.println("something2:"+something2);
        int textFontId = readCode(&b[offset], 2);
        offset += 2;
        //System.out.println("textFontId:"+textFontId);
        int textStyle = readCode(&b[offset], 1);
        offset += 1;
        //System.out.println("textStyle:"+textStyle);
        int textStyleChanged = readCode(&b[offset], 1);
        offset += 1;
        //System.out.println("textStyleChanged:"+textStyleChanged);
        int textSize = readCode(&b[offset], 2);
        offset += 2;
        //System.out.println("textSize:"+textSize);
        /*String filler2 =*/ readStr(&b[offset], 6);
        offset += 6;
        //System.out.println("filler2:"+filler2);
        
        NSString *idStr = [NSString stringWithFormat:@"%d", styleId];
        NSString *fontStr = [NSString stringWithFormat:@"%d", textFontId];
        NSMutableString *styleStr = [NSMutableString stringWithString:@""];
        if(textStyleChanged==255){ //style unchange
            //styleStr = @"";
        }
        else{
            if(textStyle==0){
                styleStr = [NSMutableString stringWithString:@"plain"];
            }
            else{
                if((textStyle&1)>0) [styleStr appendString:@"bold "];
                if((textStyle&2)>0) [styleStr appendString:@"italic "];
                if((textStyle&4)>0) [styleStr appendString:@"underline "];
                if((textStyle&8)>0) [styleStr appendString:@"outline "];
                if((textStyle&16)>0) [styleStr appendString:@"shadow "];
                if((textStyle&32)>0) [styleStr appendString:@"condensed "];
                if((textStyle&64)>0) [styleStr appendString:@"extend "];
                if((textStyle&128)>0) [styleStr appendString:@"group "];
            }
        }
        NSString *sizeStr = [NSString stringWithFormat:@"%d", textSize];
        NSArray *styleClass = [NSArray arrayWithObjects:idStr, styleStr, fontStr, sizeStr, nil];
        [stack.styleList addObject:styleClass];
    }
    int remainLength = blockSize - offset;
    /*String padding =*/ readStr(&b[offset], remainLength);
    //System.out.println("padding:"+padding);
    
    return true;
}


static bool readFontBlock(HCXStack *stack, const UInt8 *b, int blockSize)
{
    //System.out.println("readFontBlock");
    
    if(blockSize>200000 || blockSize<24){
        return false;
    }
    //ブロックのデータを順次読み込み
    int offset = 0;
    /*int blockId =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("blockId:"+blockId);
    /*String tygersStr =*/ readStr(&b[offset], 6);
    offset += 6;
    //System.out.println("tygersStr:"+tygersStr);
    int numOfFonts = readCode(&b[offset], 2);
    offset += 2;
    //System.out.println("numOfFonts:"+numOfFonts);
    /*String tygers2Str =*/ readStr(&b[offset], 4);
    offset += 4;
    //System.out.println("tygers2Str:"+tygers2Str);
    
    for(int i=0; i<numOfFonts; i++){
        int fontId = readCode(&b[offset], 2);
        offset+=2;
        //System.out.println("fontId:"+fontId);
        int nameLen;// = readCode(&b[offset], 1);
        //offset+=1;
        //System.out.println("nameLen:"+nameLen);
        //if(offset+nameLen>blockSize){
        //break;
        nameLen = blockSize - offset;
        //if(nameLen<0)break;
        //}
        int nameResultLength;
        NSString *nameResult = readTextToZero(&b[offset], nameLen, &nameResultLength);
        //System.out.println("nameResult.str:"+nameResult.str);
        offset+=nameResultLength;
        if((nameResultLength+1)%2==0){
            readCode(&b[offset], 1);
            offset+=1;
        }
        
        //フォントIDと名前を登録
        HCXObject *obj = [[HCXObject alloc] init];
        obj.pid = fontId;
        obj.name = nameResult;
        [stack.fontList addObject:obj];
    }
    
    int remainLength = blockSize - offset;
    /*String padding =*/ readStr(&b[offset], remainLength);
    //System.out.println("padding:"+padding);
    
    return true;
}



static bool readListBlock(HCXStack *stack, const UInt8 *b, int blockSize)
{
    //System.out.println("readListBlock");
    
    if(blockSize>200000 || blockSize<12){
        return false;
    }
    
    //ブロックのデータを順次読み込み
    int offset = 0;
    stack.listId = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("listId:"+listId);
    /*int filler =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("filler:"+filler);
    int pageCount = readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("pageCount:"+pageCount);
    /*int pageSize =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("pageSize:"+pageSize);
    /*int pageEntryTotal =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("pageEntryTotal:"+pageEntryTotal);
    stack.pageEntrySize = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("\n pageEntrySize:"+pageEntrySize);
    /*int filler2 =*/ readCode(&b[offset], 10);
    offset += 10;
    //System.out.println("filler2:"+filler2);
    /*int pageEntryTotal2 =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("pageEntryTotal2:"+pageEntryTotal2);
    /*int filler3 =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("filler3:"+filler3);
    
    //pageIdList = new int[pageCount];
    //pageEntryCountList = new int[pageCount];
    for(int i=0; i<pageCount; i++){
        int num = readCode(&b[offset], 4);
        offset += 4;
        [stack.pageIdList addObject:[NSNumber numberWithInt:num]];
        //HCStackDebug.debuginfo("\n pageIdList["+i+"]:"+pageEntryCountList[i]);
        //System.out.println("pageId:"+pageIdList[i]);
         int num2 = readCode(&b[offset], 2);
         offset += 2;
         [stack.pageEntryCountList addObject:[NSNumber numberWithInt:num2]];
        //HCStackDebug.debuginfo(" pageEntryCountList["+i+"]:"+pageEntryCountList[i]);
        //System.out.println("pageEntryCount:"+pageEntryCountList[i]);
    }
    
    int remainLength = blockSize-(48+pageCount*6);
    if(remainLength>0){
        /*String padding =*/ readStr(&b[offset], remainLength);
        //System.out.println("padding:"+padding);
    }
    
    return true;
}


static bool readPageBlock(HCXStack *stack, const UInt8 *b, int blockSize)
{
    //System.out.println("readPageBlock");
    
    //HCStackDebug.write(" readPageBlock blockSize:"+blockSize);
    if(blockSize>200000 || blockSize<12){
        return false;
    }
    
    //HCStackDebug.debuginfo(" pageIdList:"+pageIdList);
    //HCStackDebug.debuginfo(" pageEntryCountList:"+pageEntryCountList);
    if(stack.pageIdList==NULL || stack.pageEntryCountList==NULL){
        //return false;
    }
    
    int offset = 0;
    
    //ブロックのデータを順次読み込み
    int pageId = readCode(&b[offset], 4);
    offset += 4;
    //HCStackDebug.debuginfo(" pageId:"+pageId);
    //System.out.println("pageId:"+pageId);
    /*int filler =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("filler:"+filler);
    /*int listId =*/ readCode(&b[offset], 4);
    offset += 4;
    //HCStackDebug.debuginfo(" listId:"+listId);
    //System.out.println("listId:"+listId);
    /*int filler2 =*/ readCode(&b[offset], 4);
    offset += 4;
    //System.out.println("filler2:"+filler2);
    
    int pageEntryCount = 0;
    if(stack.pageIdList!=NULL&&stack.pageEntryCountList!=NULL){
        for(int i=0; i<[stack.pageIdList count]; i++){
            if([[stack.pageIdList objectAtIndex:i] intValue] == pageId){
                NSNumber *number = [stack.pageEntryCountList objectAtIndex:i];
                pageEntryCount =  [number intValue];
                break;
            }
        }
    }
    else{
        stack.pageEntrySize = 8;
        pageEntryCount = (blockSize-offset)/stack.pageEntrySize;
    }
    
    int intAry[(blockSize-24)/4];
    memset(intAry, 0x00, (blockSize-24)/4);
    for(;offset<blockSize;offset+=4){
        intAry[(offset-16)/4] = readCode(&b[offset], 4);
        offset += 4;
    }
    
    //うまくpageEntrySizeがとれてない場合の対策として、それっぽく読めるまで4ずつ増やす
    for(int size=stack.pageEntrySize; size<128; size+=4){
        bool errFlag = false;
        //HCStackDebug.debuginfo("\n--------------");
        //HCStackDebug.debuginfo(" size:"+size);
        if(size!=stack.pageEntrySize){
            pageEntryCount = (blockSize-24)/stack.pageEntrySize;
        }
        for(int i=0; i<pageEntryCount; i++){
            int cardId = intAry[i*size/4];
            //HCStackDebug.debuginfo(" cardId:"+cardId);
            if( cardId<0 || cardId>10000000){
                errFlag = true;
                break;
            }
            if( cardId==0){
                continue;
            }
            if([stack GetCardIdList:cardId]==-1){
                [stack.cardIdList addObject:[NSNumber numberWithInt:cardId]]; //cardのidリストに追加
                [stack.cardMarkedList addObject:[NSNumber numberWithInt:false]];
            }
            if(size>4){
                int flags = intAry[i*size/4+1];
                if((flags & 0x10000000)!=0){
                    [stack.cardMarkedList removeLastObject];
                    [stack.cardMarkedList addObject:[NSNumber numberWithInt:true]];
                }
            }
        }
        if(!errFlag)break;
    }
    
    /*
     for(int i=0; i<pageEntryCount; i++){
     int cardId = readCode(&b[offset], 4);
     offset+=4;
     //System.out.println("cardId:"+cardId);
     HCStackDebug.debuginfo(" cardId:"+cardId);
     if(cardId<=0){
     continue;
     }
     if(GetCardbyId(cardId)==null){
     cardIdList.add(cardId); //cardのidリストに追加
     cardMarkedList.add(false);
     }
     if(pageEntrySize>4){
     int flags = readCode(&b[offset], 4);
     if((flags & 0x10000000)!=0){
     cardMarkedList.remove(cardMarkedList.size()-1);
     cardMarkedList.add(true);
     }
     if(pageEntrySize-8 > 0){
     HCData.readStr(dis, pageEntrySize-8);
     }
     offset+=pageEntrySize-4;
     //System.out.println("something:"+something);
     }
     }*/
    
    int remainLength = blockSize-offset;
    if(remainLength>0){
        /*String padding =*/ readStr(&b[offset], remainLength);
        //System.out.println("padding:"+padding);
    }
    
    return true;
}

static bool readPictureBlock(HCXStack *stack, const UInt8 *b, int blockSize)
{
    //System.out.println("readPictureBlock");
    
    if(blockSize>200000 || blockSize < 0){
        return false;
    }
    
    //ブロックのデータを順次読み込み
    int offset = 0;
    int bitmapId = readCode(&b[offset], 4);
    offset += 4;
    //HCStackDebug.debuginfo("bitmapId:"+Integer.toString(bitmapId));
    //System.out.println("bitmapId:"+bitmapId);
    /*String filler =*/ readStr(&b[offset], 12);
    offset += 12;
    //System.out.println("filler:"+filler);
    
    int top = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("top:"+Integer.toString(top));
    int left = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("left:"+Integer.toString(left));
    int bottom = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("bottom:"+Integer.toString(bottom));
    int right = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("right:"+Integer.toString(right));
    
    int maskTop = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("maskTop:"+Integer.toString(maskTop));
    int maskLeft = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("maskLeft:"+Integer.toString(maskLeft));
    int maskBottom = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("maskBottom:"+Integer.toString(maskBottom));
    int maskRight = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("maskRight:"+Integer.toString(maskRight));
    
    int imgTop = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("imgTop:"+Integer.toString(imgTop));
    int imgLeft = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("imgLeft:"+Integer.toString(imgLeft));
    int imgBottom = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("imgBottom:"+Integer.toString(imgBottom));
    int imgRight = readCode(&b[offset], 2);
    offset += 2;
    //HCStackDebug.debuginfo("imgRight:"+Integer.toString(imgRight));
    
    /*String filler2 =*/ readStr(&b[offset], 8);
    offset += 8;
    //System.out.println("filler2:"+filler2);
    
    int maskSize = readCode(&b[offset], 4);
    offset += 4;
    //HCStackDebug.debuginfo("maskSize:"+Integer.toString(maskSize));
    int imgSize = readCode(&b[offset], 4);
    offset += 4;
    //HCStackDebug.debuginfo("imgSize:"+Integer.toString(imgSize));
    
    if(blockSize < 64+maskSize+imgSize){
        //System.out.println("!:");
        return false;
    }
    if(maskSize<0 || imgSize<0){
        //System.out.println("!:");
        return false;
    }
    
    //マスクをbyte配列にロード
    UInt8 maskbyte[maskSize>0?maskSize:1];
    UInt8 *mask = NULL;
    if(maskSize>0){
        mask = maskbyte;
        {
            memcpy(mask, &b[offset], maskSize);
            offset += maskSize;
        }
    }
    
    //イメージをbyte配列にロード
    UInt8 img[imgSize];
    memcpy(img, &b[offset], imgSize);
    //offset += imgSize;

    //bgに登録されているbitmapIDか？(スタックのデータを読み切ってしまわないと見逃してしまう場合あり)
    BOOL isBgPicture = false;
    /*for(int i=0; i<stack.bgCacheList.size(); i++){
     if(stack.bgCacheList.get(i).bitmapName!=null && stack.bgCacheList.get(i).bitmapName.equals("BMAP_"+bitmapId+".png")){
     isBgPicture = true;
     break;
     }
     }*/
    
    CGColorSpaceRef imageColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate (NULL, right, bottom, 8, right * 4,
                                                  imageColorSpace, kCGImageAlphaPremultipliedLast);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    // get data-buffer
    CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
    CFDataRef tmpData = CGDataProviderCopyData(dataProvider);
    CFMutableDataRef data = CFDataCreateMutableCopy(0, 0, tmpData);
    UInt32 *maindb = (UInt32 *)CFDataGetMutableBytePtr(data);
    
    //
    CGColorSpaceRef maskImageColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef maskContext = CGBitmapContextCreate (NULL, right, bottom, 8, right * 4,
                                                  maskImageColorSpace, kCGImageAlphaPremultipliedLast);
    CGImageRef maskCgImage = CGBitmapContextCreateImage(maskContext);
    
    // get data-buffer
    CGDataProviderRef maskDataProvider = CGImageGetDataProvider(maskCgImage);
    CFDataRef maskTmpData = CGDataProviderCopyData(maskDataProvider);
    CFMutableDataRef maskData = CFDataCreateMutableCopy(0, 0, maskTmpData);
    UInt32 *maskdb = (UInt32 *)CFDataGetMutableBytePtr(maskData);
    
    if(mask!=NULL){
        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
        CGContextFillRect(context, CGRectMake(0,0,right,bottom));
        readWOBA(maskdb, mask, maskSize, bitmapId, right, bottom, maskLeft, maskTop, maskRight, maskBottom, false);
    }
    
    if(isBgPicture){
        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
        CGContextFillRect(context, CGRectMake(0,0,right,bottom));
    }
    else{
        CGContextClearRect(context, CGRectMake(0,0,right,bottom));
    }
    readWOBA(maindb, img, imgSize, bitmapId, right, bottom, imgLeft, imgTop, imgRight, imgBottom, isBgPicture);
    
    //アルファチャンネル付きのイメージに合成
    if(mask!=NULL){
        if(imgTop>top || imgBottom<bottom || imgLeft>left || imgRight<right){ //なんかよくわからんけど、範囲が一部のみになっているときだけマスクが逆に思える
            for(int y=top; y<bottom; y++){
                for(int x=left; x<right; x++){
                    int v = 0x00FFFFFF&maindb[x+y*right];
                    if((0xFF000000&maindb[x+y*right])==0){
                        continue;
                    }
                    if(v!=0){
                        v = v | (0xFF000000&(maskdb[x+y*right]<<24));
                    }
                    else {
                        v = v | 0xFF000000;
                    }
                    maindb[x+y*right] = v;
                }
            }
        }else{
            for(int y=top; y<bottom; y++){
                for(int x=left; x<right; x++){
                    int v = 0x00FFFFFF&maindb[x+y*right];
                    if((0xFF000000&maindb[x+y*right])==0){
                        continue;
                    }
                    if(v!=0){
                        v = v | (0xFF000000&(~maskdb[x+y*right]<<24));
                    }
                    else {
                        v = v | 0xFF000000;
                    }
                    maindb[x+y*right] = v;
                }
            }
        }
    }
    else if(!isBgPicture){
        for(int y=imgTop; y<imgBottom; y++){
            for(int x=imgLeft; x<imgRight; x++){
                int v = 0x00FFFFFF & maindb[x+y*right];
                if(v!=0) v = 0xFFFFFFFF;
                else v = 0xFF000000;
                maindb[x+y*right] = v;
            }
        }
    }
    
    //ファイルに保存
    CFDataRef dstData = CFDataCreate(NULL, (UInt8*)maindb, CFDataGetLength(data));
    CGDataProviderRef dstDataProvider = CGDataProviderCreateWithCFData(dstData);
    
    CGImageRef dstCGImage = CGImageCreate(
                                          right, bottom,
                                          8, 8*4, right*4,
                                          imageColorSpace, CGImageGetBitmapInfo(cgImage), dstDataProvider,
                                          NULL, CGImageGetShouldInterpolate(cgImage), CGImageGetRenderingIntent(cgImage));
    
    // save as PNG file
    NSString *path = [NSString stringWithFormat:@"%@/BMAP_%d.png", stack.dirPath, bitmapId];
    if(exportCGImage2PNGFileWithDestination(dstCGImage, path)==NO)
    {
        path = nil;
    }
    
    CGImageRelease(dstCGImage);
    CFRelease(dstDataProvider);
    CFRelease(dstData);
    
    CGColorSpaceRelease(imageColorSpace);
    CGContextRelease(context);
    CGImageRelease(cgImage);
    CFRelease(data);
    CFRelease(tmpData);
    
    CGColorSpaceRelease(maskImageColorSpace);
    CGContextRelease(maskContext);
    CGImageRelease(maskCgImage);
    CFRelease(maskData);
    CFRelease(maskTmpData);
    
    return true;
}


//HyperCardのピクチャフォーマット(Wrath Of Bill Atkinson)の読み込み
static void readWOBA(UInt32 *db, const UInt8 *img, int imgLength, int bitmapId, int cdWidth, int cdHeight, int left, int top, int right, int bottom, BOOL isBgPicture)
{
    left = left/32*32;
    right = (right+31)/32*32;
    //String debugStr = "";
    
    UInt8 keepArray[] = {0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55};
    int dh = 0;
    int dv = 0;
    int repeatInstructionCount = 0;
    int repeatInstructionIndex = 0;
    
    int i=0;
    for(int y=top; y<bottom; y++){
        //debugStr += "\n"+"line "+y;//####
        
        int opcode = 0;
        int x = left;
        for(; i<imgLength && x < right; /*i++*/){
            if(repeatInstructionCount>0){
                i = repeatInstructionIndex;
                repeatInstructionCount--;
                //debugStr += "rep ";//####
            }
            opcode = (0x00FF&img[i]);
            i++;
            //System.out.println("opcode("+i+")="+Integer.toHexString(opcode));
            //debugStr += "["+Integer.toHexString(opcode)+"]";//####
            
            if(opcode <= 0x7F){
                int dataBytes = opcode>>4;
                int zeroBytes = opcode & 0x0F;
                
                for(int j=0; j<zeroBytes; j++){
                    for(int k=0; k<8 && x<right; k++){
                        db[x+y*cdWidth] = 0xFFFFFFFF;
                        x++;
                    }
                }
                for(int j=0; j<dataBytes && i<imgLength; j++){
                    for(int k=0; k<8; k++){
                        db[x+y*cdWidth] = (0x01&(img[i]>>(7-k)))!=0?0xFF000000:0xFFFFFFFF;
                        x++;
                    }
                    //debugStr += Integer.toHexString((int)(0x00ff&img[i]))+" ";//####
                    i++;
                }
            }
            else if(opcode >= 0x80 && opcode <= 0x8F){
                switch(opcode){
                    case 0x80: //1行分無圧縮
                        while(x<right && i<imgLength){
                            for(int k=0; k<8; k++){
                                db[x+y*cdWidth] = (0x01&(img[i]>>(7-k)))!=0?0xFF000000:0xFFFFFFFF;
                                x++;
                            }
                            //debugStr += Integer.toHexString((int)(0x00FF&img[i]))+" ";//####
                            i++;
                        }
                        break;
                    case 0x81: //1行白
                        while(x<right){
                            db[x+y*cdWidth] = 0xFFFFFFFF;
                            x++;
                        }
                        break;
                    case 0x82: //1行黒
                        while(x<right){
                            db[x+y*cdWidth] = 0xFF000000;
                            x++;
                        }
                        break;
                    case 0x83: //1行同一バイト
                        while(x<right){
                            for(int k=0; k<8; k++){
                                db[x+y*cdWidth] = (0x01&(img[i]>>(7-k)))!=0?0xFF000000:0xFFFFFFFF;
                                x++;
                            }
                        }
                        //debugStr += Integer.toHexString(img[i])+" ";//####
                        keepArray[y%8] = img[i];
                        i++;
                        break;
                    case 0x84: //1行同一バイト,保持配列のデータを使う
                        while(x<right){
                            for(int k=0; k<8; k++){
                                db[x+y*cdWidth] = (0x01&(keepArray[y%8]>>(7-k)))!=0?0xFF000000:0xFFFFFFFF;
                                x++;
                            }
                        }
                        //debugStr += "keep "+Integer.toHexString((int)(0x00FF&keepArray[y%8]))+" ";//####
                        break;
                    case 0x85: //1行上をコピー
                        while(x<right){
                            for(int k=0; k<8; k++){
                                db[x+y*cdWidth] = db[x+(y-1)*cdWidth];
                                x++;
                            }
                        }
                        break;
                    case 0x86: //2行上をコピー
                        while(x<right){
                            for(int k=0; k<8; k++){
                                db[x+y*cdWidth] = db[x+(y-2)*cdWidth];
                                x++;
                            }
                        }
                        break;
                    case 0x87: //3行上をコピー
                        while(x<right){
                            for(int k=0; k<8; k++){
                                db[x+y*cdWidth] = db[x+(y-3)*cdWidth];
                                x++;
                            }
                        }
                        break;
                    case 0x88:
                        dh = 16; dv = 0; //16bit右シフトしてXOR
                        break;
                    case 0x89:
                        dh = 0; dv = 0; //
                        break;
                    case 0x8A:
                        dh = 0; dv = 1; //1行上とXOR
                        break;
                    case 0x8B:
                        dh = 0; dv = 2; //2行上とXOR
                        break;
                    case 0x8C:
                        dh = 1; dv = 0; //1bit右シフトしてXOR
                        break;
                    case 0x8D:
                        dh = 1; dv = 1; //1bit右シフト、1行上とXOR
                        break;
                    case 0x8E:
                        dh = 2; dv = 2; //2bit右シフト、2行上とXOR
                        break;
                    case 0x8F:
                        dh = 8; dv = 0; //8bit右シフトしてXOR
                        break;
                        
                    default:
                        //System.out.println("!");
                        break;
                }
            }
            else if(opcode >= 0xA0 && opcode <= 0xBF){
                //下5bit分、次のバイトのopcodeを繰り返す
                repeatInstructionCount = (0x1F & opcode);
                repeatInstructionIndex = i;
            }
            else if(opcode >= 0xC0 && opcode <= 0xDF){
                //下5bit*8分のデータ
                int count = (0x1F & opcode)*8;
                while(count>0 && x<cdWidth && i<imgLength){
                    for(int k=0; k<8; k++){
                        db[x+y*cdWidth] = (0x01&(img[i]>>(7-k)))!=0?0xFF000000:0xFFFFFFFF;
                        x++;
                    }
                    count--;
                    //debugStr += Integer.toHexString((int)(0x00FF&img[i]))+" ";//####
                    i++;
                }
            }
            else if(opcode >= 0xE0 && opcode <= 0xFF){
                //下5bit*16分のゼロ
                int count = (0x1F & opcode)*16;
                while(count>0 && x<cdWidth){
                    for(int k=0; k<8; k++){
                        db[x+y*cdWidth] = 0xFFFFFFFF;
                        x++;
                    }
                    count--;
                }
            }
        }
        
        if(opcode>=0x80 && opcode<=0x87){
            //1行書き換えのときはdh,dvを実施しない
            continue;
        }
        
        //
        //debugStr += " dh="+dh+" dv="+dv;//####
        if( y<bottom ){
            if (dh>0)
            {
                x=left+dh;
                while(x<right){
                    //int v = 0xFF000000|0x00FFFFFF&(db.getElem(0, x+y*cdWidth)^db.getElem(0, (x-dh)+y*cdWidth));
                    int a1 = db[x+y*cdWidth];
                    int a2 = db[(x-dh)+y*cdWidth];
                    int a3 = a1^a2;
                    int a4 = 0x00FFFFFF&a3;
                    int a5 = 0xFF000000|a4;
                    int v = a5;
                    v = v^(0x00FFFFFF);
                    db[x+y*cdWidth] = v;
                    x++;
                }
            }
            
            x=left;
            if (dv>0)
            {
                while(x<right && y>=dv){
                    db[x+y*cdWidth] = 0x00FFFFFF^(0xFF000000|(0x00FFFFFF&(db[x+y*cdWidth]^db[x+(y-dv)*cdWidth])));
                    x++;
                }
            }
        }
        
        //go next row
    }
    
    /*File f = new File("./woba_debug_"+id+".txt");
     try {
     FileOutputStream stream = new FileOutputStream(f);
     stream.write(debugStr.getBytes());
     stream.close();
     } catch (IOException e) {
     e.printStackTrace();
     }*/
    
    //return bi;
}

static void HCStackDebug_write(NSString *str)
{
    
}

- (void) outputXML
{
    NSXMLDocument *document= [NSXMLNode document];
    [document setVersion:@"1.0"];
    [document setCharacterEncoding:@"utf-8"];
    
    //DTD
    //NSXMLDTD* dtd= [[NSXMLDTD alloc] init];
    //[dtd setPublicID:@"__URL__"];
    //[document setDTD:dtd];
    
    NSXMLElement* rootElem = [NSXMLNode elementWithName:@"stackfile"];
    [document setRootElement:rootElem];
    
    [self outputXMLStack:rootElem];
    [self outputXMLFonts:rootElem];
    [self outputXMLStyle:rootElem];
    for(int i=0; i<[stack.bgList count]; i++){
        [self outputXMLBackground:rootElem bg:[stack.bgList objectAtIndex:i]];
    }
    for(int i=0; i<[stack.cardCacheList count]; i++){
        [self outputXMLCard:rootElem cd:[stack.cardCacheList objectAtIndex:i]];
    }
    [self outputXMLResource:rootElem];
    [self outputXMLPLTE:rootElem];
    [self outputXMLAddColor:rootElem];
    [self outputXMLExtenal:rootElem];
    
    // write file
    NSString *path = [NSString stringWithFormat:@"%@/_stack.xml", dirPath];
    //NSString* output= [document XMLString];
    NSString *output= [document XMLStringWithOptions:NSXMLNodePrettyPrint];
    NSError *error;
    [output writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
}

- (void) outputXMLStack:(NSXMLElement *)rootElem
{
    NSXMLElement *stackElem= [NSXMLNode elementWithName:@"stack"];
    [rootElem addChild:stackElem];
    
    NSXMLElement *elem, *elem2;
    elem = [NSXMLNode elementWithName:@"stackID"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", stack.stackid]];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"format"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", 11]]; // 10 - HyperCard 2.x
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"backgroundCount"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", stack.backgroundCount]];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"firstBackgroundID"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", stack.firstBg]];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"cardCount"];
    [elem setStringValue:[NSString stringWithFormat:@"%ld", [stack.cardIdList count]]];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"firstCardID"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", stack.firstCard]];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"listID"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", stack.listId]];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"password"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", stack.passwordHash]];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"userLevel"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", stack.userLevel]];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"cantModify"];
    elem2 = [NSXMLNode elementWithName:stack.cantModify?@"true":@"false"];
    [elem addChild:elem2];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"cantDelete"];
    elem2 = [NSXMLNode elementWithName:stack.cantDelete?@"true":@"false"];
    [elem addChild:elem2];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"privateAccess"];
    elem2 = [NSXMLNode elementWithName:stack.privateAccess?@"true":@"false"];
    [elem addChild:elem2];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"cantAbort"];
    elem2 = [NSXMLNode elementWithName:stack.cantAbort?@"true":@"false"];
    [elem addChild:elem2];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"cantPeek"];
    elem2 = [NSXMLNode elementWithName:stack.cantPeek?@"true":@"false"];
    [elem addChild:elem2];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"createdByVersion"];
    [elem setStringValue:stack.createdByVersion];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"lastCompactedVersion"];
    [elem setStringValue:stack.lastCompactedVersion];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"modifyVersion"];
    [elem setStringValue:stack.lastEditedVersion];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"openVersion"];
    [elem setStringValue:stack.firstEditedVersion];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"fontTableID"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", stack.fontTableID]];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"styleTableID"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", stack.styleTableID]];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"cardSize"];
    elem2 = [NSXMLNode elementWithName:@"width"];
    [elem2 setStringValue:[NSString stringWithFormat:@"%d", stack.width]];
    [elem addChild:elem2];
    elem2 = [NSXMLNode elementWithName:@"height"];
    [elem2 setStringValue:[NSString stringWithFormat:@"%d", stack.height]];
    [elem addChild:elem2];
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"patterns"];
    for(int i=0; i<[stack.Pattern count]; i++){
        elem2 = [NSXMLNode elementWithName:@"pattern"];
        [elem2 setStringValue:[NSString stringWithFormat:@"%@", [stack.Pattern objectAtIndex:i]]];
        [elem addChild:elem2];
    }
    [stackElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"script"];
    [elem setStringValue:stack.scriptStr];
    [stackElem addChild:elem];
    
    //[child addAttribute:[NSXMLNode attributeWithName:@"attrKey" stringValue:@"attrVal"]];
}

- (void) outputXMLFonts:(NSXMLElement *)rootElem
{
    NSXMLElement *elem;
    
    for(int i=0; i<[stack.fontList count]; i++)
    {
        elem = [NSXMLNode elementWithName:@"font"];
        {
            NSXMLElement *elem2;
            HCXObject *obj = [stack.fontList objectAtIndex:i];
            elem2 = [NSXMLNode elementWithName:@"id"];
            [elem2 setStringValue:[NSString stringWithFormat:@"%d", obj.pid]];
            [elem addChild:elem2];
            
            elem2 = [NSXMLNode elementWithName:@"name"];
            [elem2 setStringValue:[NSString stringWithFormat:@"%@", obj.name]];
            [elem addChild:elem2];
        }
        [rootElem addChild:elem];
    }
}

- (void) outputXMLStyle:(NSXMLElement *)rootElem
{
    NSXMLElement *elem;
    
    elem = [NSXMLNode elementWithName:@"nextStyleID"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", stack.nextStyleID]];
    [rootElem addChild:elem];
    
    for(int i=0; i<[stack.styleList count]; i++)
    {
        elem = [NSXMLNode elementWithName:@"styleentry"];
        {
            NSXMLElement *elem2;
            NSArray *ary = [stack.styleList objectAtIndex:i];
            NSString *idStr = [ary objectAtIndex:0];
            NSString *styleStr = [ary objectAtIndex:1];
            NSString *fontStr = [ary objectAtIndex:2];
            NSString *sizeStr = [ary objectAtIndex:3];
            
            elem2 = [NSXMLNode elementWithName:@"id"];
            [elem2 setStringValue:idStr];
            [elem addChild:elem2];
            
            if([fontStr length]>0 && [fontStr isEqualToString:@"-1"]==NO){
                elem2 = [NSXMLNode elementWithName:@"font"];
                [elem2 setStringValue:fontStr];
                [elem addChild:elem2];
            }
            
            if([sizeStr length]>0 && [sizeStr isEqualToString:@"-1"]==NO){
                elem2 = [NSXMLNode elementWithName:@"size"];
                [elem2 setStringValue:sizeStr];
                [elem addChild:elem2];
            }
            
            if([styleStr length]>0 && [styleStr isEqualToString:@"-1"]==NO){
                elem2 = [NSXMLNode elementWithName:@"style"];
                [elem2 setStringValue:styleStr];
                [elem addChild:elem2];
            }
        }
        [rootElem addChild:elem];
    }
    
}

- (void) outputXMLBackground:(NSXMLElement *)rootElem bg:(HCXCard *)bg
{
    NSXMLElement *backgroundElem= [NSXMLNode elementWithName:@"background"];
    [rootElem addChild:backgroundElem];
    
    NSXMLElement *elem, *elem2;
    elem = [NSXMLNode elementWithName:@"id"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", bg.pid]];
    [backgroundElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"bitmap"];
    [elem setStringValue:bg.bitmapName];
    [backgroundElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"cantDelete"];
    elem2 = [NSXMLNode elementWithName:bg.cantDelete?@"true":@"false"];
    [elem addChild:elem2];
    [backgroundElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"showPict"];
    elem2 = [NSXMLNode elementWithName:bg.showPict?@"true":@"false"];
    [elem addChild:elem2];
    [backgroundElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"dontSearch"];
    elem2 = [NSXMLNode elementWithName:bg.dontSearch?@"true":@"false"];
    [elem addChild:elem2];
    [backgroundElem addChild:elem];
    
    for(int i=0; i<[bg.partsList count]; i++)
    {
        HCXObject *part = [bg.partsList objectAtIndex:i];
        if([part.objectType isEqualToString:@"field"]==YES)
        {
            // field
            [self outputXMLField:backgroundElem fld:(HCXField *)part isBg:YES];
        }
        else
        {
            // button
            [self outputXMLButton:backgroundElem btn:(HCXButton *)part isBg:YES];
            
        }
    }
    
    for(int i=0; i<[bg.partsList count]; i++)
    {
        HCXObject *part = [bg.partsList objectAtIndex:i];
        if([part.text length]>0)
        {
            elem = [NSXMLNode elementWithName:@"content"];
            {
                elem2 = [NSXMLNode elementWithName:@"layer"];
                [elem2 setStringValue:@"background"];
                [elem addChild:elem2];
                
                elem2 = [NSXMLNode elementWithName:@"id"];
                [elem2 setStringValue:[NSString stringWithFormat:@"%d", part.pid]];
                [elem addChild:elem2];
                
                elem2 = [NSXMLNode elementWithName:@"text"];
                NSString *textStr = [part.text stringByReplacingOccurrencesOfString:@"\x01" withString:@""];
                [elem2 setStringValue:textStr];
                [elem addChild:elem2];
                
                if(([part.objectType isEqualToString:@"field"]==YES) &&
                   ((HCXField *)part).styleList!=nil)
                {
                    HCXField *fld = (HCXField *)part;
                    for(int j=0; j<[fld.styleList count]; j++)
                    {
                        HCXStyleClass *styleC = [fld.styleList objectAtIndex:j];
                        elem2 = [NSXMLNode elementWithName:@"stylerun"];
                        {
                            NSXMLElement *elem3 = [NSXMLNode elementWithName:@"offset"];
                            [elem3 setStringValue:[NSString stringWithFormat:@"%d", styleC.textPosition]];
                            [elem2 addChild:elem3];
                        }
                        {
                            NSXMLElement *elem3 = [NSXMLNode elementWithName:@"id"];
                            [elem3 setStringValue:[NSString stringWithFormat:@"%d", styleC.styleId]];
                            [elem2 addChild:elem3];
                        }
                        [elem addChild:elem2];
                    }
                }
            }
            [backgroundElem addChild:elem];
        }
    }
    
    elem = [NSXMLNode elementWithName:@"name"];
    [elem setStringValue:bg.name];
    [backgroundElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"script"];
    [elem setStringValue:bg.scriptStr];
    [backgroundElem addChild:elem];
}

- (void) outputXMLCard:(NSXMLElement *)rootElem cd:(HCXCard *)cd
{
    NSXMLElement *cardElem= [NSXMLNode elementWithName:@"card"];
    [rootElem addChild:cardElem];
    
    NSXMLElement *elem, *elem2;
    elem = [NSXMLNode elementWithName:@"id"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", cd.pid]];
    [cardElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"bitmap"];
    [elem setStringValue:cd.bitmapName];
    [cardElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"cantDelete"];
    elem2 = [NSXMLNode elementWithName:cd.cantDelete?@"true":@"false"];
    [elem addChild:elem2];
    [cardElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"showPict"];
    elem2 = [NSXMLNode elementWithName:cd.showPict?@"true":@"false"];
    [elem addChild:elem2];
    [cardElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"dontSearch"];
    elem2 = [NSXMLNode elementWithName:cd.dontSearch?@"true":@"false"];
    [elem addChild:elem2];
    [cardElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"marked"];
    elem2 = [NSXMLNode elementWithName:cd.marked?@"true":@"false"];
    [elem addChild:elem2];
    [cardElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"background"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", cd.bgid]];
    [cardElem addChild:elem];
    
    for(int i=0; i<[cd.partsList count]; i++)
    {
        HCXObject *part = [cd.partsList objectAtIndex:i];
        if([part.objectType isEqualToString:@"field"]==YES)
        {
            // field
            [self outputXMLField:cardElem fld:(HCXField *)part isBg:NO];
        }
        else
        {
            // button
            [self outputXMLButton:cardElem btn:(HCXButton *)part isBg:NO];
            
        }
    }
    
    for(int i=0; i<[cd.partsList count]; i++)
    {
        HCXObject *part = [cd.partsList objectAtIndex:i];
        if([part.text length]>0)
        {
            elem = [NSXMLNode elementWithName:@"content"];
            {
                elem2 = [NSXMLNode elementWithName:@"layer"];
                [elem2 setStringValue:@"card"];
                [elem addChild:elem2];
                
                elem2 = [NSXMLNode elementWithName:@"id"];
                [elem2 setStringValue:[NSString stringWithFormat:@"%d", part.pid]];
                [elem addChild:elem2];
                
                elem2 = [NSXMLNode elementWithName:@"text"];
                [elem2 setStringValue:part.text];
                [elem addChild:elem2];
                
                if(([part.objectType isEqualToString:@"field"]==YES) &&
                   ((HCXField *)part).styleList!=nil)
                {
                    HCXField *fld = (HCXField *)part;
                    for(int j=0; j<[fld.styleList count]; j++)
                    {
                        HCXStyleClass *styleC = [fld.styleList objectAtIndex:j];
                        elem2 = [NSXMLNode elementWithName:@"stylerun"];
                        {
                            NSXMLElement *elem3 = [NSXMLNode elementWithName:@"offset"];
                            [elem3 setStringValue:[NSString stringWithFormat:@"%d", styleC.textPosition]];
                            [elem2 addChild:elem3];
                        }
                        {
                            NSXMLElement *elem3 = [NSXMLNode elementWithName:@"id"];
                            [elem3 setStringValue:[NSString stringWithFormat:@"%d", styleC.styleId]];
                            [elem2 addChild:elem3];
                        }
                        [elem addChild:elem2];
                    }
                }
            }
            [cardElem addChild:elem];
        }
    }
    
    for(int i=0; i<[cd.bgfldList count]; i++)
    {
        HCXBgField *part = [cd.bgfldList objectAtIndex:i];
        HCXCard *bg = [stack GetBgbyId:cd.bgid];
        if(bg==nil) continue;
        HCXObject *bgpart = [bg getPartById:part.pid];
        if([bgpart.objectType isEqualToString:@"field"]==YES)
        {
            // bg field content
            if([part.text length]<=0) continue;
            
            elem = [NSXMLNode elementWithName:@"content"];
            {
                elem2 = [NSXMLNode elementWithName:@"layer"];
                [elem2 setStringValue:@"background"];
                [elem addChild:elem2];
                
                elem2 = [NSXMLNode elementWithName:@"id"];
                [elem2 setStringValue:[NSString stringWithFormat:@"%d", part.pid]];
                [elem addChild:elem2];
                
                elem2 = [NSXMLNode elementWithName:@"text"];
                NSString *textStr = [part.text stringByReplacingOccurrencesOfString:@"\x01" withString:@""];
                [elem2 setStringValue:textStr];
                [elem addChild:elem2];
            }
            
            if(part.styleList!=nil)
            {
                for(int j=0; j<[part.styleList count]; j++)
                {
                    HCXStyleClass *styleC = [part.styleList objectAtIndex:j];
                    elem2 = [NSXMLNode elementWithName:@"stylerun"];
                    {
                        NSXMLElement *elem3 = [NSXMLNode elementWithName:@"offset"];
                        [elem3 setStringValue:[NSString stringWithFormat:@"%d", styleC.textPosition]];
                        [elem2 addChild:elem3];
                        
                        elem3 = [NSXMLNode elementWithName:@"id"];
                        [elem3 setStringValue:[NSString stringWithFormat:@"%d", styleC.styleId]];
                        [elem2 addChild:elem3];
                    }
                    [elem addChild:elem2];
                }
            }
            
            [cardElem addChild:elem];
        }
        else
        {
            // bg button content
            HCXBgField *part = [cd.bgfldList objectAtIndex:i];
            elem = [NSXMLNode elementWithName:@"content"];
            {
                elem2 = [NSXMLNode elementWithName:@"layer"];
                [elem2 setStringValue:@"background"];
                [elem addChild:elem2];
                
                elem2 = [NSXMLNode elementWithName:@"id"];
                [elem2 setStringValue:[NSString stringWithFormat:@"%d", part.pid]];
                [elem addChild:elem2];
                
                elem2 = [NSXMLNode elementWithName:@"highlight"];
                NSXMLElement *elem3 = [NSXMLNode elementWithName:part.forBgButtonHilite?@"true":@"false"];
                [elem2 addChild:elem3];
                [elem addChild:elem2];
            }
            
            [cardElem addChild:elem];
        }
    }
    
    elem = [NSXMLNode elementWithName:@"name"];
    [elem setStringValue:cd.name];
    [cardElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"script"];
    [elem setStringValue:cd.scriptStr];
    [cardElem addChild:elem];
}

- (void) outputXMLButton:(NSXMLElement *)parentElem btn:(HCXButton *)btn isBg:(BOOL)isBg
{
    NSXMLElement *partElem= [NSXMLNode elementWithName:@"part"];
    [parentElem addChild:partElem];
    
    NSXMLElement *elem, *elem2;
    elem = [NSXMLNode elementWithName:@"id"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", btn.pid]];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"type"];
    [elem setStringValue:@"button"];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"visible"];
    elem2 = [NSXMLNode elementWithName:btn.visible?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"enabled"];
    elem2 = [NSXMLNode elementWithName:btn.enabled?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"rect"];
    {
        elem2 = [NSXMLNode elementWithName:@"left"];
        [elem2 setStringValue:[NSString stringWithFormat:@"%d", btn.left]];
        [elem addChild:elem2];
        elem2 = [NSXMLNode elementWithName:@"top"];
        [elem2 setStringValue:[NSString stringWithFormat:@"%d", btn.top]];
        [elem addChild:elem2];
        elem2 = [NSXMLNode elementWithName:@"right"];
        [elem2 setStringValue:[NSString stringWithFormat:@"%d", btn.left+btn.width]];
        [elem addChild:elem2];
        elem2 = [NSXMLNode elementWithName:@"bottom"];
        [elem2 setStringValue:[NSString stringWithFormat:@"%d", btn.top+btn.height]];
        [elem addChild:elem2];
    }
    [partElem addChild:elem];
    
    NSString *styleStr = @"";
    switch(btn.style){
        case 0: styleStr = @"standard";break;
        case 1: styleStr = @"transparent";break;
        case 2: styleStr = @"opaque";break;
        case 3: styleStr = @"rectangle";break;
        case 4: styleStr = @"shadow";break;
        case 5: styleStr = @"roundrect";break;
        case 6: styleStr = @"default";break;
        case 7: styleStr = @"oval";break;
        case 8: styleStr = @"popup";break;
        case 9: styleStr = @"checkbox";break;
        case 10: styleStr = @"radio";break;
    }
    
    elem = [NSXMLNode elementWithName:@"style"];
    [elem setStringValue:styleStr];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"showName"];
    elem2 = [NSXMLNode elementWithName:btn.showName?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"highlight"];
    elem2 = [NSXMLNode elementWithName:btn.hilite?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"autoHighlight"];
    elem2 = [NSXMLNode elementWithName:btn.autoHilite?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"family"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", btn.group]];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"titleWidth"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", btn.titleWidth]];
    [partElem addChild:elem];
    
    if(isBg==YES){
        elem = [NSXMLNode elementWithName:@"sharedHighlight"];
        elem2 = [NSXMLNode elementWithName:btn.sharedHilite?@"true":@"false"];
        [elem addChild:elem2];
        [partElem addChild:elem];
    }
    
    if(btn.style==8){
        elem = [NSXMLNode elementWithName:@"selectedLines"];
        elem2 = [NSXMLNode elementWithName:@"integer"];
        [elem2 setStringValue:[NSString stringWithFormat:@"%d", btn.selectedLine]];
        [elem addChild:elem2];
        [partElem addChild:elem];
    }
    else{
        elem = [NSXMLNode elementWithName:@"icon"];
        [elem setStringValue:[NSString stringWithFormat:@"%d", btn.icon]];
        [partElem addChild:elem];
    }
    
    NSString *textAlignStr = @"";
    switch(btn.textAlign){
        case 0: textAlignStr = @"left";break;
        case 1: textAlignStr = @"center";break;
        case 2: textAlignStr = @"right";break;
    }
    
    elem = [NSXMLNode elementWithName:@"textAlign"];
    [elem setStringValue:textAlignStr];
    [partElem addChild:elem];
    
    int textFontID = 0;
    for(int i=0; i<[stack.fontList count]; i++){
        HCXObject *fontinfo = [stack.fontList objectAtIndex:i];
        if([fontinfo.name isEqualToString:btn.textFont]==YES){
            textFontID = fontinfo.pid;
            break;
        }
    }
    elem = [NSXMLNode elementWithName:@"textFontID"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", textFontID]];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"textSize"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", btn.textSize]];
    [partElem addChild:elem];
    
    if(btn.textStyle==0){
        elem = [NSXMLNode elementWithName:@"textStyle"];
        [elem setStringValue:@"plain"];
        [partElem addChild:elem];
    }else{
        if((btn.textStyle&1)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"bold"];
            [partElem addChild:elem];
        }
        if((btn.textStyle&2)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"italic"];
            [partElem addChild:elem];
        }
        if((btn.textStyle&4)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"underline"];
            [partElem addChild:elem];
        }
        if((btn.textStyle&8)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"outline"];
            [partElem addChild:elem];
        }
        if((btn.textStyle&16)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"shadow"];
            [partElem addChild:elem];
        }
        if((btn.textStyle&32)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"condensed"];
            [partElem addChild:elem];
        }
        if((btn.textStyle&64)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"extend"];
            [partElem addChild:elem];
        }
        if((btn.textStyle&128)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"group"];
            [partElem addChild:elem];
        }
    }
    
    elem = [NSXMLNode elementWithName:@"textHeight"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", btn.textHeight]];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"name"];
    [elem setStringValue:btn.name];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"script"];
    [elem setStringValue:btn.scriptStr];
    [partElem addChild:elem];
}

- (void) outputXMLField:(NSXMLElement *)parentElem fld:(HCXField *)fld isBg:(BOOL)isBg
{
    NSXMLElement *partElem= [NSXMLNode elementWithName:@"part"];
    [parentElem addChild:partElem];
    
    NSXMLElement *elem, *elem2;
    elem = [NSXMLNode elementWithName:@"id"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", fld.pid]];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"type"];
    [elem setStringValue:@"field"];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"visible"];
    elem2 = [NSXMLNode elementWithName:fld.visible?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"dontWrap"];
    elem2 = [NSXMLNode elementWithName:fld.dontWrap?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"dontSearch"];
    elem2 = [NSXMLNode elementWithName:fld.dontSearch?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    if(isBg==YES){
        elem = [NSXMLNode elementWithName:@"sharedText"];
        elem2 = [NSXMLNode elementWithName:fld.sharedText?@"true":@"false"];
        [elem addChild:elem2];
        [partElem addChild:elem];
    }
    
    elem = [NSXMLNode elementWithName:@"fixedLineHeight"];
    elem2 = [NSXMLNode elementWithName:fld.fixedLineHeight?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"autoTab"];
    elem2 = [NSXMLNode elementWithName:fld.autoTab?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"lockText"];
    elem2 = [NSXMLNode elementWithName:fld.lockText?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"rect"];
    {
        elem2 = [NSXMLNode elementWithName:@"left"];
        [elem2 setStringValue:[NSString stringWithFormat:@"%d", fld.left]];
        [elem addChild:elem2];
        elem2 = [NSXMLNode elementWithName:@"top"];
        [elem2 setStringValue:[NSString stringWithFormat:@"%d", fld.top]];
        [elem addChild:elem2];
        elem2 = [NSXMLNode elementWithName:@"right"];
        [elem2 setStringValue:[NSString stringWithFormat:@"%d", fld.left+fld.width]];
        [elem addChild:elem2];
        elem2 = [NSXMLNode elementWithName:@"bottom"];
        [elem2 setStringValue:[NSString stringWithFormat:@"%d", fld.top+fld.height]];
        [elem addChild:elem2];
    }
    [partElem addChild:elem];
    
    NSString *styleStr = @"";
    switch(fld.style){
        case 0: styleStr = @"standard";break;
        case 1: styleStr = @"transparent";break;
        case 2: styleStr = @"opaque";break;
        case 3: styleStr = @"rectangle";break;
        case 4: styleStr = @"shadow";break;
        case 5: styleStr = @"scrolling";break;
    }
    
    elem = [NSXMLNode elementWithName:@"style"];
    [elem setStringValue:styleStr];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"autoSelect"];
    elem2 = [NSXMLNode elementWithName:fld.autoSelect?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"showLines"];
    elem2 = [NSXMLNode elementWithName:fld.showLines?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"wideMargins"];
    elem2 = [NSXMLNode elementWithName:fld.wideMargins?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"multipleLines"];
    elem2 = [NSXMLNode elementWithName:fld.multipleLines?@"true":@"false"];
    [elem addChild:elem2];
    [partElem addChild:elem];
    
    if(fld.selectedLine>0){
        elem = [NSXMLNode elementWithName:@"selectedLines"];
        elem2 = [NSXMLNode elementWithName:@"integer"];
        [elem2 setStringValue:[NSString stringWithFormat:@"%d", fld.selectedLine]];
        [elem addChild:elem2];
        [partElem addChild:elem];
    }
    
    NSString *textAlignStr = @"";
    switch(fld.textAlign){
        case 0: textAlignStr = @"left";break;
        case 1: textAlignStr = @"center";break;
        case 2: textAlignStr = @"right";break;
    }
    
    elem = [NSXMLNode elementWithName:@"textAlign"];
    [elem setStringValue:textAlignStr];
    [partElem addChild:elem];
    
    int textFontID = 0;
    for(int i=0; i<[stack.fontList count]; i++){
        HCXObject *fontinfo = [stack.fontList objectAtIndex:i];
        if([fontinfo.name isEqualToString:fld.textFont]==YES){
            textFontID = fontinfo.pid;
            break;
        }
    }
    elem = [NSXMLNode elementWithName:@"textFontID"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", textFontID]];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"textSize"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", fld.textSize]];
    [partElem addChild:elem];
    
    if(fld.textStyle==0){
        elem = [NSXMLNode elementWithName:@"textStyle"];
        [elem setStringValue:@"plain"];
        [partElem addChild:elem];
    }else{
        if((fld.textStyle&1)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"bold"];
            [partElem addChild:elem];
        }
        if((fld.textStyle&2)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"italic"];
            [partElem addChild:elem];
        }
        if((fld.textStyle&4)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"underline"];
            [partElem addChild:elem];
        }
        if((fld.textStyle&8)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"outline"];
            [partElem addChild:elem];
        }
        if((fld.textStyle&16)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"shadow"];
            [partElem addChild:elem];
        }
        if((fld.textStyle&32)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"condensed"];
            [partElem addChild:elem];
        }
        if((fld.textStyle&64)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"extend"];
            [partElem addChild:elem];
        }
        if((fld.textStyle&128)>0){
            elem = [NSXMLNode elementWithName:@"textStyle"];
            [elem setStringValue:@"group"];
            [partElem addChild:elem];
        }
    }
    
    elem = [NSXMLNode elementWithName:@"textHeight"];
    [elem setStringValue:[NSString stringWithFormat:@"%d", fld.textHeight]];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"name"];
    [elem setStringValue:fld.name];
    [partElem addChild:elem];
    
    elem = [NSXMLNode elementWithName:@"script"];
    [elem setStringValue:fld.scriptStr];
    [partElem addChild:elem];
}

- (void) outputXMLResource:(NSXMLElement *)rootElem
{
    NSArray *rsrcList = stack.rsrc.list;
    
    for(int i=0; i<[rsrcList count]; i++){
        HCXRes *rsrc = [rsrcList objectAtIndex:i];
        
        NSXMLElement *mediaElem= [NSXMLNode elementWithName:@"media"];
        [rootElem addChild:mediaElem];
        
        NSXMLElement *elem, *elem2;
        elem = [NSXMLNode elementWithName:@"id"];
        [elem setStringValue:[NSString stringWithFormat:@"%d", rsrc.resid]];
        [mediaElem addChild:elem];
        
        elem = [NSXMLNode elementWithName:@"type"];
        [elem setStringValue:rsrc.type];
        [mediaElem addChild:elem];
        
        elem = [NSXMLNode elementWithName:@"name"];
        [elem setStringValue:rsrc.name];
        [mediaElem addChild:elem];
        
        elem = [NSXMLNode elementWithName:@"file"];
        [elem setStringValue:rsrc.filename];
        [mediaElem addChild:elem];
        
        if([rsrc.type isEqualToString:@"cursor"]==YES)
        {
            elem = [NSXMLNode elementWithName:@"hotspot"];
            {
                elem2 = [NSXMLNode elementWithName:@"left"];
                [elem2 setStringValue:[NSString stringWithFormat:@"%d", rsrc.hotspotleft]];
                [elem addChild:elem2];
                
                elem2 = [NSXMLNode elementWithName:@"top"];
                [elem2 setStringValue:[NSString stringWithFormat:@"%d", rsrc.hotspottop]];
                [elem addChild:elem2];
            }
            [mediaElem addChild:elem];
        }
        
        /*
        FontInfo fontinfo = (FontInfo)this.optionInfo;
        if(this.type.equals("font") && fontinfo!=null){
            writer.writeCharacters("\t");
            writer.writeStartElement("fontinfo");
            writer.writeCharacters("\n\t\t\t");
            {
                
                writer.writeStartElement("fontType");
                writer.writeCharacters(Integer.toString(fontinfo.fontType));
                writer.writeEndElement();
                writer.writeCharacters("\n\t\t");
                
                writer.writeStartElement("firstChar");
                writer.writeCharacters(Integer.toString(fontinfo.firstChar));
                writer.writeEndElement();
                writer.writeCharacters("\n\t\t");
                
                writer.writeStartElement("lastChar");
                writer.writeCharacters(Integer.toString(fontinfo.lastChar));
                writer.writeEndElement();
                writer.writeCharacters("\n\t\t");
                
                writer.writeStartElement("widMax");
                writer.writeCharacters(Integer.toString(fontinfo.widMax));
                writer.writeEndElement();
                writer.writeCharacters("\n\t\t");
                
                writer.writeStartElement("kernMax");
                writer.writeCharacters(Integer.toString(fontinfo.kernMax));
                writer.writeEndElement();
                writer.writeCharacters("\n\t\t");
                
                writer.writeStartElement("nDescent");
                writer.writeCharacters(Integer.toString(fontinfo.nDescent));
                writer.writeEndElement();
                writer.writeCharacters("\n\t\t");
                
                writer.writeStartElement("fRectWidth");
                writer.writeCharacters(Integer.toString(fontinfo.fRectWidth));
                writer.writeEndElement();
                writer.writeCharacters("\n\t\t");
                
                writer.writeStartElement("fRectHeight");
                writer.writeCharacters(Integer.toString(fontinfo.fRectHeight));
                writer.writeEndElement();
                writer.writeCharacters("\n\t\t");
                
                writer.writeStartElement("owTLoc");
                writer.writeCharacters(Integer.toString(fontinfo.owTLoc));
                writer.writeEndElement();
                writer.writeCharacters("\n\t\t");
                
                writer.writeStartElement("ascent");
                writer.writeCharacters(Integer.toString(fontinfo.ascent));
                writer.writeEndElement();
                writer.writeCharacters("\n\t\t");
                
                writer.writeStartElement("descent");
                writer.writeCharacters(Integer.toString(fontinfo.descent));
                writer.writeEndElement();
                writer.writeCharacters("\n\t\t");
                
                writer.writeStartElement("leading");
                writer.writeCharacters(Integer.toString(fontinfo.leading));
                writer.writeEndElement();
                writer.writeCharacters("\n\t\t");
                
                for(int j=0; fontinfo.locs!=null&&j<fontinfo.locs.length; j++){
                    writer.writeStartElement("loc");
                    writer.writeCharacters(Integer.toString(fontinfo.locs[j]));
                    writer.writeEndElement();
                    writer.writeCharacters("\n\t\t");
                }
                
                for(int j=0; fontinfo.offsets!=null&&j<fontinfo.offsets.length; j++){
                    writer.writeStartElement("offset");
                    writer.writeCharacters(Integer.toString(fontinfo.offsets[j]));
                    writer.writeEndElement();
                    writer.writeCharacters("\n\t\t");
                }
                
                for(int j=0; fontinfo.widthes!=null&&j<fontinfo.widthes.length; j++){
                    writer.writeStartElement("width");
                    writer.writeCharacters(Integer.toString(fontinfo.widthes[j]));
                    writer.writeEndElement();
                    writer.writeCharacters("\n\t\t");
                }
            }
        }
         */
    }
}

- (void) outputXMLPLTE:(NSXMLElement *)rootElem
{
}

- (void) outputXMLAddColor:(NSXMLElement *)rootElem
{
}

- (void) outputXMLExtenal:(NSXMLElement *)rootElem
{
    NSArray *xcmdList = stack.rsrc.xcmdList;
    
    for(int i=0; i<[xcmdList count]; i++){
        HCXXcmd *xcmd = [xcmdList objectAtIndex:i];
        
        NSXMLElement *xcmdElem= [NSXMLNode elementWithName:@"externalcommand"];
        
        [xcmdElem addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:xcmd.type]];
        [xcmdElem addAttribute:[NSXMLNode attributeWithName:@"platform" stringValue:xcmd.platform]];
        [xcmdElem addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:[NSString stringWithFormat:@"%d", xcmd.xcmdid]]];
        [xcmdElem addAttribute:[NSXMLNode attributeWithName:@"size" stringValue:[NSString stringWithFormat:@"%d", xcmd.size]]];
        [xcmdElem addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:xcmd.name]];
        [xcmdElem addAttribute:[NSXMLNode attributeWithName:@"file" stringValue:xcmd.filename]];
        
        [rootElem addChild:xcmdElem];
    }
}

@end
