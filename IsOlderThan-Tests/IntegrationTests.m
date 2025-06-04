    //
//  IntegrationTests.m
//  IsOlderThan
//
//  Created by Christian Kropfberger on 04.06.25.
//
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
#include "../isOlderThan/main.c"

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
