# Set API keys (redacted to avoid violating use agreements)
## See ex_set_api_keys.R to set up your own script
source("Forsyth-Food-Access/data/set_api_keys.R")

# Load centroids of census block groups (CBGs) in Forsyth & bordering counties 
cbg_centroid = read.csv(file = "https://raw.githubusercontent.com/sarahlotspeich/Forsyth-Food-Access/main/data/forsyth_border_cbg_centroids.csv")

# Create empty grocery_data dataframe and fill with results
grocery_data = data.frame()
for (i in 1:nrow(cbg_centroid)) {
  # Search for stores around the ith census block group
  cbg = cbg_centroid$GEOID[i]
  lon = cbg_centroid$lon[i]
  lat = cbg_centroid$lat[i]
  ### initial search (includes first 20 stores in $results)
  grocery_search = google_places(search_string = "Grocery Stores", 
                                 location = c(lat, lon),
                                 radius = 1000)
  ### save first 20 stores to grocery_data
  grocery_data = grocery_data |> 
    dplyr::bind_rows(
      grocery_search$results |> 
        dplyr::select(place_id, 
                      name, 
                      formatted_address, 
                      business_status, 
                      rating, 
                      user_ratings_total, 
                      types) |> 
        dplyr::mutate(GEOID = cbg)
    )
}

# Geocode addresses
grocery_data = grocery_data |> 
  ggmap::mutate_geocode(location = formatted_address, 
                        source = "google")

# Types of grocery stores in search
grocery_types = unique(unlist(grocery_data$types))

# Reformat $types to be a string rather than a list
grocery_data$types = sapply(X = 1:nrow(grocery_data), 
                            FUN = function(x) paste(grocery_data$types[[x]], 
                                                    collapse = ", "))

# Create indicator variables for different types 
grocery_data = grocery_data |> 
  dplyr::mutate(
    grocery_or_supermarket = as.numeric(grepl(x = types, pattern = "grocery_or_supermarket")),
    supermarket = as.numeric(grepl(x = types, pattern = "supermarket")),
    food = as.numeric(grepl(x = types, pattern = "food")),
    health = as.numeric(grepl(x = types, pattern = "health")),
    store = as.numeric(grepl(x = types, pattern = "store")),
    convenience_store = as.numeric(grepl(x = types, pattern = "convenience_store")),
    gas_station = as.numeric(grepl(x = types, pattern = "gas_station")),
    bakery = as.numeric(grepl(x = types, pattern = "bakery")),
    bar = as.numeric(grepl(x = types, pattern = "bar")),
    cafe = as.numeric(grepl(x = types, pattern = "cafe")),
    car_repair = as.numeric(grepl(x = types, pattern = "car_repair")),
    car_wash = as.numeric(grepl(x = types, pattern = "car_wash")),
    liquor_store = as.numeric(grepl(x = types, pattern = "liquor_store")),
    night_club = as.numeric(grepl(x = types, pattern = "night_club")),
    pharmacy = as.numeric(grepl(x = types, pattern = "pharmacy")),
    drugstore = as.numeric(grepl(x = types, pattern = "drugstore"))
  )

unique_grocery_data = grocery_data |> 
  dplyr::select(-GEOID, -types) |> 
  unique()

# There was a duplicate row for place_id = ChIJHZsa7ee5U4gRnuBsuoaYvW8
## due to different user_ratings_total in the search (manually taking the row with max ratings)
unique_grocery_data = unique_grocery_data |> 
  dplyr::filter(!(place_id == "ChIJHZsa7ee5U4gRnuBsuoaYvW8" & user_ratings_total == 901))

# There were also duplicate rows for some addresses that have multiple store names
## Take weighted average of ratings across rows and save other names into new variable
unique_grocery_data$other_names = ""
dup_addresses = names(table(unique_grocery_data$formatted_address)[table(unique_grocery_data$formatted_address) > 1])
for (add in dup_addresses) {
  add_data = unique_grocery_data |> 
    dplyr::filter(formatted_address == add)
  comb_data = add_data |> 
    dplyr::mutate(rating = round(x = weighted.mean(x = rating, w = user_ratings_total / sum(user_ratings_total)), digits = 1),  
                  user_ratings_total = sum(user_ratings_total)) |> 
    dplyr::ungroup() |> 
    dplyr::slice(1)
  comb_data$other_names = paste(x = add_data$name[-1], collapse = ", ")
  unique_grocery_data = unique_grocery_data |> 
    dplyr::filter(formatted_address != add) |> 
    dplyr::bind_rows(comb_data)
}
nrow(unique_grocery_data) 

# And there are still duplicate lon/lat 
dup_latlon = with(unique_grocery_data, table(lon, lat)) |> 
  data.frame() |> 
  dplyr::filter(Freq > 1)

## Manual review 
### 1. Google Maps shows "Food King" 
unique_grocery_data |> 
  dplyr::filter(lon == dup_latlon$lon[1], lat == dup_latlon$lat[1])
unique_grocery_data = unique_grocery_data |> 
  dplyr::filter(place_id != "ChIJGS2YzuGaVIgRJv8eYKqONRE") #### so delete "Montgomery Foods" 
### 2. Google Maps shows "Route62 MART" 
unique_grocery_data |> 
  dplyr::filter(lon == dup_latlon$lon[2], lat == dup_latlon$lat[2])
unique_grocery_data = unique_grocery_data |> 
  dplyr::filter(place_id != "ChIJbY7xf9UNU4gR5NegVh3sEaA") #### so delete "Liberty Discount Grocery and Fishing Store" 
### 3. Google Maps shows both a Dollar Tree & Harris Teeter in this shopping center (keep both)
unique_grocery_data |> 
  dplyr::filter(lon == dup_latlon$lon[3], lat == dup_latlon$lat[3])
### 4. Google Maps shows "Al Aqsa Meat Market" 
unique_grocery_data |> 
  dplyr::filter(lon == dup_latlon$lon[4], lat == dup_latlon$lat[4])
unique_grocery_data = unique_grocery_data |> 
  dplyr::filter(place_id != "ChIJQayVJgobU4gRHPnxzBAXKDM") #### so delete "Arabic Store" 
### 5. Google Maps shows "Keh'Lani Groceries" 
unique_grocery_data |> 
  dplyr::filter(lon == dup_latlon$lon[5], lat == dup_latlon$lat[5])
unique_grocery_data[unique_grocery_data$name == "Keh'Lani Groceries", c("lon", "lat")] = c(-80.2569394, 36.0747041)
unique_grocery_data = unique_grocery_data |> 
  dplyr::filter(place_id != "ChIJHbuLrcmvU4gRz94LIfGwJqY", #### so delete "La Hacienda" 
                place_id != "ChIJaTdrq8mvU4gRqSj5o69UKBg") #### and "Steve Mini Market" 
### 6. Google Maps shows both a Family Dollar & Harris Teeter in this shopping center (keep both)
unique_grocery_data |> 
  dplyr::filter(lon == dup_latlon$lon[6], lat == dup_latlon$lat[6])
### 7. Google Maps shows two stores maybe close together (keeping both)
unique_grocery_data |> 
  dplyr::filter(lon == dup_latlon$lon[7], lat == dup_latlon$lat[7])

unique_grocery_data |> 
  write.csv("Forsyth-Food-Access/data/raw_forsyth_border_grocery.csv", 
            row.names = F)
