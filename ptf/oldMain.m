//
//  main.m
//  ptf
//
//  Created by Erik Larsen on 3/17/14.
//  Copyright (c) 2014 Erik Larsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

void processDir(void);
void process(NSString *filePath);
int tag(NSMutableString *paragraph);
int tagAndSaveData(NSMutableString *paragraph);
void analyze(void);
void setupStyles(void);


long maxLineLength = 0L;
long n = 0L;
double mean = 0.0;
double delta = 0.0;
double M2 = 0.0;
long sum = 0L;
long numberLines = 0L;
long shortLineLength = 0L;
long shortShortLineLength = 0L;
double stdDeviation = 0.0;
double averageLineLength = 0.0;
double shortLine = 0L;
double shortShortLine = 0L;



static NSString *const kLinesString = @"Lines";
static NSString *const kLineLengths = @"LineLengths";
static NSString *const kNumberLines = @"NumberLines";
static NSString *const kAverageLineLength = @"AverageLineLength";
static NSString *const kStdDeviationLineLength = @"StdDeviationLineLength"; // for entire file
static NSString *const kMaxLineLength = @"MaxLineLength";
static NSString *const kMinLineLength = @"MinLineLength";
static NSString *const kBeginsUpperCaseLines = @"BeginsUpperCase"; // Whether the line begins with an uppercase char (array)
static NSString *const kAllCapsLines = @"AllCapsLines"; // Whether the line is all caps
static NSString *const kLineIndented = @"LineIndented"; // # of indents (array)
static NSString *const kCenteredLines = @"CenteredLines"; // whether the line is centered (array)
static NSString *const kTags = @"Tags"; // tags for this paragraph
static NSString *const kTagRanges = @"TagRanges"; // ranges for the previous tags
static NSString *const kSentenceTerminators = @"SentenceTerminators"; // # of sentence terminators in the paragraph
static NSString *const kQuotes = @"Quotes"; // # of quotes in the paragraph
static NSString *const kHeadersWithCounter = @"HeadersWithCounters";
static NSString *const kHeaderCounters = @"HeaderCounters";
static NSString *const kHeaders = @"Headers";

static NSRegularExpression *indentRegularExpression;
static NSRegularExpression *headersWithCounters;
static NSRegularExpression *headersWithoutCounters;

static NSMutableParagraphStyle *defaultParagraphStyle;
static NSMutableParagraphStyle *blockQuoteParagraphStyle;
static NSMutableParagraphStyle *listParagraphStyle;
static NSMutableParagraphStyle *headerParagraphStyle;

static NSDictionary *italicAttributeDictionary;
static NSDictionary *boldAttributeDictionary;


//NSMutableDictionary *article; // Contains paragraphs and other metadata about paragraphs (average line length, max line length, etc)
NSMutableArray *paragraphs; // Contains mutable dictionaries, one per paragraph.
NSMutableDictionary *currentParagraph;

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        indentRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"\\s+" options:0 error:nil];
        headersWithCounters = [NSRegularExpression
                               regularExpressionWithPattern:@"^\\s*(volume|book|part|chapter|section|act|scene|appendix)\\b(.*)"
                               options:NSRegularExpressionCaseInsensitive
                                error:nil];
        headersWithoutCounters = [NSRegularExpression
                regularExpressionWithPattern:@"^\\s*(table of|introduction|preface|foreward|conclusion|addendum|synopsis|glossary|prologue|prolog|epilogue|epilog)\\b"
                               options:NSRegularExpressionCaseInsensitive
                                 error:nil];

        setupStyles();
        processDir();

    }
    return 0;
}

void setupStyles()
{
    defaultParagraphStyle = [NSMutableParagraphStyle new];
    blockQuoteParagraphStyle = [NSMutableParagraphStyle new];
    listParagraphStyle = [NSMutableParagraphStyle new];
    headerParagraphStyle = [NSMutableParagraphStyle new];

    defaultParagraphStyle.headIndent = 0;
    defaultParagraphStyle.firstLineHeadIndent = 4;

    blockQuoteParagraphStyle.headIndent = 4;
    blockQuoteParagraphStyle.firstLineHeadIndent = 4;
    blockQuoteParagraphStyle.paragraphSpacingBefore = 4;
    blockQuoteParagraphStyle.tailIndent = 4;

    headerParagraphStyle.headerLevel = 2;
}

void processDir()
{
    NSString *docsDir = @"~/Desktop/st/stuff1/st1/sto/backup/all"; // /html/convert
    NSFileManager *localFileManager=[[NSFileManager alloc] init];
    NSDirectoryEnumerator *dirEnum =
    [localFileManager enumeratorAtPath:[docsDir stringByExpandingTildeInPath]];


    NSString *file;
    while ((file = [dirEnum nextObject]))
    {
        [dirEnum skipDescendants];
        if ([[file pathExtension] isEqualToString: @"txt"]) {
            // process the document

            paragraphs = [[NSMutableArray alloc] init];

            process([docsDir stringByAppendingPathComponent:file]);

            analyze();
            NSLog(@"Average line length: %f", mean);
//            [paragraphs writeToFile:[@"/Users/erikla/Desktop/files/" stringByAppendingPathComponent:file] atomically:YES];

        }
    }
    
}

void process(NSString *path)
{
    NSError *error = nil;
    __block int sentenceTerminators;
    NSStringEncoding encoding = 0;
    NSMutableString *paragraphText = [[NSMutableString alloc] init];

    NSRegularExpression *header = [NSRegularExpression
                                regularExpressionWithPattern:@"^\\s*(volume|book|part|chapter|section|act|scene|table of|introduction|preface|foreward|conclusion|appendix|addendum|synopsis|glossary|prologue|prolog|epilogue|epilog)\\b(.*)"
                                options:NSRegularExpressionCaseInsensitive error:nil];


    NSString *file = [NSString stringWithContentsOfFile:path
                                           usedEncoding:&encoding
                                                  error:&error];
    if(encoding == 0) // Can't figure it out, default to Win 1252
    {
        file = nil;
        error = nil;
        encoding = NSWindowsCP1252StringEncoding;
        file = [NSString stringWithContentsOfFile:path
                                         encoding:encoding
                                            error:&error];
    }

    NSLog(@"File: %@", path);


    [file enumerateLinesUsingBlock:^(NSString *line, BOOL *stop)
     {
         NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

//         NSArray *matches = [header matchesInString:line options:0 range:NSMakeRange(0, line.length)];


         if([trimmedLine isEqualToString:@""])
         {
             if(![paragraphText isEqualToString:@""])
             {
//                 sentenceTerminators = tag(paragraphText);
                 tagAndSaveData(paragraphText);
//                 if(sentenceTerminators == 0)
//                 {
//                     NSLog(@"\t%@", paragraphText);
//                 }
                 [paragraphs addObject:[paragraphText copy]];


                 [paragraphText setString:@""];
             }
         }
         else
         {
             [paragraphText appendString:[line stringByAppendingString:@"\n"]];
         }

     }];

    // TODO: last paragraph if the file doesn't end with a blank line (or append "\n" to file string?)

    return;



}
void analyze()
{
    maxLineLength = 0L;
    n = 0L;
    mean = 0.0;
    delta = 0.0;
    M2 = 0.0;
    sum = 0L;
    numberLines = 0L;
    stdDeviation = 0.0;


    for(NSString *paragraph in paragraphs)
    {
        NSMutableArray *lines = [NSMutableArray array];

        [paragraph enumerateLinesUsingBlock:^(NSString *line, BOOL *stop)
         {
             [lines addObject:line];

         }];

        [lines removeLastObject]; // The last line's length is almost always short

        for(NSString *line in lines)
        {

            maxLineLength = MAX(line.length, maxLineLength);

            sum += line.length;
            numberLines++;

            // variance
            n++;
            delta = (double)line.length - mean;
            mean = mean + delta / (double)n;
            M2 = M2 + delta * ((double)line.length - mean);

        }
     }
    stdDeviation = sqrt(M2/((double)n - 1));
    averageLineLength = (double)sum / (double)numberLines;
    shortLineLength = averageLineLength / 2;
}

void analyzeOld()
{

    // look for header lines
    // look for indented lines
    // calculate line metrics
    // ID as body, header, centered, block quote, list,

    for(NSMutableDictionary *paragraph in paragraphs)
    {
        NSMutableArray *lineLengths = [[NSMutableArray alloc] init];
        NSMutableArray *indentedLines = [[NSMutableArray alloc] init];
        NSMutableArray *headerWithCounter = [NSMutableArray array];
        NSMutableArray *headerCounters = [NSMutableArray array];
        NSMutableArray *headers = [NSMutableArray array];

        unsigned long sentenceTerminators = 0;
        unsigned long quotes = 0;

        __block unsigned long max = 0;
        __block unsigned long min = LONG_MAX;

        [paragraph[kLinesString] enumerateLinesUsingBlock:^(NSString *line, BOOL *stop)
        {

            [lineLengths addObject:[NSNumber numberWithUnsignedLong:line.length]];
            max = MAX(max, line.length);
            min = MIN(min, line.length);

            NSRange rangeOfFirstMatch = [indentRegularExpression
                                         rangeOfFirstMatchInString:line
                                         options:0
                                         range:NSMakeRange(0, [line length])];

            if(rangeOfFirstMatch.location == 0 && rangeOfFirstMatch.length != 0)
            {
                [indentedLines addObject:[NSNumber numberWithUnsignedLong:rangeOfFirstMatch.length]];
            }
            else
            {
                [indentedLines addObject:@0];
            }

            NSTextCheckingResult *match = [headersWithCounters firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];

            if(match)
            {
                [headerWithCounter addObject:[line substringWithRange:[match rangeAtIndex:1]]];
                [headerCounters addObject:[line substringWithRange:[match rangeAtIndex:2]]];
            }
            else
            {
                [headerWithCounter addObject:@""];
                [headerCounters addObject:@""];
            }

            match = [headersWithoutCounters firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];

            if(match)
            {
                [headers addObject:[line substringWithRange:[match rangeAtIndex:1]]];
            }
            else
            {
                [headers addObject:@""];
            }



        }];

        paragraph[kLineLengths] = lineLengths;
        paragraph[kLineIndented] = indentedLines;
        paragraph[kMaxLineLength] = [NSNumber numberWithUnsignedLong:max];
        paragraph[kMinLineLength] = [NSNumber numberWithUnsignedLong:min];
        paragraph[kNumberLines] = [NSNumber numberWithUnsignedLong:lineLengths.count];
        paragraph[kHeadersWithCounter] = headerWithCounter;
        paragraph[kHeaderCounters] = headerCounters;
        paragraph[kHeaders] = headers;

        for(NSString *tag in paragraph[kTags])
        {
            if(tag == NSLinguisticTagSentenceTerminator)
            {
                sentenceTerminators++;
            }
            if(tag == NSLinguisticTagOpenQuote || tag == NSLinguisticTagCloseQuote)
            {
                quotes++;
            }
        }
        paragraph[kSentenceTerminators] = [NSNumber numberWithUnsignedLong:sentenceTerminators];
        paragraph[kQuotes] = [NSNumber numberWithUnsignedInteger:quotes];

        unsigned int sum = 0;
        // Don't use the last line in calculations because it's shorter almost always
        for(int i = 0; i < lineLengths.count - 1; i++)
        {
            NSNumber *length = lineLengths[i];
            sum += [length unsignedLongValue];
        }
        paragraph[kAverageLineLength] = [NSNumber numberWithDouble:(double)sum/(double)(lineLengths.count - 1)];
    }

}

void analyzeLine(NSString *line)
{

}

void fixArticleParagraphs()
{
    for(NSString *paragraph in paragraphs)
    {

        [paragraph enumerateLinesUsingBlock:^(NSString *line, BOOL *stop)
        {
            NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

            NSRange rangeOfFirstMatch = [indentRegularExpression
                                         rangeOfFirstMatchInString:line
                                         options:0
                                         range:NSMakeRange(0, [line length])];

            if(rangeOfFirstMatch.location == 0 && rangeOfFirstMatch.length != 0)
            {
//                [indentedLines addObject:[NSNumber numberWithUnsignedLong:rangeOfFirstMatch.length]];
            }
            else
            {
//                [indentedLines addObject:@0];
            }


        }];

    }

}

void formatArticle()
{

}

void outputAricle()
{

}


int tag(NSMutableString *paragraph)
{
    __block int sentenceTerminators = 0;

    NSLinguisticTaggerOptions options = NSLinguisticTaggerJoinNames | NSLinguisticTaggerOmitWhitespace;

    NSArray *tagSchemes = [NSLinguisticTagger availableTagSchemesForLanguage:@"en"];

    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:tagSchemes options:options];

    tagger.string = paragraph;
    [tagger enumerateTagsInRange:NSMakeRange(0, [paragraph length])
                          scheme:NSLinguisticTagSchemeNameTypeOrLexicalClass
                         options:options
                      usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop)
     {
         NSString *token = [paragraph substringWithRange:tokenRange];
         if([tag isEqualToString:NSLinguisticTagSentenceTerminator])
         {
             sentenceTerminators++;
         }
     }];

    return sentenceTerminators;
}

int tagAndSaveData(NSMutableString *paragraph)
{
    __block int sentenceTerminators = 0;

    NSLinguisticTaggerOptions options = 0; // NSLinguisticTaggerOmitWhitespace;

    NSArray *tagSchemes = [NSLinguisticTagger availableTagSchemesForLanguage:@"en"];

    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:tagSchemes options:options];

    tagger.string = paragraph;

    NSArray *tokenRanges;
    NSArray *tags;
    tags = [tagger tagsInRange:NSMakeRange(0,[paragraph length])
                        scheme:NSLinguisticTagSchemeLexicalClass
                       options:options
                   tokenRanges:&tokenRanges];
    currentParagraph[kTags] = tags;
    NSMutableArray *rangesAsStrings = [[NSMutableArray alloc] init];
    for(NSValue *rangeObj in tokenRanges)
    {
        [rangesAsStrings addObject:NSStringFromRange([rangeObj rangeValue])];
    }
    currentParagraph[kTagRanges] = rangesAsStrings;


//    [tagger enumerateTagsInRange:NSMakeRange(0, [paragraph length])
//                          scheme:NSLinguisticTagSchemeNameTypeOrLexicalClass
//                         options:options
//                      usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop)
//     {
//         NSString *token = [paragraph substringWithRange:tokenRange];
//         if([tag isEqualToString:NSLinguisticTagSentenceTerminator])
//         {
//             sentenceTerminators++;
//         }
//     }];

    return sentenceTerminators;

}


//                 [header enumerateMatchesInString:paragraph
//                                          options:0
//                                            range:NSMakeRange(0, paragraph.length)
//                                       usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
//                  {
//                      if(sentenceTerminators == 0)
//                      {
//                          NSRange range1 = [result rangeAtIndex:1];
//                          NSRange range2 = [result rangeAtIndex:2];
//
//                          if(!NSEqualRanges(range1, NSMakeRange(NSNotFound, 0)))
//                          {
//                              NSLog(@"\tmatch1 = %@", [paragraph substringWithRange:range1]);
//                          }
//                          if(!NSEqualRanges(range2, NSMakeRange(NSNotFound, 0)))
//                          {
//                              NSLog(@"\tmatch2 = %@", [paragraph substringWithRange:range2]);
//                          }
//                      }
//                  }];

