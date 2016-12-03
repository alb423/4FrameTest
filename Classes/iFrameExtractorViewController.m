//
//  ViewController.m
//  4FrameTest
//
//  Created by Liao KuoHsun on 2016/12/3.
//
//

#import "iFrameExtractorViewController.h"
#import "VideoFrameExtractor.h"
#import "Utilities.h"
#import "MyGLView.h"
#include <sys/time.h>

#define PLAY_MEMORY_FILE 1
#define PLAY_REMOTE_FILE 2


// Configuration
#define PLAY_MEHTOD PLAY_MEMORY_FILE // PLAY_MEMORY_FILE, PLAY_REMOTE_FILE
#define RENDER_BY_OPENGLES 1
#define ENABLE_DISPATCH_QUEUE_FOR_GLVIEW 0 // enable will cause crash



#if PLAY_MEHTOD == PLAY_MEMORY_FILE

//#define VIDEO_SRC1 @"IMG_0292.mp4"
//#define VIDEO_SRC1 @"IMG_0292_moovHead.mp4"
#define VIDEO_SRC1 @"320x180_64kbps_7fps.mp4"
//#define VIDEO_SRC1 @"160x90_64kbps_7fps.mp4"
//#define VIDEO_SRC1 @"7h800.mp4"
#define VIDEO_SRC2 @"7h800-2.mp4"
#define VIDEO_SRC3 @"7h800-3.mp4"
#define VIDEO_SRC4 @"7h800-4.mp4"

#else
//#define VIDEO_SRC1 @"rtsp://mm2.pcslab.com/mm/7h800.mp4"
//#define VIDEO_SRC2 @"rtsp://mm2.pcslab.com/mm/7h800.mp4"
//#define VIDEO_SRC3 @"rtsp://mm2.pcslab.com/mm/7h800.mp4"
//#define VIDEO_SRC4 @"rtsp://mm2.pcslab.com/mm/7h800.mp4"

#define VIDEO_SRC1 @"rtsp://192.168.82.75/stream2"
#define VIDEO_SRC2 @"rtsp://192.168.82.75/stream2"
//#define VIDEO_SRC1 @"rtsp://210.65.250.18:80/cam000b67014ff4001/20131025/094606.mp4"
//#define VIDEO_SRC2 @"rtsp://210.65.250.18:80/cam000b67014ff4001/20131025/094606.mp4"
#define VIDEO_SRC3 @"rtsp://210.65.250.18:80/cam000b67014ff4001/20131025/094606.mp4"
#define VIDEO_SRC4 @"rtsp://210.65.250.18:80/cam000b67014ff4001/20131025/094606.mp4"

#endif


//#define VIDEO_SRC @"rtsp://mm2.pcslab.com/mm/7h800.mp4"
//#define VIDEO_SRC @"rtsp://quicktime.tc.columbia.edu:554/users/lrf10/movies/sixties.mov"





@interface iFrameExtractorViewController ()

@end

@implementation iFrameExtractorViewController
int vRtspNum = 1;
int isStop =0;

int   vDecodeNum = 0;
double vDecodeTime = 0.0;
double vCopyFrameTime = 0.0;
int   vShowImageNum = 0;
double vShowImageTime = 0.0;

int vDisplayCount = 0;
NSMutableArray *myImage;

@synthesize window, imageView, imageView2, imageView3, imageView4, label, DecodeLabel, ShowImageLabel, playButton, FPS;
#if OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_4
//@synthesize video1, video2, video3, video4;
#elif OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_8
@synthesize video1, video2, video3, video4, video5, video6, video7, video8;
#elif OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_16
@synthesize video1, video2, video3, video4, video5, video6, video7, video8, video9, video10, video11, video12, video13, video14, video15, video16 ;
#endif

@synthesize viewController = _viewController;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (_dispatchQueue) {
        _dispatchQueue = NULL;
    }
    
    // Override point for customization after application launch.
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#if RENDER_BY_OPENGLES==1 // Test for shaders
-(IBAction)playButtonAction:(id)sender {
    [playButton setEnabled:NO];
    isStop = 0;
    
    int VideoHeight=960;
    int VideoWidth=640;
    
    [playButton setEnabled:NO];
    isStop = 0;
    
#if OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_4
    
    UIButton *vBn = (UIButton *)sender;
    
    if([vBn.currentTitle isEqualToString:@"1"])
    {
        vRtspNum=1;
#if PLAY_MEHTOD == PLAY_MEMORY_FILE
        self->video1 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
#else
        self.video1 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC1];
#endif
        [video1 seekTime:0.0];
    }
    else if([vBn.currentTitle isEqualToString:@"2"])
    {
        vRtspNum=2;
#if PLAY_MEHTOD == PLAY_MEMORY_FILE
        self->video1 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self->video2 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC2]];
#else
        self.video1 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC1];
        self.video2 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC2];
#endif
        [video1 seekTime:0.0];
        [video2 seekTime:0.0];
    }
    else if([vBn.currentTitle isEqualToString:@"4"])
    {
        vRtspNum=4;
#if PLAY_MEHTOD == PLAY_MEMORY_FILE
        self->video1 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self->video2 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC2]];
        self->video3 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC3]];
        self->video4 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC4]];
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
    
#else
    
    
    {
        vRtspNum=OPENGL_RENDER_SCREE_NUM;
#if PLAY_MEHTOD == PLAY_MEMORY_FILE
        video1 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video2 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video3 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video4 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video5 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video6 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video7 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video8 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video9 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video10 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video11 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video12 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video13 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video14 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video15 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        video16 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        
        [video1 seekTime:0.0];
        [video2 seekTime:0.0];
        [video3 seekTime:0.0];
        [video4 seekTime:0.0];
        [video5 seekTime:0.0];
        [video6 seekTime:0.0];
        [video7 seekTime:0.0];
        [video8 seekTime:0.0];
        [video9 seekTime:0.0];
        [video10 seekTime:0.0];
        [video11 seekTime:0.0];
        [video12 seekTime:0.0];
        [video13 seekTime:0.0];
        [video14 seekTime:0.0];
        [video15 seekTime:0.0];
        [video16 seekTime:0.0];
#else
        // do nothing
#endif
    }
#endif
    
    
    // The bound should be assigned to the same size of screen
    //CGRect vBound = self.window.bounds;
    
    // The size should be set according the video size, 1280 * 720 for 720p
    VideoWidth = video1.sourceWidth;
    VideoHeight = video1.sourceHeight;
    
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
    
    
#if OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_4
    myGLView = [[MyGLView alloc] initWithFrame:vBound splitnumber:vRtspNum frameWidth:VideoWidth frameHeight:VideoHeight];
    
    // Set this so that the texture will scale to the windows
    //myGLView.contentMode = UIViewContentModeScaleAspectFit;
    
    //    <#CGAffineTransform t#>;
    //    CGAffineTransformTranslate(t, 1, 1);
    //[self.window addSubview:myGLView];
    [self.window insertSubview:myGLView atIndex:0];
#else
    // do nothing
#endif
    
    self.FPS = video1.fps;
    if(self.FPS==0) self.FPS=30;
    
#if OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_4
    // do nothing
#else
    self.FPS=7;
#endif
    
    NSLog(@"RTSPNUM=%d self.FPS=%ld", vRtspNum, (long)self.FPS);
    {
        
        
        [NSTimer scheduledTimerWithTimeInterval:1.0/self.FPS
                                         target:self
                                       selector:@selector(displayNextFrame_Optimized:)
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
    else if([vBn.currentTitle isEqualToString:@"4"])
        vRtspNum=4;
    else
        vRtspNum=OPENGL_RENDER_SCREE_NUM; // 8 or 16
    
    
    // video images are landscape, so rotate image view 90 degrees
    [imageView setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    [imageView2 setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    [imageView3 setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    [imageView4 setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    
    // set output image size
    if(vRtspNum==1)
    {
        ScreenHeight=426;
        ScreenWidth=320;
        
#if PLAY_MEHTOD == PLAY_MEMORY_FILE
        self.video1 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
#else
        self.video1 = [[VideoFrameExtractor alloc] initWithVideo:VIDEO_SRC1];
#endif
        
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
    else
    {
        self.video1 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video2 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video3 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video4 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video5 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video6 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video7 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video8 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video9 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video10 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video11 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video12 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video13 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video14 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video15 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        self.video16 = [[VideoFrameExtractor alloc] initWithVideoMemory:[Utilities bundlePath:VIDEO_SRC1]];
        
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
    else
    {
        [video2 seekTime:0.0];
        [video3 seekTime:0.0];
        [video4 seekTime:0.0];
        [video5 seekTime:0.0];
        [video6 seekTime:0.0];
        [video7 seekTime:0.0];
        [video8 seekTime:0.0];
        [video9 seekTime:0.0];
        [video10 seekTime:0.0];
        [video11 seekTime:0.0];
        [video12 seekTime:0.0];
        [video13 seekTime:0.0];
        [video14 seekTime:0.0];
        [video15 seekTime:0.0];
        [video16 seekTime:0.0];
    }
    
    // TODO: mark me
    self.FPS = video1.fps;
    if(self.FPS==0) self.FPS=30;
    
    NSLog(@"RTSPNUM=%d self.FPS=%d", vRtspNum, self.FPS);
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

-(void)displayNextFrame_Optimized:(NSTimer *)timer {
    
    struct timeval before, after;
    
#if OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_4
    [myGLView clearFrameBuffer];
#endif
    
    //NSLog(@"displayNextFrame_Optimized");
    if(isStop)
    {
        [timer invalidate];
        [playButton setEnabled:YES];
        return;
    }
    
    
    gettimeofday(&before, NULL);
    if (![video1 stepFrame]) {
        NSLog(@"video1 stepFrame fail");
        [timer invalidate];
        [playButton setEnabled:YES];
        return;
    }
#if OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_4
    gettimeofday(&after, NULL);
    vDecodeTime += after.tv_sec * 1000000 + after.tv_usec - (before.tv_sec * 1000000 + before.tv_usec);
    vDecodeNum++;
    
    gettimeofday(&before, NULL);
    [myGLView setAVFrame:self->video1->pYUVFrame at:eLOC_TOP_LEFT];
#endif
    //    gettimeofday(&after, NULL);
    //    vCopyFrameTime += after.tv_sec * 1000000 + after.tv_usec - (before.tv_sec * 1000000 + before.tv_usec);
    
    
    //vShowImageTime = [NSDate timeIntervalSinceReferenceDate]-vTmpTime;
    vShowImageTime = vCopyFrameTime;
    vShowImageNum++;
    
#if OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_4
    //NSLog(@"OPENGL_RENDER_SCREE_NUM_4");
    if(vRtspNum>=2)
    {
        [video2 stepFrame];
        
        [myGLView setAVFrame:self->video2->pYUVFrame at:eLOC_TOP_RIGHT];
        
        gettimeofday(&after, NULL);
        vCopyFrameTime += after.tv_sec * 1000000 + after.tv_usec - (before.tv_sec * 1000000 + before.tv_usec);
        
        if(vRtspNum==4)
        {
            [video3 stepFrame];
            
            [myGLView setAVFrame:self->video3->pYUVFrame at:eLOC_BOTTOM_LEFT];
            
            
            [video4 stepFrame];
            [myGLView setAVFrame:self->video4->pYUVFrame at:eLOC_BOTTOM_RIGHT];
        }
    }
    pVideoFrame1 = nil;
    pVideoFrame2 = nil;
    pVideoFrame3 = nil;
    pVideoFrame4 = nil;
#elif OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_8
    
    [video2 stepFrame];
    [video3 stepFrame];
    [video4 stepFrame];
    [video5 stepFrame];
    [video6 stepFrame];
    [video7 stepFrame];
    [video8 stepFrame];
    
    gettimeofday(&after, NULL);
    vDecodeTime += after.tv_sec * 1000000 + after.tv_usec - (before.tv_sec * 1000000 + before.tv_usec);
    vDecodeNum++;
#elif OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_16
    
    [video2 stepFrame];
    [video3 stepFrame];
    [video4 stepFrame];
    [video5 stepFrame];
    [video6 stepFrame];
    [video7 stepFrame];
    [video8 stepFrame];
    [video9 stepFrame];
    [video10 stepFrame];
    [video11 stepFrame];
    [video12 stepFrame];
    [video13 stepFrame];
    [video14 stepFrame];
    [video15 stepFrame];
    [video16 stepFrame];
    
    gettimeofday(&after, NULL);
    vDecodeTime += after.tv_sec * 1000000 + after.tv_usec - (before.tv_sec * 1000000 + before.tv_usec);
    vDecodeNum++;
#endif
    
    
    
    
    //	float frameTime = 1.0/([NSDate timeIntervalSinceReferenceDate]-startTime);
    //	if (lastFrameTime<0) {
    //		lastFrameTime = frameTime;
    //	} else {
    //		lastFrameTime = LERP(frameTime, lastFrameTime, 0.8);
    //	}
    //	[label setText:[NSString stringWithFormat:@"%.0f",lastFrameTime]];
    
    vDisplayCount++;
    if(vDisplayCount==self.FPS) // display once per second
    {
        // update the estimate time
        [self.DecodeLabel setText:[NSString stringWithFormat:@"%f", (vDecodeTime/self.FPS/1000000)]];
        [self.ShowImageLabel setText:[NSString stringWithFormat:@"%f", (vShowImageTime/self.FPS/1000000)]];
        //NSLog(@"self.FPS = %d ",self.FPS);
        //NSLog(@"<--Current Time");
        
        NSLog(@"Time %f %f %f", (vDecodeTime/self.FPS/1000000), (vCopyFrameTime/self.FPS/1000000), (vShowImageTime/self.FPS/1000000));
        
        vDecodeNum=0;
        vShowImageNum=0;
        vShowImageTime=0.0;
        vDecodeTime=0.0;
        vDisplayCount=0;
        
        vCopyFrameTime=0.0;
    }
    
#if OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_4
    [myGLView RenderToHardware:nil];
#endif
}


-(void)displayNextFrame_OpenGLEs:(NSTimer *)timer {
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval vTmpTime= [NSDate timeIntervalSinceReferenceDate];
    
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
    pVideoFrame1 =[MyGLView CopyFullAVFrameToVideoFrame:video1->pYUVFrame \
                                              withWidth: video1->pYUVFrame->width \
                                             withHeight: video1->pYUVFrame->height];
    
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
        pVideoFrame2 =[MyGLView CopyFullAVFrameToVideoFrame:video2->pYUVFrame \
                                                  withWidth: video2->pYUVFrame->width \
                                                 withHeight: video2->pYUVFrame->height];
        
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
            pVideoFrame3 =[MyGLView CopyFullAVFrameToVideoFrame:video1->pYUVFrame \
                                                      withWidth: video1->pYUVFrame->width \
                                                     withHeight: video1->pYUVFrame->height];
            
#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
            dispatch_async(_dispatchQueue, ^{
#endif
                [myGLView setFrame:pVideoFrame3 at:eLOC_BOTTOM_LEFT];
#if ENABLE_DISPATCH_QUEUE_FOR_GLVIEW == 1
            });
#endif
            
            [video4 stepFrame];
            pVideoFrame4 =[MyGLView CopyFullAVFrameToVideoFrame:video1->pYUVFrame \
                                                      withWidth: video1->pYUVFrame->width \
                                                     withHeight: video1->pYUVFrame->height];
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
