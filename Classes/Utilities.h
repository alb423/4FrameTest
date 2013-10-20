//
//  Utilities.h
//  iFrameExtractor
//
//  Created by lajos on 1/10/10.
//
//  Copyright 2010 Lajos Kamocsay
//
//  lajos at codza dot com
//
//  iFrameExtractor is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2.1 of the License, or (at your option) any later version.
// 
//  iFrameExtractor is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//

#import <Foundation/Foundation.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"

@interface Utilities : NSObject {

}

+(NSString *)bundlePath:(NSString *)fileName;
+(NSString *)documentsPath:(NSString *)fileName;

// Reference
// http://stackoverflow.com/questions/9604633/reading-a-file-located-in-memory-with-libavformat
typedef struct tFileX
{
    int64_t FileSize;
    int64_t FilePosition;
    unsigned char *pBuffer;
}tFileX;

int readFunction(void* opaque, uint8_t* buf, int buf_size);
int64_t seekFunction(void* opaque, int64_t offset, int whence);


@end
