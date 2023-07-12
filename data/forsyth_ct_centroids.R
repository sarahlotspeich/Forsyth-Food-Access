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

# Step 2: Reverse-geocode centroids of the CTs to align with Google Maps
for (i in 1:nrow(ct_centroid)) {
  ## Get all reverse-geocoding results 
  temp = suppressWarnings(
    suppressMessages(
      ggmap::revgeocode(location = as.vector(unlist(ct_centroid[i, c("lon", "lat")])), 
                        output = "all")
    )
  )
  
  ## Extract location types
  location_type = sapply(X = 1:length(temp$results), 
                         FUN = function(x) temp$results[[x]]$geometry$location_type)
  lat_lon = t(sapply(X = 1:length(temp$results), 
                     FUN = function(x) temp$results[[x]]$geometry$location[c(2, 1)]))
  dist_between = as.vector(rep(NA, length(location_type)))
  for (l in which(location_type == "ROOFTOP")) { 
    dist_between[l] = geosphere::distHaversine(p1 = as.vector(unlist(ct_centroid[i, c("lon", "lat")])), 
                                                   p2 = as.numeric(unlist(temp$results[[l]]$geometry$location[c(2, 1)])), 
                                                   r = 3958.8)
  }
  if (any(location_type == "ROOFTOP")) {
    ct_centroid$address[i] = temp$results[[which.min(dist_between)]]$formatted_address  
  } else {
    ct_centroid$address[i] = NA
  }
}

## Manual review: One CT did not have any rooftop-level matches 
ct_centroid |> 
  dplyr::filter(is.na(address))

### Manual entry of lat/long (36.09941, -80.29910) suggested that the 
### Forsyth Country Club would was the nearest realistic location.
ct_centroid$address[is.na(ct_centroid$address)] = "3101 Country Club Rd, Winston-Salem, NC 27104"

# Step 3: Re-geocode map-aligned centroids of the CTs (from Step 2)
ct_centroid = ct_centroid |> 
  ggmap::mutate_geocode(location = address)

## Manual review: One centroid address was not uniquely geocoded 
## Address: 1817 Chanterelle Ct, Winston-Salem, NC 27106, USA for i = 39 
ct_centroid[39, ] 

### Manual entry of lat/long (36.10901, -80.37993) suggested that the 
### following range-interpolated match was reasonable. 
ct_centroid$address[39] = "1169 Maple Chase Ln, Lewisville, NC 27023, USA"

### Re-geocode new address 
ct_centroid[39, c("lon...6", "lat...7")] = ggmap::geocode(location = ct_centroid$address[39])

## Rename lat/lon columns 
colnames(ct_centroid)[3:4] = c("lon1", "lat1") ### original centroids from Step 1
colnames(ct_centroid)[6:7] = c("lon2", "lat2") ### map-aligned centroids from Step 3

# Save 
ct_centroid |>
  write.csv("Forsyth-Food-Access/data/forsyth_ct_centroids.csv",
            row.names = FALSE)
