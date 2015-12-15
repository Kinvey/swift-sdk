#
# Be sure to run `pod lib lint KinveyKit.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "KinveyKit"
  s.version          = "1.40.2"
  s.summary          = "Kinvey iOS SDK"
  s.description      = "Kinvey provides a robust backend for your mobile apps by providing features that enable you to build amazing apps without worrying about your backend. Currently Kinvey provides the following services:\n\n* __appdata__ — A query-able key/value (and more) data storage platform for your app\n* __Resources__ — A storage system for your media content (images, videos, files, etc.) that provides out of the box Content Distribution Network (CDN) capabilities.\n* __Users__ — Keep track of users of your application and control access to data on a user-by-user basis\n* __Push Notifications__ — Our partnership with Urban Airship gives you awesome push features without the headache of managing them yourself.\n* __Location-Aware Queries__ — Query your data for entities that are near other entities.\n\nFor more details on how to use these features read the [Kinvey Service Overview](http://docs.kinvey.com/service-overview.html).\n"
  s.homepage         = "http://devcenter.kinvey.com/ios/guides/getting-started"
  s.license          = { :type => 'Copyright', :text => " Copyright (c) 2014, Kinvey, Inc. All rights reserved.\n \n This software is licensed to you under the Kinvey terms of service located at\n http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this\n software, you hereby accept such terms of service  (and any agreement referenced\n therein) and agree that you have read, understand and agree to be bound by such\n terms of service and are of legal age to agree to such terms with Kinvey.\n \n This software contains valuable confidential and proprietary information of\n KINVEY, INC and is subject to applicable licensing agreements.\n Unauthorized reproduction, transmission or distribution of this file and its\n contents is a violation of applicable laws.\n" }
  s.author           = "Kinvey, Inc."
  s.source           = { :http => "http://download.kinvey.com/iOS/KinveyKit-#{s.version}.zip" }
  s.social_media_url = 'http://twitter.com/Kinvey'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.preserve_paths = "**"
  s.prepare_command = <<-CMD
      cp KinveyKit.framework/KinveyKit libKinveyKit.a
      mkdir -p include/KinveyKit
      cp KinveyKit.framework/Headers/* include/KinveyKit
    CMD
  s.vendored_libraries = "libKinveyKit.a"
  s.public_header_files = "include/KinveyKit/*.h"
  s.frameworks = 'Accounts', 'CoreGraphics', 'CoreLocation', 'MobileCoreServices', 'Security', 'Social', 'SystemConfiguration'
  s.weak_framework = 'WebKit'
  s.libraries = 'sqlite3'
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-ObjC', 'HEADER_SEARCH_PATHS' => "KinveyKit-#{s.version}/include" }
end
