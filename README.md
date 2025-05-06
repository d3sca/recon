## Recon.bash

## installation:
- Save the script as install_recon_tools.sh
- Make it executable: `chmod +x install_recon_tools.sh`
- Run it with sudo: `sudo ./install.sh`

The script will do the following:
- Install required system dependencies
- Install Go (if not already installed)
- Install all required security tools
- Create a basic configuration file for amass

## Changes:
- Change amass's config.ini add enum api , ex. securitytrails etc...

## Usage:
1. Make the script executable:
`chmod +x domain_recon.sh`.
2. Run the script:
`./domain_recon.sh`.
3. When prompted, enter the domain names separated by spaces:
`Enter domain names separated by space: example.com test.org`.


## what the script will do:
it will extract subdomains passively form sourced like  ex. security trails and then check for any 443 or 80 port listening on them then make a file containing all the subdomains and test them with nuclei default templates.

## Output structure:
recon_results_YYYYMMDD_HHMMSS/
├── example.com/
│   ├── amass.txt
│   ├── assetfinder.txt
│   ├── default-logins.txt
│   ├── exposed-panels.txt
│   ├── exposures.txt
│   ├── fuzzing/
│   │   ├── example_com_dirs.json
│   │   └── example_com_urls.txt
│   ├── fuzzed_endpoints.txt
│   ├── all_targets.txt
│   ├── misconfiguration.txt
│   ├── non-http_list.txt
│   ├── subdomains.txt
│   ├── subfinder.txt
│   ├── summary.md
│   ├── takeovers.txt
│   └── vulnerabilities.txt
└── test.org/
    └── [same structure as above]



