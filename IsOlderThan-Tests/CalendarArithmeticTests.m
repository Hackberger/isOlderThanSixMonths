//
//  CalendarArithmeticTests.m
//  IsOlderThan
//
//  Created by Christian Kropfberger on 04.06.25.
//
//  isOlderThan Tests
//
//  Tests for calendar arithmetic functions including leap years,
//  month calculations, and edge cases in date handling
//

#import <XCTest/XCTest.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Include the main source file for testing
#include "../isOlderThan/isOlderThan.c"

@interface CalendarArithmeticTests : XCTestCase
@end

@implementation CalendarArithmeticTests

#pragma mark - Leap Year Tests

- (void)testLeapYearCalculation {
    // Test regular leap years (divisible by 4)
    XCTAssertTrue(is_leap_year(2020), @"2020 should be a leap year");
    XCTAssertTrue(is_leap_year(2024), @"2024 should be a leap year");
    XCTAssertTrue(is_leap_year(1996), @"1996 should be a leap year");
    
    // Test non-leap years
    XCTAssertFalse(is_leap_year(2021), @"2021 should not be a leap year");
    XCTAssertFalse(is_leap_year(2022), @"2022 should not be a leap year");
    XCTAssertFalse(is_leap_year(2023), @"2023 should not be a leap year");
}

- (void)testLeapYearCenturyRule {
    // Test century years (divisible by 100 but not 400)
    XCTAssertFalse(is_leap_year(1700), @"1700 should not be a leap year");
    XCTAssertFalse(is_leap_year(1800), @"1800 should not be a leap year");
    XCTAssertFalse(is_leap_year(1900), @"1900 should not be a leap year");
    XCTAssertFalse(is_leap_year(2100), @"2100 should not be a leap year");
}

- (void)testLeapYear400Rule {
    // Test years divisible by 400 (special leap years)
    XCTAssertTrue(is_leap_year(1600), @"1600 should be a leap year");
    XCTAssertTrue(is_leap_year(2000), @"2000 should be a leap year");
    XCTAssertTrue(is_leap_year(2400), @"2400 should be a leap year");
}

#pragma mark - Days in Month Tests

- (void)testDaysInMonthNormal {
    // Test regular months in non-leap year
    XCTAssertEqual(get_days_in_month(1, 2023), 31, @"January should have 31 days");
    XCTAssertEqual(get_days_in_month(2, 2023), 28, @"February 2023 should have 28 days");
    XCTAssertEqual(get_days_in_month(3, 2023), 31, @"March should have 31 days");
    XCTAssertEqual(get_days_in_month(4, 2023), 30, @"April should have 30 days");
    XCTAssertEqual(get_days_in_month(5, 2023), 31, @"May should have 31 days");
    XCTAssertEqual(get_days_in_month(6, 2023), 30, @"June should have 30 days");
    XCTAssertEqual(get_days_in_month(7, 2023), 31, @"July should have 31 days");
    XCTAssertEqual(get_days_in_month(8, 2023), 31, @"August should have 31 days");
    XCTAssertEqual(get_days_in_month(9, 2023), 30, @"September should have 30 days");
    XCTAssertEqual(get_days_in_month(10, 2023), 31, @"October should have 31 days");
    XCTAssertEqual(get_days_in_month(11, 2023), 30, @"November should have 30 days");
    XCTAssertEqual(get_days_in_month(12, 2023), 31, @"December should have 31 days");
}

- (void)testDaysInMonthLeapYear {
    // Test February in leap years
    XCTAssertEqual(get_days_in_month(2, 2020), 29, @"February 2020 should have 29 days");
    XCTAssertEqual(get_days_in_month(2, 2024), 29, @"February 2024 should have 29 days");
    XCTAssertEqual(get_days_in_month(2, 2000), 29, @"February 2000 should have 29 days");
}

- (void)testDaysInMonthFebruaryNonLeap {
    // Test February in non-leap years
    XCTAssertEqual(get_days_in_month(2, 2021), 28, @"February 2021 should have 28 days");
    XCTAssertEqual(get_days_in_month(2, 1900), 28, @"February 1900 should have 28 days");
    XCTAssertEqual(get_days_in_month(2, 2100), 28, @"February 2100 should have 28 days");
}

- (void)testDaysInMonthInvalidInput {
    // Test invalid month numbers
    XCTAssertEqual(get_days_in_month(0, 2023), 0, @"Month 0 should return 0");
    XCTAssertEqual(get_days_in_month(13, 2023), 0, @"Month 13 should return 0");
    XCTAssertEqual(get_days_in_month(-1, 2023), 0, @"Negative month should return 0");
}

#pragma mark - Month Addition Tests

- (void)testAddMonthsBasic {
    // Create a base time: January 15, 2023, 12:00:00
    struct tm base_tm = {0};
    base_tm.tm_year = 2023 - 1900;
    base_tm.tm_mon = 0; // January
    base_tm.tm_mday = 15;
    base_tm.tm_hour = 12;
    time_t base_time = mktime(&base_tm);
    
    // Add 6 months
    time_t result_time = add_months_to_time(base_time, 6);
    struct tm *result_tm = localtime(&result_time);
    
    XCTAssertEqual(result_tm->tm_year, 2023 - 1900, @"Year should remain 2023");
    XCTAssertEqual(result_tm->tm_mon, 6, @"Month should be July (6)");
    XCTAssertEqual(result_tm->tm_mday, 15, @"Day should remain 15");
}

- (void)testAddMonthsYearOverflow {
    // Create a base time: October 15, 2023
    struct tm base_tm = {0};
    base_tm.tm_year = 2023 - 1900;
    base_tm.tm_mon = 9; // October
    base_tm.tm_mday = 15;
    time_t base_time = mktime(&base_tm);
    
    // Add 6 months (should go to April 2024)
    time_t result_time = add_months_to_time(base_time, 6);
    struct tm *result_tm = localtime(&result_time);
    
    XCTAssertEqual(result_tm->tm_year, 2024 - 1900, @"Year should be 2024");
    XCTAssertEqual(result_tm->tm_mon, 3, @"Month should be April (3)");
    XCTAssertEqual(result_tm->tm_mday, 15, @"Day should remain 15");
}

- (void)testAddMonthsDayOverflow {
    // Create a base time: January 31, 2023
    struct tm base_tm = {0};
    base_tm.tm_year = 2023 - 1900;
    base_tm.tm_mon = 0; // January
    base_tm.tm_mday = 31;
    time_t base_time = mktime(&base_tm);
    
    // Add 1 month (should go to February 28, 2023)
    time_t result_time = add_months_to_time(base_time, 1);
    struct tm *result_tm = localtime(&result_time);
    
    XCTAssertEqual(result_tm->tm_year, 2023 - 1900, @"Year should remain 2023");
    XCTAssertEqual(result_tm->tm_mon, 1, @"Month should be February (1)");
    XCTAssertEqual(result_tm->tm_mday, 28, @"Day should be adjusted to 28");
}

- (void)testAddMonthsLeapYearHandling {
    // Create a base time: January 31, 2020 (leap year)
    struct tm base_tm = {0};
    base_tm.tm_year = 2020 - 1900;
    base_tm.tm_mon = 0; // January
    base_tm.tm_mday = 31;
    time_t base_time = mktime(&base_tm);
    
    // Add 1 month (should go to February 29, 2020)
    time_t result_time = add_months_to_time(base_time, 1);
    struct tm *result_tm = localtime(&result_time);
    
    XCTAssertEqual(result_tm->tm_year, 2020 - 1900, @"Year should remain 2020");
    XCTAssertEqual(result_tm->tm_mon, 1, @"Month should be February (1)");
    XCTAssertEqual(result_tm->tm_mday, 29, @"Day should be adjusted to 29 (leap year)");
}

- (void)testAddMonthsNegative {
    // Create a base time: July 15, 2023
    struct tm base_tm = {0};
    base_tm.tm_year = 2023 - 1900;
    base_tm.tm_mon = 6; // July
    base_tm.tm_mday = 15;
    time_t base_time = mktime(&base_tm);
    
    // Subtract 6 months
    time_t result_time = add_months_to_time(base_time, -6);
    struct tm *result_tm = localtime(&result_time);
    
    XCTAssertEqual(result_tm->tm_year, 2023 - 1900, @"Year should remain 2023");
    XCTAssertEqual(result_tm->tm_mon, 0, @"Month should be January (0)");
    XCTAssertEqual(result_tm->tm_mday, 15, @"Day should remain 15");
}

#pragma mark - Year Addition Tests

- (void)testAddYearsBasic {
    // Create a base time: June 15, 2020
    struct tm base_tm = {0};
    base_tm.tm_year = 2020 - 1900;
    base_tm.tm_mon = 5; // June
    base_tm.tm_mday = 15;
    time_t base_time = mktime(&base_tm);
    
    // Add 3 years
    time_t result_time = add_years_to_time(base_time, 3);
    struct tm *result_tm = localtime(&result_time);
    
    XCTAssertEqual(result_tm->tm_year, 2023 - 1900, @"Year should be 2023");
    XCTAssertEqual(result_tm->tm_mon, 5, @"Month should remain June (5)");
    XCTAssertEqual(result_tm->tm_mday, 15, @"Day should remain 15");
}

- (void)testAddYearsLeapYearToNonLeap {
    // Create a base time: February 29, 2020 (leap year)
    struct tm base_tm = {0};
    base_tm.tm_year = 2020 - 1900;
    base_tm.tm_mon = 1; // February
    base_tm.tm_mday = 29;
    time_t base_time = mktime(&base_tm);
    
    // Add 1 year (should go to February 28, 2021)
    time_t result_time = add_years_to_time(base_time, 1);
    struct tm *result_tm = localtime(&result_time);
    
    XCTAssertEqual(result_tm->tm_year, 2021 - 1900, @"Year should be 2021");
    XCTAssertEqual(result_tm->tm_mon, 1, @"Month should remain February (1)");
    XCTAssertEqual(result_tm->tm_mday, 28, @"Day should be adjusted to 28");
}

- (void)testAddYearsLeapYearToLeap {
    // Create a base time: February 29, 2020 (leap year)
    struct tm base_tm = {0};
    base_tm.tm_year = 2020 - 1900;
    base_tm.tm_mon = 1; // February
    base_tm.tm_mday = 29;
    time_t base_time = mktime(&base_tm);
    
    // Add 4 years (should go to February 29, 2024)
    time_t result_time = add_years_to_time(base_time, 4);
    struct tm *result_tm = localtime(&result_time);
    
    XCTAssertEqual(result_tm->tm_year, 2024 - 1900, @"Year should be 2024");
    XCTAssertEqual(result_tm->tm_mon, 1, @"Month should remain February (1)");
    XCTAssertEqual(result_tm->tm_mday, 29, @"Day should remain 29 (leap year)");
}

- (void)testAddYearsNegative {
    // Create a base time: September 10, 2025
    struct tm base_tm = {0};
    base_tm.tm_year = 2025 - 1900;
    base_tm.tm_mon = 8; // September
    base_tm.tm_mday = 10;
    time_t base_time = mktime(&base_tm);
    
    // Subtract 2 years
    time_t result_time = add_years_to_time(base_time, -2);
    struct tm *result_tm = localtime(&result_time);
    
    XCTAssertEqual(result_tm->tm_year, 2023 - 1900, @"Year should be 2023");
    XCTAssertEqual(result_tm->tm_mon, 8, @"Month should remain September (8)");
    XCTAssertEqual(result_tm->tm_mday, 10, @"Day should remain 10");
}

#pragma mark - Reference Time Calculation Tests

- (void)testCalculateReferenceTimeDefault {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    // No time parameters set - should use default 6 months
    
    time_t reference_time = calculate_reference_time(&args);
    time_t current_time;
    time(&current_time);
    
    // The difference should be approximately 6 months
    double diff_seconds = difftime(current_time, reference_time);
    double diff_days = diff_seconds / (24 * 60 * 60);
    
    // Should be approximately 6 months (roughly 180 days, allow ±10 days for calendar variance)
    XCTAssertTrue(diff_days >= 170 && diff_days <= 190,
                  @"Default reference time should be approximately 6 months ago, got %.1f days", diff_days);
}

- (void)testCalculateReferenceTimeDays {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    args.days = 30;
    args.has_days = 1;
    
    time_t reference_time = calculate_reference_time(&args);
    time_t current_time;
    time(&current_time);
    
    double diff_seconds = difftime(current_time, reference_time);
    double diff_days = diff_seconds / (24 * 60 * 60);
    
    // Should be approximately 30 days (allow ±1 day for time calculation variance)
    XCTAssertTrue(diff_days >= 29 && diff_days <= 31,
                  @"Reference time should be approximately 30 days ago, got %.1f days", diff_days);
}

- (void)testCalculateReferenceTimeExactMode {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    args.days = 1;
    args.has_days = 1;
    args.exact_mode = 1;
    
    time_t reference_time = calculate_reference_time(&args);
    time_t current_time;
    time(&current_time);
    
    // In exact mode, the reference should be very close to current time - 1 day
    double diff_seconds = difftime(current_time, reference_time);
    double diff_hours = diff_seconds / (60 * 60);
    
    // Should be approximately 24 hours (allow ±1 hour for execution time)
    XCTAssertTrue(diff_hours >= 23 && diff_hours <= 25,
                  @"Exact mode reference time should be approximately 24 hours ago, got %.1f hours", diff_hours);
}

- (void)testCalculateReferenceTimeNonExactMode {
    arguments_t args = {0};
    args.filepath = "/tmp/test.txt";
    args.days = 1;
    args.has_days = 1;
    args.exact_mode = 0; // Default non-exact mode
    
    time_t reference_time = calculate_reference_time(&args);
    struct tm *ref_tm = localtime(&reference_time);
    
    // In non-exact mode, time should be set to end of previous day (23:59:59)
    XCTAssertEqual(ref_tm->tm_hour, 23, @"Non-exact mode should use 23:59:59 of previous day");
    XCTAssertEqual(ref_tm->tm_min, 59, @"Non-exact mode should use 23:59:59 of previous day");
    XCTAssertEqual(ref_tm->tm_sec, 59, @"Non-exact mode should use 23:59:59 of previous day");
}

#pragma mark - Edge Case Tests

- (void)testFebruary29BoundaryConditions {
    // Test various February 29 scenarios
    
    // 1. February 29, 2020 + 1 year = February 28, 2021
    struct tm leap_tm = {0};
    leap_tm.tm_year = 2020 - 1900;
    leap_tm.tm_mon = 1; // February
    leap_tm.tm_mday = 29;
    time_t leap_time = mktime(&leap_tm);
    
    time_t result1 = add_years_to_time(leap_time, 1);
    struct tm *result1_tm = localtime(&result1);
    XCTAssertEqual(result1_tm->tm_mday, 28, @"Feb 29 + 1 year should become Feb 28 in non-leap year");
    
    // 2. February 29, 2020 + 4 years = February 29, 2024
    time_t result2 = add_years_to_time(leap_time, 4);
    struct tm *result2_tm = localtime(&result2);
    XCTAssertEqual(result2_tm->tm_mday, 29, @"Feb 29 + 4 years should remain Feb 29 in leap year");
}

- (void)testMonthEndBoundaryConditions {
    // Test adding months to month-end dates
    
    // January 31 + 1 month = February 28/29
    struct tm jan31_tm = {0};
    jan31_tm.tm_year = 2023 - 1900;
    jan31_tm.tm_mon = 0; // January
    jan31_tm.tm_mday = 31;
    time_t jan31_time = mktime(&jan31_tm);
    
    time_t feb_result = add_months_to_time(jan31_time, 1);
    struct tm *feb_tm = localtime(&feb_result);
    XCTAssertEqual(feb_tm->tm_mday, 28, @"Jan 31 + 1 month should become Feb 28 in 2023");
    
    // March 31 + 1 month = April 30
    struct tm mar31_tm = {0};
    mar31_tm.tm_year = 2023 - 1900;
    mar31_tm.tm_mon = 2; // March
    mar31_tm.tm_mday = 31;
    time_t mar31_time = mktime(&mar31_tm);
    
    time_t apr_result = add_months_to_time(mar31_time, 1);
    struct tm *apr_tm = localtime(&apr_result);
    XCTAssertEqual(apr_tm->tm_mday, 30, @"Mar 31 + 1 month should become Apr 30");
}

- (void)testCenturyBoundaryConditions {
    // Test calculations across century boundaries
    
    // December 31, 1999 + 1 year = December 31, 2000
    struct tm century_tm = {0};
    century_tm.tm_year = 1999 - 1900;
    century_tm.tm_mon = 11; // December
    century_tm.tm_mday = 31;
    time_t century_time = mktime(&century_tm);
    
    time_t result = add_years_to_time(century_time, 1);
    struct tm *result_tm = localtime(&result);
    
    XCTAssertEqual(result_tm->tm_year, 2000 - 1900, @"Century boundary should be handled correctly");
    XCTAssertEqual(result_tm->tm_mon, 11, @"Month should remain December");
    XCTAssertEqual(result_tm->tm_mday, 31, @"Day should remain 31");
}

@end
