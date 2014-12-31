# AccessMod 5.0 server configuration

This is the configuration files to configure a virtual private server providing accessmod 5.0 services.

## Usage

### Prerequisite  
- Knowing how to install software on your computer.

### First step
1. To use this virtual server on mac, linux or windows, clone or download this git repository from github to a folder on your computer (e.g. linux or mac `$HOME/vm/accessModServer` ;  windows `c:\Users\<yourname>\vm\accessModServer`  ) 
2. Download and install Vagrant from https://www.vagrantup.com

### Linux and Mac
1. open a terminal and go to accessmod server repository. (e.g. cd `$HOME/vm/accessModServer`)
2. type : `vagrant up` (this could take a while to complete)
3. open a browser (chrome, safari, firefox, opera) and go to http://localhost:8080/accessModShiny.git/

### Windows
1. Navigate to the accessmod server repository (e.g. `c:\Users\<yourname>\vm\accessModServer`)
2. Holding the shift key, right click on the folder, then chose "open command window here"
3. type: `vagrant up` (this could take a while to complete)
4. open a browser (chrome, safari, firefox, opera) and go to http://localhost:8080/accessModShiny.git/
