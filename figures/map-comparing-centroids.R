# Set API keys (redacted to avoid violating use agreements)
## See ex_set_api_keys.R to set up your own script
source("Forsyth-Food-Access/data/set_api_keys.R")

# Load packages
library(ggplot2)
library(ggmap)

# Load census tract centroids 
ct_centroid = read.csv("Forsyth-Food-Access/data/forsyth_ct_centroids.csv")

# Load census tract shapefiles
forsyth_tracts = tidycensus::get_acs(state = "NC", 
                                     geography = "tract", 
                                     county = "forsyth",
                                     variables = "B19013_001",
                                     geometry = TRUE, 
                                     year = 2020)
map_centroids = forsyth_tracts |> 
  ggplot() + 
  geom_sf(aes(geometry = geometry)) + 
  geom_point(data = ct_centroid, 
             aes(x = lon1, y = lat1, col = "Geometric Centroid"),
             alpha = 0.7) + 
  geom_point(data = ct_centroid, 
             aes(x = lon2, y = lat2, col = "Map-Aligned Centroid"),
             alpha = 0.7) + 
  scale_color_manual(name = "",
                     breaks=c("Geometric Centroid", 
                              "Map-Aligned Centroid"),
                     values=c("Geometric Centroid" = "#b53975", 
                              "Map-Aligned Centroid" = "#34104f")) +
  guides(colour = guide_legend(nrow = 1)) +
  theme_void() + 
  theme(plot.margin = margin(l=25,r=20,t=20,b=25),
        legend.position = c(0.5, 1.05), 
        legend.text = element_text(size = 12),
        legend.title = element_text(size = 12),
        legend.box.margin = margin(r=10,l=10,t=20,b=20))
map_centroids
ggsave(filename = "Forsyth-Food-Access/figures/map-comparing-centroids.png", 
       device = "png", units = "in", width = 4, height = 5)
