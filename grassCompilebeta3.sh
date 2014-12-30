

mkdir -p /home/vagrant/downloads
cd /home/vagrant/downloads
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
cd ..
# compile r.walk.accessmod
git clone https://github.com/fxi/rWalkAccessmod.git rWalkAccessmod
cd rWalkAccessmod
sudo make MODULE_TOPDIR=/usr/local/grass-7.0.0beta3
