#! /bin/bash

#Download and process TanDEM-X 90-m products

#Turn off auto ls after cd
unset -f cd

res=90

#Location for additional processing scripts, assumed to be in same directory as this script
#srcdir=~/src/tandemx
srcdir=$(dirname "$(readlink -f "$0")")

topdir=/nobackup/deshean/data/tandemx/hma/
cd $topdir

#Pregenerated input list of urls for the desired tiles
#Can do this interactively with web viewer
#Save list by cmd-click and downloading list
#https://download.geoservice.dlr.de/TDM90/

url_list=$1
#url_list=TDM90-url-list.txt

#Download
#Set username and password 
uname=''
#uname=email@domain.edu
#Quotes required for special characters in pw
pw=''
#pw=\''passwd'\'

parallel --progress -j 64 "wget --auth-no-challenge --user=$uname --password=$pw -nc {}" < $url_list
parallel --progress 'unzip {}' ::: *.zip

#Process
export gdal_opt="-co COMPRESS=LZW -co TILED=YES -co BIGTIFF=IF_SAFER"
#export site='conus'
#export proj='+proj=aea +lat_1=36 +lat_2=49 +lat_0=43 +lon_0=-115 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '
export site='hma'
export proj='+proj=aea +lat_1=25 +lat_2=47 +lat_0=36 +lon_0=85 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '

export mosdir='mos_warp_erode'
if [ ! -d $mosdir ] ; then
    mkdir -pv $mosdir
fi

#This is original ndv
ndv=-32767
parallel --progress "gdal_edit.py -a_nodata $ndv {}" ::: TDM1_DEM*_C/DEM/*DEM.tif TDM1_DEM*_C/AUXFILES/*HEM.tif
parallel --progress "gdal_edit.py -a_nodata 0 {}" ::: TDM1_DEM*_C/AUXFILES/*{AM2,AMP,WAM,COV,COM,LSM}.tif

#Mask DEM files using err products
echo "Masking input tiles"
parallel --progress "$srcdir/tandemx_mask.py {}" ::: TDM1_DEM*_C

echo "Reprojecting input tiles"
#Reproject tiles up front
#See thread on GDAL issue: https://github.com/OSGeo/gdal/issues/1620
parallel --progress "gdalwarp -tap -overwrite -r cubic -tr $res $res -t_srs \"$proj\" $gdal_opt {} {.}_aea.tif" ::: TDM1_DEM*_C/DEM/*DEM.tif TDM1_DEM*_C/DEM/*DEM_masked.tif TDM1_DEM*_C/DEM/*DEM_masked_erode.tif

echo "Generating vrt of warped tiles"

#Some issues with this using parallel
#function proc_lyr() {
#    cd $mosdir
#    lyr=$1
#    lyr_list=$(ls ../TDM1*/*/*$lyr.tif)
#    vrt=TDM1_DEM_${res}m_${site}_${lyr}.vrt
#    #Shouldn't need cubic here, but include just in case
#    gdalbuildvrt -r cubic -tr $res $res -tap $vrt $lyr_list
#    cd ..
#}
#export -f proc_lyr

cd $mosdir 

#ext_list="DEM DEM_masked HEM AM2 AMP COM COV LSM WAM"
#parallel --progress "proc_lyr {}" ::: $ext_list

ext_list="DEM_aea DEM_masked_aea DEM_masked_erode_aea"
for lyr in $ext_list
do
    #proc_lyr $ext
    lyr_list=$(ls ../TDM1*/*/*$lyr.tif)
    vrt=TDM1_DEM_${res}m_${site}_${lyr}.vrt
    gdalbuildvrt -r cubic -tr $res $res -tap $vrt $lyr_list
done

#Create shaded relief map for DEM
echo "Generating hillshade"
hs.sh TDM1_DEM_${res}m_${site}_DEM_aea.vrt TDM1_DEM_${res}m_${site}_DEM_masked_aea.vrt TDM1_DEM_${res}m_${site}_DEM_masked_erode_aea.vrt
gdaladdo_ro.sh TDM1_DEM_${res}m_${site}_DEM_aea_hs_az*.tif TDM1_DEM_${res}m_${site}_DEM_masked_aea_hs_az*.tif TDM1_DEM_${res}m_${site}_DEM_masked_erode_aea_hs_az*.tif
