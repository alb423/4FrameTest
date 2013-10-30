//
//  iFrameExtractorAppDelegate.m
//  iFrameExtractor
//
//  Created by lajos on 1/8/10.
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

#import "iFrameExtractorAppDelegate.h"
#import "VideoFrameExtractor.h"
#import "Utilities.h"
#import "MyGLView.h"


#define PLAY_MEMORY_FILE 1
#define PLAY_REMOTE_FILE 2

#if PLAY_MEHTOD == PLAY_MEMORY_FILE

#define VIDEO_SRC1 @"7h800.mp4"
#define VIDEO_SRC2 @"7h800-2.mp4"
#define VIDEO_SRC3 @"7h800-3.mp4"
#define VIDEO_SRC4 @"7h800-4.mp4"

#else
//#define VIDEO_SRC1 @"rtsp://mm2.pcslab.com/mm/7h800.mp4"
//#define VIDEO_SRC2 @"rtsp://mm2.pcslab.com/mm/7h800.mp4"
//#define VIDEO_SRC3 @"rtsp://mm2.pcslab.com/mm/7h800.mp4"
//#define VIDEO_SRC4 @"rtsp://mm2.pcslab.com/mm/7h800.mp4"


#endif


//#define VIDEO_SRC @"rtsp://mm2.pcslab.com/mm/7h800.mp4"
//#define VIDEO_SRC @"rtsp://quicktime.tc.columbia.edu:554/users/lrf10/movies/sixties.mov"


// Configuration
#define PLAY_MEHTOD PLAY_REMOTE_FILE
#define RENDER_BY_OPENGLES 1
#define ENABLE_DISPATCH_QUEUE_FOR_GLVIEW 0 // enable will cause crash



@implementation iFrameExtractorAppDelegate
int vRtspNum = 1;
int isStop =0;

int   vDecodeNum = 0;
float vDecodeTime = 0.0;
float vCopyFrameTime = 0.0;
int   vShowImageNum = 0;
float vShowImageTime = 0.0;

int vDisplayCount = 0;
NSMutableArray *myImage;

@synthesize window, imageView, imageView2, imageView3, imageView4, label, DecodeLabel, ShowImageLabel, playButton, video1, video2, video3, video4, FPS;


-(void)applicationDidEnterBackground:(UIApplication *)application
{
    if (_dispatchQueue) {
        _dispatchQueue = NULL;
    }
}


@synthesize viewController = _viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    isStop = 0;
    FPS = 30;
    
    
	//self.video2 = [[VideoFrameExtractor alloc] initWithVideo:[Utilities bundlePath:@"rtsp://quicktime.tc.columbia.edu:554/users/lrf10/movies/sixties.mov"]];
    //self.video1 = [[VideoFrameExtractor alloc] initWithVideo:[Utilities bundlePath:@"22.5b67a4e4e5508f98.mp4"]];
    //self.video = [[VideoFrameExtractor alloc] initWithVideo:[Utilities bundlePath:@"rtsp://192.168.82.170:554/livestream"]];
    //self.video = [[VideoFrameExtractor alloc] initWithVideo:[Utilities bundlePath:@"rtsp://mm2.pcslab.com/mm/7h800.mp4"]];
    //self.video = [[VideoFrameExtractor alloc] initWithVideo:[Utilities bundlePath:@"rtsp://quicktime.tc.columbia.edu:554/users/lrf10/movies/sixties.mov"]];
    //rtsp://mm2.pcslab.com/mm/7h800.mp4

    _dispatchQueue  = dispatch_queue_create("MyGLView", DISPATCH_QUEUE_SERIAL);
    
    [window makeKeyAndVisible];
}

#if RENDER_BY_OPENGLES==1 // Test for shaders
-(IBAction)playButtonAction:(id)sender {
	[playButton setEnabled:NO];
    isStop = 0;
    
    int VideoHeight=960;
    int VideoWidth=640;
    
	[playButton setEnabled:NO];
    isStop = 0;

    UIButton *vBn = (UIButton *)sender;
    
    if([vBn.currentTitle isEqualToString:@"1"])
    {
        vRtspNum=1;
#if PLAY_MEHTOD == PLAY_MEMORY_FILE
        self.video1 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
#else
        self.video1 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC1];
#endif
        [video1 seekTime:0.0];
    }
    else if([vBn.currentTitle isEqualToString:@"2"])
    {
        vRtspNum=2;
#if PLAY_MEHTOD == PLAY_MEMORY_FILE
        self.video1 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video2 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC2]];
#else
        self.video1 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC1];
        self.video2 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC2];
#endif
        [video1 seekTime:0.0];
        [video2 seekTime:0.0];
    }
    else
    {
        vRtspNum=4;
#if PLAY_MEHTOD == PLAY_MEMORY_FILE
        self.video1 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video2 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC2]];
        self.video3 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC3]];
        self.video4 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC4]];
#else
        self.video1 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC1];
        self.video2 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC2];
        self.video3 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC3];
        self.video4 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC4];
#endif
        [video1 seekTime:0.0];
        [video2 seekTime:0.0];
        [video3 seekTime:0.0];
        [video4 seekTime:0.0];
    }
    
    // The bound should be assigned to the same size of screen
    //CGRect vBound = self.window.bounds;
    
    // The size should be set according the video size, 1280 * 720 for 720p
    VideoWidth = self.video1.sourceWidth;
    VideoHeight = self.video1.sourceHeight;

#if 0
    CGRect vBound;
    vBound.origin.x = self.window.bounds.origin.x;
    vBound.origin.y = self.window.bounds.origin.y;
    vBound.size.width=self.window.bounds.size.width;
    vBound.size.height=self.window.bounds.size.height; // (320,480) for iPhone4
#else
    CGRect vBound = [[UIScreen mainScreen] bounds];
#endif
    NSLog(@"x,y,w,h = (%.0f,%.0f,%.0f,%.0f)",vBound.origin.x,vBound.origin.y,vBound.size.width,vBound.size.height);
    
    
    myGLView = [[MyGLView alloc] initWithFrame:vBound splitnumber:vRtspNum frameWidth:VideoWidth frameHeight:VideoHeight];

    // Set this so that the texture will scale to the windows
    myGLView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self.window insertSubview:myGLView atIndex:0];

    NSLog(@"RTSPNUM=%d", vRtspNum);
    {
        [NSTimer scheduledTimerWithTimeInterval:1.0/self.FPS
                                         target:self
                                       selector:@selector(displayNextFrame:)
                                       userInfo:nil
                                        repeats:YES];
    }
    
}

#else
-(IBAction)playButtonAction:(id)sender {

    isStop = 0;
    
    int ScreenHeight=960;
    int ScreenWidth=640;
    
	[playButton setEnabled:NO];
    isStop = 0;
    
	lastFrameTime = -1;

    UIButton *vBn = (UIButton *)sender;
    NSLog(@"playButton.currentTitle=%@", vBn.currentTitle);
    imageView.image = nil;
    imageView2.image = nil;
    imageView3.image = nil;
    imageView4.image = nil;
    
    
    if([vBn.currentTitle isEqualToString:@"1"])
        vRtspNum=1;
    else if([vBn.currentTitle isEqualToString:@"2"])
        vRtspNum=2;
    else
        vRtspNum=4;
 
	
	// video images are landscape, so rotate image view 90 degrees
	[imageView setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    [imageView2 setTransform:CGAffineTransformMakeRotation(M_PI/2)];
	[imageView3 setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    [imageView4 setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    
#if PLAY_MEHTOD == PLAY_MEMORY_FILE
    self.video1 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
#else
    self.video1 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC1];
#endif
    
    // set output image size
    if(vRtspNum==1)
    {
        ScreenHeight=426;
        ScreenWidth=320;
        video1.outputWidth = ScreenHeight;
        video1.outputHeight = ScreenWidth;
    }
    else if(vRtspNum==2)
    {
        [imageView setTransform:CGAffineTransformMakeRotation(M_PI*2)];
        [imageView2 setTransform:CGAffineTransformMakeRotation(M_PI*2)];
        ScreenHeight=426;
        ScreenWidth=320;
        
#if PLAY_MEHTOD == PLAY_MEMORY_FILE
        self.video2 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC2]];
#else
        self.video2 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC2];
#endif
        
        video1.outputWidth = ScreenWidth;
        video1.outputHeight = ScreenHeight/2;
        video2.outputWidth = ScreenWidth;
        video2.outputHeight = ScreenHeight/2;
    }
    else if(vRtspNum==4)
    {
        ScreenHeight=426;
        ScreenWidth=320;

#if PLAY_MEHTOD == PLAY_MEMORY_FILE
        self.video2 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC2]];
        self.video3 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC3]];
        self.video4 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC4]];
#else
        self.video2 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC2];
        self.video3 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC3];
        self.video4 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC4];
#endif

        video1.outputWidth = ScreenHeight/2;//426;
        video1.outputHeight = ScreenWidth/2; // 320
        video2.outputWidth = ScreenHeight/2;//426;
        video2.outputHeight = ScreenWidth/2;
        video3.outputWidth = ScreenHeight/2;//426;
        video3.outputHeight = ScreenWidth/2;
        video4.outputWidth = ScreenHeight/2;//426;
        video4.outputHeight = ScreenWidth/2;
    }

    
	// print some info about the video
	NSLog(@"video duration: %f",video1.duration);
	NSLog(@"video src size: %d x %d", video1.sourceWidth, video1.sourceHeight);
	NSLog(@"video out size: %d x %d", video1.outputWidth, video1.outputHeight);    
    

    if(vRtspNum==1)
    {
        CGRect vBound = CGRectMake(0, 0, ScreenHeight, ScreenWidth);
        [imageView setBounds:vBound];
        [imageView setCenter:CGPointMake(ScreenWidth/2,ScreenHeight/2)];
    }
    else if(vRtspNum==2)
    {
        [imageView setBounds:CGRectMake(0, 0, ScreenWidth/2, ScreenHeight)];
        [imageView setCenter:CGPointMake(ScreenWidth/2,  ScreenHeight/2 - ScreenHeight/4 -1 )];
        [imageView2 setBounds:CGRectMake(0, 0, ScreenWidth/2, ScreenHeight)];
        [imageView2 setCenter:CGPointMake(ScreenWidth/2,  ScreenHeight/2 + ScreenHeight/4 -1)];
        
    }
    else if(vRtspNum==4)
    {
        [imageView setBounds:CGRectMake(0, 0, ScreenWidth/2, ScreenHeight/2)];
        [imageView setCenter:CGPointMake(ScreenWidth/2 - ScreenWidth/4,  ScreenHeight/2 - ScreenHeight/4 -1)];
        
        [imageView2 setBounds:CGRectMake(0, 0, ScreenWidth/2, ScreenHeight/2)];
        [imageView2 setCenter:CGPointMake(ScreenWidth/2 - ScreenWidth/4,  ScreenHeight/2 + ScreenHeight/4 -1)];

        [imageView3 setBounds:CGRectMake(0, 0, ScreenWidth/2, ScreenHeight/2)];
        [imageView3 setCenter:CGPointMake(ScreenWidth/2 + ScreenWidth/4,  ScreenHeight/2 - ScreenHeight/4 -1)];

        [imageView4 setBounds:CGRectMake(0, 0, ScreenWidth/2, ScreenHeight/2)];
        [imageView4 setCenter:CGPointMake(ScreenWidth/2 + ScreenWidth/4,  ScreenHeight/2 + ScreenHeight/4 -1)];
    }
    // set vRtspNum

    
	// seek to 0.0 seconds
	[video1 seekTime:0.0];
    if(vRtspNum==2)
    {
        [video2 seekTime:0.0];

    }
    else if(vRtspNum==4)
    {
	   [video2 seekTime:0.0];
	   [video3 seekTime:0.0];
	   [video4 seekTime:0.0];
    }
    
    // TODO: mark me
    self.FPS = video1.fps;
    if(self.FPS==0) self.FPS=30;
    
    NSLog(@"RTSPNUM=%d", vRtspNum);
    {
        [NSTimer scheduledTimerWithTimeInterval:1.0/self.FPS
                                         target:self
                                       selector:@selector(displayNextFrame:)
                                       userInfo:nil
                                        repeats:YES];
    }
    
}
#endif


- (void) updateUI_1
{
    
    vDisplayCount++;
    if(vDisplayCount==self.FPS)
    {
        // update the estimate time
        //        NSLog(@"Decode Time=%f", vDecodeTime / vDecodeNum);
        //        NSLog(@"ShowImage Time=%f", vShowImageTime / vShowImageNum);
        [self.DecodeLabel setText:[NSString stringWithFormat:@"%f", (vDecodeTime/vDecodeNum)]];
        [self.ShowImageLabel setText:[NSString stringWithFormat:@"%f", (vShowImageTime/vShowImageNum)]];
        
        vDecodeNum=0;
        vShowImageNum=0;
        vShowImageTime=0.0;
        vDecodeTime=0.0;
        vDisplayCount=0;
    }
    
    imageView.image = video1.currentImage;
    
}

- (void) updateUI_2
{
    imageView2.image = video2.currentImage;
}

- (void) updateUI_3
{
    imageView3.image = video3.currentImage;
}

- (void) updateUI_4
{
    imageView4.image = video4.currentImage;
}


- (IBAction)showTime:(id)sender {
    NSLog(@"current time: %f s",video1.currentTime);
    // add stop here
    isStop = 1;
}

#define LERP(A,B,C) ((A)*(1.0-C)+(B)*C)

#if RENDER_BY_OPENGLES==1
-(void)displayNextFrame:(NSTimer *)timer {
	NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval vTmpTime= [NSDate timeIntervalSinceReferenceDate];

    
    //MyVideoFrame * pVideoFrame1, *pVideoFrame2, *pVideoFrame3, *pVideoFrame4;
    // albert.liao ***
#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
    dispatch_async(_dispatchQueue, ^{
#endif
    [myGLView clearFrameBuffer];
#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
    });
#endif
            
    if(isStop)
    {
		[timer invalidate];
		[playButton setEnabled:YES];
		return;
	}
    
    vTmpTime = [NSDate timeIntervalSinceReferenceDate];
	if (![video1 stepFrame]) {
		[timer invalidate];
		[playButton setEnabled:YES];
		return;
	}
    vDecodeTime += [NSDate timeIntervalSinceReferenceDate]-vTmpTime;
    vDecodeNum++;

    
    vTmpTime = [NSDate timeIntervalSinceReferenceDate];
    
    // This function cost about 11ms in iPad2...
    // This is the bottle neck of GLView
    pVideoFrame1 =[MyGLView CopyFullAVFrameToVideoFrame:self.video1->pFrame \
                                          withWidth: self.video1->pFrame->width \
                                         withHeight: self.video1->pFrame->height];
    
    vCopyFrameTime += [NSDate timeIntervalSinceReferenceDate]-vTmpTime;
    
    
#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
    dispatch_async(_dispatchQueue, ^{
#endif
    
    [myGLView setFrame:pVideoFrame1 at:eLOC_TOP_LEFT];
        
#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
    });
#endif
    

    vShowImageTime += [NSDate timeIntervalSinceReferenceDate]-vTmpTime;
    vShowImageNum++;
    
    if(vRtspNum>=2)
    {
        [video2 stepFrame];
        pVideoFrame2 =[MyGLView CopyFullAVFrameToVideoFrame:self.video2->pFrame \
                                                                   withWidth: self.video2->pFrame->width \
                                                                  withHeight: self.video2->pFrame->height];

#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
        dispatch_async(_dispatchQueue, ^{
#endif
            [myGLView setFrame:pVideoFrame2 at:eLOC_TOP_RIGHT];
#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
        });
#endif

        if(vRtspNum==4)
        {
            [video3 stepFrame];
            pVideoFrame3 =[MyGLView CopyFullAVFrameToVideoFrame:self.video1->pFrame \
                                                                       withWidth: self.video1->pFrame->width \
                                                                      withHeight: self.video1->pFrame->height];

#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
            dispatch_async(_dispatchQueue, ^{
#endif
                [myGLView setFrame:pVideoFrame3 at:eLOC_BOTTOM_LEFT];
#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
            });
#endif

            [video4 stepFrame];
            pVideoFrame4 =[MyGLView CopyFullAVFrameToVideoFrame:self.video1->pFrame \
                                                                       withWidth: self.video1->pFrame->width \
                                                                      withHeight: self.video1->pFrame->height];
#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
            dispatch_async(_dispatchQueue, ^{
#endif
                [myGLView setFrame:pVideoFrame4 at:eLOC_BOTTOM_RIGHT];
#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
            });
#endif
        }
    }

    pVideoFrame1 = nil;
    pVideoFrame2 = nil;
    pVideoFrame3 = nil;
    pVideoFrame4 = nil;
//    av_free(self.video1->pFrame);
//    av_free(self.video2->pFrame);
//    av_free(self.video3->pFrame);
//    av_free(self.video4->pFrame);
    
	float frameTime = 1.0/([NSDate timeIntervalSinceReferenceDate]-startTime);
	if (lastFrameTime<0) {
		lastFrameTime = frameTime;
	} else {
		lastFrameTime = LERP(frameTime, lastFrameTime, 0.8);
	}
	[label setText:[NSString stringWithFormat:@"%.0f",lastFrameTime]];
    
    vDisplayCount++;
    if(vDisplayCount==self.FPS) // display once per second
    {
        // update the estimate time
        [self.DecodeLabel setText:[NSString stringWithFormat:@"%f", (vDecodeTime/self.FPS)]];
        [self.ShowImageLabel setText:[NSString stringWithFormat:@"%f", (vShowImageTime/self.FPS)]];
        //NSLog(@"self.FPS = %d ",self.FPS);
        NSLog(@"<--Current Time");
        
        NSLog(@"RenderTime %f %f", (vCopyFrameTime/self.FPS), (vShowImageTime/self.FPS));
        
        
        vDecodeNum=0;
        vShowImageNum=0;
        vShowImageTime=0.0;
        vDecodeTime=0.0;
        vDisplayCount=0;
        
        vCopyFrameTime=0.0;
    }
    
    
#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
    dispatch_async(_dispatchQueue, ^{
#endif
        [myGLView RenderToHardware:nil];
#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
    });
#endif
    

}


#else
-(void)displayNextFrame:(NSTimer *)timer {
	NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval vTmpTime= [NSDate timeIntervalSinceReferenceDate];

    if(isStop)
    {
		[timer invalidate];
		[playButton setEnabled:YES];
		return;
	}
    
    vTmpTime = [NSDate timeIntervalSinceReferenceDate];
	if (![video1 stepFrame]) {
		[timer invalidate];
		[playButton setEnabled:YES];
		return;
	}
    vDecodeTime += [NSDate timeIntervalSinceReferenceDate]-vTmpTime;
    vDecodeNum++;
    
    
    vTmpTime = [NSDate timeIntervalSinceReferenceDate];
	imageView.image = video1.currentImage;
    vShowImageTime += [NSDate timeIntervalSinceReferenceDate]-vTmpTime;
    vShowImageNum++;
    
    if(vRtspNum>=2)
    {
        [video2 stepFrame];
        imageView2.image = video2.currentImage;
        if(vRtspNum==4)
        {
            [video3 stepFrame];
            imageView3.image = video3.currentImage;
            [video4 stepFrame];
            imageView4.image = video4.currentImage;
        }
    }
        
	float frameTime = 1.0/([NSDate timeIntervalSinceReferenceDate]-startTime);
	if (lastFrameTime<0) {
		lastFrameTime = frameTime;
	} else {
		lastFrameTime = LERP(frameTime, lastFrameTime, 0.8);
	}
	[label setText:[NSString stringWithFormat:@"%.0f",lastFrameTime]];
    
    vDisplayCount++;
    if(vDisplayCount==self.FPS) // display once per second
    {
        // update the estimate time
        [self.DecodeLabel setText:[NSString stringWithFormat:@"%f", (vDecodeTime/self.FPS)]];
        [self.ShowImageLabel setText:[NSString stringWithFormat:@"%f", (vShowImageTime/self.FPS)]];
        NSLog(@"<--Current Time");
        
        vDecodeNum=0;
        vShowImageNum=0;
        vShowImageTime=0.0;
        vDecodeTime=0.0;
        vDisplayCount=0;
        
    }
}
#endif

@end
