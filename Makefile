all: error

ORG_PATH=~/.emacs.d/src/org/lisp/

restart: myconf.lua
	awesome -k
	echo 'awesome.restart()' | awesome-client
