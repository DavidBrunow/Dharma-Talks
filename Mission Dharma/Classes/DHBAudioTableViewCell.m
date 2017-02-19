//
//  DHBAudioTableViewCell.m
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

@class AppDelegate;

#import "DHBAudioTableViewCell.h"
#import "Mission_Dharma-Swift.h"

@implementation DHBAudioTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        // Initialization code
        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        [self.progressView setProgress:0.0];

        [self.progressView setProgressTintColor:AppDelegate.lightColor];
        self.downloadProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        [self.downloadProgressView setProgress:0.0];
        [self.downloadProgressView setProgressTintColor:AppDelegate.darkColor];
        
        self.nowPlayingLabel = [[UILabel alloc] init];
        [self.nowPlayingLabel setHidden:YES];
        self.actionButton = [[UIButton alloc] init];
        self.playPauseButton = [[UIButton alloc] init];
        
        [self addSubview:self.progressView];
        [self addSubview:self.downloadProgressView];
        
        [self addSubview:self.nowPlayingLabel];
        [self addSubview:self.actionButton];
        [self addSubview:self.playPauseButton];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.nowPlayingLabel setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 90, 12, 80, 26)];
    
    [self.playPauseButton setFrame:CGRectMake([[UIScreen mainScreen]bounds].size.width - 100, 10, 90, 45)];
    
    
    [self.progressView setUserInteractionEnabled:NO];
    [self.downloadProgressView setUserInteractionEnabled:NO];
    
    [self.nowPlayingLabel setUserInteractionEnabled:NO];
    [self.actionButton setUserInteractionEnabled:YES];
    [self.playPauseButton setUserInteractionEnabled:NO];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"downloadInProgress"]) {
        float newValue = [[change valueForKey:NSKeyValueChangeNewKey] floatValue];
        [self.downloadProgressView setProgress:newValue animated:NO];
        [self.actionButton setTitle:@"DOWNLOADING" forState:UIControlStateNormal];
        [self.actionButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        
        if(newValue == 1.0) {
            [self.actionButton setTitle:@"" forState:UIControlStateNormal];
            [self.actionButton setHidden:YES];
            [self.downloadProgressView setHidden:YES];
            [self.progressView setHidden:NO];
            
            [self layoutSubviews];
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
