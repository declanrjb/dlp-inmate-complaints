library(tidyverse)

paste_not_na <- function(vec) {
  vec <- vec[!is.na(vec)]
  return(paste(vec,collapse=', '))
}