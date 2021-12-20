#!/bin/bash
# variable will be populated by terraform template

yum update -y

amazon-linux-extras install -y nginx1


db_username=${db_username}
region_name=${region_name}
db_RDS_endpoint=${db_RDS_endpoint}

cat <<EOF > /usr/share/nginx/html/index.html
<html>
<body bgcolor="black">
<h2><font color="gold">Made by ${db_username} <font color="red">Terraform version v1.1.1</font></h2><br><p>
<font color="green">Server in Region ${region_name} <font color="aqua">$myip<br><br>
<font color="magenta">
<b>RDS endpoint - ${db_RDS_endpoint}</b>
</body>
</html>
EOF


systemctl start nginx
systemctl enable  httpd.service
yes
