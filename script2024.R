
# Load packages:
library(terra)
library(remotes)
library(tidyverse)
library(AOI)
library(climateR)
library(sf)
library(tidyterra)
library(ggplot2)

aoi.global <- aoi_get(country= c("Europe","Asia" ,"North America", "South America", "Australia","Africa", "New Zealand"))

aoi.global %>% plot()

#normals.ppt <- aoi.global  %>% getTerraClimNormals(varname ="ppt")

normals.ppt <- terra::rast('data/normals.ppt.tif' )
normals.ppt %>% names()
units(normals.ppt) <- "mm"
normals.ppt %>% time()
time(normals.ppt) <- seq(1, 12, 1)
# File brought in from canvas, required changes to normal.ppt$ppt

ggplot() + geom_spatraster(data=normals.ppt[[1]])

normals.ppt.annual <- normals.ppt %>% sum(na.rm = TRUE)

# look at the object
normals.ppt.annual %>% plot()

# Check the name of the layers:
names(normals.ppt.annual)

# re-name the layers:
names(normals.ppt.annual) <- "ppt"


normals.ppt.annual %>% global( na.rm=T, mean)

normals.ppt %>% global( na.rm=T, mean)


normals.ppt.annual.country <- zonal(x = normals.ppt.annual, 
                                    z= vect(aoi.global) , fun = "mean", as.polygons=TRUE,  na.rm=TRUE)


class( normals.ppt.annual.country)


normals.ppt.annual.country.sf <- st_as_sf(normals.ppt.annual.country)   

ggplot( data=normals.ppt.annual.country.sf ) + geom_sf(aes(fill= ppt))

FLUXNET.ch4 <- st_read(dsn="Data", layer="FLUXNET_CH4")



FLUXNET.ch4 
normals.ppt

FLUXNET.ch4  <- st_transform(FLUXNET.ch4, crs= crs(normals.ppt))


ggplot() + geom_spatraster( data=normals.ppt.annual) +geom_sf( data =FLUXNET.ch4 )


FLUXNET.ch4.ppt <- terra::extract( normals.ppt, FLUXNET.ch4)


FLUXNET.ch4.ppt.sf <- FLUXNET.ch4 %>% cbind(FLUXNET.ch4.ppt)

summary(FLUXNET.ch4.ppt.sf )

ggplot()+  geom_sf(data = aoi.global) + geom_sf( data = FLUXNET.ch4.ppt.sf, aes( col= ppt_1961.09.01_19812010)) 
