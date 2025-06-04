//
//  main.c (formerly isOlderThan.c)
//  IsOlderThan
//
//  Created by Christian Kropfberger on 03.06.25.
//

/*
 * isOlderThan - File Age Verification Tool
 *
 * Purpose: Checks if a file is older than specified time parameters
 * Default: 6 months if no time specification provided
 *
 * Author: C Programming Expert
 * Language: C (C99 Standard)
 * Platforms: Unix, Linux, Mac, Windows
 *
 * Compilation: Use provided Makefile or: gcc -std=c99 -Wall -Wextra -o isOlderThan isOlderThan.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <limits.h>     // Für INT_MAX, INT_MIN etc.

#ifdef _WIN32
    #include <windows.h>
    #define PATH_SEPARATOR '\\'
#else
    #define PATH_SEPARATOR '/'
#endif

// Include our header file
#include "isOlderThan.h"

/**
 * Print program usage information
 *
 * @param program_name Name of the executable
 */
void print_usage(const char *program_name) {
    printf("Usage: %s <filepath> [options]\n\n", program_name);
    printf("Checks if a file is older than specified time period.\n");
    printf("Default: 6 months if no time specification provided.\n\n");
    
    printf("Required parameter:\n");
    printf("  <filepath>        Path to file to check\n\n");
    
    printf("Optional parameters:\n");
    printf("  -days <count>     Number of days (excludes other time parameters)\n");
    printf("  -weeks <count>    Number of weeks (excludes other time parameters)\n");
    printf("  -months <count>   Number of months (can combine with -years, max 11)\n");
    printf("  -years <count>    Number of years (can combine with -months)\n");
    printf("  -exact            Use exact current time instead of end of previous day\n\n");
    
    printf("Parameter rules:\n");
    printf("  - -days excludes all other time parameters\n");
    printf("  - -weeks excludes all other time parameters\n");
    printf("  - -months can be combined with -years (max 11 months)\n");
    printf("  - Default mode: end of previous day reference\n");
    printf("  - -exact mode: current program execution time reference\n\n");
    
    printf("Exit codes:\n");
    printf("  0: File is older than specified period\n");
    printf("  1: Invalid arguments or file is not older\n");
    printf("  2: File not found\n");
    printf("  3: File access error\n");
    printf("  4: Invalid parameter combination\n");
    printf("  5: Invalid parameter value\n");
}

/**
 * Parse command line arguments
 *
 * @param argc Argument count
 * @param argv Argument vector
 * @param args Pointer to arguments structure to fill
 * @return Error code (SUCCESS or error)
 */
int parse_arguments(int argc, char *argv[], arguments_t *args) {
    /* Initialize structure */
    memset(args, 0, sizeof(arguments_t));
    
    if (argc < 2) {
        fprintf(stderr, "Error: File path is required\n");
        return ERROR_INVALID_ARGS;
    }
    
    args->filepath = argv[1];
    
    /* Parse optional parameters */
    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "-days") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Error: -days requires a value\n");
                return ERROR_INVALID_ARGS;
            }
            
            // VERBESSERT: Verwende strtol() statt atoi() für bessere Validierung
            char *endptr;
            long val = strtol(argv[++i], &endptr, 10);
            
            // Prüfe ob kompletter String eine Zahl war
            if (*endptr != '\0') {
                fprintf(stderr, "Error: -days value must be a number\n");
                return ERROR_INVALID_VALUE;
            }
            
            // Prüfe Bereich
            if (val <= 0 || val > INT_MAX) {
                fprintf(stderr, "Error: -days value out of range (1-%d)\n", INT_MAX);
                return ERROR_INVALID_VALUE;
            }
            
            args->days = (int)val;
            args->has_days = 1;
        }
        else if (strcmp(argv[i], "-weeks") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Error: -weeks requires a value\n");
                return ERROR_INVALID_ARGS;
            }
            
            // VERBESSERT: Gleiche Validierung für weeks
            char *endptr;
            long val = strtol(argv[++i], &endptr, 10);
            
            if (*endptr != '\0') {
                fprintf(stderr, "Error: -weeks value must be a number\n");
                return ERROR_INVALID_VALUE;
            }
            
            if (val <= 0 || val > INT_MAX) {
                fprintf(stderr, "Error: -weeks value out of range\n");
                return ERROR_INVALID_VALUE;
            }
            
            args->weeks = (int)val;
            args->has_weeks = 1;
        }
        else if (strcmp(argv[i], "-months") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Error: -months requires a value\n");
                return ERROR_INVALID_ARGS;
            }
            
            // VERBESSERT: Gleiche Validierung für months
            char *endptr;
            long val = strtol(argv[++i], &endptr, 10);
            
            if (*endptr != '\0') {
                fprintf(stderr, "Error: -months value must be a number\n");
                return ERROR_INVALID_VALUE;
            }
            
            if (val <= 0 || val > INT_MAX) {
                fprintf(stderr, "Error: -months value out of range\n");
                return ERROR_INVALID_VALUE;
            }
            
            args->months = (int)val;
            args->has_months = 1;
        }
        else if (strcmp(argv[i], "-years") == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Error: -years requires a value\n");
                return ERROR_INVALID_ARGS;
            }
            
            // VERBESSERT: Gleiche Validierung für years
            char *endptr;
            long val = strtol(argv[++i], &endptr, 10);
            
            if (*endptr != '\0') {
                fprintf(stderr, "Error: -years value must be a number\n");
                return ERROR_INVALID_VALUE;
            }
            
            if (val <= 0 || val > 1000) { // VERBESSERT: Praktisches Limit für Jahre
                fprintf(stderr, "Error: -years value out of range (1-1000)\n");
                return ERROR_INVALID_VALUE;
            }
            
            args->years = (int)val;
            args->has_years = 1;
        }
        else if (strcmp(argv[i], "-exact") == 0) {
            args->exact_mode = 1;
        }
        else {
            fprintf(stderr, "Error: Unknown parameter: %s\n", argv[i]);
            return ERROR_INVALID_ARGS;
        }
    }
    
    return SUCCESS;
}

/**
 * Validate argument combinations according to specification
 *
 * @param args Parsed arguments structure
 * @return Error code (SUCCESS or error)
 */
int validate_arguments(const arguments_t *args) {
    /* Check mutual exclusivity rules */
    if (args->has_days && (args->has_weeks || args->has_months || args->has_years)) {
        fprintf(stderr, "Error: -days excludes all other time parameters\n");
        return ERROR_INVALID_COMBINATION;
    }
    
    if (args->has_weeks && (args->has_days || args->has_months || args->has_years)) {
        fprintf(stderr, "Error: -weeks excludes all other time parameters\n");
        return ERROR_INVALID_COMBINATION;
    }
    
    /* Check months + years combination rule */
    if (args->has_months && args->has_years && args->months > MAX_MONTHS_WITH_YEARS) {
        fprintf(stderr, "Error: When combined with -years, -months can have maximum value of %d\n",
                MAX_MONTHS_WITH_YEARS);
        return ERROR_INVALID_COMBINATION;
    }
    
    // VERBESSERT: Zusätzliche Vernünftigkeitsprüfungen
    if (args->has_days && args->days > 365000) { // ~1000 Jahre in Tagen
        fprintf(stderr, "Error: -days value too large (max ~365000)\n");
        return ERROR_INVALID_VALUE;
    }
    
    if (args->has_weeks && args->weeks > 52000) { // ~1000 Jahre in Wochen
        fprintf(stderr, "Error: -weeks value too large (max ~52000)\n");
        return ERROR_INVALID_VALUE;
    }
    
    if (args->has_months && args->months > 12000) { // ~1000 Jahre in Monaten
        fprintf(stderr, "Error: -months value too large (max ~12000)\n");
        return ERROR_INVALID_VALUE;
    }
    
    return SUCCESS;
}

/**
 * Get file modification time using platform-appropriate method
 *
 * @param filepath Path to the file
 * @return File modification time as time_t, or -1 on error
 */
time_t get_file_modification_time(const char *filepath) {
    struct stat file_stat;
    
    if (stat(filepath, &file_stat) != 0) {
        if (errno == ENOENT) {
            fprintf(stderr, "Error: File not found: %s\n", filepath);
        } else {
            fprintf(stderr, "Error: Cannot access file: %s (%s)\n", filepath, strerror(errno));
        }
        return -1;
    }
    
    return file_stat.st_mtime;
}

/**
 * Check if a year is a leap year
 * Implements Gregorian calendar leap year rules
 *
 * @param year Year to check
 * @return 1 if leap year, 0 otherwise
 */
int is_leap_year(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

/**
 * Get number of days in a specific month of a specific year
 * Accounts for leap years in February
 *
 * @param month Month (1-12)
 * @param year Year
 * @return Number of days in the month
 */
int get_days_in_month(int month, int year) {
    static const int days_per_month[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    
    if (month < 1 || month > 12) return 0;
    
    if (month == 2 && is_leap_year(year)) {
        return 29;
    }
    
    return days_per_month[month - 1];
}

/**
 * Add months to a time_t value with proper calendar arithmetic
 * Handles varying month lengths and leap years correctly
 *
 * @param base_time Starting time
 * @param months Number of months to add
 * @return New time_t value
 */
time_t add_months_to_time(time_t base_time, int months) {
    if (months == 0) return base_time;
    
    struct tm *tm_struct = localtime(&base_time);
    if (!tm_struct) return -1;
    
    /* Copy to avoid modifying original */
    struct tm new_tm = *tm_struct;
    
    /* Add months */
    new_tm.tm_mon += months;
    
    /* Normalize year overflow */
    while (new_tm.tm_mon >= 12) {
        new_tm.tm_year++;
        new_tm.tm_mon -= 12;
        
        if (new_tm.tm_year > 1100) return -1; // Jahr > 3000
    }
    
    /* Normalize negative months */
    while (new_tm.tm_mon < 0) {
        new_tm.tm_year--;
        new_tm.tm_mon += 12;
        
        if (new_tm.tm_year < -1900) return -1; // Jahr < 0
    }
    
    /* Handle day overflow for shorter months */
    int days_in_new_month = get_days_in_month(new_tm.tm_mon + 1, new_tm.tm_year + 1900);
    if (days_in_new_month == 0) return -1; // Ungültiger Monat
    
    if (new_tm.tm_mday > days_in_new_month) {
        new_tm.tm_mday = days_in_new_month;
    }
    
    time_t result = mktime(&new_tm);
    return result;
}

/**
 * Add years to a time_t value with proper calendar arithmetic
 * Handles leap year boundary conditions
 *
 * @param base_time Starting time
 * @param years Number of years to add
 * @return New time_t value
 */
time_t add_years_to_time(time_t base_time, int years) {
    if (years == 0) return base_time;
    
    struct tm *tm_struct = localtime(&base_time);
    if (!tm_struct) return -1;
    
    struct tm new_tm = *tm_struct;
    
    if (abs(years) > 100) {
        time_t result = base_time;
        int remaining = years;
        int step = (years > 0) ? 50 : -50;
        
        while (abs(remaining) > 50) {
            result = add_years_to_time(result, step);
            if (result == -1) return -1; // mktime Fehler
            remaining -= step;
        }
        
        if (remaining != 0) {
            result = add_years_to_time(result, remaining);
        }
        return result;
    }
    
    new_tm.tm_year += years;
    
    if (new_tm.tm_year < -1900 || new_tm.tm_year > 1100) { // Jahr 0-3000
        return -1; // Unrealistisches Datum
    }
    
    /* Handle February 29 on non-leap years */
    if (new_tm.tm_mon == 1 && new_tm.tm_mday == 29 && !is_leap_year(new_tm.tm_year + 1900)) {
        new_tm.tm_mday = 28;
    }
    
    time_t result = mktime(&new_tm);
    return result;
}

/**
 * Calculate reference time based on arguments and exact mode
 *
 * @param args Parsed arguments
 * @return Reference time for comparison
 */
time_t calculate_reference_time(const arguments_t *args) {
    time_t current_time;
    time(&current_time);
    
    time_t reference_time;
    
    if (args->exact_mode) {
        /* Use exact current time */
        reference_time = current_time;
    } else {
        /* Use end of previous day */
        struct tm *tm_struct = localtime(&current_time);
        if (!tm_struct) return -1;
        
        tm_struct->tm_hour = 23;
        tm_struct->tm_min = 59;
        tm_struct->tm_sec = 59;
        tm_struct->tm_mday -= 1;  /* Previous day */
        reference_time = mktime(tm_struct);
        
        if (reference_time == -1) return -1;
    }
    
    /* Calculate target time based on parameters */
    time_t target_time = reference_time;
    
    if (args->has_days) {
        // VERBESSERT: Prüfe auf Overflow bei sehr großen Tageswerten
        if (args->days > (INT_MAX / SECONDS_PER_DAY)) {
            return -1; // Overflow würde auftreten
        }
        target_time -= (time_t)args->days * SECONDS_PER_DAY;
    }
    else if (args->has_weeks) {
        // VERBESSERT: Prüfe auf Overflow bei sehr großen Wochenwerten
        if (args->weeks > (INT_MAX / (DAYS_PER_WEEK * SECONDS_PER_DAY))) {
            return -1; // Overflow würde auftreten
        }
        target_time -= (time_t)args->weeks * DAYS_PER_WEEK * SECONDS_PER_DAY;
    }
    else if (args->has_months || args->has_years) {
        /* Handle months and years with proper calendar arithmetic */
        if (args->has_years) {
            target_time = add_years_to_time(target_time, -args->years);
            if (target_time == -1) return -1; // Fehler bei Jahr-Berechnung
        }
        if (args->has_months) {
            target_time = add_months_to_time(target_time, -args->months);
            if (target_time == -1) return -1; // Fehler bei Monat-Berechnung
        }
    }
    else {
        /* Default: 6 months */
        target_time = add_months_to_time(target_time, -DEFAULT_MONTHS);
        if (target_time == -1) return -1; // Fehler bei Default-Berechnung
    }
    
    return target_time;
}

/**
 * Get human-readable error message for error code
 *
 * @param error_code Error code
 * @return Error message string
 */
const char *get_error_message(int error_code) {
    switch (error_code) {
        case SUCCESS: return "Success";
        case ERROR_INVALID_ARGS: return "Invalid arguments";
        case ERROR_FILE_NOT_FOUND: return "File not found";
        case ERROR_FILE_ACCESS: return "File access error";
        case ERROR_INVALID_COMBINATION: return "Invalid parameter combination";
        case ERROR_INVALID_VALUE: return "Invalid parameter value";
        default: return "Unknown error";
    }
}

/**
 * Main program entry point
 * When testing, this function is exposed as isOlderThan_main
 *
 * @param argc Argument count
 * @param argv Argument vector
 * @return Exit code
 */
int isOlderThan_main(int argc, char *argv[]) {
    arguments_t args;
    int result;
    
    /* Parse command line arguments */
    result = parse_arguments(argc, argv, &args);
    if (result != SUCCESS) {
        if (result == ERROR_INVALID_ARGS && argc < 2) {
            print_usage(argv[0]);
        }
        return result;
    }
    
    /* Validate argument combinations */
    result = validate_arguments(&args);
    if (result != SUCCESS) {
        return result;
    }
    
    /* Get file modification time */
    time_t file_time = get_file_modification_time(args.filepath);
    if (file_time == -1) {
        return (errno == ENOENT) ? ERROR_FILE_NOT_FOUND : ERROR_FILE_ACCESS;
    }
    
    /* Calculate reference time */
    time_t reference_time = calculate_reference_time(&args);
    
    // VERBESSERT: Bessere Fehlerbehandlung für extreme Werte
    if (reference_time == -1) {
        fprintf(stderr, "Error: Cannot calculate reference time (values too extreme)\n");
        return ERROR_INVALID_VALUE;
    }
    
    /* Compare times */
    if (file_time < reference_time) {
        /* File is older than specified period */
        printf("File '%s' is older than specified period\n", args.filepath);
        
        /* Optional: Print detailed time information */
        char file_time_str[64], ref_time_str[64];
        struct tm *file_tm = localtime(&file_time);
        struct tm *ref_tm = localtime(&reference_time);
        
        if (file_tm && ref_tm) { // VERBESSERT: Prüfe localtime() Erfolg
            strftime(file_time_str, sizeof(file_time_str), "%Y-%m-%d %H:%M:%S", file_tm);
            strftime(ref_time_str, sizeof(ref_time_str), "%Y-%m-%d %H:%M:%S", ref_tm);
            
            printf("File modified: %s\n", file_time_str);
            printf("Reference time: %s\n", ref_time_str);
        }
        
        return SUCCESS;
    } else {
        /* File is not older than specified period */
        printf("File '%s' is NOT older than specified period\n", args.filepath);
        return ERROR_INVALID_ARGS;  /* Using as "not older" indicator */
    }
}
