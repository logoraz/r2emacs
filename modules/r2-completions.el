;;; r2-completions.el --- Completions Framework -*- lexical-binding: t -*-

;;; Commentary:


;;; Code:




(use-package orderless
  ;;https://github.com/oantolin/orderless
  :ensure t
  :custom
  ;; Need to verify this doesn't conflict with mct mode
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :ensure t
  :diminish marginalia-mode
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle))
  :config
  (marginalia-mode))

(use-package mct
  :ensure t
  :diminish mct-mode
  :demand t
  :bind (:map minibuffer-local-filename-completion-map
              ("DEL" . r2/backward-updir)
              :map minibuffer-local-completion-map
              ("SPC" . nil)
              ("?"   . nil))
  :custom
  (mct-completion-window-size (cons 'mct-frame-height-third 1))
  (mct-remove-shadowed-file-names t)
  (mct-hide-completion-mode-line t)
  (mct-live-completion t)
  (mct-minimum-input 3)
  (mct-live-update-delay 0.6)
  (mct-persist-dynamic-completion t)
  (mct-completion-passlist nil)
  (mct-completion-blocklist nil)
  (completion-styles '(basic substring initials flex partial-completion orderless))
  (completion-category-overrides '((file
                                    (styles . (basic
                                               partial-completion
                                               orderless)))))
  :config
  ;; Prot's adaptation of `icomplete-fido-backward-updir'.
  (defun r2/backward-updir ()
    "Delete char before point or go up a directory."
    (interactive nil mct-mode)
    (cond
     ((and (eq (char-before) ?/)
           (eq (mct--completion-category) 'file))
      (when (string-equal (minibuffer-contents) "~/")
        (delete-minibuffer-contents)
        (insert (expand-file-name "~/"))
        (goto-char (line-end-position)))
      (save-excursion
        (goto-char (1- (point)))
        (when (search-backward "/" (minibuffer-prompt-end) t)
          (delete-region (1+ (point)) (point-max)))))
     (t (call-interactively 'backward-delete-char))))

  (mct-mode))

(use-package corfu
  :ensure t
  :diminish corfu-mode
  :hook ((prog-mode . corfu-mode))
  :custom
  (corfu-cycle t "Enable corfu cycling...")
  (corfu-auto t)
  (corfu-separator ?\s)
  (corfu-quit-at-boundary 'separator)
  (corfu-quit-no-match t)
  (corfu-preview-current nil)
  (corfu-preselect 'prompt)
  (corfu-on-exact-match nil)
  (corfu-scroll-margin 5)
  :custom-face
  (corfu-default ((t (:background "#2e3440" :foreground "#d8dee9"))))
  (corfu-current ((t (:background "#5e81ac" :foreground "#eceff4"))))
  :config
  (when (eq system-type 'windows-nt)
    ;; Need to reapply here due to load order in windows
    (custom-set-faces
     '(corfu-default ((t (:background "#2e3440" :foreground "#d8dee9"))))
     '(corfu-current ((t (:background "#5e81ac" :foreground "#eceff4"))))))
  ;; Needed for customization/control of other variables that interfere with corfu
  (setq text-mode-ispell-word-completion nil
        read-extended-command-predicate #'command-completion-default-include-p
        tab-always-indent 'complete
        completion-cycle-threshold 3))





(provide 'r2-completions)
;;; r2-completions.el ends here
