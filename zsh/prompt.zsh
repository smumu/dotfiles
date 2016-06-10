### Oh yeah my prompt
autoload -U promptinit && promptinit
setopt PROMPT_SUBST

## Left prompt

local virtualenv_prompt_parse='$([[ "${VIRTUAL_ENV}" != "" ]] && echo " $(basename ${VIRTUAL_ENV})")'

function _prompt_context() {
    local prompt=""

    local _default_username="samuel"

    if [[ "${LOGNAME}" != "${USER}" || "${LOGNAME}" != "${_default_username}" || "${USER}" != "${_default_username}" ]] ; then
        prompt="${prompt}%{$fg_no_bold[cyan]%}%n%{$reset_color%}"
    fi

    unset _default_username

    if [[ -n "${SSH_CLIENT}" ]] ; then
        [ -n "${prompt}" ] && prompt="${prompt}@"
        prompt="${prompt}%{$fg_no_bold[blue]%}%M%{$reset_color%}"
    fi

    [ -n "${prompt}" ] && prompt=" ${prompt}"

    echo -n "${prompt}"
}

function build_prompt() {
  local prompt=""

  [[ "${VIRTUAL_ENV}" != "" ]] && prompt="${prompt} %{$fg_no_bold[red]%}$(basename ${VIRTUAL_ENV})%{$reset_color%}"

	if [[ ${COLUMNS} -lt 80 ]]; then
		local _prompt_path_max_length=2
	elif [[ ${COLUMNS} -lt 90 ]]; then
		local _prompt_path_max_length=3
	fi
  prompt="${prompt} %{$fg_no_bold[yellow]%}%${_prompt_path_max_length:-}~%{$reset_color%}"

  #[[ ${COLUMNS} -lt 60 ]] && local _newline=$'\n ' && prompt="┌${prompt}└${_newline}"
  echo -n "${prompt}"
}
BASE_PROMPT='%{$fg_no_bold[white]%}%T%{$reset_color%}$(_prompt_context)$(build_prompt)'
PROMPT="${BASE_PROMPT}"

function TRAPALRM() {
    zle .reset-prompt
}
TMOUT=10

# current vi mode and last status
function zle-line-finish zle-keymap-select {
    PROMPT="${BASE_PROMPT} "

    local _nbsp=$'\u00A0'
    case "${KEYMAP}" in
        vicmd)
            PROMPT="${PROMPT}%{$fg_no_bold[yellow]%}?"
            ;;
        *)
                PROMPT="${PROMPT}%(?.%{$fg_no_bold[green]%}→.%{$fg_bold[red]%}!)"
            ;;
    esac

    PROMPT="${PROMPT}%{$reset_color%}${_nbsp}"
    zle && zle reset-prompt
}
zle -N zle-line-finish
zle -N zle-keymap-select
zle-line-finish


## Right prompt
BASE_RPROMPT='%{$fg_no_bold[white]%}%(?.$(rprompt_last_duration).%{$fg_no_bold[red]%}%?%{$fg_no_bold[white]%})%{$reset_color%}%(1j. (%{$fg_no_bold[magenta]%}%j%{$reset_color%}💤%).)'
source ~/.zsh/git.prompt.zsh

function rprompt_slow_cmd() {
    echo "$(git_prompt_string)"
}

function rprompt_last_duration() {
    [[ ${_rprompt_timer_show} -le 2 ]] && return

    local _color="blue"

    if [[ $_rprompt_timer_show -ge 10 ]]; then
        _color="magenta"
    elif [[ $_rprompt_timer_show -ge 5 ]]; then
        _color="yellow"
    fi

    echo "%{$fg_no_bold[$_color]%}${_rprompt_timer_show:-0}s%{$reset_color%}"
}

function preexec() {
    _rprompt_timer=${_rprompt_timer:-$SECONDS}
}

ASYNC_RPROMPT_PROC=0
_async_rprompt_tmp_file="/tmp/zsh_rprompt_$(date +%Y%m%d_%H%M%S)"
function precmd() {
    if [ $_rprompt_timer ]; then
        _rprompt_timer_show=$(($SECONDS - $_rprompt_timer))
        unset _rprompt_timer
    fi

    RPROMPT="${BASE_RPROMPT} 🔃"

    function async() {
        printf "%s" "$(rprompt_slow_cmd)" > "${_async_rprompt_tmp_file}"
        kill -s USR1 $$
    }

    if [[ "${ASYNC_RPROMPT_PROC}" != 0 ]]; then
        kill -s HUP $ASYNC_RPROMPT_PROC >/dev/null 2>&1 || :
    fi

    async &!
    ASYNC_RPROMPT_PROC=$!
}

function TRAPUSR1() {
    RPROMPT="${BASE_RPROMPT}$(cat ${_async_rprompt_tmp_file})"
	rm "${_async_rprompt_tmp_file}"
    ASYNC_RPROMPT_PROC=0
	(zle && zle .reset-prompt) 2> /dev/null
}
