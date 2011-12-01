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

@implementation KCSBlobResponse

@synthesize localFileName=_localFileName;
@synthesize blobId=_blobId;
@synthesize blob=_blob; // Set to nil on upload
@synthesize length=_length;

+ (KCSBlobResponse *)responseWithFileName: (NSString *)localFile withBlobId: (NSString *)blobId withData: (NSData *)blob withLength: (NSInteger)length
{
    KCSBlobResponse *response = [[[KCSBlobResponse alloc] init] autorelease];
    response.localFileName = localFile;
    response.blobId = blobId;
    response.blob = blob;
    response.length = length;
    
    return response;
}

- (void)dealloc
{
    [_localFileName release];
    self.localFileName = nil;
    [_blobId release];
    self.blobId = nil;
    
    self.blob = nil;
}


@end

#pragma mark Blob Service

@implementation KCSBlobService

@synthesize kinveyClient=_kinveyClient;

- (void)blobDelegate:(id<KCSBlobDelegate>)delegate downloadBlob:(NSString *)blobId
{
    NSString *resource = [[[KCSClient sharedClient] assetBaseURL] stringByAppendingFormat:@"download-loc/%@", blobId];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            [delegate blobRequestDidFail:[NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:[response.responseData objectFromJSONData]]];
        } else {
            [delegate blobRequestDidComplete:[KCSBlobResponse responseWithFileName:nil withBlobId:blobId withData:response.responseData withLength:[response.responseData length]]];
        }
    };
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate blobRequestDidFail:error];
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnection *connection){};
    
    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}

- (void)blobDelegate:(id<KCSBlobDelegate>)delegate downloadBlob:(NSString *)blobId toFile: (NSString *)file
{
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:@"This feature is not yet supported."
                                userInfo:nil];
    @throw myException;
   
}

- (void)blobDelegate:(id<KCSBlobDelegate>)delegate saveFile:(NSString *)file
{
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:@"This feature is not yet supported."
                                userInfo:nil];
    @throw myException;

}

- (void)blobDelegate:(id<KCSBlobDelegate>)delegate saveFile:(NSString *)file toBlob: (NSString *)blobId
{
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:@"This feature is not yet supported"
                                userInfo:nil];
    @throw myException;

}

- (void)blobDelegate:(id<KCSBlobDelegate>)delegate saveData:(NSData *) data toBlob: (NSString *)blobId
{
    NSString *resource = [[[KCSClient sharedClient] assetBaseURL] stringByAppendingFormat:@"upload-loc/%@", blobId];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];

    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate blobRequestDidFail:error];
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnection *connection){};
    
    KCSConnectionCompletionBlock userCallback = ^(KCSConnectionResponse *response){
        if (response.responseCode != KCS_HTTP_STATUS_CREATED){
            NSString *xmlData = [[[NSString alloc] initWithData:response.responseData encoding:NSUTF8StringEncoding] autorelease];
            [delegate blobRequestDidFail:[NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:[NSDictionary dictionaryWithObject:xmlData forKey:@"serviceError"]]];
        } else {
            // I feel like we should have a length here, but I might not be saving that response...
            [delegate blobRequestDidComplete:[KCSBlobResponse responseWithFileName:nil withBlobId:blobId withData:nil withLength:0]];
        }
    };
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        NSDictionary *jsonData = [response.responseData objectFromJSONData];
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError *err = [NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:jsonData];
            [delegate blobRequestDidFail:err];
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

- (void)blobDelegate:(id<KCSBlobDelegate>)delegate deleteBlob:(NSString *)blobId
{
    NSString *resource = [[[KCSClient sharedClient] assetBaseURL] stringByAppendingFormat:@"remove-loc/%@", blobId];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:kGetRESTMethod];

    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        [delegate blobRequestDidFail:error];
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnection *connection){};
    
    KCSConnectionCompletionBlock userCallback = ^(KCSConnectionResponse *response){
        if (response.responseCode != KCS_HTTP_STATUS_ACCEPTED){
            NSString *xmlData = [[[NSString alloc] initWithData:response.responseData encoding:NSUTF8StringEncoding] autorelease];
            [delegate blobRequestDidFail:[NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:[NSDictionary dictionaryWithObject:xmlData forKey:@"serviceError"]]];
        } else {
            // I feel like we should have a length here, but I might not be saving that response...
            [delegate blobRequestDidComplete:[KCSBlobResponse responseWithFileName:nil withBlobId:nil withData:nil withLength:0]];
        }

    };
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        NSDictionary *jsonData = [response.responseData objectFromJSONData];
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            NSError *err = [NSError errorWithDomain:@"KINVEY ERROR" code:[response responseCode] userInfo:jsonData];
            [delegate blobRequestDidFail:err];
        } else {
            NSString *newResource = [jsonData valueForKey:@"URI"];
            KCSRESTRequest *newRequest = [KCSRESTRequest requestForResource:newResource usingMethod:kDeleteRESTMethod];
            [[newRequest withCompletionAction:userCallback failureAction:fBlock progressAction:pBlock] start];
        }
    };

    [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
}


@end
