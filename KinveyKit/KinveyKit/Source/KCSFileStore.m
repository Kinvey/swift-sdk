
//
//  KCSFileStore.m
//  KinveyKit
//
//  Created by Michael Katz on 6/17/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSFileStore.h"

#if TARGET_OS_IPHONE
#import <MobileCoreServices/MobileCoreServices.h>
#endif

#import "KCSGenericRESTRequest.h"
#import "NSMutableDictionary+KinveyAdditions.h"
#import "KCSLogManager.h"

#import "NSArray+KinveyAdditions.h"

#import "KCSHiddenMethods.h"
#import "KCSUser+KinveyKit2.h"
#import "KCSMetadata.h"

#import "KCSAppdataStore.h"
#import "KCSErrorUtilities.h"
#import "NSDate+KinveyAdditions.h"
#import "NSString+KinveyAdditions.h"

NSString* const KCSFileId = KCSEntityKeyId;
NSString* const KCSFileACL = KCSEntityKeyMetadata;
NSString* const KCSFileMimeType = @"mimeType";
NSString* const KCSFileFileName = @"_filename";
NSString* const KCSFileSize = @"size";
NSString* const KCSFileOnlyIfNewer = @"fileStoreNewer";
NSString* const KCSFileResume = @"fileStoreResume";
NSString* const KCSFileLocalURL = @"fileStoreLocalURL";
NSString* const KCSFilePublic = @"_public";
NSString* const KCSFileLinkExpirationTimeInterval = @"ttl_in_seconds";


#define kServerLMT @"serverlmt"
#define kRequiredHeaders @"_requiredHeaders"
#define kBytesWritten @"bytesWritten"
#define kGCSULID @"ulid"
#define TIME_INTERVAL 10

NSString* mimeTypeForFilename(NSString* filename)
{
    CFStringRef MIMEType = nil;
    if (filename != nil) {
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[filename pathExtension], NULL);
        if (UTI != nil) {
            MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
            CFRelease(UTI);
        }
    }
    NSString* mimeType = MIMEType ? (NSString*)CFBridgingRelease(MIMEType) : @"application/octet-stream";
    
    return mimeType;
}


NSString* mimeTypeForFileURL(NSURL* fileURL)
{
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[fileURL pathExtension], NULL);
    CFStringRef MIMEType = nil;
    if (UTI != nil) {
        MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
        CFRelease(UTI);
    }
    NSString* mimeType = MIMEType ? (NSString*)CFBridgingRelease(MIMEType) : @"application/octet-stream";

    return mimeType;
}

typedef void (^StreamCompletionBlock)(BOOL done, NSDictionary* returnInfo, NSError* error);

#if BUILD_FOR_UNIT_TEST
static id lastRequest = nil;
#endif

@interface KCSHeadRequest : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>
@property (nonatomic, copy) StreamCompletionBlock completionBlock;
- (void) headersForURL:(NSURL*)url completionBlock:(StreamCompletionBlock)completionBlock;
@end
@implementation KCSHeadRequest
- (void)headersForURL:(NSURL *)url completionBlock:(StreamCompletionBlock)completionBlock
{
    self.completionBlock = completionBlock;
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _completionBlock(NO, @{}, error);
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* hResponse = (NSHTTPURLResponse*)response;
    NSMutableDictionary* responseDict = [NSMutableDictionary dictionary];

    NSDictionary* headers =  [hResponse allHeaderFields];
    BOOL statusOk = hResponse.statusCode >= 200 && hResponse.statusCode <= 300;
    if (statusOk) {
        NSString* serverLMTStr = headers[@"Last-Modified"];
        if (serverLMTStr != nil) {
            NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
            [formatter setLenient:YES];
            NSDate* serverLMT = [formatter dateFromString:serverLMTStr];
            if (serverLMT == nil) {
                [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
                serverLMT = [formatter dateFromString:serverLMTStr];
            }
            if (serverLMT != nil) {
                responseDict[kServerLMT] = serverLMT;
            }
        }
    }
    [connection cancel];
    _completionBlock(statusOk, responseDict, nil);
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    _completionBlock(YES, @{}, nil);
}
@end

@interface KCSUploadStreamRequest : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>
@property (nonatomic, retain) NSMutableData* data;
@property (nonatomic, copy) StreamCompletionBlock completionBlock;
@property (nonatomic, copy) KCSProgressBlock progressBlock;
@property (nonatomic, strong) NSURLConnection* connection;
@property (nonatomic) unsigned long long bytesWritten;
@property (nonatomic, strong) NSHTTPURLResponse* response;
@end

@implementation KCSUploadStreamRequest
- (void) uploadStream:(NSInputStream*)stream
               length:(NSUInteger)length
          contentType:(NSString*)contentType
                toURL:(NSURL*)url
               offset:(unsigned long long) offset
      requiredHeaders:(NSDictionary*)requiredHeaders
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBodyStream:stream];
    
    NSMutableDictionary* headers = [NSMutableDictionary dictionaryWithDictionary:requiredHeaders];
    headers[@"Content-Length"] = [@(length) stringValue];
    headers[@"Content-Type"] = contentType;
    
    if (offset > 0) {
        NSUInteger remaining = length - offset;
        headers[@"Content-Length"] = [@(remaining) stringValue];
        headers[@"Content-Range"] = [NSString stringWithFormat:@"bytes %llu-%d/%d",offset+1,length,length];
        [stream setProperty:@(offset) forKey:NSStreamFileCurrentOffsetKey];
    }

    [request setAllHTTPHeaderFields:headers];
    
    KCSLogTrace(@"upload stream: PUT %@ headers=%@", url, headers);
    
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [_connection start];
    
#if BUILD_FOR_UNIT_TEST
    lastRequest = self;
#endif
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSDictionary* returnVals = @{kBytesWritten: @(_bytesWritten)};
    _completionBlock(NO, returnVals, error);
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    _bytesWritten += bytesWritten;
    KCSLogTrace(@"Uploaded %u bytes (%u / %u)", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    double progress = (double) totalBytesWritten / (double) totalBytesExpectedToWrite;
    if (_progressBlock) {
        _progressBlock(nil, progress);
    }
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    KCSLogNetwork(@"Upload received GCS response code: %d", [(NSHTTPURLResponse*)response statusCode]);
    KCSLogTrace(@"GCS upload response headers: %@", [(NSHTTPURLResponse*)response allHeaderFields]);

    self.response = (NSHTTPURLResponse*) response;
    NSString* length = [(NSHTTPURLResponse*)response allHeaderFields][@"Content-Length"];
    NSUInteger expectedSize = [length longLongValue];
    _data = [NSMutableData dataWithCapacity:expectedSize];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSInteger responseCode = self.response.statusCode;
    NSError* error = nil;
    if (responseCode >= 400) {
        NSString* errorStr = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
        ifNil(errorStr, @"");
        NSDictionary* userInfo = @{NSLocalizedDescriptionKey : @"Upload to GCS Failed", NSLocalizedFailureReasonErrorKey : errorStr};
        error = [NSError errorWithDomain:KCSFileStoreErrorDomain code:responseCode userInfo:userInfo];
    }
    
    NSDictionary* returnVals = @{kBytesWritten: @(_bytesWritten)};
    _completionBlock(YES, returnVals, error);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_data appendData:data];
}

- (void) cancel
{
    [_connection cancel];
    NSError* error = [NSError errorWithDomain:@"UNIT TEST" code:700 userInfo:nil];
    
    NSDictionary* returnVals = @{kBytesWritten: @(_bytesWritten)};
    _completionBlock(NO, returnVals, error);
}

@end


@interface KCSDownloadStreamRequest : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>
@property (nonatomic, retain) NSFileHandle* outputHandle;
@property (nonatomic) NSUInteger maxLength;
@property (nonatomic, copy) StreamCompletionBlock completionBlock;
@property (nonatomic, copy) KCSProgressBlock progressBlock;
@property (nonatomic, retain) KCSFile* intermediateFile;
@property (nonatomic, retain) NSString* serverContentType;
@property (nonatomic, retain) NSURLConnection* connection;
@property (nonatomic, retain) NSHTTPURLResponse* response;
@property (nonatomic, retain) NSMutableData* responseData;
@property (nonatomic) unsigned long long bytesWritten;
@end

@implementation KCSDownloadStreamRequest
- (void) downloadStream:(KCSFile*)intermediate fromURL:(NSURL*)url alreadyWrittenBytes:(NSNumber*)alreadyWritten completionBlock:(StreamCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    self.completionBlock = completionBlock;
    self.progressBlock = progressBlock;
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];

    NSURL* file = [intermediate localURL];
    NSError* error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[file path]] == NO) {
        [[NSFileManager defaultManager] createFileAtPath:[file path] contents:nil attributes:nil];
    }
    if (error != nil) {
        error = [KCSErrorUtilities createError:nil description:@"Unable to write to intermediate file" errorCode:error.code domain:KCSFileStoreErrorDomain requestId:nil sourceError:error];
        completionBlock(NO, @{}, error);
        return;
    }
    _outputHandle = [NSFileHandle fileHandleForWritingToURL:file error:&error];
    if (error != nil) {
        error = [KCSErrorUtilities createError:nil description:@"Unable to write to intermediate file" errorCode:error.code domain:KCSFileStoreErrorDomain requestId:nil sourceError:error];
        completionBlock(NO, @{}, error);
        return;
    }
    if (alreadyWritten != nil) {
        unsigned long long written = [_outputHandle seekToEndOfFile];
        if ([alreadyWritten unsignedLongLongValue] == written) {
            KCSLogTrace(@"Download was already in progress. Resuming from byte %llu.", written);
            [request addValue:[NSString stringWithFormat:@"bytes=%llu-", written] forHTTPHeaderField:@"Range"];
        }
    }
    
    _intermediateFile = intermediate;
    _bytesWritten = 0;
    
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [_connection start];

    
#if BUILD_FOR_UNIT_TEST
    lastRequest = self;
#endif
}

- (void) cancel
{
    [_connection cancel];
    [_outputHandle closeFile];
    NSError* error = [NSError errorWithDomain:@"UNIT TEST" code:700 userInfo:nil];

    NSMutableDictionary* returnVals = [NSMutableDictionary dictionary];
    setIfValNotNil(returnVals[KCSFileMimeType], _serverContentType);
    _completionBlock(NO, returnVals, error);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_outputHandle closeFile];
    NSMutableDictionary* returnVals = [NSMutableDictionary dictionary];
    setIfValNotNil(returnVals[KCSFileMimeType], _serverContentType);
    _completionBlock(NO, returnVals, error);
}


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    KCSLogNetwork(@"GCS download response code: %d",[(NSHTTPURLResponse*)response statusCode]);
    
    _response = (NSHTTPURLResponse*)response;
    NSDictionary* headers =  [_response allHeaderFields];
    NSString* length = headers[@"Content-Length"];
    _maxLength = [length longLongValue];
    _serverContentType = headers[@"Content-Type"];
    
    if (_response.statusCode >= 400) {
        _responseData = [NSMutableData data];
    }
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    [_outputHandle closeFile];
    
    NSMutableDictionary* returnVals = [NSMutableDictionary dictionary];
    setIfValNotNil(returnVals[KCSFileMimeType], _serverContentType);
    setIfValNotNil(returnVals[kBytesWritten], @(_bytesWritten));
    
    NSInteger responseCode = self.response.statusCode;
    NSError* error = nil;
    if (responseCode >= 400) {
        NSString* errorStr = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
        ifNil(errorStr, @"");
        NSDictionary* userInfo = @{NSLocalizedDescriptionKey : @"Download from GCS Failed", NSLocalizedFailureReasonErrorKey : errorStr};
        error = [NSError errorWithDomain:KCSFileStoreErrorDomain code:responseCode userInfo:userInfo];
    }
    
    _completionBlock(YES, returnVals, error);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    KCSLogTrace(@"downloaded %u bytes from file service", [data length]);
    
    if (_response && _response.statusCode >= 400) {
        //is an error just get the data locally
        [_responseData appendData:data];
    } else {
        //response is good, collect data
        [_outputHandle writeData:data];
        _bytesWritten += data.length;
        if (_progressBlock) {
            NSUInteger downloadedAmount = [_outputHandle offsetInFile];
            _intermediateFile.length = downloadedAmount;
            
            double progress = (double)downloadedAmount / (double) _maxLength;
            _progressBlock(@[_intermediateFile], progress);
        }
    }
}

@end

@implementation KCSFileStore
static NSMutableSet* _ongoingDownloads;

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _ongoingDownloads = [NSMutableSet set];
    });
}

#pragma mark - Uploads
+ (void) _getUploadHeader:(NSURL*)url
                  options:(NSDictionary*)options
          requiredHeaders:(NSDictionary*)requiredHeaders
               uploadFile:(KCSFile*)uploadFile
                   stream:(NSInputStream*)stream
          completionBlock:(KCSFileUploadCompletionBlock)completionBlock
            progressBlock:(KCSProgressBlock)progressBlock
{
    //PUT {session_uri} HTTP/1.1
    //Authorization: your_auth_token
    //Content-Length: 0
    //Content-Range: bytes */2000000
    
    NSString* urlstr = [[url absoluteString] stringByAppendingFormat:@"&%@", options[kGCSULID]];
    
    
    KCSGenericRESTRequest* req = [KCSGenericRESTRequest requestForResource:urlstr usingMethod:kPutRESTMethod withCompletionAction:^(KCSConnectionResponse *response) {
        
        if (response.responseCode == 308) {
            //can resume
            NSString* rangeStr = [response responseHeaders][@"Range"];
            NSString* bytesW =[rangeStr componentsSeparatedByString:@"-"][1];
            NSNumber* bytesN = [[[NSNumberFormatter alloc] init] numberFromString:bytesW];
            NSUInteger ulBytes = [bytesN unsignedIntegerValue];
            KCSLogTrace(@"Already uploaded %d bytes. Need to upload rest", ulBytes);
            
            
            KCSUploadStreamRequest* request = [[KCSUploadStreamRequest alloc] init];
            request.completionBlock = ^(BOOL done,  NSDictionary* returnInfo, NSError *error) {
                uploadFile.bytesWritten = [returnInfo[kBytesWritten] longLongValue];
                completionBlock(uploadFile, error);
            };
            if (progressBlock) {
                request.progressBlock = ^(NSArray* objects, double progress){
                    progressBlock(@[uploadFile], progress);
                };
            }
            
            [request uploadStream:stream length:uploadFile.length contentType:uploadFile.mimeType toURL:[NSURL URLWithString:urlstr] offset:ulBytes requiredHeaders:requiredHeaders];
            
        } else {
            //start from beginning
            KCSLogTrace(@"Got a %d from GCS, so restarting upload from beginning", response.responseCode);
            NSMutableDictionary* d = [NSMutableDictionary dictionaryWithDictionary:options];
            [d removeObjectForKey:kGCSULID];
            [self uploadFile:uploadFile.localURL options:d completionBlock:completionBlock progressBlock:progressBlock];
        }
    } failureAction:^(NSError *error) {
        KCSLogTrace(@"Error resuming upload, restarting from beginning");
        //start from beginning
        NSMutableDictionary* d = [NSMutableDictionary dictionaryWithDictionary:options];
        [d removeObjectForKey:kGCSULID];
        [self uploadFile:uploadFile.localURL options:d completionBlock:completionBlock progressBlock:progressBlock];

    } progressAction:nil];
    
    req.headers[@"Content-Length"] = @"0";
    req.headers[@"Content-Type"] = options[KCSFileMimeType];
    
    NSNumber* fileSize = options[KCSFileSize];
    req.headers[@"Content-Range"] = [NSString stringWithFormat:@"bytes */%@", fileSize];

    [requiredHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        req.headers[key] = obj;
    }];
    
    [req start];
}

+ (void) _uploadStream3:(NSInputStream*)stream
                 toURL:(NSURL*)url
       requiredHeaders:(NSDictionary*)requiredHeaders
            uploadFile:(KCSFile*)uploadFile
               options:(NSDictionary*)options
       completionBlock:(KCSFileUploadCompletionBlock)completionBlock
         progressBlock:(KCSProgressBlock)progressBlock
{
  
    
    KCSUploadStreamRequest* request = [[KCSUploadStreamRequest alloc] init];
    request.completionBlock = ^(BOOL done,  NSDictionary* returnInfo, NSError *error) {
        uploadFile.bytesWritten = [returnInfo[kBytesWritten] longLongValue];
        completionBlock(uploadFile, error);
    };
    if (progressBlock) {
        request.progressBlock = ^(NSArray* objects, double progress){
            progressBlock(@[uploadFile], progress);
        };
    }
    
    unsigned long long bytes = 0;
    // GCS RESUMABLE UPLOAD STEP #3 ---------------
    [request uploadStream:stream length:uploadFile.length contentType:uploadFile.mimeType toURL:url offset:bytes requiredHeaders:requiredHeaders];
}


+ (void) _uploadStream:(NSInputStream*)stream
                 toURL:(NSURL*)url
       requiredHeaders:(NSDictionary*)requiredHeaders
            uploadFile:(KCSFile*)uploadFile
               options:(NSDictionary*)options
       completionBlock:(KCSFileUploadCompletionBlock)completionBlock
         progressBlock:(KCSProgressBlock)progressBlock
{
    if (fieldExistsAndIsYES(options, KCSFileResume)) {
        NSMutableDictionary* d = [NSMutableDictionary dictionaryWithDictionary:options];
        d[KCSFileSize] = @(uploadFile.length);
        d[KCSFileMimeType] = uploadFile.mimeType;

        d[kGCSULID] = uploadFile.gcsULID;
        [self _getUploadHeader:url options:d requiredHeaders:requiredHeaders uploadFile:uploadFile stream:stream completionBlock:completionBlock progressBlock:progressBlock];
        
        return;
    }
    
    KCSLogTrace(@"Upload location found, uploading file to: %@", url);

    KCSGenericRESTRequest* req = [KCSGenericRESTRequest requestForResource:[url absoluteString] usingMethod:kPutRESTMethod withCompletionAction:^(KCSConnectionResponse *response) {
        if (response.responseCode >= 400) {
            //handle error
            NSError* error = [KCSErrorUtilities createError:nil description:[NSString stringWithFormat:@"Error uploading to GCS: %@", [response jsonResponseValue]] errorCode:response.responseCode domain:KCSFileStoreErrorDomain requestId:nil];
            completionBlock(nil, error);
        } else {
            NSDictionary* h = [response responseHeaders];
            NSString* loc = h[@"Location"];
            NSString* queryParams = [[NSURL URLWithString:loc] query];
            NSArray* ps = [queryParams componentsSeparatedByString:@"&"];
            
            NSString* ulid = @"";
            for (NSString* s in ps) {
                if ([s hasPrefix:@"upload_id"]) {
                    ulid = s;
                }
            }
            
            uploadFile.gcsULID = ulid;
            
            NSString* newstr = [[url absoluteString] stringByAppendingFormat:@"&%@", ulid];
            NSURL * newurl = [NSURL URLWithString:newstr];
            [self _uploadStream3:stream toURL:newurl requiredHeaders:requiredHeaders uploadFile:uploadFile options:options completionBlock:completionBlock progressBlock:progressBlock];
        }
    } failureAction:^(NSError *error) {
        completionBlock(nil, error);
    } progressAction:nil];
    req.headers[@"Content-Length"] = @"0";
    if (options[KCSFileMimeType] != nil) {
        req.headers[@"Content-Type"] = options[KCSFileMimeType];
    }
    
    [requiredHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        req.headers[key] = obj;
    }];
    
    // GCS RESUMABLE UPLOAD STEP #1---------------
    [req start];
}

+ (void) _uploadData:(NSData*)data toURL:(NSURL*)url requiredHeaders:(NSDictionary*)requiredHeaders uploadFile:(KCSFile*)uploadFile options:(NSDictionary*)options completionBlock:(KCSFileUploadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSInputStream* stream = [NSInputStream inputStreamWithData:data];
    [self _uploadStream:stream toURL:url requiredHeaders:requiredHeaders uploadFile:uploadFile options:options completionBlock:completionBlock progressBlock:progressBlock];
}

+ (void) _uploadFile:(NSURL*)localFile toURL:(NSURL*)url requiredHeaders:(NSDictionary*)requiredHeaders uploadFile:(KCSFile*)uploadFile options:(NSDictionary*)options completionBlock:(KCSFileUploadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSInputStream* stream = [NSInputStream inputStreamWithURL:localFile];
    [self _uploadStream:stream toURL:url requiredHeaders:requiredHeaders uploadFile:uploadFile options:options completionBlock:completionBlock progressBlock:progressBlock];
}

+ (KCSNetworkRequest*) _getUploadLoc:(NSMutableDictionary *)options
{
    //remove unwanted keys
    NSMutableDictionary* body = [NSMutableDictionary dictionaryWithDictionary:options];
    [body removeObjectForKey:KCSFileResume];
    [body removeObjectForKey:kGCSULID];
    
    NSString* fileId = body[KCSFileId];
    
    KCSNetworkRequest* request = [[KCSNetworkRequest alloc] init];
    request.httpMethod = kKCSRESTMethodPOST;
    request.contextRoot = kKCSContextBLOB;
    if (fileId) {
        request.pathComponents = @[fileId];
        request.httpMethod = kKCSRESTMethodPUT;
    }
    
    KCSMetadata* metadata = [body popObjectForKey:KCSEntityKeyMetadata];
    if (metadata) {
        body[@"_acl"] = [metadata aclValue];
    }
    
    request.authorization = [KCSUser activeUser];
    request.body = body;
    
    request.headers[@"x-Kinvey-content-type"] = body[@"mimeType"];
    
    return request;
}

KCSFile* fileFromResults(NSDictionary* results)
{
    KCSFile* uploadFile = [[KCSFile alloc] init];
    uploadFile.length = [results[@"size"] unsignedIntegerValue];
    uploadFile.mimeType = results[KCSFileMimeType];
    uploadFile.fileId = results[KCSFileId];
    uploadFile.filename = results[KCSFileFileName];
    uploadFile.publicFile = results[KCSFilePublic];
    
    NSDictionary* kmd = results[@"_kmd"];
    NSDictionary* acl = results[@"_acl"];
    KCSMetadata* metadata = [[KCSMetadata alloc] initWithKMD:kmd acl:acl];
    uploadFile.metadata = metadata;

    return uploadFile;
}

+ (void)uploadData:(NSData *)data options:(NSDictionary *)uploadOptions completionBlock:(KCSFileUploadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSParameterAssert(data != nil);
    NSParameterAssert(completionBlock != nil);
    if (uploadOptions && uploadOptions[KCSFileSize]) {
        [[NSException exceptionWithName:@"KCSInvalidParameter" reason:@"Specifing upload file size (`KCSFileSize`) is not supported. Size is determined by the data." userInfo:nil] raise];
    }

    NSMutableDictionary* opts = [NSMutableDictionary dictionaryWithDictionary:uploadOptions];
    opts[KCSFileSize] = @(data.length);
    NSString* mimeType = opts[KCSFileMimeType];
    ifNil(mimeType, mimeTypeForFilename(opts[KCSFileFileName]));
    setIfEmpty(opts, KCSFileMimeType, mimeType);
    
    KCSNetworkRequest* request = [self _getUploadLoc:opts];    
    [request run:^(id results, NSError *error) {
        if (error != nil){
            error = [error updateDomain:KCSFileStoreErrorDomain];
            completionBlock(nil, error);
        } else {
            NSString* url = results[@"_uploadURL"];
            if (url) {
                KCSFile* uploadFile = fileFromResults(results);
                NSDictionary* requiredHeaders = results[kRequiredHeaders];
                [self _uploadData:data toURL:[NSURL URLWithString:url] requiredHeaders:requiredHeaders uploadFile:uploadFile options:opts completionBlock:completionBlock progressBlock:progressBlock];
            } else {
                NSError* error = [KCSErrorUtilities createError:nil description:[NSString stringWithFormat:@"Did not get an _uploadURL id:%@", results[KCSFileId]] errorCode:KCSFileStoreLocalFileError domain:KCSFileStoreErrorDomain requestId:nil];
                completionBlock(nil, error);
            }
        }
    }];
}

+ (void) uploadFile:(NSURL*)fileURL options:(NSDictionary*)uploadOptions completionBlock:(KCSFileUploadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSParameterAssert(fileURL != nil);
    NSParameterAssert(completionBlock != nil);
    if (uploadOptions && uploadOptions[KCSFileSize]) {
        [[NSException exceptionWithName:@"KCSInvalidParameter" reason:@"Specifing upload file size (`KCSFileSize`) is not supported. Size is determined by the size of the file's data." userInfo:nil] raise];
    }
    
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]];
    if (exists == NO) {
        NSError* error = [KCSErrorUtilities createError:nil description:[NSString stringWithFormat:@"fileURL does not exist '%@'", fileURL] errorCode:KCSFileStoreLocalFileError domain:KCSFileStoreErrorDomain requestId:nil];
        completionBlock(nil, error);
        return;
    }
    
    NSError* error = nil;
    NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:&error];
    if (error != nil) {
         error = [KCSErrorUtilities createError:nil description:[NSString stringWithFormat:@"Trouble loading attributes at '%@'", fileURL] errorCode:KCSFileStoreLocalFileError domain:KCSFileStoreErrorDomain requestId:nil sourceError:error];
        completionBlock(nil, error);
        return;
    }
    
    NSMutableDictionary* opts = [NSMutableDictionary dictionaryWithDictionary:uploadOptions];
    opts[KCSFileSize] = attr[NSFileSize]; //overwrite size
    setIfEmpty(opts, KCSFileFileName, [fileURL lastPathComponent]);
    
    NSString* mimeType = mimeTypeForFileURL(fileURL);
    
    setIfEmpty(opts, KCSFileMimeType, mimeType);

    NSNumber* resume = opts[KCSFileResume];
    
    KCSNetworkRequest* request = [self _getUploadLoc:opts];
    [request run:^(id results, NSError *error) {
        if (error != nil){
            error = [error updateDomain:KCSFileStoreErrorDomain];
            completionBlock(nil, error);
        } else {
            NSString* url = results[@"_uploadURL"];
            if (url) {
                KCSFile* uploadFile = fileFromResults(results);
                uploadFile.localURL = fileURL;
                NSDictionary* requiredHeaders = results[kRequiredHeaders];
                if (resume) {
                    opts[KCSFileResume] = resume;
                    uploadFile.gcsULID = uploadOptions[kGCSULID];
                }

                [self _uploadFile:fileURL toURL:[NSURL URLWithString:url] requiredHeaders:requiredHeaders uploadFile:uploadFile options:opts completionBlock:completionBlock progressBlock:progressBlock];
            } else {
                NSError* error = [KCSErrorUtilities createError:nil description:[NSString stringWithFormat:@"Did not get an _uploadURL id:%@", results[KCSFileId]] errorCode:KCSFileStoreLocalFileError domain:KCSFileStoreErrorDomain requestId:nil];
                completionBlock(nil, error);
            }
        }
    }];
}

#pragma mark - Downloads
+ (void) _downloadToFile:(NSURL*)localFile
                 fromURL:(NSURL*)url
                  fileId:(NSString*)fileId
                filename:(NSString*)filename
                mimeType:(NSString*)mimeType
             onlyIfNewer:(BOOL)onlyIfNewer
         downloadedBytes:(NSNumber*)bytes
         completionBlock:(KCSFileDownloadCompletionBlock)completionBlock
           progressBlock:(KCSProgressBlock)progressBlock
{
    if (!localFile) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"no local file to download to." userInfo:nil] raise];
    }
    
    if ([_ongoingDownloads containsObject:fileId]) {
        NSDictionary* userInfo = @{NSLocalizedDescriptionKey : @"Download already in progress."};
        NSError* error = [NSError errorWithDomain:KCSFileStoreErrorDomain code:KCSFileError userInfo:userInfo];
        completionBlock(nil, error);
        return;
    } else {
        [_ongoingDownloads addObject:fileId];
    }
    
    KCSFile* intermediateFile = [[KCSFile alloc] initWithLocalFile:localFile
                                                            fileId:fileId
                                                          filename:filename
                                                          mimeType:mimeType];
    intermediateFile.remoteURL = url;
    
    if (onlyIfNewer == YES) {
        BOOL fileAlreadyExists = [[NSFileManager defaultManager] fileExistsAtPath:[localFile path]];
        if (fileAlreadyExists == YES) {
            NSError* error = nil;
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[localFile path] error:&error];
            if (error == nil && attributes != nil) {
                NSDate* localLMT = attributes[NSFileModificationDate];
                if (localLMT != nil) {
                    //get lmt from server
                    ifNil(mimeType, mimeTypeForFileURL(localFile));
                    KCSHeadRequest* hr = [[KCSHeadRequest alloc] init];
                    [hr headersForURL:url completionBlock:^(BOOL done, NSDictionary *returnInfo, NSError *error) {
                        if (done && returnInfo && returnInfo[kServerLMT]) {
                            NSDate* serverLMT = returnInfo[kServerLMT];
                            if (ABS([localLMT timeIntervalSinceDate:serverLMT]) < TIME_INTERVAL) {
                                //don't re-download the file
                                intermediateFile.mimeType = mimeType;
                                intermediateFile.length = [attributes[NSFileSize] unsignedIntegerValue];
                                [_ongoingDownloads removeObject:fileId];
                                completionBlock(@[intermediateFile], nil);
                            } else {
                                //redownload the file
                                [self _downloadToFile:localFile fromURL:url fileId:fileId filename:filename mimeType:mimeType onlyIfNewer:NO downloadedBytes:nil completionBlock:completionBlock progressBlock:progressBlock];
                            }
                        } else {
                            // do download the whole if we can't determine the server lmt (assume it's new)
                            [self _downloadToFile:localFile fromURL:url fileId:fileId filename:filename mimeType:mimeType onlyIfNewer:NO downloadedBytes:nil completionBlock:completionBlock progressBlock:progressBlock];
                        }
                    }];
                    return; // stop here, otherwise keep doing the righteous path
                }
            }
        }

    }

    KCSLogTrace(@"Download location found, downloading file from: %@", url);
    
    KCSDownloadStreamRequest* downloader = [[KCSDownloadStreamRequest alloc] init];
    [downloader downloadStream:intermediateFile fromURL:url alreadyWrittenBytes:bytes completionBlock:^(BOOL done, NSDictionary* returnInfo, NSError *error) {
        [_ongoingDownloads removeObject:fileId];
        if (intermediateFile.mimeType == nil && returnInfo[KCSFileMimeType] != nil) {
            intermediateFile.mimeType = returnInfo[KCSFileMimeType];
        } else if (intermediateFile.mimeType == nil) {
            intermediateFile.mimeType = mimeTypeForFilename(intermediateFile.filename);
        }
        intermediateFile.bytesWritten = [returnInfo[kBytesWritten] unsignedLongLongValue];
        intermediateFile.length = [[[NSFileManager defaultManager] attributesOfItemAtPath:[localFile path] error:NULL] fileSize];

        completionBlock(@[intermediateFile], error);
    } progressBlock:progressBlock];
}


+ (void) _downloadToData:(NSURL*)url
                  fileId:(NSString*)fileId
                filename:(NSString*)filename
                mimeType:(NSString*)mimeType
         completionBlock:(KCSFileDownloadCompletionBlock)completionBlock
           progressBlock:(KCSProgressBlock)progressBlock
{
    if ([_ongoingDownloads containsObject:fileId]) {
        NSDictionary* userInfo = @{NSLocalizedDescriptionKey : @"Download already in progress."};
        NSError* error = [NSError errorWithDomain:KCSFileStoreErrorDomain code:KCSFileError userInfo:userInfo];
        completionBlock(nil, error);
        return;
    } else {
        [_ongoingDownloads addObject:fileId];
    }
    
    NSURL* cachesDir = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    NSString* tempName = [NSString stringByPercentEncodingString:[fileId stringByReplacingOccurrencesOfString:@"/" withString:@""]];
    NSURL* localFile = [NSURL URLWithString:tempName relativeToURL:cachesDir];
    
    NSAssert(localFile != nil, @"%@ is not a valid file name for temp storage", fileId);

    KCSFile* intermediateFile = [[KCSFile alloc] initWithLocalFile:localFile
                                                            fileId:fileId
                                                          filename:filename
                                                          mimeType:mimeType];
    
    
    KCSLogTrace(@"Download location found, downloading file from: %@", url);
    
    KCSDownloadStreamRequest* downloader = [[KCSDownloadStreamRequest alloc] init];
    [downloader downloadStream:intermediateFile fromURL:url alreadyWrittenBytes:nil completionBlock:^(BOOL done, NSDictionary* returnInfo, NSError *error) {
        [_ongoingDownloads removeObject:fileId];
        
        if (error) {
            completionBlock(nil, error);
        } else {
            NSData* data = [NSData dataWithContentsOfURL:localFile];
            if (data == nil) {
                KCSLogError(@"Error reading temp file for data download: %@", localFile);
                NSDictionary* userInfo = @{NSLocalizedDescriptionKey : @"Error reading temp file for data download.", NSLocalizedRecoverySuggestionErrorKey : @"Retry download."};
                NSError* error = [NSError errorWithDomain:KCSFileStoreErrorDomain code:KCSFileError userInfo:userInfo];
                completionBlock(nil, error);
                return;
            }
            
            KCSFile* file = [[KCSFile alloc] initWithData:data
                                                   fileId:fileId
                                                 filename:filename
                                                 mimeType:mimeType];
            NSError* error = nil;
            [[NSFileManager defaultManager] removeItemAtURL:localFile error:&error];
            KCSLogNSError(@"error removing temp download cache", error);
            completionBlock(@[file], nil);
        }
    } progressBlock:progressBlock];
}

+ (void) _getDownloadObject:(NSString*)fileId options:(NSDictionary*)options intermediateCompletionBlock:(KCSCompletionBlock)completionBlock
{
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection fileMetadataCollection] options:nil];
    
    if (options) {
        KCSQuery* query = [KCSQuery queryOnField:KCSEntityKeyId withExactMatchForValue:fileId];
        if (options[KCSFileLinkExpirationTimeInterval]) {
            KCSQueryTTLModifier* ttl = [[KCSQueryTTLModifier alloc] initWithTTL:options[KCSFileLinkExpirationTimeInterval]];
            query.ttlModifier = ttl;
        }
#if BUILD_FOR_UNIT_TEST
        if (fieldExistsAndIsYES(options, KCSFileStoreTestExpries)) {
            KCSQueryTTLModifier* ttl = [[KCSQueryTTLModifier alloc] initWithTTL:@0.1];
            query.ttlModifier = ttl;
        }
#endif
        [store queryWithQuery:query withCompletionBlock:completionBlock withProgressBlock:nil];
    } else {
        [store loadObjectWithID:fileId withCompletionBlock:completionBlock withProgressBlock:nil];
    }
}

+ (void) _downloadFile:(NSString*)toFilename fileId:(NSString*)fileId options:(NSDictionary*)options completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    __block NSString* destinationName = toFilename;
    [self _getDownloadObject:fileId options:options intermediateCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil != nil) {
            NSError* fileError = [KCSErrorUtilities createError:nil
                                       description:[NSString stringWithFormat:@"Error downloading file, id='%@'", fileId]
                                         errorCode:errorOrNil.code
                                            domain:KCSFileStoreErrorDomain
                                         requestId:nil
                                       sourceError:errorOrNil];
            completionBlock(nil, fileError);
        } else {
            if (objectsOrNil == nil || objectsOrNil.count == 0) {
                completionBlock(@[],nil);
                return;
            }
            
            if (objectsOrNil.count != 1) {
                KCSLogError(@"returned %u results for file metadata at id '%@', expecting only 1.", objectsOrNil.count, fileId);
            }
            
#if BUILD_FOR_UNIT_TEST
            if (fieldExistsAndIsYES(options, KCSFileStoreTestExpries)) {
                KCSLogDebug(@"SLEEPING TO EXPIRE LINK");
                [NSThread sleepForTimeInterval:10];
            }
#endif
            
            KCSFile* file = objectsOrNil[0];
            if (file && file.remoteURL) {
                
                NSURL* downloadsDir = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
                ifNil(destinationName, file.filename);
                NSURL*  destinationFile = [NSURL URLWithString:destinationName relativeToURL:downloadsDir];
                
                
                if (fieldExistsAndIsYES(options, KCSFileOnlyIfNewer)) {
                    
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[destinationFile path]];
                    if (fileExists == YES) {
                        
                        NSDate* serverDate = file.metadata.lastModifiedTime;
                        NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[destinationFile path] error:NULL];
                        NSDate* fileDate = fileAttributes ? [fileAttributes fileModificationDate]: nil;

                        if ([serverDate isLaterThan:fileDate] == NO) {
                            //return existing file
                            KCSLogTrace(@"File %@ is older or same as file on disk. Using local file cache", fileId);
                            file.localURL = destinationFile;
                            completionBlock(@[file], nil);
                            return;
                        } // else re-download the file (NOTE: requires fall through to below)
                    }
                }
                
                //TODO: handle onlyIfNewer - check time on downloadObject
                [self _downloadToFile:destinationFile fromURL:file.remoteURL fileId:fileId filename:destinationName mimeType:file.mimeType onlyIfNewer:NO downloadedBytes:nil completionBlock:completionBlock progressBlock:progressBlock];
            } else {
                NSError* error = [KCSErrorUtilities createError:nil description:@"No download url provided by Kinvey" errorCode:KCSFileError domain:KCSFileStoreErrorDomain requestId:nil];
                completionBlock(nil, error);
            }
        }
    }];
}

+ (void) _downloadData:(NSString*)fileId completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [self _getDownloadObject:fileId options:nil intermediateCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil != nil) {
            NSError* fileError = [KCSErrorUtilities createError:nil
                                                    description:[NSString stringWithFormat:@"Error downloading file, id='%@'", fileId]
                                                      errorCode:errorOrNil.code
                                                         domain:KCSFileStoreErrorDomain
                                                      requestId:nil
                                                    sourceError:errorOrNil];
            completionBlock(nil, fileError);
        } else {
            if (objectsOrNil.count != 1) {
                KCSLogError(@"returned %u results for file metadata at id '%@', expecting only 1.", objectsOrNil.count, fileId);
            }
            
            KCSFile* file = objectsOrNil[0];
            if (file && file.remoteURL) {
                [self _downloadToData:file.remoteURL fileId:fileId filename:file.filename mimeType:file.mimeType completionBlock:completionBlock progressBlock:progressBlock];
            } else {
                NSError* error = [KCSErrorUtilities createError:nil description:@"No download url provided by Kinvey" errorCode:KCSFileError domain:KCSFileStoreErrorDomain requestId:nil];
                completionBlock(nil, error);
            }
        }
    }];
}

+ (void)downloadFileByQuery:(KCSQuery *)query completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [self downloadFileByQuery:query filenames:nil options:nil completionBlock:completionBlock progressBlock:progressBlock];
}

+ (void)downloadFileByQuery:(KCSQuery *)query filenames:(NSArray*)filenames options:(NSDictionary*)options completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSParameterAssert(query != nil);
    NSParameterAssert(completionBlock != nil);
    
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection fileMetadataCollection] options:nil];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil != nil) {
            NSError* fileError = [KCSErrorUtilities createError:nil
                                                    description:[NSString stringWithFormat:@"Error downloading file(S), query='%@'", [query description]]
                                                      errorCode:errorOrNil.code
                                                         domain:KCSFileStoreErrorDomain
                                                      requestId:nil
                                                    sourceError:errorOrNil];
            completionBlock(nil, fileError);
        } else {
            if (objectsOrNil == nil || objectsOrNil.count == 0) {
                completionBlock(objectsOrNil, errorOrNil);
                return; //short circuit since there is no work
            }
            
            NSUInteger totalBytes = [[objectsOrNil valueForKeyPath:@"@sum.length"] unsignedIntegerValue];
            NSMutableArray* files = [NSMutableArray arrayWith:objectsOrNil.count copiesOf:[NSNull null]];

            //get ids to match the out-of order return file objects
            NSArray* destinationIds = nil;
            if (query.query != nil) {
                //parse the query object
                NSDictionary* idQuery = query.query[KCSEntityKeyId];
                //need to also check for dictionary b/c id query could be a exact match on id
                if (idQuery != nil && [idQuery isKindOfClass:[NSDictionary class]]) {
                    NSArray* inIds = idQuery[@"$in"]; // mongo ql dependency
                    if (inIds && [inIds isKindOfClass:[NSArray class]]) {
                        destinationIds = inIds;
                    }
                }
            }
            
            __block NSUInteger completedCount = 0;
            __block NSError* firstError = nil;
            [objectsOrNil enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                KCSFile* thisFile = obj;
                if (thisFile && thisFile.remoteURL) {
                    
                    NSURL* destinationFile = nil;
                    NSURL* downloadsDir = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
                    NSString* destinationFilename = thisFile.filename;
                    
                    if (destinationIds != nil && filenames != nil) {
                        NSUInteger specifiedFileIndex = [destinationIds indexOfObject:thisFile.fileId];
                        if (specifiedFileIndex != NSNotFound && specifiedFileIndex < filenames.count) {
                            destinationFilename = filenames[specifiedFileIndex];
                        }
                    }
                    
                    destinationFile = [NSURL URLWithString:destinationFilename relativeToURL:downloadsDir];

                    //TODO: onlyIfNewer check download object
                    [self _downloadToFile:destinationFile fromURL:thisFile.remoteURL fileId:thisFile.fileId filename:destinationFilename mimeType:thisFile.mimeType onlyIfNewer:NO downloadedBytes:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
                        if (error != nil && firstError == nil) {
                            firstError = error;
                        }
                        DBAssert(downloadedResources.count == 1, @"should only get 1 per download");
                        if (downloadedResources != nil && downloadedResources.count > 0) {
                            files[idx] = downloadedResources[0];
                        }
                        if (++completedCount == objectsOrNil.count) {
                            //only call completion when all done
                            completionBlock(files, firstError);
                        }
                    } progressBlock:^(NSArray *objects, double percentComplete) {
                        if (progressBlock != nil) {
                            DBAssert(objects.count == 1, @"should only get 1 per download");
                            files[idx] = objects[0];
                            double progress = 0;
                            for (KCSFile* progFile in objects) {
                                progress += percentComplete * ((double) thisFile.length / (double) totalBytes);
                            }
                            progressBlock(files,progress);
                        }
                    }];
                }
            }];
        }
    } withProgressBlock:nil];
}

+ (void)downloadFileByName:(id)nameOrNames completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSParameterAssert(nameOrNames != nil);
    NSParameterAssert(completionBlock != nil);
    
    NSArray* names = [NSArray wrapIfNotArray:nameOrNames];
    KCSQuery* nameQuery = [KCSQuery queryOnField:KCSFileFileName usingConditional:kKCSIn forValue:names];
    [self downloadFileByQuery:nameQuery completionBlock:completionBlock progressBlock:progressBlock];
}

+ (void)downloadFile:(id)idOrIds options:(NSDictionary *)options completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSParameterAssert(idOrIds != nil);
    NSParameterAssert(completionBlock != nil);
    
    BOOL idIsString = [idOrIds isKindOfClass:[NSString class]];
    BOOL idIsArray = [idOrIds isKindOfClass:[NSArray class]];

    id filename = (options != nil) ? options[KCSFileFileName] : nil;
    
    if (idIsString || (idIsArray && [idOrIds count] == 1)) {        
        [self _downloadFile:filename fileId:idOrIds options:options completionBlock:completionBlock progressBlock:progressBlock];
    } else if (idIsArray) {
        KCSQuery* idQuery = [KCSQuery queryOnField:KCSFileId usingConditional:kKCSIn forValue:idOrIds];
        [self downloadFileByQuery:idQuery filenames:filename options:options completionBlock:completionBlock progressBlock:progressBlock];
    } else {
        [[NSException exceptionWithName:@"KCSInvalidParameter" reason:@"idOrIds is not single id or array of ids" userInfo:nil] raise];
    }
    
}

+ (void)downloadDataByQuery:(KCSQuery *)query completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSParameterAssert(query != nil);
    NSParameterAssert(completionBlock != nil);

    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection fileMetadataCollection] options:nil];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil != nil) {
            NSError* fileError = [KCSErrorUtilities createError:nil
                                                    description:[NSString stringWithFormat:@"Error downloading file(S), query='%@'", [query description]]
                                                      errorCode:errorOrNil.code
                                                         domain:KCSFileStoreErrorDomain
                                                      requestId:nil
                                                    sourceError:errorOrNil];
            completionBlock(nil, fileError);
        } else {
            if (objectsOrNil == nil || objectsOrNil.count == 0) {
                completionBlock(objectsOrNil, errorOrNil);
                return; //short circuit since there is no work
            }
            
            NSUInteger totalBytes = [[objectsOrNil valueForKeyPath:@"@sum.length"] unsignedIntegerValue];
            NSMutableArray* files = [NSMutableArray arrayWith:objectsOrNil.count copiesOf:[NSNull null]];
            __block NSUInteger completedCount = 0;
            __block NSError* firstError = nil;
            [objectsOrNil enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                KCSFile* thisFile = obj;
                if (thisFile && thisFile.remoteURL) {
                    [self _downloadToData:thisFile.remoteURL fileId:thisFile.fileId filename:thisFile.filename mimeType:thisFile.mimeType completionBlock:^(NSArray *downloadedResources, NSError *error) {
                        if (error != nil && firstError == nil) {
                            firstError = error;
                        }
                        DBAssert(downloadedResources == nil || downloadedResources.count == 1, @"should only get 1 per download");
                        if (downloadedResources != nil && downloadedResources.count > 0) {
                            files[idx] = downloadedResources[0];
                        }
                        if (++completedCount == objectsOrNil.count) {
                            //only call completion when all done
                            completionBlock(files, firstError);
                        }
                    } progressBlock:^(NSArray *objects, double percentComplete) {
                        if (progressBlock != nil) {
                            DBAssert(objects.count == 1, @"should only get 1 per download");
                            files[idx] = objects[0];
                            double progress = 0;
                            for (KCSFile* progFile in objects) {
                                progress += percentComplete * ((double) thisFile.length / (double) totalBytes);
                            }
                            progressBlock(files,progress);
                        }
                    }];
                }
            }];
        }
    } withProgressBlock:nil];
}

+ (void)downloadDataByName:(id)nameOrNames completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSParameterAssert(nameOrNames != nil);
    NSParameterAssert(completionBlock != nil);
    
    NSArray* names = [NSArray wrapIfNotArray:nameOrNames];
    KCSQuery* nameQuery = [KCSQuery queryOnField:KCSFileFileName usingConditional:kKCSIn forValue:names];
    [self downloadDataByQuery:nameQuery completionBlock:completionBlock progressBlock:progressBlock];
}

+ (void)downloadData:(id)idOrIds completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSParameterAssert(idOrIds != nil);
    NSParameterAssert(completionBlock != nil);
    
    BOOL idIsString = [idOrIds isKindOfClass:[NSString class]];
    BOOL idIsArray = [idOrIds isKindOfClass:[NSArray class]];
    
    if (idIsString || (idIsArray && [idOrIds count] == 1)) {
        [self _downloadData:idOrIds completionBlock:completionBlock progressBlock:progressBlock];
    } else if (idIsArray) {
        KCSQuery* idQuery = [KCSQuery queryOnField:KCSFileId usingConditional:kKCSIn forValue:idOrIds];
        [self downloadDataByQuery:idQuery completionBlock:completionBlock progressBlock:progressBlock];
    } else {
        [[NSException exceptionWithName:@"KCSInvalidParameter" reason:@"idOrIds is not single id or array of ids" userInfo:nil] raise];
    }
}

+ (void)downloadFileWithResolvedURL:(NSURL *)url options:(NSDictionary *)options completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSParameterAssert(url);
    NSParameterAssert(completionBlock);
    
    ifNil(options, @{});
    
    NSURL* downloadsDir = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    
    //NOTE: this logic is heavily based on GCS url structure
    NSArray* pathComponents = [url pathComponents];
    NSString* filename = options[KCSFileFileName];
    ifNil(filename, [url lastPathComponent]);
    DBAssert(filename != nil, @"should have a valid filename");
    NSURL* destinationFile = options[KCSFileLocalURL];
    ifNil(destinationFile, [NSURL URLWithString:filename relativeToURL:downloadsDir]);
    NSString* fileId = pathComponents[MAX(pathComponents.count - 2, 1)];
    
    BOOL onlyIfNewer = fieldExistsAndIsYES(options, KCSFileOnlyIfNewer);
    NSNumber* bytes = nil;
    if (fieldExistsAndIsYES(options, KCSFileResume)) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[destinationFile path]] == YES) {
            NSError* error = nil;
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[destinationFile path] error:&error];
            if (error == nil) {
                bytes = attributes[NSFileSize];
            }
        }
    }
    
    
    [self _downloadToFile:destinationFile fromURL:url fileId:fileId filename:filename mimeType:nil onlyIfNewer:onlyIfNewer downloadedBytes:bytes completionBlock:completionBlock progressBlock:progressBlock];
}

+ (void)downloadDataWithResolvedURL:(NSURL *)url completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSParameterAssert(url);
    NSParameterAssert(completionBlock);
    
    [self downloadFileWithResolvedURL:url options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        if (!error && downloadedResources != nil && downloadedResources.count > 0) {
            KCSFile* file = downloadedResources[0];
            NSURL* localFile = file.localURL;
            if ([[NSFileManager defaultManager] fileExistsAtPath:[localFile path]]) {
                NSData* data = [NSData dataWithContentsOfURL:localFile];
                file.data = data;
                NSError* fileError = nil;
                [[NSFileManager defaultManager] removeItemAtPath:[localFile path] error:&fileError];
                if (fileError == nil) {
                    file.localURL = nil;
                } else {
                    NSString* errMessage = [NSString stringWithFormat:@"Error cleaning up file on download data %@", file.localURL];
                    KCSLogNSError(errMessage, fileError);
                }
                completionBlock(@[file], error);
            }
        } else {
            completionBlock(downloadedResources, error);
        }
    } progressBlock:progressBlock];
}

+ (void)resumeDownload:(NSURL *)partialLocalFile from:(NSURL *)resolvedURL completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSParameterAssert(partialLocalFile);
    NSParameterAssert(resolvedURL);
    NSParameterAssert(completionBlock);
    
    [self downloadFileWithResolvedURL:resolvedURL options:@{KCSFileLocalURL : partialLocalFile, KCSFileResume : @(YES)} completionBlock:completionBlock progressBlock:progressBlock];
}

#pragma mark - Streaming
+ (void) getStreamingURL:(NSString *)fileId completionBlock:(KCSFileStreamingURLCompletionBlock)completionBlock
{
    [self getStreamingURL:fileId options:nil completionBlock:completionBlock];
}

+ (void) getStreamingURL:(NSString *)fileId options:(NSDictionary*)options completionBlock:(KCSFileStreamingURLCompletionBlock)completionBlock
{
    NSParameterAssert(fileId != nil);
    NSParameterAssert(completionBlock != nil);
    
    [self _getDownloadObject:fileId options:options intermediateCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil != nil) {
            errorOrNil = [errorOrNil updateDomain:KCSResourceErrorDomain];
            completionBlock(nil, errorOrNil);
        } else {
            if (objectsOrNil.count != 1) {
                KCSLogError(@"returned %u results for file metadata at id '%@'", objectsOrNil.count, fileId);
            }
            
            KCSFile* file = objectsOrNil[0];
            completionBlock(file, nil);
        }
    }];
}

+ (void)getStreamingURLByName:(NSString *)fileName completionBlock:(KCSFileStreamingURLCompletionBlock)completionBlock
{
    NSParameterAssert(fileName != nil);
    NSParameterAssert(completionBlock != nil);

    KCSQuery* nameQuery = [KCSQuery queryOnField:KCSFileFileName withExactMatchForValue:fileName];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection fileMetadataCollection] options:nil];
    [store queryWithQuery:nameQuery withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil != nil) {
            errorOrNil = [errorOrNil updateDomain:KCSResourceErrorDomain];
            completionBlock(nil, errorOrNil);
        } else {
            if (objectsOrNil.count != 1) {
                KCSLogError(@"returned %u results for file metadata with query: %@", objectsOrNil.count, nameQuery);
                errorOrNil = [KCSErrorUtilities createError:nil description:[NSString stringWithFormat:@"No matching file by name: %@", fileName] errorCode:KCSNotFoundError domain:KCSResourceErrorDomain requestId:nil];
                completionBlock(nil, errorOrNil);
            } else {
                completionBlock( objectsOrNil[0], nil);
            }
        }

    } withProgressBlock:nil];
}

#pragma mark - Deletes
+ (void)deleteFile:(NSString *)fileId completionBlock:(KCSCountBlock)completionBlock
{
    NSParameterAssert(fileId != nil);
    NSParameterAssert(completionBlock != nil);
    
    KCSNetworkRequest* request = [[KCSNetworkRequest alloc] init];
    request.httpMethod = kKCSRESTMethodDELETE;
    request.contextRoot = kKCSContextBLOB;
    request.pathComponents = @[fileId];
    
    request.authorization = [KCSUser activeUser];
    request.body = @{};
    
    [request run:^(id results, NSError *error) {
        if (error != nil){
            error = [KCSErrorUtilities createError:nil
                                       description:[NSString stringWithFormat:@"Error Deleting file, id='%@'", fileId]
                                         errorCode:error.code
                                            domain:KCSFileStoreErrorDomain
                                         requestId:nil
                                       sourceError:error];
            completionBlock(0, error);
        } else {
            completionBlock([results[@"count"] unsignedLongValue], nil);
        }
    }];
}

#pragma mark - for Linked Data

+ (void)uploadKCSFile:(KCSFile *)file options:(NSDictionary*)options completionBlock:(KCSFileUploadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    NSMutableDictionary* newOptions = [NSMutableDictionary dictionaryWithDictionary:options];
    setIfValNotNil(newOptions[KCSFileMimeType], file.mimeType);
    setIfValNotNil(newOptions[KCSFileFileName], file.filename);
    setIfValNotNil(newOptions[KCSFileId], file.fileId);
    setIfValNotNil(newOptions[KCSFileACL], file.metadata);
    setIfValNotNil(newOptions[kGCSULID], file.gcsULID);
    
    if (file.data != nil) {
        [self uploadData:file.data options:newOptions completionBlock:completionBlock progressBlock:progressBlock];
    } else if (file.localURL != nil) {
        [self uploadFile:file.localURL options:newOptions completionBlock:completionBlock progressBlock:progressBlock];
    } else {
        [[NSException exceptionWithName:@"KCSFileStoreInvalidParameter" reason:@"Input file did not specify a data or local URL value" userInfo:nil] raise];
    }
}


+ (void)downloadKCSFile:(KCSFile*) file completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock) progressBlock
{
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    setIfValNotNil(options[KCSFileMimeType], file.mimeType);
    setIfValNotNil(options[KCSFileFileName], file.filename);
    setIfValNotNil(options[KCSFileId], file.fileId);
    setIfValNotNil(options[KCSFileFileName], file.filename);
    if (file.length > 0) {
        setIfValNotNil(options[KCSFileSize], @(file.length));
    }
    
    if (file.localURL) {
        if (file.fileId) {
            [self downloadFile:file.fileId options:options completionBlock:completionBlock progressBlock:progressBlock];
        } else {
            [self downloadFileByName:file.filename completionBlock:completionBlock progressBlock:progressBlock];
        }
    } else {
        if (file.fileId) {
            [self downloadData:file.fileId completionBlock:completionBlock progressBlock:progressBlock];
        } else {
            [self downloadDataByName:file.filename completionBlock:completionBlock progressBlock:progressBlock];
        }
    }
}

#pragma mark - test Helpers

#if BUILD_FOR_UNIT_TEST
+ (id) lastRequest
{
    return lastRequest;
}
#endif

@end

#pragma mark - Helpers

@implementation KCSCollection (KCSFileStore)
NSString* const KCSFileStoreCollectionName = @"_blob";

+ (instancetype)fileMetadataCollection
{
    return [KCSCollection collectionFromString:@"_blob" ofClass:[KCSFile class]];
}

@end

