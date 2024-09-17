# Introduction to rasters with the terra package.

### Install libraries for this workshop:
```{r, include=T}
install.packages('sf')
install.packages('terra')
install.packages("remotes")
install.packages("tidyverse")
install.packages('tidyterra')
remotes::install_github("mikejohnson51/AOI")
remotes::install_github("mikejohnson51/climateR")
```
### Load libraries:

```{r, include=T}
library(terra)
library(remotes)
library(tidyverse)
library(AOI)
library(climateR)
library(sf)
library(tidyterra)
```
## Rasters
A raster is a spatial data structure that subdivides an extent into rectangles known as "cells" (or "pixels"). Each cell has the capacity to store one or more values. This type of data structure is commonly referred to as a "grid" and is frequently juxtaposed with simple features.

The terra package offers functions designed for the creation, reading, manipulation, and writing of raster data. The terra package is built around a number of “classes” of which the SpatRaster and SpatVector are the most important.

#### SpatRaster
A SpatRaster object stores a number of fundamental parameters that describe it. These include the number of columns and rows, the coordinates of its spatial extent, and the coordinate reference system. In addition, a SpatRaster can store information about the file(s) in which the raster cell values are stored.

#### SpatVector
A SpatVector represents “vector” data, that is, points, lines or polygon geometries and their tabular attributes.

#### Working with climate data:

To become familiar with working with rasters, we will download climate data for an area of interest (AOI). 

```{r, include=T}

# First create an AOI
aoi.global <- aoi_get(country= c("Europe","Asia" ,"North America", "South America", "Australia","Africa", "New Zealand"))

```
Visualize your AOI:
```{r, include=T}

```

We will use TerraClimate, a dataset of high-spatial resolution (1/24°, ~4-km) monthly climate and climatic water balance for global terrestrial surfaces from 1958–2015 (Abatzoglou, 2018).

Download climate data using the library climateR for the AOI. For this exercise we will use climate normals, multi-decadal averages for climate variables like temperature and precipitation. They provide a baseline that allows us to understand the location’s average condition.

You can access monthly precipitation ("ppt"), monthly temperature minimum ("tmin"), monthly temperature maximum ("tmax") climate normals and more.

Download monthly precipitation (ppt)

```{r, include=T}

normals.ppt <- aoi.global  %>% getTerraClimNormals(varname ="ppt")

```
What is this object:
```{r, include=T}
class(normals.ppt)
class(normals.ppt$ppt)
```

A RasterStack is a collection of RasterLayer objects with the same spatial extent and resolution. In essence it is a list of RasterLayer objects.

To access the raster stack:
```{r, include=T}
normals.ppt$ppt
normals.ppt$ppt %>% names()
normals.ppt$ppt %>% time()

ggplot() + geom_spatraster(data=normals.ppt$ppt[[1]])

```
#### Raster algebra
Many generic functions that allow for simple and elegant raster algebra have been implemented for SpatRaster objects, including the normal algebraic operators such as +, -, *, /, logical operators such as >, >=, <, ==, !} and functions such as abs, round, ceiling, floor, trunc, sqrt, log, log10, exp, cos, sin, max, min, range, prod, sum, any, all. In these functions you can mix terra objects with numbers, as long as the first argument is a terra object. If you use multiple SpatRaster objects, all objects must have the same resolution and origin. 

Lets summarize monthly data to annual normals: 

```{r, include=T}
normals.ppt.annual <- normals.ppt$ppt %>% sum(na.rm = TRUE)

# look at the object
normals.ppt.annual %>% plot()

# Check the name of the layers:
names(normals.ppt.annual)

# re-name the layers:
names(normals.ppt.annual) <- "ppt"
```
Summary functions (min, max, mean, prod, sum, median, cv, range, any, all) always return a SpatRaster object.

Use global if instead of a SpatRaster you want a single number summarizing the cell values of each layer.

```{r, include=T}

normals.ppt.annual %>% global( na.rm=T, mean)

```

#### Spatial Summaries

You might also find it useful to create zonal summaries for each polygon within the simple feature. To do this we can use the function zonal, which takes a SpatRast and a SpatVect.

```{r, include=T}

normals.ppt.annual.country <- zonal(x = normals.ppt.annual, 
z= vect(aoi.global) , fun = "mean", as.polygons=TRUE,  na.rm=TRUE)

```
What did the function return?

```{r, include=T}

class( normals.ppt.annual.country)

```
Convert the SpatVect back to a simple feature and plot it.

```{r, include=T}

normals.ppt.annual.country.sf <- st_as_sf(normals.ppt.annual.country)   

ggplot( data=normals.ppt.annual.country.sf ) + geom_sf(aes(fill= ppt))

```
#### Extracting information to a point file:
For this exercise you will use your FLUXNET.CH4 vector file you saved last week and the monthly ppt data downloaded (normals.ppt.NAmerica$ppt).  

Import your point file FLUXNET.ch4:

```{r, include=T}

FLUXNET.ch4 <- st_read(dsn="Data", layer="FLUXNET_CH4")

```
Ensure both files have the same coordinate reference system (CRS):

```{r, include=T}

FLUXNET.ch4 
normals.ppt$ppt
```
You can transform one of the files if they dont match. Here I transform th vector:

```{r, include=T}
FLUXNET.ch4  <- st_transform(FLUXNET.ch4, crs= crs(normals.ppt$ppt ))
```

To check to see if everything lines up, I plot the files together:
```{r, include=T}

ggplot() + geom_spatraster( data=normals.ppt$ppt[[1]]) +geom_sf( data =FLUXNET.ch4 )

```
Extract information from your raster stack using terra::extract()

```{r, include=T}

FLUXNET.ch4.ppt <-terra::extract( normals.ppt$ppt, FLUXNET.ch4)

```

What did the extract function return?

```{r, include=T}
class(FLUXNET.ch4.ppt)
```
Combine extracted information to the simple feature:
```{r, include=T}

FLUXNET.ch4.ppt.sf <- FLUXNET.ch4 %>% cbind(FLUXNET.ch4.ppt)
```
Visualize your work:

```{r, include=T}
ggplot()+  geom_sf(data = aoi.global) + geom_sf( data = FLUXNET.ch4.ppt.sf, aes( col= ppt_1961.09.01_19812010)) 
```

FLUXNET data can be used to understand patterns in natural methane fluxes. Evaluating the conditions where measurements are taken is essential to designing a useful model. 

## Download monthly temperature (tmin and tmax) to understand the differences in temperature for the tower locations. Use precipitation and temperature summaries in Assessment 2/3.

## Assessment 2/3
We will use data from FLUXNET CH4 to explore patterns in natural methane emissions. Explore the distribution of tower sites and create visualizations that may be helpful to understand in the design and development of models. You are welcome to use any additional data or just new plot types.

#### References

Abatzoglou, J., Dobrowski, S., Parks, S. et al. TerraClimate, a high-resolution global dataset of monthly climate and climatic water balance from 1958–2015. Sci Data 5, 170191 (2018). https://doi.org/10.1038/sdata.2017.191
