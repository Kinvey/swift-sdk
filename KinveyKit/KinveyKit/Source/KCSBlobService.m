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

@implementation KCSBlobResponse

@synthesize localFileName=_localFileName;
@synthesize blobId=_blobId;
@synthesize blob=_blob; // Set to nil on upload
@synthesize length=_length;

@end

#pragma mark Blob Fetch Delegate Mapper

// Just to fix the order in the file.
@class KCSBlobUtilDelegateMapper;

@interface KCSBlobDelegateMapper : NSObject <KCSClientActionDelegate>

@property (retain) id<KCSBlobDelegate> delegate;
@property (retain) KCSClient *kinveyClient;

- (id)initWithDelegate: (id<KCSBlobDelegate>)theDelegate;
+ (id)blobDelegateMapperFromBlobUtilDelegateMapper: (KCSBlobUtilDelegateMapper *)utilMapper;

@end

@implementation KCSBlobDelegateMapper

@synthesize delegate=_delegate;
@synthesize kinveyClient=_kinveyClient;

- (id)initWithDelegate:(id<KCSBlobDelegate>)theDelegate usingClient: (KCSClient *)client
{
    self = [super init];
    
    if (self){
        [self setDelegate:theDelegate];
        [self setKinveyClient:client];
    }
    return self;    
}
- (id)initWithDelegate:(id<KCSBlobDelegate>)theDelegate
{
    return [self initWithDelegate:theDelegate usingClient:nil];
}


+ (id)blobDelegateMapperFromBlobUtilDelegateMapper:(KCSBlobUtilDelegateMapper *)utilMapper
{
    [utilMapper retain];
    KCSBlobDelegateMapper *m = [[KCSBlobDelegateMapper alloc] initWithDelegate:[utilMapper delegate] usingClient:[utilMapper kinveyClient]];
    [utilMapper release];
//    [m autorelease];
    return m;
}


- (void)actionDidComplete:(NSObject *)result
{
    
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)[[self kinveyClient] lastResponse];
    
    if ([response statusCode] != KCS_HTTP_STATUS_OK      &&   // GET
        [response statusCode] != KCS_HTTP_STATUS_CREATED &&   // PUT
        [response statusCode] != KCS_HTTP_STATUS_ACCEPTED){   // DELETE
        [[self delegate] blobRequestDidFail:response];
        return;
    }
    
    NSDictionary *responseHeaders = [response allHeaderFields];
    KCSBlobResponse *res = [[KCSBlobResponse alloc] init];

    // If we preformed a get, this should be the data we requested
    [res setBlob:(NSData *)result];
    
    NSString *contentLength = [responseHeaders objectForKey:@"Content-Length"];
    if (contentLength){
        // We have the length field, so extract it into our length para
        [res setLength:[contentLength intValue]];
    } else {
        [res setLength:0];
    }
    
    [[self delegate] blobRequestDidComplete:res];

    [res release];
}

- (void)actionDidFail:(id)error
{
    [[self delegate] blobRequestDidFail:error];
}

@end

#pragma mark Blob utility delegate mapper


// This class is used to transparently redirect the GET request to the correct
// type, as per the response.

@interface KCSBlobUtilDelegateMapper : NSObject <KCSClientActionDelegate>

@property (retain) id<KCSBlobDelegate> delegate;
@property (retain) NSData *requestData;
@property (retain) NSString *requestType;
@property (retain) KCSClient *kinveyClient;

- (id)initWithDelegate: (id<KCSBlobDelegate>)theDelegate;

@end

@implementation KCSBlobUtilDelegateMapper

@synthesize delegate=_delegate;
@synthesize requestData=_requestData;
@synthesize requestType=_requestType;
@synthesize kinveyClient=_kinveyClient;

- (id)initWithDelegate:(id<KCSBlobDelegate>)theDelegate forOperation: (NSString *)op withRequestData: (NSData *)data usingClient: (KCSClient *)client
{
    self = [super init];
    
    if (self){
        [self setDelegate:theDelegate];
        [self setRequestData:data];
        [self setRequestType:op];
        [self setKinveyClient:client];
    }
    return self;
}

- (id)initWithDelegate:(id<KCSBlobDelegate>)theDelegate forOperation:(NSString *)op usingClient: (KCSClient *)client
{
    return [self initWithDelegate:theDelegate forOperation:op withRequestData:nil usingClient:client];
}

- (id)initWithDelegate:(id<KCSBlobDelegate>)theDelegate forOperation: (NSString *)op
{
    return [self initWithDelegate:theDelegate forOperation:op withRequestData:nil usingClient:nil];
}

- (id)initWithDelegate:(id<KCSBlobDelegate>)theDelegate
{
    return [self initWithDelegate:theDelegate forOperation:nil];
}

- (void)actionDidComplete:(NSObject *)result
{
   
    // At this point in time our request has finished, dispatch to the "correct"
    // activity
    NSHTTPURLResponse *theResponse = (NSHTTPURLResponse *)[[self kinveyClient] lastResponse];
    
    // Communicate a complete request with a failed status back to the client
    if ([theResponse statusCode] != KCS_HTTP_STATUS_OK){
        [[self delegate] blobRequestDidFail:theResponse];
        return;
    }

    NSData *data = (NSData *)result;
    NSDictionary *jsonData = [data objectFromJSONData];
    
    KCSBlobDelegateMapper *finalMap = [KCSBlobDelegateMapper blobDelegateMapperFromBlobUtilDelegateMapper:self];
    [finalMap retain];
    
    if ([[self requestType] isEqualToString:@"PUT"]){
        [[self kinveyClient] clientActionDelegate:finalMap forDataPutRequest:[self requestData] atPath:[jsonData valueForKey:@"URI"]];        
    } else {
        [[self kinveyClient] clientActionDelegate:finalMap forDeleteRequestAtPath:[jsonData valueForKey:@"URI"]];
    }
    
    [finalMap release];
}

- (void)actionDidFail:(id)error
{
    [[self delegate] blobRequestDidFail:error];
}

@end

#pragma mark Blob Service

@implementation KCSBlobService

@synthesize kinveyClient=_kinveyClient;

- (void)blobDelegate:(id<KCSBlobDelegate>)delegate downloadBlob:(NSString *)blobId
{
    NSString *baseURL = [[_kinveyClient baseURL] stringByDeletingLastPathComponent];
    NSString *blobLoc = [baseURL stringByAppendingFormat:@"/blob/%@/download-loc/%@", [[self kinveyClient] appKey], blobId];
    KCSBlobDelegateMapper *mappedDelegate = [[KCSBlobDelegateMapper alloc] initWithDelegate:delegate usingClient:_kinveyClient];
    
    [[self kinveyClient] clientActionDelegate:mappedDelegate forGetRequestAtPath:blobLoc];
    
//    [mappedDelegate autorelease];
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
    NSString *baseURL = [[_kinveyClient baseURL] stringByDeletingLastPathComponent];
    NSString *putPath = [baseURL stringByAppendingFormat:@"/blob/%@/upload-loc/%@", [[self kinveyClient] appKey], blobId];
    
    KCSBlobUtilDelegateMapper *mapper = [[KCSBlobUtilDelegateMapper alloc] initWithDelegate:delegate forOperation:@"PUT" withRequestData:data usingClient:[self kinveyClient]];
    
    [[self kinveyClient] clientActionDelegate:mapper forGetRequestAtPath:putPath];
    
//    [mapper autorelease];

}

- (void)blobDelegate:(id<KCSBlobDelegate>)delegate deleteBlog:(NSString *)blobId
{
    NSString *baseURL = [[_kinveyClient baseURL] stringByDeletingLastPathComponent];
    NSString *deletePath = [baseURL stringByAppendingFormat:@"/blob/%@/remove-loc/%@", [[self kinveyClient] appKey], blobId];
    
    KCSBlobUtilDelegateMapper *mapper = [[KCSBlobUtilDelegateMapper alloc] initWithDelegate:delegate forOperation:@"DELETE" usingClient:[self kinveyClient]];
    
    [[self kinveyClient] clientActionDelegate:mapper forGetRequestAtPath:deletePath];
    
//    [mapper autorelease];
}


@end
