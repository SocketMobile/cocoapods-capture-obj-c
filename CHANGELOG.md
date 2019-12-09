# Change Log
This file tracks released versions with the changes made to this project.
## [Version 1.1.380](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.1.380)
### New
* Added an optional mainBundle parameter to check the application contains the "com.socketmobile.chs" string in its Info.plist. This is necessary for connecting to Socket Mobile barcode readers.
## [Version 1.1.372](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.1.372)
### New
  * Now compatibile with iOS 13.0

### Bug fixes
  * Fixed bug with switching the RFID data format between Tag-Type-And-ID and Tag-Type-And-Data
  
## [Version 1.1.351](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.1.351)
### New
  * Added new DotCode symbology
  * Converted symbologies to dataSources to accomodate D600

### Improvements
  * D600 Data Store supported

### Bug fixes
  * n/a

## [Version 1.1.286](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.1.286)
### New
  * compiled with Xcode 10.2.1

  * CaptureHelper and CaptureHelperDevice have now generic getProperty, setProperty methods that could be use for the Capture properties that don't have already a method in CaptureHelper or CaptureHelperDevice

### Improvements
  * Add a generic get/set properties in CaptureHelper and CaptureHelperDevice so it is easy to extend these classes and it simplifies the code too

  * Empty buffer in iAP protocol when some partial data are received

### Bug fixes
  * Fix the openWithAppInfo that uses to call twice the block in case of failure

  * Fix the partial decoded data occurring on some scanners when scanning long barcode before the scanner beeps when it is ready

  * Fix the failure to reconnect to the scanner when asking the battery status as soon as the scanner connects

  * Increase the timeout in Capture Service Direct, to be bigger than the Capture property timeout

  * Check if the main capture reference is not nil and neither is its devices list

## [Version 1.1.148](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.1.148)
### New
  * Add a device type for the S840

  * Add a Dispatch Queue property in CaptureHelper to keep the code simpler when handling
  UI modification in a completion handler.

  * Add a Get and Set Data Format for D600

  * Add a None state in SKTCaptureButtonsState

### Improvements
  * Make sure there is no pending requests for a device when closing Capture

  * Prevent Auto-Discovery when D600 disconnects while closing Capture

  * Disconnect the D600 when closing Capture

### Bug fixes
  * Fix the warning: non-portable path to file "SktCapture.h"

  * Fix a crash that occurred sometimes when setting or getting a device property

## [Version 1.1.33](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.1.33)
### New
  n/a
### Improvements
  n/a
### Bug fixes
  * Fix the previous release 1.1.31 where the armv7 and arm64 architecture were missing

## [Version 1.1.31](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.1.31)
### New
  n/a
### Improvements
  Officially build with Xcode 10
### Bug fixes
  * Fix the button notifications that were always reporting a 0 as value for buttons pressed

## [Version 1.1.24](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.1.24)
### New
  n/a
### Improvements
  * CaptureHelper pushDelegate and popDelegate now returns a boolean when the
    delegate has been added or removed respectively.

### Bug fixes
  * Fix D600 reading of the Local Decode Action property, when the default has not changed.

## [Version 1.1.6](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.1.6)
### New
  * D600 support for data format (Tag ID or NDEF Data)

  * D600 API for connected and disconnected timeout support

  * D600 API for stand configuration

  * D600 API for UI controls (BEEP, LED†, VIBRATE)
    † the LED is not fully operational on D600.

  * D600 API for device specific command. A firmware command can be sent
    directly through Capture API

### Improvements
  * Add a trace if the application is missing the Socket Mobile device protocol string

  * Add stability of using D600 by adding a separate event when sending and confirming
    a D600 command.

### Bug fixes
  * Fix the BLE misused API, the device manager presence follows the Bluetooth radio state

  * Fix D600 reading tag data that are longer than 19 bytes

## [Version 1.0.341](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.0.341)
### New
  * Added new Socket product types

### Improvements
  * Compiled with Xcode 9.4.

  * Better handling when opening and closing Capture multiple times.

### Bug fixes
  * Fix the 10s delay when closing Capture while a scanner is connected.

## [Version 1.0.151](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.0.151)
### New
n/a

### Improvements
  * Move the Capture.xml config file out of the application Documents folder.

### Bug fixes
  * Fix crash occurring when cancelling the pairing of a D600.

## [Version 1.0.117](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.0.117)
### New
n/a

### Improvements
  * Replace AppInfo.BundleID by AppInfo.AppID, because the AppID is the platforms
  prefix followed by a colon and by the App Bundle ID. ie: "ios.com.mycompany.myapp".

  * Compiled with Xcode 9.3.

  * Better AppKey verification handling various size of App Keys.

### Bug fixes
  * Fix the multiple decoded data when using SoftScan.

  * Fix the scanner long reconnection time.

## [Version 1.0.67](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.0.67)
### New
n/a

### Improvements
n/a
### Bug fixes
  * Fix the AppKey crash when opening the Capture SDK.

## [Version 1.0.65](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.0.65)
### New
n/a

### Improvements
n/a
### Bug fixes
  * Fix the ESKT_LISTEMPTY (-6) error when getting the BLE Device Manager favorites

  * Add notification of already connected devices when pushing a delegate

## [Version 1.0.61](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.0.61)
### New
n/a

### Improvements
n/a
### Bug fixes
  * Fix a crash when closing Capture

## [Version 1.0.32](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.0.32)
### New
n/a

### Improvements
n/a
### Bug fixes
* Fix the AppKey verification

* Fix the inline comment to display correctly in Xcode help

* Fix a bug when enabling SoftScan at the same than enabling/disabling D600
support.

* Apply the correct singleton pattern in Capture Helper.

## [Version 1.0.0](https://github.com/SocketMobile/cocoapods-capture-obj-c/releases/tag/1.0.0)
### New
  * Initial release

### Improvements
n/a
### Bug fixes
n/a
