/*
 
 File: Reachability.m
 Abstract: Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 
 Version: 2.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
*/

#import "CusomizeReachability.h"

#define kShouldPrintReachabilityFlags 1

static void PrintReachabilityFlags(SCNetworkReachabilityFlags    flags, const char* comment)
{
#if kShouldPrintReachabilityFlags
	
    NSLog(@"Reachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n",
			(flags & kSCNetworkReachabilityFlagsIsWWAN)				  ? 'W' : '-',
			(flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
			
			(flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
			(flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
			(flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
			(flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
			(flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
			(flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
			(flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-',
			comment
			);
#endif
}


@implementation CusomizeReachability
static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
	#pragma unused (target, flags)
	NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
	NSCAssert([(__bridge NSObject*) info isKindOfClass: [CusomizeReachability class]], @"info was wrong class in ReachabilityCallback");

	//We're on the main RunLoop, so an NSAutoreleasePool is not necessary, but is added defensively
	// in case someon uses the Reachablity object in a different thread.
    @autoreleasepool {
        
        CusomizeReachability *noteObject = (__bridge CusomizeReachability *) info;
        // Post a notification to notify the client that the network reachability changed.
        [[NSNotificationCenter defaultCenter] postNotificationName: kReachabilityChangedNotification object: noteObject];
    }
}

- (BOOL) startNotifier
{
	BOOL retVal = NO;
	SCNetworkReachabilityContext	context = {0, (__bridge void *)(self), NULL, NULL, NULL};
	if (SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context)) {
		if(SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
			retVal = YES;
		}
	}
	return retVal;
}

- (void) stopNotifier
{
	if (reachabilityRef!= NULL) {
		SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	}
}

- (void) dealloc
{
	[self stopNotifier];
	if (reachabilityRef!= NULL)
	{
		CFRelease(reachabilityRef);
	}
}

+ (CusomizeReachability*) reachabilityWithHostName: (NSString*) hostName;
{
	CusomizeReachability* retVal = NULL;
	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
	if (reachability != NULL) {
		retVal = [[[self class] alloc] init];
		if (retVal) {
			retVal->reachabilityRef = reachability;
			retVal->localWiFiRef = NO;
		}
	}
	return retVal;
}

+ (CusomizeReachability*) reachabilityWithAddress: (const struct sockaddr_in*) hostAddress;
{
	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)hostAddress);
	CusomizeReachability* retVal = NULL;
	if (reachability != NULL) {
		retVal = [[[self class] alloc] init];
		if (retVal) {
			retVal->reachabilityRef = reachability;
			retVal->localWiFiRef = NO;
		}
	}
	return retVal;
}

+ (CusomizeReachability*) reachabilityForInternetConnection;
{
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
	return [self reachabilityWithAddress: &zeroAddress];
}

+ (CusomizeReachability*) reachabilityForLocalWiFi;
{
	struct sockaddr_in localWifiAddress;
	bzero(&localWifiAddress, sizeof(localWifiAddress));
	localWifiAddress.sin_len = sizeof(localWifiAddress);
	localWifiAddress.sin_family = AF_INET;
	// IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
	localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
	CusomizeReachability *retVal = [self reachabilityWithAddress: &localWifiAddress];
	if (retVal) {
		retVal->localWiFiRef = YES;
	}
	return retVal;
}

#pragma mark Network Flag Handling

- (NetworkStatus) localWiFiStatusForFlags: (SCNetworkReachabilityFlags) flags
{
	PrintReachabilityFlags(flags, "localWiFiStatusForFlags");

	BOOL retVal = NotReachable;
	if((flags & kSCNetworkReachabilityFlagsReachable) && (flags & kSCNetworkReachabilityFlagsIsDirect))
	{
		retVal = ReachableViaWiFi;	
	}
	return retVal;
}

- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags
{
	PrintReachabilityFlags(flags, "networkStatusForFlags");
	if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
	{
		// if target host is not reachable
		return NotReachable;
	}

	BOOL retVal = NotReachable;
	
	if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
	{
		// if target host is reachable and no connection is required
		//  then we'll assume (for now) that your on Wi-Fi
		retVal = ReachableViaWiFi;
	}
	
	
	if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
		(flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
	{
			// ... and the connection is on-demand (or on-traffic) if the
			//     calling application is using the CFSocketStream or higher APIs

			if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
			{
				// ... and no [user] intervention is needed
				retVal = ReachableViaWiFi;
			}
		}
	
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
	{
		// ... but WWAN connections are OK if the calling application
		//     is using the CFNetwork (CFSocketStream?) APIs.
		retVal = ReachableViaWWAN;
	}
	return retVal;
}

- (BOOL) connectionRequired;
{
	NSAssert(reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
	{
		return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
	}
	return NO;
}

- (NetworkStatus) currentReachabilityStatus
{
	NSAssert(reachabilityRef != NULL, @"currentNetworkStatus called with NULL reachabilityRef");
	NetworkStatus retVal = NotReachable;
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
	{
		if(localWiFiRef)
		{
			retVal = [self localWiFiStatusForFlags: flags];
		}
		else
		{
			retVal = [self networkStatusForFlags: flags];
		}
	}
	return retVal;
}

@end

@interface ReachabilityAutoChecker : NSObject
@property (nonatomic, retain) CusomizeReachability      *reachability;
@property (nonatomic, assign) NetworkStatus             networkStatus;
@property (nonatomic, assign) BOOL                      connectionRequired;
@end

@implementation ReachabilityAutoChecker
@synthesize reachability;

+ (id)sharedChecker
{
    static __strong ReachabilityAutoChecker *staticChecker = nil;
    if (!staticChecker) {
        staticChecker = [[ReachabilityAutoChecker alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:staticChecker selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        staticChecker.networkStatus = NotReachable;
        staticChecker.connectionRequired = NO;
    }
    return staticChecker;
}

- (void)reachabilityChanged:(NSNotification* )note
{
	CusomizeReachability *curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [CusomizeReachability class]]);
    self.networkStatus = [curReach currentReachabilityStatus];
    self.connectionRequired = [curReach connectionRequired];
}

@end

@implementation CusomizeReachability (AutoChecker)

+ (void)startCheckWithReachability:(CusomizeReachability *)reachability
{
    ReachabilityAutoChecker *checker = [ReachabilityAutoChecker sharedChecker];
    
    if (checker.reachability) {
        [checker.reachability stopNotifier];
        checker.reachability = nil;
    }
    
    checker.reachability = reachability;
    [checker.reachability startNotifier];
}

+ (BOOL)isReachable
{
    ReachabilityAutoChecker *checker = [ReachabilityAutoChecker sharedChecker];
    
    if (!checker.reachability) {
        NSLog(@"Check Reachability With No Reachability has been Set!");
        return NO;
    }
    
    NetworkStatus networkStatus = [checker networkStatus];
    BOOL connectionRequired = NO;
    connectionRequired = [checker connectionRequired];
    
#if kShouldPrintReachabilityFlags
    NSLog(@"NetworkStatus %d connectionRequired %d", networkStatus, connectionRequired);
#endif
    
    if (networkStatus)
        return YES;
    else
        return NO;
}

@end
