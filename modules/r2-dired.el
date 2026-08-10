;;; r2-dired.el --- Advanced Configuration for Dired -*- lexical-binding: t -*-

;;; Commentary:
;;;


;;; Code:



;;;
;;; File Manager Helpers (linux only)
;;;
(when (eq system-type 'gnu/linux)
  (defun r2/installed-desktop-files ()
    "List all installed .desktop file basenames."
    (let ((dirs '("~/.guix-home/profile/share/applications/"
                  "~/.local/share/applications/"
                  "/run/current-system/profile/share/applications/"
                  "~/.local/share/flatpak/exports/share/applications/")))
      (delete-dups
       (mapcan (lambda (d)
                 (when (file-directory-p (expand-file-name d))
                   (directory-files (expand-file-name d) nil "\\.desktop$")))
               dirs))))

  (defun r2/system-mime-types ()
    "Return list of MIME types from system mime database."
    (let ((path "/run/current-system/profile/share/mime/types"))
      (when (file-readable-p path)
        (with-temp-buffer
          (insert-file-contents path)
          (split-string (buffer-string) "\n" t)))))

  (defun r2/set-default-app (app mime)
    "Set APP as the default for MIME type."
    (interactive
     (list (completing-read "Desktop file: " (r2/installed-desktop-files))
           (completing-read "MIME type: "    (or (r2/system-mime-types)
                                                 (mailcap-mime-types)))))
    (call-process "xdg-mime" nil nil nil "default" app mime)
    (message "Set %s as default for %s" app mime))

  (defun r2/query-default-app (mime)
    "Show the default app for MIME type."
    (interactive
     (list (completing-read "MIME type: " (or (r2/system-mime-types)
                                              (mailcap-mime-types)))))
    (let ((app (string-trim
                (with-output-to-string
                  (with-current-buffer standard-output
                    (call-process "xdg-mime" nil t nil "query" "default" mime))))))
      (message (if (string-empty-p app)
                   "No default set for %s"
                 "Default for %s: %s")
               mime app)))

  (defun r2/list-default-apps ()
    "Display all current default app mappings from mimeapps.list."
    (interactive)
    (let ((file (expand-file-name "~/.config/mimeapps.list")))
      (if (not (file-readable-p file))
          (message "No mimeapps.list found")
        (with-current-buffer (get-buffer-create "*Default Apps*")
          (erase-buffer)
          (insert-file-contents file)
          ;; Keep only the [Default Applications] section
          (goto-char (point-min))
          (when (re-search-forward "^\\[Default Applications\\]" nil t)
            (forward-line)
            (delete-region (point-min) (point))
            (when (re-search-forward "^\\[" nil t)
              (beginning-of-line)
              (delete-region (point) (point-max))))
          (sort-lines nil (point-min) (point-max))
          (goto-char (point-min))
          (pop-to-buffer-same-window (current-buffer)))))))

;;;
;;; Main Dired setup
;;;
(use-package dired
  :ensure nil
  :defer t
  :commands (dired dired-jump)
  :bind (:map dired-mode-map
              ("r" . r2/dired-find-file-other-window)
              ("C-c t" . trashed))
  :custom
  (dired-listing-switches "-alh --group-directories-first")
  (dired-dwim-target t)                 ; guess target dir in split window
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (dired-auto-revert-buffer t)          ; refresh on revisit
  (delete-by-moving-to-trash t)
  (dired-kill-when-opening-new-dired-buffer t) ; single-buffer navigation
  :config
  (defun r2/dired-find-file-other-window ()
    "Open file at point in the tallest other window.
Falls back to `next-window' if multiple windows tie for tallest."
    (interactive)
    (let* ((file (dired-get-file-for-visit))
           (current (selected-window))
           (others (seq-filter (lambda (w) (not (eq w current)))
                               (window-list)))
           (tallest (seq-reduce (lambda (a b)
                                  (if (> (window-height b) (window-height a)) b a))
                                (cdr others) (car others)))
           (max-height (window-height tallest))
           (tallest-windows (seq-filter (lambda (w) (= (window-height w) max-height))
                                        others))
           (target (if (= (length tallest-windows) 1)
                       tallest
                     (next-window current 'no-minibuf))))
      (select-window target)
      (find-file file))))

(use-package dired-x
  :ensure nil
  :defer t
  ;; package provides dired-jump (C-x C-j)
  :after (dired)
  :bind (:map dired-mode-map
         ("E" . r2/dired-xdg-open))
  ;; :hook (dired-mode . dired-omit-mode)
  :custom (dired-x-hands-off-my-keys nil)
  :config
  ;; (setq dired-omit-files   ;; hide .dot files when in dired-omit-mode
  ;;     (concat dired-omit-files "\\|^\\..+$"))
  (let ((open-command
         (cond ((eq system-type 'darwin) "open")
               ((eq system-type 'windows-nt) "cmd.exe")
               (t "xdg-open"))))
    (defun r2/dired-xdg-open ()
      "Open marked files (or file at point) with the system handler."
      (interactive)
      (dolist (file (or (dired-get-marked-files)
                        (list (dired-get-file-for-visit))))
        (if (eq system-type 'windows-nt)
            (call-process open-command nil 0 nil
                          "/c" "start" "" (expand-file-name file))
          (call-process open-command nil 0 nil file))))

    (setq dired-guess-shell-alist-user
          (mapcar (lambda (exts)
                    (list (rx-to-string `(seq "." (or ,@exts) eos))
                          open-command))
                  '(("pdf" "epub" "mobi")
                    ("mp4" "mkv" "avi" "webm" "mov" "mp3" "flac" "ogg")
                    ("jpg" "jpeg" "png" "gif" "webp")
                    ("odt" "ods" "odp" "docx" "xlsx" "pptx")
                    ("htm" "html"))))))

(use-package image-dired
  :ensure nil
  :defer t
  :custom ((image-dired-thumb-size 256)
           (image-dired-thumbnail-storage 'standard-large)))

(use-package dired-aux
  :ensure nil
  :defer t
  :after dired
  :config
  ;; shell-command-guess-xdg (Emacs 30+) does
  ;; (replace-regexp-in-string " .*" "" (gethash "Exec" desktop))
  ;; with no nil-guard, so any matched .desktop file missing Exec=
  ;; crashes the whole !/& prompt. Wrap it so a bad entry is skipped
  ;; and named instead of erroring out entirely.
  (advice-add 'shell-command-guess-xdg :around
              (lambda (orig-fn commands files)
                (condition-case err
                    (funcall orig-fn commands files)
                  (wrong-type-argument
                   (message "shell-command-guess-xdg: skipping malformed .desktop entry (%s)"
                            (error-message-string err))
                   commands)))))



;;;
;;; DIRED Extensions --> Prettify & Mutimedia Support
;;;
(use-package all-the-icons-dired
  :ensure t
  :defer t)

(use-package dired-subtree
  :ensure t
  :after dired
  :bind (:map dired-mode-map
              ("<tab>" . dired-subtree-toggle)
              ("<backtab>" . dired-subtree-cycle)))

(use-package trashed
  :ensure t
  :defer t
  :commands (trashed)
  :custom
  (trashed-action-confirmer 'y-or-n-p)
  (trashed-use-header-line t)
  (trashed-sort-key '("Date deleted" . t))
  (trashed-date-format "%Y-%m-%d %H:%M:%S"))

(use-package dired-preview
  :ensure t
  :defer t
  :after dired
  ;; https://protesilaos.com/emacs/dired-preview
  :hook ((dired-preview-mode . dired-hide-details-mode)
         (dired-preview-mode . all-the-icons-dired-mode)
         (dired-preview-mode . ready-player-mode))
  :bind (:map dired-mode-map
              ("C-c C-p" . dired-preview-mode)
              ("C-c C-k" . ready-player-mode))
  :config
  (setq dired-preview-ignored-extensions-regexp
        (rx "." (or "gz" "zst" "tar" "xz" "rar" "zip" "iso" "epub"))))

(use-package ready-player
  :ensure (ready-player :pin melpa)
  :defer t
  ;; currently not available in guix
  ;; https://github.com/xenodium/ready-player
  ;; For some reason use-package is not able to successfuly retreive/load
  ;; this unless I manually install from list-packages
  ;; --> melpa
  :custom ((ready-player-autoplay nil)
           (ready-player-thumbnail-max-pixel-height 500)))





(provide 'r2-dired)
;;; r2-dired.el ends here
