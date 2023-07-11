# Set API keys (redacted to avoid violating use agreements)
## See ex_set_api_keys.R to set up your own script
source("Forsyth-Food-Access/data/set_api_keys.R")

# Define border counties
border_counties = c("davidson", "davie", "yadkin", "surry", "stokes", 
                    "rockingham", "guilford", "randolph")

# Load 1023 census block groups (CBGs) in Forsyth County, NC & border counties
forsyth_border_cbg = tidycensus::get_acs(state = "NC", 
                                         geography = "cbg", 
                                         county = c("forsyth", border_counties),
                                         variables = "B19013_001",
                                         geometry = TRUE, 
                                         year = 2020)
nrow(forsyth_border_cbg) 

# Find centroids of the CBGs
cbg_centroid = forsyth_border_cbg |>
  sf::st_transform(2273) |> # convert to projected coord system for better centroid
  sf::st_centroid() |> 
  sf::st_transform("NAD83")

## Add separate columns for lat/long
cbg_centroid = cbg_centroid |>
  dplyr:: mutate(lon = unlist(purrr::map(cbg_centroid$geometry,1)),
                 lat = unlist(purrr::map(cbg_centroid$geometry,2)))
cbg_centroid |> 
  as.data.frame() |> 
  dplyr::ungroup() |> 
  dplyr::select(GEOID, NAME, lon, lat) |> 
  write.csv("Forsyth-Food-Access/data/forsyth_border_cbg_centroids.csv", 
            row.names = FALSE)
