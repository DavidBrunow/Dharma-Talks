//
//  DHBAudioTableViewCell.h
//  Mission Dharma
//
//  Created by David Brunow on 10/27/13.
/*
 The MIT License (MIT)
 
 Copyright (c) 2014 David Brunow
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface DHBAudioTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UILabel *subLabel;
@property (weak, nonatomic) IBOutlet UIImageView *unplayedIndicator;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *nowPlayingLabel;

//@property (nonatomic, retain) UILabel *mainLabel;
//@property (nonatomic, retain) UILabel *subLabel;

//@property (nonatomic, retain) UILabel *nowPlayingLabel;
//@property (nonatomic, retain) UIButton *actionButton;
@property (nonatomic, retain) UIButton *playPauseButton;
//@property (nonatomic, retain) UIProgressView *progressView;
//@property (nonatomic, retain) UIProgressView *downloadProgressView;
@property (nonatomic, weak) UITableView *parentTableView;
//@property (nonatomic, retain) UIImageView *unplayedIndicator;

@end
