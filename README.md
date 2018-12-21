# tandemx
Scripts for processing the TanDEM-X global mosaic

# Background
The TanDEM-X 90m Digital Elevation Model (DEM) is a publicly availalble 90-m (1-arcsec) elevation dataset with global coverage.  It is unprecendented in coverage, resolution (12-m product available), and accuracy.  This repo contains scripts to automatically download tiles (in parallel), clean up, and mosaic for use as a reference DEM.  

See details about the product here: https://geoservice.dlr.de/web/dataguide/tdm90/

Excellent documentation available in the Product Specification Document: https://geoservice.dlr.de/web/dataguide/tdm90/pdfs/TD-GS-PS-0021_DEM-Product-Specification.pdf

To download tiles, you need to register for free account here: https://sso.eoc.dlr.de/pwm-tdmdem90

## Use
Some artifacts persist over mountainous terrain, water bodies, and areas with limited overlapping InSAR-derived DEM strips, especially in the v1 tiles.  See the official doc for more details.  The masking functionality here is intended to remove these artifacts, preserving pixels with limited error (ideally <1 m horizontal and vertical, especially for planar surfaces with limited surface slope).

The masked DEM is an excellent reference DEM for robust co-registration of other DEM datasets (including high-resolution DEMs) on a regional scale (see demcoreg repo), as it has high absolute and relative accuracy within each tile (ie, limited horizontal/vertical offsets between mosaicked strips).  

# Tools
- `tandemx_proc.sh`: wrapper to download, process and mask tiles for user lat/lon bounds, requires temporary hardcoding of account credentials if downloading tiles.
- `tandemx_mask.py`: mask DEM products using a series of filters from AUX products, intended to remove artifacts and pixels with increased error
- tandemx_eval.ipynb: Notebook for interactive analysis and visualization, used to evaluate AUX layers for each tile and set thresholds for masking
