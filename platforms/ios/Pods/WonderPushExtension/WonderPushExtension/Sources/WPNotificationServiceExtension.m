/*
 Copyright 2017 WonderPush
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "WPNotificationServiceExtension.h"

#import "WPLog.h"

#import <objc/runtime.h>


/**
 Key of the WonderPush content in a push notification
 */
#define WP_PUSH_NOTIFICATION_KEY @"_wp"

@interface WonderPushFileDownloader: NSObject
@property (nonatomic, strong) NSURL *downloadURL;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSURLSessionDownloadTask *task;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
- (instancetype) initWithDownloadURL: (NSURL*) downloadURL fileURL: (NSURL*) fileURL;
- (void) download:(NSError **)error;
@end


@implementation WPNotificationServiceExtension

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    // Forward the call to the WonderPush NotificationServiceExtension SDK
    if (![[self class] serviceExtension:self didReceiveNotificationRequest:request withContentHandler:contentHandler]) {
        // The notification was not for the WonderPush SDK consumption, handle it ourself
        contentHandler(request.content);
    }
}

- (void)serviceExtensionTimeWillExpire {
    // Forward the call to the WonderPush NotificationServiceExtension SDK
    [[self class] serviceExtensionTimeWillExpire:self];
    // If the notification was not for the WonderPush SDK consumption,
    // we would have handled it ourself, and we would never enter this function.
}

typedef void (^ContentHandler)(UNNotificationContent *contentToDeliver);

const char * const WPNOTIFICATIONSERVICEEXTENSION_CONTENTHANDLER_ASSOCIATION_KEY = "com.wonderpush.sdk.NotificationServiceExtension.contentHandler";
const char * const WPNOTIFICATIONSERVICEEXTENSION_CONTENT_ASSOCIATION_KEY = "com.wonderpush.sdk.NotificationServiceExtension.content";


# pragma mark - Service extension methods

+ (BOOL)serviceExtension:(UNNotificationServiceExtension *)extension didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    @try {
        WPLog(@"didReceiveNotificationRequest:%@", request);
        WPLog(@"                     userInfo:%@", request.content.userInfo);
        
        UNMutableNotificationContent *content = [request.content mutableCopy];
        [self setContentHandler:contentHandler forExtension:extension];
        [self setContent:content forExtension:extension];
        
        if (![self isNotificationForWonderPush:content.userInfo]) {
            WPLog(@"Notification not for WonderPush");
            return NO;
        }
        
        id wpData = [content.userInfo valueForKey:WP_PUSH_NOTIFICATION_KEY];
        
        NSArray *attachments = [wpData valueForKey:@"attachments"];
        if (attachments && [attachments isKindOfClass:[NSArray class]] && attachments.count > 0) {
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSURL *documentsDirectoryURL = [NSURL fileURLWithPath:documentsDirectory];
            NSMutableArray *contentAttachments = [[NSMutableArray alloc] initWithArray:content.attachments];
            int index = -1;
            for (NSDictionary *attachment in attachments) {
                @try {
                    ++index;
                    if (![attachment isKindOfClass:[NSDictionary class]]) continue;
                    NSString *attachmentUrl = [attachment valueForKey:@"url"];
                    if (![attachmentUrl isKindOfClass:[NSString class]]) continue;
                    NSURL *attachmentURL = [NSURL URLWithString:attachmentUrl];
                    if (!attachmentURL) continue;
                    
                    NSMutableDictionary *attachmentOptions = [[NSMutableDictionary alloc] initWithDictionary:([[attachment valueForKey:@"options"] isKindOfClass:[NSDictionary class]] ? [attachment valueForKey:@"options"] : @{})];
                    NSString *type = [attachment valueForKey:@"type"];
                    if ([type isKindOfClass:[NSString class]] && !attachmentOptions[UNNotificationAttachmentOptionsTypeHintKey]) {
                        NSString *utType = [self getAttachmentTypehintFrom:type];
                        if (utType) {
                            attachmentOptions[UNNotificationAttachmentOptionsTypeHintKey] = utType;
                        }
                    }
                    NSString *attachmentId = [[attachment valueForKey:@"id"] isKindOfClass:[NSString class]] ? [attachment valueForKey:@"id"] : [NSString stringWithFormat:@"%d", index];
                    NSError *error = nil;
                    WPLog(@"downloading %@", attachmentURL);
                    NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@.%@", attachmentId, attachmentURL.pathExtension ?: @""] relativeToURL:documentsDirectoryURL];
                    WonderPushFileDownloader *downloader = [[WonderPushFileDownloader alloc] initWithDownloadURL:attachmentURL fileURL:fileURL];
                    [downloader download:&error];
                    if (error != nil) {
                        WPLog(@"Failed download attachment: %@", error);
                        continue;
                    }
                    @try {
                        UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:attachmentId
                                                                                                              URL:fileURL
                                                                                                          options:attachmentOptions
                                                                                                            error:&error];
                        if (error != nil) {
                            WPLog(@"Failed to create attachment: %@", error);
                            continue;
                        }
                        if (attachment) {
                            WPLog(@"Adding attachment: %@", attachment);
                            [contentAttachments addObject:attachment];
                            content.attachments = contentAttachments;
                        }
                    } @catch (NSException *exception) {
                        WPLog(@"WonderPush/NotificationServiceExtension didReceiveNotificationRequest:withContentHandler: exception when adding attachment: %@", exception);
                    }
                } @catch (NSException *exception) {
                    WPLog(@"WonderPush/NotificationServiceExtension didReceiveNotificationRequest:withContentHandler: exception when processing %dth attachment: %@", index, exception);
                }
            }
        }
        
        WPLog(@"Final content: %@", content);
        contentHandler(content);
        return YES;
    } @catch (NSException *exception) {
        WPLog(@"WonderPush/NotificationServiceExtension didReceiveNotificationRequest:withContentHandler: exception: %@", exception);
        return NO;
    }
}

+ (BOOL)serviceExtensionTimeWillExpire:(UNNotificationServiceExtension *)extension {
    @try {
        WPLog(@"serviceExtensionTimeWillExpire");
        UNMutableNotificationContent *content = [self getContentForExtension:extension];
        ContentHandler contentHandler = [self getContentHandlerForExtension:extension];
        
        if (!content || !contentHandler || ![self isNotificationForWonderPush:content.userInfo]) {
            return NO;
        }
        
        WPLog(@"Final content: %@", content);
        contentHandler(content);
        return YES;
    } @catch (NSException *exception) {
        WPLog(@"WonderPush/NotificationServiceExtension serviceExtensionTimeWillExpire exception: %@", exception);
        return NO;
    }
}


#pragma mark - Associated objects

+ (ContentHandler)getContentHandlerForExtension:(UNNotificationServiceExtension *)extension {
    return objc_getAssociatedObject(extension, WPNOTIFICATIONSERVICEEXTENSION_CONTENTHANDLER_ASSOCIATION_KEY);
}

+ (void)setContentHandler:(ContentHandler)contentHandler forExtension:(UNNotificationServiceExtension *)extension {
    objc_setAssociatedObject(extension, WPNOTIFICATIONSERVICEEXTENSION_CONTENTHANDLER_ASSOCIATION_KEY, contentHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (UNMutableNotificationContent *)getContentForExtension:(UNNotificationServiceExtension *)extension {
    return objc_getAssociatedObject(extension, WPNOTIFICATIONSERVICEEXTENSION_CONTENT_ASSOCIATION_KEY);
}

+ (void)setContent:(UNMutableNotificationContent *)content forExtension:(UNNotificationServiceExtension *)extension {
    objc_setAssociatedObject(extension, WPNOTIFICATIONSERVICEEXTENSION_CONTENT_ASSOCIATION_KEY, content, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


#pragma mark - Attachment type

static const NSString *UTTypeAudioInterchangeFileFormat = @"public.aiff-audio";
static const NSString *UTTypeWaveformAudio = @"com.microsoft.waveform-audio";
static const NSString *UTTypeMP3 = @"public.mp3";
static const NSString *UTTypeMPEG4Audio = @"public.mpeg-4-audio";
static const NSString *UTTypeJPEG = @"public.jpeg";
static const NSString *UTTypeGIF = @"com.compuserve.gif";
static const NSString *UTTypePNG = @"public.png";
static const NSString *UTTypeMPEG = @"public.mpeg";
static const NSString *UTTypeMPEG2Video = @"public.mpeg-2-video";
static const NSString *UTTypeMPEG4 = @"public.mpeg-4";
static const NSString *UTTypeAVIMovie = @"public.avi";

+ (NSString * _Nullable)getAttachmentTypehintFrom:(NSString *)extensionOrMimeTypeOrTypeUTType {
    NSDictionary *mapping = @{
                              @"png": UTTypePNG,
                              @"jpg": UTTypeJPEG,
                              @"jpeg": UTTypeJPEG,
                              @"gif": UTTypeGIF,
                              @"image/png": UTTypePNG,
                              @"image/x-png": UTTypePNG,
                              @"image/jpeg": UTTypeJPEG,
                              @"image/gif": UTTypeGIF,
                              @"wav": UTTypeWaveformAudio,
                              @"wave": UTTypeWaveformAudio,
                              @"aiff": UTTypeAudioInterchangeFileFormat,
                              @"mp3": UTTypeMP3,
                              @"m4a": UTTypeMPEG4Audio,
                              @"mp4a": UTTypeMPEG4Audio,
                              @"audio/wav": UTTypeWaveformAudio,
                              @"audio/x-wav": UTTypeWaveformAudio,
                              @"audio/aiff": UTTypeAudioInterchangeFileFormat,
                              @"audio/x-aiff": UTTypeAudioInterchangeFileFormat,
                              @"audio/mpeg": UTTypeMP3,
                              @"audio/mp3": UTTypeMP3,
                              @"audio/mpeg3": UTTypeMP3,
                              @"audio/mp4": UTTypeMPEG4Audio,
                              @"mpg": UTTypeMPEG,
                              @"mpeg": UTTypeMPEG,
                              @"mp2": UTTypeMPEG2Video,
                              @"m2v": UTTypeMPEG2Video,
                              @"mp4": UTTypeMPEG4,
                              @"avi": UTTypeAVIMovie,
                              @"video/mpeg": UTTypeMPEG,
                              @"video/x-mpeg1": UTTypeMPEG,
                              @"video/mpeg2": UTTypeMPEG2Video,
                              @"video/x-mpeg2": UTTypeMPEG2Video,
                              @"video/mp4": UTTypeMPEG4,
                              @"video/mpeg4": UTTypeMPEG4,
                              @"video/avi": UTTypeAVIMovie,
                              UTTypeAudioInterchangeFileFormat: UTTypeAudioInterchangeFileFormat,
                              UTTypeWaveformAudio: UTTypeWaveformAudio,
                              UTTypeMP3: UTTypeMP3,
                              UTTypeMPEG4Audio: UTTypeMPEG4Audio,
                              UTTypeJPEG: UTTypeJPEG,
                              UTTypeGIF: UTTypeGIF,
                              UTTypePNG: UTTypePNG,
                              UTTypeMPEG: UTTypeMPEG,
                              UTTypeMPEG2Video: UTTypeMPEG2Video,
                              UTTypeMPEG4: UTTypeMPEG4,
                              UTTypeAVIMovie: UTTypeAVIMovie,
                              };
    return [mapping objectForKey:extensionOrMimeTypeOrTypeUTType];
}

#pragma mark - WonderPush SDK stuff

+ (BOOL)isNotificationForWonderPush:(NSDictionary *)userInfo{
    if ([userInfo isKindOfClass:[NSDictionary class]]) {
        NSDictionary *wonderpushData = [[userInfo valueForKey:WP_PUSH_NOTIFICATION_KEY] isKindOfClass:[NSDictionary class]] ? [userInfo valueForKey:WP_PUSH_NOTIFICATION_KEY] : nil;
        return !!wonderpushData;
    }
    return NO;
}

@end


@implementation WonderPushFileDownloader

- (instancetype) initWithDownloadURL: (NSURL*) downloadURL fileURL: (NSURL*) fileURL {
    self = [super init];
    self.fileURL = fileURL;
    self.downloadURL = downloadURL;
    self.error = nil;
    self.task = [[NSURLSession sharedSession] downloadTaskWithURL:downloadURL completionHandler:^(NSURL *downloadedFileURL, NSURLResponse *response, NSError *error) {
        self.error = error;
        self.response = response;
        if (!error && downloadedFileURL) {
            NSError *moveError = nil;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtURL:fileURL error:nil];
            [fileManager moveItemAtURL:downloadedFileURL toURL:fileURL error:&moveError];
            self.error = moveError;
        }
        dispatch_semaphore_signal(self.semaphore);
    }];
    return self;
}
- (void) download:(NSError *__autoreleasing *)error {
    self.semaphore = dispatch_semaphore_create(0);
    [self.task resume];
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    *error = self.error;
}

@end
