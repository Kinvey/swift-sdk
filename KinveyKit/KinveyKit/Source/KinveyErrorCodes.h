//
//  KinveyErrorCodes.h
//  KinveyKit
//
//  Created by Brian Wilson on 1/10/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#ifndef KinveyKit_KinveyErrorCodes_h
#define KinveyKit_KinveyErrorCodes_h

// Error Domains
#define KCSNetworkErrorDomain @"KCSNetworkErrorDomain"
#define KCSAppDataErrorDomain @"KCSAppDataErrorDomain"
#define KCSResourceErrorDomain @"KCSResourceErrorDomain"
#define KCSUserErrorDomain @"KCSUserErrorDomain"
#define KCSPushErrorDomain @"KCSPushErrorDomain"
#define KCSErrorDomain @"KCSErrorDomain"

// Error Codes
enum {
    // Error Codes Based on HTTP
    KCSBadRequestError = 400,
    KCSDeniedError = 401,
    KCSForbiddenError = 403,
    KCSNotFoundError = 404,
    KCSBadMethodError = 405,
    KCSNoneAcceptableError = 406,
    KCSProxyAuthRequiredError = 407,
    KCSRequestTimeoutError = 408,
    KCSConflictError = 409,
    KCSGoneError = 410,
    KCSLengthRequiredError = 411,
    KCSPrecondFailedError = 412,
    KCSRequestTooLargeError = 413,
    KCSUriTooLongError = 414,
    KCSUnsupportedMediaError = 415,
    KCSRetryWithError = 449,
    KCSServerErrorError = 500,
    KCSNotSupportedError = 501,
    KCSBadGatewayError = 502,
    KCSServiceUnavailableError = 503,
    KCSGatewayTimeoutError = 504,
    KCSVersionNotSupporteError = 505,
    
    
    // Internal Library Codes (starting at 60000)
    KCSUnderlyingNetworkConnectionCreationFailureError = 60000,
    KCSNetworkUnreachableError = 60001,
    KCSKinveyUnreachableError = 60002,
    KCSUserCreationContentionTimeoutError = 60003,
    KCSUnexpectedResultFromServerError = 60004,
    KCSAuthenticationRetryError = 60005,
    KCSUserAlreadyLoggedInError = 60006,
    KCSUserAlreadyExistsError = 60007,
    KCSOperationREquiresCurrentUserError = 60008,
    KCSLoginFailureError = 60009,
    KCSUnexpectedError = 60010,
    KCSFileError = 60011,
    KCSInvalidArgumentError = 60012,
    
    
    // For testing only, no user should ever see this!
    KCSTestingError = 65535
    
};



#endif
