(provide 'local-ess)

(use-package ess)
(require 'ess-r-mode)
(defun R-remote (&optional remote-host session directory)
  "Connect to the remote-host's dtach session running R."
  (interactive (list
                (read-from-minibuffer "R remote host: " R-remote-host)
                (read-from-minibuffer "R remote session: " R-remote-session)
                (read-from-minibuffer "R remote directory: " R-remote-directory)))
  (pop-to-buffer (make-comint (concat "remote-" session)
                              "ssh" nil "-Y" "-C" "-t" remote-host
                              "cd" directory ";"
                              "dtach" "-A" (concat ".dtach-" session)
                              "-z" "-E" "-r" "none"
                              "R" "--no-readline"
                              inferior-R-args))
  (ess-remote (process-name (get-buffer-process (current-buffer))) "R")
  (setq comint-process-echoes t))
(defvar R-remote-host "lia@ibm")
(defvar R-remote-session "R-session")
(defvar R-remote-directory "/home/lia/p/sme")


(setq company-dabbrev-downcase nil)
(setq ess-default-style 'RStudio)
;; these next two lines are supposed to do the same thing
(define-key ess-mode-map ";" 'ess-insert-assign)
(define-key inferior-ess-mode-map ";" 'ess-insert-assign)
(define-key ess-mode-map "_" nil)
(define-key inferior-ess-mode-map "_" nil)
(define-key ess-mode-map "\\" 'ess-insert-pipe)
(define-key inferior-ess-mode-map "\\" 'ess-insert-pipe)


(setq ess-eval-visibly 'nowait) 
(setq ess-tab-complete-in-script t)



(use-package polymode
  ;; R-SQL polymode, from https://www.masteringemacs.org/article/polymode-multiple-major-modes-how-to-use-sql-python-in-one-buffer
  :ensure t
  :mode ("\.R$" . poly-R-sql-mode)
  :config
  (setq polymode-prefix-key (kbd "C-c n"))
  (define-hostmode poly-R-hostmode :mode 'R-mode)
  (define-innermode poly-sql-expr-R-innermode
    :mode 'sql-mode
    :head-matcher (rx "\"--sql")
    :tail-matcher (rx "\"")
    :head-mode 'host
    :tail-mode 'host)
  (defun poly-R-sql-eval-chunk (beg end msg)
    "Calls out to `sql-send-region' with the polymode chunk region"
    (sql-send-region beg end))

  (define-polymode poly-R-sql-mode
    :hostmode 'poly-R-hostmode
    :innermodes '(poly-sql-expr-R-innermode)
    (setq polymode-eval-region-function #'poly-R-sql-eval-chunk)))


(setq ess-pipe-list '(" %>% "))

(defun ess-insert-pipe (arg)
  "Insert the first element of `ess-pipe-list' unless in string or comment.
If the character before point is the first element of
`ess-pipe-list', replace it with the last character typed.

If `ess-language' is not \"S\", call `self-insert-command' with ARG."
  (interactive "p")
  (if (string= ess-language "S")
      (let* ((pipe (car ess-pipe-list))
             (event (event-basic-type last-input-event))
             (char (ignore-errors (format "%c" event))))
        (cond ((and char (ess-inside-string-or-comment-p))
               (insert char))
              ((re-search-backward pipe (- (point) (length pipe)) t)
               (if (and char (numberp event))
                   (replace-match char t t)
                 (replace-match "")))
              (t (delete-horizontal-space) 
                 (insert pipe))))
    (funcall #'self-insert-command arg)))

