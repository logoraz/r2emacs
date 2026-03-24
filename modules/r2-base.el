;;; r2-base.el --- Base Config/Defaults -*- lexical-binding: t -*-

;;; Commentary:
;;; Configuration of Emacs Core libraries.
;;; Default "Essential" Settings & Packages I use daily...
;;; See `comp.el' for review of Andrea Corallo's legendary world on native
;;; compilation (aka `eln' files).
;;; Research difference between emacs-next-tree-sitter & emacs-next-pgtk
;;; See https://www.emacswiki.org/emacs/PageBreaks
;;;  ‘forward-page’ (`C-x ]’ or `C-]’),
;;;  ‘backward-page’ (`C-x [’ or `C-[’), and `narrow-to-page' (‘C-x n p’).


;;; Code:



;;; File Settings: Auto Save, Backups, History, Bookmark, Recent Files,
;;; & Minibuffer control

;;; Open files with sudo
(defun r2/sudo-edit-current-file ()
  "Edit the current file using sudo."
  (interactive)
  (unless buffer-file-name
    (user-error "Current buffer is not visiting a file"))
  (find-alternate-file (concat "/sudo::" buffer-file-name)))

(unless (eq system-type 'gnu/linix)
  (global-set-key (kbd "C-c s") #'r2/sudo-edit-current-file))

;;; Auto Save: Prefix for generating auto-save-list-file-name
;; see - `auto-save-list-file-name'
(setq auto-save-list-file-prefix (expand-file-name "auto-save/.saves-"
                                                   r2-var-directory))
;; Backups
(setq  backup-directory-alist
       `(("." . ,(expand-file-name "backup" r2-var-directory)))
       make-backup-files t
       vc-make-backup-files nil
       backup-by-copying t
       version-control t
       delete-old-versions t
       kept-old-versions 6
       kept-new-versions 9
       delete-by-moving-to-trash t)

;;; History
(use-package savehist
  :ensure nil
  :defer t
  :diminish savehist-mode
  :custom
  (savehist-save-minibuffer-history t)
  (savehist-file (expand-file-name "savehist.el" r2-var-directory))
  :config
  (setq history-length 500
        history-delete-duplicates t)
  (savehist-mode 1))

;; Bookmarks
(use-package bookmark
  :ensure nil
  :defer t
  :custom
  (bookmark-default-file (expand-file-name "bookmarks" r2-var-directory)))

;;; Recent Files
(use-package recentf
  :ensure nil
  :defer t
  ;; TODO: Optimize use-package configuration for this!
  :diminish recentf-mode
  :init
  (setq recentf-save-file (expand-file-name "recentf" r2-var-directory)
        recentf-max-menu-items 50)
  ;; (customize-set-variable 'recentf-exlcude)
  :config
  (r2/ignore-messages
    (recentf-mode)))

;;; Minibuffer acrobatics
(defun r2/switch-to-minibuffer ()
  "Switch to minibuffer window."
  (interactive)
  (if (active-minibuffer-window)
      (select-window (active-minibuffer-window))
    (error "Minibuffer is not active")))

(bind-key "C-c o" 'r2/switch-to-minibuffer)

;;; Info Files (Xtra)
(use-package info
  :ensure nil
  :defer t
  :init
  (make-directory (expand-file-name "info" r2-xdg-cache-home) t)
  :config
  (add-to-list 'Info-directory-list
               (expand-file-name "info" user-emacs-directory))
  (setopt Info-default-directory-list Info-directory-list))

;;; Enable Emacs server
(use-package server
  :ensure nil
  :hook (emacs-startup . r2/start-emacs-server)
  :config
  (defun r2/start-emacs-server ()
    "Hook function to start the Emacs Server."
    (interactive)
    ;; Set editor to use emacsclient
    (setenv "EDITOR" "emacsclient -c")
    (setenv "VISUAL" "emacsclient -c")

    (unless (server-running-p)
      (server-start))
    (message "Emacs Server started!!")))

(use-package project
  :ensure nil
  :custom
  (project-list-file
   (expand-file-name "projects" r2-var-directory)
   "Handled by no-littering, but here for a safeguard.")
  :config
  (setq project-vc-ignores '("*.elc" "*.eln")))


;;; External Modules

;;; Configure package PATH's
(use-package no-littering
  :ensure t)


;;; UI Configuration
;;; Fonts Ligatures, Icons, Modeline, Themes, Tabs
;;;

(use-package ligature
  ;; Fonts & Theme Configuration
  ;; Fira Code & Ligature Support
  ;; See: https://github.com/tonsky/FiraCode/wiki/Emacs-instructions#using-ligature
  ;; See: https://github.com/mickeynp/ligature.el
  :ensure t
  :after server
  :diminish ligature-mode
  :config
  (defvar font-height
    (let ((height
           (pcase system-type
             ('windows-nt 90)
             ('gnu/linux  100)
             (_           110))))
      height)
    "Set the font height based on system-type.")
  (defun r2/set-font-faces ()
    "Set font faces"
    (dolist
        (face
         `((default :font "Fira Code" :height ,font-height)
           (fixed-pitch :font "Fira Code" :height ,font-height)
           (variable-pitch :font "Iosevka Aile" :height ,font-height)))
      (r2/set-face-attribute (car face) (cdr face))))

  (if (server-running-p)
      (add-hook 'after-make-frame-functions
                (lambda (frame)
                  (with-selected-frame frame
                    (r2/set-font-faces))))
    (r2/set-font-faces))

  ;; Enable the "www" ligature in every possible major mode
  (ligature-set-ligatures 't '("www"))
  ;; Enable traditional ligature support in eww-mode, if the
  ;; `variable-pitch' face supports it
  (ligature-set-ligatures 'eww-mode '("ff" "fi" "ffi"))
  ;; Enable all Cascadia Code ligatures in programming modes
  (ligature-set-ligatures
   'prog-mode
   '("|||>" "<|||" "<==>" "<!--" "####" "~~>" "***" "||=" "||>"
     ":::" "::=" "=:=" "===" "==>" "=!=" "=>>" "=<<" "=/=" "!=="
     "!!." ">=>" ">>=" ">>>" ">>-" ">->" "->>" "-->" "---" "-<<"
     "<~~" "<~>" "<*>" "<||" "<|>" "<$>" "<==" "<=>" "<=<" "<->"
     "<--" "<-<" "<<=" "<<-" "<<<" "<+>" "</>" "###" "#_(" "..<"
     "..." "+++" "/==" "///" "_|_" "www" "&&" "^=" "~~" "~@" "~="
     "~>" "~-" "**" "*>" "*/" "||" "|}" "|]" "|=" "|>" "|-" "{|"
     "[|" "]#" "::" ":=" ":>" ":<" "$>" "==" "=>" "!=" "!!" ">:"
     ">=" ">>" ">-" "-~" "-|" "->" "--" "-<" "<~" "<*" "<|" "<:"
     "<$" "<=" "<>" "<-" "<<" "<+" "</" "#{" "#[" "#:" "#=" "#!"
     "##" "#(" "#?" "#_" "%%" ".=" ".-" ".." ".?" "+>" "++" "?:"
     "?=" "?." "??" ";;" "/*" "/=" "/>" "//" "__" "~~" "(*" "*)"
     "\\\\" "://" ";;;" ";;;;" "!!!" "!!!!"))
  ;; Enables ligature checks globally in all buffers. You can also do it
  ;; per mode with `ligature-mode'.
  (global-ligature-mode t))


;; Load in local copy of nord theme - to develop and customize...
;; (add-to-list 'custom-theme-load-path (expand-file-name "~/.config/emacs/themes/"))
;; (load-theme 'kanagawa t)
;; https://github.com/tinted-theming/base16-emacs
(use-package all-the-icons
  :ensure t
  :defer t)

(use-package nerd-icons
  :ensure t
  :defer t
  :config
  ;; changes for newer version of nerd-icons
  (add-to-list
   'nerd-icons-extension-icon-alist
   '("lisp" nerd-icons-mdicon "nf-md-yin_yang" :face nerd-icons-silver))

  (add-to-list
   'nerd-icons-extension-icon-alist
   '("asd" nerd-icons-mdicon "nf-md-yin_yang" :face nerd-icons-silver))

  (add-to-list
   'nerd-icons-mode-icon-alist
   '(lisp-mode nerd-icons-mdicon "nf-md-yin_yang" :face nerd-icons-silver))

  ;; Set "lisp" extensions/lisp-mode to Common Lisp Icon, instead of Scheme Icon...
  (add-to-list
   'nerd-icons-extension-icon-alist
   '("lisp" nerd-icons-sucicon "nf-custom-common_lisp" :face nerd-icons-silver))

  (add-to-list
   'nerd-icons-extension-icon-alist
   '("asd" nerd-icons-sucicon "nf-custom-common_lisp" :face nerd-icons-silver))

  (add-to-list
   'nerd-icons-mode-icon-alist
   '(lisp-mode nerd-icons-sucicon "nf-custom-common_lisp" :face nerd-icons-silver)))

(use-package doom-modeline
  :ensure t
  :defer t
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-height 32)
  (doom-modeline-buffer-encoding nil)
  ;; (doom-modeline-buffer-file-name-style 'file-name)
  :config
  (line-number-mode)
  (column-number-mode))

(use-package doom-themes
  :ensure t
  :bind ("C-c d" . #'neotree)
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled

  ;; (load-theme 'doom-one :no-confirm)
  (load-theme 'doom-tomorrow-night :no-confirm)

  (defun r2/apply-theme (frame)
    "Apply my preferred theme to a new frame."
    (select-frame frame)
    (load-theme 'doom-tomorrow-night :no-confirm))

  ;; Needed to apply theme to new frames (and for emacs clients)
  (add-hook 'after-make-frame-functions
            'r2/apply-theme)

  ;; Enable custom neotree theme (nerd-icons must be installed!)
  (doom-themes-neotree-config)
  (setq doom-themes-neotree-file-icons t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)

  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

(use-package dashboard
  :ensure t
  :config
  (setq dashboard-icon-type 'nerd-icons
        dashboard-set-heading-icons t
        dashboard-set-file-icons t
        dashboard-center-content t
        dashboard-image-banner-max-height 200
        dashboard-startup-banner (expand-file-name "assets/cl-logoraz.svg"
                                                   r2-xdg-config-home)
        dashboard-projects-backend 'project-el
        dashboard-items '((recents  . 5)
                          (bookmarks . 5)
                          (projects  . 5))
        initial-buffer-choice (lambda () (get-buffer "*dashboard*")))
  (dashboard-setup-startup-hook))


;;; Tabs (optional)
(use-package tab-bar
  :disabled                             ; Not currently using tab-bar
  :ensure t
  :custom
  (tab-bar-show 1))



;;; Window Management Configuration

;; Window configuration presets
(defun r2/general-win-layout ()
  "Scaffold preferred general window layout."
  (interactive)
  (switch-to-buffer "*scratch*")
  (split-window-horizontally)
  (other-window 1)
  (split-window-vertically))

(defun r2/calendar-win-layout ()
  "Scaffold org calendar window layout."
  (interactive)
  (calendar)
  (other-window 1)
  (split-window-horizontally))

;; Window layout persistence
;; #:TODO/250910 - Create this as a stack (alist/plist) to save multiple
;; window instances and pop to the desired layout based on workspace...
;; Also want to keep this current option available, i.e. saving any custom
;; window layout and restoraction on demand...
;; Instead of a stack, I can take the functional programming approach as saving
;; the layout as a closure --> see my functional calculator gcal for reference.
(defvar r2--current-window-layout nil
  "Persistant variable holding window layout.")

(defun r2/save-current-windows ()
  "Save current window layout"
  (interactive)
  ;; #:TODO/250910 push current window configuration and workspace to stack
  (setq r2--current-window-layout (current-window-configuration)))

(defun r2/restore-last-windows ()
  "Restore window layout to last saved"
  (interactive)
  ;; #:TODO/250910 set based workspace
  (set-window-configuration r2--current-window-layout))



;;; Alternative Frame/Window Management & Notifications

(use-package beframe
  ;; Use beframe to handle desktops
  :ensure t
  :defer t
  :diminish beframe-mode
  :bind (("C-c b"   . beframe-transient)
         ("C-c f o" . make-frame-command)
         ("C-c f e" . delete-frame))
  :hook ((Buffer-menu-mode . r2/buffer-menu-colorize))
  :custom
  (beframe-global-buffers
   '("*scratch*" "*Messages*" "*Completions*" "*Backtrace*" "*info*"
     "*Buffer List*" "*Async-native-compile-log*" "*dashboard*"))
  :init (beframe-mode 1)
  :config
  (setq beframe-create-frame-scratch-buffer nil)

  (add-to-list 'display-buffer-alist
               '("*Buffer List*" . (display-buffer-same-window)))

(defvar r2--beframe-colors
    '("#5e81ac" "#81a1c1" "#88c0d0" "#8fbcbb")
    "List of colors for different beframes.")

(defvar r2--global-buffer-color "#b48ead"
  "Color for global buffers in buffer menu.")

(defvar r2--unassociated-buffer-color "#4c566a"
  "Color for buffers not associated with any frame.")

  (defun r2/beframe-buffer-color (buffer)
    "Return color for BUFFER based on its beframe association.
Returns specified color  for global buffers, frame-specific color otherwise."
    (when (bound-and-true-p beframe-mode)
      ;; Check if buffer is a global buffer
      (if (member (buffer-name buffer) beframe-global-buffers)
          r2--global-buffer-color
        ;; Otherwise find frame-specific color
        (let* ((frames (frame-list))
               (frame-index
                (cl-position-if
                 (lambda (frame)
                   (with-selected-frame frame
                     (memq buffer (beframe-buffer-list frame))))
                 frames)))
          (if frame-index
              (nth (mod frame-index (length r2--beframe-colors))
                   r2--beframe-colors)
            ;; Not associated with any frame
            r2--unassociated-buffer-color)))))

  (defun r2/buffer-menu-colorize ()
    "Colorize buffer menu entries by beframe."
    (when (eq major-mode 'Buffer-menu-mode)
      (save-excursion
        (goto-char (point-min))
        ;; (forward-line 2) ; Skip header lines
        (while (not (eobp))
          (when-let* ((buffer (tabulated-list-get-id))
                      (color (r2/beframe-buffer-color buffer)))
            (let ((inhibit-read-only t))
              (add-text-properties
               (line-beginning-position)
               (line-end-position)
               `(face (:foreground ,color :weight bold)))))
          (forward-line 1)))))

  ;; Add advice once globally, not per buffer
  (advice-add 'tabulated-list-print :after
              (lambda (&rest _)
                (when (eq major-mode 'Buffer-menu-mode)
                  (r2/buffer-menu-colorize)))))

(use-package ace-window
  :ensure t
  :defer t
  :bind ("M-o" . ace-window))





(provide 'r2-base)
;;; r2-base.el ends here
