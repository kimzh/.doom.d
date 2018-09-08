;;; lang/coq/config.el -*- lexical-binding: t; -*-

;; `coq'
(setq proof-electric-terminator-enable t
      proof-splash-seen t)

(after! company-coq
  (set-lookup-handlers! 'company-coq-mode
    :definition #'company-coq-jump-to-definition
    :references #'company-coq-grep-symbol
    :documentation #'company-coq-doc)
  (unless (featurep! :completion company)
    (setq company-coq-disabled-features '(company company-defaults))))
