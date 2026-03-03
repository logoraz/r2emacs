;;; r2-defhook.el --- Emacs Lisp Hygenic Hooks System -*- lexical-binding: t -*-

;;; Commentary:


;;; Code:

(add-to-list 'load-path (expand-file-name "transducers.el"
                                          r2-contrib-directory))

(require 'transducers)

;;; Hygenic Hooks Syntax

;;;###autoload
(defmacro r2->defhook (symbol doc body &rest pairs)
  "Always create a well-defined hook function using DOC and BODY for SYMBOL.
Provide hook parameters from PAIRS of form :KEYWORD VALUE.

The following keywords are meaninful:

:hook  VALUE should be a variable type designating the hook which function named
       SYMBOL should be associated with.  VALUE may be a single hook, or a list
       of hooks.
:depth VALUE should conform `add-hook' spec for optional values.
:local VALUE should conform `add-hook' spec for optional values.
:args  VALUE should be a list of args, i.e. (arg1 arg2 ...) or arg (singular)
:defer VALUE should be an integer type designating the time in seconds to wait
       after hook has been called before running body of function named SYMBOL.
:disable? VALUE should be either nil (default) or t
:tbd   tbd...

\(fn SYMBOL [DOCSTRING] BODY KEYWORDS)"
  (declare (doc-string 2) (debug (name body)) (indent defun))
  (let ((disabled nil) (hooks nil) (depth 0) (local nil) (args '())
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
            (:disable? (setq disabled value))
            (:defer (setq time value))))))

    (unless (eval disabled)
      (if time (setq body `((run-at-time ,time nil (lambda ,args ,@body)))))
      (if (and doc (>= (length doc) 1)) (push `(defun ,symbol ,args ,doc ,@body) exps)
        (push `(defun ,symbol ,args ,@body) exps))
      (while hooks
        (let (hook)
          (setq hook (pop hooks))
          (push `(add-hook ',hook #',symbol ,depth ,local) exps)))
      `(progn . ,(nreverse exps)))))

;;; Example usage
;; (r2->defhook my-hook-func
;;   "Hook function for testings"

;;   (;;function body
;;    (message "I am here!!! %s %s %s" first second third))

;;   :disable? (eq system-type 'gnu/linux)
;;   :hook (first-hook second-hook third-hook)
;;   :depth 'append
;;   :local 'local
;;   :args (first second third)
;;   :defer 3)


(provide 'r2-defhook)
;;; r2-defhook.el ends here
