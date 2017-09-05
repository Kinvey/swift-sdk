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
        return parseCode(redirectURI: redirectURI, url: url) != nil
    }
    
    class func parseCode(redirectURI: URL, url: URL) -> String? {
        guard redirectURI.scheme?.lowercased() == url.scheme?.lowercased(),
            redirectURI.host?.lowercased() == url.host?.lowercased(),
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            var queryItems = urlComponents.queryItems
            else
        {
            return nil
        }
        
        queryItems = queryItems.filter { $0.name == "code" && $0.value != nil && !$0.value!.isEmpty }
        guard queryItems.count == 1, let queryItem = queryItems.first, let code = queryItem.value else {
            return nil
        }
        
        return code
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
            clientId: options?.clientId,
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
    ) -> Request {
        let client = options?.client ?? sharedClient
        let requests = MultiRequest()
        Promise<U> { fulfill, reject in
            let request = client.networkRequestFactory.buildOAuthToken(
                redirectURI: redirectURI,
                code: code,
                options: options
            )
            request.execute { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let authData = client.responseParser.parse(data)
                {
                    requests += User.login(
                        authSource: .kinvey,
                        authData,
                        options: options
                    ) { (result: Result<U, Swift.Error>) in
                        switch result {
                        case .success(let user):
                            fulfill(user)
                        case .failure(let error):
                            reject(error)
                        }
                    }
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
            requests += request
        }.then { user in
            completionHandler?(.success(user))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return requests
    }
    
    @discardableResult
    class func login<U: User>(
        redirectURI: URL,
        username: String,
        password: String,
        options: Options? = nil,
        completionHandler: ((Result<U, Swift.Error>) -> Void)? = nil
    ) -> Request {
        let client = options?.client ?? sharedClient
        let requests = MultiRequest()
        let request = client.networkRequestFactory.buildOAuthGrantAuth(
            redirectURI: redirectURI,
            options: options
        )
        Promise<URL> { fulfill, reject in
            request.execute { (data, response, error) in
                if let response = response,
                    response.isOK,
                    let json = client.responseParser.parse(data),
                    let tempLoginUri = json["temp_login_uri"] as? String,
                    let tempLoginUrl = URL(string: tempLoginUri)
                {
                    fulfill(tempLoginUrl)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
            requests += request
        }.then { tempLoginUrl in
            return Promise<U> { fulfill, reject in
                let request = client.networkRequestFactory.buildOAuthGrantAuthenticate(
                    redirectURI: redirectURI,
                    tempLoginUri: tempLoginUrl,
                    username: username,
                    password: password,
                    options: options
                )
                let urlSession = URLSession(
                    configuration: client.urlSession.configuration,
                    delegate: URLSessionDelegateAdapter(),
                    delegateQueue: nil
                )
                request.execute(urlSession: urlSession) { (data, response, error) in
                    if let response = response,
                        let httpResponse = response as? HttpResponse,
                        httpResponse.response.statusCode == 302,
                        let location = httpResponse.response.allHeaderFields["Location"] as? String,
                        let url = URL(string: location),
                        let code = parseCode(redirectURI: redirectURI, url: url)
                    {
                        requests += login(
                            redirectURI: redirectURI,
                            code: code,
                            options: options
                        ) { result in
                            switch result {
                            case .success(let user):
                                fulfill(user as! U)
                            case .failure(let error):
                                reject(error)
                            }
                        }
                    } else {
                        reject(buildError(data, response, error, client))
                    }
                    urlSession.invalidateAndCancel()
                }
                requests += request
            }
        }.then { user -> Void in
            completionHandler?(.success(user))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return requests
    }
    
    @discardableResult
    class func login<U: User>(
        refreshToken: String,
        clientId: String?,
        client: Client = sharedClient,
        completionHandler: User.UserHandler<U>? = nil
    ) -> Request {
        let requests = MultiRequest()
        let request = client.networkRequestFactory.buildOAuthGrantRefreshToken(
            refreshToken: refreshToken,
            options: Options(
                clientId: clientId
            )
        )
        request.execute { (data, response, error) in
            if let response = response, response.isOK, let authData = client.responseParser.parse(data) {
                requests += User.login(authSource: .kinvey, authData, client: client, completionHandler: completionHandler)
            } else {
                completionHandler?(nil, buildError(data, response, error, client))
            }
        }
        requests += request
        return requests
    }
    
}

/// Used to tell which user interface must be used during the login process using MIC.
public enum MICUserInterface {
    
    /// Uses SFSafariViewController
    case safari
    
    /// Uses WKWebView
    case wkWebView
    
    /// Uses UIWebView
    case uiWebView
    
}

/// Specifies which version of the MIC API will be used.
public enum MICApiVersion: String {
    
    /// Version 1
    case v1 = "v1"
    
    /// Version 2
    case v2 = "v2"
    
    /// Version 3
    case v3 = "v3"
    
}

#if os(iOS)

import UIKit
import WebKit

class MICLoginViewController: UIViewController, WKNavigationDelegate, UIWebViewDelegate {
    
    typealias UserHandler<U: User> = (Result<U, Swift.Error>) -> Void
    
    var activityIndicatorView: UIActivityIndicatorView!
    
    let redirectURI: URL
    let forceUIWebView: Bool
    let options: Options?
    let completionHandler: UserHandler<User>
    
    var webView: UIView!
    var timer: Timer? {
        willSet {
            if let timer = timer, timer.isValid {
                timer.invalidate()
            }
        }
    }
    
    init<UserType: User>(
        redirectURI: URL,
        userType: UserType.Type,
        forceUIWebView: Bool = false,
        options: Options?,
        completionHandler: @escaping UserHandler<UserType>
    ) {
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
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
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
    
    func closeViewControllerUserInteractionCancel(_ sender: Any) {
        closeViewControllerUserInteraction(.failure(Error.requestCancelled))
    }
    
    func closeViewControllerUserInteractionTimeout(_ sender: Any) {
        closeViewControllerUserInteraction(.failure(Error.requestTimeout))
    }
    
    func closeViewControllerUserInteraction(_ result: Result<User, Swift.Error>) {
        timer = nil
        dismiss(animated: true) {
            self.completionHandler(result)
        }
    }
    
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
        if let url = navigationAction.request.url,
            let code = MIC.parseCode(redirectURI: redirectURI, url: url)
        {
            success(code: code)
            
            decisionHandler(.cancel)
        }
        
        decisionHandler(.allow)
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
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.url, let code = MIC.parseCode(redirectURI: redirectURI, url: url) {
            success(code: code)
            return false
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
