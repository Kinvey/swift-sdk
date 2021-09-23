#
#  Be sure to run `pod spec lint Kinvey.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "Kinvey"
  s.version      = "6.0.0"
  s.summary      = "Kinvey iOS SDK"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
	Kinvey iOS SDK #{s.version}
                   DESC

  s.homepage     = "https://devcenter.kinvey.com/ios/guides/getting-started"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  s.license      = { :type => 'Copyright', :text => " Copyright (c) 2021, Kinvey, Inc. All rights reserved.\n \n This software is licensed to you under the Kinvey terms of service located at\n http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this\n software, you hereby accept such terms of service  (and any agreement referenced\n therein) and agree that you have read, understand and agree to be bound by such\n terms of service and are of legal age to agree to such terms with Kinvey.\n \n This software contains valuable confidential and proprietary information of\n KINVEY, INC and is subject to applicable licensing agreements.\n Unauthorized reproduction, transmission or distribution of this file and its\n contents is a violation of applicable laws.\n" }
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author             = "Kinvey, Inc."
  # Or just: s.author    = "Victor Barros"
  # s.authors            = { "Victor Barros" => "victor@kinvey.com" }
  s.social_media_url   = "http://twitter.com/Kinvey"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # s.platform     = :ios, "9.0"

  #  When using multiple platforms
  s.ios.deployment_target = "11.0"
  s.osx.deployment_target = "10.12"
  s.tvos.deployment_target = "11.0"
  s.watchos.deployment_target = "4.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/Kinvey/swift-sdk.git",
                     :tag => "#{s.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = "Kinvey/Kinvey/**/*.{swift,h,m,mm}", "Carthage/Checkouts/NSPredicate-MongoDB-Adaptor/Sources/MongoDBPredicateAdaptor/*.{swift}"

  # s.public_header_files =

  # s.private_header_files =

  # s.exclude_files =

  # s.prefix_header_file =


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  s.preserve_paths = "Kinvey/**", "KinveyKit/**", "Carthage/**"
  # s.prepare_command = ""
  # s.ios.vendored_frameworks = "Kinvey-#{s.version}/Kinvey.framework"

  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  s.frameworks = "CoreGraphics", "CoreLocation", "Security"
  s.ios.frameworks = "MobileCoreServices", "WebKit"

  # s.libraries =


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  s.requires_arc = true

  s.swift_version = '5.2'

  s.dependency "PromiseKit", "~> 6.0"
  s.dependency "KeychainAccess", "~> 4.0"
  s.dependency "Realm", "~> 10.0"
  s.dependency "RealmSwift", "~> 10.0"
  s.dependency "ObjectMapper", "~> 4.0"
  s.dependency "SwiftyBeaver", "~> 1.0"
  s.dependency "PubNub", "~> 4.0"

end
