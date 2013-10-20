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
}

@property (retain, nonatomic) IBOutlet UILabel *DecodeLabel;
@property (retain, nonatomic) IBOutlet UILabel *ShowImageLabel;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (retain, nonatomic) IBOutlet UIImageView *imageView3;
@property (retain, nonatomic) IBOutlet UIImageView *imageView4;
@property (retain, nonatomic) IBOutlet UIImageView *imageView2;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) VideoFrameExtractor *video1;
@property (nonatomic, retain) VideoFrameExtractor *video2;
@property (nonatomic, retain) VideoFrameExtractor *video3;
@property (nonatomic, retain) VideoFrameExtractor *video4;
-(IBAction)playButtonAction:(id)sender;
- (IBAction)showTime:(id)sender;

@property (strong, nonatomic) VideoFrameExtractor *viewController;

@end

