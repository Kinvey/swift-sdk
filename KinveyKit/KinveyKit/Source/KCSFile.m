//
//  KCSFile.m
//  KinveyKit
//
//  Created by Michael Katz on 5/29/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//


#import "KCSFile.h"

#import "KCSFileStore.h"

#import "KCSImageUtils.h"
#import "NSString+KinveyAdditions.h"

#define kTypeResourceValue @"resource"
#define kImageMimeType @"image/png"

@interface KCSFile ()
@property (nonatomic, retain) NSString* refType;
@property (nonatomic, retain) NSURL* localURL;
@property (nonatomic, retain) NSURL* remoteURL;
@property (nonatomic, retain) NSData* data;
@property (nonatomic, retain) NSDate* expirationDate;
@property (nonatomic, retain) id resolvedObject;
@property (nonatomic, retain) Class valClass;
@property (nonatomic, copy) NSString* gcsULID;
@end

@implementation KCSFile

#pragma mark -

- (instancetype)initWithData:(NSData *)data fileId:(NSString*)fileId filename:(NSString*)filename mimeType:(NSString*)mimeType
{
    NSParameterAssert(data != nil);
    self = [super init];
    if (self) {
        _data = data;
        _length = [data length];
        _fileId = fileId;
        _filename = filename;
        _mimeType = mimeType;
    }
    return self;
}

- (instancetype)initWithLocalFile:(NSURL *)localURL fileId:(NSString*)fileId filename:(NSString*)filename mimeType:(NSString*)mimeType
{
    NSParameterAssert(localURL != nil);
    self = [super init];
    if (self) {
        _localURL = localURL;
        _fileId = fileId;
        _filename = filename;
        _mimeType = mimeType;
    }
    return self;
}

+ (instancetype) fileRef:(id)objectToRef collectionIdProperty:(NSString*)idStr
{
    KCSFile* file;
    if ([objectToRef isKindOfClass:[KCSFile class]]) {
        file = objectToRef;
    } else {
        file = [[self alloc] init];
    }
    
    if ([objectToRef isKindOfClass:[NSURL class]]) {
        file.localURL = (NSURL*)objectToRef;
        file.filename = [objectToRef lastPathComponent];
    } else if ([objectToRef isKindOfClass:[ImageClass class]]) {
        //UI(NS)Image -> id/filename : collection-entityid-property.png > hash -> image/png
        file.mimeType = kImageMimeType;
        file.data = [KCSImageUtils dataFromImage:(ImageClass*)objectToRef];
        file.filename = [[NSString UUID] stringByAppendingPathExtension:@"png"];
    } else if ([objectToRef isKindOfClass:[NSData class]]) {
        file.data = objectToRef;
        file.filename = [NSString UUID];
    }
    
    file.refType = @"KinveyFile";
    file.resolvedObject = objectToRef;
    file.valClass = [objectToRef class];
    ifNil(file.fileId, idStr);

    return file;
}

+ (instancetype) fileRefFromKinvey:(NSDictionary*)kinveyDict class:(Class)klass;
{
    KCSFile* file = [[KCSFile alloc] init];
    file.fileId = kinveyDict[KCSEntityKeyId];
    file.mimeType = kinveyDict[KCSFileMimeType];
    file.filename = kinveyDict[KCSFileFileName];
    file.length = [kinveyDict[KCSFileSize] unsignedIntegerValue];
    NSString* url = kinveyDict[@"_downloadURL"];
    ifNil(url, kinveyDict[@"_uploadURL"]);
    file.remoteURL = url ? [NSURL URLWithString:url] : nil;

    file.expirationDate = kinveyDict[@"_expiresAt"];
    file.refType = kinveyDict[@"_type"];
    if ([file.refType isEqualToString:kTypeResourceValue]) {
        file.filename = kinveyDict[@"_loc"];
        file.mimeType = kinveyDict[@"_mime-type"];
    }
    file.valClass = klass;
    return file;
}

#pragma mark - kinvey
- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{ @"fileId" : KCSEntityKeyId,
              @"mimeType" : KCSFileMimeType,
              @"filename" : KCSFileFileName,
              @"remoteURL" : @"_downloadURL",
              @"remoteURL" : @"_uploadURL",
              @"length" : @"size",
              @"metadata" : KCSEntityKeyMetadata,
              @"expirationDate" : @"_expiresAt",
              @"refType" : @"_type",
              @"publicFile" : @"_public"
             };
}

- (id) proxyForJson
{
    return @{@"_type" : @"KinveyFile", KCSFileId : _fileId};
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[NSDictionary class]]) {
        object = [[self class] fileRefFromKinvey:object class:nil];
    }
    if ([object isKindOfClass:[self class]] == NO) {
        return NO;
    }
    if (_refType && [_refType isEqualToString:kTypeResourceValue]) {
        return [_refType isEqualToString:[object refType]] && [_filename
                                                               isEqualToString:[object filename]];
    }
    return [_fileId isEqualToString:[object fileId]];
}

- (NSUInteger)hash
{
    if (_refType && [_refType isEqualToString:kTypeResourceValue]) {
        return [_filename hash];
    }
    return [_fileId hash];
}

- (void) updateAfterUpload:(KCSFile*)newFile
{
    _fileId = newFile.fileId;
    _filename = newFile.filename;
    _mimeType = newFile.mimeType;
    _length = newFile.length;
}

#pragma mark - objects

- (id)resolvedObject
{
    if (_resolvedObject) {
        return _resolvedObject;
    }

    if (_data == nil && _localURL != nil) {
        _data = [NSData dataWithContentsOfURL:_localURL];
    }
    
    if ((_valClass && [_valClass isSubclassOfClass:[ImageClass class]]) || (_mimeType != nil && [_mimeType hasPrefix:@"image"]) ) {
        _resolvedObject = [KCSImageUtils imageWithData:_data];
    } else {
        _resolvedObject = _data;
    }
    
    return _resolvedObject;
}

#pragma mark - properties

- (NSNumber *)public
{
    return self.publicFile;
}

- (void)setPublic:(NSNumber *)public
{
    self.publicFile = public;
}

#pragma mark - debug

- (NSString*) debugDescription
{
    NSString* descr = [NSString stringWithFormat:@"%@ [Data from file: '%@' (id: '%@', length: %u)]", [super debugDescription], _filename, _fileId, _length];
    if (_localURL == nil && _data == nil && _remoteURL == nil) {
        descr = [NSString stringWithFormat:@"%@ [Uploaded file id: '%@', (filename: '%@', mime-type:'%@', length: %u)]", [super debugDescription], _fileId, _filename, _mimeType, _length];
    } else if (_localURL == nil && _data == nil) {
        descr = [NSString stringWithFormat:@"%@ [Remote file (id: '%@', length: %u) url: '%@' / expires: '%@']", [super debugDescription], _fileId, _length, _remoteURL, _expirationDate];
    } else if (_localURL != nil) {
        descr = [NSString stringWithFormat:@"%@ [Locally cached file '%@' (id: '%@', length: %u)]", [super debugDescription], _localURL, _fileId, _length];
    } else if (_data != nil) {
        descr = [NSString stringWithFormat:@"%@ [Upload data '%@' (id: '%@', data-length: %u)]", [super debugDescription], _localURL, _fileId, _data.length];
    }
    return descr;
}
@end
