//
//  main.swift
//  DevCenterRelease
//
//  Created by Victor Hugo on 2017-07-20.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation

let githubToken = ProcessInfo.processInfo.environment["GITHUB_TOKEN"]
guard githubToken != nil else {
    fatalError("GITHUB_TOKEN environment variable missing")
}

var arguments = ProcessInfo.processInfo.arguments
if arguments.contains("-module-name"),
    let moduleNameIndex = arguments.index(of: "-module-name"),
    let mainIndex = arguments.index(of: "main"),
    moduleNameIndex + 1 == mainIndex,
    let dashDashIndex = arguments.index(of: "--"),
    mainIndex + 1 == dashDashIndex
{
    arguments = Array(arguments[dashDashIndex ..< arguments.count])
}

extension NSRange {
    
    func rangeStringIndex(for string: String) -> Range<String.Index> {
        let start = string.index(string.startIndex, offsetBy: self.location)
        let end = string.index(start, offsetBy: self.length)
        return start ..< end
    }
    
}

extension String {
    
    subscript(range: NSRange) -> String {
        let start = self.index(self.startIndex, offsetBy: range.location)
        let end = self.index(start, offsetBy: range.length)
        return String(self[start ..< end])
    }
    
}

let version = arguments[1]
let downloadURLString = "http://download.kinvey.com/iOS/Kinvey-\(version).zip"
let versionTuple: (major: Int, minor: Int, patch: Int) = {
    let regex = try! NSRegularExpression(pattern: "(\\d+)\\.(\\d+)\\.(\\d+)")
    let match = regex.firstMatch(in: version, range: NSRange(location: 0, length: version.count))!
    let major = Int(version[match.range(at: 1)])!
    let minor = Int(version[match.range(at: 2)])!
    let patch = Int(version[match.range(at: 3)])!
    return (major: major, minor: minor, patch: patch)
}()
let session = URLSession.shared

func latestRelease(completionHandler: @escaping ([String : Any]) -> Void) {
    let request = URLRequest(url: URL(string: "https://api.github.com/repos/Kinvey/swift-sdk/releases/latest")!)
    
    let task = session.dataTask(with: request) { (data, response, error) -> Void in
        if let httpResponse = response as? HTTPURLResponse,
            200 <= httpResponse.statusCode && httpResponse.statusCode < 300,
            let data = data,
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let latestRelease = jsonObject as? [String : Any]
        {
            completionHandler(latestRelease)
        } else if let error = error {
            print(error)
            fatalError()
        } else {
            if let response = response {
                print(response.description)
                print(response.debugDescription)
            }
            if let data = data,
                let string = String(data: data, encoding: .utf8)
            {
                print(string)
            }
            fatalError()
        }
    }
    task.resume()
}

func convertBody(body: String) -> String {
    var result = ""
    let regexHeader = try! NSRegularExpression(pattern: "##\\s?(.*)")
    let regexTopic = try! NSRegularExpression(pattern: "\\*\\s?(.*)")
    var currentHeader: String? = nil
    for line in body.components(separatedBy: "\n") {
        if let match = regexHeader.firstMatch(in: line, range: NSRange(location: 0, length: line.count)),
            match.numberOfRanges > 1
        {
            currentHeader = line[match.range(at: 1)]
            switch currentHeader {
            case "Improvements"?:
                currentHeader = "Improvement"
            case "Bugfixes"?:
                currentHeader = "Bugfix"
            case "Breaking Changes"?:
                currentHeader = "Breaking Change"
            default:
                break
            }
        } else if let currentHeader = currentHeader,
            let match = regexTopic.firstMatch(in: line, range: NSRange(location: 0, length: line.count)),
            match.numberOfRanges > 1,
            let line = Optional(line[match.range(at: 1)]),
            line != "None"
        {
            result += "* \(currentHeader): \(line)\n"
        }
    }
    return result
}

func changeDownloadsJson(pathURL: URL) {
    guard FileManager.default.fileExists(atPath: pathURL.path) else {
        fatalError("Path does not exists: \(pathURL.path)")
    }
    var data = try! Data(contentsOf: pathURL)
    var json = String(data: data, encoding: .utf8)!
    let regex = try! NSRegularExpression(pattern: "\"ios\"\\s*:\\s*\\{(\\s*\\n*\\s*\"[^\"]*\"\\s*:\\s*(\"[^\"]*\"|\\{(\\s*\\n*\\s*\"[^\"]*\"\\s*:\\s*\"[^\"]*\"\\s*,?\\s*\\n*\\s*)*\\})\\s*,?\\s*\\n*\\s*)*\\}")
    let match = regex.firstMatch(in: json, range: NSRange(location: 0, length: json.count))!
    var ios = json[match.range]
    
    let regexKeyValue = try! NSRegularExpression(pattern: "\"([^\"]*)\"\\s*:\\s*\"([^\"]*)\"")
    for match in regexKeyValue.matches(in: ios, range: NSRange(location: 0, length: ios.count)) where match.numberOfRanges == 3 {
        let rangeKey = match.range(at: 1)
        let rangeValue = match.range(at: 2)
        let key = ios[rangeKey]
        switch key {
        case "version":
            ios.replaceSubrange(rangeValue.rangeStringIndex(for: ios), with: version)
        case "link":
            ios.replaceSubrange(rangeValue.rangeStringIndex(for: ios), with: downloadURLString)
        case "releaseDate":
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            ios.replaceSubrange(rangeValue.rangeStringIndex(for: ios), with: dateFormatter.string(from: Date()))
        default:
            break
        }
    }
    json.replaceSubrange(match.range.rangeStringIndex(for: json), with: ios)
    
    data = json.data(using: .utf8)!
    try! data.write(to: pathURL, options: [.atomic])
    
    print("File \(pathURL.lastPathComponent) changed!")
}

func changeChangelog(pathURL: URL, body: String) {
    guard FileManager.default.fileExists(atPath: pathURL.path) else {
        fatalError("Path does not exists: \(pathURL.path)")
    }	
    var data = try! Data(contentsOf: pathURL)
    var content = String(data: data, encoding: .utf8)!
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM dd, yyyy"
    let date = dateFormatter.string(from: Date())
    content.insert(contentsOf: "\n\n{{ download('\(version)', '\(date)', '\(downloadURLString)') }}\n\n\(body)", at: content.range(of: "{% include '../content/guide/ios-v3.0/language-support.md' %}")!.upperBound)
    
    data = content.data(using: .utf8)!
    try! data.write(to: pathURL, options: [.atomic])
    
    print("File \(pathURL.lastPathComponent) changed!")
}

func changeLanguageSupport(pathURL: URL) {
    guard FileManager.default.fileExists(atPath: pathURL.path) else {
        fatalError("Path does not exists: \(pathURL.path)")
    }
    var data = try! Data(contentsOf: pathURL)
    var content = String(data: data, encoding: .utf8)!
    
    let regex = try! NSRegularExpression(pattern: "\\| Swift 3\\.1 and above \\| (\\d+\\.\\d+) \\| \\[Download Version (\\d+\\.\\d+\\.\\d+)\\]\\(([^\\)]*)\\) \\|")
    guard let match = regex.firstMatch(in: content, range: NSRange(location: 0, length: content.count)) else {
        print("Language Support not detected!")
        return
    }
    let versionWithoutPatchRange = match.range(at: 1)
    let versionRange = match.range(at: 2)
    let downloadURLRange = match.range(at: 3)
    
    content.replaceSubrange(versionWithoutPatchRange.rangeStringIndex(for: content), with: "\(versionTuple.major).\(versionTuple.minor)")
    content.replaceSubrange(versionRange.rangeStringIndex(for: content), with: version)
    content.replaceSubrange(downloadURLRange.rangeStringIndex(for: content), with: downloadURLString)
    
    data = content.data(using: .utf8)!
    try! data.write(to: pathURL, options: [.atomic])
    
    print("File \(pathURL.lastPathComponent) changed!")
}

func changeFiles(body: String) {
    let basePathURL = URL(fileURLWithPath: NSString(string: arguments[2]).standardizingPath)
    
    let downloadsJsonPathURL = basePathURL.appendingPathComponent("content").appendingPathComponent("downloads.json")
    changeDownloadsJson(pathURL: downloadsJsonPathURL)
    
    let changelogPathURL = basePathURL.appendingPathComponent("content").appendingPathComponent("downloads").appendingPathComponent("ios-changelog.md")
    changeChangelog(pathURL: changelogPathURL, body: body)
    
    let languageSupportPathURL = basePathURL.appendingPathComponent("content").appendingPathComponent("guide").appendingPathComponent("ios-v3.0").appendingPathComponent("language-support.md")
    changeLanguageSupport(pathURL: languageSupportPathURL)
}

latestRelease { latestRelease in
    var body = latestRelease["body"] as! String
    body = convertBody(body: body)
    changeFiles(body: body)
    exit(EXIT_SUCCESS)
}

CFRunLoopRun()
