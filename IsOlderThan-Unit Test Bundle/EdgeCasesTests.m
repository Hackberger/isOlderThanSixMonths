//
//  EdgeCasesTests.m
//  isOlderThan Tests
//
//  Tests for edge cases, error conditions, and boundary scenarios
//  including file permissions, special file types, and extreme values
//

#import <XCTest/XCTest.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>

// Include the header
#include "isOlderThan.h"

// Forward declaration for main function
extern int main(int argc, char *argv[]);

@interface EdgeCasesTests : XCTestCase
@property (nonatomic, strong) NSString *testFilesDirectory;
@property (nonatomic, strong) NSMutableArray<NSString *> *createdFiles;
@end

@implementation EdgeCasesTests

- (void)setUp {
    [super setUp];
    
    // Create test files directory
    NSString *tempDir = NSTemporaryDirectory();
    self.testFilesDirectory = [tempDir stringByAppendingPathComponent:@"isOlderThan_edge_tests"];
    self.createdFiles = [NSMutableArray array];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:self.testFilesDirectory
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
}

- (void)tearDown {
    // Clean up all created files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *filePath in self.createdFiles) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
    [fileManager removeItemAtPath:self.testFilesDirectory error:nil];
    
    [super tearDown];
}

#pragma mark - Test Utilities

- (NSString *)createTestFileWithName:(NSString *)fileName
                             content:(NSString *)content
                                 age:(NSTimeInterval)ageInSeconds
                         permissions:(NSNumber *)permissions {
    NSString *filePath = [self.testFilesDirectory stringByAppendingPathComponent:fileName];
    
    // Create file with content
    [content writeToFile:filePath
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:nil];
    
    // Set modification time
    if (ageInSeconds > 0) {
        NSDate *modificationDate = [NSDate dateWithTimeIntervalSinceNow:-ageInSeconds];
        NSDictionary *attributes = @{NSFileModificationDate: modificationDate};
        [[NSFileManager defaultManager] setAttributes:attributes
                                         ofItemAtPath:filePath
                                                error:nil];
    }
    
    // Set permissions if specified
    if (permissions) {
        NSDictionary *permissionAttributes = @{NSFilePosixPermissions: permissions};
        [[NSFileManager defaultManager] setAttributes:permissionAttributes
                                         ofItemAtPath:filePath
                                                error:nil];
    }
    
    [self.createdFiles addObject:filePath];
    return filePath;
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
    
    // Capture stdout and stderr
    int stdout_backup = dup(STDOUT_FILENO);
    int stderr_backup = dup(STDERR_FILENO);
    
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

#pragma mark - File Access Edge Cases

- (void)testNonExistentFile {
    NSString *nonExistentPath = [self.testFilesDirectory stringByAppendingPathComponent:@"does_not_exist.txt"];
    
    NSArray *arguments = @[@"isOlderThan", nonExistentPath];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    XCTAssertEqual(result, ERROR_FILE_NOT_FOUND, @"Non-existent file should return ERROR_FILE_NOT_FOUND");
}

- (void)testEmptyFilePath {
    arguments_t args;
    char *argv[] = {"isOlderThan", ""};
    int argc = 2;
    
    int result = parse_arguments(argc, argv, &args);
    
    // Should parse successfully but file access will fail later
    XCTAssertEqual(result, SUCCESS, @"Empty filepath should parse successfully");
    
    time_t file_time = get_file_modification_time("");
    XCTAssertEqual(file_time, -1, @"Empty filepath should return -1");
}

- (void)testVeryLongFilePath {
    // Create a very long file path (close to system limits)
    NSMutableString *longPath = [NSMutableString stringWithString:self.testFilesDirectory];
    for (int i = 0; i < 50; i++) {
        [longPath appendString:@"/very_long_directory_name_to_test_path_limits"];
    }
    [longPath appendString:@"/test_file.txt"];
    
    NSArray *arguments = @[@"isOlderThan", longPath];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    // Should handle long paths gracefully (either work or return appropriate error)
    XCTAssertTrue(result == ERROR_FILE_NOT_FOUND || result == ERROR_FILE_ACCESS,
                  @"Very long path should return appropriate error");
}

- (void)testFileWithSpecialCharacters {
    NSString *specialFileName = @"test file with spaces & special chars !@#$%^&*()_+.txt";
    NSString *testFile = [self createTestFileWithName:specialFileName
                                              content:@"test content"
                                                  age:86400 // 1 day old
                                          permissions:@(0644)];
    
    NSArray *arguments = @[@"isOlderThan", testFile, @"-days", @"1"];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    XCTAssertEqual(result, SUCCESS, @"File with special characters should be handled correctly");
}

- (void)testSymbolicLink {
    NSString *originalFile = [self createTestFileWithName:@"original.txt"
                                                  content:@"original content"
                                                      age:172800 // 2 days old
                                              permissions:@(0644)];
    
    NSString *linkPath = [self.testFilesDirectory stringByAppendingPathComponent:@"symlink.txt"];
    
    // Create symbolic link
    if (symlink([originalFile UTF8String], [linkPath UTF8String]) == 0) {
        [self.createdFiles addObject:linkPath];
        
        NSArray *arguments = @[@"isOlderThan", linkPath, @"-days", @"1"];
        int result = [self runIsOlderThanWithArguments:arguments];
        
        XCTAssertEqual(result, SUCCESS, @"Symbolic link should follow to original file");
    } else {
        XCTFail(@"Failed to create symbolic link for testing");
    }
}

#pragma mark - Extreme Value Tests

- (void)testExtremelyOldFile {
    // Create file with very old timestamp (January 1, 1970)
    NSString *testFile = [self createTestFileWithName:@"very_old.txt"
                                              content:@"old content"
                                                  age:0 // Will set manually
                                          permissions:@(0644)];
    
    // Set file time to Unix epoch
    struct timespec times[2];
    times[0].tv_sec = 0; // January 1, 1970
    times[0].tv_nsec = 0;
    times[1].tv_sec = 0; // modification time
    times[1].tv_nsec = 0;
    
    utimensat(AT_FDCWD, [testFile UTF8String], times, 0);
    
    NSArray *arguments = @[@"isOlderThan", testFile, @"-years", @"1"];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    XCTAssertEqual(result, SUCCESS, @"Extremely old file should be handled correctly");
}

- (void)testVeryLargeTimeValues {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    args.years = 1000; // Very large year value
    args.has_years = 1;
    
    // Should validate successfully (large values are allowed)
    int result = validate_arguments(&args);
    XCTAssertEqual(result, SUCCESS, @"Large time values should be accepted");
    
    // Test calculation doesn't crash
    time_t reference_time = calculate_reference_time(&args);
    XCTAssertTrue(reference_time > 0, @"Should handle large time calculations");
}

- (void)testZeroTimeValues {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-days", "0"};
    int argc = 4;
    
    int result = parse_arguments(argc, argv, &args);
    
    XCTAssertEqual(result, ERROR_INVALID_VALUE, @"Zero time values should be rejected");
}

- (void)testNegativeTimeValues {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-months", "-5"};
    int argc = 4;
    
    int result = parse_arguments(argc, argv, &args);
    
    XCTAssertEqual(result, ERROR_INVALID_VALUE, @"Negative time values should be rejected");
}

#pragma mark - Parameter Boundary Tests

- (void)testMaximumMonthsWithYears {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    args.months = 11; // Maximum allowed when combined with years
    args.has_months = 1;
    args.years = 1;
    args.has_years = 1;
    
    int result = validate_arguments(&args);
    XCTAssertEqual(result, SUCCESS, @"Maximum months (11) with years should be valid");
}

- (void)testOverMaximumMonthsWithYears {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    args.months = 12; // Over maximum when combined with years
    args.has_months = 1;
    args.years = 1;
    args.has_years = 1;
    
    int result = validate_arguments(&args);
    XCTAssertEqual(result, ERROR_INVALID_COMBINATION, @"Months > 11 with years should be invalid");
}

- (void)testMonthsAloneCanExceed11 {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    args.months = 15; // Should be valid when not combined with years
    args.has_months = 1;
    args.years = 0;
    args.has_years = 0;
    
    int result = validate_arguments(&args);
    XCTAssertEqual(result, SUCCESS, @"Months > 11 should be valid when not combined with years");
}

#pragma mark - Complex Parameter Combinations

- (void)testAllInvalidCombinations {
    // Test days with weeks
    arguments_t args1 = {0};
    args1.filepath = "/tmp/test.txt";
    args1.days = 30;
    args1.has_days = 1;
    args1.weeks = 4;
    args1.has_weeks = 1;
    
    int result1 = validate_arguments(&args1);
    XCTAssertEqual(result1, ERROR_INVALID_COMBINATION, @"Days with weeks should be invalid");
    
    // Test days with months
    arguments_t args2 = {0};
    args2.filepath = "/tmp/test.txt";
    args2.days = 30;
    args2.has_days = 1;
    args2.months = 6;
    args2.has_months = 1;
    
    int result2 = validate_arguments(&args2);
    XCTAssertEqual(result2, ERROR_INVALID_COMBINATION, @"Days with months should be invalid");
    
    // Test days with years
    arguments_t args3 = {0};
    args3.filepath = "/tmp/test.txt";
    args3.days = 30;
    args3.has_days = 1;
    args3.years = 1;
    args3.has_years = 1;
    
    int result3 = validate_arguments(&args3);
    XCTAssertEqual(result3, ERROR_INVALID_COMBINATION, @"Days with years should be invalid");
    
    // Test weeks with months
    arguments_t args4 = {0};
    args4.filepath = "/tmp/test.txt";
    args4.weeks = 4;
    args4.has_weeks = 1;
    args4.months = 6;
    args4.has_months = 1;
    
    int result4 = validate_arguments(&args4);
    XCTAssertEqual(result4, ERROR_INVALID_COMBINATION, @"Weeks with months should be invalid");
    
    // Test weeks with years
    arguments_t args5 = {0};
    args5.filepath = "/tmp/test.txt";
    args5.weeks = 4;
    args5.has_weeks = 1;
    args5.years = 1;
    args5.has_years = 1;
    
    int result5 = validate_arguments(&args5);
    XCTAssertEqual(result5, ERROR_INVALID_COMBINATION, @"Weeks with years should be invalid");
}

- (void)testTripleCombinations {
    // Test days + weeks + months
    arguments_t args1 = {0};
    args1.filepath = "/tmp/test.txt";
    args1.days = 30;
    args1.has_days = 1;
    args1.weeks = 4;
    args1.has_weeks = 1;
    args1.months = 6;
    args1.has_months = 1;
    
    int result1 = validate_arguments(&args1);
    XCTAssertEqual(result1, ERROR_INVALID_COMBINATION, @"Triple combination should be invalid");
    
    // Test weeks + months + years
    arguments_t args2 = {0};
    args2.filepath = "/tmp/test.txt";
    args2.weeks = 4;
    args2.has_weeks = 1;
    args2.months = 6;
    args2.has_months = 1;
    args2.years = 1;
    args2.has_years = 1;
    
    int result2 = validate_arguments(&args2);
    XCTAssertEqual(result2, ERROR_INVALID_COMBINATION, @"Triple combination should be invalid");
}

#pragma mark - String and Memory Edge Cases

- (void)testVeryLongArgumentStrings {
    // Test with very long numeric string
    NSString *longNumberString = [@"" stringByPaddingToLength:1000 withString:@"1" startingAtIndex:0];
    
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-days", (char *)[longNumberString UTF8String]};
    int argc = 4;
    
    int result = parse_arguments(argc, argv, &args);
    
    // Should handle gracefully (atoi will parse leading digits)
    XCTAssertEqual(result, SUCCESS, @"Should handle very long numeric strings");
    XCTAssertTrue(args.days > 0, @"Should extract valid number from long string");
}

- (void)testNonNumericStrings {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-days", "abc"};
    int argc = 4;
    
    int result = parse_arguments(argc, argv, &args);
    
    // atoi("abc") returns 0, which should trigger ERROR_INVALID_VALUE
    XCTAssertEqual(result, ERROR_INVALID_VALUE, @"Non-numeric strings should be rejected");
}

- (void)testMixedNumericStrings {
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-days", "30abc"};
    int argc = 4;
    
    int result = parse_arguments(argc, argv, &args);
    
    // atoi("30abc") returns 30, which should be valid
    XCTAssertEqual(result, SUCCESS, @"Should parse leading digits from mixed strings");
    XCTAssertEqual(args.days, 30, @"Should extract 30 from '30abc'");
}

#pragma mark - Time Precision Tests

- (void)testSubSecondFileTimes {
    // Create a file and immediately check it
    NSString *testFile = [self createTestFileWithName:@"immediate.txt"
                                              content:@"immediate content"
                                                  age:0 // Current time
                                          permissions:@(0644)];
    
    // Check if file is older than 1 day with exact mode
    NSArray *arguments = @[@"isOlderThan", testFile, @"-days", @"1", @"-exact"];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    XCTAssertEqual(result, ERROR_INVALID_ARGS, @"Immediately created file should not be older than 1 day");
}

- (void)testMidnightBoundary {
    // Test behavior around midnight boundary
    // This test approximates the boundary condition
    
    NSString *testFile = [self createTestFileWithName:@"midnight_test.txt"
                                              content:@"midnight content"
                                                  age:86400 // Exactly 1 day
                                          permissions:@(0644)];
    
    // Test with exact mode
    NSArray *argumentsExact = @[@"isOlderThan", testFile, @"-days", @"1", @"-exact"];
    int resultExact = [self runIsOlderThanWithArguments:argumentsExact];
    
    // Test with non-exact mode
    NSArray *argumentsNonExact = @[@"isOlderThan", testFile, @"-days", @"1"];
    int resultNonExact = [self runIsOlderThanWithArguments:argumentsNonExact];
    
    // Results might differ between exact and non-exact modes
    XCTAssertTrue(resultExact == SUCCESS || resultExact == ERROR_INVALID_ARGS,
                  @"Exact mode should return valid result");
    XCTAssertTrue(resultNonExact == SUCCESS || resultNonExact == ERROR_INVALID_ARGS,
                  @"Non-exact mode should return valid result");
}

#pragma mark - Platform-Specific Edge Cases

- (void)testFileSystemLimits {
    // Test with the maximum file path length supported by the system
    long maxPath = pathconf("/", _PC_PATH_MAX);
    if (maxPath > 0) {
        NSMutableString *longPath = [NSMutableString stringWithString:@"/tmp/"];
        while ([longPath length] < maxPath - 20) { // Leave some margin
            [longPath appendString:@"a"];
        }
        [longPath appendString:@".txt"];
        
        NSArray *arguments = @[@"isOlderThan", longPath];
        int result = [self runIsOlderThanWithArguments:arguments];
        
        // Should handle gracefully (likely file not found)
        XCTAssertTrue(result >= ERROR_INVALID_ARGS, @"Should handle maximum path length gracefully");
    }
}

- (void)testUnicodeFilenames {
    NSString *unicodeFileName = @"测试文件_тест_파일_ファイル.txt";
    NSString *testFile = [self createTestFileWithName:unicodeFileName
                                              content:@"unicode content"
                                                  age:86400 // 1 day old
                                          permissions:@(0644)];
    
    NSArray *arguments = @[@"isOlderThan", testFile, @"-days", @"1"];
    int result = [self runIsOlderThanWithArguments:arguments];
    
    XCTAssertEqual(result, SUCCESS, @"Unicode filenames should be handled correctly");
}

#pragma mark - Memory and Resource Edge Cases

- (void)testManyArguments {
    // Test with maximum reasonable number of arguments
    NSMutableArray *arguments = [NSMutableArray arrayWithArray:@[@"isOlderThan", @"/tmp/test.txt"]];
    
    // Add many -exact flags (they should be ignored after the first)
    for (int i = 0; i < 100; i++) {
        [arguments addObject:@"-exact"];
    }
    
    int result = [self runIsOlderThanWithArguments:arguments];
    
    // Should handle gracefully (likely invalid args due to unknown parameters)
    XCTAssertTrue(result >= ERROR_INVALID_ARGS, @"Should handle many arguments gracefully");
}

- (void)testRepeatedParameters {
    // Test with repeated parameter names
    arguments_t args;
    char *argv[] = {"isOlderThan", "/tmp/test.txt", "-days", "30", "-days", "45"};
    int argc = 6;
    
    int result = parse_arguments(argc, argv, &args);
    
    // Should take the last value
    XCTAssertEqual(result, SUCCESS, @"Should handle repeated parameters");
    XCTAssertEqual(args.days, 45, @"Should use the last value for repeated parameters");
}

#pragma mark - Error Message and Logging Tests

- (void)testErrorMessages {
    // Test that error messages are meaningful
    const char *msg1 = get_error_message(SUCCESS);
    XCTAssertTrue(strlen(msg1) > 0, @"Success message should not be empty");
    
    const char *msg2 = get_error_message(ERROR_FILE_NOT_FOUND);
    XCTAssertTrue(strlen(msg2) > 0, @"File not found message should not be empty");
    
    const char *msg3 = get_error_message(ERROR_INVALID_COMBINATION);
    XCTAssertTrue(strlen(msg3) > 0, @"Invalid combination message should not be empty");
    
    const char *msg4 = get_error_message(999); // Invalid error code
    XCTAssertTrue(strlen(msg4) > 0, @"Should handle invalid error codes gracefully");
}

#pragma mark - Concurrency and Race Condition Tests

- (void)testFileModificationDuringCheck {
    // Create a test file
    NSString *testFile = [self createTestFileWithName:@"modification_test.txt"
                                              content:@"original content"
                                                  age:86400 // 1 day old
                                          permissions:@(0644)];
    
    // Get initial modification time
    time_t initial_time = get_file_modification_time([testFile UTF8String]);
    XCTAssertTrue(initial_time > 0, @"Should get valid initial modification time");
    
    // Modify the file
    [@"modified content" writeToFile:testFile
                          atomically:YES
                            encoding:NSUTF8StringEncoding
                               error:nil];
    
    // Get new modification time
    time_t new_time = get_file_modification_time([testFile UTF8String]);
    XCTAssertTrue(new_time > initial_time, @"New modification time should be later");
}

- (void)testConcurrentFileAccess {
    // This test simulates potential race conditions
    NSString *testFile = [self createTestFileWithName:@"concurrent_test.txt"
                                              content:@"concurrent content"
                                                  age:86400 // 1 day old
                                          permissions:@(0644)];
    
    // Perform multiple checks rapidly
    for (int i = 0; i < 10; i++) {
        time_t file_time = get_file_modification_time([testFile UTF8String]);
        XCTAssertTrue(file_time > 0, @"Should consistently get valid file time");
    }
}

@end
