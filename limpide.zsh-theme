ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[yellow]%}o%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

PROMPT='%{$fg[cyan]%}%2~%{$reset_color%} %{$fg[red]%}|%{$reset_color%} \
$(git_prompt_info)$(enhance_prompt)%{$fg[cyan]%}>%{$reset_color%} '

enhance_prompt() {
    if is_redmine $1; then
        subject="$(redmine subject | xargs -0)"
        version=$(echo "($(redmine fixed_version.name))")

        echo "%$(( $COLUMNS - 60 ))>...>$subject%<< $version \
%{$fg[cyan]%}$(redmine spent_hours)h%{$reset_color%} \n\x"
    fi
}

redmine() {
    get_info

    case $1 in
	[a-z\/.:]*issues\/([0-9]*))
        handle_link $1
        return
        ;;
	.) SELECTOR=".";;
	"") SELECTOR=".";;
    lastmessage)SELECTOR=".issue.journals | .[length-1]";;
	*)SELECTOR=".issue.$1";;
	esac

    jq -r $SELECTOR <<< $RESPONSE
}

get_info() {
    if is_redmine $1; then
        if [ ! -z "$REDMINE_SERVER" ]; then
            redmine_id true
            ADDRESS="https://${REDMINE_SERVER}/issues/${REDMINE_ID}.json?include=journals"
        else
            echo "[$(date)] REDMINE: The environement variable 'REDMINE_SERVER' is \
nowhere to be seen but it is required." >> /var/log/lastlog
            return 1
        fi

        get_redmine
    fi
}

is_redmine() {
    [[ $(git_prompt_info) == *"/RM"* ]]
}

get_redmine() {
    FILENAME="/tmp/.redmine_${REDMINE_ID}"

    if [ -f $FILENAME ]; then
        TIME_DIFFERENCE=1800
        CURTIME=$(date +%s)
        FILETIME=$(stat $FILENAME -c %Y)
        TIMEDIFF=$(expr $CURTIME - $FILETIME)

        if [[ $TIMEDIFF -gt $TIME_DIFFERENCE ]]; then
            echo "[$(date)] REDMINE: New update: file '${FILENAME}' exceeded it's time \
diff (by ${TIMEDIFF} seconds)" >> /var/log/lastlog
            send_request
        else RESPONSE=$(cat ${FILENAME}) fi
    else
        echo "[$(date)] REDMINE: New update: file '${FILENAME}' didn't existed \
before" >> /var/log/lastlog
        send_request
    fi
}

send_request() {
    if [ ! -z "$REDMINE_API_KEY" ]; then
        curl --silent -H 'Content-Type: application/json' \
            -H "X-Redmine-API-Key: ${REDMINE_API_KEY}" \
            $ADDRESS -o "${FILENAME}"

        RESPONSE=$(cat ${FILENAME})
    else
        echo "[$(date)] REDMINE: The environement variable 'REDMINE_API_KEY' is \
nowhere to be seen but it is required." >> /var/log/lastlog
        return 1
    fi
}

handle_link() {
    REDMINE_ID=$(echo "$1"| grep -Eo "[[:digit:]]{5}")
    branch="feature/RM${REDMINE_ID}"

    git checkout $branch &> /dev/null

    if [[ ! $? -eq 0 ]]; then
        git checkout -b $branch origin/develop &> /dev/null
    fi
}

feature() {
    if is_redmine $1; then
        redmine_id true
        echo feature/RM$REDMINE_ID
    fi
}

redmine_id() {
    REDMINE_ID=$(git_prompt_info | grep -Eo "[[:digit:]]{5}")

    if [[ "" = $1 ]]; then
        echo $REDMINE_ID
    fi
}
