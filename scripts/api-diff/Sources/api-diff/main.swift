import Foundation
import SourceKittenFramework

guard 3 <= CommandLine.arguments.count && CommandLine.arguments.count <= 4 else {
    print("Usage:")
    print("  api-diff <old path> <new path> <optional output format>")
    exit(EXIT_FAILURE)
}

let oldPath = CommandLine.arguments[1]
let newPath = CommandLine.arguments[2]
let outputFormat = CommandLine.arguments.count > 3 ? CommandLine.arguments[3].lowercased() : ""

func infoPlist(path: String) throws -> [String : Any] {
    return try PropertyListSerialization.propertyList(
        from: try Data(contentsOf: URL(fileURLWithPath: "\(path)/Kinvey/Kinvey/Info.plist".replacingOccurrences(of: "~", with: NSHomeDirectory()))),
        options: .mutableContainersAndLeaves,
        format: nil
    ) as! [String : Any]
}

let oldInfoPlist = try infoPlist(path: oldPath)
let newInfoPlist = try infoPlist(path: newPath)

extension Dictionary where Key == String {
    
    subscript<Key: RawRepresentable>(key: Key) -> Value? where Key.RawValue == String {
        return self[key.rawValue]
    }
    
}

let versionKey = "CFBundleShortVersionString"
let oldVersion = oldInfoPlist[versionKey] as! String
let newVersion = newInfoPlist[versionKey] as! String

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
    case `subscript`      = "source.lang.swift.decl.function.subscript"
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

let regexDeprecated = try! NSRegularExpression(pattern: "\\,\\s*deprecated\\s*\\:\\s*(\\d)+.(\\d)+.(\\d)+")

func isDeprecated(_ symbol: [String : SourceKitRepresentable]) -> Bool {
    guard let docDeclaration = symbol[Key.docDeclaration] as? String else {
        return false
    }
    return regexDeprecated.numberOfMatches(in: docDeclaration, range: NSRange(location: 0, length: docDeclaration.count)) > 0
}

func format(_ names: String...) -> String {
    return names.joined(separator: ".")
}

func convert(_ symbol: [String : SourceKitRepresentable]) -> (names: Set<String>, deprecations: Set<String>)? {
    let accessibility: Accessibility?
    if let accessibilityString = symbol[Key.accessibility] as? String {
        accessibility = Accessibility(rawValue: accessibilityString)
    } else {
        accessibility = nil
    }
    
    let kind: Kind?
    if let kindString = symbol[Key.kind] as? String {
        kind = Kind(rawValue: kindString)
    } else {
        kind = nil
    }
    
    guard accessibility == .public || accessibility == .open || kind == .extension,
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
        case .var,
             .staticVar,
             .func,
             .staticFunc,
             .subscript,
             .classFunc,
             .typealias,
             .associatedtype:
            if let name2 = substructure[Key.name] as? String {
                let formattedName = format(name, name2)
                names.append(formattedName)
                if isDeprecated(substructure) {
                    deprecations.append(formattedName)
                }
            }
        case .class,
             .struct,
             .enum:
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

let deletions = oldSymbols.subtracting(newSymbols).sorted()
let additions = newSymbols.subtracting(oldSymbols).sorted()
let deprecations = newDeprecations.subtracting(oldDeprecations).sorted()
let breakingChanges = oldDeprecations.subtracting(newDeprecations).sorted()

func toMarkdown(title: String, symbols: [String]) -> String {
    return """
      ### \(symbols.count) \(title):
    \(symbols.map { "  * `\($0)`" }.joined(separator: "\n"))
    """
}

func toHTML(title: String, symbols: [String]) -> String {
    guard symbols.count > 0 else {
        return ""
    }
    return """
    <h3>\(title)</h3>
    <ul>
    \(symbols.map { "  <li><code>\($0)</code></li>" }.joined(separator: "\n"))
    </ul>
    """
}

switch outputFormat {
case "html":
    print("""
    <h2 id="\(oldVersion)-\(newVersion)"><a href="#\(oldVersion)-\(newVersion)">\(oldVersion) to \(newVersion) API Differences</a></h2>
    \(toHTML(title: "Deletions", symbols: deletions))
    \(toHTML(title: "Additions", symbols: additions))
    \(toHTML(title: "Deprecations", symbols: deprecations))
    \(toHTML(title: "Breaking Changes", symbols: breakingChanges))
    """)
default:
    print("""
    \(toMarkdown(title: "Deletions", symbols: deletions))
    
    \(toMarkdown(title: "Additions", symbols: additions))
    
    \(toMarkdown(title: "Deprecations", symbols: deprecations))
    
    \(toMarkdown(title: "Breaking Changes", symbols: breakingChanges))
    """)
}
