#!/usr/bin/env bash
# .bashrc

. /etc/bashrc

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

##
## KUBERNETES
##

alias k="kubectl"
alias ksh="kubectl run busybox -i --tty --image=busybox --restart=Never --rm -- sh"
alias kbash="kubectl run busybox -i --tty --image=busybox --restart=Never --rm -- ash"
alias kexport="export KUBECONFIG=`pwd`/kubeconfig.yaml"
alias kurl="docker run --rm byrnedo/alpine-curl"
source <(kubectl completion bash)
source <(k completion bash | sed s/kubectl/k/g)

##
## GIT STUFF
##

alias ga="git add -A"
alias gp="git push origin"

gm() {
	if [[ "$1" ]]; then
		printf -v _msg "%s\n\n" "$*"
		git commit -m "$_msg"
	else
		git commit
	fi
}

alias gamend="git commit --amend"
