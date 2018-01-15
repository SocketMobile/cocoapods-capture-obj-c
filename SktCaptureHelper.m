//
//  SKTCaptureHelper.m
//
//
//  © Copyright 2017, Socket Mobile, Inc.
//
//

#import "SktCaptureHelper.h"

@interface SKTCaptureHelperDevice()
@property SKTCapture* captureDevice;
@end

@interface SKTCaptureHelper() <SKTCaptureDelegate>
@end

@implementation SKTCaptureHelper {
    NSArray* _delegatesStack;
    id<SKTCaptureHelperDelegate> _currentDelegate;
    SKTCapture* _capture;
    bool _softScanPending;
    bool _softScanTrigger;
    NSArray* _devices;
    NSArray* _deviceManagers;
}

/**
 * instantiate a capture helper for the entire app
 * @return a unique capture helper instance
 */
+(instancetype) sharedInstance{
    static SKTCaptureHelper* capture = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        capture = [SKTCaptureHelper new];
    });
    return capture;
}

/**
 * push a delegate in the delegates stack. The last delegate
 * being pushed is the one receiving the notification.
 *
 * If the delegate on top of the stack is the same as the delegate
 * it will added like if it was a different delegate.
 */
-(void)pushDelegate:(id<SKTCaptureHelperDelegate>) delegate{
    NSMutableArray* stack;
    if(_currentDelegate != delegate){
        if(_delegatesStack == nil){
            stack = [NSMutableArray new];
        }
        else{
            stack = [[NSMutableArray alloc]initWithArray:_delegatesStack];
        }
        [stack addObject:delegate];
        _currentDelegate = delegate;
        _delegatesStack = stack;
        stack = nil;
    }
    // whatever view is pushed, it means SoftScan
    // is no longer pending
    _softScanPending = false;
    _softScanTrigger = false;
}

/**
 * pop a delegate from the delegates stack. The last delegate
 * being pushed is the first one to be pop out the stack if it
 * matches the delegate passed in argument.
 *
 * If it does not match with delegate provided in argument
 * then nothing happen.
 */
-(void)popDelegate:(id<SKTCaptureHelperDelegate>) delegate{
    NSMutableArray* stack;
    if(_currentDelegate == delegate){
        // if SoftScan has been triggered then
        // SoftScan is now pending
        // If SoftScan is pending the current view
        // controller delegate should not be removed from
        // the delegates stack so it can still receive
        // the SoftScan decoded data
        if(_softScanTrigger == true){
            _softScanPending = true;
        }
        _softScanTrigger = false;
        if(_softScanPending == false){
            if(_delegatesStack == nil){
                stack = [NSMutableArray new];
            }
            else{
                stack = [[NSMutableArray alloc]initWithArray:_delegatesStack];
            }
            NSInteger count = _delegatesStack.count;
            if(count > 0){
                id<SKTCaptureHelperDelegate> newDelegate = [stack objectAtIndex:count -1];
                [stack removeLastObject];
                _currentDelegate = newDelegate;
                if(count - 1 >0){
                    _delegatesStack = stack;
                }
                else {
                    _delegatesStack = nil;
                }
                stack = nil;
            }
            else{
                _currentDelegate = nil;
            }
        }
    }
}

/**
 *
 * Open Capture for this app by providing the App information.
 *
 * The app must be registered on Socket Mobile developer portal
 * in order to get a AppKey matching to the application.
 *
 * @param appInfo contains the app information with the AppKey to
 * validate the access to this API.
 * @param block called upon completion of opening capture with the
 * result code
 */
-(void)openWithAppInfo:(SKTAppInfo*)appInfo completionHandler:(void(^)(SKTResult result)) block{
    if (_capture == nil ){
        _capture = [SKTCapture new];
        [_capture setDelegate:self];
        [_capture openWithAppInfo:appInfo completionHandler:^(SKTResult result) {
            if(block != nil){
                block(result);
            }
            if(!SKTSUCCESS(result)) {
                _capture = nil;
            }
        }];
    } else {
        if(block != nil){
            block(SKTCaptureE_NOERROR);
        }
    }
}


/**
 * Close capture when the application needs to free some resources.
 *
 * @param block called upon completion of closing capture with the
 * result code
 */
-(void)closeWithCompletionHandler:(void(^)(SKTResult result)) block{
    if (_capture != nil) {
        [_capture closeWithCompletionHandler:^(SKTResult result) {
            if(block != nil){
                block(result);
            }
        }];
        _capture = nil;
    } else {
        if(block != nil){
            block(SKTCaptureE_NOERROR);
        }
    }
}


/**
 * Return the actual list of connected devices. This is mostly useful
 * when displaying somewhere the devices that are actually connected to
 * the host.
 * @returns the list of devices
 */
-(NSArray*)getDevicesList {
    return _devices;
}

/**
 * retrieve the Capture version
 *
 * @param block called upon completion of getting the Capture version
 * with the result and the version as argument.
 */
-(void)getVersionWithCompletionHandler:(void(^)(SKTResult result, SKTCaptureVersion* version)) block{
    if(_capture != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDVersion;
        property.Type = SKTCapturePropertyTypeNone;
        [_capture getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            SKTCaptureVersion* version = nil;
            if(SKTSUCCESS(result)){
                version = complete.Version;
            }
            if(block != nil){
                block(result, version);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, nil);
        }
    }
}

/**
 * retrieve the confirmation mode used to configure how the decoded data
 * are confirmed.
 *
 * @param block called upon completion of getting the confirmation mode
 * with the result and the confirmation mode as argument.
 */
-(void)getConfirmationModeWithCompletionHandler:(void(^)(SKTResult result, SKTCaptureDataConfirmation confirmationMode)) block{
    if(_capture != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDDataConfirmationMode;
        property.Type = SKTCapturePropertyTypeNone;
        [_capture getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            SKTCaptureDataConfirmation confirmation = SKTCaptureDataConfirmationModeOff;
            if(SKTSUCCESS(result)){
                confirmation = complete.ByteValue;
            }
            if(block != nil){
                block(result, confirmation);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, SKTCaptureDataConfirmationModeOff);
        }
    }
}

/**
 * set the confirmation mode to define how the decoded data should be confirmed.
 *
 * @param block called upon completion of setting the confirmation mode
 * with the result of setting the confirmation mode.
 */
-(void)setConfirmationMode:(SKTCaptureDataConfirmation)confirmationMode completionHandler:(void(^)(SKTResult result)) block{
    if(_capture != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDDataConfirmationMode;
        property.Type = SKTCapturePropertyTypeByte;
        property.ByteValue = confirmationMode;
        [_capture setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}

/**
 * retrieve the SoftScan (Scanning using the host camera) status. The status could
 * be "not supported", "supported", "disabled" and "enabled".
 *
 * @param block called upon completion of getting the SoftScan status with
 * result and SoftScan status as argument.
 */
-(void)getSoftScanStatusWithConfirmationHandler: (void(^)(SKTResult result, SKTCaptureSoftScan status)) block{
    if(_capture != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDSoftScanStatus;
        property.Type = SKTCapturePropertyTypeNone;
        [_capture getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            SKTCaptureSoftScan status = SKTCaptureSoftScanNotSupported;
            if(SKTSUCCESS(result)){
                status = complete.ByteValue;
            }
            if(block != nil){
                block(result, status);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, SKTCaptureSoftScanNotSupported);
        }
    }
}

/**
 * set the SoftScan (Scanning using the host camera) status. The status could
 * be "not supported", "supported", "disabled" and "enabled".
 *
 * @param status contains the new SoftScan status.
 * @param block called upon completion of setting the SoftScan status with the
 * result as argument.
 */
-(void)setSoftScanStatus:(SKTCaptureSoftScan) status completionHandler:(void(^)(SKTResult result)) block{
    if(_capture != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDSoftScanStatus;
        property.Type = SKTCapturePropertyTypeByte;
        property.ByteValue = status;
        [_capture setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}
#pragma mark - Utility methods
+(SKTCaptureHelperDevice*)retrieveDeviceFromCaptureDevice:(SKTCapture*)capture fromList:(NSArray*) devices {
    SKTCaptureHelperDevice* device = nil;
    if(devices!=nil){
        for (SKTCaptureHelperDevice* dev in devices) {
            if(dev.captureDevice == capture){
                device = dev;
                break;
            }
        }
    }
    return device;
}

#pragma mark - Capture Event Delegate
-(void)didReceiveEvent:(SKTCaptureEvent *)event forCapture:(SKTCapture *)capture withResult:(SKTResult)result {
    switch(event.ID){
        case SKTCaptureEventIDNotInitialized:
            break;
        case SKTCaptureEventIDError:
        {
            if(_currentDelegate!=nil){
                if([_currentDelegate respondsToSelector:@selector(didReceiveError:withMessage:)] == TRUE){
                    [_currentDelegate didReceiveError:result withMessage:event.Data.StringValue];
                }
            }
        }
            break;
        case SKTCaptureEventIDPower:
        {
            SKTCaptureHelperDevice* device = [SKTCaptureHelper retrieveDeviceFromCaptureDevice:capture fromList:_devices];
            if(_currentDelegate!=nil){
                if([_currentDelegate respondsToSelector:@selector(didChangePowerState:forDevice:)] == TRUE){
                    [_currentDelegate didChangePowerState:event.Data.ULongValue forDevice:device];
                }
            }
        }
            break;
        case SKTCaptureEventIDButtons:
        {
            SKTCaptureHelperDevice* device = [SKTCaptureHelper retrieveDeviceFromCaptureDevice:capture fromList:_devices];
            if(_currentDelegate!=nil){
                if([_currentDelegate respondsToSelector:@selector(didChangeButtonsState:forDevice:)] == TRUE){
                    [_currentDelegate didChangeButtonsState:event.Data.ULongValue forDevice:device];
                }
            }
        }
            break;
        case SKTCaptureEventIDTerminate:
        {
            if(_currentDelegate!=nil){
                if([_currentDelegate respondsToSelector:@selector(didTerminateWithResult:)] == TRUE){
                    [_currentDelegate didTerminateWithResult:result];
                }
            }
        }
            break;
        case SKTCaptureEventIDDecodedData:
        {
            SKTCaptureHelperDevice* device = [SKTCaptureHelper retrieveDeviceFromCaptureDevice:capture fromList:_devices];
            if(_currentDelegate!=nil){
                if([_currentDelegate respondsToSelector:@selector(didReceiveDecodedData:fromDevice:withResult:)] == TRUE){
                    [_currentDelegate didReceiveDecodedData:event.Data.DecodedData fromDevice:device withResult:result];
                }
            }
        }
            break;
        case SKTCaptureEventIDBatteryLevel:
        {
            SKTCaptureHelperDevice* device = [SKTCaptureHelper retrieveDeviceFromCaptureDevice:capture fromList:_devices];
            if(_currentDelegate!=nil){
                if([_currentDelegate respondsToSelector:@selector(didChangeBatteryLevel:forDevice:withResult:)] == TRUE){
                    [_currentDelegate didChangeBatteryLevel:(long)event.Data.ULongValue forDevice:device withResult:result];
                }
            }
        }
            break;
        case SKTCaptureEventIDDeviceArrival:
        {
            SKTCaptureHelperDevice* device = [[SKTCaptureHelperDevice alloc] initWithDeviceInfo:event.Data.DeviceInfo];

            [_capture openDeviceWithGuid:device.guid completionHandler:^(SKTResult result, SKTCapture *deviceCapture) {
                if(SKTSUCCESS(result)){
                    device.captureDevice = deviceCapture;
                    NSMutableArray* devices;
                    @synchronized (self) {
                        if(_devices != nil){
                            devices = [[NSMutableArray alloc] initWithArray:_devices];
                        } else {
                            devices = [NSMutableArray new];
                        }
                        [devices addObject:device];
                        _devices = devices;
                    }
                    devices = nil;
                }
                if(_currentDelegate != nil){
                    if([_currentDelegate respondsToSelector:@selector(didNotifyArrivalForDevice:withResult:)] == TRUE){
                        [_currentDelegate didNotifyArrivalForDevice:device withResult:result];
                    }
                }
            }];
        }
            break;
        case SKTCaptureEventIDDeviceRemoval:
        {
            NSMutableArray* devices;
            //__block SKTCaptureHelperDevice* removedDevice;
            SKTCaptureHelperDevice* removedDevice;
            SKTCaptureDeviceInfo* deviceInfo;
            deviceInfo = event.Data.DeviceInfo;
            if(_devices != nil){
                @synchronized (self) {
                    devices = [[NSMutableArray alloc] initWithArray:_devices];
                    NSInteger index = 0;
                    for (SKTCaptureHelperDevice* actual in devices) {
                        if([actual.guid compare:deviceInfo.Guid] == NSOrderedSame){
                            removedDevice = [devices objectAtIndex:index];
                            [devices removeObjectAtIndex:index];
                            break;
                        }
                        index += 1;
                    }
                    if(devices.count > 0){
                        _devices = devices;
                    }
                    else {
                        _devices = nil;
                    }
                }
                devices = nil;
                [removedDevice.captureDevice closeWithCompletionHandler:^(SKTResult result) {
                    if(_currentDelegate != nil){
                        if([_currentDelegate respondsToSelector:@selector(didNotifyRemovalForDevice:withResult:)] == TRUE){
                            [_currentDelegate didNotifyRemovalForDevice:removedDevice withResult:result];
                        }
                    }
                    //removedDevice = nil;
                }];
            }
        }
            break;
        case SKTCaptureEventIDDeviceManagerArrival:
        {
            SKTCaptureHelperDeviceManager* deviceManager = [[SKTCaptureHelperDeviceManager alloc] initWithDeviceInfo:event.Data.DeviceInfo];

            [_capture openDeviceWithGuid:deviceManager.guid completionHandler:^(SKTResult result, SKTCapture *deviceCapture) {
                deviceManager.captureDevice = deviceCapture;
                if(SKTSUCCESS(result)){
                    NSMutableArray* deviceManagers;
                    if(_deviceManagers !=  nil){
                        deviceManagers = [[NSMutableArray alloc] initWithArray:_deviceManagers];
                    }
                    else {
                        deviceManagers = [NSMutableArray new];
                    }
                    [deviceManagers addObject:deviceManager];
                    _deviceManagers = deviceManagers;
                    deviceManagers = nil;
                }
                if(_currentDelegate!=nil){
                    if([_currentDelegate respondsToSelector:@selector(didNotifyArrivalForDeviceManager:withResult:)] == TRUE){
                        [_currentDelegate didNotifyArrivalForDeviceManager:deviceManager withResult:result];
                    }
                }
            }];
        }
            break;
        case SKTCaptureEventIDDeviceManagerRemoval:
        {
            NSMutableArray* deviceManagers;
            //__block SKTCaptureHelperDeviceManager* removedDeviceManager;
            SKTCaptureHelperDeviceManager* removedDeviceManager;
            SKTCaptureDeviceInfo* deviceInfo;
            deviceInfo = event.Data.DeviceInfo;
            if(_deviceManagers != nil){
                deviceManagers = [[NSMutableArray alloc] initWithArray:_deviceManagers];
                NSInteger index = 0;
                for (SKTCaptureHelperDevice* actual in _deviceManagers) {
                    if([actual.guid isEqualToString: deviceInfo.Guid]){
                        removedDeviceManager = [deviceManagers objectAtIndex:index];
                        [deviceManagers removeObjectAtIndex:index];
                        break;
                    }
                    index += 1;
                }
                if(deviceManagers.count>0){
                    _deviceManagers = deviceManagers;
                }
                else{
                    _deviceManagers = nil;
                }
                deviceManagers = nil;
                if(removedDeviceManager != nil){
                    [removedDeviceManager.captureDevice closeWithCompletionHandler:^(SKTResult result) {
                        if(_currentDelegate != nil){
                            if([_currentDelegate respondsToSelector:@selector(didNotifyRemovalForDeviceManager:withResult:)] == TRUE){
                                [_currentDelegate didNotifyRemovalForDeviceManager:removedDeviceManager withResult:result];
                            }
                        }
                    }];
                }
            }
        }
            break;
        case SKTCaptureEventIDDeviceOwnership:
            // in iOS there is no device Ownership for now,
            // since Capture is not really a service like
            // on the other platforms
            break;
        case SKTCaptureEventIDListenerStarted:
            if(_currentDelegate!=nil){
                if([_currentDelegate respondsToSelector:@selector(listenerDidStart)] == TRUE){
                    [_currentDelegate listenerDidStart];
                }
            }
            break;
        case SKTCaptureEventIDDeviceDiscovered:
        {
            SKTCaptureHelperDeviceManager* deviceManager = (SKTCaptureHelperDeviceManager*)[SKTCaptureHelper retrieveDeviceFromCaptureDevice:capture fromList:_deviceManagers];
            if(_currentDelegate!=nil){
                if([_currentDelegate respondsToSelector:@selector(didDiscoverDevice:fromDeviceManager:)] == TRUE){
                    [_currentDelegate didDiscoverDevice:event.Data.StringValue fromDeviceManager:deviceManager];
                }
            }
        }
            break;
        case SKTCaptureEventIDDiscoveryEnd:
        {
            SKTCaptureHelperDeviceManager* deviceManager = (SKTCaptureHelperDeviceManager*)[SKTCaptureHelper retrieveDeviceFromCaptureDevice:capture fromList:_deviceManagers];
            if(_currentDelegate!=nil){
                if([_currentDelegate respondsToSelector:@selector(didDiscoveryEndWithResult:fromDeviceManager:)] == TRUE){
                    [_currentDelegate didDiscoveryEndWithResult:event.Data.ULongValue fromDeviceManager:deviceManager];
                }
            }
        }
            break;
        case SKTCaptureEventIDLastID:
            break;
    }
}
@end

#pragma mark - SKTCaptureHelperDevice

@implementation SKTCaptureHelperDevice {
    SKTCaptureDeviceInfo* _deviceInfo;
}

#pragma mark - Initialization
-(instancetype)initWithDeviceInfo:(SKTCaptureDeviceInfo*) deviceInfo{
    self = [super init];
    if(self != nil){
        _deviceInfo = deviceInfo;
        _friendlyName = deviceInfo.Name;
        _deviceType = deviceInfo.DeviceType;
        _guid = deviceInfo.Guid;
    }
    return self;
}

#pragma mark - Device Information
/**
 *  retrieve the device friendly name
 *
 *  @param block receiving the response with the result and the friendly name of
 *  the device if the result is successful
 */
-(void)getFriendlyNameWithCompletionHandler:(void(^)(SKTResult result, NSString* name)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDFriendlyNameDevice;
        property.Type = SKTCapturePropertyTypeNone;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result, complete.StringValue);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, nil);
        }
    }
}

/**
 *  set the device friendly name. The device friendly name has a limit of
 *  32 UTF8 characters including the null terminated character, an error is
 *  generated if the friendly name is too long.
 *
 *  @param name friendly name to set the device with
 *  @param block receiving the result of setting the new friendly name
 */
-(void)setFriendlyName:(NSString*) name completionHandler:(void(^)(SKTResult result)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDFriendlyNameDevice;
        property.Type = SKTCapturePropertyTypeString;
        property.StringValue = name;
        [_captureDevice setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}

/**
 * get the device Bluetooth address
 *
 *  @param block receiving the result of getting the device Bluetooth Address if the result
 *  is successful
 */
-(void)getBluetoothAddressWithCompletionHandler:(void(^)(SKTResult result, NSArray* address)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDBluetoothAddressDevice;
        property.Type = SKTCapturePropertyTypeNone;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:complete.ArrayValue];
                block(result, array);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, nil);
        }
    }
}

/**
 * get the device Type
 *
 *  @param block receiving the result and the device Type if the result is successful
 */
-(void)getTypeWithCompletionHandler:(void(^)(SKTResult result, SKTCaptureDeviceType deviceType)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDDeviceType;
        property.Type = SKTCapturePropertyTypeNone;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result, (SKTCaptureDeviceType)complete.ULongValue);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, (SKTCaptureDeviceType)0);
        }
    }
}

/**
 * get the device Firmware version
 *
 *  @param block receiving the result and the device Firmware version if the result is successful
 */
-(void)getFirmwareVersionWithCompletionHandler:(void(^)(SKTResult result, SKTCaptureVersion* version)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDVersionDevice;
        property.Type = SKTCapturePropertyTypeNone;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result, complete.Version);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, nil);
        }
    }
}

/**
 * get the device battery level
 *
 * NOTE: to avoid pulling the battery level, some devices support a battery level change
 * notification.
 *
 *  @param block receiving the result and the device battery level if the result is successful
 */
-(void)getBatteryLevelWithCompletionHandler:(void(^)(SKTResult result, NSInteger levelInPercentage)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDBatteryLevelDevice;
        property.Type = SKTCapturePropertyTypeNone;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                NSInteger level = 0;
                level = [SKTHelper getCurrentLevelFromBatteryLevel:complete.ULongValue];
                block(result, level);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, 0);
        }
    }
}

/**
 * get the device power state
 *
 * NOTE: to avoid pulling the power state, some devices support a power state change
 * notification.
 *
 *  @param block receiving the result and the device power state if the result is successful
 */
-(void)getPowerStateWithCompletionHandler:(void(^)(SKTResult result, SKTCapturePowerState powerState)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDPowerStateDevice;
        property.Type = SKTCapturePropertyTypeNone;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result, (SKTCapturePowerState)complete.ULongValue);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, (SKTCapturePowerState)0);
        }
    }
}


/**
 * get the device buttons state
 *
 * NOTE: some devices support buttons state change notifications
 *
 *  @param block receiving the result and the device buttons state if the result is successful
 */
-(void)getButtonsStateWithCompletionHandler:(void(^)(SKTResult result, SKTCaptureButtonsState buttonsState)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDButtonsStatusDevice;
        property.Type = SKTCapturePropertyTypeNone;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result, (SKTCaptureButtonsState)complete.ULongValue);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, (SKTCaptureButtonsState)0);
        }
    }
}

#pragma mark - Behaviour Configuration

/**
 * get the device stand configuration
 *
 *  @param block receiving the result and the device stand configuration if the result is successful
 */
-(void)getStandConfigWithCompletionHandler:(void(^)(SKTResult result, SKTCaptureStandConfig config)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDStandConfigDevice;
        property.Type = SKTCapturePropertyTypeNone;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result, (SKTCaptureStandConfig)complete.ULongValue);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, SKTCaptureStandConfigMobileMode);
        }
    }
}

/**
 * set the device stand configuration
 *
 *  @param config stand configuration to set the device with
 *  @param block receiving the result of changing the device stand configuration
 */
-(void)setStandConfig:(SKTCaptureStandConfig)config completionHandler:(void(^)(SKTResult result)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDStandConfigDevice;
        property.Type = SKTCapturePropertyTypeUlong;
        property.ULongValue = (long)config;
        [_captureDevice setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}

/**
 * get the device decode action
 *
 *  @param block receiving the result and the device decode action if the result is successful
 */
-(void)getDecodeActionWithCompletionHandler:(void(^)(SKTResult result, SKTCaptureLocalDecodeAction decodeAction)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDLocalDecodeActionDevice;
        property.Type = SKTCapturePropertyTypeNone;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                SKTCaptureLocalDecodeAction action = (SKTCaptureLocalDecodeAction)complete.ByteValue;
                block(result, action);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, 0);
        }
    }
}

/**
 * set the device decode action
 *
 *  @param decodeAction decode action to set the device with
 *  @param block receiving the result of changing the device decode action
 */
-(void)setDecodeAction:(SKTCaptureLocalDecodeAction)decodeAction completionHandler:(void(^)(SKTResult result)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDLocalDecodeActionDevice;
        property.Type = SKTCapturePropertyTypeByte;
        property.ByteValue = decodeAction;
        [_captureDevice setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}

/**
 * get the device local data acknowledgment
 *
 *  @param block receiving the result and the device local acknowledgment if the result is successful
 */
-(void)getDataAcknowledgmentWithCompletionHandler:(void(^)(SKTResult result, SKTCaptureDeviceDataAcknowledgment dataAcknowledgment)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDDataConfirmationDevice;
        property.Type = SKTCapturePropertyTypeNone;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result, complete.ULongValue);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, 0);
        }
    }
}

/**
 * set the device local data acknowledgment
 *
 *  @param dataAcknowledgment set how the device acknwoledges data locally on the device
 *  @param block receiving the result of changing the device stand configuration
 */
-(void)setDataAcknowledgment:(SKTCaptureDeviceDataAcknowledgment)dataAcknowledgment completionHandler:(void(^)(SKTResult result)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDLocalAcknowledgmentDevice;
        property.Type = SKTCapturePropertyTypeByte;
        property.ByteValue = dataAcknowledgment;
        [_captureDevice setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}

#pragma mark - Decoded Data

/**
 * get the device postamble
 *
 *  @param block receiving the result and the device postamble if the result is successful
 */
-(void)getPostambleWithCompletionHandler:(void(^)(SKTResult result, NSString* postamble)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDPostambleDevice;
        property.Type = SKTCapturePropertyTypeNone;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result, complete.StringValue);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, nil);
        }
    }
}

/**
 * set the device postamble
 *
 *  @param postamble postamble to set the device with
 *  @param block receiving the result of changing the device postamble
 */
-(void)setPostamble:(NSString*) postamble completionHandler:(void(^)(SKTResult result)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDPostambleDevice;
        property.Type = SKTCapturePropertyTypeString;
        property.StringValue = postamble;
        [_captureDevice setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}

/**
 * get the device data source information
 *
 * @param block receiving the result and the device data source information if the result is successful
 */
-(void)getDataSourceInfo:(SKTCaptureDataSourceID) dataSourceId completionHandler:(void(^)(SKTResult result, SKTCaptureDataSource* dataSource)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDDataSourceDevice;
        property.Type = SKTCapturePropertyTypeDataSource;
        property.DataSource = [SKTCaptureDataSource new];
        property.DataSource.ID = dataSourceId;
        property.DataSource.Flags = SKTCaptureDataSourceFlagsStatus;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result, complete.DataSource);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, nil);
        }
    }
}

/**
 * set the device data source
 *
 * @param dataSource data source to enable or disable
 * @param block receiving the result of changing the device data source
 */
-(void)setDataSourceInfo:(SKTCaptureDataSource*) dataSource completionHandler:(void(^)(SKTResult result)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDDataSourceDevice;
        property.Type = SKTCapturePropertyTypeDataSource;
        property.DataSource = [SKTCaptureDataSource new];
        property.DataSource.ID = dataSource.ID;
        property.DataSource.Flags = dataSource.Flags;
        property.DataSource.Status = dataSource.Status;
        [_captureDevice setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}

/**
 * set the device trigger
 *
 * this operation can programmatically starts a device read operation, or it can
 * disable the device trigger button until it gets re-enable again by using this
 * function too.
 *
 * @param trigger contains the command to apply
 * @param block receiving the result of setting the trigger
 */
-(void)setTrigger:(SKTCaptureTrigger)trigger completionHandler:(void(^)(SKTResult result)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDTriggerDevice;
        property.Type = SKTCapturePropertyTypeByte;
        property.ByteValue = trigger;
        [_captureDevice setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}

/**
 * set the decoded data confirmation
 *
 * This function is required to acknowledge the decoded data that has been received
 * when the data confirmation mode has been set to SKTCaptureDataConfirmationModeApp
 *
 * This function could also be called at any point of time if something needs to
 * be reported to the user. By example making the scanner beep or vibrate to get
 * the user to look at a screen.
 *
 * NOTE: Good AND Bad settings can not be used together.
 *
 * @param led contains the led to light (None, Green, Red)
 * @param beep contains the beep to perform (None, Good, Bad)
 * @param rumble contains the rumble to perform (None, Good, Bad)
 * @param block receiving the result of setting the trigger
 */
-(void)setDataConfirmationWithLed:(SKTCaptureDataConfirmationLed) led withBeep:(SKTCaptureDataConfirmationBeep) beep withRumble:(SKTCaptureDataConfirmationRumble) rumble completionHandler:(void(^)(SKTResult result)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDDataConfirmationDevice;
        property.Type = SKTCapturePropertyTypeUlong;
        property.ULongValue = [SKTHelper getDataComfirmationWithReserve:0 withRumble:rumble withBeep:beep withLed:led];
        [_captureDevice setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}

#pragma mark - Notifications

/**
 * set the device notifications
 *
 * @param notifications select the notifications to receive
 * @param block receiving the result of setting the notifications
 */
-(void)setNotifications:(SKTCaptureNotifications)notifications completionHandler:(void(^)(SKTResult result)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDNotificationsDevice;
        property.Type = SKTCapturePropertyTypeUlong;
        property.ULongValue = (long)notifications;
        [_captureDevice setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}

/**
 * get the device notifications selection
 *
 * @param block receiving the result and the device notifications setting if the result is successful
 */
-(void)getNotificationsWithCompletionHandler:(void(^)(SKTResult result, SKTCaptureNotifications notifications)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDNotificationsDevice;
        property.Type = SKTCapturePropertyTypeNone;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result, (SKTCaptureNotifications)complete.ULongValue);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, (SKTCaptureNotifications)0);
        }
    }
}

#pragma mark - Advanced Commands

/**
 * send a specific command to the device
 *
 * These commands are specific to a device, therefore the device should first be identified
 * before sending such commands otherwise an unpredicable result could happen if they are
 * sent to a different device.
 *
 * @param command an array of bytes that holds the specific command to send to the device
 * @param block receiving the result and the device specific command response if the result is successful
 */
-(void)getDeviceSpecificCommand:(NSData*) command completionHandler:(void(^)(SKTResult result, NSData* commandResult)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDDeviceSpecific;
        property.Type = SKTCapturePropertyTypeArray;
        property.ArrayValue = command;
        [_captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result, complete.ArrayValue);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, nil);
        }
    }
}

#pragma mark - SoftScan (scanner using Camera)
/**
 * set the device overlay view
 *
 * @param overlay overlay settings
 * @param block receiving the result of setting the overlay view
 */
-(void)setOverlayView:(NSDictionary*)overlay completionHandler:(void(^)(SKTResult result)) block{
    if(_captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDOverlayViewDevice;
        property.Type = SKTCapturePropertyTypeObject;
        property.Object = overlay;
        [_captureDevice setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}

@end

#pragma mark - SKTCaptureHelperDeviceManager

@implementation SKTCaptureHelperDeviceManager
/**
 * start a discovery of devices manages by this manager (BLE)
 *
 * The discovery starts immediately and this method returns also immediately
 * with the result in the block function.
 *
 * If there are some devices around a
 * @param timeInMilliseconds contains the number of milliseconds the discovery should last
 * @param block receiving the result of starting the discovery
 */
-(void) startDiscoveryWithTimeout:(NSInteger) timeInMilliseconds completionHandler:(void(^)(SKTResult result)) block{
    if(self.captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDStartDiscovery;
        property.Type = SKTCapturePropertyTypeUlong;
        property.ULongValue = timeInMilliseconds;
        [self.captureDevice setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}

/**
 * set the favorites for the auto connection. If favorites are set, the DeviceManager
 * tries to discover BLE device (only looking for Socket D600 device) and try to connect
 * to the one matching to the favorite information
 *
 * @param favorites contains the D600 peripheral identifier (UUID) semi-colon separated
 * in case there are more than one device to connect to
 * @param block called when the favorites has been set with the result as argument
 */
-(void) setFavoriteDevices:(NSString*)favorites completionHandler:(void(^)(SKTResult result)) block{
    if(self.captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDFavorite;
        property.Type = SKTCapturePropertyTypeString;
        property.StringValue = favorites;
        [self.captureDevice setProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            if(block != nil){
                block(result);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE);
        }
    }
}

/**
 * retrieve the list of favorites devices.
 * the favorites is a string of semi-colon separated peripheral UUID identifier.
 *
 * @param block called when getting the favorites has completed with the result and the
 * actual favorites string as argument.
 */
-(void) getFavoriteDevicesWithCompletionHandler:(void(^)(SKTResult result, NSString* favorites)) block{
    if(self.captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDFavorite;
        property.Type = SKTCapturePropertyTypeNone;
        [self.captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            NSString* favorite = @"";
            if(SKTSUCCESS(result)){
                favorite = complete.StringValue;
            }
            if(block != nil){
                block(result, favorite);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, @"");
        }
    }
}

/**
 * retrieve the device unique identifier from the device GUID. The unique identifier can
 * be use to add it into the favorites list.
 *
 * @param deviceGuid contains the device GUID to identify the device to get the unique identifier from
 * @param block called when getting the device unique identifier has completed with the result and the
 * unique identifier as argument.
 */
-(void) getDeviceUniqueIdentifierFromDeviceGuid:(NSString*)deviceGuid completionHandler:(void(^)(SKTResult result, NSString* deviceUniqueIdentifier)) block{
    if(self.captureDevice != nil){
        SKTCaptureProperty* property = [SKTCaptureProperty new];
        property.ID = SKTCapturePropertyIDUniqueDeviceIdentifier;
        property.Type = SKTCapturePropertyTypeString;
        property.StringValue = deviceGuid;
        [self.captureDevice getProperty:property completionHandler:^(SKTResult result, SKTCaptureProperty *complete) {
            NSString* favorite = @"";
            if(SKTSUCCESS(result)){
                favorite = complete.StringValue;
            }
            if(block != nil){
                block(result, favorite);
            }
        }];
    } else {
        if(block != nil) {
            block(SKTCaptureE_INVALIDHANDLE, @"");
        }
    }
}

@end
