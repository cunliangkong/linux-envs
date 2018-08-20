#! /usr/bin/env bash

query() {
    ask=0
    while [ $ask = 0 ]
    do
        read -p "Will setup $1, confirm?(yes|no) " answer
        if [ $answer != "yes" ] && [ $answer != "no" ]
        then
            echo "Please input yes or no."
        else
            let "ask += 1"
        fi
    done
    echo $answer
}

u_group=`groups ${USERNAME}`
if [[ ${u_group} =~ "sudo" ]]
then
    permit="yes"
else
    permit="no"
fi

echo "Permission of sudo: $permit"
answer_zsh=$(query "zsh")
if [ $answer_zsh = yes ]
then
    echo "Configuring zsh..."
    if [ $permit = yes ]
    then
        sudo apt-get install zsh
        chsh -s /usr/bin/zsh
    fi
    cp zshrc ~/.zshrc
else
    echo "Will not setup zsh."
fi

answer_vim=$(query "vim")
if [ $answer_vim = "yes" ]
then
    echo "Configuring vim..."
    if [ $permit = "yes" ]
    then
        sudo apt-get install vim
        sudo apt-get install cmake
    fi
    $(cat ./vimvundle > ~/.vimrc)
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    vim +PluginInstall +qall
    cd ~/.vim/bundle/YouCompleteMe
    python3 install.py --clang-completer
    cd -
    $(cat ./vimsettings >> ~/.vimrc)
else
    echo "Will not setup vim."
fi

answer_tmux=$(query "tmux")
if [ $answer_tmux = "yes" ]
then
    echo "Configuring tmux..."
    if [ $permit = "yes" ]
    then
        sudo apt-get install tmux
    fi
    cp tmux.conf ~/.tmux.conf
else
    echo "Will not setup tmux."
fi

answer_pip=$(query "pip")
if [ $answer_pip = "yes" ]
then
    echo "Configuring pip..."
    cp -r ./pip ~/.pip
else
    echo "Will not setup pip."
fi

if [ $permit = "no" ]
then
    echo """
    We noticed that you're not in the sudoers file.
    So these softwares above won't be installed for you.
    But the config files are copied to the right places.
    If it didn't work, please contact your Admin to install these softwares for you.
    After that, run this script again will work.
    """
fi

if [ $answer_zsh = yes ]
then
    exec zsh
fi
