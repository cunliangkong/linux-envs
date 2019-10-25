#!/bin/bash
set -e

version=0.1.0

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'
_red() { echo -e ${red}$*${none}; }
_green() { echo -e ${green}$*${none}; }
_yellow() { echo -e ${yellow}$*${none}; }
_magenta() { echo -e ${magenta}$*${none}; }
_cyan() { echo -e ${cyan}$*${none}; }

cmd="apt-get"

if [[ $(command -v apt-get) ]] && [[ $(command -v systemctl) ]]; then
    echo
else
    echo -e "
    这个${red}辣鸡脚本${none}目前还不支持你的系统 ${yellow}(-_-)${none}

    Note: For Ubuntu 16+ only.
    " && exit 1
fi

pause() {
    read -rsp "$(echo -e "按 ${green}Enter${none} 继续.... 或按 ${red}Ctrl + C${none} 退出")" -d $'\n'
    echo
}

error() {
    echo -e "\n${red}输入错误!!!${none}\n"
}

check() {
    not_installed=()
    for app in $*
    do
        dpkg --get-selections | grep $app > /dev/null
        if [[ $? -eq 1 ]]
        then
            not_installed[${#not_installed[*]}]=$app
        fi
    done
    echo ${not_installed[*]}
}

check_app() {
    case $1 in
        zsh)
            apps=(zsh curl wget)
            check ${apps[*]}
            ;;
        vim)
            apps=(vim gcc g++ cmake build-essential python3-dev
            fonts-powerline exuberant-ctags clang)
            check ${apps[*]}
            ;;
        tmux)
            apps=(tmux)
            check ${apps[*]}
            ;;
        all)
            apps=(zsh curl wget vim gcc g++ cmake build-essential
            python3-dev fonts-powerline exuberant-ctags clang tmux)
            check ${apps[*]}
            ;;
    esac
}

install_after_check() {
    not_installed=(`check_app $1`)
    if [[ ${#not_installed[*]} -ne 0 ]]
    then
        if [[ $permit == 'yes' ]]
        then
            echo
            echo "系统中缺失以下应用，即将安装"
            echo
            echo "${not_installed[*]}"
            echo
            pause
            sudo $cmd install ${not_installed[*]}
        else
            echo
            echo "系统中缺失以下应用，请联系管理员安装"
            echo
            echo ${not_installed[*]}
            echo
            exit 1
        fi
    else
        echo
        echo "系统已安装所有需要的应用"
        echo
    fi
}

config_zsh() {
    if [[ -f $HOME/.zshrc ]]
    then
        version_in_file=`head -n 1 $HOME/.zshrc`
    else
        version_in_file=""
    fi

    if [[ $version_in_file == "# version: ${version}" ]]
    then
        while :; do
            echo
            echo "您的 zsh 配置文件已是最新版本，是否重新配置？"
            echo
            read -p "$(echo -e "是否确认？(Y/N) ：")" is_confirm
            case $is_confirm in
                Y)
                    do_config=1
                    break
                    ;;
                y)
                    do_config=1
                    break
                    ;;
                N)
                    do_config=0
                    break
                    ;;
                n)
                    do_config=0
                    break
                    ;;
                *)
                    error
                    ;;
            esac
        done
    else
        do_config=1
    fi

    if [[ $do_config -eq 1 ]]
    then
        echo
        echo "正在配置 zsh ..."
        echo
        cp settings/zshrc $HOME/.zshrc
        chsh -s /usr/bin/zsh
        echo
        echo "zsh 已完成配置"
        echo
    fi
}

config_vim() {
    if [[ -f $HOME/.vimrc ]]
    then
        version_in_file=`head -n 1 $HOME/.vimrc`
    else
        version_in_file=""
    fi

    if [[ $version_in_file == "\" version: ${version}" ]]
    then
        while :; do
            echo
            echo "您的 vim 配置文件已是最新版本，是否重新配置？"
            echo
            read -p "$(echo -e "是否确认？(Y/N) ：")" is_confirm
            case $is_confirm in
                Y)
                    do_config=1
                    break
                    ;;
                y)
                    do_config=1
                    break
                    ;;
                N)
                    do_config=0
                    break
                    ;;
                n)
                    do_config=0
                    break
                    ;;
                *)
                    error
                    ;;
            esac
        done
    else
        do_config=1
    fi

    if [[ $do_config -eq 1 ]]
    then
        echo
        echo "正在配置 vim ..."
        echo
        if [[ -d $HOME/.vim ]]
        then
            rm -rf $HOME/.vim
        fi

        curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs \
            https://gitee.com/styxjedi/vim-plug/raw/master/plug.vim
        mkdir -p $HOME/.vim/plugged
        git -C $HOME/.vim/plugged clone https://gitee.com/mirrors/youcompleteme.git
        cd $HOME/.vim/plugged/youcompleteme
        git submodule update --init
        sed -i "s@go.googlesource.com@github.com/golang@g" ./third_party/ycmd/.gitmodules
        export GO111MODULE=on
        export GOPROXY=https://goproxy.io
        git submodule update --init --recursive
        /usr/bin/python3 install.py --clang-completer
        cd -
        cp settings/vimvundle $HOME/.vimrc
        vim +PlugInstall +qall
        cat settings/vimsettings >> $HOME/.vimrc
        cp $HOME/.vim/plugged/youcompleteme/third_party/ycmd/.ycm_extra_conf.py $HOME
        echo
        echo "vim 已完成配置"
        echo
    fi
}

install_miniconda() {
    echo
    echo "正在准备安装 miniconda3 ..."
    echo
    if [[ -f "Miniconda3-latest-Linux-x86_64.sh" ]]
    then
        rm Miniconda3-latest-Linux-x86_64.sh
    fi
    wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh
    echo
    echo "已安装 miniconda3"
    echo
    if [[ -f "$HOME/.zshenv" ]]
    then
        if [[ `grep -c "conda initialize" $HOME/.zshenv` -eq 0 ]]
        then
            is_set=0
        else
            is_set=1
        fi
    else
        is_set=0
    fi

    if [[ $is_set -eq 0 ]]
    then
        read -p "$(echo -e "请输入刚才安装 ${magenta}miniconda3$none 的路径（默认为$HOME/miniconda3）：")" conda_path
        if [[ $conda_path == "" ]]
        then
            conda_path=$HOME/miniconda3
        fi
        $conda_path/bin/conda init zsh -d -v | grep ^+ | tr -d '+' | tr -s '\n' >> $HOME/.zshenv
    fi
}

config_miniconda() {
    if [[ -f "$HOME/.zshenv" ]]
    then
        if [[ `grep -c "conda initialize" $HOME/.zshenv` -eq 0 ]]
        then
            is_set=0
        else
            is_set=1
        fi
    else
        is_set=0
    fi

    if [[ $is_set -eq 0 ]]
    then
        read -p "$(echo -e "请输入 ${magenta}miniconda3$none 的安装路径（默认为$HOME/miniconda3）：")" conda_path
        if [[ $conda_path == "" ]]
        then
            conda_path=$HOME/miniconda3
        fi
        $conda_path/bin/conda init zsh -d -v | grep ^+ | tr -d '+' | tr -s '\n' >> $HOME/.zshenv
    fi
    echo
    echo "切换 conda 源至 mirror.tuna.tsinghua.edu.cn..."
    echo
    cp settings/condarc $HOME/.condarc
    echo "已完成"
    echo
}

config_pip() {
    echo
    echo "切换 pip 源至 pypi.tuna.tsinghua.edu.cn"
    echo
    if [[ -d $HOME/.pip ]]
    then
        rm -r $HOME/.pip
    fi
    cp -r settings/pip $HOME/.pip
    echo "已完成"
    echo
}

config_tmux() {
    echo
    echo "配置 tmux ..."
    echo
    cp settings/tmux.conf $HOME/.tmux.conf
    echo "已完成"
    echo
}

config_apt() {
    if [[ $permit == 'yes' ]]
    then
        declare -A ver2name
        ver2name=([18.04]="bionic" [16.04]="xenial" [14.04]="trusty" [12.04]="precise"
        [18.10]="cosmic" [17.10]="artful" [17.04]="zesty" [16.10]="yakkety" [15.10]="wily" [15.04]="vivid")

        while :; do
            echo
            echo "切换 apt 源 ..."
            echo
            read -p "$(echo -e "请输入您的 Ubuntu 系统版本号（默认为18.04）: ")" ubuntu_version

            if [[ $ubuntu_version == "" ]]
            then
                ubuntu_version=18.04
            fi

            if [[ `echo ${!ver2name[*]} | grep -cw $ubuntu_version` -eq 1 ]]
            then
                sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak
                sudo cat ./settings/sources.list \
                    | awk '{gsub(/<codename>/,"'"${ver2name[$ubuntu_version]}"'"); print $0}' \
                    > /etc/apt/sources.list
                break
            else
                error
            fi
        done

    else
        echo
        echo "您没有管理员权限，仅管理员可以运行此项。"
        echo
    fi
}

install_all() {
    while :; do
        echo
        echo "即将安装并配置以下软件："
        echo
        echo "zsh vim miniconda3 tmux"
        echo
        read -p "$(echo -e "是否确认？(Y/N) ：")" is_confirm
        case $is_confirm in
            Y)
                break
                ;;
            y)
                break
                ;;
            N)
                exit 1
                ;;
            n)
                exit 1
                ;;
            *)
                error
                ;;
        esac
    done

    install_after_check all
    config_zsh
    config_vim
    install_miniconda
    config_miniconda
    config_pip
    config_tmux
    echo
    echo "已完成安装和配置，部分配置重启终端后生效。"
    echo
}

install_select() {
    while :; do
        echo
        echo " 1. 安装 & 配置 zsh"
        echo
        echo " 2. 安装 & 配置 vim"
        echo
        echo " 3. 安装 & 配置 tmux"
        echo
        echo " 4. 安装 & 配置 miniconda3（包含 5,6 步骤）"
        echo
        echo " 5. 配置 miniconda3"
        echo
        echo " 6. 切换 pip 源"
        echo
        echo " 7. 切换 apt 源（需要管理员权限）"
        echo
        read -p "$(echo -e "请选择 [${magenta}1-7$none] 或按 ${magenta}ctrl + c$none 退出： ")" choose
        case $choose in
            1)
                install_after_check zsh
                config_zsh
                pause
                ;;
            2)
                install_after_check vim
                config_vim
                pause
                ;;
            3)
                install_after_check tmux
                config_tmux
                pause
                ;;
            4)
                install_miniconda
                config_miniconda
                config_pip
                pause
                ;;
            5)
                config_miniconda
                pause
                ;;
            6)
                config_pip
                pause
                ;;
            7)
                config_apt
                pause
                ;;
            *)
                error
                ;;
        esac
    done
}

# start from here
u_group=`groups ${USER}`
if [[ ${u_group} =~ "sudo" || ${u_group} =~ "root" ]]
then
    permit="yes"
else
    permit="no"
fi

clear
while :; do
    echo
    echo "........... Linux 环境一键配置脚本 .........."
    echo
    echo
    echo "使用说明: https://styxjedi.github.io"
    echo
    echo
    echo " 1. 一键安装 & 配置"
    echo
    echo " 2. 自定义安装 & 配置"
    echo
    echo
    read -p "$(echo -e "请选择 [${magenta}1-2$none] 或按 ${magenta}ctrl + c$none 退出：")" choose
    case $choose in
        1)
            install_all
            break
            ;;
        2)
            install_select
            break
            ;;
        *)
            error
            ;;
    esac
done

