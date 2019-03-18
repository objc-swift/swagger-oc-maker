//
//  ViewController.m
//  AutoAPIMaker
//
//  Created by 蒲公英 on 2019/3/16.
//  Copyright © 2019年 MVC. All rights reserved.
//

#import "ViewController.h"
#import "OCParameter.h"
@interface ViewController()
@property (weak) IBOutlet NSTextField *inputTextField;
@property (weak) IBOutlet NSButton *makeButton;
@property (weak) IBOutlet NSTextField *outPathTextField;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%@",[NSObject description]);
    
}
- (IBAction)showDifferentAlert:(NSButton *)sender {
    NSAlert * alert = [[NSAlert alloc]init];
    alert.messageText = @"JSON 文本解析失败";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"好的"]; //will generate a return code of 1000
    [alert setInformativeText:@"请检查JSON 格式是否正确！"];
    [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
        
    }];
}

- (IBAction)makeButtonTap:(id)sender {
    
    NSString *jsonString = self.inputTextField.stringValue;
    NSDictionary *jsonDict = [self dictionaryWithJsonString:jsonString];
    if (!jsonDict) {
        [self showDifferentAlert:sender];
        return ;
    }
    NSDictionary *paths = jsonDict[@"paths"];
    for ( NSString *key in paths) {
        [self makeFileByApiPathDict:paths[key] apiPath:key];
    }
}

- (void)makeFileByApiPathDict:(NSDictionary *)apiPathDict
                      apiPath:(NSString *)apiPath {
    
    for (NSString *apiPathItem in apiPathDict) {
        if ([self isHttpMethodStr:apiPathItem]) {

            NSString *fileName = [self fileNameByApiPath:apiPath httpMethod:apiPathItem];
            NSDictionary *httpMethodDict = apiPathDict[apiPathItem];
            NSArray<OCParameter *> *parametersArr = [self getParametersByHttpParametersArr:httpMethodDict[@"parameters"]];
            NSString *methodBodyString = [self createMethodByParametersArray:parametersArr ];
            [self make_h_file:fileName methodBodyStr:methodBodyString];
            
        }
    }
}
- (void)make_h_file:(NSString *)filename methodBodyStr:(NSString *)methodBody {
    NSMutableString *oc_hCodeStr = [[NSMutableString alloc] init];
    NSString *dir = self.outPathTextField.stringValue;
    NSString *path = [NSString stringWithFormat:@"%@%@.h",dir,filename];
    [oc_hCodeStr appendString:@"#import \"ServModel.h\"\n"];
    [oc_hCodeStr appendString:[NSString stringWithFormat:@"@interface %@ : ServModel\n",filename]];
    [oc_hCodeStr appendString:methodBody];
    [oc_hCodeStr appendString:@";\n"];
    [oc_hCodeStr appendString:@"@end\n"];
    NSError *err = nil;
    [oc_hCodeStr writeToURL:[NSURL fileURLWithPath:path] atomically:YES encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        NSLog(@"%@",err);
    }
}
/*
 由 httpMethodDict创建
 */
- (NSString *)createMethodByParametersArray:(NSArray<OCParameter *> *)parametersArray{
   
    // apiPath中可能有参数
    NSArray *httpParamters = parametersArray;
    if (httpParamters.count == 0) {
        return @"- (void)sendRequest";
    }
    NSMutableString *oc_methodStr = [[NSMutableString alloc] init];
    [oc_methodStr appendFormat:@"- (void)sendRequestWith"];
    for (OCParameter *parameter in httpParamters) {
        if (parameter == httpParamters.firstObject) {
            [oc_methodStr appendString:parameter.firstAplhaUpperCaseName];
        }else {
            // 不是第一个参数有空格，且小写
            NSString *parameterStr = [NSString stringWithFormat:@" %@",parameter.displayName];
            [oc_methodStr appendString:parameterStr];
        }
        NSString *realParameter = [NSString stringWithFormat:@":(#!TYPE)%@",parameter.displayName];
        NSString *typePoinerStr = [NSString stringWithFormat:@"%@ *",[parameter.parameterType description]];
        realParameter = [realParameter stringByReplacingOccurrencesOfString:@"#!TYPE" withString:typePoinerStr];
        [oc_methodStr appendString:realParameter];
    }
    return oc_methodStr;
}

- (NSString *)fileNameByApiPath:(NSString *)apiPath httpMethod:(NSString *)method {
    NSMutableString *fileName = [[NSMutableString alloc] init];
    NSArray *partOfPath = [apiPath componentsSeparatedByString:@"/"];
    NSMutableString *pathWithUnderline =  [[NSMutableString alloc] init];
    for (NSString *part in partOfPath) {
        NSString *finalPart = part;
        if (finalPart.length == 0) continue;
        [pathWithUnderline appendString:@"_"];
        if ([finalPart containsString:@"{"]) {
            // delte {}
            finalPart = [finalPart stringByReplacingOccurrencesOfString:@"{" withString:@""];
            finalPart = [finalPart stringByReplacingOccurrencesOfString:@"}" withString:@""];
        }
        [pathWithUnderline appendString:finalPart.capitalizedString];
    }
    [fileName appendString:@"API_"];
    [fileName appendString:method.uppercaseString];
    [fileName appendString:pathWithUnderline];
    return fileName;
}

- (NSArray<NSString *> *)getPathParameterName:(NSString *)apiPath {
    NSArray *partOfPath = [apiPath componentsSeparatedByString:@"/"];
    NSMutableArray *parameters = [[NSMutableArray alloc] init];
    for (NSString *part in partOfPath) {
        NSString *finalPart = part;
        if ([finalPart containsString:@"{"]) {
            // delte {}
            finalPart = [finalPart stringByReplacingOccurrencesOfString:@"{" withString:@""];
            finalPart = [finalPart stringByReplacingOccurrencesOfString:@"}" withString:@""];
        }
        [parameters addObject:finalPart];
    }
    return parameters;
}

- (NSArray<OCParameter *> *)getParametersByHttpParametersArr:(NSArray *)parametersArr {
    NSMutableArray *parameters = [[NSMutableArray alloc] init];
    for (NSDictionary *parameterDict in parametersArr) {
        NSString *_in =  parameterDict[@"in"];
        if ([self isNotInHttpHead:_in]) continue ;
        if ([_in isEqualToString:@"body"]) {
           NSString *ref = parameterDict[@"schema"][@"$ref"];
           NSString *bodyDefineKey = [ref componentsSeparatedByString:@"/"].lastObject;
            
        } else if ([_in isEqualToString:@"query"] ||
                   [_in isEqualToString:@"path"]) {
            
            OCParameter *ocParameter = [[OCParameter alloc] init];
            ocParameter.parameterName = parameterDict[@"name"];
            ocParameter.httpParameterType = _in;
            [parameters addObject:ocParameter];
            if ([parameterDict[@"type"] isEqualToString:@"integer"] ||
                [parameterDict[@"type"] isEqualToString:@"number"]) {
                ocParameter.parameterType = NSNumber.class;
            }
            if ([parameterDict[@"type"] isEqualToString:@"string"]) {
                ocParameter.parameterType = NSString.class;
            }
        }
    }
    return parameters;
}
- (BOOL)isNotInHttpHead:(NSString *)type {
    
    return !( [type isEqualToString:@"in"] ||[type isEqualToString:@"path"] ||[type isEqualToString:@"query"]  || [type isEqualToString:@"body"] ) ;
    
}
- (BOOL)isContainPathParameter:(NSString *)apiPath {
    // etc ,/block/{blokcId}
    return [apiPath containsString:@"{"] ;
}
- (BOOL)isHttpMethodStr:(NSString *)key {
    
    return [key isEqualToString:@"post"] ||
          [key isEqualToString:@"get"] ||
          [key isEqualToString:@"put"] ||
          [key isEqualToString:@"delete"] ;
}
- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}
@end
