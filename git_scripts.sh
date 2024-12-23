echo "git_scripts.sh has been sourced!"

alias amend="git commit -a --amend"
alias force="git push -f"
alias branch="git branch"
alias fetch="git fetch"
alias status="git status"
alias report="yarn spectator report"
alias pull="git pull"
alias storybook=' yarn storybook:canvas:dev'
alias caf='caffeinate -t 3600'
alias gcu='getclienturl'
alias ggu='getgitbranchurl'

RED='\033[0;31m'
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

function specswitch(){
    if [[ "$1" == "h" ]] ; then
        echo "Command inside: ${GREEN}yarn spectator switch -n \$1 \$2 \$3${NC}";
        return 0;
    fi
    result=$(pwd)
    if [[ $result != $pathSpec ]] ; then
            echo "${RED}Wrong path: ${result}${NC}"
            echo "Switching to correct path..."
            cd ~/client/e2e-tests/client ;
            yarn spectator switch -n $1 $2 $3
    else  yarn spectator switch -n $1 $2 $3 ; 
    fi
}

function dockertest(){
    if [[ "$1" == "h" ]] ; then
        echo "Command inside: ${GREEN}yarn spectator test --docker -b chromium \$1 \$2 \$3 \$4 \$5 \$6${NC}";
        return 0;
    fi
    if [[ $result != $pathSpec ]] ; then
            echo "${RED}Wrong path: ${result}${NC}"
            echo "Switching to correct path..."
            cd ~/client/e2e-tests/client ;   
            echo "remove /allure-results..."
	        rm -r ./spectator/allure-results/;
            echo "running tests..."
            yarn spectator test --docker -b chromium $1 $2 $3 $4 $5 $6 ; 
    else yarn spectator test --docker -b chromium $1 $2 $3 $4 $5 $6 ;
	        report;
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

function getallure(){
    if [[ "$1" == "h" ]] ; then
        echo "Command inside: ${GREEN}spectator generate-allure-id -s${NC} ;\nNeed to add just path to file";
        return 0;
    fi
    result=$(pwd)
        if [[ $result != $pathSpec ]] ; then
            echo "${RED}Wrong path: ${result}${NC}"
            echo "Switching to correct path..."
            cd ~/client/e2e-tests/client ;
            yarn spectator generate-allure-id -s $1; 
        else yarn spectator generate-allure-id -s $1;  
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

function newbranch(){
    echo checking safety of this operation...
    if [ -z "$(git status | grep 'Changes not staged for commit')" ] && [ -z "$(git status | grep 'Changes to be committed')" ] ; then
        echo "${GREEN}!Everything is ok! Let do it!${NC}" ;
        generalBranch=$(getGeneralBranch)
        git switch "$generalBranch"
        git pull
        newBranch=$(echo $1 | sed 's/.*\(DIAG.*\)/\1/')
        echo "newBranch: $newBranch"
        git checkout -b $newBranch
    else 
        echo "${RED}! You need to commit changes or do stash before ! ${NC}" ;
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


function dockallure(){
    if [[ "$1" == "h" ||  "$1" == "-h" ]] ; then
        echo "Command inside: \n${GREEN}dockertest -a \$1 -f \$2 \nreport${NC}";
        return 0;
    else 
        if [ -z "$1" ]; then
            echo "${RED}Please, input allure id${NC}"
            read 1
        fi
        if [ -z "$2" ] ; then
            echo "${RED}Please, input number of repetitions (0 - run once)${NC}"
            read 2
        fi
        echo "remove /allure-results..."
	    rm -r ./spectator/allure-results/;
        echo "running tests..."
	    dockertest -a $1 -f $2;
	    report;
    fi
}

function list(){

    case "$1" in
        '') echo "Please, input ${BLUE}'spec'${NC}, ${BLUE}'git'${NC}, ${BLUE}'else'${NC} or ${BLUE}'all'${NC} parameter" ;;
        spec) echo "specswitch \ndockertest \nscreenshot \ngetallure \ndockallure" ;;
        git) echo "switch \nfindGeneralBranch \nupdate \npush \nnewbranch \ncompush \nfindbranch";;
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

function findbranch(){
    if [[ "$1" == "h" ]] ; then
        echo "Does grep in git branch result. Parameter: string with search key";
        return 0;
    else
        resultedList=git branch | grep $1;
        echo $resultedList
    fi
}

function getclienturl(){
    local port=8080
    local ip=$(ifconfig -a | grep -v '127.0.0.1' | grep -oE 'inet (addr:)?100\.[0-9]+\.[0-9]+\.[0-9]+'| awk '{print $2}')
    echo "\e[96mhttps://develop.testmiro.com/app/?clientHost=${ip}&clientPort=${port}&serverName=released";                
}

function getgitbranchurl(){
    branch=$(git branch --show-current)

    echo "\e[96mhttps://github.com/miroapp-dev/client/tree/${branch}";                
}

function bunchscreenshot(){
    array=($(getids))
    echo "Need to update ${YELLOW}${#array[@]}${NC} tests"
    for x in $array; do
    echo "${YELLOW}Making screenshot for $x allureId...${NC}"
     screenshot -a $x; done
}

function getids(){
    text='
   #53153
User could create a custom shape on a board by dragging its preview to the board from the Diagramming sidebar
31s 333ms

#53147
User could add extra items in shape pack preview by 'plus' button
31s 032ms

#53139
User could edit custom shape name in the More shapes dialog
46s 930ms

#53129
User could edit lable setting of a custom library by its context menu in the More shapes dialog
53s 052ms

#52710
User could edit custom library name by its context menu in the Shape settings dialog
31s 112ms

#52709
User could edit custom library name by clicking on it in the More shapes dialog
28s 361ms

#52706
I could see all existed custom libraries in the diagramming app dialog
57s 339ms

#52703
I could create custom shape on a board from the diagramming app sidebar
32s 219ms

#52701
I could delete custom libraries from the diagramming app dialog
30s 405ms

    '
    id=($(echo $text | grep -o '#[0-9]\+'))
    echo $id:gs/#/
}

function cm(){
    FOLDER_NAME="autotests"
    FILE_NAME="values.yaml"
    for i in $(seq 1 12); do   
    FILE_CONTENT="---
miro-svc-helm-chart:
    configmaps:
        env:
            envFrom: true
            data:
                application.environment: https://autotests-$i.testmiro.com
                SPRING_PROFILES_ACTIVE: autotests-$i"
        echo $i
        mkdir -p $FOLDER_NAME-$i
        echo -n $FILE_CONTENT >> $FOLDER_NAME-$i/$FILE_NAME
    done
}
