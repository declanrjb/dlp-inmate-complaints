# Overview
Initial stages of volunteer data cleaning for the Data Liberation Project's Federal Inmate Complaints dataset.

# Locations
Found this https://www.corecivic.com/facilities
Appears to show locations of private prisons that match some of the records in the complaints dataset
Going to attempt a download and merge to find out how much they overlap

# Large Files
Drive folder with large files that cannot be stored on GitHub
https://drive.google.com/drive/folders/1yhVTG_iZfAWIbg349VBOGRQkMGYL79Za?usp=sharing

# Proposed Changes / Additions to the Documentation
Google Doc containing notes on columns added or altered during this process:
https://docs.google.com/document/d/1fYZagz3RH4Ba4Tf3P3nh5ShAD99DzArc0u9YwjcQ4lI/edit?usp=sharing

# Steps Taken
Overall, the dataset was reduced from 37 columns to 19 after dropping redundant and/or derived columns. No rows were dropped at this stage.

Wherever possible, esoteric codes were replaced with their human-readable equivalents according to dictionaries provided by the BOP.
This alteration was not performed if a) doing so would make the data less readable or less easy or to understand, b) no such dictionaries
were available, or c) there was any doubt about the accuracy of such a translation.

Status Reasons were collapsed into a single column with a comma-separated list, although the original five separate columns
for this data were also retained.

# Further Work
Immediate next steps will be to scrape futher geographic and descriptive information about each facility from BOP webpages such as https://www.bop.gov/locations/institutions/ald/ and bind them in using the facility codes.

Facility information obtained from most fac codes in current use, but further scraping will be required to get information for old fac codes stored in `data/raw/bop-facility-codes-scraped.csv`

# Code

The `code` directory contains the following scripts:

- `scrape.R`: Scrapes facility information from [BOP's website](https://www.bop.gov/mobile/locations/). 
- `fac_clean.R`: Creates `data/clean/facilities/facility-locations.csv`, based on data provided by BOP via FOIA and online, as well as ZIP code metadata and geocoding results.
- `merge.R`: Reads the raw complaints data, merges it with the facility data, expands status and subject codes, and removes redundant columns, writing the results to output files in `data/clean`. 
- `private_facs.R`: A work in progress to obtain information about privately-run facilities; not yet used in the results.
- `functions.R`: Contains various helper functions used in the scripts above.

# Reproducibility

The code in this repository requires `R` to be installed on your computer.

To run the main data cleaning and merging steps, run `make data` or:

```sh
Rscript code/fac_clean.R
Rscript code/merge.R
```

