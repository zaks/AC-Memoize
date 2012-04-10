(in-package #:user)

#-allegro
(error "This package works on Allegro CL only")

(asdf:defsystem #:ac-memoize
  :author "Slawomir Zak"
  :description "AllegroCache memoisation library"
  :components ((:file "package")
               (:file "ac-memoize" :depends-on ("package"))))

