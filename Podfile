workspace 'VIMNetworking'
xcodeproj 'VIMNetworkingFramework/VIMNetworkingFramework.xcodeproj'
xcodeproj 'VIMNetworkingLibrary/VIMNetworkingLibrary.xcodeproj'

platform :ios, '8.0'

def shared_pods
    use_frameworks!
    pod 'AFNetworking', '2.6.3'
end

target 'VIMNetworkingLibrary' do
    shared_pods
    xcodeproj 'VIMNetworkingLibrary/VIMNetworkingLibrary.xcodeproj'
end

target 'VIMNetworkingFramework' do
    shared_pods
    xcodeproj 'VIMNetworkingFramework/VIMNetworkingFramework.xcodeproj'
end

