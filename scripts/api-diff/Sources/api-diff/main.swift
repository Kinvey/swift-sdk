import Foundation
import SourceKittenFramework

guard CommandLine.arguments.count == 3 else {
    print("Usage:")
    print("  api-diff <old path> <new path>")
    exit(EXIT_FAILURE)
}

let oldPath = CommandLine.arguments[1]
let newPath = CommandLine.arguments[2]

let operationQueue = OperationQueue()
operationQueue.maxConcurrentOperationCount = 2

struct Docs {
    
    var oldDocs: [SwiftDocs]?
    var newDocs: [SwiftDocs]?
    
}

var docs = Docs()

func newModule(path: String) -> Module {
    let _module = Module(
        xcodeBuildArguments: [
            "-workspace",
            "Kinvey.xcworkspace",
            "-scheme",
            "Kinvey"
        ],
        name: "Kinvey",
        inPath: path
    )
    guard let module = _module else {
        print("Project not found")
        exit(EXIT_FAILURE)
    }
    return module
}

operationQueue.addOperation {
    docs.oldDocs = newModule(path: oldPath).docs
}

operationQueue.addOperation {
    docs.newDocs = newModule(path: newPath).docs
}

operationQueue.waitUntilAllOperationsAreFinished()

guard
    let oldDocs = docs.oldDocs,
    let newDocs = docs.newDocs
else {
    print("Project not found")
    exit(EXIT_FAILURE)
}

enum Kind: String {
    
    case `enum`           = "source.lang.swift.decl.enum"
    case enumCase         = "source.lang.swift.decl.enumcase"
    case `var`            = "source.lang.swift.decl.var.instance"
    case staticVar        = "source.lang.swift.decl.var.static"
    case `extension`      = "source.lang.swift.decl.extension"
    case `func`           = "source.lang.swift.decl.function.method.instance"
    case classFunc        = "source.lang.swift.decl.function.method.class"
    case staticFunc       = "source.lang.swift.decl.function.method.static"
    case `typealias`      = "source.lang.swift.decl.typealias"
    case `associatedtype` = "source.lang.swift.decl.associatedtype"
    case `class`          = "source.lang.swift.decl.class"
    case `struct`         = "source.lang.swift.decl.struct"
    
}

enum Accessibility: String {
    
    case `private`     = "source.lang.swift.accessibility.private"
    case `fileprivate` = "source.lang.swift.accessibility.fileprivate"
    case `internal`    = "source.lang.swift.accessibility.internal"
    case `public`      = "source.lang.swift.accessibility.public"
    case `open`        = "source.lang.swift.accessibility.open"
    
}

enum Key: String {
    
    case name           = "key.name"
    case moduleName     = "key.modulename"
    case accessibility  = "key.accessibility"
    case substructure   = "key.substructure"
    case kind           = "key.kind"
    case attribute      = "key.attribute"
    case docDeclaration = "key.doc.declaration"
    
}

enum Attribute: String {
    
    case available = "source.decl.attribute.available"
    
}

extension Dictionary where Key == String, Value == SourceKitRepresentable {
    
    subscript<Key: RawRepresentable>(key: Key) -> SourceKitRepresentable? where Key.RawValue == String {
        get {
            return self[key.rawValue]
        }
    }
    
    func get<Key: RawRepresentable>(key: Key) -> SourceKitRepresentable? where Key.RawValue == String {
        return self[key.rawValue]
    }
    
}

let regexDeprecated = try! NSRegularExpression(pattern: "\\,\\s*deprecated\\s*\\:\\s*(\\d)+.(\\d)+.(\\d)+")

func isDeprecated(_ symbol: [String : SourceKitRepresentable]) -> Bool {
    guard let docDeclaration = symbol[Key.docDeclaration] as? String else {
        return false
    }
    return regexDeprecated.numberOfMatches(in: docDeclaration, range: NSMakeRange(0, docDeclaration.count)) > 0
}

func format(_ names: String...) -> String {
    return names.joined(separator: ".")
}

func convert(_ symbol: [String : SourceKitRepresentable]) -> (names: Set<String>, deprecations: Set<String>)? {
    guard
        let accessibilityString = symbol[Key.accessibility] as? String,
        let accessibility = Accessibility(rawValue: accessibilityString),
        accessibility == .public || accessibility == .open,
        let name = symbol[Key.moduleName] as? String ?? symbol[Key.name] as? String,
        let substructures = symbol[Key.substructure] as? Array<Dictionary<String, SourceKitRepresentable>>
    else {
        return nil
    }
    var names = [String]()
    var deprecations = [String]()
    if isDeprecated(symbol) {
        deprecations.append(name)
    }
    for substructure in substructures {
        guard
            let accessibilityString2 = substructure[Key.accessibility] as? String,
            let accessibility2 = Accessibility(rawValue: accessibilityString2),
            accessibility2 == .public || accessibility2 == .open,
            let kindString = substructure[Key.kind] as? String
        else {
            continue
        }
        let kind = Kind(rawValue: kindString)!
        switch kind {
        case .enumCase:
            if let substructures2 = substructure[Key.substructure] as? Array<Dictionary<String, SourceKitRepresentable>> {
                for substructure2 in substructures2 {
                    if let name2 = substructure2[Key.name] as? String {
                        let formattedName = format(name, name2)
                        names.append(formattedName)
                        if isDeprecated(substructure2) {
                            deprecations.append(formattedName)
                        }
                    }
                }
            }
        case .var, .staticVar, .func, .staticFunc, .classFunc, .typealias, .associatedtype:
            if let name2 = substructure[Key.name] as? String {
                let formattedName = format(name, name2)
                names.append(formattedName)
                if isDeprecated(substructure) {
                    deprecations.append(formattedName)
                }
            }
        case .class, .struct, .enum:
            if let (names2, deprecations2) = convert(substructure) {
                for name2 in names2 {
                    let formattedName = format(name, name2)
                    names.append(formattedName)
                    if deprecations2.contains(name2) {
                        deprecations.append(formattedName)
                    }
                }
            }
        case .extension:
            break
        }
    }
    return (names: Set(names), deprecations: Set(deprecations))
}

func convert(docs: [SwiftDocs]) -> (names: Set<String>, deprecations: Set<String>) {
    let array = docs.compactMap {
        $0.docsDictionary[Key.substructure] as? Array<Dictionary<String, SourceKitRepresentable>>
    }.flatMap {
        $0.compactMap {
            convert($0)
        }
    }
    var namesTotal = Set<String>()
    var deprecationsTotal = Set<String>()
    for (names, deprecations) in array {
        namesTotal.formUnion(names)
        deprecationsTotal.formUnion(deprecations)
    }
    return (names: namesTotal, deprecations: deprecationsTotal)
}

let (oldSymbols, oldDeprecations) = convert(docs: oldDocs)
let (newSymbols, newDeprecations) = convert(docs: newDocs)

let deletions = oldSymbols.subtracting(newSymbols)
let additions = newSymbols.subtracting(oldSymbols)
let deprecations = newDeprecations.subtracting(oldDeprecations)
let breakingChanges = oldDeprecations.subtracting(newDeprecations)

print("")
print("\(deletions.count) Deletions:")
for deletion in deletions {
    print("  \(deletion)")
}

print("")
print("\(additions.count) Additions:")
for addition in additions {
    print("  \(addition)")
}

print("")
print("\(deprecations.count) Deprecations:")
for deprecation in deprecations {
    print("  \(deprecation)")
}

print("")
print("\(breakingChanges.count) Breaking Changes:")
for breakingChange in breakingChanges {
    print("  \(breakingChange)")
}

print("")
