# this document is a step by step configuration file for a fresh ubuntu 14.04 VM
# TODO : create docker version !

# if any of the addition ppa is already present, skipping.
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
sudo apt-get update
sudo apt-get upgrade -y

# apt-get.. to much failed attempt, new method: one by one.
sudo apt-get install -y  build-essential 
sudo apt-get install -y  curl 
sudo apt-get install -y  gdebi-core 
sudo apt-get install -y  pandoc 
sudo apt-get install -y  pandoc-citeproc 
sudo apt-get install -y  libgdal-dev 
sudo apt-get install -y  libcurl4-gnutls-dev 
sudo apt-get install -y  libcairo2-dev 
sudo apt-get install -y  libxt-dev 
sudo apt-get install -y  gdal-bin 
sudo apt-get install -y  libgdal1-dev
sudo apt-get install -y  libgeos-dev 
sudo apt-get install -y  libgeos-3.4.2 
sudo apt-get install -y  r-base 
sudo apt-get install -y  r-base-dev 
sudo apt-get install -y  grass
#sudo apt-get install -y  grass70-dev 
#sudo apt-get install -y  grass70-dev-doc


# Download and install libssl 0.9.8 
if [ `dpkg-query  -l | grep libssl0.9.8 | wc -l` -eq 0 ]
then
  sudo wget --no-verbose http://ftp.us.debian.org/debian/pool/main/o/openssl/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb && \
    dpkg -i libssl0.9.8_0.9.8o-4squeeze14_amd64.deb && \
    rm -f libssl0.9.8_0.9.8o-4squeeze14_amd64.deb
else
  echo "libssl0.9.8 already installed" 
fi


# Download and install shiny server
if [ `dpkg-query  -l | grep shiny-server | wc -l` -eq 0 ]
then
  echo "Download and install shiny-server"
  sudo wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    sudo wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    sudo  gdebi -n ss-latest.deb && \
    sudo rm -f version.txt ss-latest.deb && \
    sudo R -e "install.packages(c('shiny', 'rmarkdown'), repos='http://cran.rstudio.com/')" && \
    sudo cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/ && \
    sudo echo 'options("repos"="http://cran.rstudio.com")' >> /etc/R/Rprofile.site
else
  echo "Shiny-server already installed"
fi

sudo apt-get autoclean
sudo apt-get autoremove


