;;; r2-defhook.el --- Emacs Lisp Hygienic Hooks System -*- lexical-binding: t -*-

;;; Commentary:


;;; Code:
(require 'transducers)

;;;
;;; Registry & introspection
;;;
(defvar r2--defhook-registry (make-hash-table :test 'eq)
  "Map from defhook function symbol to its registration metadata.
Each value is a plist with keys :hooks, :depth, :local, :condition, :file.")

(defun r2--defhook-register (symbol hooks depth local condition file)
  "Internal: record that SYMBOL was registered on HOOKS.
Called from code emitted by `r2->defhook'."
  (puthash symbol
           (list :hooks hooks
                 :depth depth
                 :local local
                 :condition condition
                 :file file)
           r2--defhook-registry))

(defun r2--defhook-active-p (entry)
  "Return non-nil if the registry ENTRY's hook is currently active.
Checks runtime evaluation of the entry's :condition form."
  (let ((condition (plist-get entry :condition)))
    (or (eq condition t) (eval condition))))

;;;###autoload
(defun r2/defhook-list ()
  "Display all hook functions defined via `r2->defhook'."
  (interactive)
  (let ((entries '()))
    (maphash (lambda (sym plist) (push (cons sym plist) entries))
             r2--defhook-registry)
    (setq entries (sort entries
                        (lambda (a b)
                          (string< (symbol-name (car a))
                                   (symbol-name (car b))))))
    (with-current-buffer (get-buffer-create "*r2 defhooks*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "r2->defhook registry (%d entries)\n" (length entries)))
        (insert (make-string 60 ?-) "\n\n")
        (if (null entries)
            (insert "  (empty)\n")
          (dolist (e entries)
            (let* ((sym (car e))
                   (plist (cdr e))
                   (active (r2--defhook-active-p plist)))
              (insert (format "%s%s\n"
                              (if active "  " "  [inactive] ")
                              sym))
              (insert (format "    hooks:     %s\n"
                              (plist-get plist :hooks)))
              (insert (format "    depth:     %s\n"
                              (plist-get plist :depth)))
              (insert (format "    local:     %s\n"
                              (plist-get plist :local)))
              (let ((condition (plist-get plist :condition)))
                (unless (eq condition t)
                  (insert (format "    condition: %S\n" condition))))
              (when-let* ((f (plist-get plist :file)))
                (insert (format "    file:      %s\n" f)))
              (insert "\n")))))
      (goto-char (point-min))
      (special-mode))
    (pop-to-buffer-same-window "*r2 defhooks*")))

;;;###autoload
(defun r2/defhook-unregister (symbol)
  "Remove SYMBOL from every hook it's registered on, and forget it.
Useful for cleaning up after renames during development."
  (interactive
   (list (intern
          (completing-read
           "Unregister: "
           (let (names)
             (maphash (lambda (k _) (push (symbol-name k) names))
                      r2--defhook-registry)
             names)
           nil t))))
  (if-let* ((plist (gethash symbol r2--defhook-registry)))
      (progn
        (dolist (h (plist-get plist :hooks))
          (remove-hook h symbol))
        (remhash symbol r2--defhook-registry)
        (message "r2: unregistered `%s' from %d hook(s)"
                 symbol (length (plist-get plist :hooks))))
    (user-error "No defhook registered for `%s'" symbol)))


;;;
;;; Hygienic Hooks Syntax
;;;
;;;###autoload
(defmacro r2->defhook (symbol doc body &rest pairs)
  "Always create a well-defined hook function using DOC and BODY for SYMBOL.
Provide hook parameters from PAIRS of form :KEYWORD VALUE.

The following keywords are meaningful:

:hook  VALUE should be a variable type designating the hook which function named
       SYMBOL should be associated with.  VALUE may be a single hook, or a list
       of hooks.
:depth VALUE should conform `add-hook' spec for optional values.
:local VALUE should conform `add-hook' spec for optional values.
:args  VALUE should be a list of args, i.e. (arg1 arg2 ...) or arg (singular)
:defer VALUE should be an integer type designating the time in seconds to wait
       after hook has been called before running body of function named SYMBOL.
:if    VALUE should be a boolean or form, evaluated at macro-expansion/load time.
:tbd   tbd...

\(fn SYMBOL [DOCSTRING] BODY KEYWORDS)"
  (declare (doc-string 2) (debug (name body)) (indent defun))
  (let ((condition t) (hooks nil) (depth 0) (local nil) (args '())
        (time nil) (exps '()))

    (while pairs
      (let ((keyword (pop pairs)))
        (unless (symbolp keyword)
          (error "Junk in pairs %S" pairs))
        (unless pairs
          (error "Keyword %s is missing an argument" keyword))
        (let ((value (pop pairs)))
          (pcase keyword
            (:hook (setq hooks (flatten-list value)))
            (:depth (setq depth value))
            (:local (setq local value))
            (:args (setq args (flatten-list value)))
            (:if (setq condition value))
            (:defer (setq time value))))))

    (when (eval condition)
      (if time (setq body `((run-at-time ,time nil (lambda () ,@body)))))
      (if (and doc (>= (length doc) 1))
          (push `(defun ,symbol ,args ,doc ,@body) exps)
        (push `(defun ,symbol ,args ,@body) exps))
      (if hooks
          (let ((hooks-snapshot (copy-sequence hooks)))
            (while hooks
              (let (hook)
                (setq hook (pop hooks))
                (push (if (eq condition t)
                          `(add-hook ',hook #',symbol ,depth ,local)
                        `(when ,condition
                           (add-hook ',hook #',symbol ,depth ,local)))
                      exps)))
            (push `(r2--defhook-register
                    ',symbol ',hooks-snapshot ,depth ,local
                    ',condition
                    ,(or load-file-name buffer-file-name))
                  exps))
        (push `(warn "r2->defhook: %s defined without :hook" ',symbol) exps))
      `(progn . ,(nreverse exps)))))

;;; Example usage
;; (r2->defhook my-hook-func
;;   "Hook function for testings"

;;   (;;function body
;;    (message "I am here!!! %s %s %s" first second third))

;;   :if (eq system-type 'gnu/linux)
;;   :hook (first-hook second-hook third-hook)
;;   :depth 'append
;;   :local 'local
;;   :args (first second third)
;;   :defer 3)


(provide 'r2-defhook)
;;; r2-defhook.el ends here
