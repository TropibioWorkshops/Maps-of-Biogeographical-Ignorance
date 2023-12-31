
library(ggplot2)
library(tidyverse)
library(maps)
library(sf)
library(rnaturalearth)
library(stars)

###########################
# Open Refine workshop
###########################

df_final<-read_csv("test_lite_clean.csv")

# turn it into an sf object, for spatial plotting
my_sf <- df_final %>% 
  st_as_sf(coords<-c('decimalLongitude', 'decimalLatitude')) %>%
  st_set_crs(4326) # using 4326 for lat/lon decimal 

# ggplot2 of the data
ggplot() +
  geom_sf(data<-my_sf, size<-3)

# Getting a little fancier with it by adding the state borders
nam_map <- rnaturalearth::ne_countries(continent<-'africa', returnclass<-'sf') %>%
  filter(name %in% c("Namibia")) 

my_sf2 <-  st_intersection(nam_map,my_sf)

# Make grid

## Polygon
world<-ne_countries(scale<-"small", returnclass<-"sf")
world<-st_transform(world, "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
pol<-world[world$sovereignt == "Namibia", ]

grid<-st_as_stars(st_bbox(pol), dx<-50000, dy<-50000, crs<-st_crs(4326))
grid<-st_as_sf(grid)
grid<-grid[pol, ]

# create grid
grid_area <- grid %>%
  mutate(grid_id = 1:nrow(grid))

# transform grid area
grid_area <- st_transform(grid_area, 4326)
my_sf2 <- st_transform(my_sf2, 4326)

result <- grid_area %>%
  st_join(my_sf2) %>% 
  group_by(grid_id) %>% 
  dplyr::summarise(point_count = n())
  

result <- result %>% 
  
  # Ign_Norm: Transform observation count into 0-1 scale
  # Ign_LogNorm: it is relevant to separate sites with “few” observations from sites with “enough” 
  # observations, logarithmic transformations are preferred
  # Ign_Half: It estimates ignorance scores making data relative to a reference number of
  # observations that is considered to be enough to reduce the ignorance score by half
  
  mutate(point_max<-max(point_count),
         point_mean<-mean(point_count),
         point_sd<-sd(point_count),
         Ign_Norm<-(1 - (point_count/point_max)),
         Ign_LogNorm<-(1 - (log(point_count+1)/log(point_max+1))),
         # When Ign_Half is equal to 1 is due 50% of no records because of no effort
         # and 50% because of in spite of the effort no results were obtained
         Ign_Half_5<-(5 / (point_count + 5)),
         Ign_Half_10<-(10 / (point_count + 10)),
         Ign_Half_30<-(30 / (point_count + 30)),
         Ign_Zscore<-((point_count - point_mean)/point_sd))

#Quitamos las observaciones más influyentes
result2 <- result %>% filter(!point_count %in% c(2265,1515))


ggplot() + 
  geom_sf(data<-result, aes(fill<-Ign_Norm), size<-0.5, col='black') +
  geom_sf(data<-nam_map, size=2,  fill<-NA) + 
  theme_light()

ggplot() + 
  geom_sf(data<-result, aes(fill<-Ign_LogNorm), size<-0.5, col='black') +
  geom_sf(data<-nam_map, size=2,  fill<-NA) + 
  theme_light()
  
ggplot() + 
  geom_sf(data<-result, aes(fill<-Ign_Half_5), size<-0.5, col='black') +
  geom_sf(data<-nam_map, size=2,  fill<-NA) + 
  theme_light()

ggplot() + 
  geom_sf(data<-result, aes(fill<-Ign_Half_10), size<-0.5, col='black') +
  geom_sf(data<-nam_map, size=2,  fill<-NA) + 
  theme_light()

ggplot() + 
  geom_sf(data<-result, aes(fill<-Ign_Half_30), size<-0.5, col='black') +
  geom_sf(data<-nam_map, size=2,  fill<-NA) + 
  theme_light()

ggplot() + 
  geom_sf(data<-result, aes(fill<-Ign_Zscore), size<-0.5, col='black') +
  geom_sf(data<-nam_map, size=2,  fill<-NA) + 
  theme_light()



# library(sf)
# library(stars)
# library(rnaturalearth)
# 

# 
# 
# 
# # Plot
# plot(st_geometry(grid), axes<-TRUE, reset<-FALSE)
# plot(st_geometry(world), border<-"grey", add<-TRUE)
# plot(st_geometry(pol), border<-"red", add<-TRUE)

# times <- ceiling(nrow(df)/50000)
# data <- split(df,factor(sort(rank(row.names(df))%%times)))
# 
# sapply(names(data), 
#        function (x) write.csv(data[[x]], file=paste("/Users/javiermartinez/Downloads/Prueba/",
#                                                     paste(x, "csv", sep=".") ))   )


nam_bos_map <- rnaturalearth::ne_countries(continent<-'africa', returnclass<-'sf') %>%
  filter(name %in% c("Namibia","Botswana")) 

ggplot() + 
  geom_sf(data<-nam_bos_map, size=2,  fill<-NA) + 
  theme_light()

# # Polygon
world<-ne_countries(scale<-"small", returnclass<-"sf")
world<-st_transform(world, "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
pol<-world[world$sovereignt %in% c("Namibia","Botswana"), ]

grid<-st_as_stars(st_bbox(pol), dx<-10000, dy<-10000, crs<-st_crs(4326))
grid<-st_as_sf(grid)
grid<-grid[pol, ]

grid_area <- grid %>%
  mutate(grid_id<-1:n())

# transform grid area
grid_area <- st_transform(grid_area, 4326)

ggplot() + 
  geom_sf(data<-grid_area, size<-0.5, col='black') +
  geom_sf(data<-nam_map, size=2,  fill<-NA) + 
  theme_light()

# Measuring inventory completeness in Namibia

## Load libraries
library (dplyr)
library(KnowBR)

## Extract coordinates from sf object
coords = st_coordinates(my_sf2) 

## Convert sf into a df
df <- my_sf2 %>% st_drop_geometry()
df <- cbind(df,coords)

## Change column names
colnames(df)[70] <- "decimalLongitude"
colnames(df)[71] <- "decimalLatitude"

## Put data into knowBr format
df$count<-1 #create a column of frequency

df1<-df[,c("species","decimalLongitude","decimalLatitude","count")]

## Load databases
data("adworld")

## Run the function that calculates inventory completeness
KnowB(df1, cell=30, jpg = T, 
      minLon = 10, maxLon = 27, minLat = -30, maxLat = -14, extent = F)

beepr::beep(2)
