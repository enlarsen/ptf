//
//  PlainTextFile.h
//  ptf
//
//  Created by Erik Larsen on 3/26/14.
//  Copyright (c) 2014 Erik Larsen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlainTextFile : NSObject

@property (strong, nonatomic) NSMutableArray *paragraphs;
@property (nonatomic) double averageLineLength;
@property (nonatomic) double stdDeviationLineLength;
@property (nonatomic) long shortLineLength;


- (id)initWithFile:(NSString *)filePath;
- (void)convertToParagraphs;   // Call order: 1
- (void)computeLineStatistics; // 2
- (void)analyzeParagraphs;      // 3

@end
