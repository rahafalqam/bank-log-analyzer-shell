# bank-log-analyzer-
A Bash script to analyze bank server logs and generate reports


# Bank Log Analyzer

## Project Description
Bank Log Analyzer is a Bash-based tool designed to analyze bank server log files and generate useful reports about system activity, authentication events, database queries, and transactions.

## Features
- Failed Login Report
- Query Activity Summary
- Slow Query Detector
- Transaction Report
- Critical Events Report
- User Activity Report
- Session Report
- Events Per Hour Report
- General Log Summary
- Run All Reports

## Project Files
- `analyzer.sh` — Main Bash script containing the analysis functions and interactive menu.
- `bank_server.log` — Sample bank server log data used for analysis.

## Requirements
- Bash shell
- Standard Unix/Linux command-line utilities
- `grep`, `cut`, `sort`, `uniq`, `awk`, and `wc`
- A compatible `date` command for session duration calculations

## How to Run

Place `analyzer.sh` and `bank_server.log` in the same directory.

Run:

```bash
chmod +x analyzer.sh
./analyzer.sh
```

Follow the interactive menu to select a report.
