set -x

wget -P /tmp http://192.168.56.254/kickstart/ol8/cvuqdisk-1.0.10-1.rpm
rpm -ivh /tmp/cvuqdisk-1.0.10-1.rpm

# sed -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config -i

# systemctl disable firewalld.service

sed -e 's/^\(pool\)/#\1/g' /etc/chrony.conf -i
echo -e "server 192.168.56.254 iburst" |tee -a /etc/chrony.conf

cat <<'EOF' | tee /etc/oraInst.loc
inventory_loc=/u01/oraInventory
inst_group=oinstall
EOF

echo "NOZEROCONF=yes" >> /etc/sysconfig/network

cat <<'EOF' | tee -a /etc/sysctl.conf
vm.nr_hugepages = 2048
net.ipv4.conf.enp0s9.rp_filter = 2
net.ipv4.conf.enp0s8.rp_filter = 2
net.ipv4.conf.enp0s3.rp_filter = 1
EOF

groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper
groupadd -g 54324 backupdba
groupadd -g 54325 dgdba
groupadd -g 54326 kmdba
groupadd -g 54327 asmdba
groupadd -g 54328 asmoper
groupadd -g 54329 asmadmin
groupadd -g 54330 racdba
useradd -u 54331 -g oinstall -G asmadmin,asmdba,asmoper,racdba grid
echo "oracle" | passwd --stdin grid
usermod -u 54321 -g oinstall -G dba,oper,backupdba,dgdba,kmdba,asmdba,racdba oracle
echo "oracle" | passwd --stdin oracle

cat <<'EOF' | tee -a /etc/security/limits.conf
grid soft nproc 2047
grid hard nproc 16384
grid soft nofile 1024
grid hard nofile 65536
grid soft stack 10240
grid hard stack 32768
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft stack 10240
oracle hard stack 32768
oracle soft memlock 5274299
oracle hard memlock 5274299
EOF

mkdir -p /u01/grid
mkdir -p /u01/gbase
mkdir -p /u01/base/app/database
mkdir -p /u01/oraInventory
chown -R grid:oinstall /u01
chown -R oracle:oinstall /u01/base
chown -R grid:oinstall /u01/oraInventory
chmod -R 775 /u01
echo "session required pam_limits.so" | tee -a /etc/pam.d/login
cat <<'EOF' | tee -a /etc/profile
if [ $USER = "oracle" ]; then
    if [ $SHELL = "/bin/ksh" ]; then
       ulimit -u 16384
       ulimit -n 65536
    else
       ulimit -u 16384 -n 65536
    fi
fi
EOF

nmcli c mod "System enp0s3" connection.autoconnect yes
nmcli c mod "System enp0s8" connection.autoconnect yes
nmcli c mod "System enp0s9" connection.autoconnect yes

