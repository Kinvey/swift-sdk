//
//  main.swift
//  GithubRelease
//
//  Created by Victor Hugo on 2017-07-18.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation

let githubToken = ProcessInfo.processInfo.environment["GITHUB_TOKEN"]
guard githubToken != nil else {
    fatalError("GITHUB_TOKEN environment variable missing")
}

var arguments = ProcessInfo.processInfo.arguments
if arguments.contains("-module-name"),
    let moduleNameIndex = arguments.firstIndex(of: "-module-name"),
    let mainIndex = arguments.firstIndex(of: "main"),
    moduleNameIndex + 1 == mainIndex,
    let dashDashIndex = arguments.firstIndex(of: "--"),
    mainIndex + 1 == dashDashIndex
{
    arguments = Array(arguments[dashDashIndex ..< arguments.count])
}
let session = URLSession.shared

func listReleases(completionHandler: @escaping ([[String : Any]]) -> Void) {
    var request = URLRequest(url: URL(string: "https://api.github.com/repos/Kinvey/swift-sdk/releases")!)
    request.httpMethod = "GET"
    request.setValue("token \(githubToken!)", forHTTPHeaderField: "Authorization")

    let task = session.dataTask(with: request) { (data, response, error) -> Void in
        if let httpResponse = response as? HTTPURLResponse,
            200 <= httpResponse.statusCode && httpResponse.statusCode < 300,
            let data = data,
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let releases = jsonObject as? [[String : Any]]
        {
            completionHandler(releases)
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

func firstDraft(completionHandler: @escaping ([String : Any]) -> Void) {
    listReleases { releases in
        guard let firstDraft = releases.first else {
            fatalError("Release not found")
        }
        guard let draft = firstDraft["draft"] as? Bool, draft else {
            fatalError("Release detected is not a Draft Release")
        }
        completionHandler(firstDraft)
    }
}

func currentVersion() -> (infoPlist: String, podspec: String) {
    let path = URL(fileURLWithPath: NSString(string: arguments[2]).standardizingPath).absoluteURL.path
    let process = Process()
    process.environment = ["PWD" : path]
    process.currentDirectoryPath = path
    process.launchPath = "/usr/bin/make"
    process.arguments = ["show-version"]
    let standardOutput = Pipe()
    process.standardOutput = standardOutput
    process.launch()
    process.waitUntilExit()
    let data = standardOutput.fileHandleForReading.readDataToEndOfFile()
    let string = String(data: data, encoding: .utf8)!
    var infoPlistTmp: String? = nil
    var podspecTmp: String? = nil
    for line in string.components(separatedBy: "\n") {
        let parts = line.components(separatedBy: " ").filter { $0.count > 0 }
        guard parts.count == 2 else {
            continue
        }
        switch parts[0] {
        case "Info.plist":
            infoPlistTmp = parts[1]
        case "Kinvey.podspec":
            podspecTmp = parts[1]
        default:
            break
        }
    }
    guard let infoPlist = infoPlistTmp else {
        fatalError("Info.plist not found")
    }
    guard let podspec = podspecTmp else {
        fatalError("Kinvey.podspec not found")
    }
    guard infoPlist == podspec else {
        fatalError("Info.plist and Kinvey.podspec values must be equal")
    }
    return (infoPlist: infoPlist, podspec: podspec)
}

func check(printStatus: Bool = false, completionHandler: @escaping ([String : Any]) -> Void) {
    firstDraft { firstDraft in
        guard let name = firstDraft["name"] as? String,
            let tagName = firstDraft["tag_name"] as? String,
            name == tagName
            else {
                fatalError("'name' and 'tag_name' must be equal")
        }
        guard let targetCommitish = firstDraft["target_commitish"] as? String,
            targetCommitish == "master"
            else {
                fatalError("'target_commitish' branch must be 'master'")
        }
        guard let body = firstDraft["body"] as? String, !body.isEmpty else {
            fatalError("'body' must not be empty")
        }
        guard arguments.count > 2 else {
            fatalError("Missing path! Usage: \(arguments[0]) \(arguments[1]) <path>")
        }
        let version = currentVersion()
        guard version.podspec == tagName else {
            fatalError("Kinvey.podspec and 'tag_name' values must be equal")
        }
        if printStatus {
            print("Release Name     -> \(name)")
            print("Release Tag Name -> \(tagName)")
            print("Info.plist       -> \(version.infoPlist)")
            print("Kinvey.podspec   -> \(version.podspec)")
        }
        completionHandler(firstDraft)
    }
}

func uploadFiles(_ draft: [String : Any], completionHandler: @escaping () -> Void) {
    let basePath = NSString(string: arguments[2]).standardizingPath
    let basePathURL = URL(fileURLWithPath: basePath)
    let carthageBuildURL = basePathURL.appendingPathComponent("Carthage").appendingPathComponent("Build")
    let carthageZipURL = carthageBuildURL.appendingPathComponent("Carthage.xcframework.zip")
    let version = currentVersion()
    let zipURL = carthageBuildURL.appendingPathComponent("Kinvey-\(version.infoPlist).zip")
    DispatchQueue.global().async {
        let uploadGroup = DispatchGroup()

        func deleteFile(url: String, completionHandler: @escaping () -> Void) {
            var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = "DELETE"
            request.setValue("token \(githubToken!)", forHTTPHeaderField: "Authorization")

            let task = session.dataTask(with: request) { (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse,
                    200 <= httpResponse.statusCode && httpResponse.statusCode < 300,
                    let _ = data
                {
                    print("File deleted: \(url)")
                    completionHandler()
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
            print("Deleting file: \(url)")
            task.resume()
        }

        if let assets = draft["assets"] as? [[String : Any]] {
            for asset in assets {
                if let url = asset["url"] as? String {
                    uploadGroup.enter()
                    deleteFile(url: url) {
                        uploadGroup.leave()
                    }
                }
            }
            uploadGroup.wait()
        }

        func uploadFile(_ draft: [String : Any], file: URL, name: String? = nil, completionHandler: @escaping () -> Void) {
            guard let uploadUrl = draft["upload_url"] as? String else {
                fatalError("'upload_url' not found")
            }
            var urlComponents = URLComponents(string: uploadUrl.replacingOccurrences(of: "{?name,label}", with: ""))!
            let fileName = name ?? file.lastPathComponent
            urlComponents.queryItems = [
                URLQueryItem(name: "name", value: fileName)
            ]
            let url = urlComponents.url!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("token \(githubToken!)", forHTTPHeaderField: "Authorization")
            request.setValue("application/zip", forHTTPHeaderField: "Content-Type")

            let reportProgress = { (task: URLSessionUploadTask, change: NSKeyValueObservedChange<Int64>) in
                guard task.countOfBytesExpectedToSend > 0 else {
                    return
                }
                let percent = Float(task.countOfBytesSent) / Float(task.countOfBytesExpectedToSend) * 100
                print(String(format: "File \(fileName) status: \(task.countOfBytesSent)/\(task.countOfBytesExpectedToSend) %.1f%%\r", percent))
            }

            var countOfBytesSentObservationToken: NSKeyValueObservation?
            var countOfBytesExpectedToSendObservationToken: NSKeyValueObservation?

            let task = session.uploadTask(with: request, fromFile: file) { (data, response, error) in
                if let observationToken = countOfBytesSentObservationToken {
                    observationToken.invalidate()
                }
                if let observationToken = countOfBytesExpectedToSendObservationToken {
                    observationToken.invalidate()
                }
                if let httpResponse = response as? HTTPURLResponse,
                    200 <= httpResponse.statusCode && httpResponse.statusCode < 300
                {
                    print("File \(fileName) upload finished!")
                    completionHandler()
                } else if let error = error {
                    print(error)
                    fatalError()
                } else {
                    fatalError("Failure during upload file")
                }
            }
            print("Uploading \(fileName)")
            print("POST \(url)")
            let options: NSKeyValueObservingOptions = [.new]
            countOfBytesSentObservationToken = task.observe(
                \.countOfBytesSent,
                options: options,
                changeHandler: reportProgress
            )
            countOfBytesExpectedToSendObservationToken = task.observe(
                \.countOfBytesExpectedToSend,
                options: options,
                changeHandler: reportProgress
            )
            task.resume()
        }

        uploadGroup.enter()
        uploadFile(draft, file: carthageZipURL, name: "Carthage.framework.zip") {
            uploadGroup.leave()
        }
        uploadGroup.wait()

        uploadGroup.enter()
        uploadFile(draft, file: zipURL) {
            uploadGroup.leave()
        }
        uploadGroup.wait()

        completionHandler()
    }
}

func publish(url: String, completionHandler: @escaping () -> Void) {
    var request = URLRequest(url: URL(string: url)!)
    request.httpMethod = "PATCH"
    request.setValue("token \(githubToken!)", forHTTPHeaderField: "Authorization")
    let body = ["draft" : false]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions.sortedKeys)

    let task = session.dataTask(with: request) { (data, response, error) -> Void in
        if let httpResponse = response as? HTTPURLResponse,
            200 <= httpResponse.statusCode && httpResponse.statusCode < 300,
            let _ = data
        {
            completionHandler()
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

func usage() -> Never {
    fatalError("Valid arguments: 'check' or 'release'")
}

guard arguments.count > 1 else {
    usage()
}

switch arguments[1] {
case "check":
    check(printStatus: true) { _ in
        print("You are all set!")
        exit(EXIT_SUCCESS)
    }
case "release":
    check { draft in
        print("Check done!")

        uploadFiles(draft) {
            print("Upload succeed!")

            guard let url = draft["url"] as? String else {
                fatalError("Draft 'url' not found")
            }

            publish(url: url) {
                print("Release Published!")
                exit(EXIT_SUCCESS)
            }
        }
    }
default:
    usage()
}

CFRunLoopRun()
