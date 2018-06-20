(in-package #:pong)


(defparameter *world-width* 800)
(defparameter *world-height* 600)
(defparameter *paddle-width* 20)
(defparameter *paddle-height* 100)
(defparameter *ball-size* 20)

(defclass position ()
  ((x :initarg :x :accessor x)
   (y :initarg :y :accessor y)))

(defclass velocity ()
  ((dx :initarg :dx :accessor dx)
   (dy :initarg :dy :accessor dy)))

(defclass region ()
  ((width :initarg :width :accessor width)
   (height :initarg :height :accessor height)))

(defclass ball (position velocity region) ())

(defclass paddle (position region) ())

(defclass world (region)
  ((ball :initarg :ball :accessor ball)
   (paddle1 :initarg :paddle1 :accessor paddle1)
   (paddle2 :initarg :paddle2 :accessor paddle2)))

(defmethod initialize-instance :after ((world world) &key &allow-other-keys)
  (setf (width world) *world-width*
        (height world) *world-height*
        (ball world) (make-instance 'ball
                                    :x (/ (width world) 2)
                                    :y (/ (height world) 2)
                                    :dx (* (let ((dx (+ -5 (random 5))))
                                             (if (= dx 0)
                                                 (setf dx (1+ (random 2)))
                                                 dx))
                                           2)
                                    :dy (* (+ -5 (random 5))
                                           2)
                                    :width *ball-size*
                                    :height *ball-size*)
        (paddle1 world) (make-instance 'paddle
                                       :x 0
                                       :y (/ (- (height world) *paddle-height*) 2)
                                       :width *paddle-width*
                                       :height *paddle-height*)
        (paddle2 world) (make-instance 'paddle
                                       :x (- (width world) *paddle-width*)
                                       :y (/ (- (height world) *paddle-height*) 2)
                                       :width *paddle-width*
                                       :height *paddle-height*)))

(defmethod scored ((world world))
  (let ((ball (ball world)))
    (cond ((< (x ball) 0)
           :player1)
          ((> (+ (width ball) (x ball)) (width world))
           :player2)
          (t nil))))

(defmethod update-entity ((ball ball) (world world) dt)
  (let ((x1 (+ (x ball) (dx ball)))
        (y1 (+ (y ball) (dy ball))))
    (when (or (< y1 0) (> (+ y1 (height ball)) (height world)))
      (setf (dy ball) (- (dy ball)))
      (update-entity ball world dt))
    (setf (x ball) x1
          (y ball) y1)
    (let ((collision (or (collision (ball world) (paddle1 world))
                         (collision (ball world) (paddle2 world)))))
      (when collision
        (setf (dx ball) (- (dx ball))
              (dy ball) (* (abs (dy ball)) (* 10 (abs collision))))))))

(defmethod update ((world world) dt)
  (update-entity (ball world) world dt))

(defmethod draw-entity ((ball ball) (world world) renderer)
  (sdl2:set-render-draw-color renderer 0 0 0 0)
  (let ((rect (sdl2:make-rect (floor (x ball)) (floor (y ball)) (floor (width ball)) (floor (height ball)))))
    (sdl2:render-fill-rect renderer rect)))

(defmethod draw-entity ((paddle paddle) (world world) renderer)
  (sdl2:set-render-draw-color renderer 0 0 0 0)
  (let ((rect (sdl2:make-rect (floor (x paddle)) (floor (y paddle)) (floor (width paddle)) (floor (height paddle)))))
    (sdl2:render-fill-rect renderer rect)))

(defmethod draw ((world world) renderer)
  (sdl2:set-render-draw-color renderer 255 255 255 0)
  (sdl2:render-clear renderer)
  (draw-entity (ball world) world renderer)
  (draw-entity (paddle1 world) world renderer)
  (draw-entity (paddle2 world) world renderer))

(defmethod collision ((ball ball) (paddle paddle))
  (let ((bx1 (x ball))
        (by1 (y ball))
        (bx2 (+ (x ball) (width ball)))
        (by2 (+ (y ball) (height ball)))
        (px1 (x paddle))
        (py1 (y paddle))
        (px2 (+ (x paddle) (width paddle)))
        (py2 (+ (y paddle) (height paddle))))
    (and (< bx1 px2)
         (> bx2 px1)
         (< by1 py2)
         (> by2 py1)
         (abs (/ (- (+ py1 (/ (height paddle) 2))
                    (+ by1 (/ (height ball) 2)))
                 (height paddle))))))

(defun main ()
  (sdl2:with-init (:everything)
    (sdl2:with-window (window :title "Pong" :w *game-width* :h *game-height* :flags '(:shown))
      (sdl2:with-renderer (renderer window)
        (sdl2:set-render-draw-color renderer 255 255 255 0)
        (sdl2:render-clear renderer)
        (let ((world (make-instance 'world)))
          (sdl2:with-event-loop ()
            (:keydown (:keysym keysym)
                      (switch (keysym :test #'sdl2:scancode= :key #'sdl2:scancode-value)
                        (:scancode-escape (sdl2:push-event :quit))
                        (:scancode-a (decf (y (paddle1 world)) 10))
                        (:scancode-z (incf (y (paddle1 world)) 10))
                        (:scancode-up (decf (y (paddle2 world)) 10))
                        (:scancode-down (incf (y (paddle2 world)) 10))))
            (:idle ()
                   (update world 0)
                   (when (scored world)
                     (setf world (make-instance 'world)))
                   (draw world renderer)
                   (sdl2:render-present renderer)
                   (sleep 0.012))
            (:quit () t)))))))
