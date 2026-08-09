;;; r2-clide.el --- CL IDE -*- lexical-binding: t -*-

;;; Commentary:


;;; Code:



;;; General Editing/Dev Tools

;; Interpreter Mode Alist
;; (add-to-list 'interpreter-mode-alist '("Lisp" . lisp-mode))

;; .dir-local variables for development projects
(r2/setopts enable-local-eval t
            enable-local-variables :safe
            "Set the safe variables, and ignore the rest.")

(set-default-coding-systems 'utf-8)

(r2/setopts global-auto-revert-non-file-buffers t
            tab-width 8
            indent-tabs-mode nil
            ;; "Use spaces instead of tabs."
            sentence-end-double-space t
            large-file-warning-threshold 100000000
            find-file-visit-truename t)

(global-auto-revert-mode 1)
(delete-selection-mode)

(use-package display-line-numbers
  :ensure nil
  :hook ((scheme-mode lisp-mode emacs-lisp-mode nix-mode)
         . display-line-numbers-mode))

(use-package display-fill-column-indicator
  :ensure nil
  ;; TODO: Customize theme color for this element -> via ':config' keyword
  :diminish
  :hook ((prog-mode) . display-fill-column-indicator-mode)
  :custom
  (fill-column 81)
  (display-fill-column-indicator-column fill-column)
  :config
  ;; Make fill-column-indicator face darker --> line-number face
  ;; theme value #5c5e5e --> #3f4040 (good with doom-tomorrow-night theme)
  (r2/set-face-attribute 'fill-column-indicator '(:foreground "#3f4040")))

(use-package eldoc
  :ensure nil
  :defer t
  :diminish eldoc-mode)

(use-package ediff
  :ensure nil
  :defer t
  :custom
  (ediff-split-window-function 'split-window-horizontally)
  (ediff-window-setup-function 'ediff-setup-windows-plain)
  :config
  ;; Save & Restore Window configuration
  ;; https://www.emacswiki.org/emacs/EdiffMode
  (add-hook
   'ediff-load-hook
   (lambda ()
     (add-hook 'ediff-before-setup-hook
               (lambda ()
                 (setq ediff-saved-window-configuration
                       (current-window-configuration))))
     (let ((restore-window-configuration
            (lambda ()
              (set-window-configuration ediff-saved-window-configuration))))
       (add-hook 'ediff-quit-hook
                 restore-window-configuration
                 'append)
       (add-hook 'ediff-suspend-hook
                 restore-window-configuration
                 'append)))))

(use-package paredit
  :ensure t
  :diminish paredit-mode
  :hook ((lisp-interaction-mode
          emacs-lisp-mode
          lisp-mode
          scheme-mode)
         . enable-paredit-mode))

(use-package undo-tree
  :ensure (undo-tree :pin gnu)
  :diminish undo-tree-mode
  :hook (emacs-startup . global-undo-tree-mode)
  :custom
  (undo-tree-history-directory-alist
   `(("." . ,(expand-file-name "undo-tree-hist/"
                               r2-var-directory))))
  :config
  (setq kill-do-not-save-duplicates t))

(use-package ws-butler
  :ensure t
  :diminish ws-butler-mode
  :hook ((text-mode prog-mode) . ws-butler-mode))

(use-package flycheck
  :ensure t
  :diminish
  ;; flycheck freezes emacs when enabled in lisp-mode and using reader
  ;; macros (e.g. #+nil) as well as freezes when used alongside corfu
  ;; in general - disabling any sort of auto-enabling for now...
  ;; :hook ((emacs-lisp-mode) . flycheck-mode)
  :custom
  (flycheck-checker-error-threshold 2000 "Increase error threshold."))

(use-package colorful-mode
  :ensure t
  :diminish
  ;; :hook (prog-mode . colorful-mode)
  :custom
  (colorful-use-prefix t)
  (colorful-only-strings 'only-prog)
  (css-fontify-colors nil)
  :config
  ;; (global-colorful-mode t)
  (add-to-list 'global-colorful-modes 'helpful-mode))

(use-package xr
  :ensure t
  :defer t)

;;; Shells
(use-package eat
  :if (eq system-type 'gnu/linux)
  :ensure t
  :bind (:map eat-semi-char-mode-map
              ("M-o" . ace-window)))

(use-package shell
  :if (eq system-type 'windows-nt)
  :ensure nil
  :hook (shell-mode . r2/shell-config)
  :bind (:map shell-mode-map
              ("C-c l" . comint-clear-buffer))
  :init
  ;; Use PowerShell 7 for `M-x shell`
  (setq explicit-shell-file-name
        (concat "C:/Users/erik.almaraz/AppData/Local/"
                "Microsoft/WindowsApps/pwsh.exe"))

  ;; Arguments passed to pwsh.exe
  (setq explicit-pwsh.exe-args '())

  ;; Ensure subprocesses use pwsh too
  (setq shell-file-name explicit-shell-file-name)

  :config
  (defun r2/shell-config ()
    "Improve shell-mode behavior"
    (setq comint-prompt-read-only t
          comint-scroll-to-bottom-on-input t)
    ;; Avoid command echo odities in some shells
    (setq-local comint-process-echoes t)))

;;--------------------------------------------------------------------------------
;; Keep for reference
(use-package powershell
  :disable
  :if (eq system-type 'windows-nt)
  :load-path r2-contrib-directory       ; can load custom modules via use-package
  ;; :vc (:url "https://github.com/jschaf/powershell.el" :branch "main")
  :config
  (setq explicit-powershell.exe-args '("-NoLogo" "-NoProfile")))
;;--------------------------------------------------------------------------------

(use-package neotree
  :ensure t
  :defer t
  :config
  (setq neo-smart-open t
        neo-show-hidden-files t
        neo-window-width 35
        neo-mode-line-type 'none
        neo-window-fixed-size nil
        inhibit-compacting-font-caches t)

  (setq neo-theme (if (display-graphic-p) 'nerd-icons 'arrow))


  ;; truncate long file names in neotree
  (add-hook 'neo-after-create-hook
            #'(lambda (_)
                (with-current-buffer (get-buffer neo-buffer-name)
                  (setq truncate-lines t)
                  (setq word-wrap nil)
                  (make-local-variable 'auto-hscroll-mode)
                  (setq auto-hscroll-mode nil)))))

(use-package keycast
  :ensure t
  ;; :hook (prog-mode . keycast-mode-line-mode)
  :bind ("C-c k" . keycast-header-line-mode))

(use-package mermaid-mode
  :ensure t)


;;; Guile Scheme IDE

(r2/setopts scheme-program-name "guile")

;; `emacs-guix' dependencies:
;; emacs-bui, emacs-dash, emacs-edit-indirect,
;; emacs-geiser, emacs-geiser-guile, emacs-magit-popup
;; module-import-compiled
(use-package guix
  :if (eq system-type 'gnu/linux)
  :ensure t
  :defer t)

(use-package geiser
  :if (eq system-type 'gnu/linux)
  :ensure nil
  :custom
  (geiser-mode-auto-p nil)
  (geiser-active-implementations '(guile))
  (geiser-default-implementation '(guile)))

(use-package consult
  :if (eq system-type 'gnu/linux)
  :ensure t)

(use-package sesman
  :if (eq system-type 'gnu/linux)
  :ensure t
  :pin nongnu)

(use-package arei
  :if (eq system-type 'gnu/linux)
  :vc (:url "https://git.sr.ht/~abcdw/emacs-arei"
       :lisp-dir "lisp"
       :rev :newest)
  :commands (r2/kill-ares-nrepl
             r2/ares-nrepl-start)
  :init
  (global-arei-mode)
  :config
  (require 'cl-lib)

  ;; Prevent `geiser' from interfering into completion (CAPF)
  (setq geiser-mode-auto-p nil)

  (defvar r2/ares-rs--process nil
    "Holds process for Ares nREPL RPC server.")

  (defun get-project-root-or-cwd ()
    "Get Project Root or Current working directory"
    (or (project-root (project-current))
        default-directory))

  (defun r2/kill-ares-nrepl ()
    "Kill Ares RS nREPL RPC server."
    (interactive)
    (when r2/ares-rs--process
      (ignore-errors
        (kill-process r2/ares-rs--process)
        (let ((port-file (expand-file-name
                          (concat (get-project-root-or-cwd)
                                  ".nrepl-port"))))
          (when (file-exists-p port-file)
            (delete-file port-file))))
      (setq r2/ares-rs--process nil)))

  (defun r2/ares-nrepl-start ()
    "Start Ares nREPL RPC server in Project Root or CWD."
    (interactive)

    (let* ((path (get-project-root-or-cwd))
           (bname (concat "*" (symbol-name (gensym "ares-nrepl-process-")) "*")))
      (r2/kill-ares-nrepl)
      (setq r2/ares-rs--process
            (start-process-shell-command
             bname
             (get-buffer-create bname)
             (concat "cd " path " && "
                     "ares-nrepl "
                     " -- "
                     "-L " path)))
      ;; Automatically start sesman session
      (when r2/ares-rs--process
        (ignore-errors
          (sesman-link-with-least-specific))))))


;;; Common Lisp IDE
(use-package lisp-comment-dwim
  :disable
  :vc (:url "https://github.com/dotemacs/lisp-comment-dwim.el" :branch "main")
  :custom (lisp-comment-dwim-comment-macro "#+nil")
  :config
  (lisp-comment-dwim-setup-keybindings))

;; NOTE: `sly.el' and its `sly-fancy' contrib (via `(sly-setup '(sly-fancy))'
;; in `:config') must be loaded before the first lisp-mode buffer's
;; `lisp-mode-hook' runs -- otherwise `sly-editing-mode' triggers the
;; load lazily, mid-iteration of that same hook run, so contrib setup
;; (which mutates `lisp-mode-hook' and `font-lock-extend-region-functions')
;; misses the first buffer's pass entirely, and `#+nil'-style
;; reader-conditional fontification silently fails to apply until the
;; buffer is edited or reopened.
;;
;; We force the load via an idle timer in `:init' rather than `:demand
;; t', since the latter loads synchronously during init and measurably
;; slows startup. The idle timer still guarantees `sly' is fully loaded
;; before any realistic first buffer-open, without that cost -- `:config'
;; runs via `with-eval-after-load' either way, so a plain `(require
;; 'sly)' from the timer triggers it same as `:demand t' would.
;;
;; Only `sly-editing-mode' itself goes through `use-package's `:hook' --
;; it's autoloaded by `sly' proper, so `use-package' can safely generate
;; the autoload stub for it. Our own hook functions (`r2/sly-auto-connect',
;; `r2/sly-completions', `r2/register-mrepl-frame', etc.) are defined
;; inside this block's `:config', not inside `sly' itself, so `:hook'
;; would generate an autoload pointing at `sly.elc' for a symbol that
;; file never defines -- it fails at hook-run time with a "failed to
;; define function" error. Wiring them via our own hooking macro instead
;; runs `add-hook' directly against functions that already exist by the
;; time `:config' reaches them, sidestepping that entirely.
;;
;; `r2/sly-refresh-fontification' on `sly-connected-hook' covers the
;; remaining gap: the first buffer's initial fontification pass runs
;; before the async SLY connection completes.
(use-package sly
  :ensure t
  ;; Enable sly IDE for Common Lisp
  :hook ((lisp-mode . sly-editing-mode))
  :init
  (run-with-idle-timer 1 nil (lambda () (require 'sly)))
  :custom
  (sly-default-lisp 'sbcl
                    "Set default lisp to Steel Bank Common Lisp.")
  :config
  ;; `sly-setup' loads contribs once at init to avoid a lisp-mode-hook race;
  ;; `sly-symbol-completion-mode' is global, so disable it once here too,
  ;; not per-buffer (that caused the corrupted-timer bug).
  (sly-setup '(sly-fancy))
  (sly-symbol-completion-mode -1)
  ;; Disable Sylvester the cat
  (setq sly-mrepl-pop-sylvester nil)

  ;; Provide proper syntax highlighting for `defsystem'
  (font-lock-add-keywords
   'lisp-mode
   '(("(\\s-*\\(defsystem\\)\\>" 1 font-lock-keyword-face append)))

  ;; Invoke SLY with a negative prefix argument, M-- M-x sly,
  ;; and you can select a program from that list.
  (setq sly-lisp-implementations
        '((sbcl  ("sbcl") :coding-system utf-8-unix)
          (clasp ("clasp") :coding-system utf-8-unix)
          (ecl   ("ecl")  :coding-system utf-8-unix)))

  ;; Ensure history file exists
  (let ((history-file (expand-file-name "var/sly/mrepl-history"
                                        r2-xdg-cache-home)))
    (make-directory (file-name-directory history-file) t)
    (unless (file-exists-p history-file)
      (write-region "" nil history-file)))

  ;; Open Sly mREPL in background
  (setq display-buffer-alist
        (cons '("\\*sly-mrepl"
                (display-buffer-no-window)
                (allow-no-window . t))
              display-buffer-alist))

  ;; Register sly mrepl buffer with the frame it is openned with instead of it
  ;; being considered unassociated from setting it to the background..
  (r2->defhook r2/register-mrepl-frame
    "Associates sly-mrepl buffer  with the curent frame."
    ((beframe-assume-buffers-matching-regexp-all-frames "\\*sly-mrepl"))
    :hook sly-mrepl-mode-hook)

  ;; Sly completions
  (r2->defhook r2/sly-completions
    "Set flex to completion styles."
    ((setq-local completion-styles '(basic flex)))
    :hook sly-mode-hook)

  ;; See: https://joaotavora.github.io/sly/#Loading-Slynk-faster
  (r2->defhook r2/sly-auto-connect
    "Auto-connect to SLY if not already connected."
    ((interactive)
     (unless (sly-connected-p)
       (save-excursion (sly))))
    :hook lisp-mode-hook)

  (r2->defhook r2/sly-refresh-fontification
    "Refresh fontification in Lisp buffers once SLY connects."
    ((run-at-time
      0 nil
      (lambda ()
        (dolist (buf (buffer-list))
          (with-current-buffer buf
            (when (eq major-mode 'lisp-mode)
              (font-lock-flush)
              (font-lock-ensure)))))))
    :hook sly-connected-hook))



;; OTLS - Other Than Lisp Support

;; JSL
(use-package jsl-mode
  :vc (:url "https://github.com/logoraz/jsl-mode.git" :rev :newest))

;; Nix
(use-package nix-mode
  :vc (:url "https://github.com/NixOS/nix-mode.git" :rev :newest)
  :mode "\\.nix\\'")

;; VBA
(use-package vba-mode
  :vc (:url "https://github.com/logoraz/vba-mode.git" :rev :newest))




(provide 'r2-clide)
;;; r2-clide.el ends here
