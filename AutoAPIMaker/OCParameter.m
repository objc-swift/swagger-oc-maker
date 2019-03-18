//
//  OCParameter.m
//  AutoAPIMaker
//
//  Created by 蒲公英 on 2019/3/18.
//  Copyright © 2019年 MVC. All rights reserved.
//

#import "OCParameter.h"

@implementation OCParameter
- (void)setParameterName:(NSString *)parameterName {
    
    _parameterName = parameterName;
    if ([_parameterName isEqualToString:@"id"]) {
        _displayName = @"idField";
    }else {
        _displayName = parameterName;
    }
}
- (NSString *)displayName {
    return _displayName;
}
- (NSString *)firstAplhaUpperCaseName {
    NSString *first =  [[self.displayName substringToIndex:1] uppercaseString];
    NSString *remain = [self.displayName substringFromIndex:1];
    NSString *str =   [NSString stringWithFormat:@"%@%@",first,remain];
    return str ;
}
@end
