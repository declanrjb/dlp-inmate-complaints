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

fac_df <- fac_df %>%
  select(facility_code,
         facility_name,
         Fac_Address) %>%
  filter(!is.na(Fac_Address))

osm_coded <- fac_df %>%
  geocode(address = Fac_Address, method = "osm", verbose = TRUE)

census_coded <- fac_df %>%
  geocode(address = Fac_Address, method = "census", verbose = TRUE)

census_missing <- census_coded %>% filter(is.na(lat)) %>% pull(facility_code)

osm_fixed <- osm_coded %>% 
  filter(facility_code %in% census_missing) %>% 
  filter(!is.na(lat)) %>% 
  pull(facility_code)

census_coded <- rbind(census_coded %>% filter(!(facility_code %in% osm_fixed)),
                      osm_coded %>% filter(facility_code %in% osm_fixed))

fac_df <- census_coded

fac_df['zipcode'] <- fac_df %>%
  pull(Fac_Address) %>%
  str_split_i(' ',-1)

fac_df <- fac_df %>%
  pull(zipcode) %>%
  lapply(reverse_zipcode) %>%
  do.call(rbind,.) %>%
  select(zipcode,major_city,state) %>%
  unique() %>%
  left_join(fac_df,.,by='zipcode') %>%
  select(!zipcode) %>%
  rename(city = major_city)

fac_df <- left_join(fac_codes,fac_df,by=c('facility_code','facility_name'))

fac_df <- fac_df %>%
  select(facility_name,
         Fac_Address,
         lat,
         long,
         city,
         state)

colnames(fac_df) <- str_to_title(colnames(fac_df))
fac_df <- fac_df %>% 
  rename(Facility_Name = Facility_name) %>%
  rename(Facility_Address = Fac_address)

write.csv(fac_df,'clean_data/facilities/facility-locations.csv',row.names=FALSE)
