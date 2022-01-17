#!/usr/bin/env bash

echo "
DESCARECON
";

nuclei --update-templates --silent

read -p "Enter domain names seperated by 'space' : " input
for i in ${input[@]}
do

echo "
.
.
.
Scan started for $i
" | notify --silent

mkdir $i

assetfinder -subs-only $i >> $i/assetfinder.txt
subfinder -d $i -o $i/subfinder.txt
cat $i/assetfinder.txt $i/subfinder.txt > $i/subf.txt
amass enum --config /home/config.ini --scripts /root/tools/scripts -passive -src -d $i -dir . ###CHANGE_CONFIG_FILE_LOCATION
cat amass.txt | awk -F "]" '{print $2}' > $i/amass.txt
echo "subdomains saved at $i/amass.txt."
cat $i/amass.txt $i/subf.txt > $i/non-http_list.txt
cat $i/non-http_list.txt | httpx > $i/subdomains.txt
echo "subdomains saved at $i/subdomains.txt."
rm amass.txt
echo "Scan for default-logins started."  ########CHANGE_NUCLEI_TEMPLATES_LOCATIONS
nuclei -l $i/subdomains.txt -t /nuclei-templates/default-logins/ -o $i/default-logins.txt
echo "Scan for default-logins completed." 
echo "Scan for exposures started." 
nuclei -l $i/subdomains.txt -t /nuclei-templates/exposures/ -o $i/exposures.txt 
echo "Scan for exposures completed." 
echo "Scan for misconfigurations started."
nuclei -l $i/subdomains.txt -t /nuclei-templates/misconfiguration/ -o $i/misconfiguration.txt
echo "Scan for misconfigurations completed." 
echo "Scan for takeovers started." 
nuclei -l $i/subdomains.txt -t /nuclei-templates/takeovers/ -o $i/takeovers.txt
echo "Scan for takeovers completed." 
echo "Scan for vulnerabilities started."
nuclei -l $i/subdomains.txt -t /nuclei-templates/vulnerabilities/ -o $i/vulnerabilities.txt
echo "Scan for vulnerabilities completed." 
echo "Scan for exposed-panels started."
nuclei -l $i/subdomains.txt -t /nuclei-templates/exposed-panels/ -o $i/exposed-panels.txt
echo "Scan for exposed-panels completed." 
echo "
.
.
.
Scan finished for $i
" | notify --silent
done
