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
#import "JSONKit.h"
#import "KCSRESTRequest.h"
#import "KCSConnectionResponse.h"

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
    self.localFileName = nil;

    [_resourceId release];
    self.resourceId = nil;
    
    [_resource release];
    self.resource = nil;
    
    [_streamingURL release];
    self.streamingURL = nil;
    
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
            [delegate resourceServiceDidFailWithError:[NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:[response.responseData objectFromJSONData]]];
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
            [delegate resourceServiceDidFailWithError:[NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:[response.responseData objectFromJSONData]]];
        } else {
            // We have a valid NSData object, right now this is the only way I know to complete this request...
            NSError *fileError = [[NSError alloc] init];
            BOOL didWriteSuccessfully = [response.responseData writeToFile:filename
                                                                   options:NSDataWritingAtomic
                                                                     error:&fileError];
            
            if (didWriteSuccessfully){
                [delegate resourceServiceDidCompleteWithResult:[KCSResourceResponse responseWithFileName:filename 
                                                                                          withResourceId:resourceId withStreamingURL:nil withData:nil withLength:[response.responseData length]]];
            } else {
                // We failed to write the file
                [delegate resourceServiceDidFailWithError:fileError];
            }
            [fileError release];
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

+ (void)getStreamingURLForResource:(NSString *)resourceId withResourceDelegate:(id<KCSResourceDelegate>)delegate
{
    NSString *resource = [[[KCSClient sharedClient] resourceBaseURL] stringByAppendingFormat:@"download-loc/%@", resourceId];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        // This needs to be REDIRECT, otherwise something is messed up!
        if (response.responseCode != KCS_HTTP_STATUS_REDIRECT){
            [delegate resourceServiceDidFailWithError:[NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:[response.responseData objectFromJSONData]]];
        } else {
            NSString *URL = [response.responseHeaders objectForKey:@"Location"];
            
            if (!URL){
                [delegate resourceServiceDidFailWithError:[NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:[NSDictionary dictionaryWithObject:@"Malformed Redirect, cannot get URL" forKey:@"error"]]];
            } else {
                [delegate resourceServiceDidCompleteWithResult:[KCSResourceResponse responseWithFileName:nil withResourceId:resourceId withStreamingURL:URL withData:nil withLength:0]];
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
    NSError *fileOpError = [[NSError alloc] init];
    // Not sure what the best read options to use here are, so not providing any.  Hopefully the defaults are ok.
    NSData *data = [NSData dataWithContentsOfFile:filename options:0 error:&fileOpError];
    if (data){
        // We read in the data, we can upload it.
        [KCSResourceService saveData:data toResource:resourceId withDelegate:delegate];
    } else {
        // We had an issue..., we didn't upload, so call the failure method of the delegate
        [delegate resourceServiceDidFailWithError:fileOpError];
    }
    [fileOpError release];
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
            [delegate resourceServiceDidFailWithError:[NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:[NSDictionary dictionaryWithObject:xmlData forKey:@"serviceError"]]];
        } else {
            // I feel like we should have a length here, but I might not be saving that response...
            [delegate resourceServiceDidCompleteWithResult:[KCSResourceResponse responseWithFileName:nil withResourceId:resourceId withStreamingURL:nil withData:nil withLength:0]];
        }
    };
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        NSDictionary *jsonData = [response.responseData objectFromJSONData];
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError *err = [NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:jsonData];
            [delegate resourceServiceDidFailWithError:err];
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
            [delegate resourceServiceDidFailWithError:[NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:[NSDictionary dictionaryWithObject:xmlData forKey:@"serviceError"]]];
        } else {
            // I feel like we should have a length here, but I might not be saving that response...
            [delegate resourceServiceDidCompleteWithResult:[KCSResourceResponse responseWithFileName:nil withResourceId:nil withStreamingURL:nil withData:nil withLength:0]];
        }

    };
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        NSDictionary *jsonData = [response.responseData objectFromJSONData];
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError *err = [NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:jsonData];
            [delegate resourceServiceDidFailWithError:err];
        } else {
            NSString *newResource = [jsonData valueForKey:@"URI"];
            KCSRESTRequest *newRequest = [KCSRESTRequest requestForResource:newResource usingMethod:kDeleteRESTMethod];
            [[newRequest withCompletionAction:userCallback failureAction:fBlock progressAction:pBlock] start];
        }
    };

    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}


@end
