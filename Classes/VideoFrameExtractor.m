//
//  Video.m
//  iFrameExtractor
//
//  Created by lajos on 1/10/10.
//  Copyright 2010 www.codza.com. All rights reserved.
//

#import "VideoFrameExtractor.h"
#import "Utilities.h"


@interface VideoFrameExtractor (private)
-(void)convertFrameToRGB;
-(UIImage *)imageFromAVPicture:(AVFrame *)pFrame width:(int)width height:(int)height;
-(void)savePicture:(AVFrame *)pFrame width:(int)width height:(int)height index:(int)iFrame;
-(void)setupScaler;
@end



// 20130308 albert.liao modified start

// Uniform index.
enum
{
    UNIFORM_Y,
    UNIFORM_UV,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

// 20130308 albert.liao modified end


@implementation VideoFrameExtractor
//@synthesize _program;
//@synthesize _positionVBO;
//@synthesize _texcoordVBO;
//@synthesize _indexVBO;

@synthesize outputWidth, outputHeight, fps;

-(void)setOutputWidth:(int)newValue {
	if (outputWidth == newValue) return;
	outputWidth = newValue;
	[self setupScaler];
}

-(void)setOutputHeight:(int)newValue {
	if (outputHeight == newValue) return;
	outputHeight = newValue;
	[self setupScaler];
}

-(UIImage *)currentImage {
	if (!pYUVFrame->data[0]) return nil;
	[self convertFrameToRGB];
	return [self imageFromAVPicture:pRGBFrame width:outputWidth height:outputHeight];
}

-(double)duration {
	return (double)pFormatCtx->duration / AV_TIME_BASE;
}

-(double)currentTime {
    AVRational timeBase = pFormatCtx->streams[videoStream]->time_base;
    return packet.pts * (double)timeBase.num / timeBase.den;
}

-(int)sourceWidth {
	return pCodecCtx->width;
}

-(int)sourceHeight {
	return pCodecCtx->height;
}



-(id)initWithVideoMemory:(NSString *)moviePath
{
    AVCodec         *pCodec;
    int ioBufferSize=0;
    
    tFileX *vpFileX=malloc(sizeof(tFileX));
    memset(vpFileX, 0, sizeof(tFileX));
    // Register all formats and codecs
    avcodec_register_all();
    av_register_all();
    fps=0.0;
    
    // Get File size and read to the buffer
    if (moviePath) {
        NSData *pData = [NSData dataWithContentsOfFile:moviePath];
        if (pData) {
            vpFileX->FilePosition =0 ;
            vpFileX->FileSize = [pData length];
            vpFileX->pBuffer = (unsigned char*) av_malloc(vpFileX->FileSize);
            memcpy(vpFileX->pBuffer , [pData bytes], vpFileX->FileSize);
            
            NSLog(@"file %@,size =%lld", moviePath, vpFileX->FileSize);

        }  
    }
    
    ioBufferSize = 10240;//32768;
    

    unsigned char * ioBuffer = (unsigned char *)av_malloc(ioBufferSize + FF_INPUT_BUFFER_PADDING_SIZE); // can get av_free()ed by libav
    
    AVIOContext * avioContext = avio_alloc_context(ioBuffer, ioBufferSize, 0, (void*)vpFileX, &readFunction, NULL, &seekFunction);
    
    pFormatCtx = avformat_alloc_context();
    pFormatCtx->pb = avioContext;
    
    // Open video file
    if(avformat_open_input(&pFormatCtx, "dummyFileName", NULL, NULL) != 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open memory file\n");
        goto initError;
    }
    
	
    // Retrieve stream information
    if(avformat_find_stream_info(pFormatCtx,NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information\n");
        goto initError;
    }
    
    // Find the first video stream
    if ((videoStream =  av_find_best_stream(pFormatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &pCodec, 0)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot find a video stream in the input file\n");
        goto initError;
    }
	
    // Get a pointer to the codec context for the video stream
    //pCodecCtx = pFormatCtx->streams[videoStream]->codec;
    pCodecCtx = avcodec_alloc_context3(NULL);
    avcodec_parameters_to_context(pCodecCtx, pFormatCtx->streams[videoStream]->codecpar);
    
    // Find the decoder for the video stream
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    if(pCodec == NULL) {
        av_log(NULL, AV_LOG_ERROR, "Unsupported codec!\n");
        goto initError;
    }
	
    // Open codec
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot open video decoder\n");
        goto initError;
    }
	
    av_dump_format(pFormatCtx, 0, [moviePath cStringUsingEncoding:NSASCIIStringEncoding], 0);
    
    if(fps==0)
    {
        fps = 1.0/ av_q2d(pCodecCtx->time_base)/ FFMAX(pCodecCtx->ticks_per_frame, 1);
        NSLog(@"fps_method(tbc): 1/av_q2d()=%g",fps);
    }
    
    // Allocate video frame
    pYUVFrame = av_frame_alloc();
    
	outputWidth = pCodecCtx->width;
	self.outputHeight = pCodecCtx->height;
 
    // 20130311 albert.liao modified start
#if 0
    {
        AVHWAccel *vHwAccel = NULL;
        vHwAccel  = ff_find_hwaccel( AV_CODEC_ID_H264 ,  AV_PIX_FMT_YUV420P ); // 7h800.mp4 is YUV420P
        if(vHwAccel  != NULL)
        {
            NSLog(@"Find vHwAccel  for H264");
        }
        else
        {
            NSLog(@"Cannot Find vHwAccel  for H264");
        }
    }
#endif
    // 20130311 albert.liao modified end
	return self;
	
initError:
	;
	return nil;
    
}

-(id)initWithVideo:(NSString *)moviePath {
	if (!(self=[super init])) return nil;
 
    AVCodec         *pCodec;

    // Register all formats and codecs
    avcodec_register_all();
    av_register_all();
    avformat_network_init();
    fps=0.0;
    // Open video file
    AVDictionary *opts = 0;
    //int ret = av_dict_set(&opts, "rtsp_transport", "tcp", 0);
    av_dict_set(&opts, "rtsp_transport", "tcp", 0);
    
    if(avformat_open_input(&pFormatCtx, [moviePath cStringUsingEncoding:NSASCIIStringEncoding], NULL, &opts) != 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open file %s\n", [moviePath cStringUsingEncoding:NSASCIIStringEncoding]);
        goto initError;
    }
	av_dict_free(&opts);
    
	   
    // Retrieve stream information
    if(avformat_find_stream_info(pFormatCtx,NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information\n");
        goto initError;
    }
    
    // Find the first video stream
    if ((videoStream =  av_find_best_stream(pFormatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &pCodec, 0)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot find a video stream in the input file\n");
        goto initError;
    }
	
    // Get a pointer to the codec context for the video stream
    //pCodecCtx = pFormatCtx->streams[videoStream]->codec;
    pCodecCtx = avcodec_alloc_context3(NULL);
    avcodec_parameters_to_context(pCodecCtx, pFormatCtx->streams[videoStream]->codecpar);
    // Find the decoder for the video stream
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    if(pCodec == NULL) {
        av_log(NULL, AV_LOG_ERROR, "Unsupported codec!\n");
        goto initError;
    }
	
    // Open codec
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot open video decoder\n");
        goto initError;
    }
	
    // Allocate video frame
    pYUVFrame = av_frame_alloc();
			
    av_dump_format(pFormatCtx, 0, [moviePath cStringUsingEncoding:NSASCIIStringEncoding], 0);
    
    if(fps==0)
    {
        fps = 1.0/ av_q2d(pCodecCtx->time_base)/ FFMAX(pCodecCtx->ticks_per_frame, 1);
        NSLog(@"fps_method(tbc): 1/av_q2d()=%g",fps);
    }
    
	outputWidth = pCodecCtx->width;
	self.outputHeight = pCodecCtx->height;
			
	return self;
	
initError:
	;
	return nil;
}


-(void)setupScaler {

	// Release old picture and scaler
	av_free(pRGBFrame);
	sws_freeContext(img_convert_ctx);	
	
	// Allocate RGB picture
    pRGBFrame = av_frame_alloc();
    av_frame_unref(pRGBFrame);
    
    int bytes_num = av_image_get_buffer_size(AV_PIX_FMT_RGB24, pYUVFrame->width, pYUVFrame->height, 1);
    uint8_t* buff = (uint8_t*)av_malloc(bytes_num);
    av_image_fill_arrays((unsigned char **)(AVFrame *)pRGBFrame->data, pRGBFrame->linesize, buff, AV_PIX_FMT_RGB24, pYUVFrame->width, pYUVFrame->height, 1);
    pRGBFrame->width = outputWidth;
    pRGBFrame->height = outputHeight;
    pRGBFrame->format = AV_PIX_FMT_RGB24;
    
	// Setup scaler
	static int sws_flags =  SWS_FAST_BILINEAR;
	img_convert_ctx = sws_getContext(pCodecCtx->width, 
									 pCodecCtx->height,
									 pCodecCtx->pix_fmt,
									 outputWidth, 
									 outputHeight,
									 AV_PIX_FMT_RGB24,
									 sws_flags, NULL, NULL, NULL);
	
}

-(void)seekTime:(double)seconds {
	AVRational timeBase = pFormatCtx->streams[videoStream]->time_base;
	int64_t targetFrame = (int64_t)((double)timeBase.den / timeBase.num * seconds);
	avformat_seek_file(pFormatCtx, videoStream, targetFrame, targetFrame, targetFrame, AVSEEK_FLAG_FRAME);
	avcodec_flush_buffers(pCodecCtx);
}

-(void)dealloc {
	// Free scaler
	sws_freeContext(img_convert_ctx);	

	// Free RGB frame
    av_free(pRGBFrame);
    
    // Free the packet that was allocated by av_read_frame
    av_packet_unref(&packet);
	
    // Free the YUV frame
    av_free(pYUVFrame);
	
    // Close the codec
    if (pCodecCtx) avcodec_close(pCodecCtx);
	
    // Close the video file
    if (pFormatCtx) avformat_close_input(&pFormatCtx);
	
}

-(BOOL)stepFrame {

    int vRet, frameFinished=0;

    while(!frameFinished && av_read_frame(pFormatCtx, &packet)>=0) {
        // Is this a packet from the video stream?
        if(packet.stream_index==videoStream) {
            // Decode video frame
//            if(packet.flags==1)
//                NSLog(@"got 1");
            
            avcodec_send_packet(pCodecCtx, &packet);
            do {
                vRet = avcodec_receive_frame(pCodecCtx, pYUVFrame);
            } while(vRet==EAGAIN);
            
            if(vRet==0) frameFinished=1;
            else frameFinished=0;
        }
        av_packet_unref(&packet);
		
	}
	return frameFinished!=0;
}

-(void)convertFrameToRGB {
	sws_scale (img_convert_ctx, (const uint8_t **)pYUVFrame->data, pYUVFrame->linesize,
			   0, pCodecCtx->height,
			   pRGBFrame->data, pRGBFrame->linesize);
}

-(UIImage *)imageFromAVFrame:(AVFrame *)frame width:(int)width height:(int)height {
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, frame->data[0], frame->linesize[0]*height,kCFAllocatorNull);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       8,
                                       24,
                                       frame->linesize[0],
                                       colorSpace,
                                       bitmapInfo,
                                       provider,
                                       NULL,
                                       NO,
                                       kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return image;
}

-(void)savePPMPicture:(AVFrame *)frame width:(int)width height:(int)height index:(int)iFrame {
    FILE *pFile;
    NSString *fileName;
    int  y;
    
    fileName = [Utilities documentsPath:[NSString stringWithFormat:@"image%04d.ppm",iFrame]];
    // Open file
    NSLog(@"write image file: %@",fileName);
    pFile=fopen([fileName cStringUsingEncoding:NSASCIIStringEncoding], "wb");
    if(pFile==NULL)
        return;
    
    // Write header
    fprintf(pFile, "P6\n%d %d\n255\n", width, height);
    
    // Write pixel data
    for(y=0; y<height; y++)
        fwrite(frame->data[0]+y*frame->linesize[0], 1, width*3, pFile);
    
    // Close file
    fclose(pFile);
}


@end
