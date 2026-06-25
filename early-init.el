(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.5)
(add-hook 'emacs-startup-hook
	  (lambda () (setq gc-cons-threshold 800000)))

(setq package-enable-at-startup nil)

(scroll-bar-mode -1) ;; Hide scrollbar
(tool-bar-mode -1) ;; Hide toolbar
(menu-bar-mode -1) ;; Hide menubar

(setq inhibit-startup-screen t) ;; Disable startup screen
(add-to-list 'default-frame-alist '(fullscreen . maximized)) ;; Maximize frames by default
