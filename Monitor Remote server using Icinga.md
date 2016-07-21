# Sử dụng Icinga monitor máy chủ từ xa

Có rất nhiều agent có thể được sử dụng để cài đặt trên cái máy chủ remote server nhưIcinga 2 Client, SNMP, NRPE, NSClient++ (For window). Trong bài viết này mình sẽ sử dụng **nrpe**

Về cơ chế hoạt động mình có thể giải thích như sau:

<img src=https://openmoz.files.wordpress.com/2015/01/screenshot-from-2015-01-06-192215.png>

Đây là hình ảnh kinh điển trong quá trình sử dụng nrpe để thực hiện việc monitor remote server. Bản chất của Icinga là Nagios core. Quá trình monitor diễn ra như sau:
    - Remote server sẽ sử dụng các plugin của nagios tiến hành check hệ thống
    - Các thông số check đc sẽ giao tiếp thông qua nrpe với máy chủ Icinga (Quá trình này đc bảo vệ bằng SSL - bắt buộc)
    - Các thông tin nhận được từ nrpe sẽ được máy chủ Icinga phân tích và hiển thị lên cgi (web interface)
    
##A. UBUNTU REMOTE SERVER

ssh root@192.168.1.221

###1. Install nrpe

```sh
# sudo apt-get update -y
# apt-get install nagios-plugins nagios-nrpe-server -y
```

###2. Change setting:

Remote server sẽ sử dụng các plugin của nagios tại đường dẫn "/usr/lib/nagios/plugins" để check local, sau đó sẽ sử dụng nrpe để truyền thông tin check được sang icinga server

`# vim /etc/nagios/nrpe.cfg`

-->
- Line 81:  allowed_hosts=127.0.0.1 to  allowed_hosts=127.0.0.1,localhost,192.168.1.220 (icinga_server)
- Line 97:   dont_blame_nrpe=0 to  dont_blame_nrpe=1
- Line 221: command[check_hda1]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /dev/hda1 to command[check_disk]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p <partition_will_be_checked>
- Thêm dòng sau vào dòng 224: 	
			  command[check_memory]=/usr/lib/nagios/plugins/check_mem.sh -w 80 -c 90
	
###3. Khởi tạo plugin check Memory 
Với nội dung [tại đây](https://github.com/huytm/Install-Icinga/blob/master/check_mem.sh) hoặc download về từ https://exchange.nagios.org/directory/Plugins/Operating-Systems/Linux/check_mem--2D-bash-script/details và cấp quyền thực thi

```sh
# cd /usr/lib/nagios/plugins/
# touch check_mem.sh 
# chmod +x check_mem.sh
``` 

###4. Restart nrpe

`# /etc/init.d/nagios-nrpe-server restart`

`# netstat -antup | grep 5666`

```sh
tcp        0      0 0.0.0.0:5666            0.0.0.0:*               LISTEN      6869/nrpe
tcp6       0      0 :::5666                 :::*                    LISTEN      6869/nrpe
```
-----------------------
##B. CENTOS REMOTE SERVER

ssh root@192.168.1.222

###1. Disalbe SElinux and stop iptables service

```sh
# sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
# service iptables stop
# chkconfig iptables off
# reboot
```

###2. install require packages

`# yum install gcc openssl* gd gd-devel make -y`

###3. Install nagios plugin

- Add nagios user
```sh
# useradd nagios
# passwd nagios
```

- Install nagios plugin

```sh
# wget https://www.nagios-plugins.org/download/nagios-plugins-1.5.tar.gz
# tar -xvf nagios-plugins-1.5.tar.gz
# cd nagios-plugins-1.5
# ./configure
# make
# make install

# chown nagios.nagios /usr/local/nagios
# chown -R nagios.nagios /usr/local/nagios/libexec
```
###4. Install xinetd và nrpe

```sh
# yum install xinetd -y
# wget http://pkgs.fedoraproject.org/repo/pkgs/nrpe/nrpe-2.15.tar.gz/3921ddc598312983f604541784b35a50/nrpe-2.15.tar.gz
# tar xzf nrpe-2.15.tar.gz
# cd nrpe-2.15
# ./configure --enable-command-args
# make all

# make install-plugin
# make install-daemon
# make install-daemon-config
# make install-xinetd
```
- Cấu hình nrpe service

`# vim /etc/xinetd.d/nrpe`

--> Line 15: only_from = 127.0.0.1 localhost 192.168.1.220 (icinga_server)

`# vim /etc/services`

--> Add dòng sau vào cuối file

`nrpe 5666/tcp #NRPE`

```sh
# service xinetd restart
# chkconfig xinetd on
```
- Kiểm tra

`# netstat -at | grep nrpe`

`tcp 	0 	0 	*:nrpe 	*:* 	LISTEN`

`# /usr/local/nagios/libexec/check_nrpe -H localhost`

`NRPE v2.15`

###5. Cấu hình nrpe giám sát hệ thống

`# vim /usr/local/nagios/etc/nrpe.cfg`

--> comment lại dòng từ 219 đến 223 và add các dòng sau

```sh
command[check_users]=/usr/local/nagios/libexec/check_users -w 5 -c 10
command[check_load]=/usr/local/nagios/libexec/check_load -w 15,10,5 -c 30,25,20
command[check_disk]=/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /dev/mapper/vg_huycentos2-lv_root ; <your partition you want to monitor>
command[check_zombie_procs]=/usr/local/nagios/libexec/check_procs -w 5 -c 10 -s Z
command[check_total_procs]=/usr/local/nagios/libexec/check_procs -w 150 -c 200
```

`#service xinetd restart`

##C. ICINGA SERVER

ssh root@192.168.1.220

###1. Install nrpe

`# sudo apt-get install nagios-nrpe-plugin`

###2. Kiểm tra kết nối với remote server

`# /usr/lib/nagios/plugins/check_nrpe -H 192.168.1.221`

`NRPE v2.15`

`# /usr/lib/nagios/plugins/check_nrpe -H 192.168.1.222`

`NRPE v2.15`


###3. Tạo file cấu hình với cho từng remote server
####a. Cho Ubuntu2 server (192.168.1.221)

```sh
# cd /etc/icinga/objects
# touch ubuntu2.cfg
# vim ubuntu2.cfg
```

--> Thêm nội dung sau

```sh
define host		{
		use                   generic-host
		host_name             Ubuntu-remote-server
		alias                 My Remote Ubuntu Server
		address               192.168.1.221
}

define service	{
		use generic-service
		host_name              Ubuntu-remote-server
		service_description    Root Partition
		check_command          check_nrpe_1arg!check_disk
}

define service	{
		use                    generic-service
		host_name              Ubuntu-remote-server
		service_description    Current Users
		check_command          check_nrpe_1arg!check_users
}

define service	{
		use                    generic-service
		host_name              Ubuntu-remote-server
		service_description    Total Processes
		check_command          check_nrpe_1arg!check_total_procs
}

define service	{
		use                    generic-service
		host_name              Ubuntu-remote-server
		service_description    Current Load
		check_command          check_nrpe_1arg!check_load
}

define service	{
		use                    generic-service
		host_name              Ubuntu-remote-server
		service_description    Zombie Processes
		check_command          check_nrpe_1arg!check_zombie_procs
}

define service	{
		use                    generic-service
		host_name              Ubuntu-remote-server
		service_description    Memory
		check_command          check_nrpe_1arg!check_memory
}

define service	{
		use                    generic-service
		host_name              Ubuntu-remote-server
		service_description    Ping
		check_command          check_ping!100.0,20%!500.0,60%
}
```

####b. Cho Centos1 server (192.168.1.222)

```sh
# cd /etc/icinga/objects    
# touch centos1.cfg
# vim centos1.cfg
```
Với nội dung như sau:

```sh
define host		{
		use                   generic-host
		host_name             Centos-server
		alias                 My Remote Centos Server
		address               192.168.1.222
}

define service	{
		use generic-service
		host_name              Centos-server
		service_description    Root Partition
		check_command          check_nrpe_1arg!check_disk
}

define service	{
		use                    generic-service
		host_name              Centos-server
		service_description    Current Users
		check_command          check_nrpe_1arg!check_users
}

define service	{
		use                    generic-service
		host_name              Centos-server
		service_description    Total Processes
		check_command          check_nrpe_1arg!check_total_procs
}

define service	{
		use                    generic-service
		host_name              Centos-server
		service_description    Current Load
		check_command          check_nrpe_1arg!check_load
}

define service	{
		use                    generic-service
		host_name              Centos-server
		service_description    Zombie Processes
		check_command          check_nrpe_1arg!check_zombie_procs
}

define service	{
		use                    generic-service
		host_name              Centos-server
		service_description    Memory
		check_command          check_ping!100.0,20%!500.0,60%
}	
```	

Khởi động lại icinga	

```sh
# /usr/sbin/icinga -v /etc/icinga/icinga.cfg
# /etc/init.d/icinga reload
# /etc/init.d/icinga restart
```

<img src=http://i.imgur.com/iDiocLs.jpg>

Have fun :)

