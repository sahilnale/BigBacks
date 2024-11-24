#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AWSCore.h"
#import "AWSCredentialsProvider.h"
#import "AWSIdentityProvider.h"
#import "AWSSignature.h"
#import "AWSCognitoIdentity.h"
#import "AWSCognitoIdentityModel.h"
#import "AWSCognitoIdentityService.h"
#import "AWSMobileAnalytics.h"
#import "AWSMobileAnalyticsAppleMonetizationEventBuilder.h"
#import "AWSMobileAnalyticsConfiguration.h"
#import "AWSMobileAnalyticsEvent.h"
#import "AWSMobileAnalyticsEventClient.h"
#import "AWSMobileAnalyticsMonetizationEventBuilder.h"
#import "AWSMobileAnalyticsOptions.h"
#import "AWSMobileAnalyticsVirtualMonetizationEventBuilder.h"
#import "MobileAnalytics.h"
#import "AWSMobileAnalyticsERS.h"
#import "AWSMobileAnalyticsERSModel.h"
#import "AWSMobileAnalyticsERSService.h"
#import "AWSNetworking.h"
#import "AWSURLSessionManager.h"
#import "AWSSerialization.h"
#import "AWSURLRequestRetryHandler.h"
#import "AWSURLRequestSerialization.h"
#import "AWSURLResponseSerialization.h"
#import "AWSValidation.h"
#import "AWSClientContext.h"
#import "AWSService.h"
#import "AWSServiceEnum.h"
#import "AWSSTS.h"
#import "AWSSTSModel.h"
#import "AWSSTSService.h"
#import "AWSCategory.h"
#import "AWSLogging.h"
#import "AWSModel.h"
#import "AWSSynchronizedMutableDictionary.h"
#import "AWSXMLWriter.h"

FOUNDATION_EXPORT double AWSCoreVersionNumber;
FOUNDATION_EXPORT const unsigned char AWSCoreVersionString[];

