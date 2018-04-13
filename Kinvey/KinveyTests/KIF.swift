//
//  KIF.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import KIF

extension XCTestCase {
    func tester(_ file : String = #file, _ line : Int = #line) -> KIFUITestActor {
        return KIFUITestActor(inFile: file, atLine: line, delegate: self)
    }
    
    func system(_ file : String = #file, _ line : Int = #line) -> KIFSystemTestActor {
        return KIFSystemTestActor(inFile: file, atLine: line, delegate: self)
    }
}

extension KIFTestActor {
    func tester(_ file : String = #file, _ line : Int = #line) -> KIFUITestActor {
        return KIFUITestActor(inFile: file, atLine: line, delegate: self)
    }
    
    func system(_ file : String = #file, _ line : Int = #line) -> KIFSystemTestActor {
        return KIFSystemTestActor(inFile: file, atLine: line, delegate: self)
    }
}

extension XCTestCase {
    @discardableResult
    @nonobjc func waitForCondition(_ condition: @autoclosure @escaping () -> Bool, negateCondition: Bool = false, timeout: CFTimeInterval = 10) -> Bool {
        var fulfilled = false
        let observer = CFRunLoopObserverCreateWithHandler(nil, CFRunLoopActivity.beforeWaiting.rawValue, true, 0) { observer, activity in
            fulfilled = condition()
            if fulfilled {
                CFRunLoopStop(CFRunLoopGetCurrent())
            } else {
                CFRunLoopWakeUp(CFRunLoopGetCurrent())
            }
        }
        
        CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, CFRunLoopMode.defaultMode)
        
        CFRunLoopRunInMode(CFRunLoopMode.defaultMode, timeout, false)
        
        CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), observer, CFRunLoopMode.defaultMode)
        
        return fulfilled
    }
}
