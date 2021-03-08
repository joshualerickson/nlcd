library(rgee)
ee_Initialize(gcs = T)

library(exploreRGEE)
library(sf)
library(tidyverse)
# Bring in image and extent

region_1_bbox <- st_bbox(c(xmin = -117.190616, xmax = -96.554411, ymax = 49.001390, ymin = 44.26879), crs = st_crs(4326))

geom = ee$Geometry$Rectangle(region_1_bbox)

nlcd = ee$Image("USGS/NLCD/NLCD2011")

#create a mask for 'barren land'

barren_land = nlcd$select('landcover')$eq(31)

nlcd_2011_barren_land <- nlcd$updateMask(barren_land)

nlcd_2011_barren_land %>% viz(band = 'landcover',user_shape = region_1_bbox)


nlcd_2011_ras <- ee_as_raster(nlcd_2011_barren_land,
                              region = geom,
                              dsn = "nlcd_wcc",
                              scale = 30,
                              crs = 'EPSG:5070',
                              container = "jle_rasters",
                              via = "gcs",
                              lazy = TRUE,
                              timePrefix = F)


nlcd1 <- raster::stack('images/nlcd_wcc1.tif')
nlcd2 <- raster::stack('images/nlcd_wcc2.tif')

# this gets the 'landcover band [[1]]' and then mosaics together
final_nlcd <- raster::mosaic(nlcd1[[1]], nlcd2[[1]], fun = min)

#now reclassify so everything that's not 'barren' is NA and 'barren' is 1
final_nlcd_rc <- raster::reclassify(final_nlcd, c(0,30, NA, 30, 31, 1))

#then write a final tiff
raster::writeRaster(final_nlcd_rc, 'images/final_nlcd.tif', overwrite = TRUE)

