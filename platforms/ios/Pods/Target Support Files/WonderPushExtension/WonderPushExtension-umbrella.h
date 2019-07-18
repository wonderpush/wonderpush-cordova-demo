#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NotificationServiceExtension.h"
#import "WonderPushExtension.h"
#import "WPNotificationServiceExtension.h"
#import "WPLog.h"

FOUNDATION_EXPORT double WonderPushExtensionVersionNumber;
FOUNDATION_EXPORT const unsigned char WonderPushExtensionVersionString[];

