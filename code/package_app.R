source('code/functions.R')

app_df <- list.files('data/clean/filings') %>%
  paste('data/clean/filings/',.,sep='') %>%
  lapply(read_csv) %>%
  do.call(rbind,.)

app_df <- app_df %>%
  left_join(read_csv('data/clean/facilities/facility-locations.csv'),
            by=c('Facility_Occurred' = 'Facility_Name')) %>%
  mutate(State = lapply(State,
                        function(x) {
                          if (x %in% state.abb) {
                            state.name[which(state.abb == x)]
                          } else {
                            return(NA)
                          }
                        }
  ))

app_df <- app_df %>%
  mutate(Lat = round(Lat,2),
         Long = round(Long,2))

app_df <- app_df %>% mutate(State = gsub('NA',NA,State))

app_df <- app_df %>%
  select(Case_Number,
         Case_Status,
         Subject_Primary,
         Subject_Secondary,
         Facility_Occurred,
         Received_Date,
         Latest_Status_Date,
         Status_Reasons,
         City,
         State)

app_df <- app_df %>% 
  filter(year(Received_Date) > 2014)

app_df %>%
  write_csv('data-explorer/all-filings.csv')

shinylive::export(appdir="data-explorer",destdir="../inmate-complaints-dashboard-standalone")
