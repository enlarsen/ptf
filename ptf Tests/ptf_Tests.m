//
//  HeaderStructure_Tests.m
//  HeaderStructure Tests
//
//  Created by Erik Larsen on 3/29/14.
//  Copyright (c) 2014 Erik Larsen. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Paragraph.h"

@interface HeaderStructure_Tests : XCTestCase

@end

@implementation HeaderStructure_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testAllUppercase
{
    Paragraph *paragraph = [[Paragraph alloc] initWithText:@"ALL UPPERCASE"];
    [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
    XCTAssertTrue(paragraph.isAllUppercase);

    paragraph = [[Paragraph alloc] initWithText:@"not even close to uppercase"];
    [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
    XCTAssertFalse(paragraph.isAllUppercase);

    paragraph = [[Paragraph alloc] initWithText:@"ALMOSt UPPERCASE"];
    [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
    XCTAssertFalse(paragraph.isAllUppercase);

    paragraph = [[Paragraph alloc] initWithText:@"12345678-56-99: 343"];
    [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
    XCTAssertFalse(paragraph.isAllUppercase);

    // Another "special" case: when there aren't very many letters vs non letters.
    // To humans, that doesn't look like it's uppercase.

}

- (void)testIndented
{
    Paragraph *paragraph = [[Paragraph alloc] initWithText:@"    hi"];
    [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
    XCTAssertTrue(paragraph.isIndented);

    paragraph = [[Paragraph alloc] initWithText:@"not indented"];
    [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
    XCTAssertFalse(paragraph.isIndented);

    paragraph = [[Paragraph alloc] initWithText:@"\t\tIndented with tabs"];
    [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
    XCTAssertTrue(paragraph.isIndented);
}

- (void)testSceneSeparator
{
    NSArray *sceneSeparators = @[@" ***", @"* * *", @"------", @"*", @" ======"];
    NSArray *notSceneSeparators = @[@"*italics*", @"a dash--is here"];

    for(NSString *separator in sceneSeparators)
    {
        Paragraph *paragraph = [[Paragraph alloc] initWithText:separator];
        [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
        XCTAssertTrue(paragraph.kind == sceneSeparator);
    }

    for(NSString *separator in notSceneSeparators)
    {
        Paragraph *paragraph = [[Paragraph alloc] initWithText:separator];
        [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
        XCTAssertFalse(paragraph.kind == sceneSeparator);
    }
}

- (void)testHeader
{
    NSArray *headers = @[@" Chapter 1", @"Volume 8", @"APPENDIX",
                         @"Epilog", @" Part 4", @"Chapter 8: Learning to swim."];
    NSArray *notHeaders = @[@"Please see chapter 4",
                            @"Some body text\nSome more body text.",
                            @"chapter is an important thing.\nYes it is."];

    for(NSString *separator in headers)
    {
        Paragraph *paragraph = [[Paragraph alloc] initWithText:separator];
        [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
        XCTAssertTrue(paragraph.kind == header);
    }

    for(NSString *separator in notHeaders)
    {
        Paragraph *paragraph = [[Paragraph alloc] initWithText:separator];
        [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
        XCTAssertFalse(paragraph.kind == header);
    }
}

- (void)testSubheader
{
    NSArray *subheaders = @[@" Sunday, January 4\n", @"       IX", @" Tuesday\n"
                         ];
    NSArray *notSubheaders = @[@"Volume 8",
                               @"Epilog", @" Part 4", @"Chapter 8: Learning to swim.",
                            @"Some body text\nSome more body text.",
                            @"chapter is an important thing.\nYes it is.", @"  ***"];

    for(NSString *separator in subheaders)
    {
        Paragraph *paragraph = [[Paragraph alloc] initWithText:separator];
        [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
        XCTAssertTrue(paragraph.kind == subheader);
    }

    for(NSString *separator in notSubheaders)
    {
        Paragraph *paragraph = [[Paragraph alloc] initWithText:separator];
        [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
        XCTAssertFalse(paragraph.kind == subheader);
    }
}

- (void)testSmartQuotes
{
    Paragraph *paragraph = [[Paragraph alloc] initWithText:@"I saw Bob's hat."];
    [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
    // TODO: test me
}

- (void)testEllipsisDots
{
    Paragraph *paragraph = [[Paragraph alloc] initWithText:@"I ... don't know."];
    [paragraph detectWithAverageLineLength:80.0 standardDeviation:3.0];
    // TODO: test me
}

@end
