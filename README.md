# Healthy Food Access and Health in Forsyth County, North Carolina

## Data Collection 

To assess the impact of food access on health in Forsyth County, North Carolina (NC), publicly available data will be combined from three sources using open-source tools for analysis.

  1.  **Neighborhoods:** As neighborhoods, the $M = 95$ census tracts in Forsyth County, NC were used, and their centroids were treated as the "origin" for all distance calculations between the neighborhoods and grocery stores. [[Script]](data/forsyth_ct_centroids.R)[[Data]](data/forsyth_ct_centroids.csv) Centroid coordinates were first found as the geometric centers of the census tract shapefiles, before being "map-aligned" using the Google Maps API to ensure that the centroid coordinates correspond to realistic, accessible locations. A map comparing the geometric and map-aligned centroids is included in the paper. [[Script]](figures/map-comparing-centroids.R)[[Data]](figures/map-comparing-centroids.png)
  2.  
