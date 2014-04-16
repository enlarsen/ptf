//
//  PlainTextFile.m
//  ptf
//
//  Created by Erik Larsen on 3/26/14.
//  Copyright (c) 2014 Erik Larsen. All rights reserved.
//

#import "PlainTextFile.h"
#import "Paragraph.h"

@interface PlainTextFile()

@property (strong, nonatomic) NSString *fileText;
@property (strong, nonatomic) NSString *filename;

@end

@implementation PlainTextFile

- (NSMutableArray *)paragraphs
{
    if(!_paragraphs)
    {
        _paragraphs = [[NSMutableArray alloc] init];
    }
    return _paragraphs;
}

- (id)initWithFile:(NSString *)filePath
{
    self = [super init];
    if(self)
    {
        NSError *error = nil;
        NSStringEncoding encoding = 0;

        self.fileText = [NSString stringWithContentsOfFile:filePath
                                              usedEncoding:&encoding
                                                     error:&error];
        // Encoding 0x0000 means encoding can't be determined, so try again with Win 1252
        if(encoding == 0)
        {
            self.fileText = nil;
            error = nil;
            encoding = NSWindowsCP1252StringEncoding;
            self.fileText = [NSString stringWithContentsOfFile:filePath
                                                      encoding:encoding
                                                         error:&error];
        }
        _filename = [NSString stringWithString:[filePath lastPathComponent]];
    }
    return self;
    
}

- (void)addParagraphText:(NSString *)paragraphText
{
    Paragraph *paragraph = [[Paragraph alloc] initWithText:paragraphText];
    [self.paragraphs addObject:paragraph];
}

- (void)computeLineStatistics
{
    long maxLineLength = 0L;
    long n = 0L;
    double mean = 0.0;
    double delta = 0.0;
    double M2 = 0.0;
    long sum = 0L;
    long numberLines = 0L;


    for(Paragraph *paragraph in self.paragraphs)
    {
        NSMutableArray *lines = [NSMutableArray array];

        [paragraph.text enumerateLinesUsingBlock:^(NSString *line, BOOL *stop)
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
    self.stdDeviationLineLength = sqrt(M2/((double)n - 1));
    self.averageLineLength = (double)sum / (double)numberLines;


    // Set the short line value to three standard deviations away from the mean
    // TODO: move this to paragraph class because it's not needed here.
    self.shortLineLength = (long)round(((double)self.averageLineLength - (double)(3.0 * self.stdDeviationLineLength)));
    NSLog(@"Mean: %f, StDev: %f, ShortLineLength: %ld, %%: %f, File: %@",
          self.averageLineLength, self.stdDeviationLineLength, self.shortLineLength,
          self.stdDeviationLineLength/self.averageLineLength * 100.0, self.filename);
}

- (void)rewrap
{

}

// Start analyzing each paragraph to determine whether it's body, header, blockquote, etc.
- (void)analyzeParagraphs
{

    for(Paragraph *paragraph in self.paragraphs)
    {
        [paragraph detectWithAverageLineLength:self.averageLineLength
            standardDeviation:self.stdDeviationLineLength];
    }
}


// Create array of strings, one string per paragraph
- (void)convertToParagraphs
{
    NSMutableString *paragraphText = [[NSMutableString alloc] init];

    [self.fileText enumerateLinesUsingBlock:^(NSString *line, BOOL *stop)
     {
         NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

         if([trimmedLine isEqualToString:@""])
         {
             if(![paragraphText isEqualToString:@""])
             {
                 [self addParagraphText:paragraphText];


                 [paragraphText setString:@""];
             }
         }
         else
         {
             [paragraphText appendString:[line stringByAppendingString:@"\n"]];
         }
         
     }];
    // Pick up the last paragraph if the file doesn't end with a blank line.
    if(![paragraphText isEqualToString:@""])
    {
        [self addParagraphText:paragraphText];
    }

    return;
}



@end
