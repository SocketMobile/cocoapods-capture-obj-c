Pod::Spec.new do |s|
  s.name         = "SKTCaptureObjC"
  s.version      = "1.3.60"
  s.summary      = "Capture SDK Objective C for Socket Mobile wireless devices."
  s.homepage     = "https://www.socketmobile.com"
  s.license      = { :type => "COMMERCIAL", :file => "LICENSE" }
  s.author       = { "Socket" => "developers@socketmobile.com" }
  s.documentation_url   = "https://docs.socketmobile.com/capture/ios/en/latest/"
  s.platform     = :ios, "10.0"
  s.source       = {
      :git => "https://github.com/SocketMobile/cocoapods-capture-obj-c.git",
      :tag => "1.3.60"
  }
  s.ios.deployment_target = "10.0"
  s.source_files  = "**/*.{h,m,mm}"

  s.public_header_files = "**/*.h"
  
  s.static_framework = true

  s.resources = "*.{wav,pem}"
  s.ios.vendored_frameworks = "lib/SKTCapture.xcframework"
  s.ios.libraries = "c++","icucore"
  s.frameworks = "ExternalAccessory", "AudioToolbox", "AVFoundation", "CoreBluetooth"
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
end
