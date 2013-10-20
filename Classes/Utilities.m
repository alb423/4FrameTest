//
//  Utilities.m
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

#import "Utilities.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"

@implementation Utilities

+(NSString *)bundlePath:(NSString *)fileName {
	return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:fileName];
}

+(NSString *)documentsPath:(NSString *)fileName {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:fileName];
}


// Reference
// http://stackoverflow.com/questions/9604633/reading-a-file-located-in-memory-with-libavformat

int readFunction(void* opaque, uint8_t* buf, int buf_size)
{
    tFileX *vpFileX = (tFileX *) opaque;
    if((vpFileX->FileSize - vpFileX->FilePosition) > buf_size)
    {
        memcpy(buf, vpFileX->pBuffer + vpFileX->FilePosition, buf_size);
        vpFileX->FilePosition += buf_size;
        return buf_size;
    }
    else
    {
        memcpy(buf, vpFileX->pBuffer + vpFileX->FilePosition,  (vpFileX->FileSize - vpFileX->FilePosition) );
        vpFileX->FilePosition = vpFileX->FileSize;
        return (vpFileX->FileSize - vpFileX->FilePosition);
    }
    
}

int64_t seekFunction(void* opaque, int64_t offset, int whence)
{
    tFileX *vpFileX = (tFileX *) opaque;
    //    if (whence == AVSEEK_SIZE)
    //        return -1; // I don't know "size of my handle in bytes"
    if (whence == AVSEEK_SIZE)
        return vpFileX->FileSize;
    else if (whence == SEEK_SET)
        vpFileX->FilePosition = offset;
    else if (whence == SEEK_CUR)
        vpFileX->FilePosition += offset;
    else if (whence == SEEK_END)
        vpFileX->FilePosition = vpFileX->FileSize - offset;
    
    return vpFileX->FilePosition;
}


@end
