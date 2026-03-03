;;; init.el --- Initialization File -*- lexical-binding: t -*-

;;; Commentary:
;;;
;;; r2EMACS framework/initializations
;;; |--> gnu/linux & windows-nt


;;; Code:



;;; r2emacs System-Wide Variables & Environment Establishment
;;;
;;; user-emacs-directory --> ~/.cache/emacs/ (early-init)

(defgroup r2emacs nil
  "Logoraz's r2Emacs (r^2 Emacs) Configuration."
  :tag "r2EMACS"
  :link '(url-link "")
  :group 'emacs)

(defcustom r2-var-directory
  (expand-file-name "var" user-emacs-directory)
  "Default var directory."
  :type 'string
  :group 'r2emacs)

(defcustom r2-etc-directory
  (expand-file-name "etc" user-emacs-directory)
  "Default etc directory."
  :type 'string
  :group 'r2emacs)

(defcustom r2-modules-directory (expand-file-name "modules" r2-xdg-config-home)
  "Default Emacs Modules directory."
  :type 'string
  :group 'r2emacs)

(defcustom r2-load-custom-file nil
  "When non-nil, load `custome.el' after user's config file, `config.el'."
  :type 'string
  :group 'r2emacs)

;; Create .cache directories to avoid prompts for their creation during initial
;; Emacs installation:
(make-directory r2-etc-directory t)
(make-directory r2-var-directory t)


;; Add the modules directory to the load path
(add-to-list 'load-path r2-modules-directory)

;; Set custom file to NOT be our init file.
(r2/setopts custom-file (expand-file-name "custom.el" r2-etc-directory)
            "Set preferred location of custom-file")

(when r2-load-custom-file
  (load custom-file t :no-error :no-message))



;;; Configure use-package

;; Enable `use-package' statistics - must be set before any `use-package' forms.
;; Run command M-x `use-package-report' to see
;; 1. How many packages were loaded,
;; 2. What stage of initialization they've reached,
;; 3. How much aggregate time they've spend (roughly).
(r2/use-modules use-package)

(r2/setopts use-package-compute-statistics t "Enable use-package statistics."
            use-package-catch-errors t "Catch errors during package installation.")



;;; Load Config Modules
(r2/use-modules r2-base
                r2-completions
                r2-dired
                r2-vcs
                r2-clide
                r2-org
                r2-vibe)




(provide 'init)
;;; init.el ends here
