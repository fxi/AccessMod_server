#      ___                                  __  ___            __   ______
#     /   |  _____ _____ ___   _____ _____ /  |/  /____   ____/ /  / ____/
#    / /| | / ___// ___// _ \ / ___// ___// /|_/ // __ \ / __  /  /___ \  
#   / ___ |/ /__ / /__ /  __/(__  )(__  )/ /  / // /_/ // /_/ /  ____/ /  
#  /_/  |_|\___/ \___/ \___//____//____//_/  /_/ \____/ \__,_/  /_____/   
#
# Author : Fred Moser <moser.frederic@gmail.com>
# Date : 30 december 2014
#
# Script for provisioning accessmod 5 server on VM created with Vagrant.
# R, shiny-server and grass 7.0 (beta3) will be installed with their
#  dependecies on a fresh ubuntu 14.04.
# Grass and r.walk.accessmod are compiled from source, it could take a while.
# TODO : create docker version
# TODO : after development, clean unecessary packages 
# TODO : avoid individual apt-get command



# in case of multiple provisioning, skip some step.
# if any of the additional ppa is already present, skipping.
if [ `cat /etc/apt/sources.list | grep 'ubuntugis  \| grass-stable \| cran' | wc -l` -eq 0 ]
then
  echo "adding ppa and key in /etc/apt/sources-list"
  # ubuntugis ppa to source
  sudo echo "deb http://ppa.launchpad.net/ubuntugis/ppa/ubuntu precise main" >> /etc/apt/sources.list && \
    sudo echo "deb-src http://ppa.launchpad.net/ubuntugis/ppa/ubuntu precise main" >> /etc/apt/sources.list && \
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 314DF160 && \
    # grass ppa to source
  sudo echo "deb http://ppa.launchpad.net/grass/grass-stable/ubuntu trusty main" >> /etc/apt/sources.list && \ 
  sudo echo "deb-src http://ppa.launchpad.net/grass/grass-stable/ubuntu trusty main" >> /etc/apt/sources.list && \
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 26D57B27 && \
    # R ppa to source
  sudo echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list && \
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
else
  echo "ppa seems already installed, skipping for all"
fi

# grass, R and geo tools
# apt-get didn't like multiline arguments : sending one by one.
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y build-essential 
sudo apt-get install -y curl 
sudo apt-get install -y gdebi-core 
sudo apt-get install -y pandoc 
sudo apt-get install -y pandoc-citeproc 
sudo apt-get install -y libcurl4-gnutls-dev 
sudo apt-get install -y libxt-dev 
sudo apt-get install -y r-base 
sudo apt-get install -y r-base-dev 
sudo apt-get install -y lesstif2-dev 
sudo apt-get install -y dpatch 
sudo apt-get install -y libtiff4-dev 
sudo apt-get install -y libfftw3-dev 
sudo apt-get install -y libxmu-dev 
sudo apt-get install -y libfreetype6-dev 
sudo apt-get install -y autoconf2.13 
sudo apt-get install -y autotools-dev 
sudo apt-get install -y doxygen 
sudo apt-get install -y libsqlite3
sudo apt-get install -y flex 
sudo apt-get install -y bison 
sudo apt-get install -y libgeos-dev 
sudo apt-get install -y libgeos-3.4.2 -dev 
sudo apt-get install -y libcairo2-dev 
sudo apt-get install -y gdal-bin 
sudo apt-get install -y libgdal1-dev  
sudo apt-get install -y libgdal1-1.5.0 
sudo apt-get install -y libproj-dev  
sudo apt-get install -y libproj0 
sudo apt-get install -y proj-data 
sudo apt-get install -y libgsl0-dev
sudo apt-get install -y python-numpy
sudo apt-get install -y python-dev
sudo apt-get install -y wx-common
sudo apt-get install -y python-wxgtk2.8
sudo apt-get install -y git

# script to install shiny server.
mkdir -p $HOME/downloads
cd $HOME/downloads

# Download and install libssl 0.9.8 
if [ `sudo dpkg-query  -l | grep libssl0.9.8 | wc -l` -eq 0 ]
then
  sudo wget --no-verbose http://ftp.us.debian.org/debian/pool/main/o/openssl/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb && \
    sudo dpkg -i libssl0.9.8_0.9.8o-4squeeze14_amd64.deb && \
    sudo  rm -f libssl0.9.8_0.9.8o-4squeeze14_amd64.deb
else
  echo "libssl0.9.8 already installed" 
fi


# Download and install shiny server
if [ `sudo dpkg-query  -l | grep shiny-server | wc -l` -eq 0 ]
then
  echo "Download and install shiny-server"

  sudo wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    sudo wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    sudo  gdebi -n ss-latest.deb && \
    sudo  rm -f version.txt ss-latest.deb 
  sudo echo 'options("repos"="http://cran.rstudio.com")' >> /etc/R/Rprofile.site

  #sudo cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/
else
  echo "Shiny-server already installed"
fi

# R packages and dependencies of accessmod shiny to downloads
sudo R -e "install.packages(c('shiny','rmarkdown','gdalUtils','spgrass6','raster','rgdal','tools','maps','R.utils','htmltools','shinysky','devtools','plyr'))"
sudo  R -e "devtools::install_github('AnalytixWare/ShinySky')"

## install accessmod shiny
sudo mkdir -p /srv/shiny-server/data/grass
sudo mkdir -p /srv/shiny-server/logs
# set a time stamp if installation in logs..
sudo echo -e `date +"%Y-%m-%d"`" \t vagrant provisioning date \t TRUE" > /srv/shiny-server/logs/logs.txt
sudo git clone https://github.com/fxi/accessModShiny.git /srv/shiny-server/accessmod
# index.html : redirection. Could also be a welcome screen or something.
# if no usage of this page is done, change config file (/etc/shiny-server/shiny-server.conf )
sudo echo "<html><head><meta http-equiv=\"refresh\" content=\"0; url=accessmod\"></head></html>" > /srv/shiny-server/index.html
# shiny own the house now.
sudo chown -R shiny:shiny /srv/shiny-server

# install grass and r.walk.accessmod
mkdir -p $HOME/downloads
cd $HOME/downloads

wget http://grass.osgeo.org/grass70/source/grass-7.0.0beta3.tar.gz
tar xvf grass-7.0.0beta3.tar.gz
cd grass-7.0.0beta3/
sudo ./configure


# flags as recommanded in http://grass.osgeo.org/grass70/source/INSTALL
sudo CFLAGS="-O2 -Wall" LDFLAGS="-s" ./configure \
  --with-cxx \
  --with-sqlite \
  --with-blas \
  --enable-largefile \
  --with-readline \
  --without-tcltk \
  --with-freetype \
  --without-opengl \
  --with-freetype-includes=/usr/include/freetype2 \
  --with-proj-share=/usr/share/proj \
  --without-x \
  --without-wxwidgets

sudo make
sudo make install
cd $HOME/downloads
# compile r.walk.accessmod
git clone https://github.com/fxi/rWalkAccessmod.git rWalkAccessmod
cd rWalkAccessmod
sudo make MODULE_TOPDIR=/usr/local/grass-7.0.0beta3

# clean 
apt-get autoclean
apt-get autoremove
rm -rf $HOME/downloads


