source('functions.R')

url <- 'https://www.bop.gov/locations/list.jsp'

page <- read_html(url)

test <- page %>%
  html_nodes('#facil_list_cont') %>%
  html_nodes('a') %>%
  html_attr('href') %>%
  .[!grepl('.jsp',.)]