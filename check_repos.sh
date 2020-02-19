#!/bin/bash
# HARDCODED options - change to
MAINDIR=~/Code/.gitrepos
GIT_REPOS=$MAINDIR/git_repos.txt
GIT_OMIT=$MAINDIR/omit_repos.txt
GIT_ALL=$MAINDIR/all_repos.txt
OIFS=$IFS #Save current end of line
IFS=$'\n'

#Should work fine on linux or macos
PS1_TMP='"\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;33m\]\w\[\033[00m\]\$ "'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

#Search for .git directories in /
find_repos (){
  if [ ! -f $GIT_ALL ]
  then
      touch $GIT_ALL
  else
      cat /dev/null > $GIT_ALL
  fi

  all_repos=()
  while IFS=  read -r -d $'\0'; do
      echo $REPLY >> $GIT_ALL
      all_repos+=("$REPLY")
  done < <(find ~/ -name ".git" -print0)
}

# Open files containing repos absolute address.
read_repos_file (){
  FILE=$1
  repos=()
  for LINE in $(cat $FILE); do
    repos+=("$LINE")
  done
}

#Creates repo files
write_repos_file(){
  cat /dev/null > $GIT_REPOS
  for line in ${my_repos[@]}
  do
    echo $line >> $GIT_REPOS
  done
}

# Gets repos from main list that are not omitted.
compare_repos_lists(){
  my_repos=()
  for i in "${all_repos[@]}"; do
      skip=
      for j in "${repos[@]}"; do
          [[ $i == $j ]] && { skip=1; break; }
      done
      [[ -n $skip ]] || my_repos+=("$i")
  done
  # declare -p my_repos
}

#Main caller - required from beginning.
 update_repos_files(){
   find_repos
   read_repos_file $GIT_OMIT
   compare_repos_lists
   write_repos_file $my_repos
}

# Print repos list
print_list(){
  elem_list=${my_repos[*]}
  for elem in ${elem_list[@]}
  do
    echo $elem
  done
}

check_repos_status(){
  CURRENT=$(pwd)
  OLDPS1=$PS1
  read_repos_file ${GIT_REPOS}
  COUNTER=1
  LN_RP=${#repos[@]}
  for val in ${repos[@]}
  do
    echo "---------$COUNTER/$LN_RP-----------"
    bash --init-file <(echo "export PS1=$PS1_TMP;cd $val;cd ..;pwd;git status")
    cd ~
    let COUNTER=COUNTER+1
  done
  export PS1=$OLDPS1
  cd $CURRENT
}

check_repos_quick(){
  CURRENT=$(pwd)
  OLDPS1=$PS1
  read_repos_file ${GIT_REPOS}
  COUNTER=1
  LN_RP=${#repos[@]}
  for val in ${repos[@]}
  do
    echo "---------$COUNTER/$LN_RP-----------"
    cd $val;cd ..;pwd
    if ! git diff --quiet # Check whether something has change in the repo
    then
      bash --init-file <(echo "export PS1=$PS1_TMP;cd $val;cd ..;pwd;git status")
    else
      echo -e "${GREEN}Nothing to do here...${NC} "
    fi
    cd ~
    let COUNTER=COUNTER+1
  done
  export PS1=$OLDPS1
  cd $CURRENT
}

list_repos_status(){
  CURRENT=$(pwd)
  read_repos_file ${GIT_REPOS}
  COUNTER=1
  LN_RP=${#repos[@]}
  for val in ${repos[@]}
  do
    echo "---------$COUNTER/$LN_RP-----------"
    cd $val;cd ..;pwd
    if ! git diff --quiet # Check whether something has change in the repo
    then
      git status
    else
      echo -e "${GREEN}Nothing to do here...${NC} "
    fi
    cd ~
    let COUNTER=COUNTER+1
  done
  cd $CURRENT
}

print_usage(){
  echo "Usage: $(basename $0) [-u] [-c] [-l] [-h] [-C]"
  echo "      -u         Update repository lists"
  echo "      -c         Manage all repo (returns a shell for each)"
  echo "      -C         Like -c but only for changed repos"
  echo "      -l         List repository status"
  echo "      -h         Print this information"
  exit 0
}

TMP=0
while getopts "cCulh" option
do
  case ${option} in
    c )
      check_repos_status ;;
    C )
      check_repos_quick ;;
    l )
      list_repos_status ;;
    u )
      update_repos_files ;;
    h )
      print_usage ;;
    \? )
      print_usage ;;
  esac
  TMP=1
done
if [ $TMP == 0 ]; then
  print_usage
fi

echo " "
echo "________________________"
echo "Repo Check Finished ... "
echo "________________________"
IFS=$OIFS
# find_repos
#
