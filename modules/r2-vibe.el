;;; r2-vibe.el --- Vibe Coding with LLMA -*- lexical-binding: t -*-

;;; Commentary:


;;; Code:

;;
;; Helper packages to prettify work with gptel...
;;
(use-package visual-fill-column
  :ensure t
  :hook (visual-line-mode . visual-fill-column-mode)
  :custom
  (visual-fill-column-width 81)
  (visual-fill-column-enable-sensible-window-split t))

;; Optional: Better indentation on wrapped lines
(use-package adaptive-wrap
  :ensure t
  :hook (visual-line-mode . adaptive-wrap-prefix-mode))



;; gptel for chat using Copilot
(use-package gptel
  :ensure t
  :bind (("C-c g" . gptel-send)
         ("C-c G" . gptel-menu)
         ("C-c m" . r2/gptel-select-model)
         ("C-c r" . r2/gptel-send-region-or-buffer))
  :hook ((gptel-mode . visual-line-mode))
  :config
  (setq gptel-model 'claude-sonnet-4-20250514
        gptel-backend (gptel-make-gh-copilot "Copilot"))

  (defun r2/gptel-send-region-or-buffer ()
    "Send the current region or entire buffer content to gptel."
    (interactive)
    (let ((content
           (if (use-region-p)
               (buffer-substring-no-properties (region-beginning) (region-end))
             (buffer-string))))
      (gptel-send content)))

  ;; On-the-fly model switching
  (defun r2/gptel-select-model ()
    "Prompt for and set the current model for gptel."
    (interactive)
    (setq gptel-model (completing-read
                       "Select model: "
                       '("claude-sonnet-4-20250514" "gpt-4" "gpt-3.5"))))

  (defun r2/fill-gptel-buffer (&rest _)
    "Force-fill the current `gptel` buffer after a response.

Use with :hook ((gptel-post-response . r2/fill-gptel-buffer))
"
    (interactive)
    (let ((fill-column 80)) ;; dynamic scope to the rescue!
      (fill-region (point-min) (point-max)))))

;; GitHub Copilot for inline completions
(use-package copilot
  :disable
  :if (eq system-type 'gnu/linux)
  :vc (:url "https://github.com/copilot-emacs/copilot.el"
            :rev :newest
            :branch "main")
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . copilot-accept-completion)
              ("TAB" . copilot-accept-completion)))





(provide 'r2-vibe)
;;; r2-vibe.el ends here
