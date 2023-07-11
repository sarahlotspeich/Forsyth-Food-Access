# Load 95 census tracts (CTs) in Forsyth County, NC
library(tidycensus)
census_api_key("0f3b62c912d5ea731c00bd1d8b6ed2bacedb8040") ## set API key
options(tigris_use_cache = TRUE)
forsyth_tracts = get_acs(state = "NC", 
                         geography = "tract", 
                         county = "forsyth",
                         variables = "B19013_001",
                         geometry = TRUE, 
                         year = 2020)
nrow(forsyth_tracts) # M = 95 census tracts

# Step 1: Find centroids of the CTs
library(sf)
ct_centroid = forsyth_tracts |>
  st_transform(2273) |> # convert to projected coord system for better centroid
  st_centroid() |> 
  st_transform("NAD83")

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
      revgeocode(location = as.vector(unlist(ct_centroid[i, c("lon", "lat")])))
    )
  )
}

# Step 3: Re-geocode map-aligned centroids of the CTs (from Step 2)
ct_centroid = ct_centroid |> 
  mutate_geocode(location = address)

## Rename lat/lon columns 
colnames(ct_centroid)[3:4] = c("lon1", "lat1") ### from Step 1
colnames(ct_centroid)[6:7] = c("lon2", "lat2") ### from Step 3

# Save 
ct_centroid |>
  write.csv("0 - Data/forsyth_ct_centroids.csv",
            row.names = FALSE)
