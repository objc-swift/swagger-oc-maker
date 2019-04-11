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
@property (strong) NSDictionary *swagger_dict ;
@property (copy) NSString *curDateStr;
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
    _swagger_dict = jsonDict;
    NSDictionary *paths = jsonDict[@"paths"];
    for ( NSString *key in paths) {
        [self makeFileByApiPathDict:paths[key] apiPath:key];
    }
}

- (void)makeFileByApiPathDict:(NSDictionary *)apiPathDict
                      apiPath:(NSString *)apiPath {
    NSTimeInterval curDateInterval = [[NSDate date] timeIntervalSince1970];
    
    self.curDateStr = [self timeWithTimeInterval_allNumberStyleString:curDateInterval];
    
    for (NSString *apiPathItem in apiPathDict) {
        if ([self isHttpMethodStr:apiPathItem]) {

            NSString *fileName = [self fileNameByApiPath:apiPath httpMethod:apiPathItem];
            NSDictionary *httpMethodDict = apiPathDict[apiPathItem];
            NSArray<OCParameter *> *parametersArr = [self getParametersByHttpParametersArr:httpMethodDict[@"parameters"]];
            NSString *methodBodyString = [self createMethodByParametersArray:parametersArr ];
            NSString *summary = httpMethodDict[@"summary"];
            [self make_h_file:fileName methodBodyStr:methodBodyString summary:summary];
            [self make_m_file:fileName
                methodBodyStr:methodBodyString
                parametersArr:parametersArr
                      apiPath:apiPath
                   httpMethod:apiPathItem summary:summary];
        }
    }
}
- (void)make_h_file:(NSString *)filename
      methodBodyStr:(NSString *)methodBody
            summary:(NSString *)summary{
    NSMutableString *oc_hCodeStr = [[NSMutableString alloc] init];
    NSString *dir = self.outPathTextField.stringValue;
    NSString *path = [NSString stringWithFormat:@"%@%@.h",dir,filename];
    [oc_hCodeStr appendString:@"// https://github.com/objc94 \n"];
    [oc_hCodeStr appendString:[NSString stringWithFormat:@"// created by swagger-occode api maker at %@\n",self.curDateStr]];
    [oc_hCodeStr appendString:[NSString stringWithFormat:@"// summary:%@\n",summary]];
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
- (void) make_m_file:(NSString *)fileName
      methodBodyStr:(NSString *)methodBody
       parametersArr:(NSArray<OCParameter *> *)parametersArr
             apiPath:(NSString *)apiPath httpMethod:(NSString *)httpMethod
             summary:(NSString *)summary {
    
    NSMutableString *oc_mCodeStr = [[NSMutableString alloc] init];
    [oc_mCodeStr appendString:@"// https://github.com/objc94 \n"];
    [oc_mCodeStr appendString:[NSString stringWithFormat:@"// created by swagger-occode api maker at %@\n",self.curDateStr]];
    [oc_mCodeStr appendString:[NSString stringWithFormat:@"// summary:%@\n",summary]];
    NSString *dir = self.outPathTextField.stringValue;
    NSString *path = [NSString stringWithFormat:@"%@%@.m",dir,fileName];
    NSError *err = nil;
    NSString *importStr = [NSString stringWithFormat:@"#import \"%@.h\"\n",fileName];
    [oc_mCodeStr appendString:importStr];
    NSString *impstr = [NSString stringWithFormat:@"@implementation %@\n",fileName];
    [oc_mCodeStr appendString:impstr];
    [oc_mCodeStr appendString:methodBody];
    [oc_mCodeStr appendString:@" {\n"];
    [oc_mCodeStr appendString:[NSString stringWithFormat:@"  NSString *apiPath = @\"%@\";\n",apiPath]];
    NSMutableString  *oc_pathParaSetting = [[NSMutableString alloc] init];
    NSMutableString  *oc_mainParaSetting = [[NSMutableString alloc] init];
    for (OCParameter *oc_parameter in parametersArr) {
        if ([oc_parameter.httpParameterType isEqualToString:@"path"]) {
            NSString *para = [NSString stringWithFormat:@"{%@}",oc_parameter.parameterName];\
            NSString *pathParamSetCode = @"";
            if (oc_parameter.parameterType == NSNumber.class) {
              pathParamSetCode = [NSString stringWithFormat:@"  apiPath = [apiPath stringByReplacingOccurrencesOfString:@\"%@\" withString:@%@.stringValue];\n",para,oc_parameter.displayName];
            }else if (oc_parameter.parameterType == NSString.class){
                pathParamSetCode = [NSString stringWithFormat:@"  apiPath = [apiPath stringByReplacingOccurrencesOfString:@\"%@\" withString:%@)];\n",para,oc_parameter.displayName];
            }
            [oc_pathParaSetting appendString:pathParamSetCode];
        }else {
            NSString *setCode = [NSString stringWithFormat: @"  self.requestDict[@\"%@\"] = %@; //%@\n",oc_parameter.parameterName,oc_parameter.displayName,oc_parameter.parameterDescription];
            [oc_mainParaSetting appendString:setCode];
        }
    }
    [oc_mainParaSetting appendString:@"  self.apiPath  = apiPath;\n"];
    NSDictionary *methodMap = @{@"get":@"HTTPMethodGET",
                                @"post":@"HTTPMethodPOST",
                                @"put":@"HTTPMethodPUT",
                                @"delete":@"HTTPMethodDELETE"};
    [oc_mainParaSetting appendString:[NSString stringWithFormat:@"  [self connectWithRquestMethod:%@];\n",methodMap[httpMethod]]];
    [oc_mCodeStr appendString:oc_pathParaSetting];
    [oc_mCodeStr appendString:oc_mainParaSetting];
    [oc_mCodeStr appendString:@"}\n@end\n"];
    [oc_mCodeStr writeToURL:[NSURL fileURLWithPath:path] atomically:YES encoding:NSUTF8StringEncoding error:&err];
    
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
           NSArray<OCParameter *> *ocParameters = [self getParamertersByDefinetionProperties:_swagger_dict[@"definitions"][bodyDefineKey][@"properties"]];
            [parameters addObjectsFromArray:ocParameters];
           
        } else if ([_in isEqualToString:@"query"] ||
                   [_in isEqualToString:@"path"]) {
            
            OCParameter *ocParameter = [[OCParameter alloc] init];
            ocParameter.parameterName = parameterDict[@"name"];
            ocParameter.httpParameterType = _in;
            ocParameter.parameterDescription = parameterDict[@"description"];
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
- (NSArray<OCParameter *> *)getParamertersByDefinetionProperties:(NSDictionary *)properties {
    NSMutableArray *parameters = [[NSMutableArray alloc] init];
    for (NSString *key in properties) {
        NSDictionary *parameterDict = properties[key];
        OCParameter *ocParameter = [[OCParameter alloc] init];
        ocParameter.parameterName = key ;
        ocParameter.parameterDescription = parameterDict[@"description"];
        NSString *rawType = parameterDict[@"type"];
        ocParameter.httpParameterType = rawType;
        if ([rawType isEqualToString:@"integer"] ||
           [rawType isEqualToString:@"number"]) {
            ocParameter.parameterType = NSNumber.class;
        }
        if ([rawType isEqualToString:@"string"]) {
            ocParameter.parameterType = NSString.class;
        }
        [parameters addObject:ocParameter];
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

- (NSString *)timeWithTimeInterval_allNumberStyleString:( NSInteger)time
{
    // 格式化时间
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"shanghai"];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    // 毫秒值转化为秒
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:time ];
    NSString* dateString = [formatter stringFromDate:date];
    return dateString;
}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}
@end
