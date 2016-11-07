#      ___                                  __  ___            __   ______
#     /   |  _____ _____ ___   _____ _____ /  |/  /____   ____/ /  / ____/
#    / /| | / ___// ___// _ \ / ___// ___// /|_/ // __ \ / __  /  /___ \  
#   / ___ |/ /__ / /__ /  __/(__  )(__  )/ /  / // /_/ // /_/ /  ____/ /  
#  /_/  |_|\___/ \___/ \___//____//____//_/  /_/ \____/ \__,_/  /_____/   
#
# Author : Fred Moser <moser.frederic@gmail.com>
# Date : 3.11.2016
#
# Script for provisioning accessmod 5 server on VM created with Vagrant.
#  dependecies on a fresh ubuntu 16.04.
# Grass and r.walk.accessmod are compiled from source, it could take a while.


set -e

#
# simple way to add repository (not in a ppa: form) and add corresponding key.
# add-apt-repository can handle custom repo, but the key server option did not always work.
# So, going on with a simple script.
#
function addToAptSource
{
  set -e
  if [ `grep "$1" /etc/apt/sources.list | wc -l` -eq 0 ]
  then
    echo "Add $1 to sources list"
    # add new source to apt source.list
    echo $1 >> /etc/apt/sources.list
    # if a second argument is given (the key url), add it with apt-key
    if [ `echo $2 | wc -l ` -ne 0 ];
    then
      echo "Add $2 to keys"
      wget --quiet -O - "$2" | \
        apt-key add -
    else
      echo "No key given for $1"
    fi
  else
    echo "$1 seems to be already present in sources. skipping"
  fi
}

#
# print a message to console with 
#
function printMsg 
{
  echo $(for i in $(seq 1 80);do echo -n "-";done;);  
  echo $1;
  echo $(for i in $(seq 1 80);do echo -n "-";done;);
}

#
# Set and create main directory
#
dirReceipts="/home/vagrant/receipts"
dirDownloads="/home/vagrant/downloads"
dirShinyApp="/srv/shiny-server"
dirAccessmod="$dirShinyApp/accessmod"
dirData="$dirShinyApp/data"
dirLogs="$dirShinyApp/logs"
dirHelp="$dirShinyApp/help"
dirDataCache="$dirData/cache"
dirDataGrass="$dirData/grass"

mkdir -p $dirReceipts
mkdir -p $dirDownloads
mkdir -p $dirShinyApp
mkdir -p $dirData
mkdir -p $dirLogs
mkdir -p $dirHelp
mkdir -p $dirDataCache
mkdir -p $dirDataGrass


#if [ 0 -eq 1 ] 
#then 
if [[ ! -e $dirReceipts/apt_source ]]
then
  printMsg "receipt apt_source not found, adding apt sources "
  # UBUNTU GIS
  addToAptSource \
    "deb http://ppa.launchpad.net/ubuntugis/ubuntugis-unstable/ubuntu xenial main" \
    "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x089EBE08314DF160" 

 # R
  addToAptSource \
    "deb http://cran.univ-lyon1.fr/bin/linux/ubuntu xenial/" \
    "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xE084DAB9"

 # NGINX
  addToAptSource \
    "deb http://ppa.launchpad.net/nginx/stable/ubuntu xenial main" \
    "http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0x00A6F0A3C300EE8C"

  touch $dirReceipts/apt_source
else
  printMsg "receipt add_source exists, skipping"
fi

#
# Get dependencies
#
if [[ ! -e $dirReceipts/apt_depedencies ]]
then
  printMsg "no receipt apt_dependencies, clean, update and install packages "
  # Install dependencies:
  # removes all packages from the package cache
  apt-get clean
  # update apt-get
  apt-get -qy update
  # install dependencies
  apt-get -qy install \
    libssl-dev \
    build-essential \
    curl \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libxt-dev \
    r-base \
    r-base-dev \
    libpawlib-lesstif3-dev \
    dpatch \
    libfftw3-dev \
    libxmu-dev \
    autoconf2.13 \
    autotools-dev \
    doxygen \
    flex \
    bison \
    libgeos-dev \
    libgeos-3.5.0 \
    gdal-bin \
    libgdal-dev \
    proj-bin \
    proj-data \
    libproj-dev \
    libproj9 \
    libgsl0-dev \
    git-core \
    libv8-dev \
    sqlite3 libsqlite3-dev \
    python-numpy

  # set a reminder
  touch $dirReceipts/apt_depedencies
else
  printMsg "receipt apt_depedencies found, skipping "
fi



#
# Copy demo data
#
if [[ ! -e $dirReceipts/demo_data ]]
then
  printMsg "copy demo data"
  # download
wget --no-verbose "https://rawgit.com/fxi/AccessMod_server/153cfdda2776c81fe94e66c3ee1100b0fd412fcc/demo/demo.tar.gz?raw=true" -O data.tar.gz
  # untar
tar xvfz data.tar.gz 
mv demo $dirDataGrass 
chown -R shiny:shiny $dirDataGrass 
  # clean
  rm data.tar.gz
  # create receipt
  touch $dirReceipts/demo_data
else
  printMsg "demo_data receipt found skipping"
fi




#
# GIT settings
#
if [[ ! -e $dirReceipts/git_setting ]]
then
  printMsg "set git global"
  sudo git config --global user.email "f@fxi.io"
  sudo git config --global user.name "fxi (accessmod server)"
  touch $dirReceipts/git_setting
else
  printMsg "git_setting found, skipping"
fi

#
# install shiny, devtools and packrat
#
if [[ ! -e $dirReceipts/r_dep ]]
then 
  printMsg "No receipt r_dep. Install shiny, devtools and packrat"
  echo 'options("repos"="http://cran.rstudio.com")' >> /etc/R/Rprofile.site
  Rscript -e "install.packages(c('devtools'))"
  Rscript -e "devtools::install_github('hadley/devtools')"
  Rscript -e "devtools::install_github('rstudio/shiny')"
  Rscript -e "devtools::install_github('rstudio/packrat')"
  touch $dirReceipts/r_dep
else
  printMsg "receipt r_dep found, skipping"
fi

#
# SHINY SERVER
#
if [[ ! -e $dirReceipts/r_shiny_server ]]
then
  printMsg "No receipt r_shiny_server, add and install shiny server"
  cd $dirDownloads
  # get the last version number
  SHINYVERSION=`curl https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION`
  # Get deb
  wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$SHINYVERSION-amd64.deb" -O shiny-server-latest.deb
  gdebi -n shiny-server-latest.deb
  rm -f shiny-server-latest.deb
  if [[ -e "$dirShinyApp/sample-apps" ]]
  then 
    rm -rf "$dirShinyApp/sample-apps"
  fi
  touch $dirReceipts/r_shiny_server
else
  printMsg "receipt r_shiny_server found, skipping"
fi

#
# AccessMod 
#
if [[ ! -e $dirReceipts/accessmod ]]
then
  printMsg "No receipt accessmod, install or update"


  if [[ ! -e $dirAccessmod/server.R ]]
  then
    printMsg "Accessmod server.R does not exists, clone and init"

    sudo git clone --depth 1 https://github.com/fxi/AccessMod_shiny.git $dirAccessmod 
    cd $dirAccessmod 
    Rscript packrat/init.R --bootstrap-packrat
    sudo echo "<html><head><meta http-equiv=\"refresh\" content=\"0; url=accessmod\"></head></html>" > $dirShinyApp/index.html
    sudo echo -e `date +"%Y-%m-%d"`" \t log \t vagrant provisioning date" > $dirLogs/logs.txt
  else 
    cd $dirAccessmod
    git pull
    Rscript -e "packrat::restore()" 
    touch restart.txt
  fi
  sudo chown -R shiny:shiny $dirShinyApp
  touch $dirReceipts/accessmod
else 
  printMsg "receipt accessmod found skipping"
fi

#
# GRASS
#
if [[ ! -e $dirReceipts/grass ]]
then
  printMsg "Compile and install grass"

  # install grass and r.walk.accessmod
  cd $dirDownloads 
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


  sudo make 
  sudo make install
  touch $dirReceipts/grass
else
  printMsg "Grass receipt found, skip"
fi

#
# r.walk accessmod
#
if [[ ! -e $dirReceipts/accessmod_r_walk ]]
then
  printMsg "install accessmod_r_walk"
  cd $dirDownloads 
  # compile r.walk.accessmod
  git clone https://github.com/fxi/AccessMod_r.walk.git AccessMod_r_walk
  cd AccessMod_r_walk
  sudo make MODULE_TOPDIR=/usr/local/grass-7.0.1
  touch $dirReceipts/accessmod_r_walk
else
  printMsg "accessmod_r_walk receipt found skipping"
fi





#
# server "welcome screen" sort of.
#

if [[ ! -e $dirReceipts/accessmod_screen ]]
then
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
echo "               -- WEB SERVER --                 " >> /etc/issue
echo "#-----------------------------------------------#" >> /etc/issue
echo " To use AccessMod 5," >> /etc/issue
echo " type this URL in a modern browser : " >> /etc/issue
echo " http://localhost:8080">> /etc/issue
echo "#-----------------------------------------------#" >> /etc/issue
echo " Please report any issue :" >> /etc/issue
echo "   - Web application:  https://github.com/fxi/AccessMod_shiny" >> /etc/issue
echo "   - Virtual machine:  https://github.com/fxi/AccessMod_server" >> /etc/issue
echo "   - Cumulative cost function: https://github.com/fxi/AccessMod_r.walk" >> /etc/issue
echo "#-----------------------------------------------#" >> /etc/issue
echo "Email: Fred Moser f@fxi.io" >> /etc/issue
' > accessmodmessage

  sudo chmod +x accessmodmessage
  sudo mv accessmodmessage /etc/network/if-up.d/accessmodmessage
  touch $dirReceipts/accessmod_screen
else
  printMsg "accessmod_screen receipt found, skipping"
fi

#
# Clean apt and download
#
if [[ 0 -eq 0 ]]
then
  printMsg "Clean apt and downloads"
  # clean 
  sudo apt-get autoclean -y
  sudo apt-get autoremove -y
  rm -rf $dirDownloads

  # Remove APT files
  find /var/lib/apt -type f | sudo  xargs rm -f

  # Remove Linux headers
  sudo rm -rf /usr/src/linux-headers*
fi




#
# update time zone
#

if [[ -e $dirReceipts/update_time_zone ]]
then
  # based on http://askubuntu.com/questions/323131/setting-timezone-from-terminal
  printMsg "Update time zone script "
  # check if there is heading space
echo 'description "Update time zone"
author "Fred Moser"
version "0.0.1"
start on net-device-up
stop on runlevel [!2345]
console output
respawn
script
TZ=$(wget -qO - http://geoip.ubuntu.com/lookup | sed -n -e "s/.*<TimeZone>\(.*\)<\/TimeZone>.*/\1/p")
export TZ
exec su -s /bin/sh -c "su - timedatectl set-timezone $TZ"
end script
' > /etc/init/updateTz.conf
else
  printMsg "update_time_zone receipt found, skiping"
fi
