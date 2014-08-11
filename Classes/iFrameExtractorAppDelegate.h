//
//  iFrameExtractorAppDelegate.h
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

#import <UIKit/UIKit.h>
#import "MyGLView.h"

@class VideoFrameExtractor;

@interface iFrameExtractorAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	IBOutlet UIImageView *imageView;
	IBOutlet UIImageView *imageView2;
	IBOutlet UIImageView *imageView3;
	IBOutlet UIImageView *imageView4;
	IBOutlet UILabel *label;
	IBOutlet UIButton *playButton;
//#if OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_4
//	VideoFrameExtractor *video1;
//    VideoFrameExtractor *video2;
//    VideoFrameExtractor *video3;
//    VideoFrameExtractor *video4;
//#else
	VideoFrameExtractor *video1;
    VideoFrameExtractor *video2;
    VideoFrameExtractor *video3;
    VideoFrameExtractor *video4;
	VideoFrameExtractor *video5;
    VideoFrameExtractor *video6;
    VideoFrameExtractor *video7;
    VideoFrameExtractor *video8;
	VideoFrameExtractor *video9;
    VideoFrameExtractor *video10;
    VideoFrameExtractor *video11;
    VideoFrameExtractor *video12;
	VideoFrameExtractor *video13;
    VideoFrameExtractor *video14;
    VideoFrameExtractor *video15;
    VideoFrameExtractor *video16;
//#endif
	float lastFrameTime;
    
    MyGLView *myGLView;
    dispatch_queue_t    _dispatchQueue;
    
#if OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_4
    MyVideoFrame * pVideoFrame1, *pVideoFrame2, *pVideoFrame3, *pVideoFrame4;
#else
    MyVideoFrame * pVideoFrame1, *pVideoFrame2, *pVideoFrame3, *pVideoFrame4;
    MyVideoFrame * pVideoFrame5, *pVideoFrame6, *pVideoFrame7, *pVideoFrame8;
    MyVideoFrame * pVideoFrame9, *pVideoFrame10, *pVideoFrame11, *pVideoFrame12;
    MyVideoFrame * pVideoFrame13, *pVideoFrame14, *pVideoFrame15, *pVideoFrame16;
#endif
}

@property (strong, nonatomic) IBOutlet UILabel *DecodeLabel;
@property (strong, nonatomic) IBOutlet UILabel *ShowImageLabel;
@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView3;
@property (strong, nonatomic) IBOutlet UIImageView *imageView4;
@property (strong, nonatomic) IBOutlet UIImageView *imageView2;
@property (nonatomic, strong) IBOutlet UILabel *label;
@property (nonatomic, strong) IBOutlet UIButton *playButton;

//#if OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_4
//@property (nonatomic, strong) VideoFrameExtractor *video1;
//@property (nonatomic, strong) VideoFrameExtractor *video2;
//@property (nonatomic, strong) VideoFrameExtractor *video3;
//@property (nonatomic, strong) VideoFrameExtractor *video4;
//#else
//@property (nonatomic, strong) VideoFrameExtractor *video1;
//@property (nonatomic, strong) VideoFrameExtractor *video2;
//@property (nonatomic, strong) VideoFrameExtractor *video3;
//@property (nonatomic, strong) VideoFrameExtractor *video4;
//@property (nonatomic, strong) VideoFrameExtractor *video5;
//@property (nonatomic, strong) VideoFrameExtractor *video6;
//@property (nonatomic, strong) VideoFrameExtractor *video7;
//@property (nonatomic, strong) VideoFrameExtractor *video8;
//@property (nonatomic, strong) VideoFrameExtractor *video9;
//@property (nonatomic, strong) VideoFrameExtractor *video10;
//@property (nonatomic, strong) VideoFrameExtractor *video11;
//@property (nonatomic, strong) VideoFrameExtractor *video12;
//@property (nonatomic, strong) VideoFrameExtractor *video13;
//@property (nonatomic, strong) VideoFrameExtractor *video14;
//@property (nonatomic, strong) VideoFrameExtractor *video15;
//@property (nonatomic, strong) VideoFrameExtractor *video16;
//#endif

@property (nonatomic) NSInteger FPS;

-(IBAction)playButtonAction:(id)sender;
- (IBAction)showTime:(id)sender;

@property (strong, nonatomic) VideoFrameExtractor *viewController;

@end

