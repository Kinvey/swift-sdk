//
//  HierarchyCache.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-07-28.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Kinvey

public class HierarchyCache: Entity {
    
    dynamic var salesOrganization: String?
    dynamic var distributionChannel: String?
    dynamic var sapCustomerNumber: String?
    dynamic var materialNumber: String?
    dynamic var conditionType: String?
    dynamic var salesDivision: String?
    dynamic var validityStartDate: String?
    dynamic var validityEndDate: String?
    dynamic var price: String?
    dynamic var currency: String?
    dynamic var deliveryUnit: String?
    dynamic var unitQuantity: String?
    dynamic var unitOfMeasure: String?
    
    public override class func collectionName() -> String {
        return "hierarchycache"
    }
    
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
