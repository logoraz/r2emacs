;;; r2-vibe.el --- Vibe Coding with LLM Agents -*- lexical-binding: t -*-

;;; Commentary:


;;; Code:
(require 'cl-lib)

;; Helper packages to prettify work with gptel...
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



;; gptel for chat AI Clients

;; Generalized LLM Backend State Slots
(defvar r2/gptel-gemini nil "Storage slot for the Gemini backend.")
(defvar r2/gptel-anthropic nil "Storage slot for the Anthropic backend.")

(use-package gptel
  :ensure t
  :bind (("C-c g" . gptel-send)
         ("C-c G" . gptel-menu)
         ("C-c m" . r2/select-llm-agent)
         ("C-c r" . r2/send-region-or-buffer)
         ("C-c c" . r2/open-chat-buffer)
         ("C-c a" . gptel-add)
         ("C-c x" . r2/gptel-add-project-context))
  :hook ((gptel-mode . visual-line-mode)
         (gptel-post-response-functions . r2/fill-gptel-buffer))
  :custom
  (gptel-default-mode 'org-mode)
  :preface
  (defun r2/send-region-or-buffer ()
  "Send current active region or full buffer content to gptel."
  (interactive)
  (let ((content
         (if (use-region-p)
             (buffer-substring-no-properties (region-beginning) (region-end))
           (buffer-string))))
    (gptel-request content
      :callback (lambda (response info)
                  (if response
                      (message "gptel: %s" response)
                    (message "gptel request failed: %s"
                             (plist-get info :status)))))))

  ;; Unified Single Source of Truth for ALL Models & Providers
  (defun r2/llm-models-alist ()
    "Master map linking menu names to backend configurations."
    (list (list :name "Gemini Flash (Free)"
                :backend 'r2/gptel-gemini
                :type 'gemini
                :model "gemini-3.6-flash")
          (list :name "Claude Sonnet"
                :backend 'r2/gptel-anthropic
                :type 'anthropic
                :model "claude-3-5-sonnet")))

  (defun r2/select-llm-agent ()
    "Prompt for and set the active LLM backend and model."
    (interactive)
    (let* ((choices (r2/llm-models-alist))
           (names (mapcar (lambda (e) (plist-get e :name)) choices))
           (selection (completing-read "Select LLM Agent: " names nil t))
           (entry (cl-find selection choices
                           :key (lambda (e) (plist-get e :name))
                           :test #'string=)))
      (when entry
        (cl-destructuring-bind (&key backend model &allow-other-keys) entry
          (let ((backend-val (symbol-value backend)))
            (if backend-val
                (progn
                  (setq gptel-backend backend-val
                        gptel-model model)
                  (message "Switched workspace agent to: %s (%s)"
                           selection model))
              (user-error "No API key configured for %s -- backend not initialized"
                          selection)))))))

  (defun r2/fill-gptel-buffer (&rest _)
    "Force-fill the current `gptel' buffer after a response, skipping code blocks."
    (let ((fill-column 80))
      (save-excursion
        (goto-char (point-min))
        (let ((in-block nil))
          (while (not (eobp))
            (if (looking-at-p "```")
                (setq in-block (not in-block))
              (unless in-block
                (fill-region (line-beginning-position) (line-end-position))))
            (forward-line 1))))))

  (defun r2/open-chat-buffer ()
    "Create or switch to a dedicated AI chat workspace buffer."
    (interactive)
    (let ((buf (gptel "*AI Workspace*")))
      (pop-to-buffer buf)
      (with-current-buffer buf
        (visual-line-mode 1)
        (visual-fill-column-mode 1))))

  (defun r2/gptel-add-project-context ()
    "Find git root and append files recursively to context."
    (interactive)
    (if (fboundp 'vc-root-dir)
        (let ((root (vc-root-dir)))
          (if root
              (progn
                (gptel-add root)
                (message "Mapped project context root: %s" root))
            (error "No VC/Git root found for active buffer")))
      (error "vc-root-dir feature unavailable in this Emacs")))

  ;; Truly Functional Backend Factory
  (defun r2/gptel-init-backend (backend-sym type display-name models api-key)
    "Dynamically construct a gptel backend object using a funcall factory."
    (let ((constructor (intern (concat "gptel-make-" (symbol-name type)))))
      (if (fboundp constructor)
          (set backend-sym
               (funcall constructor display-name
                        :key api-key
                        :stream t
                        :models models))
        (warn "r2/gptel-init-backend: %s not available (unknown provider type %s)"
              constructor type))))

  :config
  ;; Safely require your git-ignored secrets module.
  (require 'r2-secrets nil 'noerror)

  ;; 1. Generalized Dynamic Initialization Loop
  (let ((processed nil)
        (secrets-bound (boundp 'r2/llm-api-keys)))
    (dolist (entry (r2/llm-models-alist))
      (cl-destructuring-bind (&key backend type &allow-other-keys) entry
        (let* ((keyword-tgt (intern (concat ":" (symbol-name backend))))
               (api-key (and secrets-bound
                             (cdr (assoc keyword-tgt r2/llm-api-keys)))))
          (when (and api-key (not (member backend processed)))
            (let ((models (cl-loop for e in (r2/llm-models-alist)
                                   when (eq (plist-get e :backend) backend)
                                   collect (plist-get e :model))))
              (r2/gptel-init-backend backend type "AI-Backend" models api-key)
              (push backend processed)))))))

  ;; 2. Establish Default Boot Targets Using First Item in Alist (key . value)
  ;;    where key is variable name defined above
  (when-let* ((first-entry (car (r2/llm-models-alist))))
    (cl-destructuring-bind (&key backend model &allow-other-keys) first-entry
      (when (and backend (symbol-value backend))
        (setq gptel-backend (symbol-value backend)
              gptel-model model)))))





(provide 'r2-vibe)
;;; r2-vibe.el ends here
