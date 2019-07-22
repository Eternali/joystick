#import "JoystickPlugin.h"
#import <joystick/joystick-Swift.h>

@implementation JoystickPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftJoystickPlugin registerWithRegistrar:registrar];
}
@end
