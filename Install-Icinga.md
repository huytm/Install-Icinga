# Install-Icinga

Ghi chép này mình thực hiện cài đặt Icinga trên máy chủ Ubuntu 14.04. Vậy nên mình chuẩn bị một máy ảo Ubuntu với cấu hình tối thiểu là 2 GB RAM. Đồng thời để thực hiện cho phần hai, mình cũng chuẩn bị luôn 2 máy ảo nữa để thực hiện giám sát như sau:

| STT | Name 						 |OS            | Memory | IP            | Note                   |
|-----|------------------------------|--------------|--------|---------------|------------------------|
| 1   | Ubuntu-Icinga                | Ubuntu 14.04 | 2GB    | 192.168.1.220 | Máy chủ cài đặt Icinga |
| 2   | Ubuntu-Remote-server         | Ubuntu 14.04 | 1GB    | 192.168.1.221 | Máy chủ Ubuntu cần giám sát |
| 3   | Centos-Remote-server         | CentOS 6.5   | 1GB    | 192.168.1.222 | Máy chủ CentOS cần giám sát |

## Cài đặt Icinga

Trong ghi chép này mình sử dụng toàn bộ user **root** để cài đặt và cấu hình

`ssh root@192.168.1.220`

###1. Fix lỗi add repuo và updata package on Ubuntu 

```sh
# cd /var/cache/debconf
# mv *.dat /tmp/
```

###2. Add repo

`# add-apt-repository ppa:formorer/icinga`

--> Press [Enter]

###3. Update respositories and system packages

`# apt-get update && apt-get upgrade -y`

**Note**: Trong quá trình update nếu bạn gặp *"Configuring grub-pc"* thì lựa chọn primary partition, phân vùng mà bạn cài đặt hệ điều hành

###4. Install mysql

Bạn cần phải cài đặt mysql server trước khi cài đặt Icinga để tránh phát sinh lỗi trong quá trình cài đặt

`# apt-get install mysql-server libdbd-mysql mysql-client -y`

- --> Nhập password cho root user ở bước "Configuring mysql-server-5.5"
- --> Nhập lại password

###5. Install Icinga

`# apt-get install icinga icinga-doc icinga-idoutils -y`

- Các bước cài đặt như sau
<ul>
<li>At Postfix Configuration 			--> Chọn Internet Site                                                                                   </li>
<li>At Postfix Configuration: 			-->	Nhập fully qualified domain name (FQDN) (example huytm.vn)                                           </li>
<li>At Configuring icinga-cgi : 		-->	Nhập Icinga password cho icingaadmin (Chú ý password này dùng để đăng nhập vào icinga web interface).</li>
<li>At Configuring icinga-cgi :  		-->	Nhập lại password                                                                                    </li>
<li>At Configuring icinga-common : 		-->	*"Use external commands with Icinga"* chọn NO                                                        </li>
<li>At Configuring icinga-idoutils : 	-->	Chọn Yes tại bước *"Configure database for icinga-idoutils with dbconfig-common"*.                   </li>
<li>At Configuring icinga-idoutils : 	-->	Chọn mysql làm database.                                                                             </li>
<li>At Configuring icinga-idoutils  : 	-->	Enter MySQL root password mà bạn vừa đặt ở bước 4                                                    </li>
<li>At Configuring icinga-idoutils : 	-->	Nhập MySQL application password cho icinga-idoutils                                                  </li>
<li>At Configuring icinga-idoutils : 	-->	Comfirm lại password                                                                                 </li>
</ul>

###6. Config Icinga Server

- Enable ido2db daemon start cùng với hệ thống.

`# vim /etc/default/icinga`

-->  Thay đổi dòng 13: từ *"IDO2DB=no"* thành *"IDO2DB=yes"*

- Enable idomod module bằng cách copy file idoutils config mẫu vào thư mục config icinga.

`# cp /usr/share/doc/icinga-idoutils/examples/idoutils.cfg-sample /etc/icinga/modules/idoutils.cfg`

- Restart icinga service.

```sh
# service ido2db start
# service icinga restart
```

###7. Truy cập vào Icinga

Truy cập vào địa chỉ http://192.168.1.220/icinga với **username/password** **icingaadmin/<password bạn đặt ở bước 5>**

<img src=http://i.imgur.com/GHHVGYT.png>

Enjoy :)

