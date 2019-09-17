//
//  MultiInsertSpec.swift
//  Kinvey Specs
//
//  Created by Victor Hugo Carvalho Barros on 2019-06-10.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Quick
import Nimble
@testable import Kinvey

class MultiInsertSpec: QuickSpec {
    
    override func spec() {
        beforeEach {
            setURLProtocol(KinveyURLProtocol.self)
            
            kinveyInitialize()
            kinveyLogin()
        }
        afterEach {
            setURLProtocol(KinveyURLProtocol.self)
            kinveyLogout()
            setURLProtocol(nil)
            KinveyURLProtocol.reset()
        }
        
        describe("Network Store") {
            var networkDataStore: DataStore<Person>!
            beforeEach {
                do {
                    networkDataStore = try DataStore<Person>.collection(type: .network)
                } catch {
                    fail(error.localizedDescription)
                }
            }
            context("save()") {
                context("With API version 4 or less") {
                    let restApiVersion = Kinvey.restApiVersion
                    beforeEach {
                        Kinvey.restApiVersion = 4
                    }
                    afterEach {
                        Kinvey.restApiVersion = restApiVersion
                    }
                    it("should return an error with API version 4 or less") {
                        let error = kinveySaveMulti(dataStore: networkDataStore, entities: Person { $0.name = "Victor" }).error
                        
                        expect(error).toNot(beNil())
                        expect(error as? Kinvey.Error).toNot(beNil())
                        guard let kinveyError = error as? Kinvey.Error else {
                            return
                        }
                        switch kinveyError {
                        case .featureUnavailable(let debug, let description):
                            expect(debug).to(equal("Inserting multiple entities is not available in this Kinvey API version"))
                            expect(description).to(equal("Requested functionality is unavailable in this API version."))
                        default:
                            fail(kinveyError.localizedDescription)
                        }
                    }
                    it("should send POST with a single item with no _id") {
                        var entity = kinveySave(dataStore: networkDataStore, entity: Person { $0.name = "Victor" }).entity
                        expect(entity).toNot(beNil())
                        expect(entity?.entityId).toNot(beNil())
                        
                        guard let entityId = entity?.entityId else {
                            return
                        }
                        
                        entity = kinveyFind(dataStore: networkDataStore, id: entityId).result
                        expect(entity).toNot(beNil())
                        expect(entity?.entityId).toNot(beNil())
                    }
                    it("should send PUT with a single item with _id") {
                        var entity = kinveySave(dataStore: networkDataStore, entity: Person { $0.name = "Victor" }).entity
                        expect(entity).toNot(beNil())
                        expect(entity?.entityId).toNot(beNil())
                        expect(entity?.name).to(equal("Victor"))
                        
                        guard let entityId = entity?.entityId else {
                            return
                        }
                        guard let entityUnwrapped = entity else {
                            return
                        }
                        
                        entityUnwrapped.name = "Hugo"
                        entity = kinveySave(dataStore: networkDataStore, entity: entityUnwrapped).entity
                        expect(entity).toNot(beNil())
                        expect(entity?.entityId).to(equal(entityId))
                        expect(entity?.name).to(equal("Hugo"))
                        
                        entity = kinveyFind(dataStore: networkDataStore, id: entityId).result
                        expect(entity).toNot(beNil())
                        expect(entity?.entityId).to(equal(entityId))
                        expect(entity?.name).to(equal("Hugo"))
                    }
                    xit("should accept an array of items") {
                        let entity = kinveySave(dataStore: networkDataStore, entity: Person { $0.name = "Victor" }).entity
                        expect(entity).toNot(beNil())
                        expect(entity?.entityId).toNot(beNil())
                        expect(entity?.name).to(equal("Victor"))
                        
                        guard let entityUnwrapped = entity else {
                            return
                        }
                        
                        entityUnwrapped.name = "Victor 2"
                        let error = kinveySaveMulti(dataStore: networkDataStore, entities: entityUnwrapped, Person { $0.name = "Hugo" }).error
                        expect(error).toNot(beNil())
                        expect(error as? Kinvey.Error).toNot(beNil())
                        guard let kinveyError = error as? Kinvey.Error else {
                            return
                        }
                        switch kinveyError {
                        case .featureUnavailable(let debug, let description):
                            expect(debug).to(equal("Inserting multiple entities is not available in this Kinvey API version"))
                            expect(description).to(equal("Requested functionality is unavailable in this API version."))
                        default:
                            fail(kinveyError.localizedDescription)
                        }
                    }
                }
                context("API version 5") {
                    let restApiVersion = Kinvey.restApiVersion
                    beforeEach {
                        Kinvey.restApiVersion = 5
                    }
                    afterEach {
                        Kinvey.restApiVersion = restApiVersion
                    }
                    context("With single object") {
                        it("should send POST with a single item with no _id") {
                            var entity = kinveySave(dataStore: networkDataStore).entity
                            expect(entity).toNot(beNil())
                            expect(entity?.entityId).toNot(beNil())
                            
                            guard let entityId = entity?.entityId else {
                                return
                            }
                            
                            entity = kinveyFind(dataStore: networkDataStore, id: entityId).result
                            expect(entity).toNot(beNil())
                            expect(entity?.entityId).toNot(beNil())
                            expect(entity?.entityId).to(equal(entityId))
                        }
                        it("should send PUT with a single item with _id") {
                            var entity = kinveySave(dataStore: networkDataStore).entity
                            expect(entity).toNot(beNil())
                            expect(entity?.entityId).toNot(beNil())
                            
                            guard let entityId = entity?.entityId else {
                                return
                            }
                            guard let entityUnWrapped = entity else {
                                return
                            }
                            
                            entityUnWrapped.name = "Victor"
                            entity = kinveySave(dataStore: networkDataStore, entity: entityUnWrapped).entity
                            expect(entity).toNot(beNil())
                            expect(entity?.entityId).toNot(beNil())
                            expect(entity?.entityId).to(equal(entityId))
                            expect(entity?.name).to(equal("Victor"))
                            
                            let entities = kinveyFind(dataStore: networkDataStore).entities
                            expect(entities?.count).to(equal(1))
                            expect(entities?.first?.entityId).toNot(beNil())
                            expect(entities?.first?.entityId).to(equal(entityId))
                        }
                    }
                    context("With an array") {
                        it("should send POST multi-insert request for array of items with no _id") {
                            let result = kinveySaveMulti(dataStore: networkDataStore, entities: Person { $0.name = "Victor" }, Person { $0.name = "Hugo" }).result
                            
                            expect(result).toNot(beNil())
                            expect(result?.entities.count).to(equal(2))
                            expect(result?.entities.map({ $0?.name })).to(contain("Victor"))
                            expect(result?.entities.map({ $0?.name })).to(contain("Hugo"))
                            expect(result?.errors.count).to(equal(0))
                            
                            let entities = kinveyFind(dataStore: networkDataStore).entities
                            expect(entities).toNot(beNil())
                            expect(entities?.count).to(equal(2))
                            expect(entities?.map({ $0.name })).to(contain("Victor"))
                            expect(entities?.map({ $0.name })).to(contain("Hugo"))
                        }
                        it("should sent PUT requests for an array of items with _id") {
                            let id1 = UUID().uuidString
                            let id2 = UUID().uuidString
                            let result = kinveySaveMulti(
                                dataStore: networkDataStore,
                                entities: [
                                    Person { $0.entityId = id1 },
                                    Person { $0.entityId = id2 }
                                ]
                            ).result
                            
                            expect(result).toNot(beNil())
                            expect(result?.entities.count).to(equal(2))
                            expect(result?.entities.map({ $0?.entityId })).to(contain([id1, id2]))
                            expect(result?.entities.first??.entityId).to(equal(id1))
                            expect(result?.entities.last??.entityId).to(equal(id2))
                            expect(result?.errors.count).to(equal(0))
                            
                            let entities = kinveyFind(dataStore: networkDataStore).entities
                            expect(entities).toNot(beNil())
                            expect(entities?.count).to(equal(2))
                        }
                        it("should combine POST and PUT requests for items with and without _id") {
                            let id1 = UUID().uuidString
                            let id2 = UUID().uuidString
                            let result = kinveySaveMulti(
                                dataStore: networkDataStore,
                                entities: [
                                    Person { $0.entityId = id1 },
                                    Person { $0.entityId = id2 },
                                    Person(),
                                    Person()
                                ]
                            ).result
                            
                            expect(result).toNot(beNil())
                            expect(result?.entities.count).to(equal(4))
                            expect(result?.entities.compactMap({ $0 }).count).to(equal(4))
                            expect(result?.errors.count).to(equal(0))
                            guard let resultEntities = result?.entities.compactMap({ $0 }), resultEntities.count == 4 else {
                                return
                            }
                            expect(resultEntities[0].entityId).to(equal(id1))
                            expect(resultEntities[1].entityId).to(equal(id2))
                            expect(resultEntities[2].entityId).toNot(beNil())
                            expect(resultEntities[3].entityId).toNot(beNil())
                            
                            let entities = kinveyFind(dataStore: networkDataStore).entities
                            expect(entities).toNot(beNil())
                            expect(entities?.count).to(equal(4))
                        }
                        it("should return an error for an empty array") {
                            let error = kinveySaveMulti(
                                dataStore: networkDataStore,
                                entities: []
                            ).error
                            expect(error).toNot(beNil())
                            expect(error as? Kinvey.Error).toNot(beNil())
                            guard let kinveyError = error as? Kinvey.Error else {
                                return
                            }
                            switch kinveyError {
                            case .badRequest(let httpResponse, let data, let description):
                                expect(httpResponse).to(beNil())
                                expect(data).to(beNil())
                                expect(description).to(equal("Request body cannot be an empty array"))
                            default:
                                fail(kinveyError.localizedDescription)
                            }
                        }
                        it("should return an error when all items fail with multi-insert for invalid credentials") {
                            mockResponse(
                                statusCode: 401,
                                json: [
                                    "error": "InvalidCredentials",
                                    "description": "Invalid credentials. Please retry your request with correct credentials.",
                                    "debug": "Unable to validate the authorization token included in the request"
                                ]
                            )
                            defer {
                                setURLProtocol(nil)
                            }
                            let error = kinveySaveMulti(
                                dataStore: networkDataStore,
                                entities: [
                                    Person(),
                                    Person()
                                ]
                            ).error
                            expect(error).toNot(beNil())
                            expect(error as? Kinvey.Error).toNot(beNil())
                            
                            guard let kinveyError = error as? Kinvey.Error else {
                                return
                            }
                            switch kinveyError {
                            case .invalidCredentials(let httpResponse, let data, let debug, let description):
                                expect(httpResponse?.statusCode).to(equal(401))
                                expect(debug).to(equal("Unable to validate the authorization token included in the request"))
                                expect(description).to(equal("Invalid credentials. Please retry your request with correct credentials."))
                            default:
                                fail(kinveyError.localizedDescription)
                            }
                        }
                        it("should return an array of errors for all items failing for different reasons") {
                            let id1 = UUID().uuidString
                            let id2 = UUID().uuidString
                            mockResponse(
                                statusCode: 207,
                                json: [
                                    "entities": [
                                        nil,
                                        nil
                                    ],
                                    "errors" : [
                                        [
                                            "index": 0,
                                            "code": 11000,
                                            "errmsg": "E11000 duplicate key error collection: kdb1.kid1.Person index: _id_ dup key: { : \"\(id1)\" }"
                                        ],
                                        [
                                            "index": 1,
                                            "code": 11000,
                                            "errmsg": "E11000 duplicate key error collection: kdb1.kid1.Person index: _id_ dup key: { : \"\(id2)\" }"
                                        ]
                                    ]
                                ]
                            )
                            defer {
                                setURLProtocol(nil)
                            }
                            
                            let result = kinveySaveMulti(
                                dataStore: networkDataStore,
                                entities: [
                                    Person { $0.entityId = id1 },
                                    Person { $0.entityId = id2 }
                                ]
                            ).result
                            
                            expect(result).toNot(beNil())
                            guard let resultUnwrapped = result else {
                                return
                            }
                            expect(resultUnwrapped.entities.count).to(equal(2))
                            expect(resultUnwrapped.entities.first).toNot(beNil())
                            expect(resultUnwrapped.entities.last).toNot(beNil())
                            guard let firstEntity = resultUnwrapped.entities.first,
                                let lastEntity = resultUnwrapped.entities.last
                            else {
                                return
                            }
                            expect(firstEntity).to(beNil())
                            expect(lastEntity).to(beNil())
                            
                            expect(resultUnwrapped.errors.count).to(equal(2))
                            expect(resultUnwrapped.errors.first).toNot(beNil())
                            expect(resultUnwrapped.errors.first as? MultiSaveError).toNot(beNil())
                            expect(resultUnwrapped.errors.last).toNot(beNil())
                            expect(resultUnwrapped.errors.last as? MultiSaveError).toNot(beNil())
                            guard let firstError = resultUnwrapped.errors.first as? MultiSaveError,
                                let lastError = resultUnwrapped.errors.last as? MultiSaveError
                            else {
                                return
                            }
                            expect(firstError.index).to(equal(0))
                            expect(firstError.code).to(equal(11000))
                            expect(firstError.message).to(equal("E11000 duplicate key error collection: kdb1.kid1.Person index: _id_ dup key: { : \"\(id1)\" }"))
                            expect(lastError.index).to(equal(1))
                            expect(lastError.code).to(equal(11000))
                            expect(lastError.message).to(equal("E11000 duplicate key error collection: kdb1.kid1.Person index: _id_ dup key: { : \"\(id2)\" }"))
                        }
                        it("should return an entities and errors when some requests fail and some succeed") {
                            let id1 = UUID().uuidString
                            mockResponse(
                                statusCode: 207,
                                json: [
                                    "entities": [
                                        nil,
                                        [
                                            "name": "Hugo",
                                            "_acl": [
                                                "creator": UUID().uuidString
                                            ],
                                            "_kmd": [
                                                "lmt": Date().toISO8601(),
                                                "ect": Date().toISO8601()
                                            ],
                                            "_id": UUID().uuidString
                                        ]
                                    ],
                                    "errors" : [
                                        [
                                            "index": 0,
                                            "code": 11000,
                                            "errmsg": "E11000 duplicate key error collection: kdb1.kid1.Person index: _id_ dup key: { : \"\(id1)\" }"
                                        ]
                                    ]
                                ]
                            )
                            defer {
                                setURLProtocol(nil)
                            }
                            
                            let result = kinveySaveMulti(
                                dataStore: networkDataStore,
                                entities: [
                                    Person { $0.entityId = id1; $0.name = "Victor" },
                                    Person { $0.name = "Hugo" }
                                ]
                            ).result
                            
                            expect(result).toNot(beNil())
                            guard let resultUnwrapped = result else {
                                return
                            }
                            expect(resultUnwrapped.entities.count).to(equal(2))
                            expect(resultUnwrapped.entities.first).toNot(beNil())
                            expect(resultUnwrapped.entities.last).toNot(beNil())
                            guard let firstEntity = resultUnwrapped.entities.first,
                                let lastEntity = resultUnwrapped.entities.last
                                else {
                                    return
                            }
                            expect(firstEntity).to(beNil())
                            expect(lastEntity).toNot(beNil())
                            expect(lastEntity?.name).to(equal("Hugo"))
                            
                            expect(resultUnwrapped.errors.count).to(equal(1))
                            expect(resultUnwrapped.errors.first).toNot(beNil())
                            expect(resultUnwrapped.errors.last).toNot(beNil())
                            guard let firstError = resultUnwrapped.errors.first as? MultiSaveError else {
                                return
                            }
                            expect(firstError.index).to(equal(0))
                            expect(firstError.code).to(equal(11000))
                            expect(firstError.message).to(equal("E11000 duplicate key error collection: kdb1.kid1.Person index: _id_ dup key: { : \"\(id1)\" }"))
                        }
                        it("should return PUT failures at the matching index") {
                            let id1 = UUID().uuidString
                            mockResponse(
                                statusCode: 207,
                                json: [
                                    "entities": [
                                        [
                                            "name": "Victor",
                                            "_acl": [
                                                "creator": UUID().uuidString
                                            ],
                                            "_kmd": [
                                                "lmt": Date().toISO8601(),
                                                "ect": Date().toISO8601()
                                            ],
                                            "_id": UUID().uuidString
                                        ],
                                        nil
                                    ],
                                    "errors" : [
                                        [
                                            "index": 1,
                                            "code": 11000,
                                            "errmsg": "E11000 duplicate key error collection: kdb1.kid1.Person index: _id_ dup key: { : \"\(id1)\" }"
                                        ]
                                    ]
                                ]
                            )
                            defer {
                                setURLProtocol(nil)
                            }
                            
                            let result = kinveySaveMulti(
                                dataStore: networkDataStore,
                                entities: [
                                    Person { $0.name = "Victor" },
                                    Person { $0.entityId = id1; $0.name = "Hugo" }
                                ]
                            ).result
                            
                            expect(result).toNot(beNil())
                            guard let resultUnwrapped = result else {
                                return
                            }
                            expect(resultUnwrapped.entities.count).to(equal(2))
                            expect(resultUnwrapped.entities.first).toNot(beNil())
                            expect(resultUnwrapped.entities.last).toNot(beNil())
                            guard let firstEntity = resultUnwrapped.entities.first,
                                let lastEntity = resultUnwrapped.entities.last
                            else {
                                return
                            }
                            expect(firstEntity).toNot(beNil())
                            expect(firstEntity?.name).to(equal("Victor"))
                            expect(lastEntity).to(beNil())
                            
                            expect(resultUnwrapped.errors.count).to(equal(1))
                            expect(resultUnwrapped.errors.first).toNot(beNil())
                            expect(resultUnwrapped.errors.last).toNot(beNil())
                            guard let firstError = resultUnwrapped.errors.first as? MultiSaveError else {
                                return
                            }
                            expect(firstError.index).to(equal(1))
                            expect(firstError.code).to(equal(11000))
                            expect(firstError.message).to(equal("E11000 duplicate key error collection: kdb1.kid1.Person index: _id_ dup key: { : \"\(id1)\" }"))
                        }
                    }
                    context("more than 100 items") {
                        it("error indexes are correct") {
                            let entities = (1 ... 150).map { i in
                                Person { $0.name = "Person \(i)" }
                            }
                            var count = 0
                            mockResponse { request in
                                defer {
                                    count += 1
                                }
                                let json = try! JSONSerialization.jsonObject(with: request) as! [[String : Any]]
                                let response = HttpResponse(request: request, urlProcotolType: KinveyURLProtocol.self)
                                let data = response.chunks?.reduce(Data()) { (data, chunk) -> Data in
                                    return data + chunk.data
                                }
                                var jsonObject = try! JSONSerialization.jsonObject(with: data!) as! [String : Any]
                                var entities = jsonObject["entities"] as! [[String : Any]?]
                                var errors = jsonObject["errors"] as! [[String : Any]]
                                switch count {
                                case 0:
                                    XCTAssertEqual(json.count, 100)
                                    let index = 10
                                    let entity = entities[index]
                                    entities[index] = nil
                                    errors.append([
                                        "index" : index,
                                        "code" : 100,
                                        "errmsg" : "Entity not saved"
                                    ])
                                case 1:
                                    XCTAssertEqual(json.count, 50)
                                    let index = 20
                                    let entity = entities[index]
                                    entities[index] = nil
                                    errors.append([
                                        "index" : index,
                                        "code" : 200,
                                        "errmsg" : "Entity not saved"
                                    ])
                                default:
                                    XCTFail("request not expected")
                                }
                                jsonObject["entities"] = entities
                                jsonObject["errors"] = errors
                                return HttpResponse(statusCode: response.statusCode, headerFields: response.headerFields, json: jsonObject)
                            }
                            defer {
                                setURLProtocol(nil)
                            }
                            
                            let result = kinveySaveMulti(
                                dataStore: networkDataStore,
                                entities: entities
                            ).result
                            
                            XCTAssertEqual(count, 2)
                            XCTAssertNotNil(result)
                            guard let resultUnwrapped = result else {
                                return
                            }
                            XCTAssertEqual(resultUnwrapped.entities.count, 150)
                            XCTAssertEqual(resultUnwrapped.entities.filter({ $0 != nil }).count, 148)
                            XCTAssertEqual(resultUnwrapped.entities.filter({ $0 == nil }).count, 2)
                            for (offset, entity) in resultUnwrapped.entities.enumerated() {
                                switch offset {
                                case 10, 120:
                                    XCTAssertNil(entity)
                                default:
                                    XCTAssertNotNil(entity)
                                }
                            }
                            XCTAssertEqual(resultUnwrapped.errors.count, 2)
                            XCTAssertEqual((resultUnwrapped.errors.first as? IndexableError)?.index, 10)
                            XCTAssertEqual((resultUnwrapped.errors.last as? IndexableError)?.index, 120)
                        }
                    }
                }
            }
        }
        describe("Sync store") {
            let restApiVersion = Kinvey.restApiVersion
            var syncDataStore: DataStore<Person>!
            beforeEach {
                Kinvey.restApiVersion = 5
                do {
                    syncDataStore = try DataStore<Person>.collection(type: .sync)
                } catch {
                    fail(error.localizedDescription)
                }
            }
            afterEach {
                Kinvey.restApiVersion = restApiVersion
            }
            context("save()") {
                context("With single object") {
                    it("should send POST with a single item with no _id") {
                        let entity = kinveySave(dataStore: syncDataStore).entity
                        
                        expect(syncDataStore.pendingSyncCount()).to(equal(1))
                        expect(syncDataStore.pendingSyncEntities().count).to(equal(1))
                        expect(syncDataStore.pendingSyncEntities().first?.objectId).to(equal(entity?.entityId))
                        
                        let entities = kinveyFind(dataStore: syncDataStore).entities
                        expect(entities?.count).to(equal(1))
                        expect(entities?.first?.entityId).to(equal(entity?.entityId))
                    }
                    it("should send PUT with a single item with _id") {
                        let id = UUID().uuidString
                        let entity = kinveySave(dataStore: syncDataStore, entity: Person { $0.personId = id }).entity
                        
                        expect(entity?.personId).to(equal(id))
                        
                        expect(syncDataStore.pendingSyncCount()).to(equal(1))
                        expect(syncDataStore.pendingSyncEntities().count).to(equal(1))
                        expect(syncDataStore.pendingSyncEntities().first?.objectId).to(equal(id))
                        
                        let entities = kinveyFind(dataStore: syncDataStore).entities
                        expect(entities?.count).to(equal(1))
                        expect(entities?.first?.entityId).to(equal(id))
                    }
                }
                context("With an array") {
                    it("should send save an array of items with no _id") {
                        let result = kinveySaveMulti(
                                dataStore: syncDataStore,
                            entities: [
                                Person { $0.name = "Victor" },
                                Person { $0.name = "Hugo" }
                            ]
                        ).result
                        expect(result).toNot(beNil())
                        guard let resultUnwrapped = result else {
                            return
                        }
                        expect(resultUnwrapped.entities.count).to(equal(2))
                        expect(resultUnwrapped.errors.count).to(equal(0))
                        
                        expect(syncDataStore.pendingSyncCount()).to(equal(2))
                        expect(syncDataStore.pendingSyncEntities().count).to(equal(2))
                        expect(syncDataStore.pendingSyncOperations().count).to(equal(1))
                        
                        let entities = kinveyFind(dataStore: syncDataStore).entities
                        expect(entities?.count).to(equal(2))
                    }
                    it("should save an array of items with _id") {
                        let id1 = UUID().uuidString
                        let id2 = UUID().uuidString
                        let result = kinveySaveMulti(
                            dataStore: syncDataStore,
                            entities: [
                                Person { $0.personId = id1; $0.name = "Victor" },
                                Person { $0.personId = id2; $0.name = "Hugo" }
                            ]
                        ).result
                        expect(result).toNot(beNil())
                        guard let resultUnwrapped = result else {
                            return
                        }
                        expect(resultUnwrapped.entities.count).to(equal(2))
                        expect(resultUnwrapped.errors.count).to(equal(0))
                        
                        expect(syncDataStore.pendingSyncCount()).to(equal(2))
                        expect(syncDataStore.pendingSyncEntities().count).to(equal(2))
                        expect(syncDataStore.pendingSyncOperations().count).to(equal(2))
                        
                        let entities = kinveyFind(dataStore: syncDataStore).entities
                        expect(entities?.count).to(equal(2))
                        expect(entities?.first?.personId).to(equal(id1))
                        expect(entities?.last?.personId).to(equal(id2))
                    }
                    it("should save and array of items with and without _id") {
                        let result = kinveySaveMulti(
                            dataStore: syncDataStore,
                            entities: [
                                Person { $0.entityId = UUID().uuidString; $0.name = "Victor" },
                                Person { $0.name = "Hugo" }
                            ]
                        ).result
                        expect(result).toNot(beNil())
                        guard let resultUnwrapped = result else {
                            return
                        }
                        expect(resultUnwrapped.entities.count).to(equal(2))
                        expect(resultUnwrapped.errors.count).to(equal(0))
                        
                        expect(syncDataStore.pendingSyncCount()).to(equal(2))
                        expect(syncDataStore.pendingSyncEntities().count).to(equal(2))
                        expect(syncDataStore.pendingSyncOperations().count).to(equal(1))
                        
                        let entities = kinveyFind(dataStore: syncDataStore).entities
                        expect(entities?.count).to(equal(2))
                    }
                    it("should return an error for an empty array") {
                        let error = kinveySaveMulti(
                            dataStore: syncDataStore,
                            entities: []
                        ).error
                        expect(error).toNot(beNil())
                        expect(error?.localizedDescription).to(equal("Request body cannot be an empty array"))
                        
                        expect(syncDataStore.pendingSyncCount()).to(equal(0))
                        expect(syncDataStore.pendingSyncEntities().count).to(equal(0))
                        
                        let entities = kinveyFind(dataStore: syncDataStore).entities
                        expect(entities?.count).to(equal(0))
                    }
                }
            }
            context("Push()") {
                it("should use multi insert for multiple items without _id") {
                    let result = kinveySaveMulti(
                        dataStore: syncDataStore,
                        entities: [
                            Person { $0.name = "Victor" },
                            Person { $0.name = "Hugo" }
                        ]
                    ).result
                    expect(result).toNot(beNil())
                    guard let resultUnwrapped = result else {
                        return
                    }
                    expect(resultUnwrapped.entities.count).to(equal(2))
                    expect(resultUnwrapped.errors.count).to(equal(0))
                
                    expect(syncDataStore.pendingSyncCount()).to(equal(2))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(2))
                    expect(syncDataStore.pendingSyncOperations().count).to(equal(1))
                    
                    let count = kinveyPush(dataStore: syncDataStore).count
                    expect(count).to(equal(2))
                    
                    expect(syncDataStore.pendingSyncCount()).to(equal(0))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(0))
                
                    let entities = kinveyFind(dataStore: syncDataStore).entities
                    expect(entities?.count).to(equal(2))
                }
                it("should combine POST and PUT requests for items with and without _id") {
                    let result = kinveySaveMulti(
                        dataStore: syncDataStore,
                        entities: [
                            Person { $0.name = "Victor" },
                            Person { $0.entityId = UUID().uuidString; $0.name = "Hugo" },
                            Person { $0.name = "Vinay" },
                            Person { $0.entityId = UUID().uuidString; $0.name = "Thomas" }
                        ]
                    ).result
                    expect(result).toNot(beNil())
                    guard let resultUnwrapped = result else {
                        return
                    }
                    expect(resultUnwrapped.entities.count).to(equal(4))
                    expect(resultUnwrapped.errors.count).to(equal(0))
                
                    expect(syncDataStore.pendingSyncCount()).to(equal(4))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(4))
                    expect(syncDataStore.pendingSyncOperations().count).to(equal(1))
                    
                    let count = kinveyPush(dataStore: syncDataStore).count
                    expect(count).to(equal(4))
                    
                    expect(syncDataStore.pendingSyncCount()).to(equal(0))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(0))
                
                    let entities = kinveyFind(dataStore: syncDataStore).entities
                    expect(entities?.count).to(equal(4))
                }
                it("should combine POST and PUT requests for items with and without _id - mocked") {
                    var postCount = 0, putCount = 0
                    mockResponse { request in
                        switch request.httpMethod {
                        case "POST":
                            guard let jsonArray = try? JSONSerialization.jsonObject(with: request) as? [JsonDictionary] else {
                                break
                            }
                            for json in jsonArray {
                                expect(json["_id"] as? String).to(beNil())
                            }
                            postCount += 1
                        case "PUT":
                            let json = try? JSONSerialization.jsonObject(with: request) as? JsonDictionary
                            expect(json?["_id"] as? String).toNot(beNil())
                            putCount += 1
                        default:
                            break
                        }
                        return HttpResponse(request: request, urlProcotolType: KinveyURLProtocol.self)
                    }
                    defer {
                        setURLProtocol(nil)
                        expect(postCount).to(equal(1))
                        expect(putCount).to(equal(2))
                    }
                    let result = kinveySaveMulti(
                        dataStore: syncDataStore,
                        entities: [
                            Person { $0.name = "Victor" },
                            Person { $0.personId = UUID().uuidString; $0.name = "Hugo" },
                            Person { $0.name = "Vinay" },
                            Person { $0.personId = UUID().uuidString; $0.name = "Thomas" }
                        ]
                    ).result
                    expect(result).toNot(beNil())
                    guard let resultUnwrapped = result else {
                        return
                    }
                    expect(resultUnwrapped.entities.count).to(equal(4))
                    expect(resultUnwrapped.errors.count).to(equal(0))
                
                    expect(syncDataStore.pendingSyncCount()).to(equal(4))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(4))
                    expect(syncDataStore.pendingSyncOperations().count).to(equal(3))
                    
                    let count = kinveyPush(dataStore: syncDataStore).count
                    expect(count).to(equal(4))
                    
                    expect(syncDataStore.pendingSyncCount()).to(equal(0))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(0))
                
                    let entities = kinveyFind(dataStore: syncDataStore).entities
                    expect(entities?.count).to(equal(4))
                }
                it("should return the failure reason in the result for each pushed item even if it is the same") {
                    mockResponse { request in
                        switch request.httpMethod {
                        case "POST":
                            return HttpResponse(
                                statusCode: 401,
                                json: [
                                    "error": "InsufficientCredentials",
                                    "description": "The credentials used to authenticate this request are not authorized to run this operation. Please retry your request with appropriate credentials.",
                                    "debug": "You do not have access to create entities in this collection"
                                ]
                            )
                        default:
                            return HttpResponse(request: request, urlProcotolType: KinveyURLProtocol.self)
                        }
                    }
                    defer {
                        setURLProtocol(nil)
                    }
                    let result = kinveySaveMulti(
                        dataStore: syncDataStore,
                        entities: [
                            Person { $0.name = "Victor" },
                            Person { $0.name = "Hugo" }
                        ]
                    ).result
                    expect(result).toNot(beNil())
                    guard let resultUnwrapped = result else {
                        return
                    }
                    expect(resultUnwrapped.entities.count).to(equal(2))
                    expect(resultUnwrapped.errors.count).to(equal(0))
                
                    expect(syncDataStore.pendingSyncCount()).to(equal(2))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(2))
                    expect(syncDataStore.pendingSyncOperations().count).to(equal(1))
                    
                    let errors = kinveyPush(dataStore: syncDataStore).errors
                    expect(errors?.count).to(equal(1))
                    expect(errors?.first?.localizedDescription).to(equal("The credentials used to authenticate this request are not authorized to run this operation. Please retry your request with appropriate credentials."))
                    
                    expect(syncDataStore.pendingSyncCount()).to(equal(2))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(2))
                    expect(syncDataStore.pendingSyncOperations().count).to(equal(1))
                
                    let entities = kinveyFind(dataStore: syncDataStore).entities
                    expect(entities?.count).to(equal(2))
                }
                it("should return the failure reason in the result for each pushed item when they are different") {
                    mockResponse { request in
                        switch request.httpMethod {
                        case "POST":
                            return HttpResponse(
                                statusCode: 500,
                                json: [
                                    "error": "KinveyInternalErrorRetry",
                                    "description": "The Kinvey server encountered an unexpected error. Please retry your request.",
                                    "debug": "An entity with that _id already exists in this collection"
                                ]
                            )
                        default:
                            return HttpResponse(request: request, urlProcotolType: KinveyURLProtocol.self)
                        }
                    }
                    defer {
                        setURLProtocol(nil)
                    }
                    let result = kinveySaveMulti(
                        dataStore: syncDataStore,
                        entities: [
                            Person { $0.name = "Victor" },
                            Person { $0.name = "Hugo" }
                        ]
                    ).result
                    expect(result).toNot(beNil())
                    guard let resultUnwrapped = result else {
                        return
                    }
                    expect(resultUnwrapped.entities.count).to(equal(2))
                    expect(resultUnwrapped.errors.count).to(equal(0))
                
                    expect(syncDataStore.pendingSyncCount()).to(equal(2))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(2))
                    expect(syncDataStore.pendingSyncOperations().count).to(equal(1))
                    
                    let errors = kinveyPush(dataStore: syncDataStore).errors
                    expect(errors?.count).to(equal(1))
                    expect(errors?.first?.localizedDescription).to(equal("The Kinvey server encountered an unexpected error. Please retry your request."))
                    
                    expect(syncDataStore.pendingSyncCount()).to(equal(2))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(2))
                    expect(syncDataStore.pendingSyncOperations().count).to(equal(1))
                
                    let entities = kinveyFind(dataStore: syncDataStore).entities
                    expect(entities?.count).to(equal(2))
                }
                it("should use multi-insert even if the items have not been created in an array") {
                    var postCount = 0
                    mockResponse { request in
                        switch request.httpMethod {
                        case "POST":
                            postCount += 1
                            fallthrough
                        default:
                            return HttpResponse(request: request, urlProcotolType: KinveyURLProtocol.self)
                        }
                    }
                    defer {
                        setURLProtocol(nil)
                        expect(postCount).to(equal(1))
                    }
                    
                    let entities = kinveySave(dataStore: syncDataStore, numberOfItems: 2).entities
                    expect(entities?.count).to(equal(2))
                    
                    expect(syncDataStore.pendingSyncCount()).to(equal(2))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(2))
                    expect(syncDataStore.pendingSyncOperations().count).to(equal(1))
                    
                    let count = kinveyPush(dataStore: syncDataStore).count
                    expect(count).to(equal(2))
                    
                    expect(syncDataStore.pendingSyncCount()).to(equal(0))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(0))
                }
                it("should handle multi-insert push error properly") {
                    let errorCode = 300
                    let errorMessage = "Geolocation points must be in the form [longitude, latitude] with long between -180 and 180, lat between -90 and 90"
                    mockResponse { request in
                        switch request.httpMethod {
                        case "POST":
                            var persons = KinveyURLProtocol.collections["Person"] ?? [:]
                            let id1 = UUID().uuidString
                            let id2 = UUID().uuidString
                            let now = Date()
                            let json1 = [
                                "_id" : id1,
                                "_geoloc" : [0, 0],
                                "_kmd" : [
                                    "ect" : now.toISO8601(),
                                    "lmt" : now.toISO8601(),
                                ],
                            ] as JsonDictionary
                            let json2 = [
                                "_id" : id2,
                                "_geoloc" : [45, 45],
                                "_kmd" : [
                                    "ect" : now.toISO8601(),
                                    "lmt" : now.toISO8601(),
                                ],
                            ] as JsonDictionary
                            persons[id1] = json1
                            persons[id2] = json2
                            KinveyURLProtocol.collections["Person"] = persons
                            return HttpResponse(
                                statusCode: 207,
                                json: [
                                    "entities" : [
                                        json1,
                                        nil,
                                        json2,
                                    ],
                                    "errors" : [
                                        [
                                            "index": 1,
                                            "code": errorCode,
                                            "errmsg": errorMessage
                                        ],
                                    ]
                                ]
                            )
                        default:
                            return HttpResponse(request: request, urlProcotolType: KinveyURLProtocol.self)
                        }
                    }
                    defer {
                        setURLProtocol(nil)
                    }
                    
                    let result = kinveySaveMulti(
                        dataStore: syncDataStore,
                        entities: [
                            Person { $0.geolocation = GeoPoint(latitude: 0, longitude: 0) },
                            Person { $0.geolocation = GeoPoint(latitude: -300, longitude: -300) },
                            Person { $0.geolocation = GeoPoint(latitude: 45, longitude: 45) },
                        ]
                    ).result
                    expect(result).toNot(beNil())
                    guard let resultUnwrapped = result else {
                        return
                    }
                    expect(resultUnwrapped.entities.count).to(equal(3))
                    expect(resultUnwrapped.errors.count).to(equal(0))
                
                    expect(syncDataStore.pendingSyncCount()).to(equal(3))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(3))
                    expect(syncDataStore.pendingSyncOperations().count).to(equal(1))
                    
                    let errors = kinveySync(dataStore: syncDataStore).errors
                    expect(errors?.count).to(equal(1))
                    expect(errors?.first?.localizedDescription).to(equal(errorMessage))
                    expect(errors?.last?.localizedDescription).to(equal(errorMessage))
                    
                    let multiSaveError = errors?.first as? MultiSaveError
                    
                    expect(multiSaveError).toNot(beNil())
                    
                    expect(multiSaveError?.index).to(equal(1))
                    
                    expect(multiSaveError?.code).to(equal(errorCode))
                    
                    expect(multiSaveError?.message).to(equal(errorMessage))
                    
                    expect(syncDataStore.pendingSyncCount()).to(equal(1))
                    expect(syncDataStore.pendingSyncEntities().count).to(equal(1))
                    expect(syncDataStore.pendingSyncOperations().count).to(equal(1))
                    
                    let networkDataStore = try DataStore<Person>.collection(type: .network)
                    var entities = kinveyFind(dataStore: networkDataStore).entities
                    expect(entities?.count).to(equal(2))
                
                    entities = kinveyFind(dataStore: syncDataStore).entities
                    expect(entities?.count).to(equal(3))
                }
            }
        }
        describe("Auto store") {
            let restApiVersion = Kinvey.restApiVersion
            var autoDataStore: DataStore<Person>!
            var syncDataStore: DataStore<Person>!
            var networkDataStore: DataStore<Person>!
            beforeEach {
                Kinvey.restApiVersion = 5
                do {
                    autoDataStore = try DataStore<Person>.collection(type: .auto)
                    syncDataStore = try DataStore<Person>.collection(type: .sync)
                    networkDataStore = try DataStore<Person>.collection(type: .network)
                } catch {
                    fail(error.localizedDescription)
                }
            }
            afterEach {
                Kinvey.restApiVersion = restApiVersion
            }
            context("save()") {
                context("With single object") {
                    it("should send POST with a single item with no _id") {
                        let entity = kinveySave(dataStore: autoDataStore).entity
                        expect(entity?.entityId).toNot(beNil())
                        
                        var entities = kinveyFind(dataStore: syncDataStore).entities
                        expect(entities?.count).to(equal(1))
                        expect(entities?.first).toNot(beNil())
                        expect(entities?.first?.entityId).toNot(beNil())
                        expect(entities?.first?.metadata).toNot(beNil())
                        expect(entities?.first?.metadata?.ect).toNot(beNil())
                        expect(entities?.first?.metadata?.lastModifiedTime).toNot(beNil())
                        
                        entities = kinveyFind(dataStore: networkDataStore).entities
                        expect(entities?.count).to(equal(1))
                        expect(entities?.first).toNot(beNil())
                        expect(entities?.first?.entityId).toNot(beNil())
                        expect(entities?.first?.metadata).toNot(beNil())
                        expect(entities?.first?.metadata?.ect).toNot(beNil())
                        expect(entities?.first?.metadata?.lastModifiedTime).toNot(beNil())
                    }
                    it("should send with connectivity error") {
                        mockResponse(error: timeoutError)
                        defer {
                            setURLProtocol(nil)
                        }
                        let error = kinveySave(
                            dataStore: autoDataStore,
                            entity: Person { $0.geolocation = GeoPoint(latitude: -300, longitude: -300) }
                        ).error
                        expect(error?.localizedDescription).to(equal(timeoutError.localizedDescription))
                        
                        let entitites = kinveyFind(dataStore: syncDataStore).entities
                        expect(entitites?.count).to(equal(1))
                        
                        expect(syncDataStore.pendingSyncCount()).to(equal(1))
                        expect(syncDataStore.pendingSyncEntities().count).to(equal(1))
                    }
                    it("should send PUT with a sngle item with _id") {
                        let id = UUID().uuidString
                        let entity = kinveySave(dataStore: autoDataStore, entity: Person { $0.personId = id }).entity
                        expect(entity?.entityId).to(equal(id))
                        
                        var entities = kinveyFind(dataStore: syncDataStore).entities
                        expect(entities?.count).to(equal(1))
                        expect(entities?.first).toNot(beNil())
                        expect(entities?.first?.entityId).to(equal(id))
                        expect(entities?.first?.metadata).toNot(beNil())
                        expect(entities?.first?.metadata?.ect).toNot(beNil())
                        expect(entities?.first?.metadata?.lastModifiedTime).toNot(beNil())
                        
                        entities = kinveyFind(dataStore: networkDataStore).entities
                        expect(entities?.count).to(equal(1))
                        expect(entities?.first).toNot(beNil())
                        expect(entities?.first?.entityId).to(equal(id))
                        expect(entities?.first?.metadata).toNot(beNil())
                        expect(entities?.first?.metadata?.ect).toNot(beNil())
                        expect(entities?.first?.metadata?.lastModifiedTime).toNot(beNil())
                    }
                    it("should save the item with _id locally if network connectivity issue") {
                        mockResponse(error: timeoutError)
                        defer {
                            setURLProtocol(nil)
                        }
                        let id = UUID().uuidString
                        let entity = kinveySave(dataStore: autoDataStore, entity: Person { $0.personId = id }).entity
                        
                        let entities = kinveyFind(dataStore: syncDataStore).entities
                        expect(entities?.count).to(equal(1))
                        expect(entities?.first).toNot(beNil())
                        expect(entities?.first?.entityId).to(equal(id))
                        expect(entities?.first?.metadata).to(beNil())
                        expect(entities?.first?.metadata?.ect).to(beNil())
                        expect(entities?.first?.metadata?.lastModifiedTime).to(beNil())
                        
                        expect(syncDataStore.pendingSyncCount()).to(equal(1))
                        expect(syncDataStore.pendingSyncEntities().count).to(equal(1))
                        expect(syncDataStore.pendingSyncEntities().first?.buildRequest().httpMethod).to(equal("PUT"))
                    }
                }
                context("With an array") {
                    it("should send POST multi-insert request for array of items with no _id") {
                        let result = kinveySaveMulti(dataStore: autoDataStore, entities: Person(), Person()).result
                        
                        expect(result?.entities.count).to(equal(2))
                        expect(result?.errors.count).to(equal(0))
                        
                        var entities = kinveyFind(dataStore: syncDataStore).entities
                        expect(entities?.count).to(equal(2))
                        
                        expect(entities?.first).toNot(beNil())
                        expect(entities?.first?.metadata).toNot(beNil())
                        expect(entities?.first?.metadata?.entityCreationTime).toNot(beNil())
                        expect(entities?.first?.metadata?.lastModifiedTime).toNot(beNil())
                        
                        expect(entities?.last).toNot(beNil())
                        expect(entities?.last?.metadata).toNot(beNil())
                        expect(entities?.last?.metadata?.entityCreationTime).toNot(beNil())
                        expect(entities?.last?.metadata?.lastModifiedTime).toNot(beNil())
                        
                        entities = kinveyFind(dataStore: networkDataStore).entities
                        expect(entities?.count).to(equal(2))
                    }
                    it("should sent PUT requests for an array of items with _id") {
                        let id1 = UUID().uuidString
                        let id2 = UUID().uuidString
                        let result = kinveySaveMulti(
                            dataStore: autoDataStore,
                            entities: Person { $0.personId = id1 }, Person { $0.personId = id2 }
                        ).result
                        
                        expect(result?.entities.count).to(equal(2))
                        expect(result?.errors.count).to(equal(0))
                        expect(result?.entities.first??.entityId).to(equal(id1))
                        expect(result?.entities.last??.entityId).to(equal(id2))
                        
                        let entities = kinveyFind(dataStore: networkDataStore).entities
                        
                        expect(entities?.count).to(equal(2))
                        expect(entities?.map({ $0.entityId })).to(contain(id1, id2))
                    }
                    it("should combine POST and PUT requests for items with and without _id") {
                        let id = UUID().uuidString
                        let result = kinveySaveMulti(
                            dataStore: autoDataStore,
                            entities: Person(), Person { $0.personId = id }
                        ).result
                        
                        expect(result?.entities.count).to(equal(2))
                        expect(result?.errors.count).to(equal(0))
                        expect(result?.entities.first??.entityId).toNot(beNil())
                        expect(result?.entities.first??.entityId).toNot(equal(id))
                        expect(result?.entities.last??.entityId).to(equal(id))
                        
                        var entities = kinveyFind(dataStore: networkDataStore).entities
                        
                        expect(entities?.first?.entityId).toNot(beNil())
                        expect(entities?.first?.entityId).toNot(equal(id))
                        expect(entities?.last?.entityId).to(equal(id))
                        
                        entities = kinveyFind(dataStore: networkDataStore).entities
                        
                        expect(entities?.first?.entityId).toNot(beNil())
                        expect(entities?.first?.entityId).toNot(equal(id))
                        expect(entities?.last?.entityId).to(equal(id))
                    }
                    it("should return an error for an empty array") {
                        let error = kinveySaveMulti(dataStore: autoDataStore, entities: []).error
                        expect(error).toNot(beNil())
                        expect(error as? Kinvey.Error).toNot(beNil())
                        guard let kinveyError = error as? Kinvey.Error else {
                            return
                        }
                        switch kinveyError {
                        case .badRequest(let httpResponse, let data, let description):
                            expect(httpResponse).to(beNil())
                            expect(data).to(beNil())
                            expect(description).to(equal("Request body cannot be an empty array"))
                        default:
                            fail(kinveyError.localizedDescription)
                        }
                        
                        expect(syncDataStore.pendingSyncCount()).to(equal(0))
                        expect(syncDataStore.pendingSyncEntities().count).to(equal(0))
                    }
                    it("should return an error when all items fail with multi-insert for invalid credentials") {
                        mockResponse(
                            statusCode: 401,
                            json: [
                                "error": "InvalidCredentials",
                                "description": "Invalid credentials. Please retry your request with correct credentials.",
                                "debug": "Unable to validate the authorization token included in the request"
                            ]
                        )
                        defer {
                            setURLProtocol(nil)
                        }
                        
                        let id = UUID().uuidString
                        let error = kinveySaveMulti(dataStore: autoDataStore, entities: Person(), Person { $0.entityId = id }).error
                        expect(error).toNot(beNil())
                        expect(error as? Kinvey.Error).toNot(beNil())
                        guard let kinveyError = error as? Kinvey.Error else {
                            return
                        }
                        switch kinveyError {
                        case .invalidCredentials(let httpResponse, let data, let debug, let description):
                            expect(debug).to(equal("Unable to validate the authorization token included in the request"))
                            expect(description).to(equal("Invalid credentials. Please retry your request with correct credentials."))
                        default:
                            fail(kinveyError.localizedDescription)
                        }
                        
                        expect(Client.shared.activeUser).to(beNil())
                        
                        expect(autoDataStore.pendingSyncCount()).to(equal(0))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(0))
                        
                        let entities = kinveyFind(dataStore: syncDataStore).entities
                        expect(entities?.count).to(equal(0))
                    }
                    it("should return an array of errors for all items failing for different reasons") {
                        let id1 = UUID().uuidString
                        let id2 = UUID().uuidString
                        mockResponse(
                            statusCode: 207,
                            json: [
                                "entities": [
                                    nil,
                                    nil
                                ],
                                "errors" : [
                                    [
                                        "index": 0,
                                        "code": 11000,
                                        "errmsg": "E11000 duplicate key error collection: kdb1.kid1.Person index: _id_ dup key: { : \"\(id1)\" }"
                                    ],
                                    [
                                        "index": 1,
                                        "code": 11000,
                                        "errmsg": "E11000 duplicate key error collection: kdb1.kid1.Person index: _id_ dup key: { : \"\(id2)\" }"
                                    ]
                                ]
                            ]
                        )
                        defer {
                            setURLProtocol(nil)
                        }
                        
                        let result = kinveySaveMulti(dataStore: autoDataStore, entities: Person(), Person()).result
                        expect(result?.entities.count).to(equal(2))
                        expect(result?.entities.first!).to(beNil())
                        expect(result?.entities.last!).to(beNil())
                        expect(result?.errors.count).to(equal(2))
                        
                        expect((result?.errors.first as? MultiSaveError)?.index).to(equal(0))
                        expect((result?.errors.first as? MultiSaveError)?.code).to(equal(11000))
                        expect((result?.errors.first as? MultiSaveError)?.message).to(equal("E11000 duplicate key error collection: kdb1.kid1.Person index: _id_ dup key: { : \"\(id1)\" }"))
                        
                        expect((result?.errors.last as? MultiSaveError)?.index).to(equal(1))
                        expect((result?.errors.last as? MultiSaveError)?.code).to(equal(11000))
                        expect((result?.errors.last as? MultiSaveError)?.message).to(equal("E11000 duplicate key error collection: kdb1.kid1.Person index: _id_ dup key: { : \"\(id2)\" }"))
                        
                        expect(autoDataStore.pendingSyncCount()).to(equal(2))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(2))
                        expect(autoDataStore.pendingSyncOperations().count).to(equal(1))
                        
                        let entities = kinveyFind(dataStore: syncDataStore).entities
                        expect(entities?.count).to(equal(2))
                    }
                    it("should return an entities and errors when some requests fail and some succeed") {
                        mockResponse { request in
                            switch request.httpMethod {
                            case "POST":
                                let id = UUID().uuidString
                                let json = [
                                    "name": "Victor",
                                    "_acl": [
                                        "creator": UUID().uuidString
                                    ],
                                    "_kmd": [
                                        "lmt": Date().toISO8601(),
                                        "ect": Date().toISO8601()
                                    ],
                                    "_id": id
                                ] as JsonDictionary
                                if KinveyURLProtocol.collections[Person.collectionName()] == nil {
                                    KinveyURLProtocol.collections[Person.collectionName()] = [:]
                                }
                                KinveyURLProtocol.collections[Person.collectionName()]![id] = json
                                return HttpResponse(
                                    statusCode: 207,
                                    json: [
                                        "entities": [
                                            json,
                                            nil
                                        ],
                                        "errors" : [
                                            [
                                                "index" : 1,
                                                "code": 123,
                                                "errmsg": "Geolocation points must be in the form [longitude, latitude] with long between -180 and 180, lat between -90 and 90"
                                            ]
                                        ]
                                    ]
                                )
                            default:
                                return HttpResponse(request: request, urlProcotolType: KinveyURLProtocol.self)
                            }
                        }
                        defer {
                            setURLProtocol(nil)
                        }
                        
                        let result = kinveySaveMulti(
                            dataStore: autoDataStore,
                            entities: [
                                Person { $0.name = "Victor" },
                                Person { $0.geolocation = GeoPoint(latitude: -300, longitude: -300) }
                            ]
                        ).result
                        expect(result?.entities.count).to(equal(2))
                        expect(result?.entities.first!).toNot(beNil())
                        expect(result?.entities.last!).to(beNil())
                        expect(result?.errors.count).to(equal(1))
                        expect((result?.errors.first as? MultiSaveError)?.index).to(equal(1))
                        
                        expect(syncDataStore.pendingSyncCount()).to(equal(1))
                        expect(syncDataStore.pendingSyncEntities().count).to(equal(1))
                        
                        var entities = kinveyFind(dataStore: syncDataStore, query: Query(predicate: nil, sortDescriptors: [NSSortDescriptor(key: "metadata.lmt", ascending: true)])).entities
                        expect(entities?.count).to(equal(2))
                        expect(entities?.first).toNot(beNil())
                        expect(entities?.first?.metadata).toNot(beNil())
                        expect(entities?.first?.metadata?.entityCreationTime).toNot(beNil())
                        expect(entities?.first?.metadata?.lastModifiedTime).toNot(beNil())
                        expect(entities?.last).toNot(beNil())
                        expect(entities?.last?.metadata).to(beNil())
                        
                        entities = kinveyFind(dataStore: networkDataStore).entities
                        expect(entities?.count).to(equal(1))
                        expect(entities?.first).toNot(beNil())
                        expect(entities?.first?.metadata).toNot(beNil())
                        expect(entities?.first?.metadata?.entityCreationTime).toNot(beNil())
                        expect(entities?.first?.metadata?.lastModifiedTime).toNot(beNil())
                    }
                    it("should return PUT failures at the matching index") {
                        var newIds = [String]()
                        mockResponse { request in
                            switch request.httpMethod {
                            case "POST":
                                var jsonArray = try! JSONSerialization.jsonObject(with: request) as! [JsonDictionary]
                                jsonArray = jsonArray.map {
                                    var json = $0
                                    if json["_id"] == nil {
                                        let id = UUID().uuidString
                                        json["_id"] = id
                                        newIds.append(id)
                                    }
                                    var kmd = [String : Any]()
                                    let now = Date().toISO8601()
                                    kmd["lmt"] = now
                                    kmd["ect"] = now
                                    json["_kmd"] = kmd
                                    return json
                                }
                                if KinveyURLProtocol.collections[Person.collectionName()] == nil {
                                    KinveyURLProtocol.collections[Person.collectionName()] = [:]
                                }
                                KinveyURLProtocol.collections[Person.collectionName()]![newIds.last!] = jsonArray[1]
                                return HttpResponse(
                                    statusCode: 207,
                                    json: [
                                        "entities": [
                                            nil,
                                            jsonArray[1]
                                        ],
                                        "errors" : [
                                            [
                                                "index" : 0,
                                                "code": 123,
                                                "errmsg": "Geolocation points must be in the form [longitude, latitude] with long between -180 and 180, lat between -90 and 90"
                                            ]
                                        ]
                                    ]
                                )
                            default:
                                return HttpResponse(request: request, urlProcotolType: KinveyURLProtocol.self)
                            }
                        }
                        defer {
                            setURLProtocol(nil)
                        }
                        let id1 = UUID().uuidString
                        let id2 = UUID().uuidString
                        
                        let result = kinveySaveMulti(
                            dataStore: autoDataStore,
                            entities: [
                                Person { $0.age = 10; $0.geolocation = GeoPoint(latitude: -300, longitude: -300) },
                                Person { $0.age = 20; $0.personId = id1 },
                                Person { $0.age = 30; $0.personId = id2; $0.geolocation = GeoPoint(latitude: -300, longitude: -300) },
                                Person { $0.age = 40; $0.name = "Victor" }
                            ]
                        ).result
                        expect(result?.entities.count).to(equal(4))
                        guard let resultUnwrapped = result else {
                            return
                        }
                        expect(newIds.count).to(equal(2))
                        if resultUnwrapped.entities.count == 4 {
                            let entities = Array(resultUnwrapped.entities)
                            expect(entities[0]).to(beNil())
                            expect(entities[1]).toNot(beNil())
                            expect(entities[1]?.entityId).to(equal(id1))
                            expect(entities[2]).to(beNil())
                            expect(entities[3]).toNot(beNil())
                            expect(entities[3]?.entityId).to(equal(newIds.last))
                        }
                        expect(resultUnwrapped.errors.count).to(equal(2))
                        expect((resultUnwrapped.errors.first as? MultiSaveError)?.index).to(equal(0))
                        expect((resultUnwrapped.errors.last as? IndexedError)?.index).to(equal(2))
                        
                        expect(syncDataStore.pendingSyncCount()).to(equal(2))
                        expect(syncDataStore.pendingSyncEntities().count).to(equal(2))
                        
                        var entities = kinveyFind(dataStore: syncDataStore, query: Query(sortDescriptors: [NSSortDescriptor(key: "age", ascending: true)])).entities
                        expect(entities).toNot(beNil())
                        expect(entities?.count).to(equal(4))
                        expect(entities?[0].metadata).to(beNil())
                        expect(entities?[1].metadata).toNot(beNil())
                        expect(entities?[1].metadata?.entityCreationTime).toNot(beNil())
                        expect(entities?[1].metadata?.lastModifiedTime).toNot(beNil())
                        expect(entities?[2].metadata).to(beNil())
                        expect(entities?[3].entityId).to(equal(newIds.last))
                        expect(entities?[3].metadata).toNot(beNil())
                        expect(entities?[3].metadata?.entityCreationTime).toNot(beNil())
                        expect(entities?[3].metadata?.lastModifiedTime).toNot(beNil())
                        
                        entities = kinveyFind(dataStore: networkDataStore).entities
                        expect(entities?.count).to(equal(2))
                        expect(entities?.first).toNot(beNil())
                        expect(entities?.first?.metadata).toNot(beNil())
                        expect(entities?.first?.metadata?.entityCreationTime).toNot(beNil())
                        expect(entities?.first?.metadata?.lastModifiedTime).toNot(beNil())
                        expect(entities?.last).toNot(beNil())
                        expect(entities?.last?.metadata).toNot(beNil())
                        expect(entities?.last?.metadata?.entityCreationTime).toNot(beNil())
                        expect(entities?.last?.metadata?.lastModifiedTime).toNot(beNil())
                    }
                }
                context("Push()") {
                    it("should use multi insert for multiple items without _id") {
                        do {
                            mockResponse(error: timeoutError)
                            defer {
                                setURLProtocol(KinveyURLProtocol.self)
                            }
                            
                            let error = kinveySaveMulti(dataStore: autoDataStore, entities: Person(), Person()).error
                            expect(error).toNot(beNil())
                            expect(error?.localizedDescription).to(equal(timeoutError.localizedDescription))
                        } catch {
                            fail(error.localizedDescription)
                        }
                        
                        expect(autoDataStore.pendingSyncCount()).to(equal(2))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(2))
                        expect(autoDataStore.pendingSyncOperations().count).to(equal(1))
                        
                        let count = kinveyPush(dataStore: autoDataStore).count
                        expect(count).to(equal(2))
                        
                        expect(autoDataStore.pendingSyncCount()).to(equal(0))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(0))
                        
                        let entities = kinveyFind(dataStore: networkDataStore).entities
                        expect(entities?.count).to(equal(2))
                    }
                    it("should combine POST and PUT requests for items with and without _id") {
                        do {
                            mockResponse(error: timeoutError)
                            defer {
                                setURLProtocol(KinveyURLProtocol.self)
                            }
                            
                            let error = kinveySaveMulti(
                                dataStore: autoDataStore,
                                entities: Person(), Person { $0.entityId = UUID().uuidString }
                            ).error
                            expect(error).toNot(beNil())
                            expect(error?.localizedDescription).to(equal(timeoutError.localizedDescription))
                        } catch {
                            fail(error.localizedDescription)
                        }
                        
                        expect(autoDataStore.pendingSyncCount()).to(equal(2))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(2))
                        expect(autoDataStore.pendingSyncOperations().count).to(equal(1))
                        
                        let count = kinveyPush(dataStore: autoDataStore).count
                        expect(count).to(equal(2))
                        
                        expect(autoDataStore.pendingSyncCount()).to(equal(0))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(0))
                        
                        let entities = kinveyFind(dataStore: networkDataStore).entities
                        expect(entities?.count).to(equal(2))
                    }
                    it("should combine POST and PUT requests for items with and without _id - mocked") {
                        var postCount = 0
                        var putCount = 0
                        do {
                            mockResponse { request in
                                switch request.httpMethod?.uppercased() {
                                case "POST":
                                    postCount += 1
                                    let json = try? JSONSerialization.jsonObject(with: request) as? [JsonDictionary]
                                    expect(json).toNot(beNil())
                                    fallthrough
                                case "PUT":
                                    putCount += 1
                                    fallthrough
                                default:
                                    return HttpResponse(error: timeoutError)
                                }
                            }
                            defer {
                                setURLProtocol(KinveyURLProtocol.self)
                            }
                            
                            let error = kinveySaveMulti(
                                dataStore: autoDataStore,
                                entities: Person(), Person { $0.entityId = UUID().uuidString }
                            ).error
                            expect(error).toNot(beNil())
                            expect(error?.localizedDescription).to(equal(timeoutError.localizedDescription))
                        } catch {
                            fail(error.localizedDescription)
                        }
                        
                        expect(autoDataStore.pendingSyncCount()).to(equal(2))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(2))
                        expect(autoDataStore.pendingSyncOperations().count).to(equal(1))
                        
                        let count = kinveyPush(dataStore: autoDataStore).count
                        expect(count).to(equal(2))
                        
                        expect(autoDataStore.pendingSyncCount()).to(equal(0))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(0))
                        
                        let entities = kinveyFind(dataStore: networkDataStore).entities
                        expect(entities?.count).to(equal(2))
                        
                        expect(postCount).to(equal(1))
                        expect(putCount).to(equal(1))
                    }
                    it("should return a single error if a single error is returned by the backend") {
                        mockResponse { request in
                            switch request.httpMethod {
                            case "POST":
                                return HttpResponse(
                                    statusCode: 401,
                                    json: [
                                        "error": "InsufficientCredentials",
                                        "description": "The credentials used to authenticate this request are not authorized to run this operation. Please retry your request with appropriate credentials.",
                                        "debug": "You do not have access to create entities in this collection"
                                    ]
                                )
                            default:
                                return HttpResponse(request: request, urlProcotolType: KinveyURLProtocol.self)
                            }
                        }
                        defer {
                            setURLProtocol(nil)
                        }
                        let error = kinveySaveMulti(
                            dataStore: autoDataStore,
                            entities: [
                                Person { $0.name = "Victor" },
                                Person { $0.name = "Hugo" }
                            ]
                        ).error
                        expect(error).toNot(beNil())
                    
                        expect(autoDataStore.pendingSyncCount()).to(equal(2))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(2))
                        expect(autoDataStore.pendingSyncOperations().count).to(equal(1))
                        
                        let errors = kinveyPush(dataStore: autoDataStore).errors
                        expect(errors?.count).to(equal(1))
                        expect(errors?.first?.localizedDescription).to(equal("The credentials used to authenticate this request are not authorized to run this operation. Please retry your request with appropriate credentials."))
                        
                        expect(autoDataStore.pendingSyncCount()).to(equal(2))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(2))
                        expect(autoDataStore.pendingSyncOperations().count).to(equal(1))
                    }
                    it("should return the failure reason in the result for each pushed item when they are different") {
                        mockResponse { request in
                            switch request.httpMethod {
                            case "POST":
                                return HttpResponse(
                                    statusCode: 207,
                                    json: [
                                        "entities" : [
                                            nil,
                                            nil
                                        ],
                                        "errors": [
                                            [
                                                "index": 0,
                                                "code": 1,
                                                "errmsg": "An entity with that name already exists in this collection"
                                            ],
                                            [
                                                "index": 1,
                                                "code": 2,
                                                "errmsg": "An entity with that name already exists in this collection"
                                            ],
                                        ]
                                    ]
                                )
                            default:
                                return HttpResponse(request: request, urlProcotolType: KinveyURLProtocol.self)
                            }
                        }
                        defer {
                            setURLProtocol(nil)
                        }
                        let result = kinveySaveMulti(
                            dataStore: autoDataStore,
                            entities: [
                                Person { $0.name = "Victor" },
                                Person { $0.name = "Hugo" }
                            ]
                        ).result
                        expect(result).toNot(beNil())
                        guard let resultUnwrapped = result else {
                            return
                        }
                        expect(resultUnwrapped.entities.count).to(equal(2))
                        expect(resultUnwrapped.entities.first!).to(beNil())
                        expect(resultUnwrapped.entities.last!).to(beNil())
                        expect(resultUnwrapped.errors.count).to(equal(2))
                    
                        expect(autoDataStore.pendingSyncCount()).to(equal(2))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(2))
                        expect(autoDataStore.pendingSyncOperations().count).to(equal(1))
                        
                        let errors = kinveyPush(dataStore: autoDataStore).errors
                        expect(errors?.count).to(equal(2))
                        
                        expect(autoDataStore.pendingSyncCount()).to(equal(2))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(2))
                        expect(autoDataStore.pendingSyncOperations().count).to(equal(1))
                    }
                    it("should use multi-insert even if the items have not been created in an array") {
                        var postCount = 0
                        mockResponse { request in
                            switch request.httpMethod {
                            case "POST":
                                postCount += 1
                                fallthrough
                            default:
                                return HttpResponse(request: request, urlProcotolType: KinveyURLProtocol.self)
                            }
                        }
                        defer {
                            setURLProtocol(nil)
                            expect(postCount).to(equal(1))
                        }
                        
                        let entities = kinveySave(dataStore: syncDataStore, numberOfItems: 2).entities
                        expect(entities?.count).to(equal(2))
                        
                        expect(postCount).to(equal(0))
                        
                        expect(autoDataStore.pendingSyncCount()).to(equal(2))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(2))
                        expect(autoDataStore.pendingSyncOperations().count).to(equal(1))
                        
                        let count = kinveyPush(dataStore: autoDataStore).count
                        expect(count).to(equal(2))
                        
                        expect(postCount).to(equal(1))
                        
                        expect(autoDataStore.pendingSyncCount()).to(equal(0))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(0))
                    }
                    it("push 2 new items") {
                        let books = [
                            Book { $0.title = "This 1 book" },
                            Book { $0.title = "This 2 book" },
                        ]
                        
                        var postCount = 0
                        mockResponse { request in
                            switch request.httpMethod {
                            case "POST":
                                postCount += 1
                                expect(request.allHTTPHeaderFields?["Content-Type"] as? String).to(equal("application/json; charset=utf-8"))
                                let json = try! JSONSerialization.jsonObject(with: request)
                                expect(json is [[String : Any]]).to(beTrue())
                                if let jsonArray = json as? [[String : Any]] {
                                    expect(jsonArray.count).to(equal(books.count))
                                    expect(jsonArray.first?["title"] as? String).to(equal(books.first?.title))
                                    expect(jsonArray.last?["title"] as? String).to(equal(books.last?.title))
                                }
                                fallthrough
                            default:
                                return HttpResponse(request: request, urlProcotolType: KinveyURLProtocol.self)
                            }
                        }
                        defer {
                            setURLProtocol(nil)
                            expect(postCount).to(equal(1))
                        }
                        
                        let syncDataStore = try DataStore<Book>.collection(type: .sync)
                        let result = kinveySaveMulti(dataStore: syncDataStore, entities: books).result
                        
                        expect(result?.entities.count).to(equal(books.count))
                        expect(result?.errors.count).to(equal(0))
                        
                        let pushCount = kinveyPush(dataStore: syncDataStore).count
                        expect(pushCount).to(equal(UInt(books.count)))
                    }
                }
                context("Sync()") {
                    it("create an array of 3 items, the second of which has invalid _geoloc parameters") {
                        var postCount = 0
                        mockResponse { request in
                            switch request.httpMethod! {
                            case "POST":
                                defer {
                                    postCount += 1
                                }
                                switch postCount {
                                case 0:
                                    return HttpResponse(error: timeoutError)
                                default:
                                    let id1 = UUID().uuidString
                                    let id2 = UUID().uuidString
                                    let now = Date()
                                    let json1 = [
                                        "_id" : id1,
                                        "_geoloc" : [0, 0],
                                        "_kmd" : [
                                            "ect" : now.toISO8601(),
                                            "lmt" : now.toISO8601(),
                                        ],
                                    ] as JsonDictionary
                                    let json2 = [
                                        "_id" : id2,
                                        "_geoloc" : [45, 45],
                                        "_kmd" : [
                                            "ect" : now.toISO8601(),
                                            "lmt" : now.toISO8601(),
                                        ],
                                    ] as JsonDictionary
                                    var persons = KinveyURLProtocol.collections["Person"]
                                    if persons == nil {
                                        persons = [:]
                                    }
                                    persons![id1] = json1
                                    persons![id2] = json2
                                    KinveyURLProtocol.collections["Person"] = persons
                                    return HttpResponse(json: [
                                        "entities" : [
                                            json1,
                                            nil,
                                            json2,
                                        ],
                                        "errors" : [
                                            [
                                                "index" : 1,
                                                "code" : 123,
                                                "errmsg" : "Geolocation points must be in the form [longitude, latitude] with long between -180 and 180, lat between -90 and 90"
                                            ]
                                        ]
                                    ])
                                }
                            default:
                                return HttpResponse(request: request, urlProcotolType: KinveyURLProtocol.self)
                            }
                        }
                        defer {
                            setURLProtocol(KinveyURLProtocol.self)
                            expect(postCount).to(equal(2))
                        }
                    
                        let error = kinveySaveMulti(
                            dataStore: autoDataStore,
                            entities: [
                                Person { $0.geolocation = GeoPoint(latitude: 0, longitude: 0) },
                                Person { $0.geolocation = GeoPoint(latitude: -300, longitude: -300) },
                                Person { $0.geolocation = GeoPoint(latitude: 45, longitude: 45) }
                            ]
                        ).error
                        expect(error).toNot(beNil())
                    
                        expect(autoDataStore.pendingSyncCount()).to(equal(3))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(3))
                        expect(autoDataStore.pendingSyncOperations().count).to(equal(1))
                        
                        let errors = kinveySync(dataStore: autoDataStore).errors
                        expect(errors?.count).to(equal(1))
                        expect(errors?.first?.localizedDescription).to(equal("Geolocation points must be in the form [longitude, latitude] with long between -180 and 180, lat between -90 and 90"))
                        
                        expect(autoDataStore.pendingSyncCount()).to(equal(1))
                        expect(autoDataStore.pendingSyncEntities().count).to(equal(1))
                        expect(autoDataStore.pendingSyncOperations().count).to(equal(1))
                    
                        var entities = kinveyFind(dataStore: networkDataStore).entities
                        expect(entities?.count).to(equal(2))
                        
                        entities = kinveyFind(dataStore: syncDataStore).entities
                        expect(entities?.count).to(equal(3))
                    }
                }
            }
        }
    }
    
}
