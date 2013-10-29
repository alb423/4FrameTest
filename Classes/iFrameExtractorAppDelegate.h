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
	VideoFrameExtractor *video1;
    VideoFrameExtractor *video2;
    VideoFrameExtractor *video3;
    VideoFrameExtractor *video4;
	float lastFrameTime;
    
    MyGLView *myGLView;
    //VSaaSVideoDecoder * videoDecoder;
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
@property (nonatomic, strong) VideoFrameExtractor *video1;
@property (nonatomic, strong) VideoFrameExtractor *video2;
@property (nonatomic, strong) VideoFrameExtractor *video3;
@property (nonatomic, strong) VideoFrameExtractor *video4;

@property (nonatomic) NSInteger FPS;

-(IBAction)playButtonAction:(id)sender;
- (IBAction)showTime:(id)sender;

@property (strong, nonatomic) VideoFrameExtractor *viewController;

@end

