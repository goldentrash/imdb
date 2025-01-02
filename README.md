# IMDb Dataset Utilities

Command-line utilities for downloading and importing IMDb's non-commercial datasets into a MySQL database.

## Configuration

Edit `setup.sh` to configure:

- MySQL connection details
- Directory paths
- Retry settings
- Dataset list

## Notes

Large datasets may take significant time to download and import
Monitor disk space and MySQL server load
Check MySQL error log for detailed import issues

## NOTICE

This script was created with the assistance of Claude AI (Anthropic).
This implementation is based on IMDb's non-commercial datasets as of January 2025.
Future changes to the IMDb dataset structure may render this script obsolete.

### Created

January 2, 2025

### PURPOSE

This code is intended for educational purposes only and is not for commercial use.

### DATA SOURCE

This dataset is available for non-commercial use.
Please refer to [IMDb](https://developer.imdb.com/non-commercial-datasets/)'s official documentation for the most up-to-date dataset structure.
