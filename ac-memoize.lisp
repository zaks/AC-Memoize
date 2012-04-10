(in-package #:ac-memoize)

(defparameter *map-name* "ac-memoize-map")

(defvar *transforms* (make-hash-table))
(defvar *memo-db* nil)
(defvar *memo-map* nil)

(defun fname (f)
  "get function name"
  (if (symbolp f)
    f
    (excl::external-fn_symdef f)))

(defun setup-ac-memoize (&optional (db "cache/"))
  "setup caching db for ac-memoize"
  (when *memo-db*
    (close-database :db *memo-db*))
  (let* ((*allegrocache* (open-file-database db :if-does-not-exist :create))
         (map (retrieve-from-index 'ac-map 'ac-map-name *map-name*)))
    (setq *memo-db* *allegrocache*
          *memo-map* (or map (make-instance 'ac-map :ac-map-name *map-name*))))
  ;; shut cache on exit
  (pushnew '(close-database :db *memo-db*)
           system:*exit-cleanup-forms*
           :test #'equal))

(defun clr-ac-memoize (&optional fn)
  "remove funcall cache"
  (prog1
      (if fn
        (map-map (lambda (k v)
                   (declare (ignore v))
                   (when (eq fn (car k))
                     (remove-from-map *memo-map* k)))
                 *memo-map*)
        (progn
          (delete-instance *memo-map*)
          (setq *memo-map* (make-instance 'ac-map :ac-map-name *map-name*))))
    (commit)))

(defun ac-memoize (fn &optional (transform #'identity))
  "memoize values returned by fn after application of transform on arglist"
  (unless *memo-db*
    (setup-ac-memoize))
  (setf (gethash fn *transforms*) transform)
  (fwrap fn 'ac-memoize 'ac-memoize-wrap))

(def-fwrapper ac-memoize-wrap (&rest args)
  (let* ((fname (fname excl::primary-function))
         (trans (gethash fname *transforms*))
         (nargs (funcall trans args)))
    (multiple-value-bind (cached presentp)
        (map-value *memo-map* (cons fname nargs))
      (if presentp
        (apply #'values cached)
        (let ((res (multiple-value-list (call-next-fwrapper))))
          (setf (map-value *memo-map* (cons fname nargs)) res)
          (commit)
          (apply #'values res))))))

(defun test (x)
  (print 'call)
  (values 10 20 x))

(ac-memoize 'test)