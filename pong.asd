(defsystem #:pong
  :description "Pong"
  :author "Matthew Kennedy <burnsidemk@gmail.com>"
  :license  "LLGPL2.1"
  :version "0.0.1"
  :serial t
  :components ((:file "package")
               (:file "pong"))
  :depends-on (#:alexandria #:iterate #:sdl2))
