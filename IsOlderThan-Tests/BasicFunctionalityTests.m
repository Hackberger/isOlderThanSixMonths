//
//  BasicFunctionalityTests.m
//  IsOlderThan
//
//  Created by Christian Kropfberger on 04.06.25.
//
//  BasicFunctionalityTests.m
//
//  isOlderThan Tests
//
//  Tests for basic functionality of the isOlderThan program
//  Covers argument parsing, validation, and core file age checking
//

#import <XCTest/XCTest.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <unistd.h>

// Include the main source file for testing
// In a real project, you would include header files instead
#include "../isOlderThan/isOlderThan.c"

@interface BasicFunctionalityTests : XCTestCase
@property (nonatomic, strong) NSString *testFilesDirectory;
@property (nonatomic, strong) NSString *currentTestFile;
@end

@implementation BasicFunctionalityTests

- (void)setUp {
    [super setUp];
    
    // Create test files directory
    NSString *tempDir = NSTemporaryDirectory();
    self.testFilesDirectory = [tempDir stringByAppendingPathComponent:@"isOlderThan_tests"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:self.testFilesDirectory
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
}

- (void)tearDown {
    // Clean up test files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:self.testFilesDirectory error:nil];
    
    if (self.currentTestFile) {
        [fileManager removeItemAtPath:self.currentTestFile error:nil];
    }
    
    [super tearDown];
}

#pragma mark - Test Utilities

- (NSString *)createTestFileWithAge:(NSTimeInterval)ageInSeconds {
    NSString *fileName = [NSString stringWithFormat:@"test_file_%f.txt", [[NSDate date] timeIntervalSince1970]];
    self.currentTestFile = [self.testFilesDirectory stringByAppendingPathComponent:fileName];
    
    // Create file with content
    [@"test content" writeToFile:self.currentTestFile
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:nil];
    
    // Set modification time
    NSDate *modificationDate = [NSDate dateWithTimeIntervalSinceNow:-ageInSeconds];
    NSDictionary *attributes = @{NSFileModificationDate: modificationDate};
    [[NSFileManager defaultManager] setAttributes:attributes
                                     ofItemAtPath:self.currentTestFile
                                            error:nil];
    
    return self.currentTestFile;
}

- (int)runIsOlderThanWithArguments:(NSArray<NSString *> *)arguments {
    // Convert NSArray to C-style argv
    int argc = (int)arguments.count;
    char **argv = malloc(argc * sizeof(char *));
    
    for (int i = 0; i < argc; i++) {
        NSString *arg = arguments[i];
        argv[i] = malloc(strlen([arg UTF8String]) + 1);
        strcpy(argv[i], [arg UTF8String]);
    }
    
    // Capture stdout and stderr for testing
    int stdout_backup = dup(STDOUT_FILENO);
    int stderr_backup = dup(STDERR_FILENO);
    
    // Redirect to /dev/null to suppress output during tests
    freopen("/dev/null", "w", stdout);
    freopen("/dev/null", "w", stderr);
    
    // Run the main function
    int result = main(argc, argv);
    
    // Restore stdout and stderr
    dup2(stdout_backup, STDOUT_FILENO);
    dup2(stderr_backup, STDERR_FILENO);
    close(stdout_backup);
    close(stderr_backup);
    
    // Clean up argv
    for (int i = 0; i < argc; i++) {
        free(argv[i]);
    }
    free(argv);
    
    return result;
}

#pragma mark - Argument Parsing Tests

- (void)testParseArgumentsBasic {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt"};
    int argc = 2;
    
    int result = parse_arguments(argc, argv, &args);
    
    XCTAssertEqual(result, SUCCESS, @"Should successfully parse basic arguments");
    XCTAssertTrue(strcmp(args.filepath, "/tmp/test.txt") == 0, @"Should parse filepath correctly");
    XCTAssertEqual(args.has_days, 0, @"Should not have days flag");
    XCTAssertEqual(args.exact_mode, 0, @"Should not have exact mode flag");
}

- (void)testParseArgumentsWithDays {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-days", "30"};
    int argc = 4;
    
    int result = parse_arguments(argc, argv, &args);
    
    XCTAssertEqual(result, SUCCESS, @"Should successfully parse arguments with days");
    XCTAssertEqual(args.days, 30, @"Should parse days value correctly");
    XCTAssertEqual(args.has_days, 1, @"Should have days flag set");
}

- (void)testParseArgumentsWithWeeks {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-weeks", "4"};
    int argc = 4;
    
    int result = parse_arguments(argc, argv, &args);
    
    XCTAssertEqual(result, SUCCESS, @"Should successfully parse arguments with weeks");
    XCTAssertEqual(args.weeks, 4, @"Should parse weeks value correctly");
    XCTAssertEqual(args.has_weeks, 1, @"Should have weeks flag set");
}

- (void)testParseArgumentsWithMonths {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-months", "6"};
    int argc = 4;
    
    int result = parse_arguments(argc, argv, &args);
    
    XCTAssertEqual(result, SUCCESS, @"Should successfully parse arguments with months");
    XCTAssertEqual(args.months, 6, @"Should parse months value correctly");
    XCTAssertEqual(args.has_months, 1, @"Should have months flag set");
}

- (void)testParseArgumentsWithYears {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-years", "2"};
    int argc = 4;
    
    int result = parse_arguments(argc, argv, &args);
    
    XCTAssertEqual(result, SUCCESS, @"Should successfully parse arguments with years");
    XCTAssertEqual(args.years, 2, @"Should parse years value correctly");
    XCTAssertEqual(args.has_years, 1, @"Should have years flag set");
}

- (void)testParseArgumentsWithMonthsAndYears {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-years", "1", "-months", "6"};
    int argc = 6;
    
    int result = parse_arguments(argc, argv, &args);
    
    XCTAssertEqual(result, SUCCESS, @"Should successfully parse months and years combination");
    XCTAssertEqual(args.years, 1, @"Should parse years value correctly");
    XCTAssertEqual(args.months, 6, @"Should parse months value correctly");
    XCTAssertEqual(args.has_years, 1, @"Should have years flag set");
    XCTAssertEqual(args.has_months, 1, @"Should have months flag set");
}

- (void)testParseArgumentsWithExactMode {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-days", "30", "-exact"};
    int argc = 5;
    
    int result = parse_arguments(argc, argv, &args);
    
    XCTAssertEqual(result, SUCCESS, @"Should successfully parse exact mode");
    XCTAssertEqual(args.exact_mode, 1, @"Should have exact mode flag set");
}

- (void)testParseArgumentsNoFilepath {
    arguments_t args;
    char *argv[] = {"isOlderThan"};
    int argc = 1;
    
    int result = parse_arguments(argc, argv, &args);
    
    XCTAssertEqual(result, ERROR_INVALID_ARGS, @"Should return error when no filepath provided");
}

- (void)testParseArgumentsInvalidParameter {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-invalid"};
    int argc = 3;
    
    int result = parse_arguments(argc, argv, &args);
    
    XCTAssertEqual(result, ERROR_INVALID_ARGS, @"Should return error for invalid parameter");
}

- (void)testParseArgumentsMissingValue {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-days"};
    int argc = 3;
    
    int result = parse_arguments(argc, argv, &args);
    
    XCTAssertEqual(result, ERROR_INVALID_ARGS, @"Should return error when value missing for -days");
}

- (void)testParseArgumentsNegativeValue {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-days", "-5"};
    int argc = 4;
    
    int result = parse_arguments(argc, argv, &args);
    
    XCTAssertEqual(result, ERROR_INVALID_VALUE, @"Should return error for negative values");
}

#pragma mark - Argument Validation Tests

- (void)testValidateArgumentsBasic {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    args.days = 30;
    args.has_days = 1;
    
    int result = validate_arguments(&args);
    
    XCTAssertEqual(result, SUCCESS, @"Should validate basic arguments successfully");
}

- (void)testValidateArgumentsDaysExcludesOthers {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    args.days = 30;
    args.has_days = 1;
    args.weeks = 2;
    args.has_weeks = 1;
    
    int result = validate_arguments(&args);
    
    XCTAssertEqual(result, ERROR_INVALID_COMBINATION, @"Should reject days combined with weeks");
}

- (void)testValidateArgumentsWeeksExcludesOthers {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    args.weeks = 2;
    args.has_weeks = 1;
    args.months = 6;
    args.has_months = 1;
    
    int result = validate_arguments(&args);
    
    XCTAssertEqual(result, ERROR_INVALID_COMBINATION, @"Should reject weeks combined with months");
}

- (void)testValidateArgumentsMonthsWithYearsValid {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    args.months = 6;
    args.has_months = 1;
    args.years = 2;
    args.has_years = 1;
    
    int result = validate_arguments(&args);
    
    XCTAssertEqual(result, SUCCESS, @"Should accept valid months and years combination");
}

- (void)testValidateArgumentsMonthsWithYearsInvalid {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    args.months = 15;  // Invalid: > 11 when combined with years
    args.has_months = 1;
    args.years = 2;
    args.has_years = 1;
    
    int result = validate_arguments(&args);
    
    XCTAssertEqual(result, ERROR_INVALID_COMBINATION, @"Should reject months > 11 when combined with years");
}

#pragma mark - File Age Checking Tests

- (void)testFileOlderThanDefault {
    // Create file that is 7 months old (older than default 6 months)
    NSString *testFile = [self createTestFileWithAge:(7 * 30 * 24 * 60 * 60)]; // ~7 months
    
    NSArray *arguments = @[@"isOlderThan", testFile];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    XCTAssertEqual(result, SUCCESS, @"File older than 6 months should return SUCCESS");
}

- (void)testFileNewerThanDefault {
    // Create file that is 3 months old (newer than default 6 months)
    NSString *testFile = [self createTestFileWithAge:(3 * 30 * 24 * 60 * 60)]; // ~3 months
    
    NSArray *arguments = @[@"isOlderThan", testFile];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    XCTAssertEqual(result, ERROR_INVALID_ARGS, @"File newer than 6 months should return ERROR_INVALID_ARGS");
}

- (void)testFileOlderThanSpecifiedDays {
    // Create file that is 35 days old
    NSString *testFile = [self createTestFileWithAge:(35 * 24 * 60 * 60)];
    
    NSArray *arguments = @[@"isOlderThan", testFile, @"-days", @"30"];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    XCTAssertEqual(result, SUCCESS, @"File older than 30 days should return SUCCESS");
}

- (void)testFileNewerThanSpecifiedDays {
    // Create file that is 25 days old
    NSString *testFile = [self createTestFileWithAge:(25 * 24 * 60 * 60)];
    
    NSArray *arguments = @[@"isOlderThan", testFile, @"-days", @"30"];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    XCTAssertEqual(result, ERROR_INVALID_ARGS, @"File newer than 30 days should return ERROR_INVALID_ARGS");
}

- (void)testFileOlderThanSpecifiedWeeks {
    // Create file that is 5 weeks old
    NSString *testFile = [self createTestFileWithAge:(5 * 7 * 24 * 60 * 60)];
    
    NSArray *arguments = @[@"isOlderThan", testFile, @"-weeks", @"4"];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    XCTAssertEqual(result, SUCCESS, @"File older than 4 weeks should return SUCCESS");
}

- (void)testFileWithExactMode {
    // Create file that is very recent (1 second old)
    NSString *testFile = [self createTestFileWithAge:1];
    
    NSArray *arguments = @[@"isOlderThan", testFile, @"-days", @"1", @"-exact"];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    XCTAssertEqual(result, ERROR_INVALID_ARGS, @"Recent file should not be older than 1 day in exact mode");
}

#pragma mark - Error Handling Tests

- (void)testFileNotFound {
    NSArray *arguments = @[@"isOlderThan", @"/nonexistent/file.txt"];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    XCTAssertEqual(result, ERROR_FILE_NOT_FOUND, @"Nonexistent file should return ERROR_FILE_NOT_FOUND");
}

- (void)testInvalidParameterCombination {
    NSString *testFile = [self createTestFileWithAge:86400]; // 1 day old
    
    NSArray *arguments = @[@"isOlderThan", testFile, @"-days", @"30", @"-weeks", @"4"];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    XCTAssertEqual(result, ERROR_INVALID_COMBINATION, @"Invalid parameter combination should return ERROR_INVALID_COMBINATION");
}

@end
