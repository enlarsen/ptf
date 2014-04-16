//
//  main.m
//  ptf

// Plain Text Formatter (ptf) attempts to reformat plain text
// files to html files with headers and real mdashes and
// smart quotes, etc.
//
//  Created by Erik Larsen on 4/2/14.
//  Copyright (c) 2014 Erik Larsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Paragraph.h"
#import "PlainTextFile.h"

void setupStyles(void);
void processDir(NSString *directory);
void process(NSString *path);

static NSMutableParagraphStyle *defaultParagraphStyle;
static NSMutableParagraphStyle *indentedParagraphStyle;
static NSMutableParagraphStyle *listParagraphStyle;
static NSMutableParagraphStyle *headerParagraphStyle;
static NSMutableParagraphStyle *subheaderParagraphStyle;
static NSMutableParagraphStyle *sceneSeparatorStyle;

static NSDictionary *italicAttributeDictionary;
static NSDictionary *boldAttributeDictionary;
static NSMutableDictionary *standardCharacterFormattingDictionary;
static NSMutableDictionary *headerCharacterFormattingDictionary;
static NSMutableDictionary *subheaderCharacterFormattingDictionary;

int main(int argc, const char * argv[])
{
    puts("Plain Text Formatter, ptf");
    if(argc != 2)
    {
        puts("ptf <directory>");
        puts("\tprocesses all .txt files in <directory> and creates .html files in a new subdirectory <html>");
        exit(1);
    }

    @autoreleasepool
    {
        setupStyles();
        processDir([NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding]);
    }
    return 0;
}

void setupStyles()
{
    defaultParagraphStyle = [NSMutableParagraphStyle new];
    indentedParagraphStyle = [NSMutableParagraphStyle new];
    listParagraphStyle = [NSMutableParagraphStyle new];
    headerParagraphStyle = [NSMutableParagraphStyle new];
    subheaderParagraphStyle = [NSMutableParagraphStyle new];
    sceneSeparatorStyle = [NSMutableParagraphStyle new];

//    italicAttributeDictionary = [NSMutableDictionary new];
//    boldAttributeDictionary = [NSMutableDictionary new];
//    standardCharacterFormattingDictionary = [NSMutableDictionary new];
//    headerCharacterFormattingDictionary = [NSMutableDictionary new];
    italicAttributeDictionary = [NSMutableDictionary new];
    boldAttributeDictionary = [NSMutableDictionary new];
    standardCharacterFormattingDictionary = [@{NSFontAttributeName: [NSFont fontWithName:@"Georgia" size:12.0]} copy];
    headerCharacterFormattingDictionary = [@{NSFontAttributeName: [NSFont fontWithName:@"Georgia" size:18.0]} copy];
    subheaderCharacterFormattingDictionary = [@{NSFontAttributeName: [NSFont fontWithName:@"Georgia" size:16.0]} copy];

    defaultParagraphStyle.headIndent = 0;
    defaultParagraphStyle.firstLineHeadIndent = 15;

    indentedParagraphStyle.headIndent = 15;
    indentedParagraphStyle.firstLineHeadIndent = 15;
    indentedParagraphStyle.paragraphSpacingBefore = 15;
    indentedParagraphStyle.tailIndent = 15;
    
    headerParagraphStyle.headerLevel = 2;
    headerParagraphStyle.paragraphSpacingBefore = 10;
    headerParagraphStyle.paragraphSpacing = 10;
    
    subheaderParagraphStyle.headerLevel = 3;

    sceneSeparatorStyle.alignment = NSCenterTextAlignment;

}

void processDir(NSString *directory)
{
    NSFileManager *localFileManager=[[NSFileManager alloc] init];
    NSDirectoryEnumerator *dirEnum =
        [localFileManager enumeratorAtPath:directory];


    NSString *file;
    while ((file = [dirEnum nextObject]))
    {
        [dirEnum skipDescendants];
        if ([[file pathExtension] isEqualToString: @"txt"]) {
            // process the document

            @autoreleasepool
            {
                process([directory stringByAppendingPathComponent:file]);
            }
            
        }
    }
    
}

void process(NSString *path)
{

    PlainTextFile *file = [[PlainTextFile alloc] initWithFile:path];
    NSMutableAttributedString *outputDocument = [[NSMutableAttributedString alloc] init];
    NSMutableDictionary *formattingDictionary;

    // TODO: merge these methods into one
    [file convertToParagraphs];
    [file computeLineStatistics];
    [file analyzeParagraphs];

    for(Paragraph *paragraph in file.paragraphs)
    {
        NSMutableParagraphStyle *paragraphStyle;

        switch(paragraph.kind)
        {
            case body:
                formattingDictionary = [standardCharacterFormattingDictionary mutableCopy];
                paragraphStyle = defaultParagraphStyle;
                break;

            case indentedBody:
                formattingDictionary = [standardCharacterFormattingDictionary mutableCopy];
                paragraphStyle = indentedParagraphStyle;
                break;

            case sceneSeparator:
                formattingDictionary = [standardCharacterFormattingDictionary mutableCopy];
                paragraphStyle = sceneSeparatorStyle;
                break;

            case header:
                formattingDictionary = [headerCharacterFormattingDictionary mutableCopy];
                paragraphStyle = headerParagraphStyle;
                break;

            case subheader:
                formattingDictionary = [subheaderCharacterFormattingDictionary mutableCopy];
                paragraphStyle = subheaderParagraphStyle;
                break;

            case dialog: // TODO: recognize dialog
                formattingDictionary = [standardCharacterFormattingDictionary mutableCopy];
                paragraphStyle = defaultParagraphStyle;
                break;

            case preserveBreaks:
                formattingDictionary = [standardCharacterFormattingDictionary mutableCopy];
                paragraphStyle = defaultParagraphStyle;
                break;

        }

        NSDictionary *attributes = @{NSParagraphStyleAttributeName: paragraphStyle};
        [formattingDictionary addEntriesFromDictionary:attributes];
        NSAttributedString *paragraphToAdd = [[NSAttributedString alloc]
                                              initWithString:paragraph.text
                                              attributes:formattingDictionary];
        [outputDocument appendAttributedString:paragraphToAdd];
    }

    NSDictionary *htmlAttributes = @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType};
    NSData *htmlData = [outputDocument dataFromRange:NSMakeRange(0, outputDocument.length)
                                  documentAttributes:htmlAttributes
                                               error:nil];
    NSString *htmlString = [[NSString alloc] initWithData:htmlData
                                                 encoding:NSUTF8StringEncoding];

    NSString *directory = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"html"];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];

    NSString *filename = [[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"html"];

    [htmlString writeToFile:[directory stringByAppendingPathComponent:filename]
                 atomically:YES encoding:NSUTF8StringEncoding
                      error:nil];
}
