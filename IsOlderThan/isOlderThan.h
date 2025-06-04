//
//  isOlderThan.h
//  IsOlderThan
//
//  Created by Christian Kropfberger on 04.06.25.
//

/*
 * isOlderThan.h - Header file for isOlderThan file age verification tool
 *
 * Purpose: Function prototypes and constants for the isOlderThan program
 * Author: C Programming Expert
 * Language: C (C99 Standard)
 * Platforms: Unix, Linux, Mac, Windows
 */

#ifndef ISOLDERTHAN_H
#define ISOLDERTHAN_H

#include <time.h>

/* Constants and Defaults */
#define DEFAULT_MONTHS 6
#define MAX_MONTHS_WITH_YEARS 11
#define SECONDS_PER_DAY 86400
#define DAYS_PER_WEEK 7
#define VERSION "1.0"

/* Error Codes */
#define SUCCESS 0
#define ERROR_INVALID_ARGS 1
#define ERROR_FILE_NOT_FOUND 2
#define ERROR_FILE_ACCESS 3
#define ERROR_INVALID_COMBINATION 4
#define ERROR_INVALID_VALUE 5

/* Structure to hold parsed command line arguments */
typedef struct {
    char *filepath;
    int days;
    int weeks;
    int months;
    int years;
    int exact_mode;
    int has_days;
    int has_weeks;
    int has_months;
    int has_years;
} arguments_t;

/* Function Prototypes */

/* Main program functions - exposed for testing */
void print_usage(const char *program_name);
int parse_arguments(int argc, char *argv[], arguments_t *args);
int validate_arguments(const arguments_t *args);

/* File operations - exposed for testing */
time_t get_file_modification_time(const char *filepath);

/* Time calculation functions - exposed for testing */
time_t calculate_reference_time(const arguments_t *args);
int is_leap_year(int year);
int get_days_in_month(int month, int year);
time_t add_months_to_time(time_t base_time, int months);
time_t add_years_to_time(time_t base_time, int years);

/* Utility functions - exposed for testing */
const char *get_error_message(int error_code);

/* Testing-specific declarations */
#ifdef TESTING
/* When TESTING is defined, we declare these as external functions
   that will be linked from the test object files */
extern int isOlderThan_main(int argc, char *argv[]);
#endif

#endif /* ISOLDERTHAN_H */
