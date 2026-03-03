;;; early-init.el --- Early Initialization File -*- lexical-binding: t -*-

;;; Commentary:
;;;
;;;


;;; Code:



;;;
;;; Bootstrap
;;;
(defvar r2-xdg-config-home
  (let ((config-dir
         (pcase system-type
           ('windows-nt (expand-file-name ".emacs.d" "~"))
           ('gnu/linux  (expand-file-name "emacs"    "~/.config"))
           (_           (expand-file-name "emacs"    "~/.config")))))
    (make-directory config-dir t)
    config-dir)
  "Emacs config path - creates directory if non-existent.")

(defvar r2-xdg-cache-home
  (let ((cache-dir
         (pcase system-type
           ('windows-nt (expand-file-name "emacs" "~/AppData/Local/cache"))
           ('gnu/linux  (expand-file-name "emacs" "~/.cache"))
           (_           (expand-file-name "emacs" "~/.cache")))))
    (make-directory cache-dir t)
    cache-dir)
  "Emacs cache path - creates directory if non-existent.")

(defvar r2-syntax-directory (expand-file-name "syntax" r2-xdg-config-home)
  "Emacs Syntax Extensions directory.")

(defvar r2-contrib-directory (expand-file-name "contrib" r2-xdg-config-home)
  "Emacs Contrib directory.")

;; Add language syntax expression to load path and use
(add-to-list 'load-path r2-syntax-directory)

;;; End Bootstrap

;;;
;;; Import moedules/packages
;;;
;; Always byte-compile these modules
(require 'r2-subrx)
(require 'r2-defhook)

(r2/use-modules package)

;; Set the `user-emacs-directory` to a writeable path
(setq-default user-emacs-directory r2-xdg-cache-home)



;;; Compilation Settings

(r2/setopts load-prefer-newer t
            "Always load newer native comp files"
            warning-suppress-log-types '((comp) (initialization))
            "Do not log warnings for compilation & initialization."
            warning-suppress-types '((initialization))
            "Do not display initialization warning types.")

(when (featurep 'native-compile)
  ;; Set native compilation asynchronous
  (setq-default native-comp-jit-compilation t)
  (r2/setopts native-comp-async-report-warnings-errors nil
              "Suppress native comp warnings")
  ;; Set the right directory to store the native compilation cache
  ;; NOTE: The method for setting the eln-cache directory depends on the emacs
  ;; version. This is disregarded here - assume I always use emacs latest,
  ;; i.e. version >= 29
  (when (fboundp 'startup-redirect-eln-cache)
    (startup-redirect-eln-cache
     (convert-standard-filename
      (expand-file-name "var/eln-cache/" user-emacs-directory)))))

(r2/setopts byte-compile-warnings nil "Disable byte compile warnings."
            warning-minimum-level :emergency "Only warn for emergencies."
            warning-minimum-log-level :emergency "Only warn for emergencies.")




;;; Performance Optimizations (Hacks)

;; Disable Dialogs/Echos/Bells & Startup Frames/Screens/Buffers
(setq-default init-file-user user-login-name)

(r2/setopts
 frame-inhibit-implied-resize 'force
 "Disable with force, critical to smooth startup."
 ring-bell-function 'ignore
 "No need for noisy notifications at startup, doom-modeline set it later."
 use-file-dialog nil
 "Disable file dialog."
 use-dialog-box nil
 "Disable dialog box."
 inhibit-startup-screen t
 "Disable splash screen."
 inhibit-startup-echo-area-message user-login-name
 "Disable startup echo area message."
 inhibit-startup-buffer-menu t
 "Disable startup buffer menu.")

;; Inhibit redisplay & messaging/dialog/echo to avoid flickering
;; loading/compiling upon iniial startup etc.
;; re-instantiate after init.el --> r2--lazarus-hookfn
(setq inhibit-redisplay t
      inhibit-message t)


;; Temporarily increase the GC threshold for faster startup
;; The default is 800 kilobytes.  Measured in bytes (* 8 100 1000).
;; Reset GC to default after start-up --> r2--lazarus-hookfn
(defvar r2-gc-cons-threshold gc-cons-threshold
  "Capture the default value of `gc-cons-threshold' for restoration.")
(setq gc-cons-threshold most-positive-fixnum)

;; Temporarily disable file-handling during startup.
(defvar r2-file-name-handler-alist file-name-handler-alist
  "Capture the default value of `file-name-handler-alist' for restoration.")
(setq file-name-handler-alist nil)

;; Reduce `vc-handled-backends' to only Git for I/O optimization.
(defvar r2-vc-handled-backends vc-handled-backends
  "Capture the default value of `vc-handled-backends' for restoration.")
(r2/setopts vc-handled-backends '(Git) "Set Git to be the only VC for now.")

;; Restore Emacs Defaults after initialization
(r2->defhook r2/lazarus--hookfn
  "Ressurect Emacs 'Defaults' hacked to optimize startup in `early-init'."

  (;;function body
   (setq file-name-handler-alist r2-file-name-handler-alist)
   (r2/setopts gc-cons-threshold r2-gc-cons-threshold
               "Restore GC Threshold to default.")

   ;; Restore messages & redisplay
   (setq inhibit-redisplay nil
         inhibit-message nil)

   (redisplay))

  :hook emacs-startup-hook
  :depth 90)



;;; Set Default UI/UX Configuration Variables

;; See Window Frame parameters
;; https://www.gnu.org/software/emacs/manual/html_node/elisp/
;; Window-Frame-Parameters.html
(set-frame-name "Home")

;; Customize Frame Title Construct
(setq-default frame-title-format
              '(multiple-frames
                "%b"
                ("" "%b @" user-login-name)))

(r2/setopts frame-resize-pixelwise t
            "Hopefully make resizing frame more smooth.")

(defvar r2--base-frame-alist
  (let ((frame-alist
         (pcase system-type
           ('windows-nt '((alpha . (95 . 90))
                          (undecorated . t) ;; prevents intial white
                          (use-frame-synchronization . extended)
                          (width . 140)
                          (height . 40)
                          (top . 0)
                          (left . 0)))
           ('gnu/linux  '((alpha-background . 85)
                          (fullscreen . maximized)
                          (use-frame-synchronization . extended)
                          (width . 140)
                          (height . 40)
                          (top . 0)
                          (left . 0)))
           (_           '((alpha-background . 85)
                          (fullscreen . maximized)
                          (use-frame-synchronization . extended)
                          (width . 140)
                          (height . 40)
                          (top . 0)
                          (left . 0))))))
    frame-alist)
  "Default frame parameters.")

(r2/setopts initial-frame-alist
            (append
             r2--base-frame-alist
             initial-frame-alist)
            "Customize the initial frame alist.")

(r2/setopts default-frame-alist
            (append
             r2--base-frame-alist
             default-frame-alist)
            "Customize the default frame alist.")

;; Set frame to 140x40 when unmaximized/restored
(r2->defhook r2/set-default-frame-size
  "Set frame to default to 140x40 when unmaximaized."
  (;; body
   (unless (or (frame-parameter frame 'parent-frame)
               (frame-parameter frame 'fullscreen))
     (set-frame-size frame 140 40)
     (set-frame-position frame 0 0)))
  :args (frame)
  :hook window-size-change-functions
  :disable? (eq system-type 'windows-nt))

;; Prevent white flash on startup
;; https://github.com/protesilaos/dotfiles/blob/master/emacs/.emacs.d/
;; early-init.el
(defun r2/avoid-initial-flash-of-light ()
  "Improve Emacs startup appearance, normalize with theme - no white."
  (setq mode-line-format nil)
  (if (eq system-type 'gnu/linux)
      (set-frame-parameter nil 'alpha-background 85)
    (set-frame-parameter nil 'alpha 0))
  (set-face-attribute 'default nil
                      :background "#2e3440" :foreground "#d8dee9")
  (set-face-attribute 'mode-line nil
                      :background "#2e3440" :foreground "#d8dee9"
                      :box 'unspecified)
  (set-face-attribute 'mode-line-inactive nil
                      :background "#233440" :foreground "#d8dee9"
                      :box 'unspecified))

;; Set Initial UI/UX Configuration for a clean startup experience
(r2/avoid-initial-flash-of-light)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(fringe-mode 1)
(pixel-scroll-precision-mode 1)

(r2->defhook r2/frame-special
  "Restores frames to desired values in a special way."

  (;;function body
   (with-selected-frame frame
     (set-frame-parameter nil 'alpha '(95 . 90))
     (set-frame-parameter nil 'undecorated nil)
     (set-frame-parameter nil 'width 140)
     (set-frame-parameter nil 'height 40)
     (toggle-frame-maximized))
   (setf (alist-get 'alpha default-frame-alist) '(95 . 90)))

  :disable? (eq system-type 'gnu/linux)
  :args (frame)
  :hook (after-make-frame-functions)
  :depth 91)


;;; Package Management System & Loading Preferences

(r2/setopts package-enable-at-startup t
            "Enable for things to work, greatly impacts startup time."
            package-user-dir (expand-file-name "elpa" r2-xdg-cache-home)
            "Relocate elpa to Emacs XDG_CACHE_HOME location.")

(add-to-list 'package-archives
             '("stable" . "https://stable.melpa.org/packages/") :append)

(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") :append)

(r2/setopts package-archive-priorities
            '(("melpa"  . 99)  ;; prefer bleading-edge package from melpa
              ("stable" . 80)  ;; use stable "released" versions next
              ("nongnu" . 70)  ;; use non-gnu package if not found in melpa's
              ("gnu"    . 0))  ;; if all else fails, get it from gnu
            "Set package archive preference: melpa > stable > nongnu > gnu")

;; Handle TLS issues (on Windows)
(when (eq system-type 'windows-nt)
  (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3"))

;; Initialize according to archive settings
(package-initialize)

;; Refresh package contents if needed
(unless package-archive-contents
  (package-refresh-contents))






(provide 'early-init)
;;; early-init.el ends here
