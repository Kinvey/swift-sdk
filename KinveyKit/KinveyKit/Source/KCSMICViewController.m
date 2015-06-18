//
//  KCSMICViewController.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-06-16.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSMICViewController.h"
#import <WebKit/WebKit.h>

@interface KCSMICViewController () <UIWebViewDelegate, WKNavigationDelegate>

@property (nonatomic, copy) NSString* redirectURI;
@property (nonatomic, copy) KCSUserCompletionBlock completionBlock;

@property (nonatomic, weak) id webView;
@property (nonatomic, weak) UIActivityIndicatorView* activityIndicatorView;

@end

@implementation KCSMICViewController

-(instancetype)initWithRedirectURI:(NSString *)redirectURI
               withCompletionBlock:(KCSUserCompletionBlock)completionBlock
{
    self = [super init];
    if (self) {
        _redirectURI = redirectURI;
        _completionBlock = completionBlock;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Class clazz = NSClassFromString(@"WKWebView");
    if (clazz) {
        WKWebView* webView = [[WKWebView alloc] init];
        webView.translatesAutoresizingMaskIntoConstraints = NO;
        webView.navigationDelegate = self;
        [self.view addSubview:webView];
        self.webView = webView;
    } else {
        UIWebView* webView = [[UIWebView alloc] init];
        webView.translatesAutoresizingMaskIntoConstraints = NO;
        webView.delegate = self;
        [self.view addSubview:webView];
        self.webView = webView;
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" X "
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(closeViewController:)];
    
    UIBarButtonItem* refreshPageBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                          target:self
                                                                                          action:@selector(refreshPage:)];
    
    self.navigationItem.rightBarButtonItem = refreshPageBarButtonItem;
    
    NSDictionary* views = NSDictionaryOfVariableBindings(_webView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    
    UIActivityIndicatorView* activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    activityIndicatorView.hidesWhenStopped = YES;
    activityIndicatorView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    activityIndicatorView.layer.cornerRadius = 8;
    activityIndicatorView.layer.masksToBounds = YES;
    CGRect rect = CGRectInset(activityIndicatorView.bounds, -8, -8);
    activityIndicatorView.bounds = CGRectMake(0, 0, rect.size.width, rect.size.height);
    [self.view insertSubview:activityIndicatorView aboveSubview:self.webView];
    self.activityIndicatorView = activityIndicatorView;
    
    [activityIndicatorView addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicatorView
                                                                      attribute:NSLayoutAttributeWidth
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                                     multiplier:1.f
                                                                       constant:activityIndicatorView.bounds.size.width]];
    
    [activityIndicatorView addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicatorView
                                                                      attribute:NSLayoutAttributeHeight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                                     multiplier:1.f
                                                                       constant:activityIndicatorView.bounds.size.height]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicatorView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.f
                                                           constant:0.f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicatorView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.f
                                                           constant:0.f]];
}

-(void)closeViewController:(id)sender
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

-(void)refreshPage:(id)sender
{
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        [(UIWebView*)self.webView reload];
    } else {
        [(WKWebView*)self.webView reload];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSURL* url = [KCSUser URLforLoginWithMICRedirectURI:self.redirectURI];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        [(UIWebView*)self.webView loadRequest:request];
    } else {
        [(WKWebView*)self.webView loadRequest:request];
    }
}

-(void)parseMICURL:(NSURL*)url
{
    [self.activityIndicatorView startAnimating];
    
    [KCSUser parseMICRedirectURI:self.redirectURI
                          forURL:url
             withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result)
     {
         [self.activityIndicatorView stopAnimating];
         
         if (user) {
             [self closeViewController:nil];
         }
         
         if (self.completionBlock) {
             self.completionBlock(user, errorOrNil, result);
         }
     }];
}

-(void)failWithError:(NSError*)error
{
    NSURL* url = error.userInfo[NSURLErrorFailingURLErrorKey];
    if (!url || ![KCSUser isValidMICRedirectURI:self.redirectURI
                                         forURL:url])
    {
        [self.activityIndicatorView stopAnimating];
    }
}

#pragma mark - UIWebViewDelegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL* url = request.URL;
    
    if ([KCSUser isValidMICRedirectURI:self.redirectURI
                                forURL:url])
    {
        [self parseMICURL:url];
        
        return NO;
    }
    
    return YES;
}

-(void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.activityIndicatorView startAnimating];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self failWithError:error];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicatorView stopAnimating];
}

#pragma mark - WKNavigationDelegate

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL* url = navigationAction.request.URL;
    
    if ([KCSUser isValidMICRedirectURI:self.redirectURI
                                forURL:url])
    {
        [self parseMICURL:url];
        
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    [self.activityIndicatorView startAnimating];
}

-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self failWithError:error];
}

-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self failWithError:error];
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self.activityIndicatorView stopAnimating];
}

@end
