(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.5)
(add-hook 'emacs-startup-hook
	  (lambda () (setq gc-cons-threshold 800000)))

(setq package-enable-at-startup nil)
