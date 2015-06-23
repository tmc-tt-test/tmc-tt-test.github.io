#!/bin/bash

export rvmsudo_secure_path=1

log_file=~/test_log
error_log=~/test_html/errors.txt

function _date() {
	echo -n `date '+%d.%m.%Y %H:%M'`
}

function commit_hash() {
	cd ~/tmc-server
	echo -n `git log | head -1 | awk '{print $2;}'`
	cd - > /dev/null
}

function commit_message() {
	cd ~/tmc-server
	echo -n `git log --oneline | head -1 | awk '{first = $1; $1 = ""; print $0 }'`
	cd - > /dev/null
}

function log_message() {
	echo -e "\n\n$(_date)\nCommit: $(git log --oneline | head -1)\n----------------"
}

function run_tests() {
	echo "$(_date): Running tests"
	git reset --hard origin/integration > /dev/null
	rake db:migrate > /dev/null 2>&1
	rake db:reset > /dev/null 2>&1
	rake db:test:prepare
	log_message >> $log_file
	log_message >> $error_log
	rvmsudo rspec --format progress --format html -o "/home/tmc/test_html/$(commit_hash).html" >> $log_file 2>> $error_log
	echo "$(_date): Finished running tests"
}

function push_results() {
	cd ~/test_html
	echo "<br>$(_date): <a href='$(commit_hash).html'>$(commit_message)</a>" >> ~/test_html/index.html
	git add . && git commit -m "test" && git push
}

if [ "$1" = "force" ]; then
	echo "Forced tests"
	cd ~/tmc-server
	git checkout -q integration
	git pull
	run_tests
 	push_results
fi

while true; do
	cd ~/tmc-server
	git checkout -q integration
	if git pull | grep -q 'Already up-to-date'; then
		echo "$(_date): Repo is up-to-date"
		sleep 300
	else
		echo "$(_date): Repo updated"
		run_tests
		push_results
	fi
done
