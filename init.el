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

(use-package system-packages :straight t)
(use-package use-package-ensure-system-package)

(setopt make-backup-files nil)

(defun expand-file-name-cache (file-name)
  (let* ((cache-dir (expand-file-name ".cache" user-emacs-directory))
	 (file-path (expand-file-name file-name cache-dir))
	 (file-dir (file-name-directory file-path)))
    (make-directory file-dir t) file-path))

(setq custom-file (concat user-emacs-directory "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

(setopt recentf-save-file (expand-file-name-cache "recentf.el")
	recentf-exclude '((lambda (f)
			    (file-in-directory-p
			     f (expand-file-name ".cache" user-emacs-directory))))
	recentf-max-saved-items 100)

(recentf-mode)

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

(use-package dracula-theme
  :straight t
  :config
  (load-theme 'dracula t))

(set-face-attribute 'default nil
		    :font "Iosevka SS12"
		    :width 'expanded)

(set-face-attribute 'fixed-pitch nil
		    :font "Iosevka Fixed SS12"
		    :width 'expanded)

(set-face-attribute 'variable-pitch nil
		    :font "Iosevka Etoile")

(mapc (lambda (f) (set-face-attribute f nil :width 'normal))
      '(mode-line mode-line-inactive))

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

(setopt display-line-numbers-width-start t)

(defun enable-line-numbering ()
  (interactive)
  (if visual-line-mode
      (let ((display-line-numbers-type 'visual))
	(display-line-numbers-mode))
      (let ((display-line-numbers-type 'relative))
	(display-line-numbers-mode))))

(add-hook 'text-mode-hook 'enable-line-numbering)
(add-hook 'prog-mode-hook 'enable-line-numbering)
(add-hook 'visual-line-mode-hook 'enable-line-numbering)

(setopt use-short-answers t) ;; use y/n in prompts instead of typing out yes/no
(setq initial-scratch-message "") ;; Make scratch buffer empty by default
(setq-default word-wrap t) ;; Truncate: don't split in the middle of a word
(global-visual-wrap-prefix-mode) ;; Correctly align wrapped lines
;; Remove truncation symbols
(setq-default fringe-indicator-alist
  	      (mapcar (lambda (cell)
  			(if (eq (car cell) 'truncation)
  			    (cons 'truncation nil) cell))
  		      fringe-indicator-alist))

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

(use-package evil-visualstar
  :straight t
  :config (global-evil-visualstar-mode)
  :after evil)

(use-package general
  :straight t
  :config
  (general-evil-setup)

  ;; set up 'SPC' as the global leader key
  (general-create-definer my-leader-def
    :states '(normal insert visual emacs)
    :keymaps 'override
    :prefix "SPC" ;; set leader
    :global-prefix "C-SPC")) ;; access leader in insert mode

(my-leader-def
  "SPC" '("Imenu/Outline" . (lambda () (interactive)
			      (if (derived-mode-p 'text-mode)
				  (call-interactively 'counsel-outline)
				(call-interactively 'counsel-imenu))))

  ;; BUFFERS
  "b" '("Buffers" . (keymap))
  "b b" '("Switch to buffer" . counsel-switch-buffer)
  "b i" '("Ibuffer" . ibuffer)
  "b k" '("Kill this buffer" . kill-current-buffer)
  "b n" '("Next buffer" . next-buffer)
  "b o" '("Switch buffer Other window" . counsel-switch-buffer-other-window)
  "b O" '("Switch buffer Other frame" . switch-to-buffer-other-frame)
  "b p" '("Previous buffer" . previous-buffer)
  "b r" '("Rename buffer" . rename-buffer)
  "b s" '("Scratch buffer" . scratch-buffer)
  "b x" '("Kill buffer, close window" . kill-buffer-and-window)

  ;; FILES
  "f" '("Files" . (keymap))
  "f f" '("Find file" . counsel-find-file)
  "f o" '("Find file Other window" . find-file-other-window)
  "f r" '("Recent files" . counsel-recentf)
  ;; "f s" '("Find file (SSH)" . find-file-ssh)
  ;; Treemacs
  ;; "f t" '("Treemacs" . (keymap))
  ;; "f t a" '("Add project to workspace" . treemacs-add-project-to-workspace)
  ;; "f t c" '("Create workspace" . treemacs-create-workspace)
  ;; "f t d" '("Delete workspace" . treemacs-remove-workspace)
  ;; "f t e" '("Edit workspaces" . treemacs-edit-workspaces)
  ;; "f t r" '("Remove project from workspace" . treemacs-remove-project-from-workspace)
  ;; "f t s" '((lambda () (interactive)
  	      ;; (let (treemacs-select-when-already-in-treemacs stay)
  		;; (treemacs-select-window t)))
  	    ;; :wk "Switch workspace")

  ;; GIT
  "g" '("Git" . (keymap))
  "g c" '("Checkout" . magit-checkout)
  "g g" '("Magit" . magit-status)
  "g r" '("Revert hunk" . diff-hl-revert-hunk)
  "g s" '("Show hunk" . diff-hl-show-hunk)
  "g v" '("Toggle diff highlighting" . diff-hl-mode)

  ;; SPELL CHECKING
  "s" '("Spell Checking" . (keymap))
  "s s" '("Toggle" . flyspell-toggle)
  "s b" '("Scan Buffer" . flyspell-buffer)
  "s d" '("Change dictionary" . ispell-change-dictionary)

  ;; VIEW
  ;; "v" '("View" . (keymap))
  ;; "v g" '("Git Diff Highlighting" . diff-hl-mode)
  ;; "v l" '("Line numbers" . display-line-numbers-mode)
  ;; "v t" '("Truncate lines" . toggle-truncate-lines)
  ;; "v v" '("Visual line mode" . visual-line-mode)

  ;; WINDOWS
  "w" '("Windows" . (keymap))
  ;; Window splits
  "w c" '("Close window" . evil-window-delete)
  "w n" '("New window" . evil-window-new)
  "w s" '("Horizontal split window" . evil-window-split)
  "w v" '("Vertical split window" . evil-window-vsplit)
  "w x" '("Kill buffer, close window" . kill-buffer-and-window)
  ;; Window motions
  "w h" '("Window left" . evil-window-left)
  "w j" '("Window down" . evil-window-down)
  "w k" '("Window up" . evil-window-up)
  "w l" '("Window right" . evil-window-right)
  "w w" '("Goto next window" . evil-window-next)
  "w W" '("Goto previous window" . evil-window-prev)
  "w r" '("Rotate windows (down)" . evil-window-rotate-downwards)
  "w R" '("Rotate windows (up)" . evil-window-rotate-upwards)

  ;; COMMAND
  "x" '("Command" . (keymap))
  "x x" '("Run Command" . counsel-M-x)
  "x h" '("Command History" . counsel-command-history)
  "x o" 'xdg-open

  "y" '("Yasnippet" . (keymap))
  "y y" '("Insert snippet" . yas-insert-snippet)
  "y n" '("New snippet" . yas-new-snippet)
  "y e" '("Edit snippet" . yas-visit-snippet-file)
  )

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
  :diminish yas-minor-mode
  :config (yas-reload-all)
  (setopt yas-wrap-around-region t)
  :hook
  ((text-mode . yas-minor-mode)
   (prog-mode . yas-minor-mode)))

(use-package company
  :straight t
  :diminish
  :custom
  (company-minimum-prefix-length 1)
  (company-idle-delay 0)
  (company-require-match nil)
  (company-backends '(company-capf company-keywords))
  (company-frontends '(company-preview-common-frontend))
  :hook (prog-mode text-mode))

(use-package company-box
  :straight t
  :diminish
  :custom
  (company-box-scrollbar nil)
  (company-box-show-single-candidate 'when-no-other-frontend)
  :hook company-mode)

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

(use-package ghostel
  :straight t
  :defer t
  :config
  (setopt ghostel-module-auto-install 'download)
  (add-hook 'ghostel-mode-hook (lambda () (setq-local evil-lookup-func 'woman))))

(use-package ghostel-eshell
  :hook (eshell-load . ghostel-eshell-visual-command-mode))

(use-package ghostel-comint
  :hook (after-init . ghostel-comint-global-mode))

(use-package evil-ghostel
  :straight t
  :after (ghostel evil)
  :hook (ghostel-mode . evil-ghostel-mode))

(my-leader-def
  "t" '("Terminal" . (keymap))
  "t t" 'ghostel
  "t b" 'ghostel-list-buffers
  )

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

(use-package git-modes
  :straight t)

(use-package projectile
  :straight t
  :ensure-system-package (fdfind . fd-find)
  :custom
  (projectile-project-search-path '("~/Code"))
  (projectile-auto-discover t)
  (projectile-known-projects-file
   (expand-file-name-cache "projectile/known-projects.el"))
  (projectile-cache-file
   (expand-file-name-cache "projectile/cache.el"))
  :config
  (my-leader-def projectile-mode-map
    "p" '("Projectile" . projectile-command-map))
  (projectile-mode 1))

(use-package rg
  :straight t
  :ensure-system-package (rg . ripgrep))

(add-hook 'text-mode-hook 'visual-line-mode)
(add-hook 'text-mode-hook 'flyspell-mode)

(use-package mixed-pitch
  :straight t
  :diminish
  :hook text-mode)

(use-package pdf-tools
  :straight t
  :mode ("\\.[pP][dD][fF]\\'" . pdf-view-mode)
  :config
  (pdf-tools-install)
  (add-hook 'pdf-view-mode-hook 'pdf-view-roll-minor-mode))

(use-package org
  :straight t
  :defer t
  :init
  ;; indent text according to outline structure.
  (add-hook 'org-mode-hook 'org-indent-mode -90)
  (add-hook 'org-indent-mode-hook
	    (lambda () (diminish 'org-indent-mode)))

  ;; Disable visual-wrap-prefix-mode (clashes with org-modern)
  (add-hook 'org-mode-hook (lambda ()
			     (visual-wrap-prefix-mode -1)) -90)

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
	  org-imenu-depth 8
	  org-ellipsis "…"
	  org-highlight-latex-and-related '(latex script entities)
	  org-format-latex-options (plist-put org-format-latex-options :scale 1.0))

  ;; Default apps for opening attachments, links, etc.
  (setopt org-file-apps
	  '((auto-mode . emacs)
	    (directory . system)
	    ("pdf" . system)
            ("\\.x?html?\\'" . system)
	    (t . system)
	    (system . (lambda (path _) (xdg-open path)))))

  ;; Todo settings
  (setopt org-fontify-done-headline nil
	  org-todo-keywords '((sequence "TODO" "WAIT" "|" "DONE" "CANCEL")))

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
	  org-export-with-todo-keywords nil)

  ;; OrgSrc evil keymap
  ;; (with-eval-after-load 'org-src
  ;;   (evil-define-key 'normal org-src-mode-map
  ;;     "ZZ" 'org-edit-src-exit
  ;;     "ZQ" 'org-edit-src-abort))
  )

(use-package org-download
  :straight t
  :after org
  :custom
  (org-download-method 'directory)
  (org-download-image-dir "./org-images")
  (org-download-heading-lvl nil))

;; Drag-and-drop to `dired`
;; (add-hook 'dired-mode-hook 'org-download-enable)

(use-package org-modern
  :straight t
  :hook org-mode
  :config
  ;; Todo
  (setopt org-modern-todo-faces '(("TODO" :background "#FF5555" :foreground "#282A36")
				  ("WAIT" :background "#FFB86C" :foreground "#282A36")
				  ("DONE" :background "#50FA7B" :foreground "#282A36")
				  ("CANCEL" :background "#6272A4" :foreground "#F8F8F2")))

  ;; Priority
  (setopt org-modern-priority-faces '((?A :background "#FF5555" :foreground "#282A36")
				      (?B :background "#FFB86C" :foreground "#282A36")
				      (?C :background "#F1FA8C" :foreground "#282A36")))

  ;; Tags
  (set-face-background 'org-modern-tag "#8BE9FD")
  (set-face-foreground 'org-modern-tag "#282A36")

  ;; Progress
  (setopt org-modern-progress 8)
  (set-face-background 'org-modern-progress-incomplete "#6272A4")
  (set-face-foreground 'org-modern-progress-incomplete "#F8F8F2")
  (set-face-background 'org-modern-progress-complete "#50FA7B")
  (set-face-foreground 'org-modern-progress-complete "#282A36"))

(use-package org-modern-indent
  :straight
  (org-modern-indent :type git :host github :repo "jdtsmith/org-modern-indent")
  :hook org-mode)

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

(use-package auctex
  :straight t
  :ensure-system-package (latex . texlive-full)
  :defer t
  :config
  (setq TeX-auto-save t)
  (setq TeX-parse-self t)
  (setq-default TeX-master nil)

  (setq preview-default-option-list '("displaymath" "textmath" "graphics"))
  (setq preview-auto-reveal t)


  ;; Reftex
  (add-hook 'LaTeX-mode-hook 'turn-on-reftex)
  (setq reftex-plug-into-AUCTeX t)

  ;; Use pdf-tools to open PDF files
  (setq TeX-view-program-selection '((output-pdf "PDF Tools"))
        TeX-source-correlate-start-server t)

  ;; Update PDF buffers after successful LaTeX runs
  (add-hook 'TeX-after-compilation-finished-functions
            #'TeX-revert-document-buffer)

  ;; Enable SyncTeX support
  (setopt TeX-source-correlate-mode t)

  ;; Setup Company backends
  (defun setup-latex-company-backends ()
    (require 'company-reftex)
    (require 'company-math)
    (setq-local company-backends
		(append '(company-math-symbols-latex
			  company-latex-commands
			  company-reftex-labels
			  company-reftex-citations)
			company-backends)))

  (add-hook 'TeX-mode-hook 'setup-latex-company-backends))

(use-package bibtex
  :defer t
  :config
  (add-hook 'bibtex-mode-hook 'auto-revert-mode))

(use-package company-reftex
  :straight t
  :defer t)

(use-package company-math
  :straight t
  :defer t)

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

(defun tex-count-words-in-document ()
  (interactive)
  (let* ((master-file (expand-file-name (TeX-master-file t)))
	 (default-directory (file-name-directory master-file))
	 (output-buffer (generate-new-buffer "*detex-ouput*" t)))
    (unwind-protect 
	(with-current-buffer output-buffer
	  (call-process "detex" master-file t)
	  (call-interactively 'count-words))
      (kill-buffer output-buffer))))

(my-leader-def LaTeX-mode-map
  "c" '("LaTeX" . (keymap))

  "c a" 'TeX-command-run-all
  "c c" 'TeX-command-master
  "c s" 'TeX-save-document
  "c w" 'tex-count-words-in-document
  )

(use-package markdown-mode
  :straight t
  :ensure-system-package pandoc
  :mode ("README\\.md\\'" . gfm-mode)
  :init
  (setq markdown-command "pandoc"
	markdown-enable-math t
	markdown-hide-markup t))

(use-package edit-indirect
  :straight t
  :defer t)

(my-leader-def markdown-mode-map
  "c" '("Markdown" . (keymap))

  ;; Links and images
  "c i" 'markdown-insert-image
  "c l" 'markdown-insert-link

  ;; Remap
  "c c" `("Command" . ,(keymap-lookup markdown-mode-map "C-c C-c"))
  "c s" `("Styling" . ,(keymap-lookup markdown-mode-map "C-c C-s"))
  "c x" `("Toggle" . ,(keymap-lookup markdown-mode-map "C-c C-x")))

(use-package highlight-indent-guides
  :diminish
  :straight t
  :hook prog-mode
  :custom
  (highlight-indent-guides-method 'bitmap)
  (highlight-indent-guides-bitmap-function
   'highlight-indent-guides--bitmap-line)
  (highlight-indent-guides-responsive 'top)
  (highlight-indent-guides-auto-character-face-perc 30)
  (highlight-indent-guides-auto-top-character-face-perc 80))

(use-package flycheck
  :straight t
  :commands flycheck-mode
  :init
  (add-hook 'prog-mode-hook
	    (lambda () (when (buffer-file-name) (flycheck-mode)))))

(use-package flycheck-posframe
  :straight t
  :hook flycheck-mode
  :config
  (flycheck-posframe-configure-pretty-defaults)
  (setq flycheck-posframe-position 'point-window-center
	flycheck-posframe-border-width 1
	flycheck-posframe-border-use-error-face t))

(add-hook 'prog-mode-hook 'hs-minor-mode)

(use-package lsp-mode
  :straight t
  :hook (python-mode . lsp-deferred)
  :commands (lsp lsp-deferred))

(defun http-server () (interactive)
       (let ((dir (read-from-minibuffer "Directory: " default-directory))
             (port (read-from-minibuffer "Port: " "8000")))
         (async-shell-command (concat "python3 -m http.server -d " dir " " port)
                              (concat "*HTTP Server on port " port " [" dir "]*"))
         (start-process "" nil "firefox" "--new-tab" (concat "http://localhost:" port))))

(use-package yaml-mode
  :straight t)

(use-package sh-script
  :defer t
  :config
  (add-hook 'sh-mode-hook (lambda () (setq-local evil-lookup-func 'woman)))
  :ensure-system-package shellcheck)

(use-package gptel
  :straight t
  :defer t
  :config
  (setq gptel-backend (gptel-make-openai "OpenRouter"
			:host "openrouter.ai"
			:endpoint "/api/v1/chat/completions"
			:stream t
			:key #'gptel-api-key-from-auth-source
			:models (gptel-openrouter-models))
	gptel-model 'openrouter/free
	gptel-default-mode 'org-mode
	;; gptel-org-convert-response nil
	gptel-track-media t)
  ;; (add-hook 'gptel-post-response-functions
  ;; 	    (lambda (beg end)
  ;; 	      (message "BEG: %s --- END: %s" beg end)))
  )

(use-package gptel-openrouter-models
  :straight (gptel-openrouter-models :type git :host github
                                     :repo "skissue/gptel-openrouter-models"
                                     :files ("openrouter-models.json" :defaults))
  :defer t)

(use-package llm-tool-collection
  :straight (llm-tool-collection :type git :host github
				 :repo "skissue/llm-tool-collection")
  :after gptel
  :config (mapcar (apply-partially #'apply #'gptel-make-tool)
		  (llm-tool-collection-get-all)))

(defun opencode ()
  (interactive)
  (let* ((default-directory (or (projectile-project-root)
				(projectile-completing-read "Select project: "
							    projectile-known-projects)))
	 (cmd (or (executable-find "opencode")
		  (error "OpenCode not found")))
	 (buf-name (concat "*OpenCode: " (projectile-project-name) "*"))
	 (buf-exists (get-buffer buf-name)))
    (switch-to-buffer-other-window buf-name)
    (unless buf-exists
      (ghostel-exec (get-buffer buf-name) cmd)
      (setq-local ghostel-buffer-name-function nil)
      (evil-local-set-key 'insert (kbd "C-x") 'ghostel--send-event))))

(my-leader-def
  "a" '("LLM" . (keymap))
  "a a" 'gptel-menu
  "a i" 'gptel
  "a o" '("OpenCode" . opencode)
  )
