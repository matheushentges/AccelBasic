#!/bin/bash
#Autor: Matheus Hentges
#Licence Creative Commons

#Sources List
whiptail --title "Aviso!" --msgbox "  Alterando Sources List!!!"  --fb 10 35  3>&1 1>&2 2>&3;

{ echo "deb http://ftp.debian.org/debian buster main non-free contrib";
  echo "deb http://ftp.debian.org/debian buster-updates main contrib non-free";
  echo "deb http://security.debian.org buster/updates main contrib non-free";
} > /etc/apt/sources.list;

apt update && apt upgrade -y

#Declarando funcoes
#SSH
function installssh() {

      apt install openssh-server -y

    { echo "Port $PortaSSH" ;
      echo 'Protocol 2';
      echo 'DebianBanner no';
      echo 'PermitRootLogin no';
      echo 'PermitEmptyPasswords no';
      echo 'ChallengeResponseAuthentication no';
      echo 'X11Forwarding no';
      echo 'PrintMotd no';
      echo 'AcceptEnv LANG LC_*';
      echo 'Subsystem  sftp  /usr/lib/openssh/sftp-server';
      echo 'Match User *,!root';
      echo '    ForceCommand /bin/false';
      echo "Match Address $IPS";
      echo '    PermitRootLogin yes';
    } > /etc/ssh/sshd_config;

    { echo '';

echo ' $$$$$$\                                $$\         $$$$$$$\  $$$$$$$\  $$$$$$$\  ';
echo '$$  __$$\                               $$ |        $$  __$$\ $$  __$$\ $$  __$$\ ';
echo '$$ /  $$ | $$$$$$$\  $$$$$$$\  $$$$$$\  $$ |        $$ |  $$ |$$ |  $$ |$$ |  $$ |';
echo '$$$$$$$$ |$$  _____|$$  _____|$$  __$$\ $$ |$$$$$$\ $$$$$$$  |$$$$$$$  |$$$$$$$  |';
echo '$$  __$$ |$$ /      $$ /      $$$$$$$$ |$$ |\______|$$  ____/ $$  ____/ $$  ____/ ';
echo '$$ |  $$ |$$ |      $$ |      $$   ____|$$ |        $$ |      $$ |      $$ |      ';
echo '$$ |  $$ |\$$$$$$$\ \$$$$$$$\ \$$$$$$$\ $$ |        $$ |      $$ |      $$ |      ';
echo '\__|  \__| \_______| \_______| \_______|\__|        \__|      \__|      \__|      ';
echo '                                                                                  ';
    } > /etc/motd;

      systemctl restart ssh
      systemctl restart sshd

  }


#Pacote Accel
function installaccel() {
  apt install git net-tools libsnmp-dev build-essential cmake gcc linux-headers-`uname -r` git libpcre3-dev libssl-dev liblua5.1-0-dev -y
  mkdir -p /usr/local/src/accel/build
  cd /usr/local/src/accel
  git clone https://github.com/xebd/accel-ppp.git
  cd /usr/local/src/accel/build

cmake \
-DCPACK_TYPE=Debian10 \
-DBUILD_IPOE_DRIVER=TRUE \
-DBUILD_VLAN_MON_DRIVER=TRUE \
-DRADIUS=TRUE \
-DNETSNMP=TRUE \
-DCMAKE_BUILD_TYPE=Debug \
-DCMAKE_INSTALL_PREFIX=/usr \
-DKDIR=/usr/src/linux-headers-$(uname -r) \
../accel-ppp

make

cp drivers/ipoe/driver/ipoe.ko /lib/modules/$(uname -r)
cp drivers/vlan_mon/driver/vlan_mon.ko /lib/modules/$(uname -r)
depmod -a
modprobe  vlan_mon
modprobe  ipoe

echo "vlan_mon" >> /etc/modules
echo "ipoe" >> /etc/modules

cpack -G DEB
apt install ./accel-ppp.deb

systemctl enable accel-ppp
cp /etc/accel-ppp.conf.dist  /etc/accel-ppp.conf

systemctl restart accel-ppp

}

#Declarando Variaveis
OS=`cat /etc/os-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/["]//g' | awk '{print $1}'`
VERSAO=`cat /etc/os-release | grep "VERSION_ID" | sed 's/VERSION_ID=//g' | sed 's/["]//g' | awk '{print $1}'`

#Inicio da validacao do sistema
if [ "$OS" != "Debian" ]; then
    echo "   Sua distribuicao linux ($OS) nao e o Debian!!!"; echo;
else
	if [ "$VERSAO" != "10" ]; then
	    echo "   Sua distribuicao linux Debian ($VERSAO) nao esta na versao 10!!!"; echo
	else

#Instalacao e configuracao do SSH
whiptail --title "Acesso ao Accel" --msgbox "Na Proxima etapa preencha os IPs que terao acesso ao accel via SSH. Ex.:(192.168.0.0/24,45.175.128.1) e tambem a porta ssh para o equipamento, caso nao deseje alterar digite 22.                                Escolha OK para continuar." --fb 15 50
whiptail --title "Aviso!" --msgbox "Caso nao preencher nenhum dado, o SSH sera liberado na porta padrao(22) e deixando aberto para o mundo todo(0.0.0.0/0)!!!"  --fb 15 50  3>&1 1>&2 2>&3;

IPS=$(whiptail --title "IPs no sshd_config" --inputbox "Digite os IPs:              Ex.:192.168.0.0/24,45.175.128.1" --fb 10 50 3>&1 1>&2 2>&3)
PortaSSH=$(whiptail --title "Porta SSH" --inputbox "Digite a porta ssh que deseja definir:            Ex.:50022" --fb 10 50 3>&1 1>&2 2>&3)
if [ "$PortaSSH" != "" ]||[ "$IPS" != "" ];then
   installssh;
    else
      { echo "Port 22" ;
        echo 'Protocol 2';
        echo 'DebianBanner no';
        echo 'PermitRootLogin no';
        echo 'PermitEmptyPasswords no';
        echo 'ChallengeResponseAuthentication no';
        echo 'X11Forwarding no';
        echo 'PrintMotd no';
        echo 'AcceptEnv LANG LC_*';
        echo 'Subsystem  sftp  /usr/lib/openssh/sftp-server';
        echo 'Match User *,!root';
        echo '    ForceCommand /bin/false';
        echo "Match Address 0.0.0.0/0";
        echo '    PermitRootLogin yes';
      } > /etc/ssh/sshd_config;

      service ssh restart
    fi
#instalacao pacote accel
    whiptail --title "Instalacao Accel" --msgbox " Nesse passo instalaremos o Accel"  --fb 15 40  3>&1 1>&2 2>&3;
    (whiptail --title "Instalacao Accel" --yesno " Deseja prosseguir?" --yes-button "Não" --no-button "Sim" 15 40  3>&1 1>&2 2>&3);
    if [ $? -eq 1 ]; then
        installaccel;

        SUCESSO=`systemctl status accel-ppp | grep "active" | sed 's/active=//g' | sed 's/["]//g' | awk '{print $1}'`
        if [ "$SUCESSO" = "Active:" ];

        then

        echo "                       _        ____   ____   ____   ";
        echo "     /\               | |      |  __ \|  __ \|  __ \ ";
        echo "    /  \   ___ ___ ___| |______| |__) | |__) | |__) |";
        echo "   / /\ \ / __/ __/ _ \ |______|  ___/|  ___/|  ___/ ";
        echo "  / ____ \ (_| (_|  __/ |      | |    | |    | |     ";
        echo " /_/___ \_\___\___\___|_|  _   |_|    |_|    |_|     ";
        echo " |_   _|         | |      | |         | |     | |    ";
        echo "   | |  _ __  ___| |_ __ _| | __ _  __| | ___ | |    ";
        echo "   | | | |_ \/ __| __/ _| | |/ _  |/  |_|/ _ \| |    ";
        echo "  _| |_| | | \__ \ || (_| | | (_| | (_| | (_) |_|    ";
        echo " |_____|_| |_|___/\__\__,_|_|\__,_|\__,_|\___/(_)    ";
        echo;
        echo "    Status do servico Accel";
        echo " ";
        systemctl status accel-ppp
        

        else
          echo "     Ocorreu um erro na instalacao do pacote, reinicie o processo";
          echo "     Status do servico Accel";
          echo " ";
          systemctl status accel-ppp

        fi

    else
        echo " ";
        echo " ";
        echo "Operacao cancelada pelo usuario!";
        echo "Lembrando que as configuracoes do SSH foram alteradas no passo anterior!";
        echo "Caso deseje alterar edite o arquivo /etc/ssh/sshd_config.";
        echo " ";
        echo " ";
    fi
  fi
fi
