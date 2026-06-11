(add-hook 'emacs-startup-hook
	  (lambda ()
	    (message "Emacs loaded in %.2f seconds"
		     (float-time
		      (time-subtract after-init-time before-init-time)))))

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(setq use-package-compute-statistics t)

(setopt make-backup-files nil)

(setq custom-file (concat user-emacs-directory "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

(defun xdg-open (&optional path)
  "Run xdg-open on PATH (if not specified: current buffer file).
With \\[universal-argument] prefix: open the directory instead."
  (interactive)
  (-if-let (path (or path (ignore-errors
			    (expand-file-name
			     (pcase major-mode
			       ('dired-mode dired-directory)
  			       (_ buffer-file-name))))))
      (let ((target (if current-prefix-arg
  			(file-name-directory path)
  		      path))
  	    (process-connection-type nil))
  	(start-process "" nil "xdg-open" target))
    (message "Nothing to open here.")))

(defun get-title-from-url (url)
  "Make HTTP request to get title from URL"
  (with-current-buffer (url-retrieve-synchronously url)
    (goto-char (point-min))
    (re-search-forward "\n\n") ;; Skip HTTP headers
    (let ((dom (libxml-parse-html-region (point) (point-max))))
      (dom-text (car (dom-by-tag dom 'title)))
      )))

(defun parse-ssh-config-hosts (ssh-config-file)
  "Parse the SSH config file and return a list of hosts."
  (let ((hosts '()))
    (when (file-readable-p ssh-config-file)
      (with-temp-buffer
        (insert-file-contents ssh-config-file)
        (goto-char (point-min))
        (while (re-search-forward "^Host[ \t]+\\(.*\\)$" nil t)
          (let ((host-line (match-string 1)))
            (dolist (host (split-string host-line))
              (unless (string-match-p "[*?]" host) ;; Ignore wildcards
                (push host hosts)))))))
    (delete-dups hosts)))

(defun ivy-ssh-config-hosts ()
  "Return a selected SSH host from the SSH config file using Ivy."
  (let* ((ssh-config-file (expand-file-name "~/.ssh/config"))
         (hosts (parse-ssh-config-hosts ssh-config-file)))
    (if hosts
        (ivy-read "SSH Hosts: " hosts)
      (user-error "No hosts found in %s" ssh-config-file))))

(defun find-file-ssh ()
  "Open a file on a remote SSH host."
  (interactive)
  (let* ((host (ivy-ssh-config-hosts))
         (default-directory (concat "/ssh:" host ":")))
    (call-interactively #'counsel-find-file)))

(defun ssh-multi-term ()
  (interactive)
  (let* (
         (host (ivy-ssh-config-hosts))
         (multi-term-program "/bin/sh")
         (multi-term-buffer-name (format "SSH: %s" host))
         (term-cmd (format "ssh %s\n" host))
         (term-buffer (multi-term))
         )
    (term-send-raw-string term-cmd)
    ))

(use-package dracula-theme
  :straight t
  :config
  (load-theme 'dracula t)
  )

(use-package diminish :straight t)

(use-package ivy
  :straight t
  :diminish
  :custom
  (ivy-count-format "(%d/%d) ")
  (enable-recursive-minibuffers t)
  :config
  (ivy-mode))

(use-package counsel
  :straight t
  :after ivy
  :diminish
  :custom
      (ivy-initial-inputs-alist nil)
  :config 
    (counsel-mode))

(use-package ivy-rich
  :straight t
  :after (ivy counsel)
  :config
  (ivy-rich-mode 1)
  )

(use-package treemacs
  :straight t
  :defer t
  :init
  (with-eval-after-load 'winum
    (define-key winum-keymap (kbd "M-0") #'treemacs-select-window))
  :config
  (progn
    (setq treemacs-collapse-dirs                   (if treemacs-python-executable 3 0)
	    treemacs-deferred-git-apply-delay        0.5
	    treemacs-directory-name-transformer      #'identity
	    treemacs-display-in-side-window          t
	    treemacs-eldoc-display                   'simple
	    treemacs-file-event-delay                2000
	    treemacs-file-extension-regex            treemacs-last-period-regex-value
	    treemacs-file-follow-delay               0.2
	    treemacs-file-name-transformer           #'identity
	    treemacs-follow-after-init               t
	    treemacs-expand-after-init               t
	    treemacs-find-workspace-method           'find-for-file-or-pick-first
	    treemacs-git-command-pipe                ""
	    treemacs-goto-tag-strategy               'refetch-index
	    treemacs-header-scroll-indicators        '(nil . "^^^^^^")
	    treemacs-hide-dot-git-directory          t
	    treemacs-indentation                     2
	    treemacs-indentation-string              " "
	    treemacs-is-never-other-window           nil
	    treemacs-max-git-entries                 5000
	    treemacs-missing-project-action          'ask
	    treemacs-move-files-by-mouse-dragging    t
	    treemacs-move-forward-on-expand          nil
	    treemacs-no-png-images                   nil
	    treemacs-no-delete-other-windows         t
	    treemacs-project-follow-cleanup          nil
	    treemacs-persist-file                    (expand-file-name ".cache/treemacs-persist" user-emacs-directory)
	    treemacs-position                        'left
	    treemacs-read-string-input               'from-child-frame
	    treemacs-recenter-distance               0.1
	    treemacs-recenter-after-file-follow      nil
	    treemacs-recenter-after-tag-follow       nil
	    treemacs-recenter-after-project-jump     'always
	    treemacs-recenter-after-project-expand   'on-distance
	    treemacs-litter-directories              '("/node_modules" "/.venv" "/.cask")
	    treemacs-project-follow-into-home        nil
	    treemacs-show-cursor                     nil
	    treemacs-show-hidden-files               t
	    treemacs-silent-filewatch                nil
	    treemacs-silent-refresh                  nil
	    treemacs-sorting                         'alphabetic-asc
	    treemacs-select-when-already-in-treemacs 'move-back
	    treemacs-space-between-root-nodes        t
	    treemacs-tag-follow-cleanup              t
	    treemacs-tag-follow-delay                1.5
	    treemacs-text-scale                      nil
	    treemacs-user-mode-line-format           nil
	    treemacs-user-header-line-format         nil
	    treemacs-wide-toggle-width               70
	    treemacs-width                           35
	    treemacs-width-increment                 1
	    treemacs-width-is-initially-locked       t
	    treemacs-workspace-switch-cleanup        nil)

    ;; The default width and height of the icons is 22 pixels. If you are
    ;; using a Hi-DPI display, uncomment this to double the icon size.
    ;;(treemacs-resize-icons 44)

    (treemacs-follow-mode t)
    (treemacs-filewatch-mode t)
    (treemacs-fringe-indicator-mode 'always)
    (when treemacs-python-executable
	(treemacs-git-commit-diff-mode t))

    (pcase (cons (not (null (executable-find "git")))
		   (not (null treemacs-python-executable)))
	(`(t . t)
	 (treemacs-git-mode 'deferred))
	(`(t . _)
	 (treemacs-git-mode 'simple)))

    (treemacs-hide-gitignored-files-mode nil))
  :bind
  (:map global-map
	  ("C-/"       . treemacs-select-window)
	  ;; ("C-x t 1"   . treemacs-delete-other-windows)
	  ("<f1>"   . treemacs)
	  ;; ("C-x t d"   . treemacs-select-directory)
	  ;; ("C-x t B"   . treemacs-bookmark)
	  ;; ("C-x t C-t" . treemacs-find-file)
	  ;; ("C-x t M-t" . treemacs-find-tag)
	  ))

(use-package treemacs-evil
  :after (treemacs evil)
  :straight t)

;; (use-package treemacs-projectile
;;   :after (treemacs projectile)
;;   :straight t)

(use-package treemacs-icons-dired
  :hook (dired-mode . treemacs-icons-dired-enable-once)
  :straight t)

(use-package treemacs-magit
  :after (treemacs magit)
  :straight t)

;; (use-package treemacs-persp ;;treemacs-perspective if you use perspective.el vs. persp-mode
;;   :after (treemacs persp-mode) ;;or perspective vs. persp-mode
;;   :straight t
;;   :config (treemacs-set-scope-type 'Perspectives))

;; (use-package treemacs-tab-bar ;;treemacs-tab-bar if you use tab-bar-mode
;;   :after (treemacs)
;;   :straight t
;;   :config (treemacs-set-scope-type 'Tabs))

(treemacs-start-on-boot)

(scroll-bar-mode -1) ;; Hide scrollbar
(tool-bar-mode -1) ;; Hide toolbar
(menu-bar-mode -1) ;; Hide menubar

(setq inhibit-startup-screen t) ;; Disable startup screen
(add-to-list 'default-frame-alist '(fullscreen . maximized)) ;; Maximize frames by default

(setopt use-short-answers t) ;; use y/n in prompts instead of typing out yes/no

;; (setq display-line-numbers-type 'relative)
;; (add-hook 'prog-mode-hook #'display-line-numbers-mode)

(setq initial-scratch-message "")

(use-package evil
  :straight t
  :init
  ;; Needed for evil-collection (see below):
  (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
  (setq evil-want-keybinding nil)
  :custom
  (evil-undo-system 'undo-redo)
  (evil-want-fine-undo t)
  (evil-lookup-func 'counsel-describe-symbol)
  (evil-respect-visual-line-mode t)
  :config
  (setopt evil-want-Y-yank-to-eol t)
  (evil-mode 1))

(use-package evil-collection
  :straight t
  :diminish evil-collection-unimpaired-mode
  :after evil
  :config
  (evil-collection-init)
  )

(use-package evil-commentary
  :straight t
  :diminish
  :after evil
  :config
  (evil-commentary-mode)
  )

(use-package evil-goggles
  :straight t
  :diminish
  :config
  (evil-goggles-mode)

  ;; optionally use diff-mode's faces; as a result, deleted text
  ;; will be highlighed with `diff-removed` face which is typically
  ;; some red color (as defined by the color theme)
  ;; other faces such as `diff-added` will be used for other actions
  (evil-goggles-use-diff-faces)

  ;; this variable affects "blocking" hints, for example when deleting - the hint is displayed,
  ;; the deletion is delayed (blocked) until the hint disappers, then the hint is removed and the
  ;; deletion executed; it makes sense to have this duration short
  (setq evil-goggles-blocking-duration 0.100) ;; default is nil, i.e. use `evil-goggles-duration'

  ;; this variable affects "async" hints, for example when indenting - the indentation
  ;; is performed with the hint visible, i.e. the hint is displayed, the action (indent) is
  ;; executed (asynchronous), then the hint is removed, highlighting the result of the indentation
  (setq evil-goggles-async-duration 0.300) ;; default is nil, i.e. use `evil-goggles-duration'
  )

(use-package evil-numbers
  :straight t
  :config
  (evil-define-key '(normal visual) 'global (kbd "C-a") 'evil-numbers/inc-at-pt)
  (evil-define-key '(normal visual) 'global (kbd "C-x") 'evil-numbers/dec-at-pt)
  (evil-define-key '(normal visual) 'global (kbd "g C-a") 'evil-numbers/inc-at-pt-incremental)
  (evil-define-key '(normal visual) 'global (kbd "g C-x") 'evil-numbers/dec-at-pt-incremental)
)

(use-package general
  :straight t
  :config
  (general-evil-setup)

  ;; set up 'SPC' as the global leader key
  (general-create-definer my-leader-def
    :states '(normal insert visual emacs treemacs)
    :keymaps 'override
    :prefix "SPC" ;; set leader
    :global-prefix "C-SPC") ;; access leader in insert mode

  (my-leader-def
    "SPC" '("Imenu" . counsel-imenu)

    ;; BUFFERS
    "b" '(:ignore t :wk "Buffers")
    "b b" '(counsel-switch-buffer :wk "Switch to buffer")
    "b i" '(ibuffer :wk "Ibuffer")
    "b k" '(kill-current-buffer :wk "Kill this buffer")
    "b n" '(next-buffer :wk "Next buffer")
    "b o" '(counsel-switch-buffer-other-window :wk "Switch buffer Other window")
    "b O" '(switch-to-buffer-other-frame :wk "Switch buffer Other frame")
    "b p" '(previous-buffer :wk "Previous buffer")
    "b r" '(rename-buffer :wk "Rename buffer")
    "b s" '(scratch-buffer :wk "Scratch buffer")
    "b x" '(kill-buffer-and-window :wk "Kill buffer, close window")

    ;; FILES
    "f" '(:ignore t :wk "Files")
    "f f" '(counsel-find-file :wk "Find file")
    "f o" '(find-file-other-window :wk "Find file Other window")
    "f r" '(counsel-recentf :wk "Recent files")
    "f s" '(find-file-ssh :wk "Find file (SSH)")
    ;; Treemacs
    "f t" '(:ignore t :wk "Treemacs")
    "f t a" '(treemacs-add-project-to-workspace :wk "Add project to workspace")
    "f t c" '(treemacs-create-workspace :wk "Create workspace")
    "f t d" '(treemacs-remove-workspace :wk "Delete workspace")
    "f t e" '(treemacs-edit-workspaces :wk "Edit workspaces")
    "f t r" '(treemacs-remove-project-from-workspace :wk "Remove project from workspace")
    "f t s" '((lambda () (interactive)
		(let (treemacs-select-when-already-in-treemacs stay)
		  (treemacs-select-window t)))
	      :wk "Switch workspace")

    ;; GIT
    "g" '(:ignore t :wk "Git")
    "g c" '(magit-checkout :wk "Checkout")
    "g g" '(magit-status :wk "Magit")
    "g r" '(diff-hl-revert-hunk :wk "Revert hunk")
    "g s" '(diff-hl-show-hunk :wk "Show hunk")
    "g v" '(diff-hl-mode :wk "Toggle diff highlighting")

    ;; SPELL CHECKING
    "s" '(:ignore t :wk "Spell Checking")
    "s s" '(flyspell-toggle :wk "Toggle")
    "s b" '(flyspell-buffer :wk "Scan Buffer")
    "s d" '(ispell-change-dictionary :wk "Change dictionary")

    ;; TERMINAL
    "t" '(:ignore t :wk "Terminal")
    "t n" '(multi-term-next :wk "Next Terminal")
    "t p" '(multi-term-prev :wk "Previous Terminal")
    "t s" '(ssh-multi-term :wk "SSH connection")
    "t t" '(multi-term :wk "New Terminal")

    ;; VIEW
    "v" '(:ignore t :wk "View")
    "v g" '(diff-hl-mode :wk "Git Diff Highlighting")
    "v l" '(display-line-numbers-mode :wk "Line numbers")
    "v t" '(toggle-truncate-lines :wk "Truncate lines")
    "v v" '(visual-line-mode :wk "Visual line mode")

    ;; WINDOWS
    "w" '(:ignore t :wk "Windows")
    ;; Window splits
    "w c" '(evil-window-delete :wk "Close window")
    "w n" '(evil-window-new :wk "New window")
    "w s" '(evil-window-split :wk "Horizontal split window")
    "w v" '(evil-window-vsplit :wk "Vertical split window")
    "w x" '(kill-buffer-and-window :wk "Kill buffer, close window")
    ;; Window motions
    "w h" '(evil-window-left :wk "Window left")
    "w j" '(evil-window-down :wk "Window down")
    "w k" '(evil-window-up :wk "Window up")
    "w l" '(evil-window-right :wk "Window right")
    "w w" '(evil-window-next :wk "Goto next window")
    "w W" '(evil-window-prev :wk "Goto previous window")
    ;; Move Windows
    "w H" '(buf-move-left :wk "Buffer move left")
    "w J" '(buf-move-down :wk "Buffer move down")
    "w K" '(buf-move-up :wk "Buffer move up")
    "w L" '(buf-move-right :wk "Buffer move right")

    ;; COMMAND
    "x" '(:ignore t :wk "Command")
    "x x" '(counsel-M-x :wk "Run Command")
    "x h" '(counsel-command-history :wk "Command History")
    "x o" 'xdg-open
    ))

(keymap-global-set "C-S-n" #'make-frame)
(keymap-global-set "C-S-w" #'delete-frame)
(keymap-global-set "C-<tab>" #'other-frame)
(keymap-global-set "C-<iso-lefttab>" (lambda () (interactive) (other-frame -1)))

(global-set-key [escape] 'keyboard-escape-quit)

(use-package which-key
  :diminish
  :custom
  (which-key-idle-delay 1.0)
  (which-key-idle-secondary-delay 0)
  (which-key-max-description-length 80)
  (which-key-show-early-on-C-h t)
  (which-key-show-docstrings t)
  :config
  (which-key-mode)
  (which-key-setup-side-window-bottom))

(use-package yasnippet
  :straight t
  :config
  (yas-global-mode 1))

(use-package company
  :straight t
  :custom
  (company-minimum-prefix-length 1)
  (company-idle-delay 0)
  (company-backends '((company-capf :with company-yasnippet)
		      (company-keywords :with company-yasnippet)))
  (company-frontends '(company-pseudo-tooltip-unless-just-one-frontend
		       company-echo-metadata-frontend
		       company-preview-common-frontend))
  :config
  (global-company-mode))

(defun flyspell-on-for-buffer-type ()
  "Enable Flyspell appropriately for the major mode of the current buffer.  Uses `flyspell-prog-mode' for modes derived from `prog-mode', so only strings and comments get checked.  All other buffers get `flyspell-mode' to check all text.  If flyspell is already enabled, does nothing."
  (interactive)
  (if (not (symbol-value flyspell-mode)) ; if not already on
      (progn
        (if (derived-mode-p 'prog-mode)
            (progn
              (message "Flyspell on (code)")
              (flyspell-prog-mode))
          ;; else
          (progn
            (message "Flyspell on (text)")
            (flyspell-mode 1)))
        (flyspell-buffer)
        )))

(defun flyspell-toggle ()
  "Turn Flyspell on if it is off, or off if it is on.  When turning on, it uses `flyspell-on-for-buffer-type' so code-vs-text is handled appropriately."
  (interactive)
  (if (symbol-value flyspell-mode)
      (progn ; flyspell is on, turn it off
        (message "Flyspell off")
        (flyspell-mode -1))
                                        ; else - flyspell is off, turn it on
    (flyspell-on-for-buffer-type)))

(use-package magit
:straight t
:commands magit-status)

(use-package diff-hl
  :straight t
  :after evil
  :config
  (add-hook 'magit-pre-refresh-hook 'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
  (evil-define-key 'motion diff-hl-mode-map (kbd "[ g") #'diff-hl-previous-hunk)
  (evil-define-key 'motion diff-hl-mode-map (kbd "] g") #'diff-hl-next-hunk)
  (global-diff-hl-mode)
  )

(add-hook 'text-mode-hook
	    (lambda ()
	      (visual-line-mode)
	      (let ((display-line-numbers-type 'visual))
		(display-line-numbers-mode))))

(use-package pdf-tools
  :straight t
  :mode ("\\.[pP][dD][fF]\\'" . pdf-view-mode)
  :config
  (pdf-tools-install))

(use-package org
  :defer t
  :init
  ;; indent text according to outline structure.
  (add-hook 'org-mode-hook 'org-indent-mode)

  ;; Auto-tangle
  (add-hook 'org-mode-hook (lambda ()
			     (add-hook 'after-save-hook
				       'org-babel-tangle nil t)))

  :config
  (setopt org-startup-folded 'fold
	  org-startup-with-inline-images t
	  org-startup-with-latex-preview t
	  org-pretty-entities t
	  org-hide-emphasis-markers t
	  org-image-actual-width 400
	  org-return-follows-link t
	  org-imenu-depth 3
	  org-highlight-latex-and-related '(latex script entities)
	  org-format-latex-options (plist-put org-format-latex-options :scale 1.5))

  ;; Default apps for opening attachments, links, etc.
  (setopt org-file-apps
	  '((auto-mode . emacs)
	    (directory . system)
	    ("pdf" . system)
            ("\\.x?html?\\'" . system)
	    (t . system)
	    (system . (lambda (path _) (xdg-open path)))))

  ;; Fix <return> commands
  (advice-add 'org-insert-heading :before (lambda (&rest _) (evil-insert 1)))
  (evil-define-key 'normal org-mode-map (kbd "<return>") 'org-return)

  ;;; SETUP EXPORTS
  ;; Allow exporting to beamer or markdown
  (require 'ox-beamer)
  (require 'ox-md)

  ;; Setup LaTeX classes
  (setopt org-latex-classes 
	  '(("article" "\\documentclass[11pt,a4paper]{article} \\usepackage[margin=2.5cm]{geometry}"
	     ("\\section{%s}" . "\\section*{%s}")
	     ("\\subsection{%s}" . "\\subsection*{%s}")
	     ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
	     ("\\paragraph{%s}" . "\\paragraph*{%s}")
	     ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))
	    ("notes" "\\documentclass[11pt,a4paper,twocolumn]{article} \\usepackage[margin=1.5cm]{geometry}"
	     ("\\section{%s}" . "\\section*{%s}")
	     ("\\subsection{%s}" . "\\subsection*{%s}")
	     ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
	     ("\\paragraph{%s}" . "\\paragraph*{%s}")
	     ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))
	    ("report" "\\documentclass[11pt,a4paper]{report} \\usepackage[margin=2.5cm]{geometry}"
	     ;; ("\\part{%s}" . "\\part*{%s}")
	     ("\\chapter{%s}" . "\\chapter*{%s}")
	     ("\\section{%s}" . "\\section*{%s}")
	     ("\\subsection{%s}" . "\\subsection*{%s}")
	     ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
	     ("\\paragraph{%s}" . "\\paragraph*{%s}")
	     ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))
	    ("book" "\\documentclass[11pt,a4paper]{book}"
	     ("\\part{%s}" . "\\part*{%s}")
	     ("\\chapter{%s}" . "\\chapter*{%s}")
	     ("\\section{%s}" . "\\section*{%s}")
	     ("\\subsection{%s}" . "\\subsection*{%s}")
	     ("\\subsubsection{%s}" . "\\subsubsection*{%s}"))))

  ;; Default export settings
  (setopt org-latex-default-class "notes"
	  org-export-headline-levels 6
	  org-export-with-priority nil
	  org-export-with-statistics-cookies nil
	  org-export-with-tags nil
	  org-export-with-toc nil
	  org-export-with-todo-keywords nil))

(use-package org-download
  :straight t
  :after org
  :custom
  (org-download-method 'directory)
  (org-download-image-dir "./org-images")
  (org-download-heading-lvl nil)
  )

;; Drag-and-drop to `dired`
(add-hook 'dired-mode-hook 'org-download-enable)

(my-leader-def org-mode-map
  "c" '("Org mode" . (keymap))

  ;; Code blocks
  "c b" '("Code block" . (keymap))
  "c b i" '("Indent block" . org-indent-block)
  "c b r" '("Hide/show result" . org-babel-hide-result-toggle)
  "c b R" '("Remove result" . org-babel-remove-result)
  "c b C-r" '("Remove ALL results" .
              (lambda () (interactive) (org-babel-remove-result-one-or-many 1)))
  "c b t" '("Tangle" . org-babel-tangle)

  ;; For working with images
  "c i" '("Image" . (keymap))
  "c i d" '("Delete image" . org-download-delete)
  "c i i" '("Toggle inline images" . org-toggle-inline-images)
  "c i p" '("Paste from clipboard" . org-download-clipboard)
  "c i P" '("Paste from link" . org-download-yank)

  ;; Copy commands
  "c y" '("Copy" . (keymap))
  "c y y" 'org-copy-special
  "c y i" 'org-id-copy
  "c y v" 'org-copy-visible

  ;; Other misc shortcuts
  "c a" '("Attach" . org-attach)
  "c C-a" '("Archive subtree" . org-archive-subtree)
  "c c" '("Context action" . org-ctrl-c-ctrl-c)
  "c e" '("Export" . org-export-dispatch)
  "c l" '("Insert link" . org-insert-link)
  "c L" '("Toggle LaTeX preview" . org-latex-preview)
  "c h" '("Toggle heading" . org-toggle-heading)
  "c p" '("Toggle pretty entities" . org-toggle-pretty-entities)
  "c s" '("Sort" . org-sort)
  )

(use-package auctex :straight t)

(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq-default TeX-master nil)

;; (add-hook 'LaTeX-mode-hook 'visual-line-mode)
;; (add-hook 'LaTeX-mode-hook 'auto-fill-mode)
(add-hook 'LaTeX-mode-hook 'flyspell-mode)
(add-hook 'LaTeX-mode-hook 'LaTeX-math-mode)

(add-hook 'LaTeX-mode-hook 'turn-on-reftex)
(setq reftex-plug-into-AUCTeX t)

;; Use pdf-tools to open PDF files
(setq TeX-view-program-selection '((output-pdf "PDF Tools"))
      TeX-source-correlate-start-server t)

;; Update PDF buffers after successful LaTeX runs
(add-hook 'TeX-after-compilation-finished-functions
          #'TeX-revert-document-buffer)

(setq preview-default-option-list '("displaymath" "textmath" "graphics"))
(setq preview-auto-reveal t)

(defun better-LaTeX-insert-item ()
  (interactive)
  (let ((environment (LaTeX-current-environment)))
    (when (and (TeX-active-mark)
               (> (point) (mark)))
      (exchange-point-and-mark))
    (if (save-excursion
          ;; If the current line has only whitespace characters, put
          ;; the new \item on this line, not creating a new line
          ;; below.
          (goto-char (line-beginning-position))
          (if LaTeX-insert-into-comments
              (re-search-forward
               (concat "\\=" TeX-comment-start-regexp "+")
               (line-end-position) t))
          (looking-at "[ \t]*$"))
        (delete-region (match-beginning 0) (match-end 0))
      (progn (end-of-line) (LaTeX-newline)))

    (if (not (or (string-prefix-p "item" environment)
		 (string-prefix-p "enum" environment)))
	(LaTeX-insert-environment "itemize"))

    (TeX-insert-macro "item")
    (indent-according-to-mode)
    (evil-insert 1)
    ))

(with-eval-after-load 'latex
  (define-key LaTeX-mode-map (kbd "M-<return>") #'better-LaTeX-insert-item)
  )

(my-leader-def LaTeX-mode-map
  "c" '("LaTeX" . (keymap))

  "c a" '("Run all commands" . TeX-command-run-all)
  "c c" '("Command" . TeX-command-master)
  "c e" '("Environment" . LaTeX-environment)
  "c s" '("Section" . LaTeX-section)

  "c q" '("Fill" . (keymap))
  "c q e" '("Fill environment" . LaTeX-fill-environment)
  "c q p" '("Fill paragraph" . LaTeX-fill-paragraph)
  "c q r" '("Fill region" . LaTeX-fill-region)
  "c q s" '("Fill section" . LaTeX-fill-section)
  )

(add-hook 'LaTeX-mode-hook
          (lambda ()
            (setq-local wc-count-words-function
                        (function (lambda (rstart rend)
                                    (let* ((output-buffer-name "*detex-output*")
                                           (output-buffer (generate-new-buffer output-buffer-name)))
                                      (unwind-protect
                                          (progn
                                            (call-process-region rstart rend "detex"
                                                                 nil output-buffer-name nil)
                                            (with-current-buffer output-buffer
                                              (count-words (point-min) (point-max))))
                                        (kill-buffer output-buffer))))))))

(use-package markdown-mode
  :straight t
  :mode ("README\\.md\\'" . gfm-mode)
  :init
  (setq markdown-command "pandoc")
  (setq markdown-enable-math t))

(add-hook 'prog-mode-hook
	  (lambda ()
	    (let ((display-line-numbers-type 'relative))
	      (display-line-numbers-mode))))

(my-leader-def python-mode-map
  "c" '("Python" . (keymap))

  "c i" '("Interactive shell" . run-python)
  "c c" '("Python3 command" .
          (lambda () (interactive)
            (async-shell-command (concat "python3 " (read-from-minibuffer "python3 ")))))

  "c p" '("Set pyenv version" . pyenv-mode-set)
  "c P" '("Disable pyenv" . pyenv-mode-unset)
  "c s" '("Send buffer to shell" .
	  (lambda () (interactive)
	    (unless (comint-check-proc (python-shell-get-buffer))
	      (call-interactively #'run-python)
	      (sleep-for 0.5))
	    (call-interactively #'python-shell-send-buffer)))
  )

(defun http-server () (interactive)
       (let ((dir (read-from-minibuffer "Directory: " default-directory))
             (port (read-from-minibuffer "Port: " "8000")))
         (async-shell-command (concat "python3 -m http.server -d " dir " " port)
                              (concat "*HTTP Server on port " port " [" dir "]*"))
         (start-process "" nil "firefox" "--new-tab" (concat "http://localhost:" port))))

(use-package yaml-mode
  :straight t)
