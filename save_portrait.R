### Download, crop and save Andues portrait with magick!
library(magick)
library(magrittr)
magick::image_read("https://www.kompetenz-wasser.de/wp-content/uploads/2017/07/andreas_matzinger_kuras-600x400.jpg") %>%
  magick::image_crop(geometry = magick::geometry_area(250,300, 175, 0)) %>% 
  magick::image_write("static/img/author.jpg")
  
