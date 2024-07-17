source('functions.R')

fac_codes <- read_csv('raw_data/facility-codes.csv')
fac_data <- read_csv('data_processing/fac_all_data_raw.csv')
arch_fac_data <- read_csv('raw_data/bop-facility-codes-scraped.csv')

drop_fixes <- c('FCI','USP')

fac_df <- left_join(fac_codes,fac_data,by=c('facility_code' = 'Code'))

fac_df <- fac_df %>%
  select(facility_code,
         facility_type,
         facility_name,
         URL,
         Fac_Name,
         Fac_Address,
         Fac_Pop_Gender,
         Fac_Pop_Count)

write.csv(fac_df,'clean_data/fac-details_in-progress.csv',row.names=FALSE)