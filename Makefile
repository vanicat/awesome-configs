all: myconf.lua

ORG_PATH=~/.emacs.d/src/org/lisp/

myconf.lua: rc.lua.org
	emacs --batch --eval "(require 'ob-tangle)" --eval "(org-babel-tangle-file \"rc.lua.org\")"
	awesome -k -c myconf.lua

restart: myconf.lua
	echo 'awesome.restart()' | awesome-client
