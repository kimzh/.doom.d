;;; lang/latex/config.el -*- lexical-binding: t; -*-

(defvar +latex-bibtex-file ""
  "File AUCTeX (specifically RefTeX) uses to search for citations.")

(defvar +latex-bibtex-dir ""
  "Where bibtex files are kept.")

(defvar +latex-indent-level-item-continuation 4
  "Custom indentation level for items in enumeration-type environments")

(def-package! auctex
  :mode ("\\.tex\\'" . TeX-latex-mode))
;;
;; Plugins
;;

;; sp's default rules are obnoxious, so disable them
(provide 'smartparens-latex)

(after! tex
  ;; Set some varibles to fontify common LaTeX commands.
  (load! "+fontification")

  (setq TeX-parse-self t    ; Enable parse on load.
        TeX-save-query nil  ; just save, don't ask
        TeX-auto-save t     ; Enable parse on save.
        ;; Use hidden directories for AUCTeX files.
        TeX-auto-local ".auctex-auto"
        TeX-style-local ".auctex-style"
        ;; When correlating sources to rendered PDFs, don't start the emacs
        ;; server
        TeX-source-correlate-start-server nil
        TeX-source-correlate-mode t
        TeX-source-correlate-method 'synctex
        ;; Fonts for section, subsection, etc
        font-latex-fontify-sectioning 1.15)
  (setq-default TeX-master nil)
  ;; Display the output of the latex commands in a popup.
  (set-popup-rule! " output\\*$" :size 15)

  ;; TeX Font Styling
  ;; (def-package! tex-style :defer t)

  ;; TeX Folding
  (add-hook 'TeX-mode-hook #'TeX-fold-mode))


(after! latex
  (setq LaTeX-section-hook ; Add the toc entry to the sectioning hooks.
        '(LaTeX-section-heading
          LaTeX-section-title
          LaTeX-section-toc
          LaTeX-section-section
          LaTeX-section-label)
        LaTeX-fill-break-at-separators nil
        LaTeX-item-indent 0)

  (define-key LaTeX-mode-map "\C-j" nil)

  ;; Do not prompt for Master files, this allows auto-insert to add templates to
  ;; .tex files
  (add-hook! '(LaTeX-mode-hook TeX-mode-hook)
    (remove-hook 'find-file-hook
                 (cl-find-if #'byte-code-function-p find-file-hook)
                 'local))
  ;; Adding useful things for latex
  (add-hook! 'LaTeX-mode-hook
    #'(TeX-source-correlate-mode
       visual-line-mode))
  ;; Enable rainbow mode after applying styles to the buffer
  (add-hook 'TeX-update-style-hook #'rainbow-delimiters-mode)
  ;; Use chktex to search for errors in a latex file.
  (setcar (cdr (assoc "Check" TeX-command-list)) "chktex -v6 %s")
  ;; Set a custom item indentation
  (dolist (env '("itemize" "enumerate" "description"))
    (add-to-list 'LaTeX-indent-environment-list `(,env +latex/LaTeX-indent-item)))

  ;; Or Zathura
  (when (featurep! +zathura)
    (add-to-list 'TeX-view-program-selection '(output-pdf "Zathura")))

  ;; Or PDF-tools, but only if the module is also loaded
  (when (and (featurep! :tools pdf)
             (featurep! +pdf-tools))
    (add-to-list 'TeX-view-program-selection '(output-pdf "PDF Tools"))
    ;; Enable auto reverting the PDF document with PDF Tools
    (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer)))

(def-package! reftex
  :hook ((latex-mode LaTeX-mode) . turn-on-reftex)
  :init
  (setq reftex-plug-into-AUCTeX t
        reftex-toc-split-windows-fraction 0.3)
  :config
  ;; Get ReTeX working with biblatex
  ;; http://tex.stackexchange.com/questions/31966/setting-up-reftex-with-biblatex-citation-commands/31992#31992
  (setq reftex-cite-format
        '((?t . "\\textcite[]{%l}")
          (?a . "\\autocite[]{%l}")
          (?c . "\\cite[]{%l}")
          (?s . "\\smartcite[]{%l}")
          (?f . "\\footcite[]{%l}")
          (?n . "\\nocite{%l}")
          (?b . "\\blockcquote[]{%l}{}")))
  (unless (string-empty-p +latex-bibtex-file)
    (setq reftex-default-bibliography (list (expand-file-name +latex-bibtex-file))))
  (map! :map reftex-mode-map
        :localleader :n ";" 'reftex-toc)
  (add-hook! 'reftex-toc-mode-hook
    (reftex-toc-rescan)
    (map! :local
          :e "j"   #'next-line
          :e "k"   #'previous-line
          :e "q"   #'kill-buffer-and-window
          :e "ESC" #'kill-buffer-and-window)))


(def-package! bibtex
  :defer t
  :config
  (setq bibtex-dialect 'biblatex
        bibtex-align-at-equal-sign t
        bibtex-text-indentation 20)
  (define-key bibtex-mode-map (kbd "C-c \\") #'bibtex-fill-entry))


(def-package! auctex-latexmk
  :when (featurep! +latexmk)
  :after-call (latex-mode-hook LaTeX-mode-hook)
  :init
  ;; Pass the -pdf flag when TeX-PDF-mode is active
  (setq auctex-latexmk-inherit-TeX-PDF-mode t)
  ;; Set LatexMk as the default
  (setq-hook! LaTeX-mode TeX-command-default "LatexMk")
  :config
  ;; Add latexmk as a TeX target
  (auctex-latexmk-setup))

(def-package! ivy-bibtex
  :when (featurep! :completion ivy)
  :commands ivy-bibtex)

(after! bibtex-completion
  (unless (string-empty-p +latex-bibtex-file)
    (setq bibtex-completion-bibliography (list (expand-file-name +latex-bibtex-file))))
  (unless (string-empty-p +latex-bibtex-dir)
    (setq bibtex-completion-library-path (list +latex-bibtex-dir)
          bibtex-completion-notes-path (expand-file-name "notes.org" +latex-bibtex-dir))))

(def-package! company-reftex
  :after reftex
  :config
  (set-company-backend! 'reftex-mode 'company-reftex-labels 'company-reftex-citations))

;; unicode unicode everywhere
(def-package! company-auctex
  :after latex
  :config
  (def-package! company-math
    :defer t
    :init
    (add-hook! LaTeX-mode
      (setq-local company-math-allow-unicode-symbols-in-faces (quote (tex-math font-latex-math-face)))
      (setq-local company-math-disallow-unicode-symbols-in-faces nil)
      (setq-local company-math-allow-latex-symbols-in-faces nil)
      (setq-local company-backends
                  (append '((company-math-symbols-latex
                             company-math-symbols-unicode
                             company-auctex-macros
                             company-auctex-environments))
                          company-backends)))))

;; Nicely indent lines that have wrapped when visual line mode is activated
(def-package! adaptive-wrap
  :hook (LaTeX-mode . adaptive-wrap-prefix-mode)
  :init (setq-default adaptive-wrap-extra-indent 0))
