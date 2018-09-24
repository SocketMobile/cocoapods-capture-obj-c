Pod::Spec.new do |s|
  s.name         = "SKTCaptureObjC"
  s.version      = "1.1.6"
  s.summary      = "Capture SDK Objective C for Socket Mobile wireless devices."
  s.homepage     = "http://www.socketmobile.com"
  s.license      = { :type => "COMMERCIAL", :file => "LICENSE" }
  s.author       = { "Socket" => "developers@socketmobile.com" }
  s.documentation_url   = "http://docs.socketmobile.com/capture/ios/en/latest/"
  s.platform     = :ios, "8.0"
  s.source       = {
      :git => "https://github.com/SocketMobile/cocoapods-capture-obj-c.git",
      :tag => "1.1.6"
  }
  s.ios.deployment_target = "8.0"
  s.source_files  = "**/*.{h,m,mm}"
  # s.source_files  = "**/*.h"
  s.public_header_files = "*.h"
  s.preserve_path = "**/*.a"
  s.resources = "*.{wav,pem}"
  s.ios.vendored_libraries = "lib/libCaptureCore.a", "lib/libCaptureServiceDirect.a"
  s.ios.libraries = "c++","icucore"
  s.frameworks = "ExternalAccessory", "AudioToolbox", "AVFoundation", "CoreBluetooth"
end
