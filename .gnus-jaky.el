;;; .gnus.el -- Laptop


;;; Code:

;;; Search engine for imap and gmane (hit `G G' in group buffer)
;;
(require 'nnir)

;;; Gnus methods
;;
;;
;; Default method
(setq gnus-select-method '(nntp "news.gmane.org"
                           (nnir-search-engine gmane)))

;;; To add a mail account:
;;
;;  1) Add an nnimap entry in `gnus-secondary-select-methods'.
;;  2) Add an entry in `gnus-posting-styles'
;;  3) Add an entry in `tv-smtp-accounts'
;;  4) Add an entries in authinfo for imap and smtp refering to labels:
;;     imap:=> machine label port xxx login xxx password xxx
;;     smtp:=> machine smtp.gmail.com port xxx login xxx password xxx
;;     Note: for smtp it is not important to have independent machine names
;;     as the info is provided by the from header.

;; Secondary methods are mails and possibly other nntp servers.
(setq gnus-secondary-select-methods '((nnml "")
                                      ;; Add as many gmail account as needed with a label.
                                      ;; Add then an entry in .authinfo:
                                      ;; machine label port xxx login xxx password xxx
                                      (nnimap "gmail" ; Label for reference in .authinfo for machine name.
                                       (nnimap-address "imap.gmail.com")
                                       (nnimap-fetch-partial-articles "text/")) ; [1]
                                      (nnimap "gmail_jaky"
                                       (nnimap-address "imap.gmail.com")
                                       (nnimap-fetch-partial-articles "text/"))
                                      (nnimap "yahoo"
                                       (nnimap-address "imap.mail.yahoo.com")
                                       (nnimap-fetch-partial-articles "text/")) ; [1]
                                      ;(nntp "news.gwene.org")
                                      ))

;; [1] Don't load mime parts when receiving mail, only text part.
;; Use `A-C' to see entire mail.

;; Nnml mail directory 
(setq nnml-directory "~/Mail")

;;; Archivage-des-mails-envoyés
;;
(setq gnus-message-archive-group '((when (message-news-p) "sent-news")))

;;; Smtp settings - Sending mail
;;
;;
;; Posting-styles - must be set correctly for
;;  following smtp settings.
;;
;; [EVAL] (info "(gnus) Posting Styles")
;; [EVAL] (info "(gnus) X-Face")
;; [EVAL] (info "(gnus) Face")
(setq gnus-posting-styles
      '((".*"
         (name "Thierry Volpiatto")
         (address "thierry.volpiatto@gmail.com")
         (signature-file "~/.signature"))
        ((header "to" "thierry.volpiatto@gmail.com")
         (from "Thierry Volpiatto <thierry.volpiatto@gmail.com>")
         (signature-file "~/.signature"))
        ((header "to" "tvolpiatto@yahoo.fr")
         (from "Thierry Volpiatto <tvolpiatto@yahoo.fr>")
         (signature-file "~/.signature"))
        ((header "to" "jvolpiatto@gmail.com")
         (name "Jaky Volpiatto")
         (address "jvolpiatto@gmail.com")
         (from "Jaky Volpiatto <jvolpiatto@gmail.com>")
         (signature-file "~/.signature_jaky"))))

;; [README] (find-fline "/usr/local/share/emacs/24.0.92/lisp/mail/smtpmail.el.gz" "Please")

;; To queue mail, set `smtpmail-queue-mail' to t and use
;; `smtpmail-send-queued-mail' to send.
;(setq smtpmail-queue-mail t) ; Use M-x smtpmail-send-queued-mail when online.

(setq user-mail-address "thierry.volpiatto@gmail.com")
(setq user-full-name "Thierry Volpiatto")

;(require 'smtpmail-async) ; Experimental, use `smtpmail-send-it' otherwise. 
(setq message-send-mail-function 'async-smtpmail-send-it
      smtpmail-debug-info t
      ;smtpmail-debug-verb t        ; Uncomment to debug
      mail-specify-envelope-from t ; Use from field to specify sender name.
      mail-envelope-from 'header)  ; otherwise `user-mail-address' is used. 

;; Default settings.
;; This are default setting, they could be modified
;; by `tv-change-smtp-server' according to `tv-smtp-accounts'
;; and `gnus-posting-styles'.
(setq smtpmail-default-smtp-server "smtp.gmail.com"
      smtpmail-smtp-user user-mail-address
      smtpmail-smtp-server "smtp.gmail.com"
      smtpmail-smtp-service 587)

(defvar tv-smtp-accounts
  '(("thierry.volpiatto@gmail.com"
     (:server "smtp.gmail.com"
      :port 587
      :name "Thierry Volpiatto"))
    ("tvolpiatto@yahoo.fr"
     (:server "smtp.mail.yahoo.com"
      :port 587
      :name "Thierry Volpiatto"))
    ("jvolpiatto@gmail.com"
     (:server "smtp.gmail.com"
      :port 587
      :name "Jaky Volpiatto"))))

(defun tv-change-smtp-server ()
  "Use account found in `tv-smtp-accounts' according to from header.
`from' is set in `gnus-posting-styles' according to `to' header.
or manually with `tv-toggle-from-header'.
This will run in `message-send-hook'."
  (save-excursion
    (save-restriction
      (message-narrow-to-headers)
      (let* ((from         (message-fetch-field "from"))
             (user-account (loop for account in tv-smtp-accounts thereis
                                 (and (string-match (car account) from)
                                      account))))
        (setq smtpmail-smtp-user            (car user-account)
              smtpmail-default-smtp-server  (cl-getf (cadr user-account) :server)
              smtpmail-smtp-server          (cl-getf (cadr user-account) :server)
              smtpmail-smtp-service         (cl-getf (cadr user-account) :port))))))

(add-hook 'message-send-hook 'tv-change-smtp-server)

(defun tv-send-mail-with-account ()
  "Change mail account to send this mail."
  (interactive)
  (save-excursion
    (let* ((from (save-restriction
                   (message-narrow-to-headers)
                   (message-fetch-field "from")))
           (mail (helm-comp-read
                  "Use account: "
                  (mapcar 'car tv-smtp-accounts)))
           (name (cl-getf (cadr (assoc mail tv-smtp-accounts)) :name))
           (new-from (message-make-from name mail)))
        (message-goto-from)
        (forward-line 0)
        (re-search-forward ": " (point-at-eol))
        (delete-region (point) (point-at-eol))
        (insert new-from))))
(define-key message-mode-map (kbd "C-c p") 'tv-send-mail-with-account)

;;; Junk-mail
;;
;;
(when (require 'mm-decode)
  (setq mm-discouraged-alternatives
        '("text/html"
          "text/richtext"
          "text/enriched"
          "multipart/related"
          "image/.*")
        mm-automatic-display
        (remove "text/html" mm-automatic-display)
        gnus-buttonized-mime-types
        '("multipart/alternative"
          ".*/signed"
          "multipart/encrypted")))

;;; Remove white space in filenames
;;
;;
(setq mm-file-name-rewrite-functions
      '(mm-file-name-delete-control
        mm-file-name-delete-gotchas
        mm-file-name-trim-whitespace
        mm-file-name-collapse-whitespace
        mm-file-name-replace-whitespace))

;;; Show-all-these-headers
;;
;;
(setq gnus-visible-headers
      '("^From:"
	"^Newsgroups:"
	"^Subject:"
	"^Date:"
	"^Followup-To:"
	"^Reply-To:"
	"^Organization:"
	"^Summary:"
	"^Keywords:"
	"^To:"
	"^[BGF]?Cc:"
	"^Posted-To:"
	"^Mail-Copies-To:"
	"^Apparently-To:"
	"^X-Gnus-Warning:"
	"^Resent-From:"
	"^X-Sent:"
	"^X-Mailer:"
	"^X-Newsreader:"
	"^X-User-Agent:"
	"^User-Agent:"))

;;; Order-of-headers
;;
;;
(setq gnus-sorted-header-list '("^From:"
                                "^Subject:"
                                "^Summary:"
                                "^Keywords:"
                                "^Newsgroups:"
                                "^Followup-To:"
                                "^To:"
                                "^Cc:"
                                "^Date:"
                                "^User-Agent:"
                                "^X-Mailer:"
                                "^X-Newsreader:"))

;; Ne pas demander si on splitte les pa 
(setq message-send-mail-partially-limit nil)

;;; Html renderer
;;
;;
;; shr
;;
(setq shr-color-visible-luminance-min 75)
(setq shr-width nil) ; Use all window width.
(setq mm-text-html-renderer 'shr)

;; w3m
;;
;; (setq mm-text-html-renderer 'w3m)

;; (setq mm-inline-text-html-with-images t)

;; Passage à la ligne automatique
;;
(defun my-message-mode-setup ()
  (setq fill-column 72)
  (turn-on-auto-fill))
(add-hook 'message-mode-hook 'my-message-mode-setup)

;;; Mail encryption.
;;
;;
(setq mml2015-use 'epg)
(setq mml2015-encrypt-to-self t)

;; Verify/Decrypt automatically
;; only if mml knows about the protocol used.
(setq mm-verify-option 'known)
(setq mm-decrypt-option 'known)

(setq gnus-inhibit-mime-unbuttonizing nil)
(setq gnus-buttonized-mime-types '("multipart/signed"
                                   "multipart/alternative"))

;; Automatically sign/encrypt replies to signed/encrypted mails. 
(setq gnus-message-replysign t)
(setq gnus-message-replyencrypt t)

;; Enable epa.
(add-hook 'message-mode-hook 'epa-mail-mode)

;; Suppression de la signature quand on quote. 
(setq message-cite-function 'message-cite-original-without-signature)

;; shimbun 
;; (add-to-list 'load-path "~/elisp/emacs-w3m/shimbun/")
;; (setq shimbun-server-additional-path '("~/elisp"))
;; (require 'nnshimbun)
;; (autoload 'gnus-group-make-shimbun-group "nnshimbun" nil t)

;; Integration dans dired
(require 'gnus-dired)
(add-hook 'dired-mode-hook 'turn-on-gnus-dired-mode)

;; fortune 
(add-hook 'gnus-article-mode-hook
          #'(lambda ()
             (define-key gnus-article-mode-map "i" 'fortune-from-region)))
;; (add-hook 'message-setup-hook 'fortune-to-signature)
;; (message "Making new signature: %s" (fortune-to-signature "~/docs/ascii/misc/fortunes/usenet"))


;; Scoring 
;; The scoring system sorts articles and authors you read often to the beginning of the available mails.
;; Less interesting stuff is located at the end.
(setq gnus-use-adaptive-scoring t)
(setq gnus-score-expiry-days 14)
(setq gnus-default-adaptive-score-alist
      '((gnus-unread-mark)
        (gnus-ticked-mark (from 4))
        (gnus-dormant-mark (from 5))
        (gnus-saved-mark (from 20) (subject 5))
        (gnus-del-mark (from -2) (subject -5))
        (gnus-read-mark (from 2) (subject 1))
        (gnus-killed-mark (from 0) (subject -3))))
                                        ;(gnus-killed-mark (from -1) (subject -3))))
                                        ;(gnus-kill-file-mark (from -9999)))
                                        ;(gnus-expirable-mark (from -1) (subject -1))
                                        ;(gnus-ancient-mark (subject -1))
                                        ;(gnus-low-score-mark (subject -1))
                                        ;(gnus-catchup-mark (subject -1))))

(setq gnus-score-decay-constant 1)      ;default = 3
(setq gnus-score-decay-scale 0.03)      ;default = 0.05

(setq gnus-decay-scores t)              ;(gnus-decay-score 1000)

;;Use a global score file to filter gmane spam articles. That is a really cool feature.
(setq gnus-global-score-files
      '("~/News/scores/all.SCORE"))

;; all.SCORE contains:
;; (("xref"
;;  ("gmane.spam.detected" -1000 nil s)))
(setq gnus-summary-expunge-below -999)

;; gnus-demon (start with `gnus-demon-init')
;; Scan for new news
;; (gnus-demon-add-handler 'gnus-demon-scan-news 5 1)

;; Scroll-other-window 
(define-key gnus-summary-mode-map (kbd "<C-M-down>") #'(lambda ()
                                                         (interactive)
                                                         (scroll-other-window 1)))

(define-key gnus-summary-mode-map (kbd "<C-M-up>") #'(lambda ()
                                                         (interactive)
                                                         (scroll-other-window -1)))

;; Default-directory-to-save-attached-files 
(setq mm-default-directory "~/download/")

;; timestamp 
(add-hook 'gnus-select-group-hook 'gnus-group-set-timestamp)
(setq gnus-group-line-format "%M\%S\%p\%P\%5y: %(%-40,40g%) %ud\n")

(defun gnus-user-format-function-d (headers)
  (declare (special gnus-tmp-group))
  (let ((time (gnus-group-timestamp gnus-tmp-group)))
    (if time (format-time-string "%b %d  %H:%M" time) "")))

(setq gnus-summary-line-format "%U%R%z %(%&user-date;  %-15,15f %* %B%s%)\n"
      gnus-user-date-format-alist '((t . "%d.%m.%Y %H:%M"))
      gnus-sum-thread-tree-false-root ""
      gnus-sum-thread-tree-indent " "
      gnus-sum-thread-tree-root ""
      gnus-sum-thread-tree-leaf-with-other "├► "
      gnus-sum-thread-tree-single-leaf "╰► "
      gnus-sum-thread-tree-vertical "│")

;; Gravatar
(setq gnus-treat-from-gravatar 'head) ; in From header
(setq gnus-treat-mail-gravatar 'head) ; in To/Cc header

;; sort
;; (setq gnus-thread-sort-functions
;;       '(gnus-thread-sort-by-number
;;         gnus-thread-sort-by-date))


;;; .gnus.el ends here

