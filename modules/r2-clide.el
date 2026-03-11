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
  :hook ((scheme-mode lisp-mode emacs-lisp-mode)
         . display-line-numbers-mode))

(use-package display-fill-column-indicator
  :ensure nil
  ;; TODO: Customize theme color for this element -> via ':config' keyword
  :diminish
  ;; Only activate for lisp-mode
  :hook ((prog-mode org-mode) . display-fill-column-indicator-mode)
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
  :hook ((eval-expression-minibuffer-setup
          lisp-interaction-mode
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
  ;; better than using flycheck-global-modes as it defers loading
  ;; optimizing Emacs startup!!
  ;; flycheck freezes emacs when enabled in lisp-mode and using reader
  ;; macros (e.g. #+nil)
  :hook ((emacs-lisp-mode) . flycheck-mode)
  :custom
  (flycheck-checker-error-threshold 2000 "Increase error threshold."))

(use-package colorful-mode
  :ensure t
  :diminish
  :hook (prog-mode . colorful-mode)
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



;;; Common Lisp IDE
(use-package lisp-comment-dwim
  :disable
  :vc (:url "https://github.com/dotemacs/lisp-comment-dwim.el" :branch "main")
  :custom (lisp-comment-dwim-comment-macro "#+nil")
  :config
  (lisp-comment-dwim-setup-keybindings))

(use-package sly
  :ensure t
  ;; Enable sly IDE for Common Lisp
  :hook ((lisp-mode . sly-editing-mode)
         (lisp-mode . r2/sly-auto-connect)
         ;; (sly-mode  . r2/sly-completions)
         (sly-mrepl-mode  . r2/register-mrepl-frame))
  :custom
  (sly-default-lisp 'sbcl
                    "Set default lisp to Steel Bank Common Lisp.")
  :config
  ;; Disable Sylvester the cat
  (setq sly-mrepl-pop-sylvester nil)

  ;; Provide proper syntax highlighting for `defsystem'
  (font-lock-add-keywords
   'lisp-mode
   '(("(\\s-*\\(defsystem\\)\\>" 1 font-lock-keyword-face append)))

  ;; Invoke SLY with a negative prefix argument, M-- M-x sly,
  ;; and you can select a program from that list.
  (setq sly-lisp-implementations
        '((clasp ("clasp") :coding-system utf-8-unix)
          (sbcl  ("sbcl") :coding-system utf-8-unix)
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
  (defun r2/register-mrepl-frame ()
    "Associates sly-mrepl buffer  with the curent frame."
    (beframe-assume-buffers-matching-regexp-all-frames "\\*sly-mrepl"))

  ;; Sly completions
  (defun r2/sly-completions ()
    "Set flex to completion styles."
    (setq-local completion-styles '(sly--external-completion basic flex))
    (sly-symbol-completion-mode -1))

  ;; See: https://joaotavora.github.io/sly/#Loading-Slynk-faster
  (defun r2/sly-auto-connect ()
    (interactive)
    (unless (sly-connected-p)
      (save-excursion (sly)))))



;;; Guile Scheme IDE

;; Set default to guile.
(r2/setopts scheme-program-name "guile")

;; `emacs-guix' dependencies:
;; emacs-bui, emacs-dash, emacs-edit-indirect,
;; emacs-geiser, emacs-geiser-guile, emacs-magit-popup
;; module-import-compiled
(use-package guix
  :disabled)

(use-package arei
  :disabled
  :after (sesman)
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


;; OTLS - Other Than Lisp Support

;; Nix
(use-package nix-mode
  :vc (:url "https://github.com/NixOS/nix-mode.git" :rev :newest)
  :mode "\\.nix\\'")

;; VBA
(use-package vba-mode
  :vc (:url "https://github.com/ayanyan/vba-mode.git" :rev :newest)
  :mode ("\\.\\(vba\\|bas\\|cls\\|frm\\)\\'" . vba-mode)
  :hook ((vba-mode . font-lock-mode)
         (vba-mode . r2/vba-config))
  :config

  ;; Hacks to fix where vba-mode gets it wrong.
  ;; TOTO:--> fork repo and correct therein
  (defun r2/vba-config ()
    "Set configuration for vba"
    (setq-local tab-width 4
                indent-tabs-mode nil)
    (setq vba-mode-indent 4))

  ;; Add highlighting for the keyword "Const"
  (font-lock-add-keywords
   'vba-mode
   '(("\\<Const\\>" . font-lock-constant-face)

     ;; Compiler metadata
     ("\\<Attribute\\>" . font-lock-preprocessor-face)

     ;; Runtime builtin
     ("\\<DoEvents\\>" . font-lock-builtin-face)

     ;; Declaration/structural keywords (match Dim)
     ("\\<WithEvents\\>" . font-lock-type-face)
     ("\\<Implements\\>" . font-lock-type-face)
     ("\\<Enum\\>"       . font-lock-type-face)
     ("\\<Type\\>"       . font-lock-type-face)
     ("\\<ReDim\\>"      . font-lock-type-face)

     ;; Parameter modifiers
     ("\\<Optional\\>" . font-lock-keyword-face)
     ("\\<ByRef\\>"    . font-lock-keyword-face)
     ("\\<ByVal\\>"    . font-lock-keyword-face)

     ;; Misc keywords
     ("\\<Erase\\>"   . font-lock-keyword-face)
     ("\\<Static\\>"  . font-lock-keyword-face)
     ("\\<Declare\\>" . font-lock-keyword-face)
     ("\\<PtrSafe\\>" . font-lock-keyword-face)
     ("\\<Lib\\>"     . font-lock-keyword-face)
     ("\\<Alias\\>"   . font-lock-keyword-face)

     ;; Property blocks
     ("\\<Property[ \t]+Get\\>" . font-lock-keyword-face)
     ("\\<Property[ \t]+Let\\>" . font-lock-keyword-face)
     ("\\<Property[ \t]+Set\\>" . font-lock-keyword-face)))

  ;;Prevent keyword auto-capitalization inside comments and strings
  (advice-add
   'expand-abbrev :around
   (lambda (orig-fun &rest args)
     (unless (nth 8 (syntax-ppss)) ;; inside comment or string?
       (apply orig-fun args)))))




(provide 'r2-clide)
;;; r2-clide.el ends here
