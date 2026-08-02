# Setup Latex on Windows

Install MikeTex: https://miktex.org/

 - Install for Just Me
 - add MikTex to Windows PATH
 - Enable "Install missing packages on the fly"


 Verify from a shell
```bash
    latex --version
    dvisvgm --version
```


# Emacs Configuration

Install `org-fragtog-mode` via `use-package` (https://github.com/io12/org-fragtog).

```lisp
    (use-package org
     ;; your org config here
     :custom  (org-preview-latex-default-process 'dvisvgm))

    # Checks
    (executable-find "latex")
    (executable-find "dvisvgm")

    # org-fragtog configuration
    (use-package org-fragtog
     :ensure t
     :hook (org-mode . org-fragtog-mode))

```
