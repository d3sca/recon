## Recon.bash

## those tools should be installed in able for recon.bash to work:

- nuclei 
- amass 
- assetfinder
- subfinder

## Changes:
- Change nuclei templates location
- Change amass's config.ini location and enter passive subdomains enums api ex. securitytrails , you can find it in https://github.com/OWASP/Amass/blob/master/examples/config.ini


## what the script will do:
it will extract subdomains passively form sourced like  ex. security trails and then check for any 443 or 80 port listening on them then make a file containing all the subdomains and test them with nuclei default templates.




# 403_bypass.sh

#usage ./Bypass-403.sh https://example.com


# Tools
https://github.com/AlexisAhmed/BugBountyToolkit

