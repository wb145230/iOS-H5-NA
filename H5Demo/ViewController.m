//
//  ViewController.m
//  H5Demo
//
//  Created by wangbo11 on 16/1/21.
//  Copyright © 2016年 wangbo11. All rights reserved.
//

#import "ViewController.h"
#import "WebViewJavascriptBridge.h"
#import "SDWebImageManager.h"

@interface ViewController ()<UIWebViewDelegate>

@property (nonatomic, strong)UIWebView *webView;
@property (nonatomic, strong)WebViewJavascriptBridge *bridge;

@property (nonatomic, strong)NSArray *imageArray;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initWebView];
    [self initJSbirdge];
    [self setupRequest];
}

- (void)initWebView {
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_webView];
}

- (void)initJSbirdge {
    
    // 初始化bridge
    _bridge = [WebViewJavascriptBridge bridgeForWebView:_webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"ObjC received message from JS: %@", data);
        responseCallback(@"Response for message from ObjC");
    }];
    
    // 注册和H5相同的方法
    [_bridge registerHandler:@"testObjcCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSDictionary *dict = data;
        NSString *url = [dict objectForKey:@"url"];
    
        // 下载图片
        [self downloadImage:url];
        
    }];
}

- (void)setupRequest {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://wb145230.github.io/"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5];
    [_webView loadRequest:request];
}

- (void)downloadImage:(NSString *)url {
    SDWebImageManager *imageManager = [SDWebImageManager sharedManager];
    [[SDWebImageManager sharedManager] setCacheKeyFilter:^(NSURL *url) {
        url = [[NSURL alloc] initWithScheme:url.scheme host:url.host path:url.path];
        NSString *str = [url absoluteString];
        return str;
    }];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"com.hackemist.SDWebImageCache.default"];
    
    NSURL *imageUrl = [NSURL URLWithString:url];
    if ([imageManager diskImageExistsForURL:imageUrl]) {
        NSString *cacheKey = [imageManager cacheKeyForURL:imageUrl];
        NSString *imagePaths = [NSString stringWithFormat:@"%@/%@",filePath,[imageManager.imageCache cachedFileNameForKey:cacheKey]];
        
        
        NSData *data = UIImagePNGRepresentation([UIImage imageNamed:imagePaths]);
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:url forKey:@"imageUrl"];
        // 图片以base64方式给H5的图片赋值
        [dict setObject:[NSString stringWithFormat:@"data:image/png;base64,%@",[data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]] forKey:@"imagePaths"];
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        if (error == nil && jsonData.length > 0) {
            NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            // 把相关的图片信息以json格式传递给H5,方便H5解析
            [_bridge send:jsonStr responseCallback:^(id responseData) {
                
            }];
        }
    } else {
        [imageManager downloadImageWithURL:imageUrl options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            
            if (image && finished) {//如果下载成功
                
                NSData *data = UIImagePNGRepresentation(image);
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                [dict setObject:url forKey:@"imageUrl"];
                [dict setObject:[NSString stringWithFormat:@"data:image/png;base64,%@",[data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]] forKey:@"imagePaths"];
                
                NSError *error;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
                if (error == nil && jsonData.length > 0) {
                    NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    [_bridge send:jsonStr responseCallback:^(id responseData) {
                        
                    }];
                }
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
