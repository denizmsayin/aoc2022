#! /bin/bash

# usage: $0 [day]
#   if day is unspecified, will attempt to fetch current day"

# Remember to put your AoC cookie in 'cookie.txt'

die() {
  printf '%s\n' "$1"
  exit 1
}

if [ "$#" == 0 ]; then
  month="$(date '+%m')"
  if [ "$month" == 12 ]; then
    day="$(date '+%-d')"
    if [ "$day" -gt 25 ]; then
      die "Can't fetch current day, it's past the 25th!"
    fi
  else
    die "Can't fetch current day, it's not December!"
  fi
  echo "Will fetch day $day, if possible!"
else
  day="$1"
fi

daylink="https://adventofcode.com/2022/day/$day"
nohup open '/Applications/Google Chrome.app/' "$daylink" &> /dev/null & 

target_dir="../io/day$day"
mkdir -p "$target_dir"
target_file="$target_dir/input.txt"
if [ -e "$target_file" ]; then
  echo "Target file already exists, did not fetch."
else
  curl --cookie "$(cat cookie.txt)" "$daylink/input" -o "$target_file"
fi
