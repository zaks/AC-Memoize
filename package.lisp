(eval-when (:compile-toplevel :load-toplevel :execute)
  (require '#:acache "acache-2.1.21.fasl"))

(defpackage #:ac-memoize
  (:use :cl :excl :db.ac))