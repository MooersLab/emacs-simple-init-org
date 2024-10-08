;; Source https://jonathanabennett.github.io/blog/2019/05/29/writing-academic-papers-with-org-mode by Jonathan Bennett
;; alias e29o='/Applications/Emacs29.3.app/Contents/MacOS/Emacs --init-directory ~/e29org --debug-init'


(require 'package)
  (setq package-enable-at-startup nil)
  (setq package-archives '(("org"  . "http://orgmode.org/elpa/")
                          ("gnu"   . "http://elpa.gnu.org/packages/")
                          ("melpa" . "http://melpa.org/packages/")))
  (package-initialize)

  (unless (package-installed-p 'use-package)
    (package-refresh-colontents)
    (package-install 'use-package))
  (require 'use-package)
  (setq use-package-always-ensure t)
 
 
  (unless (package-installed-p 'quelpa)
    (with-temp-buffer
      (url-insert-file-contents "https://raw.githubusercontent.com/quelpa/quelpa/master/quelpa.el")
      (eval-buffer)
      (quelpa-self-upgrade)))

(message "Finished package manger configuration.") 
;; Customizations

;;;# garbage collection
(use-package gcmh
  :diminish gcmh-mode
  :config
  (setq gcmh-idle-delay 5
        gcmh-high-cons-threshold (* 16 1024 1024))  ; 16mb
  (gcmh-mode 1))

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-percentage 0.1))) ;; Default value for `gc-cons-percentage'

(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs ready in %s with %d garbage collections."
                     (format "%.2f seconds"
                             (float-time
                              (time-subtract after-init-time before-init-time)))
                     gcs-done)))

(message "Finished garbage collection.")

(message "Start settings section.")
;;;# save current init.el to ~/.saves
;; source https://www.reddit.com/r/emacs/comments/11ap924/the_most_important_snippet_in_my_emacs_init_file/
(setq
backup-by-copying t ; don't clobber symlinks
backup-directory-alist
'(("." . "~/.e29orgInitSaves")) ; don't litter my fs tree
delete-old-versions t
kept-new-versions 6
kept-old-versions 2
version-control t)


;; Export from org to latex
(setq org-latex-pdf-process
  '("latexmk -pdflatex='pdflatex -interaction nonstopmode -shell-escape' -pdf -bibtex -f %f"))




;;; Basics Configuration
;;(setq openai-key "[]")
;;(setq openai-api-key "")


(setq inhibit-startup-message t) ;; hide the startup message
;; (load-theme 'material t) ;; load material theme
;; (global-linum-mode t) ;; enable line numbers globally
(set-default 'truncate-lines t) ;; do not wrap
(prefer-coding-system 'utf-8) ;; use UTF-8

;;load prefers the newest version of a file.
;; This applies when a filename suffix is not explicitly specified and load is trying various possible suffixes (see load-suffixes and load-file-rep-suffixes). Normally, it stops at the first file that exists unless you explicitly specify one or the other. If this option is non-nil, it checks all suffixes and uses whichever file is newest.
;; (setq load-prefer-newer t) --> causes RECURSIVE LOAD error

;;;# Zoom
(set-face-attribute 'default nil :height 128)

;;;# Save History
(savehist-mode +1)
(setq savehist-additional-variables '(kill-ring search-ring regexp-search-ring))


;;;# Size of the starting Window
(setq initial-frame-alist '((top . 1)
                (left . 450)
                (width . 101)
                (height . 90)))

;;;# Line wrap
(global-visual-line-mode +1)
(delete-selection-mode +1)
(save-place-mode +1)


;;;# set browser to open url in new tab
(custom-set-variables
  '(browse-url-browser-function (quote browse-url-firefox))
  '(browse-url-firefox-new-window-is-tab t))



;;;# Global keybindings

(global-set-key (kbd "C-h D") 'devdocs-lookup)
(message "End settings section.")


(message "Begin custom elisp functions section.")
;;;# Elisp functions by me and others

;; * Elisp functions by me and others.

;;;### M-x description
;; Converts a selected list into a description list.
;; The elements of the list must begin with a dash.
;; The terms to be inserted into the square brackets
;; have to be added after running the function.
(defun description (beg end)
  "wrap the active region in an 'itemize' environment,
  converting hyphens at the beginning of a line to \item"
  (interactive "r")
  (save-restriction
    (narrow-to-region beg end)
    (beginning-of-buffer)
    (insert "\\begin{description}\n")
    (while (re-search-forward "^- " nil t)
      (replace-match "\\\\item[ ]"))
    (end-of-buffer)
    (insert "\\end{description}\n")))

;;;### M-x enumerate
;; Converts a selected list into an enumerated list.
;; The elements of the list must begin with a dash.
(defun enumerate (beg end)
  "wrap the active region in an 'itemize' environment,
  converting hyphens at the beginning of a line to \item"
  (interactive "r")
  (save-restriction
    (narrow-to-region beg end)
    (beginning-of-buffer)
    (insert "\\begin{enumerate}\n")
    (while (re-search-forward "^- " nil t)
      (replace-match "\\\\item "))
    (end-of-buffer)
    (insert "\\end{enumerate}\n")))
(message "Finishd M-x enumerate configurations. Line 4369.")

;;;### M-x itemize
;; Converts a selected list into an itemized list.
;; The elements of the list must begin with a dash.
;; A similar function could be made to make an enumerated list
;; and a description list.
;; Source: \url{https://tex.stackexchange.com/questions/118958/emacsauctex-prevent-region-filling-when-inserting-itemize}
(defun itemize (beg end)
 "wrap the active region in an 'itemize' environment,
  converting hyphens at the beginning of a line to \item"
  (interactive "r")
  (save-restriction
    (narrow-to-region beg end)
    (beginning-of-buffer)
    (insert "\\begin{itemize}\n")
    (while (re-search-forward "^- " nil t)
      (replace-match "\\\\item "))
    (end-of-buffer)
    (insert "\\end{itemize}\n")))
(message "Finishd defun itemize. Line 4389.")


(defun ichmk ()
  "Inserts a checkmark."
  (interactive)
  (insert "\\\item \\checkmark "))


;;;### org headlies to beamer slides in region

;; *** M-x org-to-beamer-slides-in-region

(defun org-to-beamer-slides-in-region (start end)
  "Convert an Org-mode outline as a list of headlines into Beamer slides flanked by unnumbered subsections and notes. The output can be pasted into a beam slideshow on Overleaf."
  (interactive "r")
  (save-restriction
    (narrow-to-region start end)
    (goto-char (point-min))
    (while (re-search-forward "^\\*+ \\(.*\\)$" nil t)
      (let ((title (match-string 1)))
        (replace-match (concat "\\\\subsection*{" title "}\n\\\\begin{frame}\n\\\\frametitle{" title "}\n") nil nil)
        (end-of-line)
        (insert "\n\\end{frame}\n\\note{Your note here}\n\n"))))
(message "Conversion to Beamer slides complete!"))





;;;; https://stackoverflow.com/questions/539984/how-do-i-get-emacs-to-fill-sentences-but-not-paragraphs/6103404#6103404
;;;; Unwrap paragraphs into one sentence per line.
(defun fill-sentences-in-paragraph ()
  "Put a newline at the end of each sentence in paragraph."
  (interactive)
  (save-excursion
    (mark-paragraph)
    (call-interactively 'fill-sentences-in-region)))

(defun fill-sentences-in-region (start end)
  "Put a newline at the end of each sentence in region."
  (interactive "*r")
  (call-interactively 'unfill-region)
  (save-excursion
    (goto-char start)
    (while (re-search-forward "[.?!][]\"')}]*\\( \\)" end t)
      (newline-and-indent))))

;;;### my-openai-api-key
(defun my-openai-api-key ()
 "Read api key from disk."
 (with-temp-buffer
   (insert-file-contents "~/openaikey.txt")
   (string-trim (buffer-string))))



(defun unfill-region (beg end)
      "Unfill the region, joining text paragraphs into a
       single logical line.  This is useful, e.g., for use
       with 'visual-line-mode'."
      (interactive "*r")
      (let ((fill-column (point-max)))
        (fill-region beg end)))

(global-set-key "\M-q" 'fill-sentences-in-paragraph)


;;;## reload-init-e29org
;; Inspried https://sachachua.com/dotemacs/index.html#org4dd39d0
(defun reload-init-e29org ()
  "Reload the init.el file for e29org. Edit the path to suite your needs."
  (interactive)
  (load-file "~/e29org/init.el"))

;;;## reload-hydras
(defun reload-hydras ()
  "Reload my-hydras.el. Edit the path to suite your needs."
  (interactive)
  (load-file "~/emacs29.3/my-hydras/my-hydras.el"))

;;;## reload-learning-spiral-hydras
(defun reload-learning-spiral-hydras ()
  "Reload learning-spiral-hydras.el. Edit the path to suite your needs."
  (interactive)
  (load-file "~/emacs29.3/my-hydras/learning-spiral-hydras.el"))

;;;## reload-writing-projects-hydra
(defun reload-writing-projects-hydra ()
  "Reload lwriting-projects-hdyra.el. Edit the path to suite your needs."
  (interactive)
  (load-file "~/emacs29.3/my-hydras/writing-projects-hydra.el"))

;;;## reload-talon-quiz-hydras
;;(defun reload-talon-quiz-hydras ()
;;  "Reload learning-spiral-hydras.el. Edit the path to suite your needs."
;;  (interactive)
;;  (load-file "~/emacs29.3/my-hydras/talon-quiz-hydras.el"))

;;;## reload-uniteai
(defun reload-uniteai ()
  "Reload my-uniteai.el. Edit the path to suite your needs."
  (interactive)
  (load-file "~/e29org/my-uniteai.el"))

;;;# Clean and sort list of items in region

;; *** clean-sort-list-in-region

(defun clean-sort-list-in-region (beg end)
  "Clean and sort the lines in the selected region.
   Removes duplicate lines, blank lines, and sort alphabetically.
   Built by Copilot"
  (interactive "r")
  (let ((lines (split-string (buffer-substring-no-properties beg end) "\n" t))
        (cleaned-lines nil))
    ;; Remove duplicates and blank lines
    (dolist (line lines)
      (when (and (not (string-blank-p line))
                 (not (member line cleaned-lines)))
        (push line cleaned-lines)))
    ;; Sort alphabetically
    (setq cleaned-lines (sort cleaned-lines #'string<))
    ;; Replace the region with the cleaned and sorted lines
    (delete-region beg end)
    (insert (mapconcat #'identity cleaned-lines "\n"))))
(global-set-key (kbd "C-c s") 'clean-sort-list-in-region)


;; source https://emacs.stackexchange.com/questions/12938/how-can-i-evaluate-elisp-in-an-orgmode-file-when-it-is-opened
;; I use this to invoke wc-mode in manuscript documents.
(defun tdh/eval-startblock ()
  (if (member "startblock" (org-babel-src-block-names))
    (save-excursion
      (org-babel-goto-named-src-block "startblock")
      (org-babel-execute-src-block))
    nil
    )
  )
(add-hook 'org-mode-hook 'tdh/eval-startblock)


;; source https://irreal.org/blog/?p=5722
;; works on regions well
(defun my/count-words-in-subtree-or-region ()
;; Bind this to a key in org-mode, e.g. C-=
(interactive)
(call-interactively (if (region-active-p)
'count-words-region
'my/count-words-in-subtree)))

(defun my/count-words-in-subtree ()
"Count words in current node and child nodes, excluding heading text."
(interactive)
(org-with-wide-buffer
(message "%s words in subtree"
(-sum (org-map-entries
(lambda ()
(outline-back-to-heading)
(forward-line 1)
(while (or (looking-at org-keyword-time-regexp)
(org-in-drawer-p))
(forward-line 1))
(count-words (point)
(progn
(outline-end-of-subtree)
(point))))
nil 'tree)))))




;;;# open PDFs with default system viewer (usually Preview on a Mac)
;; source: http://stackoverflow.com/a/1253761/1325477https://emacs.stackexchange.com/questions/3105/how-to-use-an-external-program-as-the-default-way-to-open-pdfs-from-emacs
;; Remove "\\.pdf" to enable use of PDF tools
(defun mac-open (filename)
  (interactive "fFilename: ")
  (let ((process-connection-type))
    (start-process "" nil "open" (expand-file-name filename))))

(defun find-file-auto (orig-fun &rest args)
  (let ((filename (car args)))
    (if (cl-find-if
         (lambda (regexp) (string-match regexp filename))
         '( "\\.doc\\'" "\\.docx?\\'" "\\.xlsx?\\'" "\\.xlsm?\\'" "\\.pptx?\\'" "\\.itmz\\'"  "\\.png\\'"))
        (mac-open filename)
      (apply orig-fun args))))

(advice-add 'find-file :around 'find-file-auto)


;; Copy template writing log, rename the file with the project ID included in the filename, and open the file in a new buffer.
;; Translated the corresponding bash function with copilot.
(defun orglog (projectID)
  "Copy template writing log in org with project number in title and open the file."
  (interactive "sProject ID: ")
  (if (or (string= projectID "")
          (string-match-p " " projectID))
      (progn
        (message "Usage: orglog projectID")
        (error "Invalid number of arguments"))
    (let ((template "~/6112MooersLabGitHubLabRepos/writingLogTemplateInOrg/writingLogTemplateVer7.org")
          (destination (concat "log" projectID ".org")))
      (copy-file template destination t)
      (find-file destination)
      (message "Write writing log to %s file and open in a new buffer." destination))))


;; *** wrap-region-with-org-src-block

;; Wrap a marked block of elisp code with a org-mode source block.
;; I need to make a varient for LaTeX minted code environment.

(defun wrap-region-with-org-src-block ()
  "Wrap the selected region with an elisp source block."
  (interactive)
  (let ((begin (region-beginning))
        (end (region-end)))
    (goto-char end)
    (insert "\n#+END_SRC")
    (goto-char begin)
    (insert "#+BEGIN_SRC emacs-lisp\n")))

(global-set-key (kbd "C-c w") 'wrap-region-with-org-src-block)




; ** create-latex-table-with-caption
;
; This interactive function prompts the user for the number of rows, columns, caption, and label.
; Then this function generates a table that has a top Rule and a rule below the column labels.
; It also has a bottom rule. It does not contain any vertical rules.
; This function required five rounds of iteration with Copilot.
; It was developed after developing the function below: create-org-table-with-caption.
; That code was used as a template for Copilot.
; It in turn had been developed after four or five rounds of iteration.

(defun create-latex-table-with-caption ()
  (interactive)
  (let ((rows (read-number "Enter the number of rows: "))
        (cols (read-number "Enter the number of columns: "))
        (caption (read-string "Enter the table's caption: "))
        (label (read-string "Enter the table's label: ")))
    (insert (format "\\begin{table}[h]\n\\centering\n\\caption{%s \\label{%s}}\n\\begin{tabular}{%s}\n\\hline\n"
                    caption label (make-string cols ?c)))
    ;; Insert column labels
    (dotimes (col cols)
      (insert (format " %c " (+ ?A col)))
      (if (< col (1- cols))
          (insert "&")))
    (insert " \\\\\n\\hline\n")
    ;; Insert table rows
    (dotimes (_ rows)
      (dotimes (col cols)
        (insert (format " Cell %d-%d " (1+ col) (1+ _)))
        (if (< col (1- cols))
            (insert "&")))
      (insert " \\\\\n"))
    (insert "\\hline\n\\end{tabular}\n\\end{table}\n")))





;** create-org-table-with-caption
;This interactive function prompts the user for the number of rows. columns, and the caption of the table.

(defun create-org-table-with-caption ()
"This interactive function prompts the user for the number of rows. columns, and the caption of the table."
  (interactive)
  (let ((rows (read-number "Enter the number of rows: "))
        (cols (read-number "Enter the number of columns: "))
        (label (read-string "Enter the table label: "))
        (caption (read-string "Enter the table's caption: ")))
    (insert (format "#+CAPTION: %s \\label{%s}\n" caption label))
    (insert (format "#+NAME: %s\n" label))
    (insert "|")
    (dotimes (_ cols)
      (insert "----+"))
    (insert "\n|")
    ;;(insert "|")
    (dotimes (col cols)
      (insert (format " %c |" (+ ?A col))))
    (insert "\n|")
    (dotimes (_ cols)
      (insert "----+"))
    (insert "\n")
    (dotimes (_ rows)
      (insert "|")
      (dotimes (_ cols)
        (insert "     |"))
      (insert "\n"))
    (insert "|")
    (dotimes (_ cols)
      (insert "----+"))))

; *** insert-org-captioned-figure
;
; The function prompts the user for the image file path and name, the label, and the caption.

(defun insert-org-captioned-figure ()
  "Insert a captioned figure in Org-mode."
  (interactive)
  (let ((image-name (read-string "Enter the image file path: "))
        (label (read-string "Enter the figure label: "))
        (caption (read-string "Enter the figure caption: ")))
    (insert (format "#+CAPTION: %s \\label{%s}\n" caption label))
    (insert (format "#+NAME: %s\n" label))
    (insert (format "[[file:%s]]\n" image-name))))


;; *** latex-to-org-list-region

;; Select a list of items in LaTex and convert to list of items in org-mode

;; To use this function, select the region containing the LaTeX list and run:
;; M-x latex-to-org-list-region

(defun latex-to-org-list-region (start end)
  "Convert a LaTeX itemize list in the region to an Org-mode list."
  (interactive "r")
  (save-excursion
    (goto-char start)
    (while (re-search-forward "\\\\item" end t)
      (replace-match "-"))))




(message "End of the custom elisp functions section.")



;;# Shell configuration
(use-package exec-path-from-shell
  :init
  (setenv "SHELL" "/opt/local/bin/bash")
  :if (memq window-system '(mac ns x))
  :config
  (setq exec-path-from-shell-variables '("PATH" "GOPATH" "PYTHONPATH"))
  (exec-path-from-shell-initialize))
(message "Finished shell configuration. Line 480.")


;;;# Size of the starting Window
(setq initial-frame-alist '((top . 1)
                (left . 450)
                (width . 101)
                (height . 90)))



;;;# Faked full screen
(use-package maxframe)
(defvar my-fullscreen-p t "Check if fullscreen is on or off")
(defun my-toggle-fullscreen ()
  (interactive)
  (setq my-fullscreen-p (not my-fullscreen-p))
  (if my-fullscreen-p
    (restore-frame)
    (maximize-frame)))
(global-set-key (kbd "M-S") 'toggle-frame-fullscreen) ;; conflicts with an auctex command to insert an \item in a list.
(message "Finished frame configuration. Line 493.")

;;;# Backups
(setq vc-make-backup-files t)

(setq version-control t ;; Use version numbers for backups.
        kept-new-versions 10 ;; Number of newest versions to keep.
        kept-old-versions 0 ;; Number of oldest versions to keep.
        delete-old-versions t ;; Don't ask to delete excess backup versions.
        backup-by-copying t) ;; Copy all files, don't rename them.

;; If you want to avoid 'backup-by-copying', you can instead use
;;
;; (setq backup-by-copying-when-linked t)
;;
;; but that makes the second, "per save" backup below not run, since
;; buffers with no backing file on disk are not backed up, and
;; renaming removes the backing file.  The "per session" backup will
;; happen in any case, you'll just have less consistent numbering of
;; per-save backups (i.e. only the second and subsequent save will
;; result in per-save backups).

;; If you want to avoid backing up some files, e.g. large files,
;; then try setting 'backup-enable-predicate'.  You'll want to
;; extend 'normal-backup-enable-predicate', which already avoids
;; things like backing up files in '/tmp'.
;;;#  Default and per-save backups go here:
(setq backup-directory-alist '(("" . "~/e29org/backup/per-save")))

(defun force-backup-of-buffer ()
   ;; Make a special "per session" backup at the first save of each
   ;; emacs session.
   (when (not buffer-backed-up)
     ;; Override the default parameters for per-session backups.
     (let ((backup-directory-alist '(("" . "~/e29org/backup/per-session")))
           (kept-new-versions 3))
       (backup-buffer)))
   ;; Make a "per save" backup on each save.  The first save results in
   ;; both a per-session and a per-save backup, to keep the numbering
   ;; of per-save backups consistent.
   (let ((buffer-backed-up nil))
     (backup-buffer)))
(add-hook 'before-save-hook  'force-backup-of-buffer)
(message "Finished force-backup-of-buffer configuration. Line 537.")

;;;# Do not move the current file while creating backup.
(setq backup-by-copying t)
(message "Backup configuration finished. Line 541.")

;;;# Disable lockfiles.
(setq create-lockfiles nil)

(message "Finished lockfile configuration. Line 235.")

(column-number-mode)

;;;# Show stray whitespace.
(setq-default show-trailing-whitespace t)
(setq-default indicate-empty-lines t)
(setq-default indicate-buffer-boundaries 'left)

;;;# Add a newline automatically at the end of a file while saving.
(setq-default require-final-newline t)

;;;# A single space follows the end of sentence.
(setq sentence-end-double-space nil)




(message "Finished find file configuration. Line 584.")

;; (global-set-key (kbd "C-c p") 'dpkg-menpdf


;;;# Turn on font-locking or syntax highlighting
(global-font-lock-mode t)

;;;# font size in the modeline
(set-face-attribute 'mode-line nil  :height 140)

;;;# set default coding of buffers
(setq default-buffer-file-coding-system 'utf-8-unix)

;; Switch from tabs to spaces for indentation
;; Set the indentation level to 4.
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;;;# Indentation setting for various languages.
(setq c-basic-offset 4)
(setq js-indent-level 2)
(setq css-indent-offset 2)
(setq python-basic-offset 4)

(setq user-init-file "/Users/blaine/e29org/init.el")
(setq user-emacs-directory "/Users/blaine/e29org/")
;; (setq default-directory "/Users/blaine")
;; the directory that you start Emacs in should be the default for the current buffer
(setenv "HOME" "/Users/blaine")
;; (load user-init-file)


(advice-add 'describe-function-1 :after #'elisp-demos-advice-describe-function-1)

(advice-add 'helpful-update :after #'elisp-demos-advice-helpful-update)

;;;# Write customizations to a separate file instead of this file.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file t)




;;;# Custom command.
(defun show-current-time ()
  "Show current time."
  (interactive)
  (message (current-time-string)))

;;;# Custom key sequences.
;; (global-set-key (kbd "C-c t") 'show-current-time)
(global-set-key (kbd "C-c d") 'delete-trailing-whitespace)


;;;# display line numbers. Need with s-l.
(global-display-line-numbers-mode)

;;;# hippie-expand M-/. Seems to be comflicting with Corfu, Cape, and dabrrev.
;; (global-set-key [remap dabbrev-expand]  'hippie-expand)


;;;# GUI related settings
(if (display-graphic-p)
    (progn
      ;; Removed some UI elements
      ;; (menu-bar-mode -1)
      (tool-bar-mode -1)
      (scroll-bar-mode -1)
      ;; Show battery status
      (display-battery-mode 1)))


;; Hey, stop being a whimp and learn the Emacs keybindings!
;; ;; Set copy+paste
;;  (cua-mode t)
;;     (setq cua-auto-tabify-rectangles nil) ;; Don't tabify after rectangle commands
;;     (transient-mark-mode 1) ;; No region when it is not highlighted
;;     (setq cua-keep-region-after-copy t) ;; Standard Windows behaviour

;; REMOVE THE SCRATCH BUFFER AT STARTUP
;; Makes *scratch* empty.
;; (setq initial-scratch-message "")
;; Removes *scratch* from buffer after the mode has been set.
;; (defun remove-scratch-buffer ()
;;   (if (get-buffer "*scratch*")
;;       (kill-buffer "*scratch*")))
;; (add-hook 'after-change-major-mode-hook 'remove-scratch-buffer)


;;;# Disable the C-z sleep/suspend key
;; See http://stackoverflow.com/questions/28202546/hitting-ctrl-z-in-emacs-freezes-everything
(global-unset-key (kbd "C-z"))

;; Disable the C-x C-b key, use helm (C-x b) instead
;; (global-unset-key (kbd "C-x C-b"))


;;;# Make copy and paste use the same clipboard as emacs.
(setq select-enable-primary t
      select-enable-clipboard t)


(setq display-time-default-load-average nil)
(setq display-time-day-and-date t display-time-24hr-format t)
(display-time-mode t)


;;;# dired-icon-mode
(use-package dired-icon
  :ensure t
  :config
  (add-hook 'dired-mode-hook 'dired-icon-mode))


;; Revert Dired and other buffers after changes to files in directories on disk.
;; Source: [[https://www.youtube.com/watch?v=51eSeqcaikM&list=PLEoMzSkcN8oNmd98m_6FoaJseUsa6QGm2&index=2][Dave Wilson]]
(setq global-auto-revert-non-file-buffers t)


;;;# customize powerline
;; (line above the command line at the bottom of the screen)
(use-package powerline)
(powerline-default-theme)


;;;# Add line numbers.
;; (global-nlinum-mode t)

;;;# highlight current line
(global-hl-line-mode +1)
(set-face-background hl-line-face "wheat1")
(set-face-attribute 'mode-line nil  :height 180)

;;;# List recently opened files.
;; Recent files
(recentf-mode 1)
(global-set-key "\C-x\ \C-r" 'recentf-open-files)

;;;# UTF-8
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(set-keyboard-coding-system 'utf-8-unix)
(set-terminal-coding-system 'utf-8-unix)



;;;# Quickly access dot emacs d
(global-set-key (kbd "C-c e")
    (lambda()
      (interactive)
      (find-file "~/e29org/init.el")))


(set-face-attribute 'default nil :height 140)

(set-frame-parameter (selected-frame) 'buffer-predicate
                     (lambda (buf)
                       (let ((name (buffer-name buf)))
                         (not (or (string-prefix-p "*" name)
                                  (eq 'dired-mode (buffer-local-value 'major-mode buf)))))))


;;;# Global keys
;; If you use a window manager be careful of possible key binding clashes
(setq recenter-positions '(top middle bottom))
(global-set-key (kbd "C-1") 'kill-this-buffer)
(global-set-key (kbd "C-<down>") (kbd "C-u 1 C-v"))
(global-set-key (kbd "C-<up>") (kbd "C-u 1 M-v"))
(global-set-key [C-tab] 'other-window)
(global-set-key (kbd "C-c c") 'calendar)
(global-set-key (kbd "C-x C-b") 'ibuffer)
(global-set-key (kbd "C-`") 'mode-line-other-buffer)
;; (global-set-key (kbd "M-/") #'hippie-expand)
(global-set-key (kbd "C-x C-j") 'dired-jump)
(global-set-key (kbd "C-c r") 'remember)


(setq case-fold-search t)


;; Show the file path in the title of the frame
;; source https://stackoverflow.com/questions/2903426/display-path-of-file-in-status-bar See entry by mortnene
;; This is much more useful than just showing the file name or buffer name in the frame title.

(setq frame-title-format
      '(:eval
        (if buffer-file-name
            (replace-regexp-in-string
             "\\\\" "/"
             (replace-regexp-in-string
              (regexp-quote (getenv "HOME")) "e30: ~"
              (convert-standard-filename buffer-file-name)))
          (buffer-name))))


; ;; Source https://stackoverflow.com/questions/50222656/setting-emacs-frame-title-in-emacs
; (setq frame-title-format
;   (concat "%b - emacs@" (system-name)))
; (setq-default frame-title-format '("%f [%m]"))
; (setq frame-title-format "Main emacs29.3 config - %b " )




;;;# Browse URLS in text mode
(global-goto-address-mode +1)


;;;# Revert buffers when the underlying file has changed.
(global-auto-revert-mode 1)


;;;# Save history going back 25 commands.
;; Use M-p to get previous command used in the minibuffer.
;; Use M-n to move to next command.
(setq history-length 25)
(savehist-mode 1)


;;;# Save place in a file.
(save-place-mode 1)


;;;# sets monday to be the first day of the week in calendar
(setq calendar-week-start-day 1)

;;;# save emacs backups in a different directory
;; (some build-systems build automatically all files with a prefix, and .#something.someending breakes that)
(setq backup-directory-alist '(("." . "~/.emacsbackups")))


;;;# Enable show-paren-mode (to visualize paranthesis) and make it possible to delete things we have marked
(show-paren-mode 1)
(delete-selection-mode 1)


;;;# use y or n instead of yes or no
(defalias 'yes-or-no-p 'y-or-n-p)

;;;# These settings enables using the same configuration file on multiple platforms.
;; Note that windows-nt includes [[https://www.gnu.org/software/emacs/manual/html_node/elisp/System-Environment.html][windows 10]].
(defconst *is-a-mac* (eq system-type 'darwin))
(defconst *is-a-linux* (eq system-type 'gnu/linux))
(defconst *is-windows* (eq system-type 'windows-nt))
(defconst *is-cygwin* (eq system-type 'cygwin))
(defconst *is-unix* (not *is-windows*))


;; ==> adjust here
;; See this [[http://ergoemacs.org/emacs/emacs_hyper_super_keys.html][ for more information.]]
;; set keys for Apple keyboard, for emacs in OS X
;; Source http://xahlee.info/emacs/emacs/emacs_hyper_super_keys.html
(setq mac-command-modifier 'meta) ; make cmd key do Meta
(setq mac-option-modifier 'super) ; make option key do Super.
(setq mac-control-modifier 'control) ; make Control key do Control
(setq mac-function-modifier 'hyper)  ; make Fn key do Hyper. Only works on Apple produced keyboards.
(setq mac-right-command-modifier 'hyper)



;;;# Copy selected region to kill ring and clipboard. Should use M-w for same functionality.
(define-key global-map (kbd "H-c") 'cua-copy-region)


;;;# Save the buffer. Should use C-x 0
;; (define-key global-map (kbd "s-s") 'save-buffer)


;;;# Switch to previous buffer
(define-key global-map (kbd "H-<left>") 'previous-buffer)
;;;# Switch to next buffer
(define-key global-map (kbd "H-<right>") 'next-buffer)


;;;# Minibuffer history keybindings
;; The calling up of a previously issued command in the minibuffer with ~M-p~ saves times.
(autoload 'edit-server-maybe-dehtmlize-buffer "edit-server-htmlize" "edit-server-htmlize" t)
(autoload 'edit-server-maybe-htmlize-buffer "edit-server-htmlize" "edit-server-htmlize" t)
(add-hook 'edit-server-start-hook 'edit-server-maybe-dehtmlize-buffer)
(add-hook 'edit-server-done-hook  'edit-server-maybe-htmlize-buffer)
(define-key minibuffer-local-map (kbd "M-p") 'previous-complete-history-element)
(define-key minibuffer-local-map (kbd "M-n") 'next-complete-history-element)
(define-key minibuffer-local-map (kbd "<up>") 'previous-complete-history-element)
(define-key minibuffer-local-map (kbd "<down>") 'next-complete-history-element)

;;;# switch-to-minibuffer
(defun switch-to-minibuffer ()
  "Switch to minibuffer window."
  (interactive)
  (if (active-minibuffer-window)
      (select-window (active-minibuffer-window))
    (error "Minibuffer is not active")))

(global-set-key "\C-cm" 'switch-to-minibuffer) ;; Bind to `C-c m' for minibuffer.

;;;# Bibtex configuration
(defconst blaine/bib-libraries (list "/Users/blaine/Documents/global.bib"))

;;;# Combined with emacs-mac, this gives good PDF quality for [[https://www.aidanscannell.com/post/setting-up-an-emacs-playground-on-mac/][retina display]].
(setq pdf-view-use-scaling t)


;;;# PDF default page width behavior
(setq-default pdf-view-display-size 'fit-page)


;;;# Set delay in the matching parenthesis to zero.
(setq show-paren-delay 0)
(show-paren-mode t)

;;;# Window management
;; winner-mode C-c <rigth> undo change C-c <left> redo change
(winner-mode 1)

(defun split-vertical-evenly ()
  (interactive)
  (command-execute 'split-window-vertically)
  (command-execute 'balance-windows))
(global-set-key (kbd "C-x 2") 'split-vertical-evenly)


(defun split-horizontal-evenly ()
  (interactive)
  (command-execute 'split-window-horizontally)
  (command-execute 'balance-windows))
(global-set-key (kbd "C-x 3") 'split-horizontal-evenly)

(message "Starting config of packages--takes 5-60 seconds, depending on the operating system.")

;;;#  Zoom in and out via C-scroll wheel
;; (global-set-key [C-wheel-up] 'text-scale-increase)
;; (global-set-key [C-wheel-down] 'text-scale-decrease)

;;;# Control-scroll wheel to zoom in and out. Very Sweet!
(global-set-key [C-mouse-4] 'text-scale-increase)
(global-set-key [C-mouse-5] 'text-scale-decrease)


;;; Aliases
;; Source: https://www.youtube.com/watch?v=ufVldIrUOBg
;; Defalias: a quick guide to making an alias in Emacs
;; Usage: M-x ct

(defalias 'ct 'customize-themes)
(defalias 'cz 'customize)
(defalias 'ddl 'delete-duplicate-lines)
(defalias 'dga 'define-global-abbrev)
(defalias 'dma 'define-mode-abbrev)
(defalias 'ea 'edit-abbrevs)
(defalias 'ff 'flip-frame)
(defalias 'fl 'flush-lines)
(defalias 'fnd 'find-name-dired)
(defalias 'klm 'kill-matching-lines)
(defalias 'lc 'langtool-check)
(defalias 'lcu 'langtool-check-buffer)
(defalias 'lp 'list-packages)
(defalias 'pcr 'package-refresh-contents)
(defalias 'pi 'package-install)
(defalias 'pua 'package-upgrade-all)
(defalias 'qr 'query-replace)
(defalias 'rg 'rgrep)
(defalias 'rsv 'replace-smart-quotes)
(defalias 'sl 'sort-lines)
(defalias 'slo 'single-lines-only)
(defalias 'spe 'ispell-region)
(defalias 'udd 'package-upgrade-all)
(defalias 'ugg 'package-upgrade-all)
(defalias 'wr 'write-region)
(message "Finished global settings section.")


(message "Start package configurations A")

;;** ace-window
(global-set-key (kbd "M-o") 'ace-window)
;; the list of initial characters used in window labels:
(setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
;; default settings
(defvar aw-dispatch-alist
  '((?x aw-delete-window "Delete Window")
	(?m aw-swap-window "Swap Windows")
	(?M aw-move-window "Move Window")
	(?c aw-copy-window "Copy Window")
	(?j aw-switch-buffer-in-window "Select Buffer")
	(?n aw-flip-window)
	(?u aw-switch-buffer-other-window "Switch Buffer Other Window")
	(?c aw-split-window-fair "Split Fair Window")
	(?v aw-split-window-vert "Split Vert Window")
	(?b aw-split-window-horz "Split Horz Window")
	(?o delete-other-windows "Delete Other Windows")
	(?? aw-show-dispatch-help))
  "List of actions for `aw-dispatch-default'.")



(use-package auctex
  :ensure t
  :defer t
  :hook (LaTeX-mode . (lambda ()
			(push (list 'output-pdf "Skim")
			      TeX-view-program-selection))))

(message "Start package configurations C")
;;;# C


(use-package citar
  :bind (("C-c b" . citar-insert-citation)
         :map minibuffer-local-map
         ("M-b" . citar-insert-preset))
  :custom
    (citar-bibliography '("/Users/blaine/Documents/global.bib"))
    (citar-library-paths '("/Users/blaine/0papersLabeled") '("/Users/blaine/0booksUnlabeled"))
    (citar-library-file-extensions '("pdf" "epub"))
  :hook
  ;; enable autocompletion in buffer of citekeys
    (LaTeX-mode . citar-capf-setup)
    (org-mode . citar-capf-setup))

(setenv "PATH" (concat "/usr/local/bin/:/opt/local/bin/" (getenv "PATH")))
(add-to-list 'exec-path "/usr/local/bin:/opt/local/bin/")

;;*** citar-org, use after org-cite. It is not loaded.
; (use-package citar-org
;   :after oc
;   :custom
;   (org-cite-insert-processor 'citar)
;   (org-cite-follow-processor 'citar)
;   (org-cite-activate-processor 'citar)
;   :general
;   (:keymaps 'org-mode-map
;    :prefix "C-c b"
;    "b" '(citar-insert-citation :wk "Insert citation")
;    "r" '(citar-insert-reference :wk "Insert reference")
;    "o" '(citar-open-notes :wk "Open note"))
;   :custom
;   (citar-notes-paths '("/Users/blaine/org-roam/citar-org-roam")) ; List of directories for reference nodes
;   (citar-open-note-function 'orb-citar-edit-note) ; Open notes in `org-roam'
;   (citar-at-point-function 'embark-act)           ; Use `embark'
;   )


(use-package citar-embark
  ;; get a table of options including opening related files and the entry in global.bib.
  :after citar embark
  :no-require
  :config (citar-embark-mode))

(use-package citar-org-roam
    :after (citar org-roam)
    :no-require
    :config (citar-org-roam-mode))

(message "Finished citar package configuration.")


(use-package codeium
   :load-path "/Users/blaine/e29org/manual-install/codeium.el/"
   :init
   ;; use globally
   (add-to-list 'completion-at-point-functions #'codeium-completion-at-point)
   ;; or on a hook
   ;; (add-hook 'python-mode-hook
   ;;     (lambda ()
   ;;         (setq-local completion-at-point-functions '(codeium-completion-at-point))))

   ;; if you want multiple completion backends, use cape (https://github.com/minad/cape):
   ;; (add-hook 'python-mode-hook
   ;;     (lambda ()
   ;;         (setq-local completion-at-point-functions
   ;;             (list (cape-super-capf #'codeium-completion-at-point #'lsp-completion-at-point)))))
   ;; an async company-backend is coming soon!

   ;; codeium-completion-at-point is autoloaded, but you can
   ;; optionally set a timer, which might speed up things as the
   ;; codeium local language server takes ~0.2s to start up
   ;; (add-hook 'emacs-startup-hook
   ;;  (lambda () (run-with-timer 0.1 nil #'codeium-init)))

   ;; :defer t ;; lazy loading, if you want
   
   :config
   (setq use-dialog-box nil) ;; do not use popup boxes

   ;; if you don't want to use customize to save the api-key
   ;; (setq codeium/metadata/api_key "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")

   ;; get codeium status in the modeline
   (setq codeium-mode-line-enable
       (lambda (api) (not (memq api '(CancelRequest Heartbeat AcceptCompletion)))))
   (add-to-list 'mode-line-format '(:eval (car-safe codeium-mode-line)) t)
   ;; alternatively for a more extensive mode-line
   ;; (add-to-list 'mode-line-format '(-50 "" codeium-mode-line) t)

   ;; use M-x codeium-diagnose to see apis/fields that would be sent to the local language server
   (setq codeium-api-enabled
       (lambda (api)
           (memq api '(GetCompletions Heartbeat CancelRequest GetAuthToken RegisterUser auth-redirect AcceptCompletion))))
   ;; you can also set a config for a single buffer like this:
   ;; (add-hook 'python-mode-hook
   ;;     (lambda ()
   ;;         (setq-local codeium/editor_options/tab_size 4)))

   ;; You can overwrite all the codeium configs!
   ;; for example, we recommend limiting the string sent to codeium for better performance
   (defun my-codeium/document/text ()
       (buffer-substring-no-properties (max (- (point) 3000) (point-min)) (min (+ (point) 1000) (point-max))))
   ;; if you change the text, you should also change the cursor_offset
   ;; warning: this is measured by UTF-8 encoded bytes
   (defun my-codeium/document/cursor_offset ()
       (codeium-utf8-byte-length
           (buffer-substring-no-properties (max (- (point) 3000) (point-min)) (point))))
   (setq codeium/document/text 'my-codeium/document/text)
   (setq codeium/document/cursor_offset 'my-codeium/document/cursor_offset)
   )
(message "Finished codeium package configuration")



(message "Started corfu package configuration")
;;;## Corfu configuration
(use-package corfu
  :ensure t
  :init
  (setq tab-always-indent 'complete)
  (global-corfu-mode)
  :config
  (setq corfu-auto t
        corfu-echo-documentation t
        corfu-scroll-margin 0
        corfu-count 8
        corfu-max-width 50
        corfu-min-width corfu-max-width
        corfu-auto-prefix 2)

  (corfu-history-mode 1)
  (savehist-mode 1)
  (add-to-list 'savehist-additional-variables 'corfu-history)

  (defun corfu-enable-always-in-minibuffer ()
    (setq-local corfu-auto nil)
    (corfu-mode 1))
  (add-hook 'minibuffer-setup-hook #'corfu-enable-always-in-minibuffer 1)
)
(message "Finished corfu package configuration")

;;;## Cape Configuration
(use-package cape
  :ensure t
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  ;; kinda confusing re length, WIP/TODO
  ;; :hook (org-mode . (lambda () (add-to-list 'completion-at-point-functions #'cape-dabbrev)))
  ;; :config
  ;; (setq dabbrev-check-other-buffers nil
  ;;       dabbrev-check-all-buffers nil
  ;;       cape-dabbrev-min-length 6)
  )


(use-package company-box
    :ensure t
    :config
    (setq company-box-max-candidates 50
          company-frontends '(company-tng-frontend company-box-frontend)
          company-box-icons-alist 'company-box-icons-all-the-icons))

(with-eval-after-load 'company
  (define-key company-active-map
              (kbd "TAB")
              #'company-complete-common-or-cycle)
  (define-key company-active-map
              (kbd "<backtab>")
              (lambda ()
                (interactive)
                (company-complete-common-or-cycle -1))))

(with-eval-after-load 'company
  (define-key company-active-map (kbd "M-.") #'company-show-location)
  (define-key company-active-map (kbd "RET") nil))


;;;## Company Configuration
;; Source: https://github.com/Exafunction/codeium.el
(use-package company
  :ensure t    
  :defer 0.1
  :hook ((emacs-lisp-mode . (lambda ()
                              (setq-local company-backends '(company-elisp))))
         (emacs-lisp-mode . company-mode))
  
  :config
  (global-company-mode t)
  (company-tng-configure-default) ; restore old tab behavior
  (setq-default
   company-idle-delay 0.05
   company-require-match nil
   company-minimum-prefix-length 1
   ;; get only preview
   ;; company-frontends '(company-preview-frontend)
   ;; also get a drop down
   company-frontends '(company-pseudo-tooltip-frontend company-preview-frontend)
   ))


;;;;;; Extra Completion Functions
(use-package consult
 :ensure t
 :after vertico
 :bind (("C-x b"       . consult-buffer)
        ("C-x C-k C-k" . consult-kmacro)
        ("C-x C-o"     . consult-outline)
        ("M-y"         . consult-yank-pop)
        ("M-g g"       . consult-goto-line)
        ("M-g M-g"     . consult-goto-line)
        ("M-g f"       . consult-flymake)
        ("M-g i"       . consult-imenu)
        ("M-s l"       . consult-line)
        ("M-s L"       . consult-line-multi)
        ("M-s u"       . consult-focus-lines)
        ("M-s g"       . consult-ripgrep)
        ("M-s M-g"     . consult-ripgrep)
        ("C-x C-SPC"   . consult-global-mark)
        ("C-x M-:"     . consult-complex-command)
;        ("C-c n"       . consult-org-agenda)
        ("C-c m"       . my/notegrep)
        :map help-map
        ("a" . consult-apropos)
        :map minibuffer-local-map
        ("M-r" . consult-history))
 :custom
 (completion-in-region-function #'consult-completion-in-region)
 :config
 (defun my/notegrep ()
   "Use interactive grepping to search my notes"
   (interactive)
   (consult-ripgrep org-directory))
 (recentf-mode t))
(use-package consult-dir
 :ensure t
 :bind (("C-x C-j" . consult-dir)
        ;; :map minibuffer-local-completion-map
        :map vertico-map
        ("C-x C-j" . consult-dir)))

(use-package consult-recoll
 :bind (("M-s r" . counsel-recoll)
        ("C-c I" . recoll-index))
 :init
 (setq consult-recoll-inline-snippets t)
 :config
 (defun recoll-index (&optional arg) (interactive)
   (start-process-shell-command "recollindex"
                                "*recoll-index-process*"
                                  "recollindex")))
(message "Finished package configurations C")


(message "Start package configurations D")

;;;# D
;; dashboard
(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook))
(setq dashboard-center-content t)
(setq dashboard--ascii-banner-centered t)
(setq dashboard-banner-logo-title "Loxo or selpercatinib. FDA-approved RET kinase inhibitor to treat non-small cell lung cancer in 2020.")
(use-package all-the-icons)
;;(insert (all-the-icons-icon-for-buffer))
(setq dashboard-center-content t)
(setq dashboard-image-banner-max-width 120)
(setq dashboard-image-banner-max-height 150)
(use-package page-break-lines)
(setq dashboard-set-heading-icons t)
(setq dashboard-set-file-icons t)
(setq dashboard-startup-banner "/Users/blaine/images/loxoSmall.png")
(setq dashboard-items '((recents  . 20)
                        (bookmarks . 50)
                        (projects . 250)
                        (registers . 5)))

;; (agenda . 15)
;; Set the title
;;(setq dashboard-banner-logo-title "Dashboard of Blaine Mooers")
;; Set the banner
;;(setq dashboard-startup-banner 'official)
;;(setq dashboard-startup-banner "/Users/blaine/Images/jmjd4alphaFOld1Aug30.png")
;; Value can be
;; 'official which displays the official emacs logo
;; 'logo which displays an alternative emacs logo
;; 1, 2 or 3 which displays one of the text banners
;; "path/to/your/image.gif", "path/to/your/image.png" or "path/to/your/text.txt" which displays whatever gif/image/text you would prefer

;; Content is not centered by default. To center, set
;;(setq dashboard-center-content t)

;; To disable shortcut "jump" indicators for each section, set
(setq dashboard-show-shortcuts nil)

; To show info about the packages loaded and the init time:
(setq dashboard-set-init-info t)

; To use it with counsel-projectile or persp-projectile
(setq dashboard-projects-switch-function 'projectile-persp-switch-project)

; To display today’s agenda items on the dashboard, add agenda to dashboard-items:
(add-to-list 'dashboard-items '(agenda) t)

; To show agenda for the upcoming seven days set the variable dashboard-week-agenda to t.
(setq dashboard-week-agenda t)



;; *** Dashboard refresh
;; 
;; Function to refresh dashboard and open in the current window.
;; This function is useful for accessing bookmarks and recent files created in the current session.
;; The last line in the code bloack defines a global key binding to F1.
;; 
;; Source of function by Jackson Benete Ferreira: the issues section of the [[https://github.com/emacs-dashboard/emacs-dashboard/issues/236][dashboard]] GitHub page.
;; I edited the documentation line to fix the grammar and add the final phrase.


(defun new-dashboard ()
  "Jump to the dashboard buffer. If it doesn't exist, create one. Refresh while at it."
  (interactive)
  (switch-to-buffer dashboard-buffer-name)
  (dashboard-mode)
  (dashboard-insert-startupify-lists)
  (dashboard-refresh-buffer))
(global-set-key (kbd "<f1>") 'new-dashboard)



(message "Finished package configurations D")



(message "Start package configurations E")
;;;# E

;;## ekg
;; https://github.com/ahyatt/ekg?tab=readme-ov-file
;; https://github.com/ahyatt/ekg/blob/develop/doc/ekg.org
;; https://github.com/ahyatt/llm
;; https://ollama.com/search?q=&c=embedding
;; https://ollama.com/library
(use-package ekg
  :bind (("C-c C-k" . ekg-capture))
  :init
  (require 'ekg-embedding)
  (ekg-embedding-generate-on-save)
  (require 'ekg-llm)
  (require 'llm-ollama)
  :config
  (require 'ekg-auto-save)
  (add-hook 'ekg-capture-mode-hook #'ekg-auto-save-mode)
  (add-hook 'ekg-edit-mode-hook #'ekg-auto-save-mode)
)
  ; (require 'llm-openai)  ;; The specific provider you are using must be loaded.
  ; (let ((my-provider (make-llm-openai :key "my-openai-api-key")))
  ;   (setq ekg-llm-provider my-provider
  ;         ekg-embedding-provider my-provider)))





;;## Embark
(use-package embark
  :ensure t
  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
   ("M-." . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init

  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  ;; Show the Embark target at point via Eldoc.  You may adjust the Eldoc
  ;; strategy, if you want to see the documentation from multiple providers.
  (add-hook 'eldoc-documentation-functions #'embark-eldoc-first-target)
  ;; (setq eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)

  :config

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; Consult users will also want the embark-consult package.
(use-package embark-consult
  :ensure t ; only need to install it, embark loads it after consult if found
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(message "Finished package configurations E")

(message "Started package configurations F")
(use-package flycheck
  :ensure t)


(message "Finished package configurations F")

(message "Started package configurations G")
;;;# G
(use-package general)







(message "Start H packages configurations")
; ;;;#
;; major-mode-hydra
;; source https://github.com/jerrypnz/major-mode-hydra.el
(use-package major-mode-hydra
  :bind
  ("s-SPC" . major-mode-hydra))


(major-mode-hydra-define emacs-lisp-mode nil
  ("Eval"
   (("b" eval-buffer "buffer")
    ("e" eval-defun "defun")
    ("r" eval-region "region"))
   "REPL"
   (("I" ielm "ielm"))
   "Test"
   (("t" ert "prompt")
    ("T" (ert t) "all")
    ("F" (ert :failed) "failed"))
   "Doc"
   (("d" describe-foo-at-point "thing-at-pt")
    ("f" describe-function "function")
    ("v" describe-variable "variable")
    ("i" info-lookup-symbol "info lookup"))))
    
(message "Finished hydra package configurations")  

(message "Finished H package configurations")     

;;*** helpful

(use-package helpful)

;; Note that the built-in `describe-function' includes both functions
;; and macros. `helpful-function' is functions only, so we provide
;; `helpful-callable' as a drop-in replacement.
(global-set-key (kbd "C-h f") #'helpful-callable)

(global-set-key (kbd "C-h v") #'helpful-variable)
(global-set-key (kbd "C-h k") #'helpful-key)
(global-set-key (kbd "C-h x") #'helpful-command)

;; Lookup the current symbol at point. C-c C-d is a common keybinding
;; for this in lisp modes.
(global-set-key (kbd "C-c C-d") #'helpful-at-point)

;; Look up *F*unctions (excludes macros).
;;
;; By default, C-h F is bound to `Info-goto-emacs-command-node'. Helpful
;; already links to the manual, if a function is referenced there.
(global-set-key (kbd "C-h F") #'helpful-function)

(setq counsel-describe-function-function #'helpful-callable)
(setq counsel-describe-variable-function #'helpful-variable)






(message "Start I packages configurations")
;;*** ivy
(use-package counsel)
(use-package ivy
  :diminish ivy-mode
  :config
  (setq ivy-extra-directories nil) ;; Hides . and .. directories
  (setq ivy-initial-inputs-alist nil) ;; Removes the ^ in ivy searches
  ; (if (eq jib/computer 'laptop)
  ;     (setq-default ivy-height 10)
  ;   (setq-default ivy-height 11))
  (setq ivy-fixed-height-minibuffer t)
  (add-to-list 'ivy-height-alist '(counsel-M-x . 7)) ;; Don't need so many lines for M-x, I usually know what command I want

  ;;(ivy-mode 1)

  ;; Shows a preview of the face in counsel-describe-face
  (add-to-list 'ivy-format-functions-alist '(counsel-describe-face . counsel--faces-format-function))

  :general
  (general-define-key
   ;; Also put in ivy-switch-buffer-map b/c otherwise switch buffer map overrides and C-k kills buffers
   :keymaps '(ivy-minibuffer-map ivy-switch-buffer-map)
   "S-SPC" 'nil
   "C-SPC" 'ivy-restrict-to-matches ;; Default is S-SPC, changed this b/c sometimes I accidentally hit S-SPC
   ;; C-j and C-k to move up/down in Ivy
   "C-k" 'ivy-previous-line
   "C-j" 'ivy-next-line)
  )


;;;; Nice icons in Ivy. Replaces all-the-icons-ivy.
;;(use-package all-the-icons-ivy-rich
;;  :init (all-the-icons-ivy-rich-mode 1)
;;  :config
;;  (setq all-the-icons-ivy-rich-icon-size 1.0))

;;
(use-package ivy-rich
  :after ivy
  :init
  (setq ivy-rich-path-style 'abbrev)
  (setcdr (assq t ivy-format-functions-alist) #'ivy-format-function-line)
  :config
  (ivy-rich-mode 1))


(use-package ivy-bibtex
    :init
    (setq bibtex-completion-notes-path "/Users/blaine/org-roam/references/notes/"
          bibtex-completion-library-path '("/Users/blaine/0papersLabeled/" "/Users/blaine/0booksLabeled/")
          bibtex-completion-notes-path "/Users/blaine/org-roam/references/notes/"
        bibtex-completion-notes-template-multiple-files "* ${author-or-editor}, ${title}, ${journal}, (${year}) :${=type=}: \n\nSee [[cite:&${=key=}]]\n"
        bibtex-completion-additional-search-fields '(keywords)
        bibtex-completion-display-formats
        '((article       . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} ${journal:40}")
          (inbook        . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} Chapter ${chapter:32}")
          (incollection  . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} ${booktitle:40}")
          (inproceedings . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} ${booktitle:40}")
          (t             . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*}"))
        bibtex-completion-pdf-open-function
        (lambda (fpath)
          (call-process "open" nil 0 nil fpath)))
)

(message "Finished I packages configurations")




(message "Started K packages configurations")
;;;## Kind-Icon Configuration
(use-package kind-icon
  :config
  (setq kind-icon-default-face 'corfu-default)
  (setq kind-icon-default-style '(:padding 0 :stroke 0 :margin 0 :radius 0 :height 0.9 :scale 1))
  (setq kind-icon-blend-frac 0.08)
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter)
  (add-hook 'counsel-load-theme #'(lambda () (interactive) (kind-icon-reset-cache)))
  (add-hook 'load-theme         #'(lambda () (interactive) (kind-icon-reset-cache))))

(message "Finished K packages configurations")


(message "Started L packages configurations")
(use-package llm
     :load-path "/Users/blaine/e29org/manual-install/llm.git/"
     :init
)

; (use-package lsp-mode
;     :ensure t
;     :bind (:map lsp-mode-map
;                 ("C-c d" . lsp-describe-thing-at-point)
;                 ("C-c a" . lsp-execute-code-action))
;     :bind-keymap ("C-c l" . lsp-command-map)
;     :config
;     (lsp-enable-which-key-integration t))
;     :init
;     (setq lsp-auto-guess-root nil)
;     :hook (python-mode . lsp)
;           (latex-mode . lsp)
;           (lsp-mode . lsp-enable-which-key-integration)
;     :commands lsp)
    
(use-package lsp-mode
  :ensure t
  :bind (:map lsp-mode-map
              ("C-c d" . lsp-describe-thing-at-point)
              ("C-c a" . lsp-execute-code-action))
  :bind-keymap ("C-c l" . lsp-command-map)
  :config
  (lsp-enable-which-key-integration t))
    
    
    
(use-package lsp-ui
    :ensure t
    :commands lsp-ui-mode)

(use-package lsp-grammarly
    :ensure t 
    :hook (text-mode . (lambda ()
                       (require 'lsp-grammarly)
                       (lsp))))  ; or lsp-deferred

    
(use-package lsp-jedi
    :ensure t)

(use-package lsp-latex
    :ensure t)

;; language-tool integration
(use-package lsp-ltex
    :ensure t
    :hook (text-mode . (lambda ()
                       (require 'lsp-ltex)
                       (lsp)))          ; or lsp-deferred
    :init
  (setq lsp-ltex-version "16.0.0"))  ; make sure you have set this, see below
    
        
(message "Finished L packages configurations")

(message "Start package configurations M")
;;;# M
;;;## Marginalia Configuration
(use-package marginalia
  :ensure t
  :config
  (marginalia-mode))
(customize-set-variable 'marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
(marginalia-mode 1)

; This has become too expensive.
;
; (use-package mathpix.el
;   :load-path "manual-install/mathpix.el/"
;   :custom ((mathpix-app-id "JJhSopoRYlQ2Dz169a")
;            (mathpix-app-key "8cae6b1e-25aa-4c2c-8c90-e74cf6e6004e"))
;   :bind
;   ("C-x m" . mathpix-screenshot))

(use-package math-preview
    :ensure t
    :custom (math-preview-command "/Users/blaine/.nvm/versions/node/v22.4.0/lib/node_modules/math-preview/math-preview.js"))


(message "Finished M package configurations.")


(message "Start package configurations O.")
;;;# O

;; Optionally use the `orderless' completion style.
(use-package orderless
  :ensure t
  :init
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (setq orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch)
  ;;       orderless-component-separator #'orderless-escapable-split-on-space)
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))


;;;; Org configurations

; This setting enables changing the width the image in org.
(setq org-image-actual-width nil)

;;;## BEGINNING of org-agenda
(define-key org-mode-map (kbd "M-i") 'org-insert-item)
(setq org-agenda-start-with-log-mode t)
(setq org-log-done 'time)
(setq org-log-into-drawer t)

(define-key global-map "\C-ca" 'org-agenda)
(setq org-log-done t)
;; org-capture
(define-key global-map "\C-cc" 'org-capture)
(define-key global-map "\C-cl" 'org-store-link)

(setq org-columns-default-format "%50ITEM(Task) %10CLOCKSUM %16TIMESTAMP_IA")

(setq org-agenda-files '("/Users/blaine/gtd/tasks/JournalArticles.org"
                         "/Users/blaine/gtd/tasks/potentialWriting.org"
                         "/Users/blaine/gtd/tasks/Proposals.org"
                         "/Users/blaine/gtd/tasks/Books.org"
                         "/Users/blaine/gtd/tasks/Talks.org"
                         "/Users/blaine/gtd/tasks/Posters.org"
                         "/Users/blaine/gtd/tasks/ManuscriptReviews.org"
                         "/Users/blaine/gtd/tasks/Private.org"
                         "/Users/blaine/gtd/tasks/Service.org"
                         "/Users/blaine/gtd/tasks/Teaching.org"
                         "/Users/blaine/gtd/tasks/Workshops.org"
                         "/Users/blaine/gtd/tasks/springsem24.org"
                         "/Users/blaine/gtd/tasks/summersem24.org"
                         "/Users/blaine/gtd/tasks/fallsem24.org"))
(message "Finished org-agenda configuration. Line 5139.")


;; Cycle through these keywords with shift right or left arrows.
(setq org-todo-keywords
        '((sequence "TODO(t)" "INITIATED(i!)" "WAITING(w!)" "CAL(a)" "SOMEDAY(s!)" "PROJ(j)" "|" "DONE(d!)" "CANCELLED(c!)")))

(setq org-refile-targets '(("/Users/blaine/gtd/tasks/JournalArticles.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/Proposals.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/Books.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/Talks.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/Posters.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/ManuscriptReviews.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/Private.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/Service.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/Teaching.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/grasscatcer.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/Workshops.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/december23.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/springsem24.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/summersem24.org" :maxlevel . 2)
   ("/Users/blaine/gtd/tasks/fallsem24.org" :maxlevel . 2)
   ))
(setq org-refile-use-outline-path 'file)
(message "Finished refile target configuration. Line 5162.")

;; ***** customized agenda views
;;
;; These are my customized agenda views by project.
;; The letter is the last parameter.
;; For example, enter ~C-c a b~ and then enter 402 at the prompt to list all active tasks related to 402 tasks.
;;
;; I learned about this approach [[https://tlestang.github.io/blog/keeping-track-of-tasks-and-projects-using-emacs-and-org-mode.html][here]].
;;
;; The CATEGORY keyword resides inside of a Properties drawer.
;; The drawers are usually closed.
;; I am having trouble opening my drawers in may org files.
;; In addition, I do not want to have to add a drawer to each TODO.
;;
;; I am loving Tags now.
;; I may switch to using Tags because they are visible in org files.
;; I tried and they are not leading to the expect list of TODOs in org-agenda.
;; I am stumped.
;;
;; In the meantime, enter ~C-c \~ inside JournalArticles.org to narrow the focus to the list of TODOs or enter ~C-c i b~ to get an indirect buffer.
;;

(setq org-agenda-custom-commands
      '(
    ("b"
             "List of all active 402 tasks."
             tags-todo
             "402\"/TODO|INITIATED|WAITING")
    ("c"
             "List of all active 523 RNA-drug crystallization review paper tasks."
             tags-todo
             "CATEGORY=\"523\"/TODO|INITIATED|WAITING")
    ("d"
             "List of all active 485PyMOLscGUI tasks."
             tags-todo
             "CATEGORY=\"485\"/TODO|INITIATED|WAITING")
    ("e"
             "List of all active 2104 Emacs tasks"
             tags-todo
             "2104+CATEGORY=\"2104\"/NEXT|TODO|INITIATED|WAITING")
    ("n"
             "List of all active 651 ENAX2 tasks"
             tags-todo
             "651+CATEGORY=\"651\"/NEXT|TODO|INITIATED|WAITING")
    ("q"
             "List of all active 561 charge density review"
             tags
             "561+CATEGORY=\"211\"/NEXT|TODO|INITIATED|WAITING")
    ("r"
             "List of all active 211 rcl/dnph tasks"
             tags-todo
             "211+CATEGORY=\"211\"/NEXT|TODO|INITIATED|WAITING")
    ("P"
         "List of all projects"
         tags
         "LEVEL=2/PROJ")))

(message "Finished org-agenda custum command configuration. Line 5220.")
;; I usually know the project to which I want to assign a task.
;; I loathe having to come back latter to refile my tasks.
;; I want to do the filing at the time of capture.
;; I found a solution [[https://stackoverflow.com/questions/9005843/interactively-enter-headline-under-which-to-place-an-entry-using-capture][here]].
;;
;; A project has two or more tasks.
;; I believe that the 10,000 projects is the upper limit for a 30 year academic career.
;; There are about 10,000 workdays in a 30 year career if you work six days a week.
;; Of course, most academics work seven a week and many work longer than 30 years, some even reach 60 years.
;;
;; I have my projects split into ten org files.
;; Each org file has a limit of 1000 projects for ease of scrolling.
;;
;; It is best to let Emacs insert new task because it is easy to accidently delete sectons in an org file, especially when sections are folded.
;; (I know that many love folded sections.
;; There is a strong appeal to being able to collapse secitons of text.
;; However, folded section are not for me; I have experienced too many catastrophes.
;; I open all of my org files with all sections fully open.
;; I can use swiper to navigate if I do not want to scroll.)
;; Enter ~C-c c~ to start the capture menu.
;; The settings below show a single letter option for selecting the appropriate org-file.
;; After entering the single-letter code, you are prompted for the headline name.
;; You do not have to include the TODO keyword.
;; However, I changed "Headline" to "Tag" because I have the project ID was one of the tags on the same line as the project headline.
;; I am now prompted for the tag.
;; After entering the tag, I fill out the task entry.
;; I then enter ~C-c C-c~ to save the capture.
;;
;;This protocol can be executed from inside the target org file or from a different buffer.
;;
;;I learned about the following function, which I modified by changing "Headline " to "Tag", from
;;[[https://stackoverflow.com/questions/9005843/interactively-enter-headline-under-which-to-place-an-entry-using-capture][Lionel Henry]] with the modification by Phil on July 1, 2018.
;;
(defun org-ask-location ()
  (let* ((org-refile-targets '((nil :maxlevel . 9)))
         (hd (condition-case nil
                 (car (org-refile-get-location "Tag" nil t))
               (error (car org-refile-history)))))
    (goto-char (point-min))
    (outline-next-heading)
    (if (re-search-forward
         (format org-complex-heading-regexp-format (regexp-quote hd))
         nil t)
        (goto-char (point-at-bol))
      (goto-char (point-max))
      (or (bolp) (insert "\n"))
      (insert "* " hd "\n")))
  (end-of-line))


(setq org-capture-templates
 '(
   ("j" "JournalArticles" entry
    (file+function "/Users/blaine/gtd/tasks/JournalArticles.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("g" "GrantProposals" entry
    (file+function "/Users/blaine/gtd/tasks/Proposals.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("b" "Books" entry
    (file+function "/Users/blaine/gtd/tasks/Books.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("t" "Talks" entry
    (file+function "/Users/blaine/gtd/tasks/Talks.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("p" "Posters" entry
    (file+function "/Users/blaine/gtd/tasks/Posters.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("r" "ManuscriptReviews" entry
    (file+function "/Users/blaine/gtd/tasks/ManuscriptReviews.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("v" "Private" entry
    (file+function "/Users/blaine/gtd/tasks/Private.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("S" "Service" entry
    (file+function "/Users/blaine/gtd/tasks/Service.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("T" "Teaching" entry
    (file+function "/Users/blaine/gtd/tasks/Teaching.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("w" "Workshop" entry
    (file+function "/Users/blaine/gtd/tasks/Workshops.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("d" "December" entry
    (file+function "/Users/blaine/gtd/tasks/december23.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("s" "springsem24" entry
    (file+function "/Users/blaine/gtd/tasks/springsem24.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("u" "springsem24" entry
    (file+function "/Users/blaine/gtd/tasks/summersem24.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("f" "fallsem24" entry
    (file+function "/Users/blaine/gtd/tasks/fallsem24.org" org-ask-location)
    "\n\n*** TODO %?\n<%<%Y-%m-%d %a %T>>"
    :empty-lines 1)
    ("x" "Slipbox" entry  (file "/User/org-roam/inbox.org")
           "* %?\n")
    ))
(defun jethro/org-capture-slipbox ()
    (interactive)
    (org-capture nil "s"))


(message "Finished org-agenda configuration. Line 1432.")
;; <<<<<<< END of org-agenda >>>>>>>>>>>>>>

;; https://github.com/shg/ob-julia-vterm.el
;;(add-to-list 'org-babel-load-languages '(julia-vterm . t))


;;;### org-ai

; (use-package org-ai
;   :load-path "/Users/blaine/emacs29.3/manual-packages/org-ai/"
;   :commands (org-ai-mode
;              org-ai-global-mode)
;   :init
;   (add-hook 'org-mode-hook #'org-ai-mode) ; enable org-ai in org-mode
;   (org-ai-global-mode) ; installs global keybindings on C-c M-a
;   :config
;   (setq org-ai-default-chat-model "gpt-4") ; if you are on the gpt-4 beta:
;   (org-ai-install-yasnippets)) ; if you are using yasnippet and want `ai` snippets

(message "Started org-babel configuration. Line 1452.")
;;;### org-babel
(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (shell . t)
   (c . nil)
   (cpp . nil)
   (clojure . t)
   (F90 . nil)
   (gnuplot . t)
   (js . nil)
   (ditaa . nil)
   (java . t)
   (mathematica . nil)
   (plantuml . nil)
   (lisp . t)
   (org . t)
   (julia . t)
   (python . t)
   (R . t)
   (jupyter . t))
)

;;  Removed  (jupyter . t) on May 14 due to an error message.
;;    (jupyter . t))
;; By default, you need to specify julia-vterm as the language name for source blocks. 
;; To use julia as the language name, define the following aliases.

;; (defalias 'org-babel-execute:julia 'org-babel-execute:julia-vterm)
;; (defalias 'org-babel-variable-assignments:julia 'org-babel-variable-assignments:julia-vterm)
(message "Finished org-babel configuration. Line 1496.")

;;*** org-cc 
;; Context clues
;; source  https://github.com/durableOne/org-cc
(add-to-list 'load-path "/Users/blaine/emacs29.3/manual-packages/org-cc")
(use-package org-cc
  :ensure nil
  :after org
  :custom
  (org-cc-directory (concat org-directory "org-cc")) ;; subdirectory of the heading's attachment directory
  (org-cc-days 14)
  :init
  (add-hook 'org-clock-in-hook #'org-cc-display-notes)
)
(global-set-key (kbd "C-c k") 'org-cc-edit-cc-file)
(global-set-key (kbd "C-c x") 'org-cc-display-notes)

(message "Finished org-cc. Line 15--.")
;; org-caputre templates

(setq org-capture-templates
     '(("r" "Record"
 plain
 (file "/Users/blaine/org/notes.org")
 "* %^{Title}  :%^{Tags}:\n%U%i\n%?\n")))

(global-set-key (kbd "C-c t") 'org-tags-view)
(message "Finished org-capture configuration. Line 1526.")


; (use-package org-gtd
;   :after org
;   :quelpa (org-gtd :fetcher github :repo "trevoke/org-gtd.el"
;                    :commit "3.0.0" :upgrade t)
;   :demand t
;   :custom
;   (org-gtd-directory "~/org-gtd")
;   (org-edna-use-inheritance t)
;   (org-gtd-organize-hooks '(org-gtd-set-area-of-focus org-set-tags-command))
;   :config
;   (org-edna-mode)
;   :bind
;   (("C-c d c" . org-gtd-capture)
;    ("C-c d e" . org-gtd-engage)
;    ("C-c d p" . org-gtd-process-inbox)
;    :map org-gtd-clarify-map
;    ("C-c c" . org-gtd-organize)))


(message "Started org-noter configuration. Line 1530.")
(use-package org-noter)
;;*** Org-pdf-noter
;; This commented out config sort of worked.
(use-package org-noter
  :after org
  :config
  ;; Your org-noter config ........
  :config
  (setq
    org_notes (concat (getenv "HOME") "/org-roam/")
    zot_bib (concat (getenv "HOME") "/Documents/global.bib")
    org-directory org_notes
    deft-directory org_notes
    org-roam-directory org_notes
    ;; keep an empty line between headings and content in Org file
    org-noter-separate-notes-from-heading t)
  (require 'org-noter-pdftools))

(use-package org-pdftools
  :hook (org-mode . org-pdftools-setup-link))


(use-package org-noter-pdftools
  :after org-noter
  :config
  ;; Add a function to ensure precise note is inserted
  (defun org-noter-pdftools-insert-precise-note (&optional toggle-no-questions)
    (interactive "P")
    (org-noter--with-valid-session
     (let ((org-noter-insert-note-no-questions (if toggle-no-questions
                                                   (not org-noter-insert-note-no-questions)
                                                 org-noter-insert-note-no-questions))
           (org-pdftools-use-isearch-link t)
           (org-pdftools-use-freepointer-annot t))
       (org-noter-insert-note (org-noter--get-precise-info)))))

  ;; fix https://github.com/weirdNox/org-noter/pull/93/commits/f8349ae7575e599f375de1be6be2d0d5de4e6cbf
  (defun org-noter-set-start-location (&optional arg)
    "When opening a session with this document, go to the current location.
With a prefix ARG, remove start location."
    (interactive "P")
    (org-noter--with-valid-session
     (let ((inhibit-read-only t)
           (ast (org-noter--parse-root))
           (location (org-noter--doc-approx-location (when (called-interactively-p 'any) 'interactive))))
       (with-current-buffer (org-noter--session-notes-buffer session)
         (org-with-wide-buffer
          (goto-char (org-element-property :begin ast))
          (if arg
              (org-entry-delete nil org-noter-property-note-location)
            (org-entry-put nil org-noter-property-note-location
                           (org-noter--pretty-print-location location))))))))
  (with-eval-after-load 'pdf-annot
    (add-hook 'pdf-annot-activate-handler-functions #'org-noter-pdftools-jump-to-note)))

(use-package pdf-tools-org-noter-helpers
  :pin manual
  :load-path "/Users/blaine/emacs29.3/manual-packages/pdf-tools-org-noter-helpers/")


;;*** org-pomodoro
;; (shell-command-to-string "open -a tomighty.app")
(use-package org-pomodoro
    :commands  (org-pomodoro)
    :config
    (setq alert-user-configuration (quote ((((:category . "org-pomodoro")) libnotify nil)))))

;; add hook to enable automated start of the next pom after a break.
;; Source: https://github.com/marcinkoziej/org-pomodoro/issues/32
;; (add-hook 'org-pomodoro-break-finished-hook
;;           (lambda ()
;;             (interactive)
;;             (point-to-register 1)
;;             (org-clock-goto)
;;             (org-pomodoro '(25))
;;             (register-to-point 1)
;;             (shell-command-to-string "open -a tomighty.app")
;;             ))

(use-package sound-wav)
(setq org-pomodoro-ticking-sound-p nil)
(setq org-pomodoro-ticking-sound-states '(:pomodoro :short-break :long-break))
(setq org-pomodoro-ticking-sound-states '(:pomodoro))
(setq org-pomodoro-ticking-frequency 1)
(setq org-pomodoro-audio-player "mplayer")
(setq org-pomodoro-finished-sound-args "-volume 0.9")
(setq org-pomodoro-long-break-sound-args "-volume 0.9")
(setq org-pomodoro-short-break-sound-args "-volume 0.9")
(setq org-pomodoro-ticking-sound-args "-volume 0.3")

(global-set-key (kbd "C-c o") 'org-pomodoro)
(message "Finished org-pomodoros configuration. Line 1607.")


; (message "Start org-ref configuration. Line 1610.")
; ;; John Kitchin's config on YouTube https://www.youtube.com/watch?v=3u6eTSzHT6s
; ; (use-package ivy-bibtex
; ;     :init
; ;     (setq bibtex-completion-notes-path "/Users/blaine/org-roam/references/notes/"
; ;         bibtex-completion-notes-template-multiple-files "* ${author-or-editor}, ${title}, ${journal}, (${year}) :${=type=}: \n\nSee [[cite:&${=key=}]]\n"
; ;         bibtex-completion-additional-search-fields '(keywords)
; ;         bibtex-completion-display-formats
; ;         '((article       . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} ${journal:40}")
; ;           (inbook        . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} Chapter ${chapter:32}")
; ;           (incollection  . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} ${booktitle:40}")
; ;           (inproceedings . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} ${booktitle:40}")
; ;           (t             . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*}"))
; ;         bibtex-completion-pdf-open-function
; ;         (lambda (fpath)
; ;           (call-process "open" nil 0 nil fpath)))
; ; )


;; org-ref
;; Set the case of the Author and Title to Capitalize with customize.
(use-package org-ref
     :init
    (use-package bibtex)
    (setq bibtex-autokey-year-length 4
          bibtex-autokey-name-year-separator ""
          bibtex-autokey-year-title-separator ""
          bibtex-autokey-titleword-separator ""
          bibtex-autokey-titlewords 9
          bibtex-autokey-titlewords-stretch 9
          bibtex-autokey-titleword-length 15)
    ;; H is the hyper key. I have bound H to Fn. For the MacAlly keyboard, it is bound to right-command.
    (define-key bibtex-mode-map (kbd "H-b") 'org-ref-bibtex-hydra/body)
    ;; (use-package org-ref-ivy)
    (setq org-ref-insert-link-function 'org-ref-insert-link-hydra/body
                org-ref-insert-cite-function 'org-ref-cite-insert-ivy
                org-ref-insert-label-function 'org-ref-insert-label-link
                org-ref-insert-ref-function 'org-ref-insert-ref-link
                org-ref-cite-onclick-function (lambda (_) (org-ref-citation-hydra/body)))
    ; (use-package org-ref-arxiv)
    ; (use-package org-ref-pubmed)
    ; (use-package org-ref-wos)
)


(message "Start bibtex-completion-bibliography configuration of org-ref. Line 1656.")

(setq bibtex-completion-bibliography '("/Users/blaine/Documents/global.bib")
    bibtex-completion-library-path '("/Users/blaine/0papersLabeled/" "/Users/blaine/0booksLabeled/")
    bibtex-completion-notes-path "/Users/blaine/org-roam/references/notes/"
    bibtex-completion-notes-template-multiple-files "* ${author-or-editor}, ${title}, ${journal}, (${year}) :${=type=}: \n\nSee [[cite:&${=key=}]]\n"
    bibtex-completion-additional-search-fields '(keywords)
    bibtex-completion-display-formats
    '((article       . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} ${journal:40}")
      (inbook        . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} Chapter ${chapter:32}")
      (incollection  . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} ${booktitle:40}")
      (inproceedings . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*} ${booktitle:40}")
      (t             . "${=has-pdf=:1}${=has-note=:1} ${year:4} ${author:36} ${title:*}"))
    bibtex-completion-pdf-open-function
    (lambda (fpath)
      (call-process "open" nil 0 nil fpath)))

(setq bibtex-autokey-year-length 4
      bibtex-autokey-name-year-separator "-"
      bibtex-autokey-year-title-separator "-"
      bibtex-autokey-titleword-separator "-"
      bibtex-autokey-titlewords 2
      bibtex-autokey-titlewords-stretch 1
      bibtex-autokey-titleword-length 5)
(message "Finished bibtex-completion-bibliography configuration of org-ref. Line 1691.")

;; H is the hyper key. I have bound H to Fn. For the MacAlly keyboard, it is bound to right-command.
(define-key bibtex-mode-map (kbd "s-b") 'org-ref-bibtex-hydra/body)
(define-key org-mode-map (kbd "s-i") org-ref-insert-cite-function)
(define-key org-mode-map (kbd "s-r") org-ref-insert-ref-function)
(define-key org-mode-map (kbd "H-l") org-ref-insert-label-function)
(define-key org-mode-map (kbd "H-d") 'doi-add-bibtex-entry)

;; to use org-cite-insert
(setq org-ref-insert-cite-function
      (lambda ()
     (org-cite-insert nil)))

;; <<<<<<< END org-ref >>>>>>>>>>>>>>
(message "Finished org-cite configurations")




(message "Start org-roam configurations")
;; <<<<<<< BEGIN org-roam >>>>>>>>>>>>>>

;; ** Basic org-roam config
(use-package org-roam
   :custom
   (org-roam-directory (file-truename "/Users/blaine/org-roam/"))
   :bind (("C-c n l" . org-roam-buffer-toggle)
          ("C-c n f" . org-roam-node-find)
          ("C-c n g" . org-roam-graph)
          ("C-c n i" . org-roam-node-insert)
          ("C-c n c" . #'org-id-get-create)
          ;; Dailies
          ("C-c n j" . org-roam-dailies-capture-today))
   :config
   ;; If you're using a vertical completion framework, you might want a more informative completion interface
   (setq org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))
   (org-roam-db-autosync-mode))
   ;;(org-roam-ui-mode))
   ;; If using org-roam-protocol
   ;;(use-package org-roam-protocol))


;; Following https://jethrokuan.github.io/org-roam-guide/
(message "Start org-roam-capture template configurations, line 1721")

(setq org-roam-capture-templates
      '(("p" "permanent" plain
         "%?"
         :if-new (file+head "main/${slug}.org" "#+title: ${title}\n\n* Note type: permanent\n\n* References\n\n* Backlinks\n\n#+created_at: %U\n#+last_modified: %U\n")
         :immediate-finish t
         :unnarrowed t)
         ;; citar literature note
        ; ("n" "literature note" plain
        ;  "%?"
        ;  :target (file+head "%(expand-file-name (or citar-org-roam-subdir \"\") org-roam-directory)/${citar-citekey}.org"
        ;             "#+title: ${citar-citekey}.\n Article title: ${note-title}.\n Year: ${citar-year} \n  Keywords: ${citar-keywords} \n Note type: literature\n\n\n#+created: %U\n#+last_modified: %U\n\n")
        ;           :unnarrowed t)
        ("r" "reference" plain "%?"
         :if-new
         (file+head "reference/${title}.org" "#+title: ${title}\n\n\n\n\n* References\n\n* Backlinks\n\n#+created_at: %U\n#+last_modified: %U\n")
         :immediate-finish t
         :unnarrowed t)
         ("l" "clipboard" plain #'org-roam-capture--get-point "%i%a"
         :file-name "%<%Y%m%d%H%M%S>-${slug}"
         :head "#+title: ${title}\n#+created: %u\n#+last_modified: %U\n#+ROAM_TAGS: %?"
         :unnarrowed t
         :prepend t
         :jump-to-captured t)
         ;; Vidianos G's config with ivy-bibtex
         ("v" "bibliography reference" plain
             "%?"
             : if-new
             (file+head "ref/${citekey}.org" "#+title: ${title}\n
              ,#+filetags: ${entry-type}
         - keywords :: ${keywords}
         - tags ::

         ,* Analysis of ${entry-type} by ${author}



         * References\n\n* Backlinks\n\n#+created_at: %U\n#+last_modified: %U\n
         :PROPERTIES:
         :URL: ${Url}
         :NOTER_DOCUMENT: ${file}
         :NOTER_PAGE:
         :END:")
             :unnarrowed t
             :jump-to-captured t)
        ("b" "bibliography notes" plain             ; Org-noter integration
          (file "~/org-roam/references/notes/notes-template.org")
                 :target (file+head "references/notes/${citekey}.org"
                 "#+title: ${title}\n :article:\n\n\n\n\n* References\n\n* Backlinks\n\n#+created_at: %U\n#+last_modified: %U\n")
                  :empty-lines 1)
        ("a" "article" plain "%?"
         :if-new
         (file+head "articles/${title}.org" "#+title: ${title}\n :article:\n\n\n\n\n* References\n\n* Backlinks\n\n#+created_at: %U\n#+last_modified: %U\n")
         :immediate-finish t
         :unnarrowed t)))

(setq org-roam-node-display-template
    (concat "${type:15} ${title:*} " (propertize "${tags:10}" 'face 'org-tag)))


;; Writing technical documents requires us to write in paragraphs,
;; whereas org mode by default is intended to be used as an outliner,
;; to get around this problem, setting up org-export to preserve line breaks is useful
;; (setq org-export-preserve-breaks t)
(message "End org-roam package configurations, line 1785")


;; Place point on link to image. Left-click to display image in another buffer. Enter C-c t to display the code of the link for easy editing.
;; Place point on equation. Enter C-c t to render it with MathJax. Left click on the rendered equation to switch back to the code.
;; Put multiline code from mathpix between double dollar signs and treat as being on one line.
;; This trick does not work with the equation environment compressed to one line. You have to use M-x math-preview-region.
;; I modified this from https://emacs.stackexchange.com/questions/59151/how-can-i-switch-a-preview-image-in-an-org-mode-buffer-to-its-source-block
;; 
;; I ran out of time to time out how to render an active region. I need to find the analog of the latex-fragment:
;; ('latex-???? (math-preview-region))
;; ???? has to be some kind of an org-element-type. org-latex-section does not work.
;; This would enable using this application of the math-preview-region to render equation environments.


(defun bhmm/toggle-state-at-point ()
  (interactive)
  (let ((ctx (org-element-context)))
    (pcase (org-element-type ctx)
      ('link           (org-toggle-link-display))
      ('latex-fragment (math-preview-at-point)))))

(define-key org-mode-map (kbd "C-c t") #'bhmm/toggle-state-at-point)

(message "End toggle-state-at-point for use with images and equations.")


(message "End package configurations O")


(message "Start package configurations P")
;;;# P
(use-package pdf-tools
 :pin manual ;; manually update
 :config
 ;; initialise
 (pdf-tools-install)
 ;; open pdfs scaled to fit width
 (setq-default pdf-view-display-size 'fit-width)
 ;; use normal isearch
 (define-key pdf-view-mode-map (kbd "C-s") 'isearch-forward)
 :custom
 (pdf-annot-activate-created-annotations t "automatically annotate highlights"))

 ;; per frame workspaces like on the Macs spaces
(use-package perspective
  :ensure t    
  :bind
  ("C-x C-b" . persp-list-buffers)         ; or use a nicer switcher, see below
  :custom
  (persp-mode-prefix-key (kbd "C-c M-p"))  ; pick your own prefix key here
  :init
  (persp-mode))
(message "End package configurations P")


(message "Start package configurations S")
;;;# S
;;*** serenade (source: https://github.com/justin-roche/serenade-mode)
(use-package serenade-mode
  :load-path "/Users/blaine/e29org/manual-install/serenade-mode/")

(setq serenade-completion-frontend 'helm)
(setq serenade-helm-M-x t)
(setq serenade-snippet-engine 'yasnippet)

(message "End package configurations S")


(message "Start package configurations T")

;; C-x t t to launch treemacs
;; Support dragging files from the treemacs directory to a buffer to open them.
;; Default configuration for treemacs minus the treemacs-evil pacakge.
;; 
(use-package treemacs
  :ensure t
  :defer t
  :init
  (with-eval-after-load 'winum
    (define-key winum-keymap (kbd "M-0") #'treemacs-select-window))
  :config
  (progn
    (setq treemacs-collapse-dirs                   (if treemacs-python-executable 3 0)
          treemacs-deferred-git-apply-delay        0.5
          treemacs-directory-name-transformer      #'identity
          treemacs-display-in-side-window          t
          treemacs-eldoc-display                   'simple
          treemacs-file-event-delay                2000
          treemacs-file-extension-regex            treemacs-last-period-regex-value
          treemacs-file-follow-delay               0.2
          treemacs-file-name-transformer           #'identity
          treemacs-follow-after-init               t
          treemacs-expand-after-init               t
          treemacs-find-workspace-method           'find-for-file-or-pick-first
          treemacs-git-command-pipe                ""
          treemacs-goto-tag-strategy               'refetch-index
          treemacs-header-scroll-indicators        '(nil . "^^^^^^")
          treemacs-hide-dot-git-directory          t
          treemacs-indentation                     2
          treemacs-indentation-string              " "
          treemacs-is-never-other-window           nil
          treemacs-max-git-entries                 5000
          treemacs-missing-project-action          'ask
          treemacs-move-files-by-mouse-dragging    t
          treemacs-move-forward-on-expand          nil
          treemacs-no-png-images                   nil
          treemacs-no-delete-other-windows         t
          treemacs-project-follow-cleanup          nil
          treemacs-persist-file                    (expand-file-name ".cache/treemacs-persist" user-emacs-directory)
          treemacs-position                        'left
          treemacs-read-string-input               'from-child-frame
          treemacs-recenter-distance               0.1
          treemacs-recenter-after-file-follow      nil
          treemacs-recenter-after-tag-follow       nil
          treemacs-recenter-after-project-jump     'always
          treemacs-recenter-after-project-expand   'on-distance
          treemacs-litter-directories              '("/node_modules" "/.venv" "/.cask")
          treemacs-project-follow-into-home        nil
          treemacs-show-cursor                     nil
          treemacs-show-hidden-files               t
          treemacs-silent-filewatch                nil
          treemacs-silent-refresh                  nil
          treemacs-sorting                         'alphabetic-asc
          treemacs-select-when-already-in-treemacs 'move-back
          treemacs-space-between-root-nodes        t
          treemacs-tag-follow-cleanup              t
          treemacs-tag-follow-delay                1.5
          treemacs-text-scale                      nil
          treemacs-user-mode-line-format           nil
          treemacs-user-header-line-format         nil
          treemacs-wide-toggle-width               70
          treemacs-width                           35
          treemacs-width-increment                 1
          treemacs-width-is-initially-locked       t
          treemacs-workspace-switch-cleanup        nil)

    ;; The default width and height of the icons is 22 pixels. If you are
    ;; using a Hi-DPI display, uncomment this to double the icon size.
    ;;(treemacs-resize-icons 44)

    (treemacs-follow-mode t)
    (treemacs-filewatch-mode t)
    (treemacs-fringe-indicator-mode 'always)
    (when treemacs-python-executable
      (treemacs-git-commit-diff-mode t))

    (pcase (cons (not (null (executable-find "git")))
                 (not (null treemacs-python-executable)))
      (`(t . t)
       (treemacs-git-mode 'deferred))
      (`(t . _)
       (treemacs-git-mode 'simple)))

    (treemacs-hide-gitignored-files-mode nil))
  :bind
  (:map global-map
        ("M-0"       . treemacs-select-window)
        ("C-x t 1"   . treemacs-delete-other-windows)
        ("C-x t t"   . treemacs)
        ("C-x t d"   . treemacs-select-directory)
        ("C-x t B"   . treemacs-bookmark)
        ("C-x t C-t" . treemacs-find-file)
        ("C-x t M-t" . treemacs-find-tag)))

(use-package treemacs-projectile
  :after (treemacs projectile)
  :ensure t)

(use-package treemacs-icons-dired
  :hook (dired-mode . treemacs-icons-dired-enable-once)
  :ensure t)

; (use-package treemacs-magit
;   :after (treemacs magit)
;   :ensure t)

(use-package treemacs-persp ;;treemacs-perspective if you use perspective.el vs. persp-mode
  :after (treemacs persp-mode) ;;or perspective vs. persp-mode
  :ensure t
  :config (treemacs-set-scope-type 'Perspectives))

; (use-package treemacs-tab-bar ;;treemacs-tab-bar if you use tab-bar-mode
;   :after (treemacs)
;   :ensure t
;   :config (treemacs-set-scope-type 'Tabs))

(treemacs-start-on-boot)




(use-package triples
  :load-path "/Users/blaine/e29org/manual-install/triples/")

(message "End package configurations T")


(message "Start package configurations U")

(use-package undo-tree
  :ensure t
  :config
  (global-undo-tree-mode 1))
  
(message "End package configurations U")


(message "Start package configurations V")
;;;# V
;;;## Vertico Configuration
(use-package vertico
  :ensure t
  :init
  (vertico-mode)

  ;; Different scroll margin
  ;; (setq vertico-scroll-margin 0)

  ;; Show more candidates
  (setq vertico-count 20)

  ;; Grow and shrink the Vertico minibuffer
  (setq vertico-resize t)

  ;; Optionally enable cycling for `vertico-next' and `vertico-previous'.
  (setq vertico-cycle t)
  )

;; Persist history over Emacs restarts. Vertico sorts by history position.
(use-package savehist
  :ensure t
  :init
  (savehist-mode))

;; A few more useful configurations...
(use-package emacs
  :ensure t
  :init
  ;; Add prompt indicator to `completing-read-multiple'.
  ;; We display [CRM<separator>], e.g., [CRM,] if the separator is a comma.
  (defun crm-indicator (args)
    (cons (format "[CRM%s] %s"
                  (replace-regexp-in-string
                   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                   crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

  ;; Emacs 28: Hide commands in M-x which do not work in the current mode.
  ;; Vertico commands are hidden in normal buffers.
  ;; (setq read-extended-command-predicate
  ;;       #'command-completion-default-include-p)

  ;; Enable recursive minibuffers
  (setq enable-recursive-minibuffers t))
  
  
(message "Start package configurations W")
;;;## which-key
(use-package which-key
  :ensure t    
  :init
  :defer 0
  :diminish which-key-mode
  :config
  (which-key-mode)
  (setq which-key-idle-delay 0.3))
;;   (add-hook 'c-mode-hook 'lsp)
;; (add-hook 'c++-mode-hook 'lsp)
(add-hook 'clojure-mode-hook 'lsp)
;; (add-hook 'julia-mode-hook 'lsp)
(add-hook 'latex-mode-hook 'lsp)
(add-hook 'python-mode-hook 'lsp)
;; (add-hook 'R-mode-hook 'lsp)
(which-key-setup-side-window-right-bottom)


(message "End package configurations W")

(message "Start package configurations Y")

(use-package yasnippet
  :config
  (yas-global-mode 1))
(global-set-key "\C-o" 'yas-expand)
(global-set-key "\C-c y i" 'yas-insert-snippet)
(global-set-key "\C-c y n" 'yas-new-snippet)


;;;### my-hydras
;; load hydras
;;(use-package talon-quiz-hydra
;;  :load-path "~/emacs29.3/my-hydras/")
;;(global-set-key (kbd "C-c 9") 'talon-quiz-hydra/body)

(use-package writing-projects-hydra
  :load-path "~/emacs29.3/my-hydras/")
(global-set-key (kbd "C-c 9") 'writing-projects-hydra/body)

(use-package learning-packages-and-modes-hydras
  :load-path "~/emacs29.3/my-hydras/")
(global-set-key (kbd "C-c 2") 'learning-packages-and-modes-hydras/body)

(use-package learning-spiral-hydras
  :load-path "~/emacs29.3/my-hydras/")
(global-set-key (kbd "C-c 1") 'hydra-of-learning-spiral/body)

(use-package my-hydras
  :load-path "~/emacs29.3/my-hydras/")
(global-set-key (kbd "C-c 0") 'hydra-of-hydras/body)



;; A cool hydra for finding snippets at point. Invoke with C-c y.
(use-package hydra
  :defer 2
  :bind ("C-c y" . hydra-yasnippet/body))

(use-package popup)
;; add some shotcuts in popup menu mode
(define-key popup-menu-keymap (kbd "M-n") 'popup-next)
(define-key popup-menu-keymap (kbd "TAB") 'popup-next)
(define-key popup-menu-keymap (kbd "<tab>") 'popup-next)
(define-key popup-menu-keymap (kbd "<backtab>") 'popup-previous)
(define-key popup-menu-keymap (kbd "M-p") 'popup-previous)

(defun yas/popup-isearch-prompt (prompt choices &optional display-fn)
  (when (featurep 'popup)
    (popup-menu*
     (mapcar
      (lambda (choice)
        (popup-make-item
         (or (and display-fn (funcall display-fn choice))
             choice)
         :value choice))
      choices)
     :prompt prompt
     ;; start isearch mode immediately
     :isearch t
     )))
(setq yas/prompt-functions '(yas/popup-isearch-prompt yas/no-prompt))

(use-package license-snippets
    :load-path "/Users/blaine/emacs29.3/manual-packages/license-snippets")
(license-snippets-init)
(message "Fnished Y package configurations!!")


(message "Fnished package configurations!!")
(put 'downcase-region 'disabled nil)
