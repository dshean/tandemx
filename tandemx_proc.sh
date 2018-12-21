#! /bin/bash

#Download and process TanDEM-X 90-m products

#Save list by cmd-click and downloading list
#https://download.geoservice.dlr.de/TDM90/

srcdir=~/src/nasadem
topdir=/nobackup/deshean/data/tandemx/hma/
cd $topdir

#Turn off auto ls after cd
unset -f cd

#Download

url_list=$1
#url_list=TDM90-url-list.txt
#Set username and password 
uname=''
#uname=email@domain.edu
#Quotes required for special characters in pw
pw=''
#pw=\''passwd'\'

#parallel --progress -j 64 "wget --auth-no-challenge --user=$uname --password=$pw -nc {}" < $url_list
#parallel --progress 'unzip {}' ::: *.zip

#Process

export gdal_opt="-co COMPRESS=LZW -co TILED=YES -co BIGTIFF=IF_SAFER"
#export site='conus'
#export proj='+proj=aea +lat_1=36 +lat_2=49 +lat_0=43 +lon_0=-115 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '
export site='hma'
export proj='+proj=aea +lat_1=25 +lat_2=47 +lat_0=36 +lon_0=85 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs '

export mosdir='mos'
if [ ! -d $mosdir ] ; then
    mkdir -pv $mosdir
fi

#This is original ndv
ndv=-32767
parallel --progress "gdal_edit.py -a_nodata $ndv {}" ::: TDM1_DEM*_C/DEM/*DEM.tif TDM1_DEM*_C/AUXFILES/*HEM.tif
parallel --progress "gdal_edit.py -a_nodata 0 {}" ::: TDM1_DEM*_C/AUXFILES/*{AM2,AMP,WAM,COV,COM,LSM}.tif

#Mask DEM files using err products
parallel --progress "$srcdir/tandemx_mask.py {}" ::: TDM1_DEM*_C

cd $mosdir

function proc_lyr() {
    lyr=$1
    lyr_list=$(ls ../TDM1*/*/*$lyr.tif)
    vrt=TDM1_DEM_90m_${site}_${lyr}.vrt
    gdalbuildvrt $vrt $lyr_list
    cd ..
}

export -f proc_lyr
ext_list="DEM DEM_masked HEM AM2 AMP COM COV LSM WAM"
parallel --progress "proc_lyr {}" ::: $ext_list

#Create shaded relief map for DEM
lyr=DEM
#lyr=DEM_masked
vrt=TDM1_DEM_90m_${site}_${lyr}.vrt
gdalwarp -overwrite -r cubic -tr 90 90 -t_srs "$proj" $gdal_opt $vrt ${vrt%.*}_aea.tif
gdaladdo_ro.sh ${vrt%.*}_aea.tif
hs.sh TDM1_DEM_90m_${site}_DEM_aea.tif TDM1_DEM_90m_${site}_DEM_masked_aea.tif
gdaladdo_ro.sh TDM1_DEM_90m_${site}_DEM_aea_hs_az*.tif TDM1_DEM_90m_${site}_DEM_masked_aea_hs_az*.tif
