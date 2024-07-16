library(tidyverse)

paste_not_na <- function(vec) {
  vec <- vec[!is.na(vec)]
  return(paste(vec,collapse=', '))
}

# overview
# reduced 37 columns to 19 by eliminating redundancies
# bound in 

df <- read_csv('raw_data/complaint-filings.csv')

facilities_df <- read_csv('raw_data/facility-codes.csv')
facility_names <- facilities_df %>% select(facility_code,facility_name)
subject_codes <- read_csv('raw_data/subject-codes.csv')

# OTH collapsed to 'OTHER* / SEE REMARKS'
# this should be reflected clearly in the documentation
status_reason_codes <- read_csv('raw_data/status_reason_codes.csv')

status_reason_codes$STATUS_REASON <- paste(status_reason_codes$STATUS_REASON,' (',status_reason_codes$STATUS_CODE,')',sep='')

df <- df %>% rename(Case_Number = CASENBR)

# replace level codes with human readable org levels
df <- df %>% mutate(
  Org_Level = gsub('F','Facility',ITERLVL),
  Org_Level = gsub('R','Region',Org_Level),
  Org_Level = gsub('A','Agency',Org_Level)
) %>%
  select(!ITERLVL)

# bind in facility occurred names
df <- left_join(df,
                facility_names %>% rename(Facility_Occurred_NM = facility_name),
                by=c('CDFCLEVN' = 'facility_code')) %>%
  rename(Facility_Occurred_CODE = CDFCLEVN)
# where no name translation is available, use the code. Otherwise use the name
df['Facility_Occurred'] <- ifelse(is.na(df$Facility_Occurred_NM), df$Facility_Occurred_CODE, df$Facility_Occurred_NM)
# drop the two input columns, having collapsed them
df <- df %>% 
  select(!Facility_Occurred_CODE) %>%
  select(!Facility_Occurred_NM)

# bind in facility received name
df <- left_join(df,
                facility_names %>% rename(Facility_Received_NM = facility_name),
                by=c('CDFCLRCV' = 'facility_code')) %>%
  rename(Facility_Received_CODE = CDFCLRCV)
# where no name translation is available, use the code. Otherwise use the name
df['Facility_Received'] <- ifelse(is.na(df$Facility_Received_NM), df$Facility_Received_CODE, df$Facility_Received_NM)
# drop the two input columns, having collapsed them
df <- df %>%
  select(!Facility_Received_CODE) %>%
  select(!Facility_Received_NM)

# translate status code to human readable, then drop redundant binary columns
df <- df %>% mutate(
  Case_Status = gsub('ACC','Accepted',CDSTATUS),
  Case_Status = gsub('REJ','Rejected',Case_Status),
  Case_Status = gsub('CLD','Closed Denied',Case_Status),
  Case_Status = gsub('CLG','Closed Granted',Case_Status),
  Case_Status = gsub('CLO','Closed Other',Case_Status),
) %>%
  select(!CDSTATUS) %>%
  select(!reject) %>%
  select(!deny) %>%
  select(!other) %>%
  select(!grant) %>%
  select(!accept)

# translate to human readable column name
df <- df %>% rename(Received_Office = CDOFCRCV)

# translate to human readable column names
df <- df %>%
  rename(STAT_RSON_1 = STATRSN1) %>%
  rename(STAT_RSON_2 = STATRSN2) %>%
  rename(STAT_RSON_3 = STATRSN3) %>%
  rename(STAT_RSON_4 = STATRSN4) %>%
  rename(STAT_RSON_5 = STATRSN5)

# join in primary and secondary descriptions and then drop redundant columns
df <- df %>% left_join(subject_codes %>% select(code,primary_desc,secondary_desc),
                 by=c('cdsub1cb' = 'code')) %>%
  rename(Subject_Primary_DESC = primary_desc) %>%
  rename(Subject_Secondary_DESC = secondary_desc) %>%
  select(!CDSUB1PR) %>%
  select(!CDSUB1SC) %>%
  select(!cdsub1cb)

# unnecessary column, value is 1 for all rows in dataset
df <- df %>% select(!submit)

# derive from Case_Status (CDSTATUS). See docs
df <- df %>% select(!filed) %>% select(!closed)

# add units for clarity
df <- df %>% select(!comptime)

df['Status_Reasons'] <- df[,which(colnames(df) %in% c('STAT_RSON_1',
                              'STAT_RSON_2',
                              'STAT_RSON_3',
                              'STAT_RSON_4',
                              'STAT_RSON_5'))] %>%
  apply(1,paste_not_na)

# remove redundant / obscure columns
df <- df %>% 
  select(!diffreg_filed) %>%
  select(!diffinst) %>%
  select(!timely) %>%
  select(!untimely) %>%
  select(!resubmit) %>%
  select(!noinfres) %>%
  select(!attachmt) %>%
  select(!wronglvl) %>%
  select(!otherrej) %>%
  select(!diffreg_answer) %>%
  select(!overdue)

# choosing to keep comptime. It derives from sitdtrcv and sdtstat, but seems so manifestly useful
# that removing it would simply create extra work for most analysts

# bind in the human readable status reasons
# reverted to reduce file size
# df <- df %>% left_join(status_reason_codes,
#                  by=c('STAT_RSON_1' = 'STATUS_CODE')) %>%
#   select(!STAT_RSON_1) %>%
#   rename(STAT_RSON_1 = STATUS_REASON)
# 
# df <- df %>% left_join(status_reason_codes,
#                        by=c('STAT_RSON_2' = 'STATUS_CODE')) %>%
#   select(!STAT_RSON_2) %>%
#   rename(STAT_RSON_2 = STATUS_REASON)
# 
# df <- df %>% left_join(status_reason_codes,
#                        by=c('STAT_RSON_3' = 'STATUS_CODE')) %>%
#   select(!STAT_RSON_3) %>%
#   rename(STAT_RSON_3 = STATUS_REASON)
# 
# df <- df %>% left_join(status_reason_codes,
#                        by=c('STAT_RSON_4' = 'STATUS_CODE')) %>%
#   select(!STAT_RSON_4) %>%
#   rename(STAT_RSON_4 = STATUS_REASON)
# 
# df <- df %>% left_join(status_reason_codes,
#                        by=c('STAT_RSON_5' = 'STATUS_CODE')) %>%
#   select(!STAT_RSON_5) %>%
#   rename(STAT_RSON_5 = STATUS_REASON)

# collapse status reasons to a single column
#df <- df %>% select(!Status_Reasons)
df <- df %>%
  select(!STAT_RSON_1) %>%
  select(!STAT_RSON_2) %>%
  select(!STAT_RSON_3) %>%
  select(!STAT_RSON_4) %>%
  select(!STAT_RSON_5)

# rearrange columns for readability
df <- df %>% select(Case_Number,
                    Case_Status,
                    Subject_Primary_DESC,
                    Subject_Secondary_DESC,
                    Org_Level,
                    Received_Office,
                    Facility_Occurred,
                    Facility_Received,
                    sdtdue,
                    sdtstat,
                    sitdtrcv,
                    Status_Reasons)

df_2000_09 <- df %>% 
  filter(year(sitdtrcv) %in% 2000:2009)

df_2010_19 <- df %>% 
  filter(year(sitdtrcv) %in% 2010:2019)

df_2020_24 <- df %>% 
  filter(year(sitdtrcv) %in% 2020:2024)

write.csv(df,'clean_data/all_complaint-filings_clean.csv',row.names=FALSE, na='')

write.csv(df_2000_09,'clean_data/complaint-filings_2000-2009_clean.csv',row.names=FALSE, na='')
write.csv(df_2010_19,'clean_data/complaint-filings_2010-2019_clean.csv',row.names=FALSE, na='')
write.csv(df_2020_24,'clean_data/complaint-filings_2020-2024_clean.csv',row.names=FALSE, na='')


