#import <Foundation/Foundation.h>

@interface BypassAntiDebugging : NSObject

void disable_pt_deny_attach(void);
void disable_sysctl_debugger_checking(void);
void test_aniti_debugger(void);

@end
