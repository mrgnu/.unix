;;; general setup
;(set-default-font "-unknown-DejaVu Sans Mono-normal-normal-normal-*-12-*-*-*-m-0-iso10646-1")
(setq inhibit-startup-message t)
(show-paren-mode 1)
(menu-bar-mode 0)
(tool-bar-mode 0)
(winner-mode t)
(windmove-default-keybindings)
(setq truncate-partial-width-windows nil)
(setq whitespace-style '(face trailing newline indentation::tab space-before-tab::tab))
; don't allow window splitting
(setq pop-up-windows nil)
(setq split-height-threshold nil)
; order of C-l
;(setq recenter-positions (list 'top 'middle 'bottom))

; scrolling
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1))) ;; one line at a time
(setq mouse-wheel-progressive-speed nil) ;; don't accelerate scrolling
(setq mouse-wheel-follow-mouse 't) ;; scroll window under mouse
(setq scroll-step 1) ;; keyboard scroll one line at a time

; auto-install
(setq auto-install-directory "~/.emacs.d/auto-install/")
(add-to-list 'load-path (expand-file-name auto-install-directory))
(require 'auto-install)



;;; load libraries

(require 'cl)
(autoload 'magit-status "magit" nil t)
(require 'find-file-in-tags)
;(require 'whitespace)
;(load-library "thing-edit")
(autoload 'js2-mode "js2" nil t)
(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))



;;; setup keybindings
(global-set-key "\C-cg" 'goto-line)
(global-set-key "\C-ci" 'string-insert-rectangle)
(global-set-key "\C-cb" 'bury-buffer)
(global-set-key "\C-cf" 'find-file-in-tags)
(global-set-key [(f2)] 'my-git-grep)
(global-set-key [(f6)] 'my-debug-gdb)
(global-set-key [(f7)] 'my-build)
(global-set-key [(f8)]  'my-run-to-point)
(global-set-key [(f12)] 'magit-status)
(global-set-key "\C-cs" 'thing-copy-symbol)

;;; mode specific config

; gud
(add-hook 'gud-mode-hook 'my-gud-mode-hook)
(defun my-gud-mode-hook ()
  (local-set-key [(f5)]  'gud-run)
  (local-set-key [(f9)]  'gud-finish)
  (local-set-key [(f10)] 'gud-next)
  (local-set-key [(f11)] 'gud-step)
  )


; C/C++
;(require 'auto-complete)
;(global-auto-complete-mode t)
(setq c-default-style "bsd" c-basic-offset 4)
(add-hook 'c-mode-common-hook 'my-cxx-mode-hook)
(defun my-cxx-mode-hook ()
  (setup-smart-tabs)
  (whitespace-mode t)
  (setq indent-tabs-mode t)
  (local-set-key "\M-n" 'next-error)
  (local-set-key "\M-gs" 'goto-block-start)
  (local-set-key "\M-ge" 'goto-block-end)
  (local-set-key [(f5)]  'gud-run)
  (local-set-key [(f9)]  'gud-finish)
  (local-set-key [(f10)] 'gud-next)
  (local-set-key [(f11)] 'gud-step)
  (local-set-key  (kbd "C-c o") 'ff-find-other-file)
  (local-set-key  (kbd "C-c c") 'complete-tag)
  )

; SLIME
(setq inferior-lisp-program "/usr/bin/sbcl")
(add-to-list 'load-path "/usr/share/emacs/site-lisp/slime/")
;(require 'slime)
;(slime-setup '(slime-fancy))



;;; utility functions

; smart-tabs
(defun setup-smart-tabs()
  (setq indent-tabs-mode t)
  (setq-default tab-width 4)
  (setq cua-auto-tabify-rectangles nil)
  (defadvice align (around smart-tabs activate)
    (let ((indent-tabs-mode nil)) ad-do-it))
  (defadvice align-regexp (around smart-tabs activate)
    (let ((indent-tabs-mode nil)) ad-do-it))
  (defadvice indent-relative (around smart-tabs activate)
    (let ((indent-tabs-mode nil)) ad-do-it))
  (defadvice indent-according-to-mode (around smart-tabs activate)
    (let ((indent-tabs-mode indent-tabs-mode))
      (if (memq indent-line-function
		'(indent-relative
		  indent-relative-maybe))
	  (setq indent-tabs-mode nil))
      ad-do-it))
  (defmacro smart-tabs-advice (function offset)
    (defvaralias offset 'tab-width)
    `(defadvice ,function (around smart-tabs activate)
       (cond
	(indent-tabs-mode
	 (save-excursion
	   (beginning-of-line)
	   (while (looking-at "\t*\\( +\\)\t+")
	     (replace-match "" nil nil nil 1)))
	 (setq tab-width tab-width)
	 (let ((tab-width fill-column)
	       (,offset fill-column))
	   ad-do-it))
	(t
	 ad-do-it))))
  (smart-tabs-advice c-indent-line c-basic-offset)
  (smart-tabs-advice c-indent-region c-basic-offset))

; run to point (or end of function)
(defun my-run-to-point (p)
  (interactive "P")
  (progn
	(gud-tbreak p)
	(gud-finish p)))

; get file
(defun my-get-file (prompt rel)
  (read-file-name (concat prompt ": ") (concat (my-get-base-dir) rel)))
; get dir
(defun my-get-dir (prompt rel)
  (read-directory-name (concat prompt ": ") (concat (my-get-base-dir) rel)))

; base dir
(setq my-base-dir nil)
(defun my-fetch-base-dir ()
  (interactive)
  (setq my-base-dir (read-directory-name "base dir: " nil)))
(defun my-get-base-dir ()
  (interactive) ;;; remove
  (if (eq my-base-dir nil)
      (my-fetch-base-dir))
    my-base-dir)
; build dir
(setq my-build-dir nil)
(defun my-fetch-build-dir ()
  (interactive)
  (setq my-build-dir (my-get-dir "build dir" "")))
(defun my-get-build-dir ()
  (if (eq my-build-dir nil)
      (my-fetch-build-dir))
    my-build-dir)

; build project, keeps build dir once provided
(setq my-build-args "-j8")
(defun my-get-build-args (p)
  (if p
      (setq my-build-args (read-from-minibuffer "build command: " my-build-args)))
  my-build-args)
(defun my-build-int (cmd args path)
  (let ((my-build-command (concat cmd " -C " path " " args)))
    (compile my-build-command)))
(defun my-build (p)
  (interactive "P")
  (let ((my-cmd "make"))
    (my-build-int
     my-cmd
     (my-get-build-args p)
     (my-get-build-dir))))

; general gud launch, prompts for binary
(defun my-debug-gdb (p)
  (interactive "P")
  (let ((my-debug-command (concat "gdb --annotate=3 " (my-get-file "binary" "") " -x ~/.gdbinit")))
    (gdb (if (eq p nil) my-debug-command (read-from-minibuffer "gdb command: " my-debug-command)))))

; navigate blocks
(defun goto-block-start ()
  (interactive)
  (let ((l 1))
    (while (and (not (bobp)) (> l 0))
      (skip-chars-backward "^{}")
      (unless (bobp)
        (backward-char)
        (setq l (cond
                 ((eq (char-after) ?{) (1- l))
                 ((eq (char-after) ?}) (1+ l))
                 ))))
    (bobp)))
(defun goto-block-end ()
  (interactive)
  (goto-block-start)
  (forward-sexp))

; find in files
(defun git-grep (where what args)
  (interactive)
  (grep-find
   (concat "PAGER= git grep " args " -e '" what "' " where)))
(defun my-git-grep (p)
  (interactive "P")
  (let ((my-path nil) (my-args "-n"))
	(if (not (eq p nil))
		(progn
		  (setf my-path (read-directory-name  "path: " my-path))
		  (setf my-args (read-from-minibuffer "args: " my-args))))
    (git-grep
	 my-path
     (read-from-minibuffer "find what? " (thing-at-point 'symbol))
	 my-args)))

(defun my-find-other-in-tags ()
  "find 'other' (.h/.c/.cpp/.cc) file from tags"

  (defun filter-on-basename (basename list)
	"remove entries in list not matching basename"
	(remove-if-not
	 (lambda (f)
	   (let ((n (file-name-sans-extension (file-name-nondirectory f))))
		 (string= basename n)))
	 list))

  (defun filter-out-iext (ext list)
	"remove all files not matching (case-insensitive) extension"
	(remove-if-not
	 (lambda (f)
	   (let ((n (downcase (file-name-extension (file-name-nondirectory f)))))
		 (not (string= ext n))))
	 list))

  (defun get-matches (basename extension)
	"return a list of all files in TAGS table that match basename
     but not extension"
	(save-excursion
	  (visit-tags-table-buffer)
	  (mapcar (lambda (f) (concat default-directory f))
			  (filter-out-iext extension
							   (filter-on-basename
								basename
								(tags-table-files))))))

  (interactive)
  (let* ((name      (buffer-name))
		 (basename  (file-name-sans-extension name))
		 (extension (file-name-extension      name))
		 (matches   (get-matches basename extension)))

	(if (eq (length matches) 1)
		(find-file (car matches))
	  ;; FIXME: present matches in some sensible way
	  )))
