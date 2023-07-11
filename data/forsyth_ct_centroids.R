# Set API keys (redacted to avoid violating use agreements)
## See ex_set_api_keys.R to set up your own script
source("Forsyth-Food-Access/data/set_api_keys.R")

# Load 95 census tracts (CTs) in Forsyth County, NC
forsyth_tracts = tidycensus::get_acs(state = "NC", 
                                     geography = "tract", 
                                     county = "forsyth",
                                     variables = "B19013_001",
                                     geometry = TRUE, 
                                     year = 2020)
nrow(forsyth_tracts) # M = 95 census tracts

# Step 1: Find centroids of the CTs
ct_centroid = forsyth_tracts |>
  sf::st_transform(2273) |> # convert to projected coord system for better centroid
  sf::st_centroid() |> 
  sf::st_transform("NAD83")

## Add separate columns for lat/long
ct_centroid = ct_centroid |>
  dplyr:: mutate(lon = unlist(purrr::map(ct_centroid$geometry,1)),
                 lat = unlist(purrr::map(ct_centroid$geometry,2)))

## Reshape as data will be saved
ct_centroid = ct_centroid |> 
  as.data.frame() |> 
  dplyr::ungroup() |> 
  dplyr::select(GEOID, NAME, lon, lat) 

# Step 2: Reverse-geocode centroids of the CTs
for (i in 1:nrow(ct_centroid)) {
  ct_centroid$address[i] = suppressWarnings(
    suppressMessages(
      ggmap::revgeocode(location = as.vector(unlist(ct_centroid[i, c("lon", "lat")])))
    )
  )
}

# Step 3: Re-geocode map-aligned centroids of the CTs (from Step 2)
ct_centroid = ct_centroid |> 
  ggmap::mutate_geocode(location = address)

## Rename lat/lon columns 
colnames(ct_centroid)[3:4] = c("lon1", "lat1") ### from Step 1
colnames(ct_centroid)[6:7] = c("lon2", "lat2") ### from Step 3

# Save 
ct_centroid |>
  write.csv("Forsyth-Food-Access/data/forsyth_ct_centroids.csv",
            row.names = FALSE)
