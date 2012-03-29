//
//  KCSBlobService.m
//  SampleApp
//
//  Created by Brian Wilson on 11/9/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyHTTPStatusCodes.h"
#import "KCSBlobService.h"
#import "KCSClient.h"
#import "SBJson.h"
#import "KCSRESTRequest.h"
#import "KCSConnectionResponse.h"
#import "KCSErrorUtilities.h"
#import "KinveyErrorCodes.h"

@implementation KCSResourceResponse

@synthesize localFileName=_localFileName;
@synthesize resourceId=_resourceId;
@synthesize resource=_resource; // Set to nil on upload
@synthesize length=_length;
@synthesize streamingURL=_streamingURL;

+ (KCSResourceResponse *)responseWithFileName:(NSString *)localFile withResourceId:(NSString *)resourceId withStreamingURL:(NSString *)streamingURL withData:(NSData *)resource withLength:(NSInteger)length
{
    KCSResourceResponse *response = [[[KCSResourceResponse alloc] init] autorelease];
    response.localFileName = localFile;
    response.resourceId = resourceId;
    response.resource = resource;
    response.length = length;
    response.streamingURL = streamingURL;
    
    return response;
}

- (void)dealloc
{
    [_localFileName release];
    [_resourceId release];
    [_resource release];
    [_streamingURL release];
    [super dealloc];
}


@end

#pragma mark Blob Service

@implementation KCSResourceService
+ (void)downloadResource: (NSString *)resourceId withResourceDelegate: (id<KCSResourceDelegate>)delegate;
{
    NSString *resource = [[[KCSClient sharedClient] resourceBaseURL] stringByAppendingFormat:@"download-loc/%@", resourceId];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            KCS_SBJsonParser *parser = [[[KCS_SBJsonParser alloc] init] autorelease];
            NSString *failureJSON = [[parser objectWithData:response.responseData] description];
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Resource download failed."
                                                                               withFailureReason:[NSString stringWithFormat:@"JSON Error: %@", failureJSON]
                                                                          withRecoverySuggestion:@"Retry request based on information in JSON Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSResourceErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            
            [delegate resourceServiceDidFailWithError:error];
        } else {
            [delegate resourceServiceDidCompleteWithResult:[KCSResourceResponse responseWithFileName:nil withResourceId:resourceId withStreamingURL:nil withData:response.responseData withLength:[response.responseData length]]];
        }
    };
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate resourceServiceDidFailWithError:error];
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *connection){};
    
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

+ (void)downloadResource:(NSString *)resourceId toFile:(NSString *)filename withResourceDelegate:(id<KCSResourceDelegate>)delegate
{
    NSString *resource = [[[KCSClient sharedClient] resourceBaseURL] stringByAppendingFormat:@"download-loc/%@", resourceId];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            KCS_SBJsonParser *parser = [[[KCS_SBJsonParser alloc] init] autorelease];

            NSString *failureJSON = [[parser objectWithData:response.responseData] description];
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Resource download to file failed."
                                                                               withFailureReason:[NSString stringWithFormat:@"JSON Error: %@", failureJSON]
                                                                          withRecoverySuggestion:@"Retry request based on information in JSON Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSResourceErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            
            [delegate resourceServiceDidFailWithError:error];
        } else {
            // We have a valid NSData object, right now this is the only way I know to complete this request...
            NSError *fileError = nil;
            BOOL didWriteSuccessfully = [response.responseData writeToFile:filename
                                                                   options:NSDataWritingAtomic
                                                                     error:&fileError];
            
            if (didWriteSuccessfully){
                [delegate resourceServiceDidCompleteWithResult:[KCSResourceResponse responseWithFileName:filename 
                                                                                          withResourceId:resourceId 
                                                                                        withStreamingURL:nil
                                                                                                withData:nil
                                                                                              withLength:[response.responseData length]]];
            } else {
                // We failed to write the file
                [delegate resourceServiceDidFailWithError:fileError];
            }
        }
    };
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate resourceServiceDidFailWithError:error];
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *connection){};
    
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

+ (void)saveLocalResource:(NSString *)filename withDelegate:(id<KCSResourceDelegate>)delegate
{
    [KCSResourceService saveLocalResource:filename toResource:[filename lastPathComponent] withDelegate:delegate];
}

+ (void)saveLocalResourceWithURL:(NSURL *)URL toResource:(NSString *)resourceId withDelegate:(id<KCSResourceDelegate>)delegate
{
    // Not sure what the best read options to use here are, so not providing any.  Hopefully the defaults are ok.
    NSData *data = [NSData dataWithContentsOfURL:URL];
    if (data){
        // We read in the data, we can upload it.
        [KCSResourceService saveData:data toResource:resourceId withDelegate:delegate];
    } else {
        // We had an issue..., we didn't upload, so call the failure method of the delegate
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Updload failed"
                                                                           withFailureReason:@"Unable to determine why, URL didn't load"
                                                                      withRecoverySuggestion:@"Unknown"
                                                                         withRecoveryOptions:nil];
        NSError *err = [NSError errorWithDomain:KCSResourceErrorDomain code:KCSFileError userInfo:userInfo];
        [delegate resourceServiceDidFailWithError:err];
    }

}

+ (void)saveLocalResourceWithURL:(NSURL *)URL withDelegate:(id<KCSResourceDelegate>)delegate
{
    [KCSResourceService saveLocalResourceWithURL:URL toResource:[URL lastPathComponent] withDelegate:delegate];
}

+ (void)getStreamingURLForResource:(NSString *)resourceId withResourceDelegate:(id<KCSResourceDelegate>)delegate
{
    NSString *resource = [[[KCSClient sharedClient] resourceBaseURL] stringByAppendingFormat:@"download-loc/%@", resourceId];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        // This needs to be REDIRECT, otherwise something is messed up!
        if (response.responseCode != KCS_HTTP_STATUS_REDIRECT){
            KCS_SBJsonParser *parser = [[[KCS_SBJsonParser alloc] init] autorelease];
            NSString *failureJSON = [[parser objectWithData:response.responseData] description];
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Get streaming URL failed."
                                                                               withFailureReason:[NSString stringWithFormat:@"JSON Error: %@", failureJSON]
                                                                          withRecoverySuggestion:@"Retry request based on information in JSON Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSResourceErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            
            [delegate resourceServiceDidFailWithError:error];
        } else {
            NSString *URL = [[response.responseHeaders objectForKey:@"Location"] retain];
            
            if (!URL){
                NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"URL for streaming resource not available."
                                                                                   withFailureReason:@"No 'Location' header found in HTTP redirect."
                                                                              withRecoverySuggestion:@"No client recovery available, contact Kinvey Support."
                                                                                 withRecoveryOptions:nil];
                NSError *error = [NSError errorWithDomain:KCSResourceErrorDomain
                                                     code:KCSUnexpectedResultFromServerError
                                                 userInfo:userInfo];
                
                [delegate resourceServiceDidFailWithError:error];
            } else {
                // NB: The delegate must take ownership of this resource!
                [delegate resourceServiceDidCompleteWithResult:[KCSResourceResponse responseWithFileName:nil withResourceId:resourceId withStreamingURL:URL withData:nil withLength:0]];
                [URL release];
            }
        }
    };
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate resourceServiceDidFailWithError:error];
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *connection){};
    
    request.followRedirects = NO;
    
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];

}

+ (void)saveLocalResource:(NSString *)filename toResource:(NSString *)resourceId withDelegate:(id<KCSResourceDelegate>)delegate
{
    NSError *fileOpError = nil;
    // Not sure what the best read options to use here are, so not providing any.  Hopefully the defaults are ok.
    NSData *data = [NSData dataWithContentsOfFile:filename options:0 error:&fileOpError];
    if (data){
        // We read in the data, we can upload it.
        [KCSResourceService saveData:data toResource:resourceId withDelegate:delegate];
    } else {
        // We had an issue..., we didn't upload, so call the failure method of the delegate
        [delegate resourceServiceDidFailWithError:fileOpError];
    }
}

+ (void)saveData:(NSData *)data toResource:(NSString *)resourceId withDelegate:(id<KCSResourceDelegate>)delegate
{
    NSString *resource = [[[KCSClient sharedClient] resourceBaseURL] stringByAppendingFormat:@"upload-loc/%@", resourceId];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];

    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate resourceServiceDidFailWithError:error];
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *connection){};
    
    KCSConnectionCompletionBlock userCallback = ^(KCSConnectionResponse *response){
        if (response.responseCode != KCS_HTTP_STATUS_CREATED){
            NSString *xmlData = [[[NSString alloc] initWithData:response.responseData encoding:NSUTF8StringEncoding] autorelease];
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Saving data to the resource service failed."
                                                                               withFailureReason:[NSString stringWithFormat:@"XML Error: %@", xmlData]
                                                                          withRecoverySuggestion:@"Retry request based on information in XML Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSResourceErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            
            [delegate resourceServiceDidFailWithError:error];

        } else {
            // I feel like we should have a length here, but I might not be saving that response...
            [delegate resourceServiceDidCompleteWithResult:[KCSResourceResponse responseWithFileName:nil withResourceId:resourceId withStreamingURL:nil withData:nil withLength:0]];
        }
    };
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        KCS_SBJsonParser *parser = [[[KCS_SBJsonParser alloc] init] autorelease];
        NSDictionary *jsonData = [parser objectWithData:response.responseData];
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Getting the resource service save location failed."
                                                                               withFailureReason:[NSString stringWithFormat:@"JSON Error: %@", jsonData]
                                                                          withRecoverySuggestion:@"Retry request based on information in JSON Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSResourceErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            
            [delegate resourceServiceDidFailWithError:error];
        } else {
            NSString *newResource = [jsonData valueForKey:@"URI"];
            KCSRESTRequest *newRequest = [KCSRESTRequest requestForResource:newResource usingMethod:kPutRESTMethod];
            [newRequest addBody:data];
            [newRequest setContentType:KCS_DATA_TYPE];
            [[newRequest withCompletionAction:userCallback failureAction:fBlock progressAction:pBlock] start];
        }
    };

    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];

}

+ (void)deleteResource:(NSString *)resourceId withDelegate:(id<KCSResourceDelegate>)delegate
{
    NSString *resource = [[[KCSClient sharedClient] resourceBaseURL] stringByAppendingFormat:@"remove-loc/%@", resourceId];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];

    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate resourceServiceDidFailWithError:error];
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *connection){};
    
    KCSConnectionCompletionBlock userCallback = ^(KCSConnectionResponse *response){
        if (response.responseCode != KCS_HTTP_STATUS_ACCEPTED){
            NSString *xmlData = [[[NSString alloc] initWithData:response.responseData encoding:NSUTF8StringEncoding] autorelease];
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Deleting resource from resource service failed."
                                                                               withFailureReason:[NSString stringWithFormat:@"XML Error: %@", xmlData]
                                                                          withRecoverySuggestion:@"Retry request based on information in XML Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSResourceErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            
            [delegate resourceServiceDidFailWithError:error];

        } else {
            // I feel like we should have a length here, but I might not be saving that response...
            [delegate resourceServiceDidCompleteWithResult:[KCSResourceResponse responseWithFileName:nil withResourceId:nil withStreamingURL:nil withData:nil withLength:0]];
        }

    };
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        KCS_SBJsonParser *parser = [[[KCS_SBJsonParser alloc] init] autorelease];
        NSDictionary *jsonData = [parser objectWithData:response.responseData];
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Getting delete location failed."
                                                                               withFailureReason:[NSString stringWithFormat:@"JSON Error: %@", jsonData]
                                                                          withRecoverySuggestion:@"Retry request based on information in JSON Error"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSResourceErrorDomain
                                                 code:[response responseCode]
                                             userInfo:userInfo];
            
            [delegate resourceServiceDidFailWithError:error];
        } else {
            NSString *newResource = [jsonData valueForKey:@"URI"];
            KCSRESTRequest *newRequest = [KCSRESTRequest requestForResource:newResource usingMethod:kDeleteRESTMethod];
            [[newRequest withCompletionAction:userCallback failureAction:fBlock progressAction:pBlock] start];
        }
    };

    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}


@end
