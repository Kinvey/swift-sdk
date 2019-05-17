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

                    expect(items?.first).toNot(beNil())
                    guard let entity = items?.first else {
                        return
                    }

                    kinveyRemove(dataStore: networkDataStore, entity: entity)

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

                    expect(items.first?.entityId).toNot(beNil())
                    guard let id = items.first?.entityId else {
                        return
                    }
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

                    expect(items.first?.entityId).toNot(beNil())
                    guard let id = items.first?.entityId else {
                        return
                    }
                    expect(kinveyFind(dataStore: autoDataStore, id: id).result?.entityId).to(equal(id))

                    mockResponse(error: timeoutError)
                    defer {
                        setURLProtocol(nil)
                    }
                    expect(kinveyFind(dataStore: autoDataStore, id: id).result?.entityId).to(equal(id))
                }

                it("should delete the item locally if it has been deleted in the backend") {
                    let items = kinveySave(dataStore: autoDataStore, numberOfItems: 2).entities!

                    expect(items.first?.entityId).toNot(beNil())
                    guard let id = items.first?.entityId else {
                        return
                    }
                    expect(kinveyFind(dataStore: syncDataStore, id: id).result?.entityId).to(equal(id))

                    kinveyRemove(dataStore: autoDataStore, id: id)

                    expect(kinveyFind(dataStore: autoDataStore, id: id).error?.localizedDescription).to(equal(entityNotFoundErrorDescription))
                    expect(kinveyFind(dataStore: syncDataStore, id: id).error?.localizedDescription).to(equal(entityNotFoundErrorDescription))
                }

                it("should return correct item with tagged store") {
                    let items = kinveySave(dataStore: autoDataStore, numberOfItems: 2).entities!

                    expect(items.first?.entityId).toNot(beNil())
                    guard let id = items.first?.entityId else {
                        return
                    }
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

                expect(entities?.first).toNot(beNil())
                expect(entities?.last).toNot(beNil())
                guard let first = entities?.first,
                    let last = entities?.last
                else {
                    return
                }

                kinveyRemove(dataStore: networkDataStore, entity: first)
                kinveyRemove(dataStore: networkDataStore, entity: last)

                expect(kinveyPull(dataStore: autoDataStore).entities?.count).to(equal(2))
                expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(2))
            }

            it("should update items in the cache that are changed in the backend") {
                kinveySave(dataStore: networkDataStore, numberOfItems: 4)

                var entities = kinveyPull(dataStore: autoDataStore).entities
                expect(entities?.count).to(equal(4))

                expect(entities?.first).toNot(beNil())
                expect(entities?.last).toNot(beNil())
                guard let first = entities?.first,
                    let last = entities?.last
                else {
                    return
                }

                first.age = 10
                expect(kinveySave(dataStore: networkDataStore, entity: first).entity).toNot(beNil())

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
                var _entities = kinveySave(dataStore: networkDataStore, numberOfItems: 3).entities
                expect(_entities).toNot(beNil())
                guard let entities = _entities else {
                    return
                }

                expect(kinveyPull(dataStore: autoDataStore).entities?.count).to(equal(3))

                expect(entities.last).toNot(beNil())
                guard let entity = entities.last else {
                    return
                }
                entity.age = 30
                kinveySave(dataStore: networkDataStore, entity: entity)

                kinveyRemove(dataStore: networkDataStore, entity: entities.first!)

                _entities = kinveyPull(dataStore: autoDataStore).entities!
                expect(_entities).toNot(beNil())
                guard let entities2 = _entities else {
                    return
                }
                expect(entities2.count).to(equal(2))
                expect(entities2[0].age).to(equal(0))
                expect(entities2[1].age).to(equal(30))

                _entities = kinveyPull(dataStore: syncDataStore).entities!
                expect(_entities).toNot(beNil())
                guard let entities3 = _entities else {
                    return
                }
                expect(entities3.count).to(equal(2))
                expect(entities3[0].age).to(equal(0))
                expect(entities3[1].age).to(equal(30))
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

                expect(entities?.first).toNot(beNil())
                guard let entity = entities?.first else {
                    return
                }
                entity.age = 10
                kinveySave(dataStore: syncDataStore, entity: entity)

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

                expect(entities?.first).toNot(beNil())
                expect(entities?.last).toNot(beNil())
                guard let first = entities?.first,
                    let last = entities?.last
                else {
                    return
                }

                kinveyRemove(dataStore: syncDataStore, entity: first)
                kinveyRemove(dataStore: syncDataStore, entity: last)

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

                expect(autoDataStore.syncCount()).to(equal(2))
            }

            it("should push all items disregarding a query") {
                // N/A
            }

            it("should complete push of multiple items if one of them fails") {
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
                        mockCount += 1
                        switch request.httpMethod! {
                        case "DELETE":
                            return httpResponseInsufficientCredentialsError
                        case "PUT":
                            return HttpResponse(request: request)
                        default:
                            fail("\(request.httpMethod!) \(request.url!)\n\(try! JSONSerialization.jsonObject(with: request))")
                            return HttpResponse(statusCode: 404, data: Data())
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
            
            it("should recreate an item changed locally but deleted from the server") {
                kinveySave(dataStore: syncDataStore, numberOfItems: 2)
                
                expect(kinveyPush(dataStore: syncDataStore).count).to(equal(2))
                
                let entities = kinveyFind(dataStore: syncDataStore).entities
                expect(entities?.last).toNot(beNil())
                guard let entity = entities?.last else {
                    return
                }
                entity.age = 20
                kinveySave(dataStore: syncDataStore, entity: entity)
                
                expect(kinveyRemove(dataStore: networkDataStore, entity: entity).count).to(equal(1))
                
                expect(kinveyPush(dataStore: autoDataStore).count).to(equal(1))
            }
        }
        
        describe("Sync") {
            it("should push all items and pull all items") {
                kinveySave(dataStore: syncDataStore, numberOfItems: 3)
                
                kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                
                let result = kinveySync(dataStore: autoDataStore).result
                expect(result?.count).to(equal(3))
                expect(result?.entities.count).to(equal(5))
                
                expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(5))
                expect(kinveyFind(dataStore: networkDataStore).entities?.count).to(equal(5))
            }
            
            it("should push all items with a query and pull only the items conforming to that query") {
                kinveySave(
                    dataStore: syncDataStore,
                    entities: Person({ $0.age = 10 }), Person({ $0.age = 20 }), Person({ $0.age = 30 })
                )
                
                kinveySave(
                    dataStore: networkDataStore,
                    entities: Person({ $0.age = 15 }), Person({ $0.age = 25 })
                )
                
                let query = Query(\Person.age >= 20)
                let result = kinveySync(dataStore: autoDataStore, query: query).result
                expect(result?.count).to(equal(3))
                expect(result?.entities.count).to(equal(3))
                
                expect(kinveyFind(dataStore: syncDataStore, query: query).entities?.count).to(equal(3))
            }
            
            it("should return error if there is network connectivity for the push request and save the sync queue") {
                kinveySave(dataStore: syncDataStore, numberOfItems: 2)
                
                mockResponse(error: timeoutError)
                defer {
                    setURLProtocol(nil)
                }
                
                let errors = kinveySync(dataStore: autoDataStore).errors
                expect(errors?.count).to(equal(2))
                expect((errors?.first as? NSError)?.domain).to(equal(NSURLErrorDomain))
                expect((errors?.first as? NSError)?.code).to(equal(NSURLErrorTimedOut))
                expect((errors?.last as? NSError)?.domain).to(equal(NSURLErrorDomain))
                expect((errors?.last as? NSError)?.code).to(equal(NSURLErrorTimedOut))
                
                expect(autoDataStore.syncCount()).to(equal(2))
                
                let pendingSyncEntities = autoDataStore.pendingSyncEntities()
                expect(pendingSyncEntities.count).to(equal(2))
                expect(pendingSyncEntities.first?.buildRequest().httpMethod).to(equal("POST"))
                expect(pendingSyncEntities.last?.buildRequest().httpMethod).to(equal("POST"))
            }
            
            it("should push the data and return connectivity error if the pull request cannot connect") {
                kinveySave(dataStore: syncDataStore, numberOfItems: 2)
                kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                
                mockResponse { request in
                    switch request.httpMethod {
                    case "POST":
                        return HttpResponse(request: request)
                    default:
                        return HttpResponse(error: timeoutError)
                    }
                }
                defer {
                    setURLProtocol(nil)
                }
                
                let errors = kinveySync(dataStore: autoDataStore).errors
                expect(errors?.count).to(equal(1))
                expect((errors?.first as? NSError)?.domain).to(equal(NSURLErrorDomain))
                expect((errors?.first as? NSError)?.code).to(equal(NSURLErrorTimedOut))
                
                expect(autoDataStore.syncCount()).to(equal(0))
                expect(autoDataStore.pendingSyncEntities().count).to(equal(0))
            }
            
            it("should push all items and pull all items with tagged store") {
                let tag = UUID().uuidString
                
                kinveySave(dataStore: try DataStore<Person>.collection(.sync, tag: tag), numberOfItems: 3)
                kinveySave(dataStore: networkDataStore, numberOfItems: 2)
                
                let result = kinveySync(dataStore: try DataStore<Person>.collection(.auto, tag: tag)).result
                expect(result?.count).to(equal(3))
                expect(result?.entities.count).to(equal(5))
                
                expect(kinveyFind(dataStore: try DataStore<Person>.collection(.sync, tag: tag)).entities?.count).to(equal(5))
                expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(0))
                expect(kinveyFind(dataStore: networkDataStore).entities?.count).to(equal(5))
            }
        }
        
        describe("PendingSyncCount") {
            it("should return the count of entities waiting to be synced") {
                kinveySave(dataStore: syncDataStore, numberOfItems: 3)
                expect(autoDataStore.pendingSyncCount()).to(equal(3))
            }
            
            it("should return the count of created items waiting to be synced according to query") {
                // N/A
            }
            
            it("should return the count of updated items waiting to be synced according to query") {
                // N/A
            }
            
            it("should return the count of deleted items waiting to be synced according to query") {
                // N/A
            }
            
            it("should return the count of entities waiting to be synced with tagged store") {
                let tag = UUID().uuidString
                
                kinveySave(dataStore: try DataStore<Person>.collection(.sync, tag: tag), numberOfItems: 3)
                
                expect(try DataStore<Person>.collection(.auto, tag: tag).pendingSyncCount()).to(equal(3))
                expect(autoDataStore.pendingSyncCount()).to(equal(0))
            }
        }
        
        describe("PendingSyncEntities") {
            it("should return the entities waiting to be synced") {
                kinveySave(dataStore: syncDataStore, numberOfItems: 3)
                expect(autoDataStore.pendingSyncCount()).to(equal(3))
            }
            
            it("should return the created items waiting to be synced according to query") {
                // N/A
            }
            
            it("should return the updated items waiting to be synced according to query") {
                // N/A
            }
            
            it("should return the deleted items waiting to be synced according to query") {
                // N/A
            }
        }
        
        describe("ClearSync") {
            it("should clear all items from the sync queue") {
                kinveySave(dataStore: syncDataStore, numberOfItems: 3)
                
                expect(autoDataStore.clearSync()).to(equal(3))
                expect(autoDataStore.pendingSyncCount()).to(equal(0))
            }
            
            it("should clear the created items to be synced according to query") {
                // N/A
            }
            
            it("should clear the updated items to be synced according to query") {
                // N/A
            }
            
            it("should clear the deleted items to be synced according to query") {
                // N/A
            }
            
            it("should clear all items from the sync queue with tagged store") {
                let tag = UUID().uuidString
                
                kinveySave(dataStore: try DataStore<Person>.collection(.sync, tag: tag), numberOfItems: 3)
                
                let autoDataStoreTagged = try DataStore<Person>.collection(.auto, tag: tag)
                expect(autoDataStoreTagged.clearSync()).to(equal(3))
                expect(autoDataStoreTagged.pendingSyncCount()).to(equal(0))
                expect(autoDataStore.pendingSyncCount()).to(equal(0))
            }
        }
        
        describe("Clear") {
            it("should clear all entities from the cache and keep them in the backend") {
                kinveySave(dataStore: autoDataStore, numberOfItems: 2)
                
                expect(kinveyCount(dataStore: syncDataStore).count).to(equal(2))
                autoDataStore.clearCache()
                expect(kinveyCount(dataStore: syncDataStore).count).to(equal(0))
                
                expect(kinveyCount(dataStore: networkDataStore).count).to(equal(2))
            }
            
            it("should clear all items matching a query") {
                kinveySave(
                    dataStore: autoDataStore,
                    entities: Person({ $0.age = 10 }), Person({ $0.age = 20 }), Person({ $0.age = 30 })
                )
                
                expect(kinveyCount(dataStore: syncDataStore).count).to(equal(3))
                autoDataStore.clearCache(query: Query(\Person.age >= 20))
                
                expect(kinveyCount(dataStore: networkDataStore).count).to(equal(3))
                expect(kinveyCount(dataStore: syncDataStore).count).to(equal(1))
            }
            
            it("should clear only entities from the sync queue that match a query") {
                let entities = kinveySave(
                    dataStore: autoDataStore,
                    entities: Person({ $0.age = 10 }), Person({ $0.age = 20 }), Person({ $0.age = 30 })
                ).entities
                
                expect(entities?.count).to(equal(3))
                expect(entities?.first).toNot(beNil())
                expect(entities?[1]).toNot(beNil())
                expect(entities?.last).toNot(beNil())
                guard let first = entities?.first,
                    let middle = entities?[1],
                    let last = entities?.last
                else {
                    return
                }
                
                first.geolocation = GeoPoint(latitude: 10.0, longitude: 10.0)
                kinveySave(dataStore: syncDataStore, entity: first)
                
                middle.geolocation = GeoPoint(latitude: 20.0, longitude: 20.0)
                kinveySave(dataStore: syncDataStore, entity: middle)
                
                last.geolocation = GeoPoint(latitude: 30.0, longitude: 30.0)
                kinveySave(dataStore: syncDataStore, entity: last)
                
                expect(autoDataStore.pendingSyncCount()).to(equal(3))
                
                autoDataStore.clearCache(query: Query(\Person.age >= 20))
                
                expect(autoDataStore.pendingSyncCount()).to(equal(1))
            }
            
            it("should clear all items from the sync queue") {
                kinveySave(dataStore: syncDataStore, numberOfItems: 2)
                
                expect(autoDataStore.pendingSyncCount()).to(equal(2))
                
                autoDataStore.clearCache()
                
                expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(0))
                
                expect(autoDataStore.pendingSyncCount()).to(equal(0))
            }
            
            it("should clear local data for tagged store and only for it") {
                kinveySave(dataStore: autoDataStore, numberOfItems: 2)
                
                let tag = UUID().uuidString
                let autoDataStoreTagged = try DataStore<Person>.collection(.auto, tag: tag)
                kinveySave(dataStore: autoDataStoreTagged, numberOfItems: 2)
                
                autoDataStoreTagged.clearCache()
                
                expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(2))
                expect(kinveyFind(dataStore: try DataStore<Person>.collection(.sync, tag: tag)).entities?.count).to(equal(0))
            }
        }
        
        describe("Save") {
            it("should throw an error when trying to create an array of items") {
                // N/A
            }
            
            it("should create an item even if _id was not provided") {
                kinveySave(dataStore: autoDataStore, entity: Person())
                
                let entities = kinveyFind(dataStore: networkDataStore).entities
                expect(entities?.count).to(equal(1))
                expect(entities?.first?.entityId).toNot(beNil())
                expect(entities?.first?.entityId).toNot(equal(""))
                expect(entities?.first?.entityId?.starts(with: "tmp_")).to(beFalse())
                expect(entities?.first?.entityId).to(equal(entities?.first?.personId))
            }
            
            it("should create an item using the _id provided") {
                kinveySave(dataStore: autoDataStore, entity: Person({ $0.personId = "my_id" }))
                
                let entities = kinveyFind(dataStore: networkDataStore).entities
                expect(entities?.count).to(equal(1))
                expect(entities?.first?.entityId).toNot(beNil())
                expect(entities?.first?.entityId).to(equal("my_id"))
                expect(entities?.first?.entityId).to(equal(entities?.first?.personId))
            }
            
            it("should update an item with existing _id") {
                kinveySave(dataStore: autoDataStore, entity: Person({ $0.personId = "my_id" }))
                
                kinveySave(dataStore: autoDataStore, entity: Person({ $0.personId = "my_id"; $0.age = 10 }))
                
                let entities = kinveyFind(dataStore: networkDataStore).entities
                expect(entities?.count).to(equal(1))
                expect(entities?.first?.entityId).to(equal("my_id"))
                expect(entities?.first?.entityId).to(equal(entities?.first?.personId))
                expect(entities?.first?.age).to(equal(10))
            }
            
            it("should save locally the item if connectivity error occurs") {
                mockResponse(error: timeoutError)
                defer {
                    setURLProtocol(nil)
                }
                
                var error = kinveySave(dataStore: autoDataStore).error as? NSError
                expect(error?.domain).to(equal(NSURLErrorDomain))
                expect(error?.code).to(equal(NSURLErrorTimedOut))
                
                expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(1))
                
                error = kinveyFind(dataStore: networkDataStore).error as? NSError
                expect(error?.domain).to(equal(NSURLErrorDomain))
                expect(error?.code).to(equal(NSURLErrorTimedOut))
                
                let pendingSyncEntities = autoDataStore.pendingSyncEntities()
                expect(pendingSyncEntities.count).to(equal(1))
                expect(pendingSyncEntities.first?.buildRequest().httpMethod).to(equal("POST"))
            }
            
            it("should throw regular error for invalid operation") {
                mockResponse(httpResponse: httpResponseInsufficientCredentialsError)
                defer {
                    setURLProtocol(nil)
                }
                
                expect(kinveySave(dataStore: autoDataStore, entity: Person()).error?.localizedDescription).to(equal(insufficientCredentialsErrorDescription))
            }
            
            it("should create multiple sync operations with connectivity issues") {
                do {
                    mockResponse(error: timeoutError)
                    defer {
                        setURLProtocol(KinveyURLProtocol.self)
                    }
                    
                    var error = kinveySave(dataStore: autoDataStore).error as? NSError
                    expect(error?.domain).to(equal(NSURLErrorDomain))
                    expect(error?.code).to(equal(NSURLErrorTimedOut))
                    
                    error = kinveySave(dataStore: autoDataStore).error as? NSError
                    expect(error?.domain).to(equal(NSURLErrorDomain))
                    expect(error?.code).to(equal(NSURLErrorTimedOut))
                    
                    let pendingSyncEntities = autoDataStore.pendingSyncEntities()
                    expect(pendingSyncEntities.count).to(equal(2))
                    expect(pendingSyncEntities.first?.buildRequest().httpMethod).to(equal("POST"))
                    expect(pendingSyncEntities.last?.buildRequest().httpMethod).to(equal("POST"))
                    
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(2))
                    
                    error = kinveyFind(dataStore: networkDataStore).error as? NSError
                    expect(error?.domain).to(equal(NSURLErrorDomain))
                    expect(error?.code).to(equal(NSURLErrorTimedOut))
                }
                
                kinveyPush(dataStore: autoDataStore)
                
                expect(kinveyFind(dataStore: networkDataStore).entities?.count).to(equal(2))
            }
            
            it("should save locally an item with tagged store") {
                let tag = UUID().uuidString
                kinveySave(dataStore: try DataStore<Person>.collection(.auto, tag: tag), numberOfItems: 2)
                
                expect(kinveyFind(dataStore: try DataStore<Person>.collection(.sync, tag: tag)).entities?.count).to(equal(2))
                expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(0))
            }
        }
        
        describe("Create") {
            it("should throw an error when trying to create an array of items") {
                // N/A
            }
            
            it("should create an item even if _id was not provided") {
                kinveySave(dataStore: autoDataStore, entity: Person())
                
                let entities = kinveyFind(dataStore: networkDataStore).entities
                expect(entities?.count).to(equal(1))
                expect(entities?.first?.entityId).toNot(beNil())
                expect(entities?.first?.entityId).toNot(equal(""))
                expect(entities?.first?.entityId?.starts(with: "tmp_")).to(beFalse())
                expect(entities?.first?.entityId).to(equal(entities?.first?.personId))
            }
            
            it("should create an item using the _id provided") {
                kinveySave(dataStore: autoDataStore, entity: Person({ $0.personId = "my_id" }))
                
                let entities = kinveyFind(dataStore: networkDataStore).entities
                expect(entities?.count).to(equal(1))
                expect(entities?.first?.entityId).toNot(beNil())
                expect(entities?.first?.entityId).to(equal("my_id"))
                expect(entities?.first?.entityId).to(equal(entities?.first?.personId))
            }
            
            it("should update an item with existing _id") {
                kinveySave(dataStore: autoDataStore, entity: Person({ $0.personId = "my_id" }))
                
                kinveySave(dataStore: autoDataStore, entity: Person({ $0.personId = "my_id"; $0.age = 10 }))
                
                let entities = kinveyFind(dataStore: networkDataStore).entities
                expect(entities?.count).to(equal(1))
                expect(entities?.first?.entityId).to(equal("my_id"))
                expect(entities?.first?.entityId).to(equal(entities?.first?.personId))
                expect(entities?.first?.age).to(equal(10))
            }
            
            it("should save locally the item if connectivity error occurs") {
                mockResponse(error: timeoutError)
                defer {
                    setURLProtocol(nil)
                }
                
                var error = kinveySave(dataStore: autoDataStore).error as? NSError
                expect(error?.domain).to(equal(NSURLErrorDomain))
                expect(error?.code).to(equal(NSURLErrorTimedOut))
                
                expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(1))
                
                error = kinveyFind(dataStore: networkDataStore).error as? NSError
                expect(error?.domain).to(equal(NSURLErrorDomain))
                expect(error?.code).to(equal(NSURLErrorTimedOut))
                
                let pendingSyncEntities = autoDataStore.pendingSyncEntities()
                expect(pendingSyncEntities.count).to(equal(1))
                expect(pendingSyncEntities.first?.buildRequest().httpMethod).to(equal("POST"))
            }
            
            it("should throw regular error for invalid operation") {
                mockResponse(httpResponse: httpResponseInsufficientCredentialsError)
                defer {
                    setURLProtocol(nil)
                }
                
                expect(kinveySave(dataStore: autoDataStore, entity: Person()).error?.localizedDescription).to(equal(insufficientCredentialsErrorDescription))
            }
            
            it("should create multiple sync operations with connectivity issues") {
                do {
                    mockResponse(error: timeoutError)
                    defer {
                        setURLProtocol(KinveyURLProtocol.self)
                    }
                    
                    var error = kinveySave(dataStore: autoDataStore).error as? NSError
                    expect(error?.domain).to(equal(NSURLErrorDomain))
                    expect(error?.code).to(equal(NSURLErrorTimedOut))
                    
                    error = kinveySave(dataStore: autoDataStore).error as? NSError
                    expect(error?.domain).to(equal(NSURLErrorDomain))
                    expect(error?.code).to(equal(NSURLErrorTimedOut))
                    
                    let pendingSyncEntities = autoDataStore.pendingSyncEntities()
                    expect(pendingSyncEntities.count).to(equal(2))
                    expect(pendingSyncEntities.first?.buildRequest().httpMethod).to(equal("POST"))
                    expect(pendingSyncEntities.last?.buildRequest().httpMethod).to(equal("POST"))
                    
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(2))
                    
                    error = kinveyFind(dataStore: networkDataStore).error as? NSError
                    expect(error?.domain).to(equal(NSURLErrorDomain))
                    expect(error?.code).to(equal(NSURLErrorTimedOut))
                }
                
                kinveyPush(dataStore: autoDataStore)
                
                expect(kinveyFind(dataStore: networkDataStore).entities?.count).to(equal(2))
            }
            
            it("should save locally an item with tagged store") {
                let tag = UUID().uuidString
                kinveySave(dataStore: try DataStore<Person>.collection(.auto, tag: tag), numberOfItems: 2)
                
                expect(kinveyFind(dataStore: try DataStore<Person>.collection(.sync, tag: tag)).entities?.count).to(equal(2))
                expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(0))
            }
        }
        
        describe("Update") {
            it("should throw an error when trying to create an array of items") {
                // N/A
            }
            
            it("should throw an error for trying to update without supplying an _id") {
                // N/A
            }
            
            it("should create an item whose _id does not exist") {
                kinveySave(dataStore: autoDataStore)
                
                let entities1 = kinveyFind(dataStore: syncDataStore).entities
                expect(entities1?.count).to(equal(1))
                expect(entities1?.first?.metadata?.entityCreationTime).toNot(beNil())
                expect(entities1?.first?.metadata?.lastModifiedTime).toNot(beNil())
                
                let entities2 = kinveyFind(dataStore: networkDataStore).entities
                expect(entities2?.count).to(equal(1))
                expect(entities2?.first?.metadata?.entityCreationTime).toNot(beNil())
                expect(entities2?.first?.metadata?.lastModifiedTime).toNot(beNil())
                
                expect(entities2?.first?.metadata?.entityCreationTime).to(equal(entities1?.first?.metadata?.entityCreationTime))
                expect(entities2?.first?.metadata?.lastModifiedTime).to(equal(entities1?.first?.metadata?.lastModifiedTime))
            }
            
            it("should update an item with existing _id") {
                kinveySave(dataStore: autoDataStore, entity: Person({ $0.personId = "my_id" }))
                
                kinveySave(dataStore: autoDataStore, entity: Person({ $0.personId = "my_id"; $0.age = 10 }))
                
                let entities = kinveyFind(dataStore: networkDataStore).entities
                expect(entities?.count).to(equal(1))
                expect(entities?.first?.entityId).to(equal("my_id"))
                expect(entities?.first?.entityId).to(equal(entities?.first?.personId))
                expect(entities?.first?.age).to(equal(10))
            }
            
            it("should save locally the item if connectivity error occurs") {
                mockResponse(error: timeoutError)
                defer {
                    setURLProtocol(nil)
                }
                
                var error = kinveySave(dataStore: autoDataStore).error as? NSError
                expect(error?.domain).to(equal(NSURLErrorDomain))
                expect(error?.code).to(equal(NSURLErrorTimedOut))
                
                expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(1))
                
                error = kinveyFind(dataStore: networkDataStore).error as? NSError
                expect(error?.domain).to(equal(NSURLErrorDomain))
                expect(error?.code).to(equal(NSURLErrorTimedOut))
                
                let pendingSyncEntities = autoDataStore.pendingSyncEntities()
                expect(pendingSyncEntities.count).to(equal(1))
                expect(pendingSyncEntities.first?.buildRequest().httpMethod).to(equal("POST"))
            }
            
            it("should throw error if invalid credentials") {
                mockResponse(httpResponse: httpResponseInsufficientCredentialsError)
                defer {
                    setURLProtocol(nil)
                }
                
                expect(kinveySave(dataStore: autoDataStore, entity: Person()).error?.localizedDescription).to(equal(insufficientCredentialsErrorDescription))
            }
            
            it("should create multiple sync operations with connectivity issues") {
                do {
                    mockResponse(error: timeoutError)
                    defer {
                        setURLProtocol(KinveyURLProtocol.self)
                    }
                    
                    var error = kinveySave(dataStore: autoDataStore).error as? NSError
                    expect(error?.domain).to(equal(NSURLErrorDomain))
                    expect(error?.code).to(equal(NSURLErrorTimedOut))
                    
                    error = kinveySave(dataStore: autoDataStore).error as? NSError
                    expect(error?.domain).to(equal(NSURLErrorDomain))
                    expect(error?.code).to(equal(NSURLErrorTimedOut))
                    
                    let pendingSyncEntities = autoDataStore.pendingSyncEntities()
                    expect(pendingSyncEntities.count).to(equal(2))
                    expect(pendingSyncEntities.first?.buildRequest().httpMethod).to(equal("POST"))
                    expect(pendingSyncEntities.last?.buildRequest().httpMethod).to(equal("POST"))
                    
                    expect(kinveyFind(dataStore: autoDataStore).entities?.count).to(equal(2))
                    
                    error = kinveyFind(dataStore: networkDataStore).error as? NSError
                    expect(error?.domain).to(equal(NSURLErrorDomain))
                    expect(error?.code).to(equal(NSURLErrorTimedOut))
                }
                
                kinveyPush(dataStore: autoDataStore)
                
                expect(kinveyFind(dataStore: networkDataStore).entities?.count).to(equal(2))
            }
            
            it("should save locally an item with tagged store") {
                let tag = UUID().uuidString
                kinveySave(dataStore: try DataStore<Person>.collection(.auto, tag: tag), numberOfItems: 2)
                
                expect(kinveyFind(dataStore: try DataStore<Person>.collection(.sync, tag: tag)).entities?.count).to(equal(2))
                expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(0))
            }
        }
        
        describe("Remove") {
            it("should remove items matching a query") {
                kinveySave(
                    dataStore: autoDataStore,
                    entities: Person({ $0.age = 10 }), Person({ $0.age = 20 }), Person({ $0.age = 30 })
                )
                
                expect(kinveyRemove(dataStore: autoDataStore, query: Query(\Person.age >= 20)).count).to(equal(2))
                
                var entities = kinveyFind(dataStore: networkDataStore).entities
                expect(entities?.count).to(equal(1))
                expect(entities?.first?.age).to(equal(10))
                
                entities = kinveyFind(dataStore: syncDataStore).entities
                expect(entities?.count).to(equal(1))
                expect(entities?.first?.age).to(equal(10))
            }
            
            it("should remove items from the backend even if they are deleted locally") {
                kinveySave(
                    dataStore: autoDataStore,
                    entities: Person({ $0.personId = "my_id1"; $0.age = 10 }), Person({ $0.personId = "my_id2"; $0.age = 20 })
                )
                
                let query = Query(\Person.age == 20)
                
                kinveyRemove(dataStore: syncDataStore, query: query)
                
                expect(kinveyRemove(dataStore: autoDataStore, query: query).count).to(equal(1))
                
                expect(kinveyFind(dataStore: networkDataStore, id: "my_id2").error?.localizedDescription).to(equal("This entity not found in the collection."))
            }
            
            it("should return 0 when no items are deleted") {
                kinveySave(
                    dataStore: autoDataStore,
                    entities: Person({ $0.age = 10 }), Person({ $0.age = 20 })
                )
                
                expect(kinveyRemove(dataStore: autoDataStore, query: Query(\Person.age > 20)).count).to(equal(0))
            }
            
            it("should return an error for invalid query") {
                // N/A
            }
            
            it("should remove item locally and create delete operation in the sync queue with connectivity error") {
                kinveySave(
                    dataStore: autoDataStore,
                    entities: Person({ $0.age = 10 }), Person({ $0.age = 20 }), Person({ $0.age = 30 })
                )
                
                let query = Query(\Person.age >= 20)
                
                do {
                    mockResponse(error: timeoutError)
                    defer {
                        setURLProtocol(KinveyURLProtocol.self)
                    }
                    
                    let error = kinveyRemove(dataStore: autoDataStore, query: query).error as? NSError
                    expect(error?.domain).to(equal(NSURLErrorDomain))
                    expect(error?.code).to(equal(NSURLErrorTimedOut))
                }
                
                let pendingSyncEntities = autoDataStore.pendingSyncEntities()
                expect(pendingSyncEntities.count).to(equal(1))
                expect(pendingSyncEntities.first?.buildRequest().httpMethod).to(equal("DELETE"))
                expect(pendingSyncEntities.first?.buildRequest().url).toNot(beNil())
                guard let url = pendingSyncEntities.first?.buildRequest().url else {
                    return
                }
                let queryItem = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems?.filter({ $0.name == "query" }).first?.value
                expect(queryItem).to(equal("{\"age\":{\"$gte\":20}}"))
                
                expect(kinveyFind(dataStore: syncDataStore, query: query).entities?.count).to(equal(0))
            }
            
            it("should delete locally stored items that are deleted from the backend") {
                kinveySave(
                    dataStore: autoDataStore,
                    entities: Person({ $0.personId = "my_id1"; $0.age = 10 }), Person({ $0.personId = "my_id2"; $0.age = 20 }), Person({ $0.personId = "my_id3"; $0.age = 30 })
                )
                
                kinveyRemove(dataStore: networkDataStore, query: Query(\Person.age == 10))
                expect(kinveyRemove(dataStore: autoDataStore, query: Query(\Person.age < 15)).count).to(equal(0))
                expect(kinveyFind(dataStore: syncDataStore, id: "my_id1").error?.localizedDescription).to(equal("This entity not found in the collection."))
            }
            
            it("should delete items with tagged store") {
                let tag = UUID().uuidString
                let autoDataStoreTagged = try DataStore<Person>.collection(.auto, tag: tag)
                kinveySave(dataStore: autoDataStoreTagged)
                kinveySave(dataStore: autoDataStore)
                
                let syncDataStoreTagged = try DataStore<Person>.collection(.sync, tag: tag)
                expect(kinveyFind(dataStore: syncDataStoreTagged).entities?.count).to(equal(1))
                
                kinveyRemove(dataStore: autoDataStoreTagged)
                
                expect(kinveyFind(dataStore: syncDataStoreTagged).entities?.count).to(equal(0))
                expect(kinveyFind(dataStore: syncDataStore).entities?.count).to(equal(1))
            }
        }
        
        describe("RemoveById") {
            it("should remove entity with specified id") {
                kinveySave(
                    dataStore: autoDataStore,
                    entities: Person({ $0.personId = "my_id1"; $0.age = 10 }), Person({ $0.personId = "my_id2"; $0.age = 20 })
                )
                
                kinveyRemove(dataStore: autoDataStore, id: "my_id2")
                
                expect(kinveyFind(dataStore: networkDataStore, id: "my_id2").error?.localizedDescription).to(equal("This entity not found in the collection."))
                expect(kinveyFind(dataStore: syncDataStore, id: "my_id2").error?.localizedDescription).to(equal("This entity not found in the collection."))
            }
            
            it("should throw error for missing id") {
                // N/A
            }
            
            it("should remove item locally and create delete operation in the sync queue with connectivity error") {
                kinveySave(
                    dataStore: autoDataStore,
                    entity: Person({ $0.personId = "my_id1"; $0.age = 10 })
                )
                
                mockResponse(error: timeoutError)
                defer {
                    setURLProtocol(KinveyURLProtocol.self)
                }
                
                let error = kinveyRemove(dataStore: autoDataStore, id: "my_id1").error as? NSError
                expect(error?.domain).to(equal(NSURLErrorDomain))
                expect(error?.code).to(equal(NSURLErrorTimedOut))
                
                let pendingSyncEntities = autoDataStore.pendingSyncEntities()
                expect(pendingSyncEntities.count).to(equal(1))
                expect(pendingSyncEntities.first?.buildRequest().httpMethod).to(equal("DELETE"))
                
                expect(kinveyFind(dataStore: syncDataStore, id: "my_id1").error?.localizedDescription).to(equal("This entity not found in the collection."))
            }
            
            it("should throw error for non-existing id") {
                expect(kinveyRemove(dataStore: autoDataStore, id: UUID().uuidString).error?.localizedDescription).to(equal("This entity not found in the collection."))
            }
            
            it("should delete locally stored items that are deleted from the backend") {
                kinveySave(
                    dataStore: autoDataStore,
                    entities: Person({ $0.personId = "my_id1"; $0.age = 10 }), Person({ $0.personId = "my_id2"; $0.age = 20 })
                )
                
                kinveyRemove(dataStore: networkDataStore, id: "my_id2")
                
                expect(kinveyRemove(dataStore: autoDataStore, id: "my_id2").error?.localizedDescription).to(equal("This entity not found in the collection."))
                expect(kinveyFind(dataStore: syncDataStore, id: "my_id2").error?.localizedDescription).to(equal("This entity not found in the collection."))
            }
            
            it("Retrieving data. Wait a few seconds and try to cut or copy again.") {
                let tag = UUID().uuidString
                let autoDataStoreTagged = try DataStore<Person>.collection(.auto, tag: tag)
                
                kinveySave(
                    dataStore: autoDataStoreTagged,
                    entities: Person({ $0.personId = "my_id1"; $0.age = 10 }), Person({ $0.personId = "my_id2"; $0.age = 20 })
                )
                
                kinveyRemove(dataStore: autoDataStoreTagged, id: "my_id2")
                
                expect(kinveyFind(dataStore: networkDataStore, id: "my_id2").error?.localizedDescription).to(equal("This entity not found in the collection."))
                expect(kinveyFind(dataStore: try DataStore<Person>.collection(.sync, tag: tag), id: "my_id2").error?.localizedDescription).to(equal("This entity not found in the collection."))
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
