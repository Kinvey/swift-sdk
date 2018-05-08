//
//  DeviceInfo.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2018-04-26.
//  Copyright © 2018 Kinvey. All rights reserved.
//

import Foundation

#if canImport(UIKit)
    import UIKit
    #if canImport(WatchKit)
        import WatchKit
    #endif
#elseif canImport(Cocoa)
    import Cocoa
#endif

struct DeviceInfo: Codable {
    
    let version: Int
    let model: String
    
    let operationSystem: String
    let operationSystemVersion: String
    
    let platform: String
    let platformVersion: String
    
    let deviceType: String?
    let netorkCondition: String?
    let deviceId: String?
    
    static var platform: String {
        #if os(iOS)
            return "iOS"
        #elseif os(tvOS)
            return "tvOS"
        #elseif os(watchOS)
            return "watchOS"
        #elseif os(macOS)
            return "macOS"
        #elseif os(Linux)
            return "Linux"
        #else
            return "Platform Unknown"
        #endif
    }
    
    static var platformVersion: String {
        #if canImport(UIKit)
            return "\(platformVersion()) (\(DeviceInfo.systemInfoMachine))"
        #else
            return hwModel
        #endif
    }
    
    static var systemInfoMachine: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    static var isSimulator: Bool {
        switch systemInfoMachine {
        case "i386", "x86_64":
            return true
        default:
            return false
        }
    }
    
    #if canImport(UIKit)
    static func platformVersion(identifier: String = DeviceInfo.systemInfoMachine) -> String {
        switch identifier {
        case "iPod5,1": return "iPod Touch 5"
        case "iPod7,1": return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3": return "iPhone 4"
        case "iPhone4,1": return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2": return "iPhone 5"
        case "iPhone5,3", "iPhone5,4": return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2": return "iPhone 5s"
        case "iPhone7,2": return "iPhone 6"
        case "iPhone7,1": return "iPhone 6 Plus"
        case "iPhone8,1": return "iPhone 6s"
        case "iPhone8,2": return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3": return "iPhone 7"
        case "iPhone9,2", "iPhone9,4": return "iPhone 7 Plus"
        case "iPhone8,4": return "iPhone SE"
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3": return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6": return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3": return "iPad Air"
        case "iPad5,3", "iPad5,4": return "iPad Air 2"
        case "iPad6,11", "iPad6,12": return "iPad 5"
        case "iPad7,5", "iPad7,6": return "iPad 6"
        case "iPad2,5", "iPad2,6", "iPad2,7": return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6": return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9": return "iPad Mini 3"
        case "iPad5,1", "iPad5,2": return "iPad Mini 4"
        case "iPad6,3", "iPad6,4": return "iPad Pro 9 Inch"
        case "iPad6,7", "iPad6,8": return "iPad Pro 12 Inch"
        case "iPad7,1", "iPad7,2": return "iPad Pro 12 Inch 2"
        case "iPad7,3", "iPad7,4": return "iPad Pro 10 Inch"
        case "AudioAccessory1,1": return "HomePod"
        case "i386", "x86_64":
            if let simulatorModelIdentifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
                return "Simulator \(platformVersion(identifier: simulatorModelIdentifier))"
            } else {
                return DeviceInfo.model
            }
        default: return "Platform Version Unknown"
        }
    }
    #endif
    
    static var hwModel: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(validatingUTF8: model) ?? ""
    }
    
    static var model: String {
        #if canImport(UIKit)
            #if os(watchOS)
                return WKInterfaceDevice.current().model
            #else
                return UIDevice.current.model
            #endif
        #elseif canImport(Cocoa)
            return hwModel
        #endif
    }
    
    static var operationSystem: String {
        #if canImport(UIKit)
            #if os(watchOS)
                return WKInterfaceDevice.current().systemName
            #else
                return UIDevice.current.systemName
            #endif
        #elseif os(macOS)
            let operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
            switch (operatingSystemVersion.majorVersion, operatingSystemVersion.minorVersion) {
            case (10, 12):
                return "Sierra"
            case (10, 13):
                return "High Sierra"
            default:
                return "Operation System Unknown"
            }
        #endif
    }
    
    static var operationSystemVersion: String {
        #if canImport(UIKit)
            #if os(watchOS)
                return WKInterfaceDevice.current().systemVersion
            #else
                return UIDevice.current.systemVersion
            #endif
        #elseif os(macOS)
            return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }
    
    init() {
        version = 1
        model = DeviceInfo.model
        operationSystem = DeviceInfo.operationSystem
        operationSystemVersion = DeviceInfo.operationSystemVersion
        platform = DeviceInfo.platform
        platformVersion = DeviceInfo.platformVersion
        deviceType = nil
        netorkCondition = nil
        deviceId = nil
    }
    
    enum CodingKeys: String, CodingKey {
        
        case version = "hv"
        case model = "md"
        case operationSystem = "os"
        case operationSystemVersion = "ov"
        case platform = "sdk"
        case platformVersion = "pv"
        case deviceType = "ty"
        case netorkCondition = "nc"
        case deviceId = "id"
        
    }
    
}
