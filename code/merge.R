library(tidyverse)
source("code/functions.R")

df <- read_parquet("raw_data/complaint-filings.parquet")

facilities_df <- read_csv("raw_data/facility-codes.csv")
facility_names <- facilities_df %>% select(facility_code, facility_name)
subject_codes <- read_csv("raw_data/subject-codes.csv")

df <- df %>% rename(Case_Number = CASENBR)

# Replace level codes with human readable org levels
df <- df %>%
  mutate(
    Org_Level = gsub("F", "Facility", ITERLVL),
    Org_Level = gsub("R", "Region", Org_Level),
    Org_Level = gsub("A", "Agency", Org_Level)
  ) %>%
  select(!ITERLVL)

# Bind in facility occurred names
df <- left_join(df,
  facility_names %>% rename(Facility_Occurred_NM = facility_name),
  by = c("CDFCLEVN" = "facility_code")
) %>%
  rename(Facility_Occurred_CODE = CDFCLEVN)

# Where no name translation is available, use the code;
# otherwise use the name.
df["Facility_Occurred"] <- ifelse(is.na(df$Facility_Occurred_NM), df$Facility_Occurred_CODE, df$Facility_Occurred_NM)


# Bind in facility locations
facility_info <- read_csv("clean_data/facilities/facility-locations.csv")

# 78% coverage on lat long
# 97% on city and state
df <- left_join(df, facility_info, by = c("Facility_Occurred_CODE" = "Facility_Code"))


# Drop the two input columns, having collapsed them
df <- df %>%
  select(!Facility_Occurred_CODE) %>%
  select(!Facility_Occurred_NM)

# Bind in facility received name
df <- left_join(df,
  facility_names %>% rename(Facility_Received_NM = facility_name),
  by = c("CDFCLRCV" = "facility_code")
) %>%
  rename(Facility_Received_CODE = CDFCLRCV)

# Where no name translation is available, use the code. Otherwise use the name
df["Facility_Received"] <- ifelse(is.na(df$Facility_Received_NM), df$Facility_Received_CODE, df$Facility_Received_NM)

# Drop the two input columns, having collapsed them
df <- df %>%
  select(!Facility_Received_CODE) %>%
  select(!Facility_Received_NM)

# Translate status code to human readable, then drop redundant binary columns
df <- df %>%
  mutate(
    Case_Status = gsub("ACC", "Accepted", CDSTATUS),
    Case_Status = gsub("REJ", "Rejected", Case_Status),
    Case_Status = gsub("CLD", "Closed Denied", Case_Status),
    Case_Status = gsub("CLG", "Closed Granted", Case_Status),
    Case_Status = gsub("CLO", "Closed Other", Case_Status),
  ) %>%
  select(!CDSTATUS) %>%
  select(!reject) %>%
  select(!deny) %>%
  select(!other) %>%
  select(!grant) %>%
  select(!accept)

# Translate to human readable column name
df <- df %>% rename(Received_Office = CDOFCRCV)

# Translate to human readable column names
df <- df %>%
  rename(STAT_RSON_1 = STATRSN1) %>%
  rename(STAT_RSON_2 = STATRSN2) %>%
  rename(STAT_RSON_3 = STATRSN3) %>%
  rename(STAT_RSON_4 = STATRSN4) %>%
  rename(STAT_RSON_5 = STATRSN5)

# Join in primary and secondary descriptions and then drop redundant columns
df <- df %>%
  left_join(subject_codes %>% select(code, primary_desc, secondary_desc),
    by = c("cdsub1cb" = "code")
  ) %>%
  rename(Subject_Primary_DESC = primary_desc) %>%
  rename(Subject_Secondary_DESC = secondary_desc) %>%
  select(!CDSUB1PR) %>%
  select(!CDSUB1SC) %>%
  select(!cdsub1cb)

# Unnecessary column, value is 1 for all rows in dataset
df <- df %>% select(!submit)

# Derive from Case_Status (CDSTATUS). See docs
df <- df %>%
  select(!filed) %>%
  select(!closed)

df["Status_Reasons"] <- df[, which(colnames(df) %in% c(
  "STAT_RSON_1",
  "STAT_RSON_2",
  "STAT_RSON_3",
  "STAT_RSON_4",
  "STAT_RSON_5"
))] %>%
  apply(1, paste_not_na)

# Remove redundant / obscure columns
df <- df %>%
  select(!comptime) %>%
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

df <- df %>%
  select(!STAT_RSON_1) %>%
  select(!STAT_RSON_2) %>%
  select(!STAT_RSON_3) %>%
  select(!STAT_RSON_4) %>%
  select(!STAT_RSON_5)

# Rearrange columns for readability
df <- df %>% select(
  Case_Number,
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
  Status_Reasons,
)


# write out into chunks to lower file size
# df %>%
# filter(year(sitdtrcv) %in% 2000:2004) %>%
# write.csv('clean_data/cases/complaint-filings_2000-2005_clean.csv',row.names=FALSE, na='')

# df %>%
# filter(year(sitdtrcv) %in% 2005:2009) %>%
# write.csv('clean_data/cases/complaint-filings_2005-2009_clean.csv',row.names=FALSE, na='')

# df %>%
# filter(year(sitdtrcv) %in% 2010:2014) %>%
# write.csv('clean_data/cases/complaint-filings_2010-2014_clean.csv',row.names=FALSE, na='')

# df %>%
# filter(year(sitdtrcv) %in% 2015:2019) %>%
# write.csv('clean_data/cases/complaint-filings_2015-2019_clean.csv',row.names=FALSE, na='')

# df %>%
# filter(year(sitdtrcv) %in% 2020:2024) %>%
# write.csv('clean_data/cases/complaint-filings_2020-2024_clean.csv',row.names=FALSE, na='')

write.csv(df, "clean_data/all_complaint-filings_clean.csv", row.names = FALSE, na = "")
df %>% write_parquet("clean_data/parquet_form/all_complaint-filings_clean.parquet")

write.csv(df, "clean_data/all_complaint-filings_with-locations.csv", row.names = FALSE)
df %>% write_parquet("clean_data/parquet_form/all_complaint-filings_with-locations.parquet")
