//
//  AutoDataStoreSpec.swift
//  KinveyTests
//
//  Created by Victor Hugo Carvalho Barros on 2019-04-12.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Quick
import Nimble
@testable import Kinvey

class AutoDataStoreSpec: QuickSpec {
    
    override func spec() {
        var autoDataStore: DataStore<Person>!
        var autoDataStoreDeltaSetOn: DataStore<Person>!
        var syncDataStore: DataStore<Person>!
        var networkDataStore: DataStore<Person>!
        
        beforeEach {
            setURLProtocol(KinveyURLProtocol.self)
            
            kinveyInitialize()
            kinveyLogin()
            
            do {
                autoDataStore = try DataStore<Person>.collection(type: .auto)
                autoDataStoreDeltaSetOn = try DataStore<Person>.collection(type: .auto, options: Options(deltaSet: true))
                syncDataStore = try DataStore<Person>.collection(type: .sync)
                networkDataStore = try DataStore<Person>.collection(type: .network)
            } catch {
                fail(error.localizedDescription)
            }
        }
        afterEach {
            setURLProtocol(KinveyURLProtocol.self)
            kinveyLogout()
            setURLProtocol(nil)
            KinveyURLProtocol.reset()
        }
        describe("Find") {
            context("with correct data and querries and not network interruption") {
                it("should return the data") {
                    kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(2))
                    expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(2))
                
                    kinveySave(dataStore: networkDataStore)
                
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(3))
                    expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(3))
                }
                
                it("should return correct data with query") {
                    kinveySave(
                        dataStore: networkDataStore,
                        entities: [
                            Person({ $0.age = 10 }),
                            Person({ $0.age = 20 }),
                            Person({ $0.age = 30 })
                        ]
                    )
                    
                    let query = Query(\Person.age < 25)
                    
                    expect(kinveyFind(dataStore: autoDataStore, query: query).entities?.count).to(equal(2))
                    expect(kinveyFind(dataStore: syncDataStore, query: query).entities?.count).to(equal(2))
                }
                
                it("should return correct data with limit and skip") {
                    kinveySave(
                        dataStore: networkDataStore,
                        entities: [
                            Person({ $0.age = 10 }),
                            Person({ $0.age = 20 }),
                            Person({ $0.age = 30 })
                        ]
                    )
                    
                    let query = Query {
                        $0.skip = 1
                        $0.limit = 1
                    }
                    
                    var persons = kinveyFind(dataStore: autoDataStore, query: query).entities
                    expect(persons?.count).to(equal(1))
                    expect(persons?.first?.age).to(equal(20))
                    
                    persons = kinveyFind(dataStore: syncDataStore, query: Query()).entities
                    expect(persons?.count).to(equal(1))
                    expect(persons?.first?.age).to(equal(20))
                }
                
                it("should return correct data with delta set") {
                    kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                    
                    expect(kinveyPull(dataStore: autoDataStoreDeltaSetOn).entities?.count).to(equal(2))
                    
                    kinveySave(dataStore: networkDataStore)
                    
                    var deltaSetReached = false
                    let deltaSetCompletionHandler = { (changed: AnyRandomAccessCollection<Person>, deleted: AnyRandomAccessCollection<Person>) in
                        expect(changed.count).to(equal(1))
                        expect(deleted.count).to(equal(0))
                        deltaSetReached = true
                    }
                    expect(kinveyPull(dataStore: autoDataStoreDeltaSetOn, deltaSetCompletionHandler: deltaSetCompletionHandler).entities?.count).to(equal(3))
                    expect(deltaSetReached).to(beTrue())
                    
                    kinveySave(dataStore: networkDataStore)
                    
                    deltaSetReached = false
                    expect(kinveyPull(dataStore: autoDataStoreDeltaSetOn, deltaSetCompletionHandler: deltaSetCompletionHandler).entities?.count).to(equal(4))
                    expect(deltaSetReached).to(beTrue())
                    
                    expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(4))
                }
                
                it("should return correctly sorted data descending") {
                    kinveySave(
                        dataStore: networkDataStore,
                        entities: Person({ $0.age = 10 }), Person({ $0.age = 20 }), Person({ $0.age = 30 })
                    )
                    
                    let query = Query()
                    query.descending(\Person.age)
                    let _items = kinveyFind(dataStore: autoDataStore, query: query).entities
                    expect(_items).toNot(beNil())
                    guard let items = _items else {
                        return
                    }
                    expect(items.count).to(equal(3))
                    expect(items[0].age).to(equal(30))
                    expect(items[1].age).to(equal(20))
                    expect(items[2].age).to(equal(10))
                }
                
                it("should return correctly sorted data ascending") {
                    kinveySave(
                        dataStore: networkDataStore,
                        entities: Person({ $0.age = 30 }), Person({ $0.age = 20 }), Person({ $0.age = 10 })
                    )
                    
                    let query = Query()
                    query.ascending(\Person.age)
                    let _items = kinveyFind(dataStore: autoDataStore, query: query).entities
                    expect(_items).toNot(beNil())
                    guard let items = _items else {
                        return
                    }
                    expect(items.count).to(equal(3))
                    expect(items[0].age).to(equal(10))
                    expect(items[1].age).to(equal(20))
                    expect(items[2].age).to(equal(30))
                }
                
                it("should delete items in the cache that have been deleted in the backend") {
                    kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                    
                    let _items = kinveyFind(dataStore: autoDataStore).entities
                    expect(_items).toNot(beNil())
                    
                    guard let items = _items else {
                        return
                    }
                    expect(items.count).to(equal(2))
                    
                    kinveyRemove(dataStore: networkDataStore, entity: items.first!)
                    
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(1))
                    expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(1))
                }
                
                it("should use different collection with tagged data store") {
                    kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                    
                    let tag = UUID().uuidString
                    expect(kinveyFind(dataStore: try DataStore<Person>.collection(type: .auto, tag: tag)).entities?.count).to(equal(2))
                    expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(0))
                    expect(kinveyFind(dataStore: try DataStore<Person>.collection(type: .sync, tag: tag)).entities?.count).to(equal(2))
                }
            }
            
            context("with invalid data and network interruptions") {
                it("should return error for invalid query") {
                    // N/A
                }
                
                it("should return regular error for invalid operation") {
                    mockResponseInsufficientCredentialsError()
                    defer {
                        setURLProtocol(nil)
                    }
                    
                    expect(kinveyFind(dataStore: autoDataStore).error?.localizedDescription).to(equal(insufficientCredentialsErrorDescription))
                }
                
                it("should return locally stored data if connectivity error") {
                    kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                    
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(2))
                    
                    kinveySave(dataStore: networkDataStore, numberOfItems: 1)
                    
                    mockResponse(error: timeoutError)
                    defer {
                        setURLProtocol(nil)
                    }
                    
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(2))
                }
                
                it("should return locally stored data if connectivity error with tagged store") {
                    kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                    
                    let tag = UUID().uuidString
                    expect(kinveyFind(dataStore: try DataStore<Person>.collection(type: .auto, tag: tag)).entities?.count).to(equal(2))
                    
                    kinveySave(dataStore: networkDataStore)
                    
                    expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(0))
                    
                    mockResponse(error: timeoutError)
                    defer {
                        setURLProtocol(nil)
                    }
                    
                    expect(kinveyFind(dataStore: try DataStore<Person>.collection(type: .auto, tag: tag)).entities?.count).to(equal(2))
                }
                
                it("should return backend data after connectivity error is eliminated") {
                    kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                    
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(2))
                    
                    kinveySave(dataStore: networkDataStore)
                    
                    do {
                        mockResponse(error: timeoutError)
                        defer {
                            setURLProtocol(KinveyURLProtocol.self)
                        }
                        expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(2))
                    }
                    
                    kinveySave(dataStore: networkDataStore)
                    
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(4))
                }
                
                it("should return queried data if connectivity error") {
                    kinveySave(
                        dataStore: networkDataStore,
                        entities: Person({ $0.age = 10 }), Person({ $0.age = 20 }), Person({ $0.age = 30 })
                    )
                    
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(3))
                    
                    mockResponse(error: timeoutError)
                    defer {
                        setURLProtocol(nil)
                    }
                    
                    expect(kinveyFind(dataStore: autoDataStore, query: Query(\Person.age < 25)).entities?.count).to(equal(2))
                }
                
                it("should return correct data with limit and skip") {
                    kinveySave(
                        dataStore: networkDataStore,
                        entities: Person({ $0.age = 10 }), Person({ $0.age = 20 }), Person({ $0.age = 30 })
                    )
                    
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(3))
                    
                    mockResponse(error: timeoutError)
                    defer {
                        setURLProtocol(nil)
                    }
                    
                    let items = kinveyFind(dataStore: autoDataStore, query: Query({ $0.skip = 1; $0.limit = 1 })).entities
                    expect(items?.count).to(equal(1))
                    expect(items?.first?.age).to(equal(20))
                }
                
                it("should return sorted data") {
                    kinveySave(
                        dataStore: networkDataStore,
                        entities: Person({ $0.age = 10 }), Person({ $0.age = 20 }), Person({ $0.age = 30 })
                    )
                    
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(3))
                    
                    mockResponse(error: timeoutError)
                    defer {
                        setURLProtocol(nil)
                    }
                    
                    let items = kinveyFind(dataStore: autoDataStore, query: Query().descending(\Person.age)).entities
                    expect(items?.count).to(equal(3))
                    expect(items?[0].age).to(equal(30))
                    expect(items?[1].age).to(equal(20))
                    expect(items?[2].age).to(equal(10))
                }
                
                it("should return correct data with delta set") {
                    kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                    
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(2))
                    
                    kinveySave(dataStore: networkDataStore)
                    
                    do {
                        mockResponse(error: timeoutError)
                        defer {
                            setURLProtocol(KinveyURLProtocol.self)
                        }
                        expect(kinveyFind(dataStore: autoDataStoreDeltaSetOn).entities?.count).to(equal(2))
                    }
                    
                    expect(kinveyFind(dataStore: autoDataStoreDeltaSetOn).entities?.count).to(equal(3))
                }
                
                it("should remove entities no longer existing in the backend") {
                    kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                    
                    let items = kinveyFind(dataStore: autoDataStore).entities
                    expect(items?.count).to(equal(2))
                    
                    kinveyRemove(dataStore: networkDataStore, entity: items!.first!)
                    
                    let items2 = kinveyFind(dataStore: autoDataStore).entities
                    expect(items2?.count).to(equal(1))
                    expect(items2?.first?.entityId).to(equal(items?.last?.entityId))
                    
                    expect(kinveyFind(dataStore: syncDataStore, id: items!.first!.entityId!).error?.localizedDescription).to(equal(entityNotFoundErrorDescription))
                    expect(kinveyFind(dataStore: networkDataStore, id: items!.first!.entityId!).error?.localizedDescription).to(equal(entityNotFoundErrorDescription))
                }
            }
        }
        
        describe("Count") {
            context("with valid data and no network issues") {
                it("should the count of all items") {
                    kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                    
                    expect(kinveyCount(dataStore: autoDataStore).count).to(equal(2))
                    
                    kinveySave(dataStore: networkDataStore)
                    
                    expect(kinveyCount(dataStore: autoDataStore).count).to(equal(3))
                }
                
                it("should the count of all items from a tagged data store") {
                    kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                    
                    let tag = UUID().uuidString
                    expect(kinveyCount(dataStore: try DataStore<Person>.collection(type: .auto, tag: tag)).count).to(equal(2))
                    
                    kinveySave(dataStore: networkDataStore)
                    
                    expect(kinveyCount(dataStore: try DataStore<Person>.collection(type: .auto, tag: tag)).count).to(equal(3))
                    expect(kinveyCount(dataStore: syncDataStore).count).to(equal(0))
                }
                
                it("should return the count of queried items") {
                    kinveySave(
                        dataStore: networkDataStore,
                        entities: Person({ $0.age = 10 }), Person({ $0.age = 20 }), Person({ $0.age = 30 })
                    )
                    
                    expect(kinveyCount(dataStore: autoDataStore, query: Query(\Person.age <= 20)).count).to(equal(2))
                }
            }
            
            context("with invalid data or with network interruption") {
                it("should throw an error for invalid query") {
                    // N/A
                }
                
                it("should return the number of locally stored items with network interruption") {
                    kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                    
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(2))
                    
                    kinveySave(dataStore: networkDataStore)
                    
                    mockResponse(error: timeoutError)
                    defer {
                        setURLProtocol(nil)
                    }
                    expect(kinveyCount(dataStore: autoDataStore).count).to(equal(2))
                }
                
                it("should return the number of locally stored items with network interruption with tagged store") {
                    kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                    
                    let tag = UUID().uuidString
                    expect(kinveyFind(dataStore: try DataStore<Person>.collection(type: .auto, tag: tag)).entities?.count).to(equal(2))
                    
                    kinveySave(dataStore: networkDataStore)
                    
                    do {
                        mockResponse(error: timeoutError)
                        defer {
                            setURLProtocol(nil)
                        }
                        expect(kinveyCount(dataStore: try DataStore<Person>.collection(type: .auto, tag: tag)).count).to(equal(2))
                    }
                    
                    expect(kinveyCount(dataStore: syncDataStore).count).to(equal(0))
                }
                
                it("should throw regular error for invalid operation") {
                    mockResponseInsufficientCredentialsError()
                    defer {
                        setURLProtocol(nil)
                    }
                    
                    expect(kinveyCount(dataStore: autoDataStore).error?.localizedDescription).to(equal(insufficientCredentialsErrorDescription))
                }
            }
        }
        
        describe("FindById") {
            context("with correct data and not network interruption") {
                it("should return correct item") {
                    let items = kinveySave(dataStore: networkDataStore, numberOfItems: 2).entities!
                    
                    let id = items.first!.entityId!
                    expect(kinveyFind(dataStore: autoDataStore, id: id).result?.entityId).to(equal(id))
                    expect(kinveyFind(dataStore: syncDataStore, id: id).result?.entityId).to(equal(id))
                }
            }
            
            context("with invalid data and network interruptions") {
                it("should throw error if id is not provided") {
                    // N/A
                }
                
                it("should throw regular error for invalid operation") {
                    mockResponseInsufficientCredentialsError()
                    defer {
                        setURLProtocol(nil)
                    }
                    
                    expect(kinveyFind(dataStore: autoDataStore, id: UUID().uuidString).error?.localizedDescription).to(equal(insufficientCredentialsErrorDescription))
                }
                
                it("should return locally stored item if connectivity error is returned") {
                    let items = kinveySave(dataStore: networkDataStore, numberOfItems: 2).entities!
                    
                    let id = items.first!.entityId!
                    expect(kinveyFind(dataStore: autoDataStore, id: id).result?.entityId).to(equal(id))
                    
                    mockResponse(error: timeoutError)
                    defer {
                        setURLProtocol(nil)
                    }
                    expect(kinveyFind(dataStore: autoDataStore, id: id).result?.entityId).to(equal(id))
                }
                
                it("should delete the item locally if it has been deleted in the backend") {
                    let items = kinveySave(dataStore: autoDataStore, numberOfItems: 2).entities!
                    
                    let id = items.first!.entityId!
                    expect(kinveyFind(dataStore: syncDataStore, id: id).result?.entityId).to(equal(id))
                    
                    kinveyRemove(dataStore: autoDataStore, id: id)
                    
                    expect(kinveyFind(dataStore: autoDataStore, id: id).error?.localizedDescription).to(equal(entityNotFoundErrorDescription))
                    expect(kinveyFind(dataStore: syncDataStore, id: id).error?.localizedDescription).to(equal(entityNotFoundErrorDescription))
                }
                
                it("should return correct item with tagged store") {
                    let items = kinveySave(dataStore: autoDataStore, numberOfItems: 2).entities!
                    
                    let id = items.first!.entityId!
                    expect(kinveyFind(dataStore: autoDataStore, id: id).result?.entityId).to(equal(id))
                    
                    expect(kinveyFind(dataStore: try DataStore<Person>.collection(.sync, tag: UUID().uuidString), id: id).result?.entityId).to(beNil())
                    expect(kinveyFind(dataStore: try DataStore<Person>.collection(.sync), id: id).result?.entityId).to(equal(id))
                }
            }
        }
        
        describe("Pull") {
            it("should pull all data with no connectivity issues") {
                kinveySave(dataStore: autoDataStore, numberOfItems: 2)
                
                expect(kinveyPull(dataStore: autoDataStore).entities?.count).to(equal(2))
                expect(kinveyPull(dataStore: syncDataStore).entities?.count).to(equal(2))
            }
            
            it("should pull all data with no connectivity issues with tagged store") {
                kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                
                let tag = UUID().uuidString
                expect(kinveyPull(dataStore: try DataStore<Person>.collection(.auto, tag: tag)).entities?.count).to(equal(2))
                expect(kinveyFind(dataStore: try DataStore<Person>.collection(.sync, tag: tag)).entities?.count).to(equal(2))
                expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(0))
            }
            
            it("should return error with connectivity issue") {
                mockResponse(error: timeoutError)
                defer {
                    setURLProtocol(nil)
                }
                
                expect(kinveyPull(dataStore: autoDataStore).error?.localizedDescription).to(equal(timeoutError.localizedDescription))
            }
            
            it("should pull only the items conforming to a query") {
                kinveySave(
                    dataStore: networkDataStore,
                    entities: Person({ $0.age = 10 }), Person({ $0.age = 20 }), Person({ $0.age = 30 })
                )
                
                expect(kinveyFind(dataStore: autoDataStore, query: Query(\Person.age > 18)).entities?.count).to(equal(2))
                expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(2))
            }
            
            it("should delete locally stored items that are deleted from the backend") {
                kinveySave(dataStore: networkDataStore, numberOfItems: 4)
                
                let entities = kinveyPull(dataStore: autoDataStore).entities
                expect(entities?.count).to(equal(4))
                
                kinveyRemove(dataStore: networkDataStore, entity: entities!.first!)
                kinveyRemove(dataStore: networkDataStore, entity: entities!.last!)
                
                expect(kinveyPull(dataStore: autoDataStore).entities?.count).to(equal(2))
                expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(2))
            }
            
            it("should update items in the cache that are changed in the backend") {
                kinveySave(dataStore: networkDataStore, numberOfItems: 4)
                
                var entities = kinveyPull(dataStore: autoDataStore).entities
                expect(entities?.count).to(equal(4))
                
                var first = entities!.first!
                first.age = 10
                expect(kinveySave(dataStore: networkDataStore, entity: first).entity).toNot(beNil())
                
                var last = entities!.last!
                last.age = 40
                expect(kinveySave(dataStore: networkDataStore, entity: last).entity).toNot(beNil())
                
                entities = kinveyPull(dataStore: autoDataStore).entities
                expect(entities?.count).to(equal(4))
                expect(entities?[0].age).to(equal(10))
                expect(entities?[1].age).to(equal(0))
                expect(entities?[2].age).to(equal(0))
                expect(entities?[3].age).to(equal(40))
                
                entities = kinveyFind(dataStore: syncDataStore).entities
                expect(entities?.count).to(equal(4))
                expect(entities?[0].age).to(equal(10))
                expect(entities?[1].age).to(equal(0))
                expect(entities?[2].age).to(equal(0))
                expect(entities?[3].age).to(equal(40))
            }
            
            it("should use autopagination when turned on") {
                kinveySave(dataStore: networkDataStore, numberOfItems: 4)
                
                let autoDataStoreAutoPaginationOn = try DataStore<Person>.collection(type: .auto, autoPagination: true, options: Options(maxSizePerResultSet: 2))
                
                expect(kinveyPull(dataStore: autoDataStoreAutoPaginationOn).entities?.count).to(equal(4))
                expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(4))
            }
            
            it("should return error for invalid query") {
                mockResponseInsufficientCredentialsError()
                defer {
                    setURLProtocol(nil)
                }
                
                expect(kinveyPull(dataStore: autoDataStore).error?.localizedDescription).to(equal(insufficientCredentialsErrorDescription))
            }
            
            it("should return error if there are items not synced with the backend") {
                kinveySave(dataStore: syncDataStore, numberOfItems: 2)
                
                expect(kinveyPull(dataStore: autoDataStore).error?.localizedDescription).to(equal("You must push all pending sync items before new data is pulled. Call push() on the data store instance to push pending items, or purge() to remove them."))
            }
            
            it("should persist updated and deleted items") {
                var entities = kinveySave(dataStore: networkDataStore, numberOfItems: 3).entities!
                
                expect(kinveyPull(dataStore: autoDataStore).entities?.count).to(equal(3))
                
                entities.last!.age = 30
                kinveySave(dataStore: networkDataStore, entity: entities.last!)
                
                kinveyRemove(dataStore: networkDataStore, entity: entities.first!)
                
                entities = kinveyPull(dataStore: autoDataStore).entities!
                expect(entities.count).to(equal(2))
                expect(entities[0].age).to(equal(0))
                expect(entities[1].age).to(equal(30))
                
                entities = kinveyPull(dataStore: syncDataStore).entities!
                expect(entities.count).to(equal(2))
                expect(entities[0].age).to(equal(0))
                expect(entities[1].age).to(equal(30))
            }
        }
        
        describe("Push") {
            it("should push created items to the backend") {
                kinveySave(dataStore: syncDataStore, numberOfItems: 2)
                
                expect(autoDataStore.syncCount()).to(equal(2))
                
                kinveyPush(dataStore: autoDataStore)
                
                expect(kinveyFind(dataStore: networkDataStore).entities?.count).to(equal(2))
                
                expect(autoDataStore.syncCount()).to(equal(0))
            }
            
            it("should push created items to the backend with tagged store") {
                let tag = UUID().uuidString
                kinveySave(dataStore: try DataStore<Person>.collection(.sync, tag: tag), numberOfItems: 2)
                
                let autoDataStoreTagged = try DataStore<Person>.collection(.auto, tag: tag)
                
                expect(autoDataStoreTagged.syncCount()).to(equal(2))
                expect(autoDataStore.syncCount()).to(equal(0))
                
                kinveyPush(dataStore: autoDataStoreTagged)
                
                expect(kinveyFind(dataStore: networkDataStore).entities?.count).to(equal(2))
                
                expect(autoDataStoreTagged.syncCount()).to(equal(0))
                expect(autoDataStore.syncCount()).to(equal(0))
            }
            
            it("should push updated items to the backend") {
                var entities = kinveySave(dataStore: networkDataStore, numberOfItems: 2).entities
                
                expect(kinveyPull(dataStore: autoDataStore).entities?.count).to(equal(2))
                
                entities!.first!.age = 10
                kinveySave(dataStore: syncDataStore, entity: entities!.first!)
                
                expect(autoDataStore.syncCount()).to(equal(1))
                
                kinveyPush(dataStore: autoDataStore)
                
                entities = kinveyFind(dataStore: networkDataStore).entities
                expect(entities?.count).to(equal(2))
                expect(entities?.first?.age).to(equal(10))
                expect(entities?.last?.age).to(equal(0))
                
                expect(autoDataStore.syncCount()).to(equal(0))
            }
            
            it("should push deleted items to the backend") {
                var entities = kinveySave(
                    dataStore: networkDataStore,
                    entities: Person({ $0.age = 10 }), Person({ $0.age = 20 }), Person({ $0.age = 30 })
                ).entities
                
                expect(kinveyPull(dataStore: autoDataStore).entities?.count).to(equal(3))
                
                kinveyRemove(dataStore: syncDataStore, entity: entities!.first!)
                kinveyRemove(dataStore: syncDataStore, entity: entities!.last!)
                
                expect(autoDataStore.syncCount()).to(equal(2))
                
                expect(kinveyPush(dataStore: autoDataStore).count).to(equal(2))
                
                entities = kinveyFind(dataStore: networkDataStore).entities
                expect(entities?.count).to(equal(1))
                expect(entities?.first?.age).to(equal(20))
                
                expect(autoDataStore.syncCount()).to(equal(0))
            }
            
            it("should return error for connectivity error") {
                kinveySave(dataStore: syncDataStore, numberOfItems: 2)
                
                expect(autoDataStore.syncCount()).to(equal(2))
                
                do {
                    mockResponse(error: timeoutError)
                    defer {
                        setURLProtocol(nil)
                    }
                    
                    let errors = kinveyPush(dataStore: autoDataStore).errors
                    expect(errors?.count).to(equal(2))
                    for error in errors ?? [] {
                        expect((error as NSError).domain).to(equal(NSURLErrorDomain))
                        expect((error as NSError).code).to(equal(NSURLErrorTimedOut))
                        expect(error.localizedDescription).to(equal("The operation couldn’t be completed. (\(NSURLErrorDomain) error \(NSURLErrorTimedOut).)"))
                    }
                }
                
                expect(autoDataStore.syncCount()).to(equal(2))
            }
            
            it("should push all items disregarding a query") {
                // N/A
            }
            
            fit("should complete push of multiple items if one of them fails") {
                kinveySave(dataStore: syncDataStore, numberOfItems: 3)
                
                kinveyPush(dataStore: autoDataStore)
                
                let entities = kinveyFind(dataStore: syncDataStore).entities
                expect(entities?.count).to(equal(3))
                
                entities!.first!.age = 10
                kinveySave(dataStore: syncDataStore, entity: entities!.first!)
                
                kinveyRemove(dataStore: syncDataStore, entity: entities!.last!)
                
                expect(autoDataStore.syncCount()).to(equal(2))
                
                do {
                    var mockCount = 0
                    mockResponse { request in
                        switch request.httpMethod! {
                        case "DELETE":
                            return httpResponseInsufficientCredentialsError
                        case "PUT":
                            let client = KinveyURLProtocolClient()
                            let urlProtocol = KinveyURLProtocol(request: request, cachedResponse: nil, client: client)
                            urlProtocol.startLoading()
                            urlProtocol.stopLoading()
                            return HttpResponse(response: client.response, data: client.data)
                        default:
                            let error = "\(request.httpMethod!) \(request.url!)\n\(try! JSONSerialization.jsonObject(with: request))"
                            fail(error)
                            fatalError(error)
                        }
                    }
                    defer {
                        setURLProtocol(KinveyURLProtocol.self)
                    }
                    
                    let result = kinveyPush(dataStore: autoDataStore)
                    expect(result.count).to(beNil())
                    expect(result.errors?.count).to(equal(1))
                    expect(mockCount).to(equal(2))
                }
                
                expect(autoDataStore.syncCount()).to(equal(1))
                
                expect(kinveyFind(dataStore: networkDataStore).entities?.count).to(equal(3))
            }
        }
    }
    
}

func it(_ description: String, flags: FilterFlags = [:], file: String = #file, line: UInt = #line, closure: @escaping () throws -> Void) {
    it(description, flags: flags, file: file, line: line) {
        do {
            try closure()
        } catch {
            fail(error.localizedDescription)
        }
    }
}

func fit(_ description: String, flags: FilterFlags = [:], file: String = #file, line: UInt = #line, closure: @escaping () throws -> Void) {
    fit(description, flags: flags, file: file, line: line) {
        do {
            try closure()
        } catch {
            fail(error.localizedDescription)
        }
    }
}
