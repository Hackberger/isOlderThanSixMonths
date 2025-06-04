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

// Include the header file instead of the implementation
#include "isOlderThan.h"

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
    
    // LÖSUNG 1: Verwende const char** statt char** (wenn möglich)
    const char **argv_const = malloc(argc * sizeof(const char *));
    char **argv = malloc(argc * sizeof(char *));
    
    for (int i = 0; i < argc; i++) {
        NSString *arg = arguments[i];
        // Direkte Zuweisung zu const char* - kein Warning
        argv_const[i] = [arg UTF8String];
        // Dann kopieren für modifiable version
        size_t len = strlen(argv_const[i]);
        argv[i] = malloc(len + 1);
        strcpy(argv[i], argv_const[i]);
    }
    
    // Capture stdout and stderr for testing
    int stdout_backup = dup(STDOUT_FILENO);
    int stderr_backup = dup(STDERR_FILENO);
    
    // Redirect to /dev/null to suppress output during tests
    freopen("/dev/null", "w", stdout);
    freopen("/dev/null", "w", stderr);
    
    // Call the main function
    int result = isOlderThan_main(argc, argv);
    
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
    free(argv_const);
    
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

#pragma mark - File Time Tests

- (void)testGetFileModificationTime {
    // Create a test file
    NSString *testFile = [self createTestFileWithAge:0];
    
    time_t file_time = get_file_modification_time([testFile UTF8String]);
    
    XCTAssertGreaterThan(file_time, 0, @"Should get valid file modification time");
    
    // Test with non-existent file
    time_t invalid_time = get_file_modification_time("/nonexistent/file.txt");
    XCTAssertEqual(invalid_time, -1, @"Should return -1 for non-existent file");
}

#pragma mark - Calendar Tests

- (void)testIsLeapYear {
    XCTAssertTrue(is_leap_year(2020), @"2020 should be a leap year");
    XCTAssertTrue(is_leap_year(2000), @"2000 should be a leap year");
    XCTAssertFalse(is_leap_year(1900), @"1900 should not be a leap year");
    XCTAssertFalse(is_leap_year(2021), @"2021 should not be a leap year");
}

- (void)testGetDaysInMonth {
    XCTAssertEqual(get_days_in_month(1, 2023), 31, @"January should have 31 days");
    XCTAssertEqual(get_days_in_month(2, 2023), 28, @"February 2023 should have 28 days");
    XCTAssertEqual(get_days_in_month(2, 2020), 29, @"February 2020 should have 29 days");
    XCTAssertEqual(get_days_in_month(4, 2023), 30, @"April should have 30 days");
    XCTAssertEqual(get_days_in_month(0, 2023), 0, @"Invalid month should return 0");
    XCTAssertEqual(get_days_in_month(13, 2023), 0, @"Invalid month should return 0");
}

- (void)testCalculateReferenceTime {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    args.days = 30;
    args.has_days = 1;
    
    time_t reference_time = calculate_reference_time(&args);
    time_t current_time;
    time(&current_time);
    
    double diff_seconds = difftime(current_time, reference_time);
    double diff_days = diff_seconds / (24 * 60 * 60);
    
    // Should be approximately 30 days (allow ±1 day for calculation variance)
    XCTAssertTrue(diff_days >= 29 && diff_days <= 31,
                  @"Reference time should be approximately 30 days ago, got %.1f days", diff_days);
}

- (void)testErrorMessages {
    const char *msg1 = get_error_message(SUCCESS);
    XCTAssertTrue(strlen(msg1) > 0, @"Success message should not be empty");
    
    const char *msg2 = get_error_message(ERROR_FILE_NOT_FOUND);
    XCTAssertTrue(strlen(msg2) > 0, @"File not found message should not be empty");
    
    const char *msg3 = get_error_message(999); // Invalid error code
    XCTAssertTrue(strlen(msg3) > 0, @"Should handle invalid error codes gracefully");
}

#pragma mark - Integration Tests (Limited without full main function access)

- (void)testFileAgeCheckingComponents {
    // Since we can't easily test the full main function in this setup,
    // we test the individual components that make up the file age checking logic
    
    NSString *testFile = [self createTestFileWithAge:(48 * 60 * 60)]; // 2 days old
    
    // Test getting file time
    time_t file_time = get_file_modification_time([testFile UTF8String]);
    XCTAssertGreaterThan(file_time, 0, @"Should get valid file time");
    
    // Test calculating reference time for 1 day
    arguments_t args = {0};
    args.filepath = [testFile UTF8String];
    args.days = 1;
    args.has_days = 1;
    
    time_t reference_time = calculate_reference_time(&args);
    
    // File should be older than reference time (2 days old vs 1 day threshold)
    XCTAssertLessThan(file_time, reference_time, @"2-day-old file should be older than 1-day reference");
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

@end
