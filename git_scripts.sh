echo "git_scripts.sh has been sourced!"

alias amend="git commit -a --amend"
alias force="git push -f"
alias branch="git branch"
alias fetch="git fetch"
alias status="git status"
alias pull="git pull"
alias caf='caffeinate -t 3600'
alias gcu='getclienturl'
alias ggu='getgitbranchurl'
alias cdtest="cd ~/repos/eva-app-suite-test-automation"
alias bdel="branch -d"

RED='\033[0;31m'
LIGHT_RED='\033[1;31m'
RED_BACKGROUND='\e[41m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[0;33m'
LIGHT_BLUE='\033[0;87m'
NC='\033[0m' 
pathSpec="/Users/diffurchik/client/e2e-tests/client"
pathStoriesTests='/Users/diffurchik/client/packages/canvas-tests/spectator/tests/visuals'


function killp(){
    if [[ "$1" == "h" ]] ; then
        echo "Kill proccess on specific port. Just put number of port after command"
        return 0;
    else    
        lsof -ti tcp:$1 | xargs kill
    fi
}

function switch(){
    echo Checking safety of this operation...
    if [ -z "$(git status | grep 'Changes not staged for commit')" ] && [ -z "$(git status | grep 'Changes to be committed')" ] ; then
        echo "${GREEN}!Everything is ok! Let do it!${NC}" ;
        git switch $1
    else 
        echo "${RED}! You need to commit changes or do stash before ! ${NC}" ;
        return 0;
    fi  
}

function screenshot(){
    if [[ "$1" == "h" ]] ; then
        echo "Command inside: ${GREEN}yarn spectator update-screenshots $1 $2 $3 $4;${NC}";
        return 0;
    fi

    result=$(pwd)

    if [[ $result != $pathSpec ]] && [[ $result != $pathStoriesTests ]] ; then
        echo "${RED}Wrong path: ${result}${NC}"
        echo "Choose needed path: ${BLUE}e2e${NC} or ${BLUE}cs${NC} (canvas-storybook)";
        read  way;
        echo "${YELLOW}Switching to correct path...${NC}"

        case "$way" in
            'e2e') cd $pathSpec ;;
            'cs') cd $pathStoriesTests ;;
        esac

        pwd=$(pwd)
        echo "Current path: $pwd"
    fi

    if [[ -z "$(yarn spectator update-screenshots $1 $2 $3 $4 | grep ' Missing one of the arguments')" ]] ; then
        yarn spectator update-screenshots $1 $2 $3 $4 ;
    else echo "${RED}! set -a or -s parameter before test data${NC}";
    fi   

    
}

function getGeneralBranch(){
    if [ -z "$(git branch -a | grep master)" ] ; then 
        if  [ -z "$(git branch -a | grep main)" ]  ; 
            then  echo "no main, no master" ;
            else branch="main";
            fi
    else  branch="master"; fi
    echo $branch
}

function update(){
    echo checking safety of this operation...
    if [ -z "$(git status | grep 'Changes not staged for commit')" ] && [ -z "$(git status | grep 'Changes to be committed')" ] ; then
            echo "${GREEN}!Everything is ok! Let do it!${NC}" ;
            branch=$(getGeneralBranch) ;
            echo General branch of this project is $branch
            git fetch ;
            git merge origin/"$branch" ;
    else 
        echo "${RED}! You need to commit changes or do stash before ! ${NC}" ;
    fi    
}

function push(){
    branch=$(git branch --show-current)
    git push --set-upstream origin "$branch"
}

newbranch() {
    echo "Checking safety of this operation..."

    if [ -z "$(git diff)" ] && [ -z "$(git diff --cached)" ]; then
        echo "${GREEN}!Everything is ok! Let's do it!${NC}"

        generalBranch=$(getGeneralBranch)
        git switch "$generalBranch" && git pull

        ticket=$(echo "$1" | sed -E 's/.*(OPTR-[0-9]+).*/\1/')
        title=$(echo "$1" | sed -E 's/.*OPTR-[0-9]+[[:space:]]*(.*)/\1/; s/[[:space:]]/-/g;')
        newBranch="$ticket-$title"

        echo "newBranch: $newBranch"

        if git checkout -b "$newBranch"; then
            echo "${GREEN}Switched to new branch: $newBranch${NC}"
        else
            currentBranch=$(git rev-parse --abbrev-ref HEAD)
            echo "${RED_BACKGROUND}Failed to switch! Still on $currentBranch${NC}"
        fi
    else
        echo "${RED}! You need to commit changes or stash them first! ${NC}"
    fi
}

function compush(){
    echo "${YELLOW}Staging all changes...${NC}"
    git add -A
    git add .*
    git add .
    branch=$(git branch --show-current)
    echo "${YELLOW}Commiting...${NC}"
    git commit -a -m "$branch $1"
    echo "${YELLOW}Pushing...${NC}"
    push	
}

function list(){

    case "$1" in
        '') echo "Please, input ${BLUE}'spec'${NC}, ${BLUE}'git'${NC}, ${BLUE}'else'${NC} or ${BLUE}'all'${NC} parameter" ;;
        spec) echo "specswitch \ndockertest \nscreenshot \ngetallure \ndockallure" ;;
        git) echo "switch \nfindGeneralBranch \nupdate \npush \nnewbranch \ncompush \nswitchbranch";;
        else) echo "killp \ntogif \ngetclienturl" ;;
        all) echo "specswitch \ndockertest \nscreenshot \ngetallure \ndockallure \nswitch \nfindGeneralBranch \nupdate \npush \nnewbranch \ncompush \nkillp \ntogif";;
    esac
}


function togif(){
    if [[ "$1" == "h" ]] ; then
        echo "I don't remember what need to put here. Probably, path to file :)"
        return 0;
    else
	 output_file="$1.gif"
   	 ffmpeg -y -i $1 -v quiet -vf scale=iw/2:ih/2 -pix_fmt rgb8 -r 10 $output_file && gifsicle -O3 $output_file -o $output_file
    fi
}

function switchbranch(){
    if [[ "$1" == "h" ]] ; then
        echo "Search branches: arrow keys to move, Enter to switch (or copy name). Parameter: string with search key";
        return 0;
    fi
    if [[ -z "$1" ]]; then
        echo "Usage: switchbranch <search_key>"
        return 1;
    fi

    local branches=("${(@f)$(git branch | grep -- "$1" | sed 's/^[* ]*//')}")
    if [[ ${#branches[@]} -eq 0 ]]; then
        echo "No branches matching '$1'"
        return 1;
    fi
    if [[ ${#branches[@]} -eq 1 ]]; then
        switch "$branches[1]"
        if command -v pbcopy &>/dev/null; then
            echo -n "$branches[1]" | pbcopy
        fi
        return 0;
    fi
    local chosen
    if command -v fzf &>/dev/null; then
        chosen=$(printf '%s\n' "${branches[@]}" | fzf --height=20 --prompt='Branch> ')
    else
        echo "Select a branch (install fzf for arrow-key selection):"
        select chosen in "${branches[@]}"; do
            [[ -n "$chosen" ]] && break
        done
    fi
    if [[ -n "$chosen" ]]; then
        switch "$chosen"
        if command -v pbcopy &>/dev/null; then
            echo -n "$chosen" | pbcopy
            echo "${GREEN}Switched and branch name copied to clipboard.${NC}"
        fi
    fi
}

function revert() {
    status
    echo "${LIGHT_RED}Are you sure to revert all local changes? (Y/n)${NC}"
    read -r answer
    if [[ "$answer" == "Y" ]]; then
        echo "${YELLOW}Resetting...${NC}"
        git checkout .
        status
    elif [[ "$answer" == "n" ]]; then
        echo "Canceled"
    else
        echo "Invalid input"
    fi
}
