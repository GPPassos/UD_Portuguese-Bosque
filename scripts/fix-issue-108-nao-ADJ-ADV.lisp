(ql:quickload :cl-conllu)
(ql:quickload :cl-fad)
(ql:quickload :split-sequence)

(in-package :cl-conllu)

(defun find-token (id tokens)
  (find id tokens :key (lambda (tk) (slot-value tk 'id))))

(defun adv-adj? (token)
  (member (slot-value token 'upostag) '("ADV" "ADJ") :test #'string=))

(defun head-of (token tokens)
  (find-token (slot-value token 'head) tokens))

(defun append-feature (key value token)
  (let ((features (if (string= "_" (slot-value token 'feats)) nil
                      (split-sequence #\| (slot-value token 'feats)))))
    (format nil "~{~a~^|~}" (sort (append features `(,(format nil "~a=~a" key value))) #'string<))))

(defun fix-neg (tokens)
  (mapc (lambda (tk)
          (when
              (and (string-equal (slot-value tk 'lemma) "não")
                   (string= (slot-value tk 'deprel) "neg"))
            (when (adv-adj? (head-of tk tokens))
              (setf (slot-value tk 'deprel) "advmod")
              (setf (slot-value tk 'xpostag) "_")
              (setf (slot-value tk 'feats) (append-feature "Polarity" "Neg" tk)))))
        tokens))

(defun fix-corpus (sentences)
  (mapc (lambda (s) (fix-neg (sentence-tokens s))) sentences))

;; to replicate
;; (write-conllu (fix-corpus (read-conllu "bosque.udep.conll")) "bosque.fixed")
(defun run ()
  (dolist (f (cl-fad:list-directory #p "documents/"))
    (write-conllu (fix-corpus (read-conllu f)) f)))
