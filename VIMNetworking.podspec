Pod::Spec.new do |s|

  s.name         = "VIMNetworking"
  s.version      = "5.6.1.12"
  s.summary      = "The Vimeo iOS SDK"
  s.description  = <<-DESC
                   VIMNetworking is an Objective-C library that enables interaction with the Vimeo API. It handles authentication, request submission and cancellation, and video upload. Advanced features include caching and powerful model object parsing.
                   DESC

  s.homepage     = "https://github.com/vimeo/VIMNetworking"
  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }

  s.authors            = { "Alfie Hanssen" => "alfiehanssen@gmail.com",
                            "Rob Huebner" => "robh@vimeo.com",
                            "Gavin King" => "gavin@vimeo.com",
                            "Kashif Muhammad" => "support@vimeo.com",
                            "Andrew Whitcomb" => "support@vimeo.com",
                            "Stephen Fredieu" => "support@vimeo.com",
                            "Rahul Kumar" => "support@vimeo.com" }

  s.social_media_url   = "http://twitter.com/vimeo"

  s.platform     = :ios, "7.0"

  s.requires_arc = true
  s.source = { :git => "https://github.com/vimeo/VIMNetworking.git", :tag => s.version.to_s }

  s.source_files = 'VIMNetworking/VIMNetworking.h'
  s.frameworks = 'Foundation'

  s.subspec 'Networking' do |ss|
    ss.source_files = 'VIMNetworking/Networking/**/*.{h,m}'
    ss.frameworks = 'Foundation', 'UIKit'
    ss.dependency 'VIMNetworking/Cache'
    ss.dependency 'VIMNetworking/Keychain'
    ss.dependency 'VIMNetworking/Model'
    ss.dependency 'VIMNetworking/Private'
    ss.dependency 'AFNetworking'
  end

  s.subspec 'Private' do |ss|
    ss.source_files = 'VIMNetworking/Private/**/*.{h,m}'
    ss.frameworks = 'Foundation', 'UIKit'
    ss.dependency 'VIMNetworking/Model'
  end

  s.subspec 'Cache' do |ss|
    ss.source_files = 'VIMNetworking/Cache/VIMCache.{h,m}'
    ss.frameworks = 'Foundation', 'UIKit'
  end

  s.subspec 'Keychain' do |ss|
    ss.source_files = 'VIMNetworking/Keychain/VIMKeychain.{h,m}'
    ss.frameworks = 'Foundation', 'Security'
  end

  s.subspec 'Model' do |ss|
    ss.source_files = 'VIMNetworking/Model/*.{h,m}'
    ss.frameworks = 'Foundation', 'CoreGraphics', 'AVFoundation'
    ss.dependency	'VIMObjectMapper'
  end

  s.subspec 'AFNetworking' do |ss|
    ss.dependency	'AFNetworking', '2.6.3'
  end

  s.subspec 'VIMObjectMapper' do |ss|
    ss.dependency	'VIMObjectMapper', '5.6.1.1'
  end

end
