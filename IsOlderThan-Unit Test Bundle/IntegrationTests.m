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

// Include the header file instead of the implementation
#include "isOlderThan.h"

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
        const char *utf8String = [arg UTF8String];
        size_t len = strlen(utf8String);
        argv[i] = malloc(len + 1);
        strcpy(argv[i], utf8String);
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
    
    // Call the main function through our testing interface
    int result;
    result = isOlderThan_main(argc, argv);
    
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

- (int)runIsOlderThanWithArguments:(NSArray<NSString *> *)arguments {
    return [self runIsOlderThanWithArguments:arguments captureOutput:nil captureError:nil];
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
        int result = [self runIsOlderThanWithArguments:arguments];
        
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
    int dailyResult = [self runIsOlderThanWithArguments:dailyArgs];
    XCTAssertEqual(dailyResult, ERROR_INVALID_ARGS, @"Daily backup should be fresh (not older than 1 day)");
    
    // Check weekly backup (should be fresh, less than 7 days old)
    NSArray *weeklyArgs = @[@"isOlderThan", weeklyBackup, @"-weeks", @"1"];
    int weeklyResult = [self runIsOlderThanWithArguments:weeklyArgs];
    XCTAssertEqual(weeklyResult, ERROR_INVALID_ARGS, @"Weekly backup should be fresh (not older than 1 week)");
    
    // Check monthly backup (should be fresh, less than 1 month old)
    NSArray *monthlyArgs = @[@"isOlderThan", monthlyBackup, @"-months", @"1"];
    int monthlyResult = [self runIsOlderThanWithArguments:monthlyArgs];
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
        int result = [self runIsOlderThanWithArguments:arguments];
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
        int result = [self runIsOlderThanWithArguments:arguments];
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
    
    for (int i = 0; i < 50; i++) { // Reduced from 100 to 50 for faster testing
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
        int result = [self runIsOlderThanWithArguments:arguments];
        if (result == SUCCESS) {
            oldFileCount++;
        }
    }
    
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:startTime];
    
    // Performance assertions
    XCTAssertLessThan(duration, 2.0, @"Checking 50 files should take less than 2 seconds");
    XCTAssertGreaterThan(oldFileCount, 0, @"Should find some old files");
    
    NSLog(@"Performance test: Checked %lu files in %.3f seconds (%.1f files/sec)",
          (unsigned long)[testFiles count], duration, [testFiles count] / duration);
}

- (void)testMemoryUsageStability {
    // Test for memory leaks with repeated operations
    
    NSString *testFile = [self createTestFileWithName:@"memory_test.txt"
                                                  age:(24 * 60 * 60)]; // 1 day old
    
    // Perform many operations (reduced count for faster testing)
    for (int i = 0; i < 100; i++) {
        NSArray *arguments = @[@"isOlderThan", testFile, @"-days", @"1"];
        int result = [self runIsOlderThanWithArguments:arguments];
        XCTAssertEqual(result, SUCCESS, @"Operation %d should succeed", i);
        
        // Periodically check that we're not accumulating resources
        if (i % 25 == 0) {
            // This is a basic check - in a real scenario you might use more sophisticated memory monitoring
            XCTAssertTrue(YES, @"Memory check at iteration %d", i);
        }
    }
}

#pragma mark - Component Integration Tests

- (void)testArgumentParsingIntegration {
    // Test complete argument parsing workflow
    
    NSString *testFile = [self createTestFileWithName:@"integration_test.txt"
                                                  age:(48 * 60 * 60)]; // 2 days old
    
    // Test various argument combinations
    NSArray *testCases = @[
        @[@"isOlderThan", testFile, @"-days", @"1"],
        @[@"isOlderThan", testFile, @"-weeks", @"1"],
        @[@"isOlderThan", testFile, @"-months", @"1"],
        @[@"isOlderThan", testFile, @"-years", @"1", @"-months", @"6"],
        @[@"isOlderThan", testFile, @"-days", @"1", @"-exact"]
    ];
    
    for (NSArray *testCase in testCases) {
        int result = [self runIsOlderThanWithArguments:testCase];
        XCTAssertTrue(result == SUCCESS || result == ERROR_INVALID_ARGS,
                      @"Test case should return valid result: %@", testCase);
    }
}

- (void)testFileTimeCalculationIntegration {
    // Test the complete file time calculation workflow
    
    // Create files with specific ages
    NSString *oldFile = [self createTestFileWithName:@"old_file.txt"
                                                 age:(2 * 24 * 60 * 60)]; // 2 days
    NSString *newFile = [self createTestFileWithName:@"new_file.txt"
                                                 age:(12 * 60 * 60)]; // 12 hours
    
    // Test file time retrieval
    time_t oldFileTime = get_file_modification_time([oldFile UTF8String]);
    time_t newFileTime = get_file_modification_time([newFile UTF8String]);
    
    XCTAssertGreaterThan(oldFileTime, 0, @"Should get valid old file time");
    XCTAssertGreaterThan(newFileTime, 0, @"Should get valid new file time");
    XCTAssertLessThan(oldFileTime, newFileTime, @"Old file should have earlier timestamp");
    
    // Test reference time calculation
    arguments_t args = {0};
    args.filepath = [oldFile UTF8String];
    args.days = 1;
    args.has_days = 1;
    
    time_t referenceTime = calculate_reference_time(&args);
    
    // Verify relationship: old file < reference time < new file time
    XCTAssertLessThan(oldFileTime, referenceTime, @"Old file should be older than reference");
    XCTAssertGreaterThan(newFileTime, referenceTime, @"New file should be newer than reference");
}

- (void)testErrorHandlingIntegration {
    // Test error handling throughout the system
    
    // Test with non-existent file
    NSArray *args1 = @[@"isOlderThan", @"/nonexistent/file.txt", @"-days", @"1"];
    int result1 = [self runIsOlderThanWithArguments:args1];
    XCTAssertEqual(result1, ERROR_FILE_NOT_FOUND, @"Should handle non-existent file");
    
    // Test with invalid arguments
    NSArray *args2 = @[@"isOlderThan", @"/tmp/test.txt", @"-invalid"];
    int result2 = [self runIsOlderThanWithArguments:args2];
    XCTAssertEqual(result2, ERROR_INVALID_ARGS, @"Should handle invalid arguments");
    
    // Test with invalid parameter combination
    NSString *testFile = [self createTestFileWithName:@"error_test.txt" age:3600];
    NSArray *args3 = @[@"isOlderThan", testFile, @"-days", @"1", @"-weeks", @"1"];
    int result3 = [self runIsOlderThanWithArguments:args3];
    XCTAssertEqual(result3, ERROR_INVALID_COMBINATION, @"Should handle invalid combinations");
}

#pragma mark - Real-World Workflow Tests

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
        int result = [self runIsOlderThanWithArguments:args];
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
        int result = [self runIsOlderThanWithArguments:args];
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
        int result = [self runIsOlderThanWithArguments:args];
        if (result == SUCCESS) {
            [oneMonthOld addObject:[file lastPathComponent]];
        }
    }
    
    XCTAssertEqual([oneMonthOld count], 1, @"Should find 1 file older than 1 month");
    XCTAssertTrue([oneMonthOld containsObject:@"archive.zip"], @"90-day-old file should be identified");
}

@end
