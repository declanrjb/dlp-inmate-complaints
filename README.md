# Overview
Initial stages of volunteer data cleaning for the Data Liberation Project's Federal Inmate Complaints dataset.

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

Facility information obtained from most fac codes in current use, but further scraping will be required to get information for old fac codes stored in raw_data/bop-facility-codes-scraped.csv