#! /bin/sh

# Copyright (c) 2023-2024 Slawomir Wojciech Wojtczak (vermaden)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that following conditions are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS 'AS IS' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# ------------------------------
# LIST AND MGMT FreeBSD jail(8)
# ------------------------------
# vermaden [AT] interia [DOT] pl
# https://vermaden.wordpress.com

# display usage information
__usage() {
  local NAME=${0##*/}
  echo "usage:"
  echo "  ${NAME}            list jail(8) containers"
  echo "  ${NAME} -a         list jail(8) containers with all IP(s)"
  echo "  ${NAME} -h         show help"
  echo "  ${NAME} --help     show help"
  echo "  ${NAME} help       show help"
  echo "  ${NAME} version    show version"
  echo
  echo "manage:"
  echo "  ${NAME} JAILNAME start"
  echo "  ${NAME} JAILNAME restart"
  echo "  ${NAME} JAILNAME stop"
  echo "  ${NAME} JAILNAME console"
  echo "  ${NAME} JAILNAME shell"
  echo "  ${NAME} JAILNAME jexec"
  echo
  echo "shorts:"
  echo "  ${NAME} JAILNAME u   UP ------> alias for start"
  echo "  ${NAME} JAILNAME d   DOWN ----> alias for stop"
  echo "  ${NAME} JAILNAME r   RESTART -> alias for restart"
  echo "  ${NAME} JAILNAME c   CONSOLE -> alias for console|shell|jexec"
  echo

  exit 1
}

# display only 3 first interfaces
__interfaces_limit() {
  if [ $( echo "${IFACE}" | wc -l | tr -d ' ' ) -gt 3 ]
  then
    IFACE=$( echo "${IFACE}" | head -3 | tr '\n' ' ' | tr ' ' '/' )
    IFACE="${IFACE}(...)"
  else
    IFACE=$( echo "${IFACE}" | tr '\n' '/' | sed '$s/.$//' )
  fi
}

# check doas(1) presense
unalias doas
if which doas 1> /dev/null 2> /dev/null
then
  DOAS=doas
else
  DOAS=''
fi

case ${#} in
  (0)
    # do nothing and just display list of jails
    :
    ;;

  (1)
    # display version
    if [ "${1}" = "--version" -o \
         "${1}" =  "-version" -o \
         "${1}" =   "version" ]
    then
      echo "             ___                    __ ____ __   "
      echo "        ___ /  /                   / //    \\\\ \\  "
      echo "       /__//  / ____  _____ _____ / //  /  / \\ \\ "
      echo "      /  //  / /  _ \/  __//  __// / \     \ / / "
      echo "     /  //  /_/  ___/\__  \\\\__  \\\\ \ /  /  // /  "
      echo "  __/  / \____\____/ /____//____/ \_\\\\____//_/   "
      echo " /____/                                          "
      echo
      echo "jless(8) 0.1 2024/11/22"
      echo
      exit 0
    fi

    # display help if needed
    case ${1} in
      (-h|--h|help|-help|--help) __usage ;;
    esac

    # do full listing with all interfaces and IP addresses
    [ "${1}" = "-a" ] && FULL_LISTING=1
    ;;

  (2)
    case ${2} in
      (u|start)  ${DOAS} service jail onestart   ${1} ;;
      (d|stop)   ${DOAS} service jail onestop    ${1} ;;
      (s|status) ${DOAS} service jail onestatus  ${1} ;;
      (c|console|shell|jexec)
        env PS1="${1} # " ${DOAS} jexec ${1}
        ;;
    esac
    exit 0
    ;;

  (*)
    __usage
    ;;
esac

JLS=$( jls 2> /dev/null )
IFCONFIG=$( env IFCONFIG_FORMAT=inet:cidr ifconfig -l ether 2> /dev/null )

eval $( grep '^[^#]' /usr/local/etc/bastille/bastille.conf 2> /dev/null \
          | grep -m 1 bastille_prefix \
          | awk '{print $1}' )

if [ "${bastille_prefix}" != "" ]
then
  BAST_DIR="${bastille_prefix}"
  unset bastille_prefix
fi

(
  echo "JAIL JID TYPE VER DIR IFACE IP(s)"
  echo "---- --- ---- --- --- ----- -----"
  grep -h '^[^#]' \
    /etc/jail.conf \
    /etc/jail.conf.d/* \
    "${BAST_DIR}"/jails/*/jail.conf 2> /dev/null \
    | grep -h -E '[[:space:]]*[[:alnum:]][[:space:]]*\{' \
    | tr -d '\ \t{' \
    | while read JAIL
      do

        CONFIG=$( grep -h '^[^#]' /etc/jail.conf \
                                  /etc/jail.conf.d/* \
                                  "${BAST_DIR}"/jails/*/jail.conf 2> /dev/null \
                    | grep -A 512 -E "[[:space:]]*${JAIL}*[[:space:]]*\{" \
                    | grep -B 512 -m 1 ".*[[:space:]]*\}[[:space:]]*$" )

        DIR=$( echo "${JLS}" | awk '{print $NF}' | grep -E -e "/${JAIL}$" -e "/${JAIL}/root" )

        if [ "${DIR}" = "" ]
        then
          DIR=$( grep -h '^[^#]' \
                   /etc/jail.conf \
                   /etc/jail.conf.d/* \
                   "${BAST_DIR}"/jails/*/jail.conf 2> /dev/null \
                   | grep -A 512 -h -E '[[:alnum:]][[:space:]]\{' \
                   | grep -m 1 path \
                   | awk '{print $NF}' \
                   | tr -d ';' \
                   | sed -e "s.\${name}.${JAIL}.g" \
                         -e "s.\$name.${JAIL}.g" \
                   | tr -d '"' )
          if [ ! -d "${DIR}" ]
          then
            DIR="[GONE]${DIR}"
          fi
        fi

        VER=$( chroot ${DIR} freebsd-version -u 2> /dev/null \
                 | sed -e s.RELEASE.R.g \
                       -e s.CURRENT.C.g \
                       -e s.STABLE.S.g \
                       -e s.BETA.B.g )

        IPS=$( jexec ${JAIL} env IFCONFIG_FORMAT=inet:cidr ifconfig 2> /dev/null \
                 | grep 'inet ' \
                 | grep -v 127.0.0.1 \
                 | awk '{print $2}' \
                 | tr '\n' '+' \
                 | sed '$s/.$//' )

        TYPE=$( jexec ${JAIL} sysctl -n security.jail.vnet 2> /dev/null )

        case ${TYPE} in

          (1)
            TYPE=vnet
            IFACE=$( jexec ${JAIL} env IFCONFIG_FORMAT=inet:cidr ifconfig -l ether 2> /dev/null | tr ' ' '\n' )

            case ${FULL_LISTING} in

              (1)
                IFACE=$( echo "${IFACE}" | tr '\n' '/' | sed '$s/.$//' )
                ;;

              (*)
                IPS=$( echo "${IPS}" | tr '+' '\n' | head -3 | tr '\n' '+' | sed '$s/.$//' )
                __interfaces_limit
                ;;

            esac
            ;;

          (0)
            TYPE=std
            while read IP
            do
              while read INTERFACE
              do

                if env IFCONFIG_FORMAT=inet:cidr ifconfig ${INTERFACE} 2> /dev/null | grep -q "inet ${IP}"
                then
                  IFACE=${INTERFACE}
                  break
                fi
              done << EOF_INTERFACE
$( echo "${IFCONFIG}" | tr ' ' '\n' )
EOF_INTERFACE
            done << EOF_IP
$( echo "${IPS}" | tr '+' '\n' )
EOF_IP
            ;;

          (*)
            if echo "${CONFIG}" | grep -q 'vnet.interface'
            then
              TYPE=vnet
              IFACE=$( echo "${CONFIG}" | grep 'vnet.interface' | awk '{print $NF}' | tr -d ';"' | tr ',' '\n' )
              __interfaces_limit
            else
              TYPE=std
              IFACE=$( echo "${CONFIG}" | grep 'interface' | awk '{print $NF}' | tr -d ';' | tr ',' '\n' )
              __interfaces_limit
              IPS=$( echo "${CONFIG}" | grep '\.addr' | awk '{print $NF}' | tr -d ';' )
            fi
            ;;

        esac

        JID=$( echo "${JLS}" | grep -E -e "/${JAIL}$" -e "/${JAIL}/root" | awk '{print $1}' )

        if ! jexec ${JAIL} echo / 1> /dev/null 2> /dev/null
        then
          JID=-
        fi

        [ "${JID}"   = "" ] && JID='-'
        [ "${TYPE}"  = "" ] && TYPE='-'
        [ "${DIR}"   = "" ] && DIR='-'
        [ "${IFACE}" = "" ] && IFACE='-'
        [ "${IPS}"   = "" ] && IPS='-'
        [ "${VER}"   = "" ] && VER='-'

        echo ${JAIL} ${JID} ${TYPE} ${VER} ${DIR} ${IFACE} ${IPS}

        unset JAIL JID TYPE VER DIR IFACE IPS

      done
) | column -t