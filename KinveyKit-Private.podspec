Pod::Spec.new do |spec|
  spec.name         = 'KinveyKit'
  spec.version      = '1.40.5'
  spec.source       = { :git => 'git@github.com:Kinvey/ios-library.git' }
	spec.ios.deployment_target = '7.0'
	spec.requires_arc = true
	spec.pod_target_xcconfig = {
		'GCC_PRECOMPILE_PREFIX_HEADER' => 'YES'
	}
	spec.prefix_header_file = 'KinveyKit/KinveyKit/KinveyKit-Prefix.pch'
  spec.source_files = [
		'KinveyKit/KinveyKit/**/*.{h,m}',
		'KinveyKit/KinveyKitExtras/**/*.{h,m}'
	]
	spec.exclude_files = [
		'KinveyKit/KinveyKit/3rdParty/fmdb/fmdb.{h,m}',
		'KinveyKit/KinveyKitExtras/KCSWebView.m',
		'KinveyKit/KinveyKitExtras/TestUtils.{h,m}'
	]
	spec.public_header_files = [
		'KinveyKit/KinveyKit/KinveyKit.h',
		'KinveyKit/KinveyKit/Source/KCSClient.h',
		'KinveyKit/KinveyKit/KinveyHeaderInfo.h',
		'KinveyKit/KinveyKit/Source/KCSRequestConfiguration.h',
		'KinveyKit/KinveyKit/Source/KCSClientConfiguration.h',
		'KinveyKit/KinveyKit/Source/KinveyPing.h',
		'KinveyKit/KinveyKit/Source/KinveyPersistable.h',
		'KinveyKit/KinveyKit/Source/KCSEntityDict.h',
		'KinveyKit/KinveyKit/Source/KCSPush.h',
		'KinveyKit/KinveyKit/Source/KCSUserActionResult.h',
		'KinveyKit/KinveyKit/Source/KinveyUser.h',
		'KinveyKit/KinveyKit/Source/KCSUser2+KinveyUserService.h',
		'KinveyKit/KinveyKit/Source/KCSUserDiscovery.h',
		'KinveyKit/KinveyKit/Source/KCSQuery.h',
		'KinveyKit/KinveyKit/Source/KCSQuery2.h',
		'KinveyKit/KinveyKit/Source/KCSRequest.h',
		'KinveyKit/KinveyKit/Source/KCSStore.h',
		'KinveyKit/KinveyKit/Source/KinveyEntity.h',
		'KinveyKit/KinveyKit/Source/KCSUser2.h',
		'KinveyKit/KinveyKit/Source/KCSBackgroundAppdataStore.h',
		'KinveyKit/KinveyKit/Source/KCSAppdataStore.h',
		'KinveyKit/KinveyKit/Source/KCSLinkedAppdataStore.h',
		'KinveyKit/KinveyKit/Source/KCSDataStore.h',
		'KinveyKit/KinveyKit/Source/KCSCachedStore.h',
		'KinveyKit/KinveyKit/Source/KCSFile.h',
		'KinveyKit/KinveyKit/Source/KCSFileStore.h',
		'KinveyKit/KinveyKit/Source/KCSBlockDefs.h',
		'KinveyKit/KinveyKit/Source/KinveyBlocks.h',
		'KinveyKit/KinveyKit/Source/KCSCacheUpdatePolicy.h',
		'KinveyKit/KinveyKit/Source/KCSMetadata.h',
		'KinveyKit/KinveyKit/Source/KinveyCollection.h',
		'KinveyKit/KinveyKit/Source/KCSGroup.h',
		'KinveyKit/KinveyKit/Source/KCSReduceFunction.h',
		'KinveyKit/KinveyKit/Source/KCSLogSink.h',
		'KinveyKit/KinveyKit/Source/KCSOfflineUpdateDelegate.h',
		'KinveyKit/KinveyKit/Source/CLLocation+Kinvey.h',
		'KinveyKit/KinveyKit/Source/KCSClient+KinveyDataStore.h',
		'KinveyKit/KinveyKit/Source/KCSCustomEndpoints.h',
		'KinveyKit/KinveyKitExtras/KCSFacebookHelper.h',
		'KinveyKit/KinveyKitExtras/KCSUser+SocialExtras.h',
		'KinveyKit/KinveyKitExtras/KCSWebView.h',
		'KinveyKit/KinveyKit/3rdParty/Reachability/KCSReachability.h',
		'KinveyKit/KinveyKit/Source/KCSURLProtocol.h',
		'KinveyKit/KinveyKit/Source/KinveyErrorCodes.h',
		'KinveyKit/KinveyKit/Source/NSString+KinveyAdditions.h',
		'KinveyKit/KinveyKit/Source/NSURL+KinveyAdditions.h',
		'KinveyKit/KinveyKit/KinveyVersion.h'
	]
  spec.framework = 'SystemConfiguration'
	spec.library = 'sqlite3'
end
