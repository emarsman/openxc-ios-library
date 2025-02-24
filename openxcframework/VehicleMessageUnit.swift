//
//  VehicleMessageUnit.swift
//  openxc-ios-framework
//
//  Created by Ranjan, Kumar sahu (K.) on 12/03/18.
//  Copyright © 2018 Ford Motor Company. All rights reserved.
//

import UIKit

open class VehicleMessageUnit: NSObject {

    static let sharedNetwork = VehicleMessageUnit()
    // Initialization
    static public let sharedInstance: VehicleMessageUnit = {
        let instance = VehicleMessageUnit()
        return instance
    }()
    fileprivate override init() {
      //  connecting = false
    }
    
    public func getMesurementUnit(key:String , value:Any) -> Any{
        
        let stringValue = String(describing: value)
        
        let measurementType = key
        var measurmentUnit : String = ""
        switch measurementType {
        case acceleratorPedal,fuelLevel:
            measurmentUnit = stringValue + " %"
            return measurmentUnit
        case engineSpeed:
            measurmentUnit = stringValue + " RPM"
            return measurmentUnit
        case fuelConsumed:
            measurmentUnit = stringValue + " L"
            return measurmentUnit
        case latitude,longitude,steeringWheelAngle:
            measurmentUnit = stringValue + " °"
            return measurmentUnit
        case odometer:
            measurmentUnit = stringValue + " km"
            return measurmentUnit
        case torqueTransmission:
            measurmentUnit = stringValue + " Nm"
            return measurmentUnit
        case vehicleSpeed:
            measurmentUnit = stringValue + " km/hr"
            return measurmentUnit
        default:
            return value
        }
        //return value
        
    }
}
