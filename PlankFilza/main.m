//  pwner
//
//  Created by Brandon Plank on 10/1/20.
//  Copyright © 2020 Brandon Plank. All rights reserved.
//

#include <stdio.h>
#include "main.h"
#include "support.h"
#include <UIKit/UIKit.h>
#include "fishhook.h"
#include "BypassAntiDebugging.h"
#include "cicuta_virosa.h"
#include "rootless.h"

@implementation PatchEntry

+ (void)load {
    disable_pt_deny_attach();
    disable_sysctl_debugger_checking();
        
    #if TESTS_BYPASS
    test_aniti_debugger();
    #endif
    [self showAlert];
}

void error_popup(NSString *messgae_popup, BOOL fatal){
    if(fatal){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"Fatal Error" message:messgae_popup preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                exit(0);
            }]];
            UIViewController * controller = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (controller.presentedViewController) {
                controller = controller.presentedViewController;
            }
            [controller presentViewController:alertController animated:YES completion:NULL];
        });
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"Error" message:messgae_popup preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:NULL]];
            UIViewController * controller = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (controller.presentedViewController) {
                controller = controller.presentedViewController;
            }
            [controller presentViewController:alertController animated:YES completion:NULL];
        });
    }
}

int start() {
    //Start exploitation to gain tfp0.
    Log(log_info, "==Plank Filza==");
    if(SYSTEM_VERSION_LESS_THAN(@"14.0") || SYSTEM_VERSION_GREATER_THAN(@"14.3")){
        Log(log_error, "Incorrect version");
        error_popup(@"Unsupported iOS version", true);
    } else {
        if(SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"14.3")){
            jailbreak(nil);
            
        }
    }
    return 0;
}

NSString *notice_json;
NSString *message;
BOOL can_show_msg = true;
BOOL error = false;
+ (void)showAlert
{
    NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[aSession dataTaskWithURL:[NSURL URLWithString:@"https://brandonplank.org/json/PlankFilza.json"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error != nil){
            Log(log_error, "we got an error...\n");
        }
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            if (data) {
                NSString *contentOfURL = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                //NSLog(@"%@", contentOfURL);
                notice_json = contentOfURL;
            } else {
                Log(log_error, "nil\n");
            }
        } else {
           Log(log_error, "200\n");
        }
    }] resume];
    message = @"Plank Filza by Brandon Plank(@_bplank)\n\nCoryright 2021 Brandon Plank";
    if(can_show_msg){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"Notice" message:message preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:NULL]];
            UIViewController * controller = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (controller.presentedViewController) {
                controller = controller.presentedViewController;
            }
            [controller presentViewController:alertController animated:YES completion:NULL];
        });
    } else {
        Log(log_info, "Not showing msg.\n");
    }
}
__attribute__((constructor))
static void initializer(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController* main =  UIApplication.sharedApplication.windows.firstObject.rootViewController;
        while (main.presentedViewController != NULL && ![main.presentedViewController isKindOfClass: [UIAlertController class]]) {
            main = main.presentedViewController;
        }
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Exploiting"
                                                                       message:@"This will take some time..." preferredStyle:UIAlertControllerStyleAlert];
        [main presentViewController:alert animated:YES completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                start();
                [alert dismissViewControllerAnimated:YES completion:^{ }];
            });
        }];
    });
    
}

@end
