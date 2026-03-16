;;; r2-org.el --- Advanced Documentation Tools -*- lexical-binding: t; -*-

;;; Commentary:
;;; TODO - Enable Spell Check for Org Mode
;;;      - Use either Ispell, Aspell, or Enchant (Research)...


;;; Code:


;;; Global user variables
(defvar *r2-org-denote-directory* "~/Documents/org/"
  "Directory where org files & denotes are kept.")



;;; Configure the ALMIGHTY Org system

(defmacro r2/add-template->org-capture (&rest body)
  "Template macro add BODY which is of org-template format to list."
  `(with-eval-after-load 'org-mode
     (add-to-list 'org-capture-templates ',@body)))

(use-package org
  :ensure nil
  :hook ((org-mode . r2/org-fonts-hookfn)
         (org-mode . r2/org-latex-hookfn))
  :bind (("C-c a" . org-agenda)
         ("C-c c" . org-capture))
  :custom
  (org-auto-align-tags nil)
  (org-tags-column 0)
  (org-catch-invisible-edits 'show-and-error)
  (org-special-ctrl-a/e t)
  (org-insert-heading-respect-content t)
  (org-return-follows-link t)
  (org-mouse-1-follows-link t)
  (org-link-descriptive t)
  (org-hide-emphasis-markers t)
  (org-pretty-entities t)
  (org-agenda-window-setup 'current-window)
  (org-agenda-restore-windows-after-quite t)
  (org-agenda-start-with-log-mode t)
  (org-agenda-sticky t)
  (org-agenda-sticky t)
  (org-agenda-include-diary t)
  (org-log-into-drawer t)
  (org-log-done 'time)
  (org-log-into-drawer t)
  (org-use-fast-todo-selection t)
  (org-tag-alist '((:startgroup) ;; Set custom tags
                   ;; Put mutually exclusive tags here
                   (:endgroup)
                   ("@home"      . ?H)
                   ("@office"    . ?O)
                   ("@errands"   . ?E)
                   ("@traveling" . ?T)
                   ("@phone"     . ?P)
                   ("@email"     . ?M)))
  (org-todo-keywords
   '(;; List Keywords
     (sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)" "HOLD(h)" "WAIT(w)")
     ;; Workout Keywords
     (sequence "GOTO(g)" "|" "ZONE(z)" "REST(r)" "COMPLETE(e@/!)")
     ;; Project Keywords
     (sequence "ACTIVE(a@/!)" "|" "CANCELED(c@/!)" "ARCHIVED(r@/!)")))
  ;; view color options via `M-x' `list-colors-display'
  (org-todo-keyword-faces
   '(("TODO" . "#ebcb8b")               ; Aurora yellow
     ("NEXT" . "#d08770")               ; DeepSkyBlue
     ("GOTO" . "#ab82ff")               ; Aurora orange
     ("REST" . "#4c566a")               ; Polar Night Light Gray
     ("WAIT" . "#ff69b4")               ; HotPink
     ("HOLD" . "#bf616a")               ; Aurora Red
     ("DONE" . "#88c0d0")               ; Frost teal
     ("ZONE" . "#81a1c1")               ; Frost gray-blue
     ("ACTIVE"    . "#5e81ac")          ; Frost blue
     ("COMPLETE"  . "#a3be8c")          ; Aurora green
     ("CANCELED"  . "#4c566a")          ; Polar Night Light Gray
     ("ARCHIVED"  . "#434c5e")))        ; Polar Night Med. Gray
  (org-babel-lisp-eval-fn 'sly-eval
                          "Configure Babel Programming Language Execution")
  (org-agenda-files
   (list
    (expand-file-name "agenda.org" *r2-org-denote-directory*)))
  ;; Use Org to create Calendar entries (see calendar config below)
  (org-agenda-diary-file
   (expand-file-name "calendar.org" *r2-org-denote-directory*))
  :config
  ;; Org Helper Hook Functions
  (defun r2/org-fonts-hookfn ()
    "Hook function enabling Org faces/fonts."
    ;; Set faces for heading levels
    (dolist
        (face
         '((org-document-title extra-bold 1.40)
           (org-level-1 regular 1.30)
           (org-level-2 regular 1.15)
           (org-level-3 regular 1.08)
           (org-level-4 regular 1.04)
           (org-level-5 regular 1.02)
           (org-level-6 regular 1.01)
           (org-level-7 regular 1.00)
           (org-level-8 regular 1.00)))
      (set-face-attribute (car face) nil
                          :inherit 'variable-pitch
                          :weight (cadr face)
                          :height (caddr face)))
    ;; Ensure that anything that should be fixed-pitch in Org files appears that way
    (dolist
        (face
         '((org-table    fixed-pitch)
           (org-formula  fixed-pitch)
           (org-checkbox fixed-pitch)
           (org-table    (shadow fixed-pitch))
           (org-verbatim (shadow fixed-pitch))
           (org-special-keyword (shadow fixed-pitch))
           (org-meta-line (font-lock-comment-face fixed-pitch))
           (line-number  fixed-pitch)
           (line-number-current-line fixed-pitch)))
      (set-face-attribute (car face) nil
                          :inherit (cadr face))))

  (defun r2/org-latex-hookfn ()
    "Hook function setting up configuration for Org using Latex."

    (setq org-latex-listings t
          org-latex-pdf-process '("pdflatex -outdir=%o %f")
          org-export-with-smart-quotes t)

    (with-eval-after-load 'ox-latex
      (add-to-list 'org-latex-classes
                   '("org-plain-latex"
                     "\\documentclass{article}
                        [NO-DEFAULT-PACKAGES]
                        [PACKAGES]
                        [EXTRA]"
                     ("\\section{%s}"       . "\\section*{%s}")
                     ("\\subsection{%s}"    . "\\subsection*{%s}")
                     ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                     ("\\paragraph{%s}"     . "\\paragraph*{%s}")
                     ("\\subparagraph{%s}"  . "\\subparagraph*{%s}")))))

  ;; Org Babel Settings - only need the Holy Trinity of languages!
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (lisp       . t)
     (scheme     . t)))

  (dolist (lang
           '(("lisp"      . lisp)
             ("scheme"    . scheme)
             ("json"      . json)
             ("conf-unix" . conf-unix)
             ("conf-xorg" . conf-xdefaults)))
    (push lang org-src-lang-modes))

  (defun r2/org-export-html-to-dir (dir)
    "Export current Org file to HTML in DIR."
    (interactive "DExport to directory: ")
    (let ((default-directory dir))
      (org-html-export-to-html))))



;;; Org Accessories

(use-package org-indent
  :ensure nil
  ;; :diminish org-indent-mode
  :after (org))

(use-package org-tempo
  :ensure nil
  ;; :diminish org-tempo-mode
  :after (org)
  :config
  (setq org-structure-template-alist
        '(("el"  . "src emacs-lisp")
          ("cl"  . "src lisp")
          ("sc"  . "src scheme")
          ("js"  . "src json")
          ("sh"  . "src sh")
          ("co"  . "src conf")
          ("C"   . "src C")
          ("bib" . "src bibtex")
          ("cm"  . "comment"))))


;;; External Org Packages

(use-package org-appear
  :ensure t
  ;; :diminish org-appear-mode
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-trigger 'always)
  (org-appear-delay 0.2)
  (org-appear-autoemphasis t)
  (org-appear-autolinks t)
  (org-appear-autosubmarkers t)
  (org-appear-autoentities t))

(use-package org-superstar
  :ensure t
  ;; :diminish org-superstar-mode
  :hook (org-mode . org-superstar-mode)
  :custom
  (org-superstar-headline-bullets-list '("◉" "○" "●" "○" "●" "○" "●" "○" "●")))



;;; Calendar/Diary Integration
;;; 1. specify path to regular `diary-file'
;;; 2. create file with the following entry:
;;; %%(org-diary) /home/logoraz/Documents/org/calendar.org
(use-package calendar
  :ensure nil
  :after org
  :custom
  (calendar-mark-diary-entries-flag t)
  (diary-file (expand-file-name "diary" *r2-org-denote-directory*)))



;;; Markdown Support

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown")
  :bind (:map markdown-mode-map
              ("C-c C-e" . markdown-do)))


;;; Advanced Notetaking  --> Better Integrate with Org
(use-package denote
  :ensure t
  ;; (find-file . denote-link-buttonize-buffer) --> failing...
  :hook ((dired-mode . denote-dired-mode-in-directories)
         (denote-dired-mode . dired-hide-details-mode)
         (denote-dired-mode . all-the-icons-dired-mode))

  :bind (("C-c n j" . r2/denote-journal)
         ("C-c n n" . denote))
  :custom
  (denote-directory *r2-org-denote-directory* )
  (denote-dired-directories-include-subdirectories t)
  (denote-dired-directories
   (list
    (expand-file-name *r2-org-denote-directory*)
    (expand-file-name "notes/inbox"     *r2-org-denote-directory*)
    (expand-file-name "notes/meetings"  *r2-org-denote-directory*)
    (expand-file-name "notes/research"  *r2-org-denote-directory*)
    (expand-file-name "notes/reference" *r2-org-denote-directory*)
    (expand-file-name "notes/scratch"   *r2-org-denote-directory*)
    (expand-file-name "notes/trash"     *r2-org-denote-directory*)))
  (denote-known-keywords '("emacs"
                           "ideas"
                           "journal"
                           "philosophy"
                           "projects"
                           "research"))
  (denote-infer-keywords t)
  (denote-sort-keywords t)
  (denote-file-type 'org)
  (denote-prompts '(title keywords subdirectory))
  (denote-date-prompt-use-org-read-date t)
  (denote-allow-multi-word-keywords t)
  (denote-date-format nil)
  (denote-link-fontify-backlinks t)
  (denote-org-capture-specifiers "%l\n%i\n%?)")
  :config
  (r2/add-template->org-capture
   ;; Template 1
   ("n" "New Note (with denote.el)"
    plain
    (file denote-last-path)
    #'denote-org-capture
    :no-save t
    :immediate-finish nil
    :kill-buffer t
    :jump-to-captured t))

  (r2/add-template->org-capture
   ;; Template 2
   ("s" "Scratch Note (with denote.el)"
    plain
    (file denote-last-path)
    #'denote-org-capture
    :no-save t
    :immediate-finish nil
    :kill-buffer t
    :jump-to-captured t))

  (defun r2/denote-journal ()
    "Create an entry tagged 'journal', while prompting for a title."
    (interactive)
    (denote
     (denote-title-prompt)
     '("journal")
     'org
     (expand-file-name "notes/inbox" denote-directory))))





(provide 'r2-org)
;;; r2-org.el ends here
