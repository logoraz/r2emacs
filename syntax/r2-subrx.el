;;; r2-subrx.el --- Emacs Lisp Subroutines Xtra -*- lexical-binding: t -*-

;;; Commentary:


;;; Code:

(require 'rx)



;;; Helper Functions

;;;###autoload
(defun r2/run-in-background (command)
  "Run COMMAND with arguments in background provided last argument is '&'."
  (let ((command-parts (split-string command "[ ]+")))
    (apply #'call-process
           `(,(car command-parts) nil 0 nil ,@(cdr command-parts)))))

;;;###autoload
(defun r2/run-command-with-output (command &optional filter message)
  "Run COMMAND providing output, optionally formatted with FILTER and MESSAGE."
  (unless (stringp command)
    (error "Command provided must be a string: %s" command))
  (unless filter (setq filter ""))
  (if message (setq message (concat message " ")) (setq message ""))
  (let ((output (shell-command-to-string command))
        (regex filter)
        (result ""))
    (when (string-match regex output)
      (setq result (match-string 0 output)))
    (message (concat message "%s") result)))

;; Facile passing of lists to `set-face-attribute', use only in theme setting.
;;;###autoload
(defun r2/set-face-attribute (face spec)
  "Set attributes FACE from SPEC.
FACE is expected to be a symbol with the same faces
as accepted by `set-face-attribute'.
SPEC is expected to be a plist with the same key names
as accepted by `set-face-attribute'.
FRAME is always set to nil"
  (when (and face spec)
    (apply 'set-face-attribute face nil spec)))

;;;###autoload
(defun list->add-to-list (list list-var)
  "Add LIST of items to LIST-VAR via`add-to-list'."
  (dolist (item list)
    (add-to-list list-var item)))

;;;###autoload
(defun r2/ensure-directory-exists (directory)
  "Ensure DIRECTORY exists by creating it if it doesn't."
  (let ((target-directory (expand-file-name directory)))
    (unless (file-directory-p target-directory)
      ;; The 't' argument creates parent directories if they don't exist.
      (make-directory target-directory t))))


;;; Emacs Lisp Syntax Extensions (aka Macros)

;;;###autoload
(defmacro r2/use-modules (&rest modules)
  "Conveniency macro that requires multiple MODULES."
  (declare (debug setq))
  (unless (symbolp (car modules))
    (error "Attemping to require a non-symbol: %s" (car modules)))
  (let ((expr nil))
    (while modules
      (push `(require ',(car modules)) expr)
      (setq modules (cdr modules)))
    (macroexp-progn (nreverse expr))))


;;;###autoload
(defmacro r2/ignore-messages (&rest body)
  "Ignore messages for BODY of called functions."
  (declare (indent 0))
  `(let ((inhibit-message t)
         (message-log-max nil))
     (progn ,@body)))



;;; Customize/Enhance setopt --> r2/setopts

;;;###autoload
(defmacro r2/setopts (&rest pairs)
  "Set VARIABLE/VALUE/[COMMENT] PAIRS, and return the final VALUE.
This is like `setq', but is meant for user options instead of
plain variables.  This means that `setopts' will execute any
`custom-set' form associated with VARIABLE.

Note that `setopts' will emit a warning if the type of a VALUE
does not match the type of the corresponding VARIABLE as
declared by `defcustom'.  (VARIABLE will be assigned the value
even if it doesn't match the type.)

\(fn [VARIABLE VALUE]...)"
  (declare (debug setq))
  ;; (unless (evenp (length pairs))
  ;;   (error "PAIRS must have an even number of variable/value members"))
  (let ((expr nil))
    (while pairs
      (unless (symbolp (car pairs))
        (error "Attempting to set a non-symbol: %s" (car pairs)))
      (cond ((stringp (caddr pairs))
             (push `(r2/setopts--set ',(car pairs) ,(cadr pairs) ,(caddr pairs))
                   expr)
             (setq pairs (cdddr pairs)))
            (t ;; defaults to what setopt does...
             (push `(r2/setopts--set ',(car pairs) ,(cadr pairs)) expr)
             (setq pairs (cddr pairs)))))
    (macroexp-progn (nreverse expr))))

;;;###autoload
(defun r2/setopts--set (variable value &optional comment)
  "Set VALUE and optionally COMMENT to VARIABLE using `custom-set'."
  (custom-load-symbol variable)
  ;; Check that the type is correct.
  (unless comment (setq comment ""))
  (when-let* ((type (get variable 'custom-type)))
    (unless (widget-apply (widget-convert type) :match value)
      (warn "Value `%S' for variable `%s' does not match its type \"%s\""
            value variable type)))
  (put variable 'custom-check-value (list value))
  (funcall (or (get variable 'custom-set) #'set-default) variable value)
  (cond ((string= comment "")
 	 (put variable 'variable-comment nil)
 	 (put variable 'customized-variable-comment nil))
 	(comment
 	 (put variable 'variable-comment comment)
 	 (put variable 'customized-variable-comment comment))))





(provide 'r2-subrx)
;;; r2-subrx.el ends here
