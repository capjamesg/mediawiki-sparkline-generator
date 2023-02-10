;; static site generator built in Lisp
;; codename: apple (that is the full name!)

(ql:quickload :markdown.cl-test)
(ql:quickload :cl-ppcre)
(ql:quickload :uiop)

(defun writetofile (filename contents)
    (with-open-file (stream filename :direction :output :if-does-not-exist :create :if-exists :supersede)
        (format stream contents)))

(defun readfile (filename &optional newline)
    (with-open-file (in filename)
        (if newline
            (loop for line = (read-line in nil nil)
                while line collect (concatenate 'string line '(#\Newline)))
            (loop for line = (read-line in nil nil)
                while line collect line))))

(defun getpagetext (filestring)
    (loop for i from (+ (getlastpos filestring) 1) to (length filestring)
        collect (nth i filestring)))

(defun generateblogposts ()
    (loop for file in (remove-if-not (lambda (x) (search ".md" (namestring x))) (uiop:directory-files "../_posts/*.md"))
        collect (writetofile (concatenate 'string "out/" (pathname-name file) ".html") (blogpost (namestring file)))))

(defun generatepostlist ()
    (loop for file in (remove-if-not (lambda (x) (search ".md" (namestring x))) (uiop:directory-files "../_posts/*.md"))
        collect (frontmattertokeys (readfile (namestring file) t))))

(defun generatemapslist ()
    (loop for file in (remove-if-not (lambda (x) (search ".md" (namestring x))) (uiop:directory-files "../_checkins/*.md"))
        collect (frontmattertokeys (readfile (namestring file) t))))

;; (load "generator.lisp")