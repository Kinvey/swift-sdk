//
//  MIC.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-01-18.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

class URLSessionDelegateAdapter : NSObject, URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
    
}

/// Class that handles Mobile Identity Connect (MIC) calls
open class MIC {
    
    private init() {
    }
    
    /**
     Validate if a URL matches for a redirect URI and also contains a code value
     */
    open class func isValid(redirectURI: URL, url: URL) -> Bool {
        switch parseCode(redirectURI: redirectURI, url: url) {
        case .success(_):
            return true
        case .failure(_):
            return false
        }
    }
    
    class func parseCode(redirectURI: URL, url: URL) -> Result<String, Swift.Error?> {
        guard redirectURI.scheme?.lowercased() == url.scheme?.lowercased(),
            redirectURI.host?.lowercased() == url.host?.lowercased(),
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = urlComponents.queryItems
        else {
            return .failure(nil)
        }
        
        var code: String? = nil
        var error: String? = nil
        var errorDescription: String? = nil
        for queryItem in queryItems {
            guard let value = queryItem.value, !value.isEmpty else {
                continue
            }
            switch queryItem.name {
            case "code":
                code = value
            case "error":
                error = value
            case "error_description":
                errorDescription = value
            default:
                break
            }
        }
        
        if let code = code {
            return .success(code)
        } else if let error = error,
            let errorDescription = errorDescription
        {
            return .failure(Error.micAuth(error: error, description: errorDescription))
        }
        return .failure(nil)
    }
    
    /// Returns a URL that must be used for login with MIC
    open class func urlForLogin(
        redirectURI: URL,
        loginPage: Bool = true,
        options: Options? = nil
    ) -> URL {
        let client = options?.client ?? sharedClient
        return Endpoint.oauthAuth(
            client: client,
            clientId: options?.authServiceId,
            redirectURI: redirectURI,
            loginPage: loginPage
        ).url
    }
    
    @discardableResult
    class func login<U: User>(
        redirectURI: URL,
        code: String,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        let client = options?.client ?? sharedClient
        let requests = MultiRequest<Result<U, Swift.Error>>()
        Promise<U> { resolver in
            let request = client.networkRequestFactory.buildOAuthToken(
                redirectURI: redirectURI,
                code: code,
                options: options
            )
            request.execute { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let data = data,
                    let authData = try? client.jsonParser.parseDictionary(from: data)
                {
                    requests += User.login(
                        authSource: .kinvey,
                        authData,
                        options: options
                    ) { (result: Result<U, Swift.Error>) in
                        switch result {
                        case .success(let user):
                            resolver.fulfill(user)
                        case .failure(let error):
                            resolver.reject(error)
                        }
                    }
                } else {
                    resolver.reject(buildError(data, response, error, client))
                }
            }
            requests += request
        }.done { user in
            completionHandler?(.success(user))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(requests)
    }
    
    @discardableResult
    class func login<U: User>(
        redirectURI: URL,
        username: String,
        password: String,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        let client = options?.client ?? sharedClient
        let requests = MultiRequest<Result<U, Swift.Error>>()
        let request = client.networkRequestFactory.buildOAuthGrantAuth(
            redirectURI: redirectURI,
            options: options
        )
        Promise<URL> { resolver in
            request.execute { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let data = data,
                    let json = try? client.jsonParser.parseDictionary(from: data),
                    let tempLoginUri = json["temp_login_uri"] as? String,
                    let tempLoginUrl = URL(string: tempLoginUri)
                {
                    resolver.fulfill(tempLoginUrl)
                } else {
                    resolver.reject(buildError(data, response, error, client))
                }
            }
            requests += request
        }.then { tempLoginUrl in
            return Promise<U> { resolver in
                let request = client.networkRequestFactory.buildOAuthGrantAuthenticate(
                    redirectURI: redirectURI,
                    tempLoginUri: tempLoginUrl,
                    username: username,
                    password: password,
                    options: options
                )
                let urlSession = options?.urlSession ?? URLSession(
                    configuration: client.urlSession.configuration,
                    delegate: URLSessionDelegateAdapter(),
                    delegateQueue: nil
                )
                request.execute(urlSession: urlSession) { (data, response, error) in
                    if let response = response,
                        let httpResponse = response as? HttpResponse,
                        httpResponse.response.statusCode == 302,
                        let location = httpResponse.response.allHeaderFields["Location"] as? String,
                        let url = URL(string: location)
                    {
                        switch parseCode(redirectURI: redirectURI, url: url) {
                        case .success(let code):
                            requests += login(
                                redirectURI: redirectURI,
                                code: code,
                                options: options
                            ) { result in
                                switch result {
                                case .success(let user):
                                    resolver.fulfill(user as! U)
                                case .failure(let error):
                                    resolver.reject(error)
                                }
                            }
                        case .failure(let error):
                            resolver.reject(error ?? buildError(data, response, error, client))
                        }
                    } else {
                        resolver.reject(buildError(data, response, error, client))
                    }
                    urlSession.invalidateAndCancel()
                }
                requests += request
            }
        }.done { user -> Void in
            completionHandler?(.success(user))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(requests)
    }
    
    @discardableResult
    class func login<U: User>(
        username: String,
        password: String,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        let client = options?.client ?? sharedClient
        let requests = MultiRequest<Result<U, Swift.Error>>()
        let request = client.networkRequestFactory.buildOAuthToken(
            username: username,
            password: password,
            options: options
        )
        requests += request
        Promise<JsonDictionary> { resolver in
            request.execute { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let data = data,
                    let json = try? client.jsonParser.parseDictionary(from: data)
                {
                    resolver.fulfill(json)
                } else {
                    resolver.reject(error ?? buildError(data, response, error, client))
                }
            }
        }.then { socialIdentity in
            return Promise<U> { resolver in
                requests += User.login(
                    authSource: .kinvey,
                    socialIdentity
                ) { result in
                    switch result {
                    case .success(let user):
                        resolver.fulfill(user as! U)
                    case .failure(let error):
                        resolver.reject(error)
                    }
                }
            }
        }.done { user -> Void in
            completionHandler?(.success(user))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return AnyRequest(requests)
    }
    
    @discardableResult
    class func login<U: User>(
        refreshToken: String,
        options: Options?,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<U, Swift.Error>> {
        let requests = MultiRequest<Result<U, Swift.Error>>()
        let client = options?.client ?? sharedClient
        let request = client.networkRequestFactory.buildOAuthGrantRefreshToken(
            refreshToken: refreshToken,
            options: options
        )
        request.execute { (data, response, error) in
            if let response = response,
                response.isOK,
                let data = data,
                let authData = try? client.jsonParser.parseDictionary(from: data)
            {
                requests += User.login(authSource: .kinvey, authData, options: options, completionHandler: completionHandler)
            } else {
                completionHandler?(.failure(buildError(data, response, error, client)))
            }
        }
        requests += request
        return AnyRequest(requests)
    }
    
}

/// Used to tell which user interface must be used during the login process using MIC.
public enum MICUserInterface {
    
    /// Uses SFSafariViewController
    case safari

    /// Uses SFAuthenticationSession if running on iOS 11 and above, otherwise uses SFSafariViewController instead
    case safariAuthenticationSession
    
    /// Uses WKWebView
    case wkWebView
    
    /// Uses UIWebView
    case uiWebView
    
    /// Default Value: .safari
    public static let `default`: MICUserInterface = .safariAuthenticationSession
    
}

/// Specifies which version of the MIC API will be used.
public enum MICApiVersion: String {
    
    /// Version 1
    case v1
    
    /// Version 2
    case v2
    
    /// Version 3
    case v3
    
}

#if os(iOS)

import UIKit
import WebKit

class MICLoginViewController: UIViewController, WKNavigationDelegate, UIWebViewDelegate {
    
    typealias UserHandler<U: User> = (Result<U, Swift.Error>) -> Void
    
    var activityIndicatorView: UIActivityIndicatorView!
    
    var redirectURI: URL!
    var forceUIWebView: Bool!
    var options: Options?
    var completionHandler: UserHandler<User>!
    
    @objc
    var webView: UIView!
    var timer: Timer? {
        willSet {
            if let timer = timer, timer.isValid {
                timer.invalidate()
            }
        }
    }
    
    convenience init<UserType: User>(
        redirectURI: URL,
        userType: UserType.Type,
        forceUIWebView: Bool = false,
        options: Options?,
        completionHandler: @escaping UserHandler<UserType>
    ) {
        self.init(nibName: nil, bundle: nil)
        self.redirectURI = redirectURI
        self.forceUIWebView = forceUIWebView
        self.options = options
        self.completionHandler = {
            switch $0 {
            case .success(let user):
                completionHandler(.success(user as! UserType))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = NSClassFromString("WKWebView"), !forceUIWebView {
            let wkWebView = WKWebView()
            wkWebView.navigationDelegate = self
            webView = wkWebView
        } else {
            let uiWebView = UIWebView()
            uiWebView.delegate = self
            webView = uiWebView
        }
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.accessibilityIdentifier = "Web View"
        view.addSubview(webView)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: " X ",
            style: .plain,
            target: self,
            action: #selector(closeViewControllerUserInteractionCancel(_:))
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshPage(_:))
        )
        
        let views = [
            "webView" : webView!
        ]
        
        view.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[webView]|",
            metrics: nil,
            views: views
        ))
        
        view.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|[webView]|",
            metrics: nil,
            views: views
        ))
        
        activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        activityIndicatorView.layer.cornerRadius = 8
        activityIndicatorView.layer.masksToBounds = true
        let rect = activityIndicatorView.bounds.insetBy(dx: -8, dy: -8)
        activityIndicatorView.bounds = CGRect(origin: CGPoint.zero, size: rect.size)
        view.insertSubview(activityIndicatorView, aboveSubview: webView)
        
        activityIndicatorView.addConstraint(NSLayoutConstraint(
            item: activityIndicatorView,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: activityIndicatorView.bounds.size.width
        ))
        
        activityIndicatorView.addConstraint(NSLayoutConstraint(
            item: activityIndicatorView,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: activityIndicatorView.bounds.size.height
        ))
        
        view.addConstraint(NSLayoutConstraint(
            item: activityIndicatorView,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: view,
            attribute: .centerX,
            multiplier: 1,
            constant: 0
        ))
        
        view.addConstraint(NSLayoutConstraint(
            item: activityIndicatorView,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: view,
            attribute: .centerY,
            multiplier: 1,
            constant: 0
        ))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let url = MIC.urlForLogin(redirectURI: redirectURI, options: options)
        let request = URLRequest(url: url)
        webView(
            wkWebView: { $0.load(request) },
            uiWebView: { $0.loadRequest(request) }
        )
        
        if let timeout = options?.timeout, timeout > 0 {
            timer = Timer.scheduledTimer(
                timeInterval: timeout,
                target: self,
                selector: #selector(closeViewControllerUserInteractionTimeout(_:)),
                userInfo: nil,
                repeats: false
            )
        }
    }
    
    func webView(wkWebView: (WKWebView) -> Void, uiWebView: (UIWebView) -> Void) {
        if let webView = webView as? WKWebView {
            wkWebView(webView)
        } else if let webView = webView as? UIWebView {
            uiWebView(webView)
        }
    }
    
    @objc
    func closeViewControllerUserInteractionCancel(_ sender: Any) {
        closeViewControllerUserInteraction(.failure(Error.requestCancelled))
    }
    
    @objc
    func closeViewControllerUserInteractionTimeout(_ sender: Any) {
        closeViewControllerUserInteraction(.failure(Error.requestTimeout))
    }
    
    func closeViewControllerUserInteraction(_ result: Result<User, Swift.Error>) {
        timer = nil
        dismiss(animated: true) {
            self.completionHandler(result)
        }
    }
    
    @objc
    func refreshPage(_ sender: Any) {
        webView(
            wkWebView: { $0.reload() },
            uiWebView: { $0.reload() }
        )
    }
    
    func success(code: String) {
        activityIndicatorView.startAnimating()
        
        MIC.login(
            redirectURI: redirectURI,
            code: code,
            options: options
        ) { result in
            self.activityIndicatorView.stopAnimating()
            
            self.closeViewControllerUserInteraction(result)
        }
    }
    
    func failure(error: Swift.Error) {
        let url = (error as NSError).userInfo[NSURLErrorFailingURLErrorKey] as? URL
        if url == nil || !MIC.isValid(redirectURI: redirectURI, url: url!) {
            activityIndicatorView.stopAnimating()
            
            closeViewControllerUserInteraction(.failure(error))
        }
    }
    
    func handleError(body: String?) {
        if let body = body,
            let data = body.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data),
            let json = object as? JsonDictionary
        {
            failure(error: Error.unknownJsonError(httpResponse: nil, data: nil, json: json))
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var navigationActionPolicy: WKNavigationActionPolicy = .allow
        if let url = navigationAction.request.url {
            switch MIC.parseCode(redirectURI: redirectURI, url: url) {
            case .success(let code):
                success(code: code)
                
                navigationActionPolicy = .cancel
            case .failure(let error):
                if let error = error {
                    failure(error: error)
                    
                    navigationActionPolicy = .cancel
                }
            }
        }
        decisionHandler(navigationActionPolicy)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicatorView.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Swift.Error) {
        failure(error: error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Swift.Error) {
        failure(error: error)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.body.innerText") { body, error in
            if let body = body as? String {
                self.handleError(body: body)
            }
        }
        
        activityIndicatorView.stopAnimating()
    }
    
    // MARK: - UIWebViewDelegate
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        if let url = request.url {
            switch MIC.parseCode(redirectURI: redirectURI, url: url) {
            case .success(let code):
                success(code: code)
                return false
            case .failure(let error):
                if let error = error {
                    failure(error: error)
                    return false
                }
            }
        }
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        activityIndicatorView.startAnimating()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Swift.Error) {
        failure(error: error)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        let body = webView.stringByEvaluatingJavaScript(from: "document.body.innerText")
        handleError(body: body)
        
        activityIndicatorView.stopAnimating()
    }
    
}

#endif
