//
//  DHBAudioNavigationViewController.m
//  Mission Dharma
//
//  Created by David Brunow on 10/15/13.
//  Copyright (c) 2013 David Brunow. All rights reserved.
//

#import "DHBAudioNavigationViewController.h"
#import "DHBAppDelegate.h"

@interface DHBAudioNavigationViewController ()

@end

@implementation DHBAudioNavigationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    DHBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [self.navigationBar setBarTintColor:appDelegate.lightColor];
    //[self.navigationBar setBarTintColor:[UIColor whiteColor]];
    NSDictionary *titleTextAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil];
    
    [self.navigationBar setTitleTextAttributes:titleTextAttributes];
    //[self.navigationBar setTranslucent:YES];
    
    self.audioTableViewController = [[DHBAudioTableViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.audioTableViewController setTitle:@"Dharma Talks"];
    
    [self pushViewController:self.audioTableViewController animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
