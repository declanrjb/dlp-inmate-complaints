.PHONY: data scrape

default:

format:
	Rscript -e "library(styler); style_dir('code');"

data:
	Rscript code/fac_clean.R
	Rscript code/merge.R

scrape:
	Rscript code/scrape.R
