(defsystem #:pong
  :description "Pong"
  :license  "LLGPL2.1"
  :version "0.0.1"
  :serial t
  :components ((:file "package")
               (:file "pong"))
  :depends-on (#:alexandria #:iterate #:sdl2))
