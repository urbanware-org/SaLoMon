#!/bin/bash

# ============================================================================
# SaLoMon - Simple log file monitor and analyzer
# Install and uninstall script
# Copyright (C) 2018 by Ralf Kilian
# Distributed under the MIT License (https://opensource.org/licenses/MIT)
#
# GitHub: https://github.com/urbanware-org/salomon
# GitLab: https://gitlab.com/urbanware-org/salomon
# ============================================================================

# Pre-check if the Bash shell is installed and if this script has been
# executed using it
command -v bash >/dev/null 2>&1
if [ "$?" != "0" ]; then
    echo "error: The Bash shell does not seem to be installed, run the"\
                "compatibility"
    echo "       script ('compat.sh') for details."
    exit 1
elif [ ! -n "$BASH" ]; then
    echo "error: This script must be executed using the Bash shell, run the"
    echo "       compatibility script ('compat.sh') for details."
    exit 1
fi

script_dir=$(dirname $(readlink -f $0))
script_file=$(basename "$0")

source ${script_dir}/core/common.sh
source ${script_dir}/core/global.sh
set_global_variables
shell_precheck

script_mode=""
symlink_sh="/usr/local/bin/"
target_dir="/opt/salomon"
target="${color_yellow}${target_dir}${color_none}"
yesno="${color_yellow}Y${color_none}/${color_yellow}N${color_none}"

confirm() {
    echo
    echo $em "${color_lightcyan}SaLoMon install/uninstall script${color_none}"
    echo
    echo $em "This will $script_action SaLoMon. Do you wish to proceed"\
             "($yesno)? \c"
    read choice

    egrep "^yes$|^y$" -i <<< $choice &>/dev/null
    if [ $? -ne 0 ]; then
        echo
        echo $em "${color_lightred}Canceled${color_none} on user request."
        echo
        exit
    fi
}

usage() {
    error_msg=$1
    given_arg=$2

    echo "usage: salomon.sh [-i] [-u]"
    echo
    echo "  -i, --install         install SaLoMon"
    echo "  -u, --uninstall       uninstall SaLoMon"
    echo "  -?, -h, --help        print this help message and exit"
    echo
    echo "Further information and usage examples can be found inside the"\
         "documentation"
    echo "file for this script."
    if [ ! -z "$error_msg" ]; then
        echo
        if [ -z "$given_arg" ]; then
            echo $em "${color_lightred}error:${color_none} $error_msg"
        else
            echo $em "${color_lightred}error:${color_none} $error_msg"\
                     "'${color_yellow}${given_arg}${color_none}'"
        fi
        exit 1
    else
        exit 0
    fi
}

if [ $# -gt 1 ]; then
    usage "Too many arguments"
elif [ $# -lt 1 ]; then
    usage "Missing arguments"
fi

if [ "$1" = "--install" ] || [ "$1" = "-i" ]; then
    script_mode="install"
    script_action="${color_lightgreen}${script_mode}${color_none}"
elif [ "$1" = "--uninstall" ] || [ "$1" = "-u" ]; then
    script_mode="uninstall"
    script_action="${color_lightred}${script_mode}${color_none}"
elif [ "$1" = "-?" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
else
    usage "Invalid argument" "$1"
fi

if [ "$(whoami)" != "root" ]; then
    error="${color_lightred}error:${color_none}"
    echo
    echo -e "$error Superuser privileges are required"
    echo
    exit 1
fi

if [ ! -d "$symlink_sh" ]; then
    symlink_sh="/usr/bin/"
fi

confirm $script_mode
echo
echo $em "${color_lightgreen}Started $script_mode process:${color_none}"
if [ $script_mode = "uninstall" ]; then
    cd $(pwd | sed -e "s/\/salomon$//g")

    if [ -f ${symlink_sh}/salomon ]; then
        rm -f ${symlink_sh}/salomon &>/dev/null
        echo "  - Removed symbolic link for the main script."
    else
        echo "  - Symbolic link for the main script does not exist."
    fi

    if [ -d $target_dir ]; then
        rm -fR $target_dir &>/dev/null
        echo $em "  - Removed project directory '${target}'."
    else
        echo $em "  - Project directory '${target}' does not exist."
    fi
else
    if [ -d $target_dir ]; then
        echo $em "  - Target directory '${target}' already exists."
    else
        mkdir -p $target_dir &>/dev/null
        echo $em "  - Created target directory '${target}'."
    fi

    rsync -av $script_dir/* $target_dir/ &>/dev/null
    echo "  - Copied project data to target directory."

    chown root:root $target_dir -R &>/dev/null
    echo "  - Set permissions on target directory."

    chmod +x $target_dir/*.sh
    echo "  - Set executable flag for main script files."

    if [ -f ${symlink_sh}/salomon ]; then
        echo "  - Symbolic link for the main script already exists."
    else
        ln -s ${target_dir}/salomon.sh ${symlink_sh}/salomon &>/dev/null
        echo "  - Created symbolic link for the main script."
    fi
fi
echo $em "${color_lightgreen}Finished $script_mode process.${color_none}"
echo

# EOF
