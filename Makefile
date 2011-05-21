all: myconf.lua

myconf.lua: rc.lua.org
	emacs --batch --eval "(add-to-list 'load-path \"~/.emacs.d/src/org/lisp/\")" --load org-install.el --eval "(org-babel-tangle-file \"rc.lua.org\")"