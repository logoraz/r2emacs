;;; r2-dired.el --- Advanced Configuration for Dired -*- lexical-binding: t -*-

;;; Commentary:
;;;


;;; Code:



;;; Main Dired setup

(use-package dired
  :ensure nil
  :defer t
  :bind (:map dired-mode-map
              ("r" . r2/dired-find-file-other-window))
  :config
  (defun r2/dired-find-file-other-window ()
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
  ;; :hook (dired-mode . dired-omit-mode)
  :custom (dired-x-hands-off-my-keys nil)
  :config
  ;; (setq dired-omit-files   ;; hide .dot files when in dired-omit-mode
  ;;     (concat dired-omit-files "\\|^\\..+$"))
  )

(use-package image-dired
  :ensure nil
  :defer t
  :custom ((image-dired-thumb-size 256)
           (image-dired-thumbnail-storage 'standard-large)))




;;; DIRED Extensions --> Prettify & Mutimedia Support

(use-package all-the-icons-dired
  :ensure t
  :defer t)

(use-package dired-preview
  :ensure t
  :defer t
  :after (dired image-dired)
  ;; https://protesilaos.com/emacs/dired-preview
  :hook ((dired-preview-mode . dired-hide-details-mode)
         (dired-preview-mode . all-the-icons-dired-mode)
         (dired-preview-mode . ready-player-mode))
  :bind (:map dired-mode-map
              ("C-c C-p" . dired-preview-mode)
              ("C-c C-k" . ready-player-mode))
  :config
  (setq dired-preview-ignored-extensions-regexp
        (concat "\\."
                "\\(gz\\|"
                "zst\\|"
                "tar\\|"
                "xz\\|"
                "rar\\|"
                "zip\\|"
                "iso\\|"
                "epub"
                "\\)")))

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
