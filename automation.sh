#!/bin/bash

sudo apt update -y

#Checking whether apache2 package is installed or not

dpkg -s apache2 &> /dev/null


if [ $? -ne 0  ]
then
        echo "Apache2 is not installed. Installing it now."
        sudo apt-get install apache2 -y
else
        echo "Apache2 is installed."
fi


#Checking whether awscli package is installed ornot
dpkg -s awscli &> /dev/null


if [ $? -ne 0 ]
then
        echo "AWS CLI is not installed. Installing it now."
        sudo apt install awscli -y
else
        echo "AWS CLI is already installed."

fi

#Ensuring that apache2 service is active and enabled

is_active="$(systemctl is-active apache2)"
is_enabled="$(systemctl is-enabled apache2)"
if [ "${is_active}" = "active" ]
then
        echo "Apache2 service is running fine."
else
        echo "Apache2 is not active, starting the service."
        systemctl start apache2

fi

if [ "${is_enabled}" = "enabled" ]
then
        echo "Apache2 service is already enabled."
else
        echo "Apache2 is not enabled, enabling it."
        systemctl enable apache2

fi

timestamp=$(date '+%d%m%Y-%H%M%S')
myname="Bhuvnesh"
filename="${myname}-httpd-logs-${timestamp}.tar"
s3_bucket="upgrad-bhuvnesh"

cd /var/log/apache2/
tar -cvf /tmp/$filename *.log

FILE=/var/www/html/inventory.html

if [ -f "$FILE" ]
then
        echo "$FILE exists."
else
        echo -e "Log Type\tDate Created\tType\tSize" > $FILE

fi


#Bookeeping
SIZE=$(ls -lh "/tmp/$filename" | awk '{print  $5}')

echo -e "$(awk -F- '{print $2"-"$3}'  <<< $filename)\t$timestamp\t$(awk -F. '{print $2}'  <<< $filename)\t$SIZE" >> $FILE




#Copying the file to the S3 bucket
aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar


#Cron Job


cronfile=/etc/cron.d/automation
if [ -f "$cronfile" ]
then
        echo "$cronfile exists."
else
        echo -e "0 8 * * * root ./root/Automation_Project/automation.sh" > $cronfile

fi
