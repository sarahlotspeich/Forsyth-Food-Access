# Healthy Food Access and Health in Forsyth County, North Carolina

## Data Collection 

To assess the impact of food access on health in Forsyth County, North Carolina (NC), publicly available data will be combined from three sources using open-source tools for analysis.

  1.  **Health Outcomes:** 
  2.  **Neighborhoods:** As neighborhoods, the $M = 95$ census tracts in Forsyth County, NC were used, and their centroids were treated as the "origin" for all distance calculations between the neighborhoods and grocery stores. [[Script]](data/forsyth_ct_centroids.R)[[Data]](data/forsyth_ct_centroids.csv)

      -  **Neighborhood Centroids:** Centroid coordinates were first found as the geometric centers of the census tract shapefiles, before being "map-aligned" using the Google Maps API to ensure that the centroid coordinates correspond to realistic, accessible locations. A map comparing the geometric and map-aligned centroids is included in the paper. [[Script]](figures/map-comparing-centroids.R)[[Map]](figures/map-comparing-centroids.png)

  3.  **Grocery Stores:** Search results for $n = 855$ unique grocery stores from Forsyth and surrounding counties were initially queried. [[Script]](data/forsyth_border_grocery.R)[[Raw Data]](data/forsyth_ct_centroids.csv)

      -  **Grocery Stores Exclusion Criteria:** Each grocery store result was manually reviewed in Google Maps to classify it as one of the following: (i) major chains (e.g., Food Lion and Lowe’s Foods), (ii) local stores (e.g., Asian and Indian markets), (ii) specialty stores (e.g., produce stands and butcher shops), (iv) dollar stores (e.g., Family Dollar and Dollar Tree), (v) convenience stores, or (vi) other (e.g., grocery distributors and community pantries). Results in the “other” category were excluded to focus on more traditional store options. [[Final Data]](data/grocery_final.csv)
