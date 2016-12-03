//
//  Video.h
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

//@interface VideoFrameExtractor : NSObject {
@interface VideoFrameExtractor : NSObject {
    
	AVFormatContext *pFormatCtx;
//	AVCodecContext *pCodecCtx;
//    AVFrame *pFrame;
    AVPacket packet;
	//AVPicture picture;
    AVFrame *pRGBFrame;
	int videoStream;
	struct SwsContext *pImgConvertCtx;
	int sourceWidth, sourceHeight;
	int outputWidth, outputHeight;
	UIImage *currentImage;
	double duration;
    double currentTime;
    
    GLuint _program;
    GLuint _positionVBO;
    GLuint _texcoordVBO;
    GLuint _indexVBO;
    
@public
    AVCodecContext *pCodecCtx;
    AVFrame *pYUVFrame;
}

/* Last decoded picture as UIImage */
@property (weak, nonatomic, readonly) UIImage *currentImage;

/* Size of video frame */
@property (nonatomic, readonly) int sourceWidth, sourceHeight;

/* Output image size. Set to the source size by default. */
@property (nonatomic) int outputWidth, outputHeight;

/* Length of video in seconds */
@property (nonatomic, readonly) double duration;

/* Current time of video in seconds */
@property (nonatomic, readonly) double currentTime;
@property (nonatomic, readonly) double fps;
//@property (nonatomic, readonly)   GLuint _program;
//@property (nonatomic, readonly)   GLuint _positionVBO;
//@property (nonatomic, readonly)   GLuint _texcoordVBO;
//@property (nonatomic, readonly)   GLuint _indexVBO;

/* Initialize with movie at moviePath. Output dimensions are set to source dimensions. */
-(id)initWithVideo:(NSString *)moviePath;
-(id)initWithVideoMemory:(NSString *)moviePath;
/* Read the next frame from the video stream. Returns false if no frame read (video over). */
-(BOOL)stepFrame;

/* Seek to closest keyframe near specified time */
-(void)seekTime:(double)seconds;


@end
