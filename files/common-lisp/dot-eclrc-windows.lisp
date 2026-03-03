;;;; dot-eclrc.lisp -> .eclrc - ECL Initialization File

;;; Enable Advanced SBCL Features
(let ((*load-version* nil)
      (*load-print* nil))
  (ignore-errors (require :asdf)
                 (require :uiop)))

;;; Inform ECL where gcc is located, as opposed to including in Windows PATH
;;; Needed to create executables, specially vend.exe
(setf c::*cc*
      "C:/Users/erik.almaraz/AppData/Local/Programs/msys2/ucrt64/bin/gcc.exe")
(setf C::*ld*
      "C:/Users/erik.almaraz/AppData/Local/Programs/msys2/ucrt64/bin/gcc.exe")

;;; Make sure the C compiler backend is active
(ext:install-c-compiler)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Enable ocicl
;;;
;; Preserving existing (uiop:xdg-data-home #P"ocicl/ocicl-registry.cfg")
;; Use setup's --force option to override.

;; Present the following code to your LISP system at startup, either
;; by adding it to your implementation's startup file:
;; (~/.sbclrc, ~/.clasprc, ~/.eclrc, ~/.abclrc, ~/.ccl-init.lisp, ~/.clinit.cl,
;;   ~/.roswell/init.lisp)
;; or overriding it completely on the command line
;; (eg. sbcl --userinit init.lisp)

;; Note: To add other systems not registered in ocicl, simply use the
;; :tree keyword (as opposed to the default :directory) as follows. Also,
;; I wrap this initializing with `ignore-errors` so that the CL implementation
;; fails quietly...

#-ocicl
(ignore-errors
 (let ((ocicl-runtime (merge-pathnames "AppData/Local/ocicl/ocicl-runtime.lisp"
                                       (user-homedir-pathname))))
   (when (probe-file ocicl-runtime)
     (load ocicl-runtime)))
 (asdf:initialize-source-registry
  (list :source-registry
        ;; Keyword :tree needed to find self-vendored non-available systems
        (list :tree (uiop:getcwd))
        :inherit-configuration)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Other

