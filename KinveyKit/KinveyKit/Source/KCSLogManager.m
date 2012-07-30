//
//  KCSLogManager.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/11/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSLogManager.h"

enum {
    kKCSDebugChannelID = 1,
    kKCSTraceChannelID = 2,
    kKCSWarningChannelID = 3,
    kKCSErrorChannelID = 4,
    kKCSNetworkChannelID = 5,
    kKCSForcedChannelID = 6
};

@interface KCSLogChannel : NSObject

+ (KCSLogChannel *)channelForKey:(NSString *)key;
+ (NSDictionary *)channels;

- (id)initWithDisplayString: (NSString *)displayString channelID:(NSInteger)channelID;
@property (readonly, nonatomic) NSString *displayString;
@property (readonly, nonatomic) NSInteger channelID;

@end

@implementation KCSLogChannel

@synthesize displayString = _displayString;
@synthesize channelID = _channelID;

- (id)initWithDisplayString:(NSString *)displayString channelID:(NSInteger)channelID
{
    self = [super init];
    if (self){
        _displayString = [displayString retain];
        _channelID = channelID;
    }
    return self;
}

- (void)dealloc
{
    [_displayString release];
    [super dealloc];
}

- (BOOL)isEqual:(id)object
{
    return ([self.displayString isEqualToString:[(KCSLogChannel *)object displayString]] &&
            self.channelID == [(KCSLogChannel *)object channelID]);

}

+ (NSDictionary *)channels
{
    static NSDictionary *channels = nil;
    
    
    if (channels == nil){
        channels = [[NSDictionary dictionaryWithObjectsAndKeys:
                                     [[[KCSLogChannel alloc] initWithDisplayString:@"[Network]" channelID:kKCSNetworkChannelID] autorelease], @"kNetworkChannel",
                                     [[[KCSLogChannel alloc] initWithDisplayString:@"[DEBUG]" channelID:kKCSDebugChannelID] autorelease], @"kDebugChannel",
                                     [[[KCSLogChannel alloc] initWithDisplayString:@"[Trace]" channelID:kKCSTraceChannelID] autorelease], @"kTraceChannel",
                                     [[[KCSLogChannel alloc] initWithDisplayString:@"[WARN]" channelID:kKCSWarningChannelID]  autorelease], @"kWarningChannel",
                                     [[[KCSLogChannel alloc] initWithDisplayString:@"[ERROR]" channelID:kKCSErrorChannelID] autorelease], @"kErrorChannel",
                                     [[[KCSLogChannel alloc] initWithDisplayString:@"[ERROR]" channelID:kKCSForcedChannelID] autorelease], @"kForcedChannel",
                                     nil] retain];
    }
    
    return channels;
}

+ (KCSLogChannel *)channelForKey:(NSString *)key
{
    return [[KCSLogChannel channels] objectForKey:key];
}

@end

@interface KCSLogManager ()
@property (retain, nonatomic) NSDictionary *loggingState;
@end

@implementation KCSLogManager

@synthesize loggingState = _loggingState;

- (id)init
{
    self = [super init];
    if (self){}
    return self;
}

+ (KCSLogManager *)sharedLogManager
{
    static KCSLogManager *sKCSLogManager;
    // This can be called on any thread, so we synchronise.  We only do this in 
    // the sKCSLogManager case because, once sKCSLogManager goes non-nil, it can 
    // never go nil again.
    
    if (sKCSLogManager == nil) {
        @synchronized (self) {
            sKCSLogManager = [[KCSLogManager alloc] init];
            assert(sKCSLogManager != nil);
        }
        
        // Need to seed logging here, all off
        [sKCSLogManager configureLoggingWithNetworkEnabled:NO
                                              debugEnabled:NO
                                              traceEnabled:NO
                                            warningEnabled:NO
                                              errorEnabled:NO];
    }
    
    return sKCSLogManager;
}


+ (KCSLogChannel *)kNetworkChannel
{
    return [KCSLogChannel channelForKey:@"kNetworkChannel"];
}

+ (KCSLogChannel *)kDebugChannel
{
    return [KCSLogChannel channelForKey:@"kDebugChannel"];
}

+ (KCSLogChannel *)kTraceChannel
{
    return [KCSLogChannel channelForKey:@"kTraceChannel"];
}

+ (KCSLogChannel *)kWarningChannel
{
    return [KCSLogChannel channelForKey:@"kWarningChannel"];
}

+ (KCSLogChannel *)kErrorChannel
{
    return [KCSLogChannel channelForKey:@"kErrorChannel"];
}

+ (KCSLogChannel *)kForcedChannel
{
    return [KCSLogChannel channelForKey:@"kForcedChannel"];
}


- (void)logChannel: (KCSLogChannel *)channel file:(char *)sourceFile lineNumber: (int)lineNumber withFormat:(NSString *)format, ...
{
    BOOL channelIsEnabled = [(NSNumber *)[self.loggingState objectForKey:[NSNumber numberWithInt:channel.channelID]] boolValue];
    
    // If the channel is not enabled we don't do anything here, ALWAYS log the forced channel
    if (channelIsEnabled || channel.channelID == kKCSForcedChannelID){
        va_list ap;
        NSString *print,*file;
        va_start(ap,format);
        file=[[NSString alloc] initWithBytes:sourceFile 
                                      length:strlen(sourceFile) 
                                    encoding:NSUTF8StringEncoding];
        print=[[NSString alloc] initWithFormat:format arguments:ap];
        va_end(ap);
        //NSLog handles synchronization issues
        NSLog(@"%s:%d %@ %@",[[file lastPathComponent] UTF8String],
              lineNumber, channel.displayString,print);
        [print release];
        [file release];
    }
}

- (void)configureLoggingWithNetworkEnabled:(BOOL)networkIsEnabled 
                              debugEnabled:(BOOL)debugIsEnabled 
                              traceEnabled:(BOOL)traceIsEnabled
                            warningEnabled:(BOOL)warningIsEnabled
                              errorEnabled:(BOOL)errorIsEnabled
{
    NSNumber *netChan = [NSNumber numberWithInt:[[KCSLogManager kNetworkChannel] channelID]];
    NSNumber *dbgChan = [NSNumber numberWithInt:[[KCSLogManager kDebugChannel] channelID]];
    NSNumber *trcChan = [NSNumber numberWithInt:[[KCSLogManager kTraceChannel] channelID]];
    NSNumber *wrnChan = [NSNumber numberWithInt:[[KCSLogManager kWarningChannel] channelID]];
    NSNumber *errChan = [NSNumber numberWithInt:[[KCSLogManager kErrorChannel] channelID]];
    
    NSDictionary *configuredStates = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithBool:networkIsEnabled], netChan,
                                      [NSNumber numberWithBool:debugIsEnabled], dbgChan,
                                      [NSNumber numberWithBool:traceIsEnabled], trcChan,
                                      [NSNumber numberWithBool:warningIsEnabled], wrnChan,
                                      [NSNumber numberWithBool:errorIsEnabled], errChan,
                                      nil];
    
    self.loggingState = configuredStates;
}




@end
