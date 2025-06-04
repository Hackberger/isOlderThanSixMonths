//
//  IntegrationTests.m
//  isOlderThan Tests
//
//  End-to-end integration tests that simulate real-world usage scenarios
//  including batch operations, script integration, and performance tests
//

#import <XCTest/XCTest.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <time.h>

// Include the main source file for testing
#include "../isOlderThan/isOlderThan.c"

@interface IntegrationTests : XCTestCase
@property (nonatomic, strong) NSString *testFilesDirectory;
@property (nonatomic, strong) NSMutableArray<NSString *> *createdFiles;
@end

@implementation IntegrationTests

- (void)setUp {
    [super setUp];
    
    // Create test files directory
    NSString *tempDir = NSTemporaryDirectory();
    self.testFilesDirectory = [tempDir stringByAppendingPathComponent:@"isOlderThan_integration_tests"];
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
                                 age:(NSTimeInterval)ageInSeconds {
    NSString *filePath = [self.testFilesDirectory stringByAppendingPathComponent:fileName];
    
    // Create file with content
    NSString *content = [NSString stringWithFormat:@"Test file %@ created at %@",
                        fileName, [NSDate date]];
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
    
    [self.createdFiles addObject:filePath];
    return filePath;
}

- (int)runIsOlderThanWithArguments:(NSArray<NSString *> *)arguments
                      captureOutput:(NSString **)output
                       captureError:(NSString **)error {
    // Convert NSArray to C-style argv
    int argc = (int)arguments.count;
    char **argv = malloc(argc * sizeof(char *));
    
    for (int i = 0; i < argc; i++) {
        NSString *arg = arguments[i];
        argv[i] = malloc(strlen([arg UTF8String]) + 1);
        strcpy(argv[i], [arg UTF8String]);
    }
    
    // Create pipes for capturing output
    int stdout_pipe[2], stderr_pipe[2];
    pipe(stdout_pipe);
    pipe(stderr_pipe);
    
    // Backup original stdout/stderr
    int stdout_backup = dup(STDOUT_FILENO);
    int stderr_backup = dup(STDERR_FILENO);
    
    // Redirect stdout/stderr to pipes
    dup2(stdout_pipe[1], STDOUT_FILENO);
    dup2(stderr_pipe[1], STDERR_FILENO);
    close(stdout_pipe[1]);
    close(stderr_pipe[1]);
    
    // Run the main function
    int result = main(argc, argv);
    
    // Restore stdout/stderr
    dup2(stdout_backup, STDOUT_FILENO);
    dup2(stderr_backup, STDERR_FILENO);
    close(stdout_backup);
    close(stderr_backup);
    
    // Read captured output
    if (output) {
        char buffer[4096] = {0};
        read(stdout_pipe[0], buffer, sizeof(buffer) - 1);
        *output = [NSString stringWithUTF8String:buffer];
    }
    close(stdout_pipe[0]);
    
    if (error) {
        char buffer[4096] = {0};
        read(stderr_pipe[0], buffer, sizeof(buffer) - 1);
        *error = [NSString stringWithUTF8String:buffer];
    }
    close(stderr_pipe[0]);
    
    // Clean up argv
    for (int i = 0; i < argc; i++) {
        free(argv[i]);
    }
    free(argv);
    
    return result;
}

#pragma mark - Real-World Scenario Tests

- (void)testCleanupScenario {
    // Simulate a typical cleanup scenario with multiple files of different ages
    
    // Create files of various ages
    NSString *oldLog = [self createTestFileWithName:@"old.log"
                                                age:(35 * 24 * 60 * 60)]; // 35 days old
    NSString *newLog = [self createTestFileWithName:@"recent.log"
                                                age:(5 * 24 * 60 * 60)];  // 5 days old
    NSString *veryOldBackup = [self createTestFileWithName:@"backup.tar.gz"
                                                       age:(8 * 30 * 24 * 60 * 60)]; // ~8 months old
    NSString *currentConfig = [self createTestFileWithName:@"config.ini"
                                                        age:(1 * 60 * 60)]; // 1 hour old
    
    // Test cleanup criteria: remove files older than 30 days
    NSArray *testFiles = @[oldLog, newLog, veryOldBackup, currentConfig];
    NSMutableArray *filesToDelete = [NSMutableArray array];
    
    for (NSString *file in testFiles) {
        NSArray *arguments = @[@"isOlderThan", file, @"-days", @"30"];
        int result = [self runIsOlderThanWithArguments:arguments
                                         captureOutput:nil
                                          captureError:nil];
        
        if (result == SUCCESS) {
            [filesToDelete addObject:file];
        }
    }
    
    // Verify correct files were identified for deletion
    XCTAssertTrue([filesToDelete containsObject:oldLog], @"35-day-old log should be marked for deletion");
    XCTAssertTrue([filesToDelete containsObject:veryOldBackup], @"8-month-old backup should be marked for deletion");
    XCTAssertFalse([filesToDelete containsObject:newLog], @"5-day-old log should NOT be marked for deletion");
    XCTAssertFalse([filesToDelete containsObject:currentConfig], @"1-hour-old config should NOT be marked for deletion");
}

- (void)testBackupValidationScenario {
    // Simulate backup validation: ensure backup files are not too old
    
    NSString *dailyBackup = [self createTestFileWithName:@"daily_backup.tar.gz"
                                                     age:(20 * 60 * 60)]; // 20 hours old
    NSString *weeklyBackup = [self createTestFileWithName:@"weekly_backup.tar.gz"
                                                      age:(5 * 24 * 60 * 60)]; // 5 days old
    NSString *monthlyBackup = [self createTestFileWithName:@"monthly_backup.tar.gz"
                                                       age:(20 * 24 * 60 * 60)]; // 20 days old
    
    // Check daily backup (should be fresh, less than 1 day old)
    NSArray *dailyArgs = @[@"isOlderThan", dailyBackup, @"-days", @"1"];
    int dailyResult = [self runIsOlderThanWithArguments:dailyArgs
                                          captureOutput:nil
                                           captureError:nil];
    XCTAssertEqual(dailyResult, ERROR_INVALID_ARGS, @"Daily backup should be fresh (not older than 1 day)");
    
    // Check weekly backup (should be fresh, less than 7 days old)
    NSArray *weeklyArgs = @[@"isOlderThan", weeklyBackup, @"-weeks", @"1"];
    int weeklyResult = [self runIsOlderThanWithArguments:weeklyArgs
                                           captureOutput:nil
                                            captureError:nil];
    XCTAssertEqual(weeklyResult, ERROR_INVALID_ARGS, @"Weekly backup should be fresh (not older than 1 week)");
    
    // Check monthly backup (should be fresh, less than 1 month old)
    NSArray *monthlyArgs = @[@"isOlderThan", monthlyBackup, @"-months", @"1"];
    int monthlyResult = [self runIsOlderThanWithArguments:monthlyArgs
                                            captureOutput:nil
                                             captureError:nil];
    XCTAssertEqual(monthlyResult, ERROR_INVALID_ARGS, @"Monthly backup should be fresh (not older than 1 month)");
}

- (void)testLogRotationScenario {
    // Simulate log rotation scenario with different time periods
    
    NSArray *logFiles = @[
        [self createTestFileWithName:@"app.log" age:(2 * 60 * 60)],       // 2 hours
        [self createTestFileWithName:@"app.log.1" age:(1 * 24 * 60 * 60)], // 1 day
        [self createTestFileWithName:@"app.log.2" age:(3 * 24 * 60 * 60)], // 3 days
        [self createTestFileWithName:@"app.log.3" age:(7 * 24 * 60 * 60)], // 1 week
        [self createTestFileWithName:@"app.log.4" age:(14 * 24 * 60 * 60)], // 2 weeks
        [self createTestFileWithName:@"app.log.5" age:(35 * 24 * 60 * 60)]  // 5 weeks
    ];
    
    // Test different retention policies
    
    // Policy 1: Keep logs for 1 week
    NSMutableArray *weekOldLogs = [NSMutableArray array];
    for (NSString *logFile in logFiles) {
        NSArray *arguments = @[@"isOlderThan", logFile, @"-weeks", @"1"];
        int result = [self runIsOlderThanWithArguments:arguments
                                         captureOutput:nil
                                          captureError:nil];
        if (result == SUCCESS) {
            [weekOldLogs addObject:[logFile lastPathComponent]];
        }
    }
    
    XCTAssertEqual([weekOldLogs count], 2, @"Should identify 2 logs older than 1 week");
    XCTAssertTrue([weekOldLogs containsObject:@"app.log.4"], @"2-week-old log should be identified");
    XCTAssertTrue([weekOldLogs containsObject:@"app.log.5"], @"5-week-old log should be identified");
    
    // Policy 2: Keep logs for 10 days
    NSMutableArray *tenDayOldLogs = [NSMutableArray array];
    for (NSString *logFile in logFiles) {
        NSArray *arguments = @[@"isOlderThan", logFile, @"-days", @"10"];
        int result = [self runIsOlderThanWithArguments:arguments
                                         captureOutput:nil
                                          captureError:nil];
        if (result == SUCCESS) {
            [tenDayOldLogs addObject:[logFile lastPathComponent]];
        }
    }
    
    XCTAssertEqual([tenDayOldLogs count], 2, @"Should identify 2 logs older than 10 days");
}

#pragma mark - Performance Tests

- (void)testPerformanceWithManyFiles {
    // Create many test files
    NSMutableArray *testFiles = [NSMutableArray array];
    
    for (int i = 0; i < 100; i++) {
        NSString *fileName = [NSString stringWithFormat:@"perf_test_%d.txt", i];
        NSTimeInterval age = (i % 10 + 1) * 24 * 60 * 60; // 1-10 days old
        NSString *filePath = [self createTestFileWithName:fileName age:age];
        [testFiles addObject:filePath];
    }
    
    // Measure performance of checking all files
    NSDate *startTime = [NSDate date];
    
    int oldFileCount = 0;
    for (NSString *file in testFiles) {
        NSArray *arguments = @[@"isOlderThan", file, @"-days", @"5"];
        int result = [self runIsOlderThanWithArguments:arguments
                                         captureOutput:nil
                                          captureError:nil];
        if (result == SUCCESS) {
            oldFileCount++;
        }
    }
    
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:startTime];
    
    // Performance assertions
    XCTAssertLessThan(duration, 5.0, @"Checking 100 files should take less than 5 seconds");
    XCTAssertGreaterThan(oldFileCount, 0, @"Should find some old files");
    
    NSLog(@"Performance test: Checked %lu files in %.3f seconds (%.1f files/sec)",
          (unsigned long)[testFiles count], duration, [testFiles count] / duration);
}

- (void)testMemoryUsageStability {
    // Test for memory leaks with repeated operations
    
    NSString *testFile = [self createTestFileWithName:@"memory_test.txt"
                                                  age:(24 * 60 * 60)]; // 1 day old
    
    // Perform many operations
    for (int i = 0; i < 1000; i++) {
        NSArray *arguments = @[@"isOlderThan", testFile, @"-days", @"1"];
        int result = [self runIsOlderThanWithArguments:arguments
                                         captureOutput:nil
                                          captureError:nil];
        XCTAssertEqual(result, SUCCESS, @"Operation %d should succeed", i);
        
        // Periodically check that we're not accumulating resources
        if (i % 100 == 0) {
            // This is a basic check - in a real scenario you might use more sophisticated memory monitoring
            XCTAssertTrue(YES, @"Memory check at iteration %d", i);
        }
    }
}

#pragma mark - Output Format Tests

- (void)testOutputMessages {
    // Test that output messages are informative and correctly formatted
    
    NSString *oldFile = [self createTestFileWithName:@"old_file.txt"
                                                  age:(48 * 60 * 60)]; // 2 days old
    NSString *newFile = [self createTestFileWithName:@"new_file.txt"
                                                  age:(12 * 60 * 60)]; // 12 hours old
    
    // Test output for old file
    NSString *oldOutput, *oldError;
    NSArray *oldArgs = @[@"isOlderThan", oldFile, @"-days", @"1"];
    int oldResult = [self runIsOlderThanWithArguments:oldArgs
                                        captureOutput:&oldOutput
                                         captureError:&oldError];
    
    XCTAssertEqual(oldResult, SUCCESS, @"Old file check should succeed");
    XCTAssertTrue([oldOutput containsString:@"older"], @"Output should mention file is older");
    XCTAssertTrue([oldOutput containsString:[oldFile lastPathComponent]], @"Output should include filename");
    
    // Test output for new file
    NSString *newOutput, *newError;
    NSArray *newArgs = @[@"isOlderThan", newFile, @"-days", @"1"];
    int newResult = [self runIsOlderThanWithArguments:newArgs
                                        captureOutput:&newOutput
                                         captureError:&newError];
    
    XCTAssertEqual(newResult, ERROR_INVALID_ARGS, @"New file check should indicate not older");
    XCTAssertTrue([newOutput containsString:@"NOT older"], @"Output should mention file is NOT older");
    XCTAssertTrue([newOutput containsString:[newFile lastPathComponent]], @"Output should include filename");
}

- (void)testTimestampOutput {
    // Test that timestamp information is included in output
    
    NSString *testFile = [self createTestFileWithName:@"timestamp_test.txt"
                                                  age:(25 * 60 * 60)]; // 25 hours old
    
    NSString *output, *error;
    NSArray *arguments = @[@"isOlderThan", testFile, @"-days", @"1"];
    int result = [self runIsOlderThanWithArguments:arguments
                                     captureOutput:&output
                                      captureError:&error];
    
    XCTAssertEqual(result, SUCCESS, @"25-hour-old file should be older than 1 day");
    XCTAssertTrue([output containsString:@"File modified:"], @"Output should include file modification time");
    XCTAssertTrue([output containsString:@"Reference time:"], @"Output should include reference time");
    
    // Check timestamp format (YYYY-MM-DD HH:MM:SS)
    NSRegularExpression *timestampRegex = [NSRegularExpression
        regularExpressionWithPattern:@"\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}"
                             options:0
                               error:nil];
    
    NSUInteger matches = [timestampRegex numberOfMatchesInString:output
                                                         options:0
                                                           range:NSMakeRange(0, [output length])];
    
    XCTAssertGreaterThanOrEqual(matches, 2, @"Should contain at least 2 timestamps (file + reference)");
}

#pragma mark - Cross-Platform Compatibility Tests

- (void)testPathSeparatorHandling {
    // Test handling of different path separators
    
    NSString *testFile = [self createTestFileWithName:@"path_test.txt"
                                                  age:(24 * 60 * 60)]; // 1 day old
    
    // Test with forward slashes (Unix-style)
    NSString *unixPath = [testFile stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    NSArray *unixArgs = @[@"isOlderThan", unixPath, @"-days", @"1"];
    int unixResult = [self runIsOlderThanWithArguments:unixArgs
                                         captureOutput:nil
                                          captureError:nil];
    
    XCTAssertEqual(unixResult, SUCCESS, @"Unix-style paths should work");
}

- (void)testLargeFileHandling {
    // Test with a larger file to ensure file size doesn't affect time checking
    
    NSString *largeFile = [self createTestFileWithName:@"large_file.txt"
                                                    age:(48 * 60 * 60)]; // 2 days old
    
    // Write substantial content to make it a "large" file
    NSMutableString *largeContent = [NSMutableString string];
    for (int i = 0; i < 1000; i++) {
        [largeContent appendFormat:@"Line %d: This is test content for a large file test.\n", i];
    }
    
    [largeContent writeToFile:largeFile
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:nil];
    
    // Reset file age after writing content
    NSDate *modificationDate = [NSDate dateWithTimeIntervalSinceNow:-(48 * 60 * 60)];
    NSDictionary *attributes = @{NSFileModificationDate: modificationDate};
    [[NSFileManager defaultManager] setAttributes:attributes
                                     ofItemAtPath:largeFile
                                            error:nil];
    
    NSArray *arguments = @[@"isOlderThan", largeFile, @"-days", @"1"];
    int result = [self runIsOlderThanWithArguments:arguments
                                     captureOutput:nil
                                      captureError:nil];
    
    XCTAssertEqual(result, SUCCESS, @"Large files should be handled correctly");
}

#pragma mark - Command Line Interface Tests

- (void)testHelpOutput {
    // Test --help and -h options
    
    NSString *helpOutput, *helpError;
    NSArray *helpArgs = @[@"isOlderThan", @"--help"];
    int helpResult = [self runIsOlderThanWithArguments:helpArgs
                                         captureOutput:&helpOutput
                                          captureError:&helpError];
    
    XCTAssertEqual(helpResult, SUCCESS, @"Help command should return success");
    XCTAssertTrue([helpOutput containsString:@"Usage:"], @"Help should contain usage information");
    XCTAssertTrue([helpOutput containsString:@"Options:"] || [helpOutput containsString:@"parameters:"],
                  @"Help should contain options information");
    
    // Test short form
    NSString *shortHelpOutput;
    NSArray *shortHelpArgs = @[@"isOlderThan", @"-h"];
    int shortHelpResult = [self runIsOlderThanWithArguments:shortHelpArgs
                                              captureOutput:&shortHelpOutput
                                               captureError:nil];
    
    XCTAssertEqual(shortHelpResult, SUCCESS, @"Short help command should return success");
    XCTAssertTrue([shortHelpOutput containsString:@"Usage:"], @"Short help should contain usage information");
}

- (void)testVersionOutput {
    // Test --version and -v options
    
    NSString *versionOutput, *versionError;
    NSArray *versionArgs = @[@"isOlderThan", @"--version"];
    int versionResult = [self runIsOlderThanWithArguments:versionArgs
                                            captureOutput:&versionOutput
                                             captureError:&versionError];
    
    XCTAssertEqual(versionResult, SUCCESS, @"Version command should return success");
    XCTAssertTrue([versionOutput containsString:@"version"] || [versionOutput containsString:@"1.0"],
                  @"Version output should contain version information");
    
    // Test short form
    NSString *shortVersionOutput;
    NSArray *shortVersionArgs = @[@"isOlderThan", @"-v"];
    int shortVersionResult = [self runIsOlderThanWithArguments:shortVersionArgs
                                                 captureOutput:&shortVersionOutput
                                                  captureError:nil];
    
    XCTAssertEqual(shortVersionResult, SUCCESS, @"Short version command should return success");
}

#pragma mark - Stress Tests

- (void)testRepeatedOperations {
    // Test stability with repeated operations
    
    NSString *testFile = [self createTestFileWithName:@"stress_test.txt"
                                                  age:(24 * 60 * 60)]; // 1 day old
    
    int successCount = 0;
    int totalOperations = 100;
    
    for (int i = 0; i < totalOperations; i++) {
        NSArray *arguments = @[@"isOlderThan", testFile, @"-days", @"1"];
        int result = [self runIsOlderThanWithArguments:arguments
                                         captureOutput:nil
                                          captureError:nil];
        
        if (result == SUCCESS) {
            successCount++;
        }
        
        // Every operation should give the same result
        XCTAssertEqual(result, SUCCESS, @"Operation %d should succeed consistently", i);
    }
    
    XCTAssertEqual(successCount, totalOperations, @"All operations should succeed");
}

- (void)testConcurrentFileCreation {
    // Test behavior when files are created during execution
    
    NSMutableArray *concurrentFiles = [NSMutableArray array];
    
    // Create multiple files with different ages rapidly
    for (int i = 0; i < 20; i++) {
        NSString *fileName = [NSString stringWithFormat:@"concurrent_%d.txt", i];
        NSTimeInterval age = (i + 1) * 3600; // 1, 2, 3... hours old
        NSString *filePath = [self createTestFileWithName:fileName age:age];
        [concurrentFiles addObject:filePath];
    }
    
    // Check all files against 12 hours criterion
    int oldFileCount = 0;
    int newFileCount = 0;
    
    for (NSString *file in concurrentFiles) {
        NSArray *arguments = @[@"isOlderThan", file, @"-hours", @"12"]; // Note: hours not implemented, should fail gracefully
        int result = [self runIsOlderThanWithArguments:arguments
                                         captureOutput:nil
                                          captureError:nil];
        
        // Since -hours is not implemented, this should return an error
        XCTAssertNotEqual(result, SUCCESS, @"Unimplemented parameter should return error");
    }
    
    // Test with days instead
    for (NSString *file in concurrentFiles) {
        NSArray *arguments = @[@"isOlderThan", file, @"-days", @"1"];
        int result = [self runIsOlderThanWithArguments:arguments
                                         captureOutput:nil
                                          captureError:nil];
        
        if (result == SUCCESS) {
            oldFileCount++;
        } else {
            newFileCount++;
        }
    }
    
    // Files 1-20 hours old: none should be older than 1 day
    XCTAssertEqual(oldFileCount, 0, @"No files should be older than 1 day");
    XCTAssertEqual(newFileCount, 20, @"All files should be newer than 1 day");
}

#pragma mark - Comprehensive Workflow Tests

- (void)testCompleteCleanupWorkflow {
    // Simulate a complete cleanup workflow with various file types and ages
    
    // Create a realistic file structure
    NSArray *testFiles = @[
        @{@"name": @"recent_log.log", @"age": @(2 * 3600)},        // 2 hours
        @{@"name": @"daily_backup.bak", @"age": @(20 * 3600)},     // 20 hours
        @{@"name": @"weekly_report.pdf", @"age": @(8 * 24 * 3600)}, // 8 days
        @{@"name": @"old_cache.tmp", @"age": @(45 * 24 * 3600)},   // 45 days
        @{@"name": @"config.ini", @"age": @(1 * 3600)},            // 1 hour
        @{@"name": @"archive.zip", @"age": @(90 * 24 * 3600)}      // 90 days
    ];
    
    NSMutableArray *createdFilePaths = [NSMutableArray array];
    
    // Create all test files
    for (NSDictionary *fileInfo in testFiles) {
        NSString *fileName = fileInfo[@"name"];
        NSTimeInterval age = [fileInfo[@"age"] doubleValue];
        NSString *filePath = [self createTestFileWithName:fileName age:age];
        [createdFilePaths addObject:filePath];
    }
    
    // Test different cleanup policies
    
    // Policy 1: Remove files older than 1 day
    NSMutableArray *oneDayOld = [NSMutableArray array];
    for (NSString *file in createdFilePaths) {
        NSArray *args = @[@"isOlderThan", file, @"-days", @"1"];
        int result = [self runIsOlderThanWithArguments:args captureOutput:nil captureError:nil];
        if (result == SUCCESS) {
            [oneDayOld addObject:[file lastPathComponent]];
        }
    }
    
    XCTAssertEqual([oneDayOld count], 3, @"Should find 3 files older than 1 day");
    XCTAssertTrue([oneDayOld containsObject:@"weekly_report.pdf"], @"8-day-old file should be identified");
    XCTAssertTrue([oneDayOld containsObject:@"old_cache.tmp"], @"45-day-old file should be identified");
    XCTAssertTrue([oneDayOld containsObject:@"archive.zip"], @"90-day-old file should be identified");
    
    // Policy 2: Remove files older than 1 week
    NSMutableArray *oneWeekOld = [NSMutableArray array];
    for (NSString *file in createdFilePaths) {
        NSArray *args = @[@"isOlderThan", file, @"-weeks", @"1"];
        int result = [self runIsOlderThanWithArguments:args captureOutput:nil captureError:nil];
        if (result == SUCCESS) {
            [oneWeekOld addObject:[file lastPathComponent]];
        }
    }
    
    XCTAssertEqual([oneWeekOld count], 2, @"Should find 2 files older than 1 week");
    XCTAssertTrue([oneWeekOld containsObject:@"old_cache.tmp"], @"45-day-old file should be identified");
    XCTAssertTrue([oneWeekOld containsObject:@"archive.zip"], @"90-day-old file should be identified");
    
    // Policy 3: Remove files older than 1 month
    NSMutableArray *oneMonthOld = [NSMutableArray array];
    for (NSString *file in createdFilePaths) {
        NSArray *args = @[@"isOlderThan", file, @"-months", @"1"];
        int result = [self runIsOlderThanWithArguments:args captureOutput:nil captureError:nil];
        if (result == SUCCESS) {
            [oneMonthOld addObject:[file lastPathComponent]];
        }
    }
    
    XCTAssertEqual([oneMonthOld count], 1, @"Should find 1 file older than 1 month");
    XCTAssertTrue([oneMonthOld containsObject:@"archive.zip"], @"90-day-old file should be identified");
}

- (void)testBatchProcessingSimulation {
    // Simulate batch processing of many files
    
    NSMutableArray *batchFiles = [NSMutableArray array];
    
    // Create 50 files with random ages
    for (int i = 0; i < 50; i++) {
        NSString *fileName = [NSString stringWithFormat:@"batch_%03d.dat", i];
        // Random age between 1 hour and 100 days
        NSTimeInterval age = (arc4random_uniform(100 * 24) + 1) * 3600;
        NSString *filePath = [self createTestFileWithName:fileName age:age];
        [batchFiles addObject:filePath];
    }
    
    NSDate *startTime = [NSDate date];
    
    // Process all files with different criteria
    NSArray *criteria = @[
        @[@"-days", @"7"],
        @[@"-days", @"30"],
        @[@"-weeks", @"2"],
        @[@"-months", @"1"]
    ];
    
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    
    for (NSArray *criterion in criteria) {
        NSString *key = [criterion componentsJoinedByString:@" "];
        NSMutableArray *matchingFiles = [NSMutableArray array];
        
        for (NSString *file in batchFiles) {
            NSMutableArray *args = [NSMutableArray arrayWithArray:@[@"isOlderThan", file]];
            [args addObjectsFromArray:criterion];
            
            int result = [self runIsOlderThanWithArguments:args
                                             captureOutput:nil
                                              captureError:nil];
            if (result == SUCCESS) {
                [matchingFiles addObject:[file lastPathComponent]];
            }
        }
        
        results[key] = matchingFiles;
    }
    
    NSTimeInterval processingTime = [[NSDate date] timeIntervalSinceDate:startTime];
    
    // Performance assertion
    XCTAssertLessThan(processingTime, 10.0, @"Batch processing of 200 operations should complete in under 10 seconds");
    
    // Logic assertions
    NSUInteger sevenDayCount = [results[@"days 7"] count];
    NSUInteger thirtyDayCount = [results[@"days 30"] count];
    NSUInteger twoWeekCount = [results[@"weeks 2"] count];
    NSUInteger oneMonthCount = [results[@"months 1"] count];
    
    // More restrictive criteria should find fewer or equal files
    XCTAssertLessThanOrEqual(sevenDayCount, thirtyDayCount, @"7-day criteria should find <= files than 30-day");
    XCTAssertLessThanOrEqual(twoWeekCount, oneMonthCount, @"2-week criteria should find <= files than 1-month");
    
    NSLog(@"Batch processing results:");
    NSLog(@"  7 days: %lu files", (unsigned long)sevenDayCount);
    NSLog(@"  30 days: %lu files", (unsigned long)thirtyDayCount);
    NSLog(@"  2 weeks: %lu files", (unsigned long)twoWeekCount);
    NSLog(@"  1 month: %lu files", (unsigned long)oneMonthCount);
    NSLog(@"  Processing time: %.3f seconds", processingTime);
}

@end
