all: myconf.lua

ORG_PATH=~/.emacs.d/src/org/lisp/

myconf.lua: rc.lua.org
	emacs --batch --eval "(add-to-list 'load-path \"$(ORG_PATH)\")" --load org-install.el --eval "(org-babel-tangle-file \"rc.lua.org\")"
	awesome -k -c myconf.lua
