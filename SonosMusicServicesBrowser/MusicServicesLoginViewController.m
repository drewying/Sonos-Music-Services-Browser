//
//  MusicServicesLoginViewController.m
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/17/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import "MusicServicesLoginViewController.h"
#import "SonosMusicServiceManager.h"
#import "SonosMusicService.h"

@interface MusicServicesLoginViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation MusicServicesLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)doLogin:(id)sender {
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self.musicService authenticateWithUsername:self.usernameTextField.text Password:self.passwordTextField.text completion:^(BOOL success, NSError *error){
        if (success){
            [[SonosMusicServiceManager sharedManager] addService:self.musicService];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![[SonosMusicServiceManager sharedManager] save]){
                    NSLog(@"Error Saving!");
                }

                [self.navigationController popToRootViewControllerAnimated:YES];
            });
        }
    }];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
