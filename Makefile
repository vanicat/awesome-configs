all: error

ORG_PATH=~/.emacs.d/src/org/lisp/

restart: myconf.lua
	echo 'awesome.restart()' | awesome-client
