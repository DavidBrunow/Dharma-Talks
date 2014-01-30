//
//  DHBAudioTableViewCell.h
//  Mission Dharma
//
//  Created by David Brunow on 10/27/13.
//  Copyright (c) 2013 David Brunow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface DHBAudioTableViewCell : UITableViewCell

@property (nonatomic, retain) UILabel *mainLabel;
@property (nonatomic, retain) UILabel *subLabel;
@property (nonatomic, retain) UILabel *nowPlayingLabel;
@property (nonatomic, retain) UIButton *actionButton;
@property (nonatomic, retain) UIButton *playPauseButton;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, retain) UIProgressView *downloadProgressView;
@property (nonatomic, weak) UITableView *parentTableView;
@property (nonatomic, retain) UIImageView *unplayedIndicator;

@end
