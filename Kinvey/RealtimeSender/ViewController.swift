//
//  ViewController.swift
//  Realtime Sender
//
//  Created by Victor Hugo on 2017-06-09.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Cocoa
import Kinvey

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        var appKey: String? = nil
        var appSecret: String? = nil
        var hostUrl: String? = nil
        
        var username: String? = nil
        var password: String? = nil
        
        var receiverId: String? = nil
        
        var songName: String? = nil
        var songArtist: String? = nil
        var songRating: Int? = nil
        
        var logNetworkEnabled: Bool? = nil
        
        let arguments = ProcessInfo.processInfo.arguments
        for (i, argument) in arguments.enumerated() {
            switch argument {
            case "-appKey":
                appKey = arguments[i + 1]
            case "-appSecret":
                appSecret = arguments[i + 1]
            case "-hostUrl":
                hostUrl = arguments[i + 1]
            case "-username":
                username = arguments[i + 1]
            case "-password":
                password = arguments[i + 1]
            case "-receiverId":
                receiverId = arguments[i + 1]
            case "-songName":
                songName = arguments[i + 1]
            case "-songArtist":
                songArtist = arguments[i + 1]
            case "-songRating":
                songRating = Int(arguments[i + 1])
            case "-logNetworkEnabled":
                logNetworkEnabled = Bool(arguments[i + 1])
            default:
                break
            }
        }
        
        guard let _ = appKey else {
            fatalError("appKey missing")
        }
        
        guard let _ = appSecret else {
            fatalError("appSecret missing")
        }
        
        var hostURL: URL? = nil
        if let hostUrl = hostUrl {
            hostURL = URL(string: hostUrl)
        }
        
        if let logNetworkEnabled = logNetworkEnabled {
            Kinvey.sharedClient.logNetworkEnabled = logNetworkEnabled
        }
        
        Kinvey.sharedClient.initialize(
            appKey: appKey!,
            appSecret: appSecret!,
            apiHostName: hostURL ?? Client.defaultApiHostName
        )
        
        guard let _ = username else {
            fatalError("username missing")
        }
        
        guard let _ = password else {
            fatalError("password missing")
        }
        
        guard let _ = receiverId else {
            fatalError("receiverId missing")
        }
        
        func exit() {
            NSApplication.shared.terminate(self)
        }
        
        func send() {
            print(
                "Song:\n",
                "\t Name: \(songName ?? "nil")\n",
                "\t Artist: \(songArtist ?? "nil")\n",
                "\t Rating: \(songRating ?? 0)"
            )
            let songRecommendation = SongRecommendation(name: songName, artist: songArtist, rating: songRating)
            
            print("Sending data to \(receiverId!)")
            
            let stream = LiveStream<SongRecommendation>(name: "SongRecommendation")
            stream.send(userId: receiverId!, message: songRecommendation) { (result: Result<Void, Swift.Error>) in
                switch result {
                case .success:
                    print("Data Sent!")
                    exit()
                case .failure(let error):
                    print("Send Data Failed")
                    print(error)
                    exit()
                }
            }
        }
        
        func registerForRealtime(user: User) {
            print("Registering for Realtime")
            user.registerForRealtime { (result: Result<Void, Swift.Error>) in
                switch result {
                case .success:
                    print("Registering for Realtime Succeed")
                    send()
                case .failure(let error):
                    print("Registering for Realtime Failed")
                    print(error)
                    exit()
                }
            }
        }
        
        print("Requesting Login")
        
        User.login(
            username: username!,
            password: password!,
            client: sharedClient
        ) { (result: Result<User, Swift.Error>) in
            switch result {
            case .success(let user):
                print("Login Succeed")
                registerForRealtime(user: user)
            case .failure(let error):
                print("Login Failed")
                print(error)
                exit()
            }
        }
    }


}

