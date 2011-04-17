;;;; Blackthorn -- Lisp Game Engine
;;;;
;;;; Copyright (c) 2011, Robert Gross <r.gross.3@gmail.com>
;;;;
;;;; Permission is hereby granted, free of charge, to any person
;;;; obtaining a copy of this software and associated documentation
;;;; files (the "Software"), to deal in the Software without
;;;; restriction, including without limitation the rights to use, copy,
;;;; modify, merge, publish, distribute, sublicense, and/or sell copies
;;;; of the Software, and to permit persons to whom the Software is
;;;; furnished to do so, subject to the following conditions:
;;;;
;;;; The above copyright notice and this permission notice shall be
;;;; included in all copies or substantial portions of the Software.
;;;;
;;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;;;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;;; NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;;;; DEALINGS IN THE SOFTWARE.
;;;;

(in-package :blackthorn3d-graphics)

;; notes- uses similar description for a frustum as opengl
;;        there is nothing forcing the left and right plane
;;        to be mirrored
(defclass frustum ()
  ((near-dist
    :accessor frstm-near
    :initarg :near)
   (far-dist
    :accessor frstm-far
    :initarg :far)
   (top-left
    :accessor frstm-top-left
    :initarg :top-left)
   (bottom-right
    :accessor frstm-bottom-right
    :initarg :bottom-right)))

(defun make-frstm (near far aspect fov)
  (let* ((width (/ (calc-width near fov) 2.0))
         (height (* width (/ aspect))))
    (make-instance 'frustum
                   :near near
                   :far far
                   :top-left (vector width height)
                   :bottom-right (vector -width -height))))

(defun calc-width (near fov)
  (* near 
     (tan (/ fov 2))))