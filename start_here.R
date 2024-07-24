# load in helper functions. Performs no actual actions
source('code/functions.R')

# scrape in facility data from the BOP's website
# write it to data processing
# (finicky reprocessing of live site, unless necessary just use the data that's 
# already been scraped and written to data_processing/fac_all_data_raw.csv)
#source('code/scrape.R')

# clean up that facility data and merge it with the official facility codes
# results in thorough information about facilities, their codes, names, and locations
# write it to clean_data/facilities/facility-locations.csv
source('code/fac_clean.R')

# now we have facility data in clean data, and inmate complaints in raw data
# clean up the complaint data, then merge it with the facility data
source('code/merge.R')

# yielding complete clean data on all complaints in clean_data