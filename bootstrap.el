;;; bootstrap.el --- Bootstrap Emacs Config -*- lexical-binding: t -*-

;;; Commentary:
;;;
;;; Run `emacs --script bootstrap.el'


;;; Code:

(defun r2/create-symlink (target link)
  "Create a symlink, LINK of TARGET."
  (let ((target (expand-file-name target))
        (link (expand-file-name link)))
    (when (file-exists-p link)
      (delete-file link))
    (make-symbolic-link target link)))


;;; Backup System for configs
(defun r2/archive-old-configs ()
  "Rename old Emacs config files and directories to avoid conflicts."
  (let ((old-files '("~/.emacs" "~/.emacs.el"))
        (old-dir "~/.emacs.d")
        (timestamp (format-time-string "%Y%m%d-%H%M%S")))

    ;; Handle old config files
    (dolist (file old-files)
      (when (file-exists-p file)
        (let ((backup (format "%s.old-%s" file timestamp)))
          (rename-file file backup)
          (message "Renamed %s to %s" file backup))))

    ;; Handle .emacs.d directory
    (when (file-exists-p old-dir)
      (let ((backup (format "%s.old-%s" old-dir timestamp)))
        (rename-file old-dir backup)
        (message "Renamed %s to %s" old-dir backup)))))


;;; Deploy
(defun r2/deploy-config ()
  "Deploy r2Emacs config."
  (message "Starting r2Emacs configuration bootstrap...")
  (r2/archive-old-configs)
  (r2/create-symlink "~/Work/r2emacs" "~/.config/emacs")
  (message "Bootstrap complete!"))

(defun r2/deploy-sbclrc ()
  "Copy reference sbclrc, SOURCE, to DESTINATION."
  (pcase system-type
    ('windows-nt (r2/create-symlink
                  (expand-file-name "dot-sbclrc-windows.lisp"
                                    "~/.emacs.d/files/common-lisp")
                  (expand-file-name ".sbclrc" "~")))
    ('gnu/linux (r2/create-symlink
                 (expand-file-name "dot-sbclrc-linux.lisp"
                                   "~/.config/emacs/files/common-lisp")
                 (expand-file-name ".sbclrc" "~"))))
  (message "SBCLRC deployed"))

(defun r2/deploy-eclrc ()
  "Copy reference eclrc, SOURCE, to DESTINATION."
  (pcase system-type
    ('gnu/linux (r2/create-symlink
                 (expand-file-name "dot-eclrc-linux.lisp"
                                   "~/.config/emacs/files/common-lisp")
                 (expand-file-name ".eclrc" "~")))
    ('windows-nt (r2/create-symlink
                  (expand-file-name "dot-eclrc-windows.lisp"
                                    "~/.emacs.d/files/common-lisp")
                  (expand-file-name ".eclrc" "~"))))
  (message "ECLRC deployed"))

;; (if (eq system-type 'gnu/linux) (r2/deploy-config))

(when (eq system-type 'gnu/linux)
  (message "Deploying r2Emacs Bootstrap Common Lisp Environment...")
  (r2/deploy-sbclrc)
  (r2/deploy-eclrc))





(provide 'bootstrap)
;;; bootstrap.el ends here
