;;; r2-vibe.el --- Vibe Coding with LLM Agents -*- lexical-binding: t -*-

;;; Commentary:


;;; Code:

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

  :preface
  (defun r2/send-region-or-buffer ()
    "Send current active region or full buffer content to gptel."
    (interactive)
    (let ((content
           (if (use-region-p)
               (buffer-substring-no-properties (region-beginning)
                                               (region-end))
             (buffer-string))))
      (gptel-send content)))

  ;; Unified Single Source of Truth for ALL Models & Providers
  ;; Tuple Layout: ("Name" . (Backend-Symbol . (Provider-Type . "model-str")))
  (defun r2/llm-models-alist ()
    "Master map linking menu names to backend configurations."
    '(("Gemini Flash (Free)" .
       (r2/gptel-gemini . (gemini . "gemini-3.6-flash")))
      ("Claude Sonnet" .
       (r2/gptel-anthropic . (anthropic . "claude-3-5-sonnet")))))

  (defun r2/select-llm-agent ()
    "Prompt for and set the active LLM backend and model."
    (interactive)
    (let* ((choices (r2/llm-models-alist))
           (selection (completing-read "Select LLM Agent: "
                                       (mapcar #'car choices)))
           (target-pair (cdr (assoc selection choices))))
      (when target-pair
        (let ((backend-sym (car target-pair))
              (model-str (cddr target-pair)))
          (setq gptel-backend (symbol-value backend-sym)
                gptel-model model-str)
          (message "Switched workspace agent to: %s (%s)"
                   selection gptel-model)))))

  (defun r2/fill-gptel-buffer (&rest _)
    "Force-fill the current `gptel` buffer after a response."
    (interactive)
    (let ((fill-column 80))
      (fill-region (point-min) (point-max))))

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
      (when (fboundp constructor)
        (set backend-sym
             (funcall constructor display-name
                      :key api-key
                      :stream t
                      :models models)))))

  :config
  ;; Safely require your git-ignored secrets module.
  (require 'r2-secrets nil 'noerror)

  ;; 1. Generalized Dynamic Initialization Loop
  (let ((processed nil)
        (secrets-bound (boundp 'r2/llm-api-keys)))
    (dolist (item (r2/llm-models-alist))
      (let* ((config (cdr item))
             (backend-sym (car config))
             (provider-type (cadr config))
             (keyword-tgt (intern (concat ":" (symbol-name backend-sym))))
             ;; Extracted via optimal 'cdr' from your proper alist pair
             (api-key (and secrets-bound
                           (cdr (assoc keyword-tgt r2/llm-api-keys)))))
        (when (and api-key (not (member backend-sym processed)))
          (let ((models (let (accum)
                          (dolist (m (r2/llm-models-alist) accum)
                            (when (eq (car (cdr m)) backend-sym)
                              (push (cddr (cdr m)) accum))))))
            (r2/gptel-init-backend backend-sym
                                   provider-type
                                   "AI-Backend"
                                   models
                                   api-key)
            (push backend-sym processed))))))

  ;; 2. Establish Default Boot Targets Using First Item in Alist (key . value)
  ;;    where key is variable name defined above
  (let* ((first-item (car (r2/llm-models-alist)))
         (config (cdr first-item))
         (backend-sym (car config))
         (model-str (cddr config)))
    (when (and backend-sym (symbol-value backend-sym))
      (setq gptel-backend (symbol-value backend-sym)
            gptel-model   model-str))))





(provide 'r2-vibe)
;;; r2-vibe.el ends here
