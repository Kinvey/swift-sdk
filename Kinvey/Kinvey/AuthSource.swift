//
//  SocialChannel.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/**
 Authentication Source for login with a social identity.
 */
public enum AuthSource: String {

    /// Facebook social identity
    case Facebook = "facebook"
    
    /// Twitter social identity
    case Twitter = "twitter"
    
    /// Google+ social identity
    case GooglePlus = "google"
    
    /// LinkedIn social identity
    case LinkedIn = "linkedIn"
    
    /// Kinvey MIC social identity
    case Kinvey = "kinveyAuth"
    
}
