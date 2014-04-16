//
//  Paragraph.h
//  ptf
//
//  Created by Erik Larsen on 3/25/14.
//  Copyright (c) 2014 Erik Larsen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    body,
    indentedBody,
    sceneSeparator, // "***" et al between scenes
    header, // level 2
    subheader, // level 3
    dialog, // First word all caps followed by colon (many in file)
    preserveBreaks,
} ParagraphKind;

@interface Paragraph : NSObject

@property (nonatomic, strong) NSString *text;
@property (nonatomic) int numberOfLines;
@property (nonatomic, strong) NSMutableArray *characterMarks; // For storing italic bold

@property (nonatomic) int shortLineLength;
@property (nonatomic) double relativeStdDeviation;

// BOOLs as NSNumbers so they're nullable

// objective properties
@property (nonatomic, getter = isIndented) BOOL indented;
@property (nonatomic, getter = isCapitalized) BOOL capitalized;
@property (nonatomic) BOOL containsShortLines;
@property (nonatomic, getter = isAllUppercase) BOOL allUppercase;
//@property (nonatomic, strong) NSNumber *

// subjective properties, need to be guessed
//@property (nonatomic, strong, getter = isHeader) NSNumber *header;
//@property (nonatomic, strong, getter = isBody) NSNumber *body;
//@property (nonatomic, strong, getter = isBlockQuote) NSNumber *blockQuote;
//@property (nonatomic, strong, getter = isSceneSeparator) NSNumber *sceneSeparator;
//@property (nonatomic, strong, getter = isListIntroduction) NSNumber *listIntroduction;
//@property (nonatomic, strong, getter = isDialog) NSNumber *dialog;

@property (nonatomic) ParagraphKind kind;



- (id)initWithText:(NSString *)text;
- (void)detectWithAverageLineLength:(double)averageLineLength standardDeviation:(double)standardDeviation;

@end

/*

Other possible properties
 
 short paragraph (less than two lines)
 indented lines inside paragraph
 short lines inside paragraph
 is scene separator
 is screenplay slug line
 is stage play dialog line (all caps followed by colon)
 is list intro paragraph (ends with colon followed by paragraph of short lines)
 
 # of lines after this paragraph
 # of lines before this paragraph

*/