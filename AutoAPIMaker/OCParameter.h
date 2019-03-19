//
//  OCParameter.h
//  AutoAPIMaker
//
//  Created by 蒲公英 on 2019/3/18.
//  Copyright © 2019年 MVC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCParameter : NSObject
@property (copy,nonatomic) NSString *displayName;
@property (copy,nonatomic) NSString *parameterName;
@property (assign) Class parameterType; // NSString NSNumber ,etc
@property (copy,nonatomic) NSString *httpParameterType; // path ,query ,post ,etc
@property (copy,nonatomic) NSString *parameterDescription;

- (NSString *)firstAplhaUpperCaseName ;


@end

NS_ASSUME_NONNULL_END
