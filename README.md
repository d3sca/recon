## Recon.bash

## those tools should be installed in able for recon.bash to work:

- nuclei with templates locations you should change
- amass with config.ini and api's form passive subdomains scanner ex. securitytrails 
- assetfinder
- subfinder


## what the script will do:
it will extract subdomains passively form sourced like  ex. security trails and then check for any 443 or 80 port listening on them then make a file containing all the subdomains and test them with nuclei default templates.




# 403_bypass.sh

#usage ./Bypass-403.sh https://example.comou


