//
//  MusicServicesOauthLoginViewController.m
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/20/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import "MusicServicesOauthLoginViewController.h"
#import "SonosMusicService.h"
#import "SonosMusicServiceManager.h"

@interface MusicServicesOauthLoginViewController () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, readonly) SonosMusicServiceManager *musicManager;
@end

@implementation MusicServicesOauthLoginViewController

-(SonosMusicServiceManager*)musicManager{
    return [SonosMusicServiceManager sharedManager];
}

- (IBAction)doneButton:(id)sender {
    [self.musicService authenticateWithDeviceLinkCode:self.deviceLinkCode completion:^(BOOL success, NSError *error){
        if (success){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.musicManager addService:self.musicService];
                [self.musicManager save];
                [self.navigationController popToRootViewControllerAnimated:YES];
            });
        }
        else{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[[UIAlertView alloc] initWithTitle:@"Error" message:@"We have an error" delegate:Nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            });
        }
    }];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.deviceLinkUrl]]];
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

@end
