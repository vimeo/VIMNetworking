#
#  Be sure to run `pod spec lint VIMNetworking.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "VIMNetworking"
  s.version      = "5.5"
  s.summary      = "The Vimeo iOS SDK"
  s.description  = <<-DESC
                   VIMNetworking is an Objective-C library that enables interaction with the Vimeo API. It handles authentication, request submission and cancellation, and video upload. Advanced features include caching and powerful model object parsing.
                   DESC

  s.homepage     = "https://github.com/vimeo/VIMNetworking"
  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }

  s.authors            = { "Alfie Hanssen" => "alfiehanssen@gmail.com" }
  s.social_media_url   = "http://twitter.com/vimeo"

  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/vimeo/VIMNetworking.git", :tag => s.version.to_s }
  s.source_files  = "VIMNetworking", "VIMNetworking/**/*.{h,m}"
  s.exclude_files = "VIMNetworking/Exclude"

  s.frameworks = "Foundation"
  s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }

  s.subspec 'AFNetworking' do |ss|
    ss.dependency	'AFNetworking', '~> 2.5.4'
  end

  s.subspec 'VIMObjectMapper' do |ss|
    ss.dependency	'VIMObjectMapper', '~> 5.4.2'
  end

end
