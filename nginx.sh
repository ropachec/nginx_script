#!/bin/bash

valida_nginx=$(rpm -qa | grep nginx)
server_msg="Hello World - $(hostname)!"
site_path="/usr/share/nginx/html/site"
server_path="/etc/nginx/conf.d"

func_Header(){

	cat << EOF | sudo tee ${site_path}/index.html
<!-- Adicionando server-root custom-init-script -->
<html>
<head>
<title>Hello</title>
</head>
<body><p>${server_msg}</p></body>
</html>
EOF

}

func_Perm(){

	sudo chown -R nginx:nginx ${site_path}
	sudo chcon -Rt httpd_sys_content_t ${site_path}

}

func_Enable(){

	check_enable=$(systemctl is-enabled nginx)
	if [ "${check_enable}" == "disabled" ];then
			
		sudo systemctl enable --now nginx.service
			
	fi

}

func_Init(){

	check_status=$(sudo systemctl is-active nginx)
	if [ "${check_status}" != "active" ];then

		sudo systemctl start nginx
		func_Enable
		
	
	else
		sudo systemctl restart nginx
		func_Enable
	fi			
}

func_Firewall(){

	firewall_rule=$(sudo firewall-cmd --list-services | grep -wc http)
	if [ ${firewall_rule} -lt 1 ];then
	
		sudo firewall-cmd --add-service=http --permanent
		sudo firewall-cmd --reload
	fi
}

func_validaEntradas(){

	if [ ! -f ${site_path}/index.html ];then
		
		if [ -d ${site_path} ];then

			sudo touch ${site_path}/index.html
		else

			sudo mkdir -p ${site_path}
			sudo touch ${site_path}/index.html
		fi
	fi
	
	export valida_ent_http=$(grep -c "custom-init-script" ${site_path}/index.html)
	
}

if [ -z "${valida_nginx}" ];then

	sudo dnf install -y nginx
fi

func_validaEntradas
if [ ${valida_ent_http} -eq 0 ];then

	func_Header
	func_Perm	
	func_Firewall
	func_Init
else

	func_Init
	func_Firewall

fi
