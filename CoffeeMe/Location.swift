//
//  Location.swift
//  CoffeeMe
//
//  Created by Thomas Crawford on 3/5/17.
//  Copyright © 2017 VizNetwork. All rights reserved.
//

import UIKit

class Location: NSObject {

    var locationName    :String!
    var locationAddress :String!
    var locationLat     :Double!
    var locationLon     :Double!
    
    convenience init(name: String, address: String, lat: Double, lon: Double) {
        self.init()
        self.locationName = name
        self.locationAddress = address
        self.locationLat = lat
        self.locationLon = lon
    }

}
