#!/usr/bin/env merb -e rake -r 

#ap = Wire.get(1)
#ap.crawl

afp = Wire.get(2)
afp.refresh
afp.crawl

Statistic.update_all