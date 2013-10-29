

#import "VSaaSVideoDecoder.h"
//#import "mydef.h"

@implementation VSaaSVideoFrame
// 20131025 albert.liao modified start
@synthesize width, height;
// 20131025 albert.liao modified end
@end

@interface VSaaSVideoDecoder()
{
    AVFormatContext *pFormatCtx;
	AVCodecContext *pCodecCtx;
    AVFrame *pFrame;
    AVPacket packet;
	//AVPicture picture;
	int videoStream;
	//struct SwsContext *img_convert_ctx;
	int sourceWidth, sourceHeight;
	int outputWidth, outputHeight;
	UIImage *currentImage;
	double duration;
    double currentTime;
    
    //void* tbuffer;
    //AVFrame *outFrame;
    BOOL is_decode_sps_pps;
    __weak id<VSaaSH264SPSPPSDataDelegate> h264SPSPPSDelegate;
    
    
    BOOL isTakingSnapshot;
}
@end

@implementation VSaaSVideoDecoder

-(id) init
{
	if (!(self=[super init])) return nil;
    
    AVCodec *pCodec;
    
    // Register all formats and codecs
    avcodec_register_all();
    av_register_all();
    
    // Find the decoder for the video stream
    pCodec = avcodec_find_decoder(CODEC_ID_H264);
    
    pCodecCtx = avcodec_alloc_context3(pCodec);
    if (!pCodecCtx) {
        //failed to allocate codec context
        av_log(NULL, AV_LOG_ERROR, "Unsupported codec!\n");
        goto initError;
    }
    
    
    // Open codec
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot open video decoder\n");
        goto initError;
    }
	
    if (pCodecCtx->codec_id == CODEC_ID_H264){
        pCodecCtx->flags2 |= CODEC_FLAG2_CHUNKS;
    }
    
    // Allocate video frame
    pFrame = avcodec_alloc_frame();
    //tbuffer = (uint8_t*) av_malloc(1280*720*3*sizeof(uint8_t));
    //outFrame = avcodec_alloc_frame();

    is_decode_sps_pps = NO;
    
    isTakingSnapshot = NO;

	return self;
	
initError:
	return nil;
}

- (void) dealloc
{
    //NSLog(@"<<<<<<<<<<<<<<<<<<< %s" , __func__);

	// Free scaler
	//sws_freeContext(img_convert_ctx);
    
	// Free RGB picture
	//avpicture_free(&picture);
    
    // Free the packet that was allocated by av_read_frame
    av_free_packet(&packet);
	
    // Free the YUV frame
    av_free(pFrame);
	//av_free(outFrame);
    //av_free(tbuffer);
    
    // Close the codec
    if (pCodecCtx)
    {
        avcodec_close(pCodecCtx);
        av_free(pCodecCtx);//yvonne add
	}
    // Close the video file
    if (pFormatCtx) avformat_close_input(&pFormatCtx);
	
    //if (decodeFrameBuf != NULL)
    //    free(decodeFrameBuf);
    [super dealloc];
}

#if 1//Yvonne. 9/13/2013 debug video play issue: 跳針
/* return value:
 0: success
 1: fail
 */
-(int) decodeOneFrame:(unsigned char *) frameBuf andFrameSize:(unsigned int) frameSize
#else
-(void) decodeOneFrame:(unsigned char *) frameBuf andFrameSize:(unsigned int) frameSize
#endif
{
    #if IS_PRINT_DECODE_TIME
    static double decode_cost_time = 0;
    static int    decode_count = 0;
    #endif
    
    if (is_decode_sps_pps == NO)
    {
        is_decode_sps_pps = YES;
        
        uint8_t startCode[] = {0x00, 0x00, 0x00, 0x01};
        int got_frame;
        
        //==== SPS
        NSData * spsData = [h264SPSPPSDelegate getSPS];
        if (spsData != nil)
        {
            uint8_t *tmpBuf = malloc(4+spsData.length);
            if (tmpBuf)
            {
                memcpy(tmpBuf, startCode, 4);
                memcpy(tmpBuf+4, [spsData bytes], spsData.length);
                
                packet.data = tmpBuf;
                packet.size = 4+spsData.length;
                
                avcodec_decode_video2(pCodecCtx, pFrame, &got_frame, &packet);
                
                if (got_frame)
                {
                    //NSLog(@"decode sps. got frame.");
                }
                
                free(tmpBuf);
            }
        }
        
        //==== PPS
        NSData * ppsData = [h264SPSPPSDelegate getPPS];
        if (ppsData != nil)
        {
            uint8_t * tmpBuf = malloc(4 + ppsData.length);
            if (tmpBuf)
            {
                memcpy(tmpBuf, startCode, 4);
                memcpy(tmpBuf+4, [ppsData bytes], ppsData.length);
                
                packet.data = tmpBuf;
                packet.size = 4+ppsData.length;
                
                avcodec_decode_video2(pCodecCtx, pFrame, &got_frame, &packet);
                
                if (got_frame)
                {
                    //NSLog(@"decode pps. got frame.");
                }
                free(tmpBuf);
            }
        }
    }
    
    packet.data = frameBuf;
    packet.size = frameSize;

#if 1//Yvonne. 9/13/2013 debug video play issue: 跳針
    int got_frame = 0;
#endif
    
    while (packet.size > 0)
    {
#if 0 //Yvonne. 9/13/2013 debug video play issue: 跳針
        int got_frame = 0;
#endif
        
        #if IS_PRINT_DECODE_TIME
        struct timeval before;
        gettimeofday(&before, NULL);
        #endif
        
        int len = avcodec_decode_video2(pCodecCtx, pFrame, &got_frame, &packet);
        
        #if IS_PRINT_DECODE_TIME
        struct timeval after;
        gettimeofday(&after, NULL);
        
        double cost_time = after.tv_sec * 1000000 + after.tv_usec - (before.tv_sec * 1000000 + before.tv_usec);
        decode_cost_time += cost_time;
        decode_count++;
        
        if (decode_count == 90)
        {
            NSLog(@"---avg decode time per frame:%lf", decode_cost_time / 90.0);
            decode_cost_time = 0.0;
            decode_count = 0;
        }
        #endif

        //NSLog(@"-----@ decode. got_frame:%d len:%d frameSize:%d", got_frame, len, frameSize);
        
        packet.size -= len;
        packet.data += len;
        
        if (isTakingSnapshot && got_frame)
        {
            UIImage *oneImg=nil;
            
            AVPicture picture_tmp;
            struct SwsContext *img_convert_ctx_tmp;
            avpicture_alloc(&picture_tmp, PIX_FMT_RGB24, pFrame->width, pFrame->height);
            img_convert_ctx_tmp = sws_getContext(pCodecCtx->width,
                                                 pCodecCtx->height,
                                                 pCodecCtx->pix_fmt,
                                                 pFrame->width,
                                                 pFrame->height,
                                                 PIX_FMT_RGB24,
                                                 SWS_FAST_BILINEAR, NULL, NULL, NULL);
            
            sws_scale (img_convert_ctx_tmp,
                       (const uint8_t **)pFrame->data,
                       pFrame->linesize,
                       0,
                       pCodecCtx->height,
                       picture_tmp.data,
                       picture_tmp.linesize);
            
            oneImg = [self imageFromAVPicture:picture_tmp width:pFrame->width height:pFrame->height];
            
            
            UIImageWriteToSavedPhotosAlbum(oneImg, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            
            isTakingSnapshot = NO;
        }
    }
    
#if 1//Yvonne. 9/13/2013 debug video play issue: 跳針
    if (got_frame)
    {
        return 0;
    }
    else
    {
        return 1;
    }
#endif
}
- (void) SnapShot_AlertView:(NSError *)error
{
    UIAlertView *alert=nil;
    
    if (error)
    {
        // TODO: display different error message
        alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                           message:@"The Storage is full!\nFail to save captured image!"
                                          delegate:self cancelButtonTitle:@"Ok"
                                 otherButtonTitles:nil];
    }
    else // All is well
    {
        alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                           message:@"Image has been captured in Camera Roll successfully"
                                          delegate:self cancelButtonTitle:@"Ok"
                                 otherButtonTitles:nil];
    }
    [alert show];
    alert = nil;
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    [self SnapShot_AlertView:error];
}
-(UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height
{
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict.data[0], pict.linesize[0]*height,kCFAllocatorNull);
	
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    
    
    CGImageRef cgImage = CGImageCreate(width,
									   height,
									   8,
									   24,
									   pict.linesize[0],
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


-(void) setH264SPSPPSDataDelegate:(id<VSaaSH264SPSPPSDataDelegate>) delegate
{
    h264SPSPPSDelegate = delegate;
}


static NSData * copyFrameData(UInt8 *src, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength: width * height];
    Byte *dst = md.mutableBytes;
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}

- (VSaaSVideoFrame *) handleVideoFrame
{
    AVFrame * _videoFrame = pFrame;
    AVCodecContext * _videoCodecCtx = pCodecCtx;

    if (!_videoFrame->data[0])
    {
        //NSLog(@"handleVideoFrame return nil");
        return nil;
    }
    
    VSaaSVideoFrame *frame = [[VSaaSVideoFrame alloc] init];
    
    
    frame.luma = copyFrameData(_videoFrame->data[0],
                                  _videoFrame->linesize[0],
                                  _videoCodecCtx->width,
                                  _videoCodecCtx->height);
    
    frame.chromaB = copyFrameData(_videoFrame->data[1],
                                     _videoFrame->linesize[1],
                                     _videoCodecCtx->width / 2,
                                     _videoCodecCtx->height / 2);
    
    frame.chromaR = copyFrameData(_videoFrame->data[2],
                                     _videoFrame->linesize[2],
                                     _videoCodecCtx->width / 2,
                                     _videoCodecCtx->height / 2);
    
    frame.width = _videoCodecCtx->width;
    frame.height = _videoCodecCtx->height;
    
    return frame;
}


//- (VSaaSVideoFrame *) CopyAVFrameToVideoFrame: (AVFrame *) pFrameIn withWidth :(int) vWidth withHeight:(int) vHeight
+ (VSaaSVideoFrame *) CopyAVFrameToVideoFrame: (AVFrame *) pFrameIn withWidth :(int) vWidth withHeight:(int) vHeight
{
    
    if (!pFrameIn->data[0])
    {
        NSLog(@"CopyAVFrameToVideoFrame return nil");
        return nil;
    }
    
    VSaaSVideoFrame *yuvFrame = [[VSaaSVideoFrame alloc] init];
    
    
    yuvFrame.luma = copyFrameData(pFrameIn->data[0],
                                  pFrameIn->linesize[0],
                                  vWidth,
                                  vHeight);
    
    yuvFrame.chromaB = copyFrameData(pFrameIn->data[1],
                                     pFrameIn->linesize[1],
                                     vWidth / 2,
                                     vHeight / 2);
    
    yuvFrame.chromaR = copyFrameData(pFrameIn->data[2],
                                     pFrameIn->linesize[2],
                                     vWidth / 2,
                                     vHeight / 2);
    
    yuvFrame.width = vWidth;
    yuvFrame.height = vHeight;
    
    
    return yuvFrame;
}



- (AVCodecContext *) get_pCodecCtx
{
    return 	pCodecCtx;
}

-(void) takeSnapshot
{
    isTakingSnapshot = YES;
}

-(void) prepareNextRtspClient:(id<VSaaSH264SPSPPSDataDelegate>)d
{
    h264SPSPPSDelegate = d;
    is_decode_sps_pps = NO;
}
@end
