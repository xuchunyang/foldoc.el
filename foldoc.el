;;; foldoc.el --- FOLDOC - Computing Dictionary -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2019  Xu Chunyang

;; Author: Xu Chunyang <mail@xuchunyang.me>
;; Homepage: https://github.com/xuchunyang/foldoc.el
;; Package-Requires: ((emacs "24.4"))
;; Version: 0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Emacs interface for [FOLDOC - Computing Dictionary](http://foldoc.org/).

;;; Code:

(require 'subr-x)                       ; `string-trim'

(defvar foldoc-file
  (locate-user-emacs-file (convert-standard-filename "foldoc/Dictionary"))
  "File downloaded from URL `http://foldoc.org/Dictionary'.")

(defun foldoc--download ()
  "Download dictionary to `foldoc-file'."
  (make-directory (file-name-directory foldoc-file) t)
  (url-copy-file "http://foldoc.org/Dictionary" foldoc-file 'ok-if-already-exists))

(defun foldoc--read-word ()
  (unless (file-exists-p foldoc-file)
    (foldoc--download))
  (let ((completion-ignore-case t))
    (completing-read
     "Word: "
     (with-temp-buffer
       (insert-file-contents foldoc-file)
       (goto-char (point-min))
       (let (words)
         (while (re-search-forward "^[^\t\n].*$" nil t)
           (push (match-string 0) words))
         (nreverse words)))
     nil t)))

(defun foldoc--search-word (word)
  (unless (file-exists-p foldoc-file)
    (foldoc--download))
  (with-temp-buffer
    (insert-file-contents foldoc-file)
    (goto-char (point-min))
    (when (re-search-forward (concat "^" (regexp-quote word) "$") nil t)
      (let ((op (point)))
        (if (re-search-forward "^[^\t\n].*$" nil t)
            (goto-char (line-beginning-position))
          (goto-char (point-max)))
        (buffer-substring op (point))))))

(defun foldoc--format-result (result)
  (replace-regexp-in-string "^\t" "" (string-trim result)))

;;;###autoload
(defun foldoc (word)
  "Display explanation of WORD."
  (interactive (list (foldoc--read-word)))
  (let ((result (foldoc--search-word word)))
    (if result
        (with-current-buffer (get-buffer-create (format "*foldoc: %s*" word))
          (erase-buffer)
          (insert (foldoc--format-result result))
          (goto-char (point-min))
          (display-buffer (current-buffer)))
      (user-error "No result for %s" word))))

(provide 'foldoc)
;;; foldoc.el ends here
