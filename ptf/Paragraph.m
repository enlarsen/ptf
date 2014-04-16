//
//  Paragraph.m
//  ptf
//
//  Created by Erik Larsen on 3/25/14.
//  Copyright (c) 2014 Erik Larsen. All rights reserved.
//

#import "Paragraph.h"

static NSRegularExpression *indentRegex = nil;
static NSRegularExpression *headerRegex = nil;
static NSRegularExpression *letterRegex = nil;
static NSRegularExpression *sceneSeparatorRegex = nil;

@interface Paragraph()

@property (strong, nonatomic) NSArray *tokens;
@property (strong, nonatomic) NSArray *tokenRanges;
@property (nonatomic) int numberSentenceTerminators;
@property (nonatomic) double fileAverageLineLength;
@property (nonatomic) double fileStandardDeviationLineLength;

@end

@implementation Paragraph

+ (void)initialize
{
    if(!indentRegex)
    {
        indentRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\s+"
                                           options:0 error:nil];
        letterRegex = [NSRegularExpression regularExpressionWithPattern:@"[a-z]"
                                  options:NSRegularExpressionCaseInsensitive
                                    error:nil];
        headerRegex = [NSRegularExpression
                                    regularExpressionWithPattern:@"^\\s*(V(?i:olume)|B(?i:ook)|P(?i:art)|C(?i:hapter)|S(?i:ection)|A(?i:ct)|S(?i:cene)|T(?i:able of)|I(?i:ntroduction)|P(?i:reface)|F(?i:oreward)|C(?i:onclusion)|A(?i:ppendix)|A(?i:ddendum)|G(?i:lossary)|P(?i:rologue)|P(?i:rolog)|E(?i:pilogue)|E(?i:pilog))\\b(.*)"
                                    options:0 error:nil];
        sceneSeparatorRegex = [NSRegularExpression
                               regularExpressionWithPattern:@"^\\s*([-o#=+*]\\W*)+\\s*$"
                               options:NSRegularExpressionCaseInsensitive
                               error:nil];

    }
}


- (id)initWithText:(NSString *)text
{
    self = [self init];
    if(self)
    {
        self.text = [text copy];

    }
    return self;
}

- (void)countLines
{
    self.numberOfLines = 0;

    [self.text enumerateLinesUsingBlock:^(NSString *line, BOOL *stop)
     {
         self.numberOfLines++;
     }];

}

- (void)rewrap
{
    NSMutableString *rewrapped = [[NSMutableString alloc] init];

    if(self.kind == body || self.kind == indentedBody)
    {
        [self.text enumerateLinesUsingBlock:^(NSString *line, BOOL *stop)
        {
            NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

            [rewrapped appendString:[trimmedLine stringByAppendingString:@" "]];
        }];
        [rewrapped appendString:@"\n"];
        self.text = [rewrapped copy];
    }
    if(self.kind == sceneSeparator)
    {
        self.text = @"***\n";
    }
}
// TODO:
// Look for pathological case where every other line is short. Indicates longer lines
// were wrapped but paragraph wasn't rewrapped as a whole. Need to detect. Ideas:
// std deviation is high relative to mean as percentage (> 10%)
//
// If the file is pathalogical, have more tests to find unbreakable lines within
// a body paragraph. If three std deviations less than the mean is negative, don't look
// for short lines at all.
- (void)scanLines
{
    __block long numberIndented = 0;
    __block long numberShort = 0;
    __block long numberCapitalized = 0;
    __block long numberHeader = 0;
    __block long numberAllUppercase = 0;
    __block long numberSceneSeparators = 0;

    [self.text enumerateLinesUsingBlock:^(NSString *line, BOOL *stop)
     {
         NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

         if(trimmedLine.length < self.shortLineLength)
         {
             numberShort++;
         }

         NSRange rangeOfFirstMatch = [indentRegex
                                      rangeOfFirstMatchInString:line
                                      options:0
                                      range:NSMakeRange(0, [line length])];
         if(rangeOfFirstMatch.location == 0 && rangeOfFirstMatch.length != 0)
         {
             numberIndented++;
         }

         rangeOfFirstMatch = [sceneSeparatorRegex
                              rangeOfFirstMatchInString:line
                              options:0 range:NSMakeRange(0, [line length])];
         if(rangeOfFirstMatch.location == 0 && rangeOfFirstMatch.length != 0)
         {
             numberSceneSeparators++;
         }

         rangeOfFirstMatch = [headerRegex
                              rangeOfFirstMatchInString:line
                              options:0
                              range:NSMakeRange(0, [line length])];
         if(rangeOfFirstMatch.location == 0 && rangeOfFirstMatch.length != 0)
         {
             numberHeader++;
         }

         if([line isEqualToString:[line uppercaseString]])
         {
             // Handle case where line contains no letters, return NO;
             NSUInteger numberOfMatches = [letterRegex numberOfMatchesInString:line
                                options:0
                                range:NSMakeRange(0, [line length])];
             if(numberOfMatches)
             {
                 numberAllUppercase++;

             }
         }

     }];
    NSString *trimmedParagraph = [self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // More than 50% of the lines are indented
    if(((double)numberIndented / (double)self.numberOfLines) > 0.5)
    {
        _indented = YES;
    }
    else
    {
        _indented = NO;
    }

    if((double)numberAllUppercase / (double)self.numberOfLines > 0.5)
    {
        _allUppercase = YES;
    }
    else
    {
        _allUppercase = NO;
    }

    if((double)numberSceneSeparators / (double)self.numberOfLines > 0.5)
    {
        self.kind = sceneSeparator;
    }

    // TODO: Other possibilities for header.
    //
    // All caps, one line, no punctuation or just one terminator
    // Single Roman numeral paragraph
    // Dates/Months/Seasons (single line) diary entry?
    if((double)numberHeader / (double)self.numberOfLines > 0.5)
    {
        if(self.numberSentenceTerminators <= 1)
        {
            self.kind = header;
        }
//        else // TODO: what about block quote?
//        {
//            self.kind = body;
//        }
    }
    if(self.numberOfLines == 1 &&
       self.kind != header &&
       self.kind != sceneSeparator &&
       self.numberSentenceTerminators == 0 &&
       trimmedParagraph.length < self.shortLineLength)
    {
        self.kind = subheader;
    }
//    else
//    {
//        self.kind = body;
//    }

    if(self.indented == YES && self.kind == body)
    {
        self.kind = indentedBody;
    }

    if((double)numberShort / (double)self.numberOfLines > 0.5)
    {
        _containsShortLines = YES;
    }
    else
    {
        _containsShortLines = NO; // Not strictly correct
    }
}

- (void)linguisticallyTag
{
    NSLinguisticTaggerOptions options = 0;

    NSArray *tagSchemes = [NSLinguisticTagger availableTagSchemesForLanguage:@"en"];

    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:tagSchemes options:options];

    tagger.string = self.text;
    NSArray *tokenRanges;

    self.tokens = [tagger tagsInRange:NSMakeRange(0,[self.text length])
                               scheme:NSLinguisticTagSchemeLexicalClass
                              options:options
                          tokenRanges:&tokenRanges];

    self.tokenRanges = [tokenRanges mutableCopy];
    int terminators = 0;

    for(NSString *token in self.tokens)
    {
        if(token == NSLinguisticTagSentenceTerminator)
        {
            terminators++;
        }
    }
    self.numberSentenceTerminators = terminators;

}

/* Use linguistic tagging info to change to smart quotes.
    Must be run after tagging */
- (void)fixQuotes
{
    NSMutableString *text = [self.text mutableCopy];

    for(int i = 0; i < self.tokens.count; i++)
    {
        if(self.tokens[i] == NSLinguisticTagOpenQuote)
        {
            NSString *tokenString = [text substringWithRange:[self.tokenRanges[i] rangeValue]];

            if([tokenString isEqualToString:@"\""])
            {
                [text replaceCharactersInRange:[self.tokenRanges[i] rangeValue] withString:@"\u201c"];
                continue;
            }
            if([tokenString isEqualToString:@"'"])
            {
                [text replaceCharactersInRange:[self.tokenRanges[i] rangeValue] withString:@"\u2018"];
                continue;
            }
//            NSLog(@"Found unknown open quote string");


        }
        if(self.tokens[i] == NSLinguisticTagCloseQuote)
        {
            NSString *tokenString = [text substringWithRange:[self.tokenRanges[i] rangeValue]];

            if([tokenString isEqualToString:@"\""])
            {
                [text replaceCharactersInRange:[self.tokenRanges[i] rangeValue] withString:@"\u201d"];
                continue;
            }
            if([tokenString isEqualToString:@"'"])
            {
                [text replaceCharactersInRange:[self.tokenRanges[i] rangeValue] withString:@"\u2019"];
                continue;
            }
//            NSLog(@"Found unknown close quote string");

        }
    }
    // Change apostrophes to single close quotes
    // TODO: three dots to ellipsis dots
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length)
                             options:NSStringEnumerationByWords
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop)
      {
            NSRange quoteRange = [substring rangeOfString:@"'"];

            if(quoteRange.location != NSNotFound)
            {
                NSRange replacementRange = NSMakeRange(substringRange.location + quoteRange.location,
                                                       quoteRange.length);
                [text replaceCharactersInRange:replacementRange withString:@"\u2019"];
//                                    NSLog(@"Found a single quote!");
            }

      }];

    self.text = [text copy];
}

// Linguistic tagging will get out of sync after this method is run.
- (void)fixEllipsisDots
{
    NSMutableString *text = [self.text mutableCopy];

    for(int i = 0; i < self.tokenRanges.count; i++)
    {
        NSRange range = [self.tokenRanges[i] rangeValue];

        NSString *token = [self.text substringWithRange:range];
        if([token isEqualToString:@"..."])
        {
            [text replaceCharactersInRange:range withString:@"\u2026"];
            [self fixRanges:range withAdjustment:-2]; // three dots => one char = -2
            continue;
        }
        if([token isEqualToString:@"--"])
        {
            [text replaceCharactersInRange:range withString:@"\u2014"];
            [self fixRanges:range withAdjustment:-1]; // two hyphens => one char = -1
        }
    }
    self.text = [text copy];
}

// This one will damage the linguistic tagging ranges. TODO: find solution
- (void)fixDashes
{

}

- (void)fixAllCaps
{
    // Need to somehow mark text as italic (what all caps becomes) that
    // doesn't mix in controller or view stuff.
}

// Why not retag? It's too slow

- (void)fixRanges:(NSRange)startingRange withAdjustment:(NSUInteger)adjustment
{
    BOOL foundMatching = NO;
    NSMutableArray *tokenRanges = [self.tokenRanges mutableCopy];

    for(int i = 0; i < self.tokenRanges.count; i++)
    {
        NSRange currentTokenRange = [self.tokenRanges[i] rangeValue];

        if(NSEqualRanges(currentTokenRange, startingRange))
        {
            // Adjust the token to be smaller/bigger, then cascade all subsequent .location
            NSRange newTokenRange = NSMakeRange(startingRange.location,
                                                startingRange.length + adjustment);
            tokenRanges[i] = [NSValue valueWithRange:newTokenRange];
            foundMatching = YES;
            continue;
        }
        if(foundMatching)
        {
            NSRange newTokenRange = NSMakeRange(currentTokenRange.location + adjustment,
                                                currentTokenRange.length);
            tokenRanges[i] = [NSValue valueWithRange:newTokenRange];

        }
    }
    self.tokenRanges = [tokenRanges copy];
}

- (void)detectWithAverageLineLength:(double)averageLineLength standardDeviation:(double)standardDeviation
{
    self.fileAverageLineLength = averageLineLength;
    self.fileStandardDeviationLineLength = standardDeviation;

    self.shortLineLength = (int)round(averageLineLength - (3.0 * standardDeviation));

    self.relativeStdDeviation = standardDeviation/averageLineLength * 100.0;

    [self countLines];
    [self linguisticallyTag];
    [self fixQuotes];
    [self fixEllipsisDots];
    [self scanLines];
    [self rewrap];

}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p, %@>",
            [self class],
            self,
                  @{@"kind":@(self.kind),
                    @"text":self.text,
                    @"numberSentenceTerminators":@(self.numberSentenceTerminators),
                    @"fileAverageLineLength":@(self.fileAverageLineLength),
                    @"fileStandardDeviationLineLength":@(self.fileStandardDeviationLineLength),
                    @"tokens":self.tokens,
                    @"tokenRanges":self.tokenRanges,
                    @"numberOfLines":@(self.numberOfLines)}
            ];
}


@end
