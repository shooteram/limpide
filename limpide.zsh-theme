#! /bin/bash
set -m

ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[yellow]%}o%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

PROMPT='%$(( $COLUMNS - 20 ))>...>%{$fg[cyan]%}%1~%{$reset_color%} %{$fg[red]%}|%{$reset_color%} \
$(git_prompt_info)%<<$(enhance_prompt)%{$fg[cyan]%}>%{$reset_color%} '

enhance_prompt() {
    _=$(git flow config &>/dev/null)

    if [ $? -eq 0 ]; then
        echo -n "%{$fg[blue]%}flow %{$reset_color%}"
    fi

    unset _
}
