#      ___                                  __  ___            __   ______
#     /   |  _____ _____ ___   _____ _____ /  |/  /____   ____/ /  / ____/
#    / /| | / ___// ___// _ \ / ___// ___// /|_/ // __ \ / __  /  /___ \  
#   / ___ |/ /__ / /__ /  __/(__  )(__  )/ /  / // /_/ // /_/ /  ____/ /  
#  /_/  |_|\___/ \___/ \___//____//____//_/  /_/ \____/ \__,_/  /_____/   
#
# Author : Fred Moser <moser.frederic@gmail.com>
# Date : 7 january 2015
#
# Script for provisioning accessmod 5 server on VM created with Vagrant.
# R, shiny-server and grass 7.0 (beta3) will be installed with their
#  dependecies on a fresh ubuntu 14.04.
# Grass and r.walk.accessmod are compiled from source, it could take a while.
# TODO : create docker version
# TODO : after development, clean unecessary packages 
# TODO : avoid individual apt-get command


#if [ 0 -eq 1 ] 
#then 

  echo " set source repository "
  echo "in case of multiple provisioning, skip some step."
  echo "if any of the additional ppa is already present, skipping."
  if [ `cat /etc/apt/sources.list | grep 'ubuntugis  \| grass-stable \| cran' | wc -l` -eq 0 ]
  then
    echo "adding ppa and key in /etc/apt/sources-list"
    echo" ubuntugis ppa to source"
    sudo echo "deb http://ppa.launchpad.net/ubuntugis/ppa/ubuntu precise main" >> /etc/apt/sources.list && \
      sudo echo "deb-src http://ppa.launchpad.net/ubuntugis/ppa/ubuntu precise main" >> /etc/apt/sources.list && \
      sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 314DF160 && \
      echo "grass ppa to source"
    sudo echo "deb http://ppa.launchpad.net/grass/grass-stable/ubuntu trusty main" >> /etc/apt/sources.list && \ 
    sudo echo "deb-src http://ppa.launchpad.net/grass/grass-stable/ubuntu trusty main" >> /etc/apt/sources.list && \
      sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 26D57B27 && \
      echo " R ppa to source"
    sudo echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list && \
      sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
  else
    echo "ppa seems already installed, skipping for all"
  fi






  # apt-get didn't like multiline arguments : sending one by one. NOTE: Why?
  echo "install packages"
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
  #sudo apt-get install -y libtiff4-dev 
  sudo apt-get install -y libfftw3-dev 
  sudo apt-get install -y libxmu-dev 
  #sudo apt-get install -y libfreetype6-dev 
  sudo apt-get install -y autoconf2.13 
  sudo apt-get install -y autotools-dev 
  sudo apt-get install -y doxygen 
  sudo apt-get install -y libsqlite3
  sudo apt-get install -y flex 
  sudo apt-get install -y bison 
  sudo apt-get install -y libgeos-dev 
  sudo apt-get install -y libgeos-3.4.2 -dev 
  #sudo apt-get install -y libcairo2-dev 
  sudo apt-get install -y gdal-bin 
  sudo apt-get install -y libgdal1-dev  
  sudo apt-get install -y libgdal1-1.5.0 
  sudo apt-get install -y libproj-dev  
  sudo apt-get install -y libproj0 
  sudo apt-get install -y proj-data 
  sudo apt-get install -y libgsl0-dev
  #sudo apt-get install -y python-numpy
  #sudo apt-get install -y python-dev
  #sudo apt-get install -y wx-common
  #sudo apt-get install -y python-wxgtk2.8
  sudo apt-get install -y git
  sudo apt-get install -y libv8-dev #V8 JavaScript engine used by geojsonio package in R
  sudo apt-get install -y sqlite

sudo git config --global user.email "f@fxi.io"
sudo git config --global user.name "fxi (accessmod server)"




  echo "Install shiny server if needed"
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

    # get the version to wget
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

  # remove default shiny sample apps :
  sudo rm -rf /srv/shiny-server/*


  echo "Install R packages"
  sudo mkdir -p /srv/shiny-server/data/grass
  sudo mkdir -p /srv/shiny-server/data/cache
  sudo mkdir -p /srv/shiny-server/logs
  sudo mkdir -p /srv/shiny-server/help

  # R package and dependecies. Main package will be installed with packrat.
  sudo Rscript -e "install.packages(c('devtools'))"
  sudo Rscript -e "devtools::install_github('hadley/devtools')"
  sudo Rscript -e "devtools::install_github('rstudio/packrat')"


echo "Install AccessMod web app and dependencies using packrat."

# remove old version of exist
sudo rm -rf /srv/shiny-server/accessmod 2> /dev/null
sudo git clone https://github.com/fxi/AccessMod_shiny.git /srv/shiny-server/accessmod
#packrat test version
#sudo git clone -b packrat https://github.com/fxi/AccessMod_shiny.git /srv/shiny-server/accessmod-packrat
cd /srv/shiny-server/accessmod
sudo R --vanilla --slave -f packrat/init.R --args --bootstrap-packrat
cd -
# create index html for accessmod redirection
sudo echo "<html><head><meta http-equiv=\"refresh\" content=\"0; url=accessmod\"></head></html>" > /srv/shiny-server/index.html
sudo echo -e `date +"%Y-%m-%d"`" \t log \t vagrant provisioning date" > /srv/shiny-server/logs/logs.txt
sudo chown -R shiny:shiny /srv/shiny-server/



echo "Compile and install grass"

# install grass and r.walk.accessmod
mkdir -p $HOME/downloads
cd $HOME/downloads
wget http://grass.osgeo.org/grass70/source/grass-7.0.1.tar.gz
# gist containig Makefile for GRASS without gui and WX dependents DIRS. TODO: this is certainly clumsy... Search in configure script how to remove all wxpython dependencies (temporal modules, scripts...?) instead !
wget https://gist.githubusercontent.com/fxi/9cbe9223aa4dbcf01401/raw/8fb5b7f15fb90ebbade9b20dfe5aae22a813b725/Makefile
# wget http://grass.osgeo.org/grass70/source/grass-7.0.0beta3.tar.gz
tar xvf grass-7.0.1.tar.gz
# remplace Makefile by the modified one.
mv Makefile grass-7.0.1/Makefile
cd grass-7.0.1/
# http://stackoverflow.com/questions/10132904/when-compiling-programs-to-run-inside-a-vm-what-should-march-and-mtune-be-set-t
# flags as recommanded in http://grass.osgeo.org/grass70/source/INSTALL
CFLAGS="-O2 -Wall -march=x86-64 -mtune=native" LDFLAGS="-s" ./configure \
  --without-opengl \
  --without-wxwidgets \
  --without-cairo \
  --without-freetype \
  --without-x \
  --without-tiff \
  --with-geos \
  --disable-largefile \
  --with-cxx \
  --with-sqlite \
  --with-readline \
  --without-tcltk \
  --without-opengl \
  --with-proj-share=/usr/share/proj \
  --without-x \
  --without-wxwidgets

#- configuration summary
#-GRASS is now configured for:  x86_64-unknown-linux-gnu
#-
#-Source directory:           /home/vagrant/downloads/grass-7.0.0
#-Build directory:            /home/vagrant/downloads/grass-7.0.0
#-Installation directory:     ${prefix}/grass-7.0.0
#-Startup script in directory:${exec_prefix}/bin
#-C compiler:                 gcc -O2 -Wall -march=x86-64 -mtune=native
#-C++ compiler:               c++ -g -O2
#-Building shared libraries:  yes
#-OpenGL platform:            none
#-
#-MacOSX application:         no
#-MacOSX architectures:
#-MacOSX SDK:
#-
#-BLAS support:               no
#-C++ support:                yes
#-Cairo support:              no
#-DWG support:                no
#-FFTW support:               yes
#-FreeType support:           no
#-GDAL support:               yes
#-GEOS support:               yes
#-LAPACK support:             no
#-Large File support (LFS):   yes
#-libLAS support:             no
#-MySQL support:              no
#-NetCDF support:             no
#-NLS support:                no
#-ODBC support:               no
#-OGR support:                yes
#-OpenCL support:             no
#-OpenGL support:             no
#-OpenMP support:             no
#-PNG support:                yes
#-POSIX thread support:       no
#-PostgreSQL support:         no
#-Readline support:           yes
#-Regex support:              yes
#-SQLite support:             yes
#-TIFF support:               no
#-wxWidgets support:          no
#-X11 support:                no
#-


sudo make # no root access needed here... but permission error (in demolocation??) when installing custom module. Strange.
sudo make install
cd $HOME/downloads
# compile r.walk.accessmod
git clone https://github.com/fxi/AccessMod_r.walk.git AccessMod_r_walk
cd AccessMod_r_walk
sudo make MODULE_TOPDIR=/usr/local/grass-7.0.1



#amip=`ip addr | grep -Po "(?!(inet 127.\d.\d.1))(?!(inet 10.\d.\d.\d))(inet \K(\d{1,3}\.){3}\d{1,3})"`

# set message if Virtual machine is launched directly 
echo '#!/bin/sh
if [ "$METHOD" = loopback ]; then
  exit 0
fi

# Only run from ifup.
if [ "$MODE" != start ]; then
  exit 0
fi

# cp /etc/issue-orig /etc/issue
echo "                                                " > /etc/issue
echo " _____                     _____       _    ___ " >> /etc/issue
echo "|  _  |___ ___ ___ ___ ___|     |___ _| |  |  _|" >> /etc/issue
echo "|     |  _|  _| -_|_ -|_ -| | | | . | . |  |_  |" >> /etc/issue
echo "|__|__|___|___|___|___|___|_|_|_|___|___|  |___|" >> /etc/issue
echo "                                                " >> /etc/issue
echo "#-----------------------------------------------#" >> /etc/issue
echo " THIS IS A DEVELOPMENT SERVER" >> /etc/issue
echo " To launch AccessMod:" >> /etc/issue
echo " Type this URL in a modern browser" >> /etc/issue
echo " http://localhost:8080">> /etc/issue
echo "#-----------------------------------------------#" >> /etc/issue
echo " Please report any issue :" >> /etc/issue
echo "   - Web application:  https://github.com/fxi/AccessMod_shiny" >> /etc/issue
echo "   - Virtual machine:  https://github.com/fxi/AccessMod_server" >> /etc/issue
echo "   - Cumulative cost function: https://github.com/fxi/AccessMod_r.walk" >> /etc/issue
echo "#-----------------------------------------------#" >> /etc/issue
echo "Email: Fred Moser f@fxi.io"
' > accessmodmessage

sudo chmod +x accessmodmessage
sudo mv accessmodmessage /etc/network/if-up.d/accessmodmessage


# clean 
sudo apt-get autoclean -y
sudo apt-get autoremove -y
rm -rf $HOME/downloads

# Remove APT files
find /var/lib/apt -type f | sudo  xargs rm -f

# Remove Linux headers
sudo rm -rf /usr/src/linux-headers*

# update time zone
sudo mv /vagrant/updateTz.sh /etc/init.d/updateTz.sh
sudo chmod +x /etc/init.d/updateTz.sh


