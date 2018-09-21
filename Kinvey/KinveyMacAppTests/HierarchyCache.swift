//
//  HierarchyCache.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-07-28.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Kinvey

public class HierarchyCache: Entity {
    
    @objc
    dynamic var salesOrganization: String?
    
    @objc
    dynamic var distributionChannel: String?
    
    @objc
    dynamic var sapCustomerNumber: String?
    
    @objc
    dynamic var materialNumber: String?
    
    @objc
    dynamic var conditionType: String?
    
    @objc
    dynamic var salesDivision: String?
    
    @objc
    dynamic var validityStartDate: String?
    
    @objc
    dynamic var validityEndDate: String?
    
    @objc
    dynamic var price: String?
    
    @objc
    dynamic var currency: String?
    
    @objc
    dynamic var deliveryUnit: String?
    
    @objc
    dynamic var unitQuantity: String?
    
    @objc
    dynamic var unitOfMeasure: String?
    
    public override class func collectionName() -> String {
        return "hierarchycache"
    }
    
    @available(*, deprecated)
    public override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        salesOrganization <- ("salesOrganization", map["SalesOrganization"])
        distributionChannel <- ("distributionChannel", map["DistributionChannel"])
        sapCustomerNumber <- ("sapCustomerNumber", map["SAPCustomerNumber"])
        materialNumber <- ("materialNumber", map["MaterialNumber"])
        conditionType <- ("conditionType", map["ConditionType"])
        salesDivision <- ("salesDivision", map["SalesDivision"])
        validityStartDate <- ("validityStartDate", map["ValidityStartDate"])
        validityEndDate <- ("validityEndDate", map["ValidityEndDate"])
        price <- ("price", map["Price"])
        currency <- ("currency", map["Currency"])
        deliveryUnit <- ("deliveryUnit", map["DeliveryUnit"])
        unitQuantity <- ("unitQuantity", map["UnitQuantity"])
        unitOfMeasure <- ("unitOfMeasure", map["UnitOfMeasure"])
    }
    
}
