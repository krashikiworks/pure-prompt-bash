#!/bin/bash

# pure prompt on bash
#
# Pretty, minimal BASH prompt, inspired by sindresorhus/pure(https://github.com/sindresorhus/pure)
#
# Author: Hiroshi Krashiki(Krashikiworks)
# released under MIT License, see LICENSE

# Colors
readonly BLACK=$(tput setaf 0)
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly MAGENTA=$(tput setaf 5)
readonly CYAN=$(tput setaf 6)
readonly WHITE=$(tput setaf 7)
readonly BRIGHT_BLACK=$(tput setaf 8)
readonly BRIGHT_RED=$(tput setaf 9)
readonly BRIGHT_GREEN=$(tput setaf 10)
readonly BRIGHT_YELLOW=$(tput setaf 11)
readonly BRIGHT_BLUE=$(tput setaf 12)
readonly BRIGHT_MAGENTA=$(tput setaf 13)
readonly BRIGHT_CYAN=$(tput setaf 14)
readonly BRIGHT_WHITE=$(tput setaf 15)

readonly RESET=$(tput sgr0)

# symbols
pure_prompt_symbol="❯"
pure_symbol_unpulled="⇣"
pure_symbol_unpushed="⇡"
pure_symbol_dirty="*"
# pure_git_stash_symbol="≡"

# if this value is true, remote status update will be async
pure_git_async_update=false
pure_git_raw_remote_status="+0 -0"


__pure_echo_git_remote_status() {

	# get unpulled & unpushed status
	if ${pure_git_async_update}; then
		# do async
		# FIXME: this async execution doesn't change pure_git_raw_remote_status. so remote status never changes in async mode
		# FIXME: async mode takes as long as sync mode
		pure_git_raw_remote_status=$(git status --porcelain=2 --branch | grep --only-matching --perl-regexp '\+\d+ \-\d+') &
	else
		# do sync
		pure_git_raw_remote_status=$(git status --porcelain=2 --branch | grep --only-matching --perl-regexp '\+\d+ \-\d+')
	fi

	# shape raw status and check unpulled commit
	local readonly UNPULLED=$(echo ${pure_git_raw_remote_status} | grep --only-matching --perl-regexp '\-\d')
	if [[ ${UNPULLED} != "-0" ]]; then
		pure_git_unpulled=true
	else
		pure_git_unpulled=false
	fi

	# unpushed commit too
	local readonly UNPUSHED=$(echo ${pure_git_raw_remote_status} | grep --only-matching --perl-regexp '\+\d')
	if [[ ${UNPUSHED} != "+0" ]]; then
		pure_git_unpushed=true
	else
		pure_git_unpushed=false
	fi

	# if unpulled -> ⇣
	# if unpushed -> ⇡
	# if both (branched from remote) -> ⇣⇡
	if ${pure_git_unpulled}; then

		if ${pure_git_unpushed}; then
			echo "${RED}${pure_symbol_unpulled}${pure_symbol_unpushed}${RESET}"
		else
			echo "${BRIGHT_RED}${pure_symbol_unpulled}${RESET}"
		fi

	elif ${pure_git_unpushed}; then
		echo "${BRIGHT_BLUE}${pure_symbol_unpushed}${RESET}"
	fi
}

__pure_update_git_status() {

	local git_status=""

		# if current directory isn't git repository, skip this
		if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == "true" ]]; then

			git_status="$(git branch --show-current)"

			# check clean/dirty
			git_status="${git_status}$(git diff --quiet || echo "${pure_symbol_dirty}")"

			# coloring
			git_status="${BRIGHT_BLACK}${git_status}${RESET}"

			# if repository have no remote, skip this
			if [[ -n $(git remote show) ]]; then
				git_status="${git_status} $(__pure_echo_git_remote_status)"
			fi
		fi

	pure_git_status=${git_status}
}

# if last command failed, change prompt color
__pure_echo_prompt_color() {

	if [[ $? = 0 ]]; then
		echo ${pure_user_color}
	else
		echo ${RED}
	fi

}

__pure_update_prompt_color() {
	pure_prompt_color=$(__pure_echo_prompt_color)
}

# if user is root, prompt is BRIGHT_YELLOW
case ${UID} in
	0) pure_user_color=${BRIGHT_YELLOW} ;;
	*) pure_user_color=${BRIGHT_MAGENTA} ;;
esac

# if git isn't installed when shell launches, git integration isn't activated
if [[ -n $(command -v git) ]]; then
	PROMPT_COMMAND="__pure_update_git_status; ${PROMPT_COMMAND}"
fi

PROMPT_COMMAND="__pure_update_prompt_color; ${PROMPT_COMMAND}"


readonly FIRST_LINE="${CYAN}\w \${pure_git_status}\n"
# raw using of $ANY_COLOR (or $(tput setaf ***)) here causes a creepy bug when go back history with up arrow key
# I couldn't find why it occurs
readonly SECOND_LINE="\[\${pure_prompt_color}\]${pure_prompt_symbol}\[$RESET\] "
PS1="\n${FIRST_LINE}${SECOND_LINE}"

# Multiline command
PS2="\[$BLUE\]${prompt_symbol}\[$RESET\] "
