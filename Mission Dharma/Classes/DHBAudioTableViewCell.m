//
//  DHBAudioTableViewCell.m
//  Mission Dharma
//
//  Created by David Brunow on 10/27/13.
//  Copyright (c) 2013 David Brunow. All rights reserved.
//

#import "DHBAudioTableViewCell.h"
#import "DHBAppDelegate.h"

@implementation DHBAudioTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        [self.progressView setProgress:0.0];
        DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        [self.progressView setProgressTintColor:appDelegate.lightColor];
        self.downloadProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        [self.downloadProgressView setProgress:0.0];
        [self.downloadProgressView setProgressTintColor:appDelegate.darkColor];        
        
        self.mainLabel = [[UILabel alloc] init];
        [self.mainLabel setNumberOfLines:1];
        self.subLabel = [[UILabel alloc] init];
        self.nowPlayingLabel = [[UILabel alloc] init];
        [self.nowPlayingLabel setHidden:YES];
        self.actionButton = [[UIButton alloc] init];
        self.playPauseButton = [[UIButton alloc] init];

        self.unplayedIndicator = [[UIImageView alloc] init];
        [self.unplayedIndicator setHidden:YES];
        
        [self addSubview:self.progressView];
        [self addSubview:self.downloadProgressView];
        [self addSubview:self.mainLabel];
        [self addSubview:self.subLabel];
        [self addSubview:self.nowPlayingLabel];
        [self addSubview:self.actionButton];
        [self addSubview:self.playPauseButton];
        [self addSubview:self.unplayedIndicator];
    }
    return self;
}

- (void)layoutSubviews
{
    [self.progressView setFrame:CGRectMake(20, self.frame.size.height - 3, [[UIScreen mainScreen] bounds].size.width - 20, 20)];
    [self.downloadProgressView setFrame:CGRectMake(20, 0, [[UIScreen mainScreen] bounds].size.width - 20, 20)];
    
    [self.nowPlayingLabel setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 90, 12, 80, 26)];
    [self.actionButton setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 90, 12, 80, 26)];

    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    [self.actionButton setTitleColor:appDelegate.darkColor forState:UIControlStateNormal];
    self.actionButton.layer.cornerRadius = 4;
    self.actionButton.layer.borderWidth = 1;
    self.actionButton.layer.borderColor = [appDelegate darkColor].CGColor;
    [self.actionButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
    
    [self.actionButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:10.0]];
    [self.unplayedIndicator setFrame:CGRectMake(7, (self.frame.size.height / 2) - 2, 8, 8)];
    [self.unplayedIndicator setImage:[UIImage imageNamed:@"perry-color-circle"]];
    
    [self.playPauseButton setFrame:CGRectMake([[UIScreen mainScreen]bounds].size.width - 100, 10, 90, 45)];
    
    if([self.actionButton isHidden]) {
        [self.mainLabel setFrame:CGRectMake(20, 5, [[UIScreen mainScreen]bounds].size.width - 30, 25)];
        [self.subLabel setFrame:CGRectMake(20, 25, [[UIScreen mainScreen]bounds].size.width - 30, 20)];
    } else {
        [self.mainLabel setFrame:CGRectMake(20, 5, 200, 25)];
        [self.subLabel setFrame:CGRectMake(20, 25, 200, 20)];
    }
    
    [self.mainLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0]];
    [self.mainLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];

    [self.subLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0]];
    [self.subLabel setLineBreakMode:NSLineBreakByTruncatingTail];
    [self.subLabel setTextColor:[UIColor lightGrayColor]];
    [self.subLabel setTextColor:[UIColor darkGrayColor]];
    
    
    [self.nowPlayingLabel setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 90, 12, 80, 26)];
    [self.nowPlayingLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:12.0]];
    [self.nowPlayingLabel setTextColor:[UIColor whiteColor]];
    [self.nowPlayingLabel setTextAlignment:NSTextAlignmentCenter];
    
    [self.progressView setUserInteractionEnabled:NO];
    [self.downloadProgressView setUserInteractionEnabled:NO];
    [self.mainLabel setUserInteractionEnabled:NO];
    [self.subLabel setUserInteractionEnabled:NO];
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
