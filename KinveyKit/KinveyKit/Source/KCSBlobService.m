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

+ (KCSResourceResponse *)responseWithFileName:(NSString *)localFile withResourceId:(NSString *)resourceId withData:(NSData *)resource withLength:(NSInteger)length
{
    KCSResourceResponse *response = [[[KCSResourceResponse alloc] init] autorelease];
    response.localFileName = localFile;
    response.resourceId = resourceId;
    response.resource = resource;
    response.length = length;
    
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
    
    [super dealloc];
}


@end

#pragma mark Blob Service

@implementation KCSResourceService
+ (void)downloadResource: (NSString *)resourceId withResourceDelegate: (id<KCSResourceDelegate>)delegate;
{
    NSString *resource = [[[KCSClient sharedClient] assetBaseURL] stringByAppendingFormat:@"download-loc/%@", resourceId];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            [delegate resourceServicetDidFailWithError:[NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:[response.responseData objectFromJSONData]]];
        } else {
            [delegate resourceServiceDidCompleteWithResult:[KCSResourceResponse responseWithFileName:nil withResourceId:resourceId withData:response.responseData withLength:[response.responseData length]]];
        }
    };
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate resourceServicetDidFailWithError:error];
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *connection){};
    
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

+ (void)downloadResource:(NSString *)resourceId toFile:(NSString *)filename withResourceDelegate:(id<KCSResourceDelegate>)delegate
{
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:@"This feature is not yet supported."
                                userInfo:nil];
    @throw myException;
   
}

+ (void)saveLocalResource:(NSString *)filename withDelegate:(id<KCSResourceDelegate>)delegate
{
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:@"This feature is not yet supported."
                                userInfo:nil];
    @throw myException;

}

+ (void)saveLocalResource:(NSString *)filename toResource:(NSString *)resourceId withDelegate:(id<KCSResourceDelegate>)delegate
{
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:@"This feature is not yet supported"
                                userInfo:nil];
    @throw myException;

}

+ (void)saveData:(NSData *)data toResource:(NSString *)resourceId withDelegate:(id<KCSResourceDelegate>)delegate
{
    NSString *resource = [[[KCSClient sharedClient] assetBaseURL] stringByAppendingFormat:@"upload-loc/%@", resourceId];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];

    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate resourceServicetDidFailWithError:error];
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *connection){};
    
    KCSConnectionCompletionBlock userCallback = ^(KCSConnectionResponse *response){
        if (response.responseCode != KCS_HTTP_STATUS_CREATED){
            NSString *xmlData = [[[NSString alloc] initWithData:response.responseData encoding:NSUTF8StringEncoding] autorelease];
            [delegate resourceServicetDidFailWithError:[NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:[NSDictionary dictionaryWithObject:xmlData forKey:@"serviceError"]]];
        } else {
            // I feel like we should have a length here, but I might not be saving that response...
            [delegate resourceServiceDidCompleteWithResult:[KCSResourceResponse responseWithFileName:nil withResourceId:resourceId withData:nil withLength:0]];
        }
    };
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        NSDictionary *jsonData = [response.responseData objectFromJSONData];
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError *err = [NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:jsonData];
            [delegate resourceServicetDidFailWithError:err];
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
    NSString *resource = [[[KCSClient sharedClient] assetBaseURL] stringByAppendingFormat:@"remove-loc/%@", resourceId];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];

    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate resourceServicetDidFailWithError:error];
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *connection){};
    
    KCSConnectionCompletionBlock userCallback = ^(KCSConnectionResponse *response){
        if (response.responseCode != KCS_HTTP_STATUS_ACCEPTED){
            NSString *xmlData = [[[NSString alloc] initWithData:response.responseData encoding:NSUTF8StringEncoding] autorelease];
            [delegate resourceServicetDidFailWithError:[NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:[NSDictionary dictionaryWithObject:xmlData forKey:@"serviceError"]]];
        } else {
            // I feel like we should have a length here, but I might not be saving that response...
            [delegate resourceServiceDidCompleteWithResult:[KCSResourceResponse responseWithFileName:nil withResourceId:nil withData:nil withLength:0]];
        }

    };
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        NSDictionary *jsonData = [response.responseData objectFromJSONData];
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError *err = [NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:jsonData];
            [delegate resourceServicetDidFailWithError:err];
        } else {
            NSString *newResource = [jsonData valueForKey:@"URI"];
            KCSRESTRequest *newRequest = [KCSRESTRequest requestForResource:newResource usingMethod:kDeleteRESTMethod];
            [[newRequest withCompletionAction:userCallback failureAction:fBlock progressAction:pBlock] start];
        }
    };

    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}


@end
