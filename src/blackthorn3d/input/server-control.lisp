;;;; Blackthorn -- Lisp Game Engine
;;;;
;;;; Copyright (c) 2011 Chris McFarland <askgeek@gmail.com>
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

(in-package :blackthorn3d-input)

(defvar *client-controllers* nil)

(defclass server-controller ()
    ((move-x
        :accessor move-x
        :initform 0
        :documentation "the state of the move-x axis")
     (move-y
        :accessor move-y
        :initform 0
        :documentation "the state of the move-y axis")
     (view-x
        :accessor view-x
        :initform 0
        :documentation "the state of the view-x axis")
     (view-y
        :accessor view-y
        :initform 0
        :documentation "the state of the view-y axis")
     (jump
        :accessor jump
        :initform 0))
      (:documentation "Represents state of a client's controller"))
      
(defun new-server-controller (client)
    (let ((sc (make-instance 'server-controller)))
        (setf (getf *client-controllers* client) sc)))
        
(defun remove-server-controller (client)
    (remf *client-controllers* client))
        
(flet ((with-controller (client-id f)
    (let ((controller (getf *client-controllers* client-id)))
      (if (eq controller nil) 0
          (funcall f controller)))))
    
    (defun s-input-move-x (client-id)
      (with-controller client-id #'move-x))
    (defun s-input-move-y (client-id)
      (with-controller client-id #'move-y))
    (defun s-input-view-x (client-id)
      (with-controller client-id #'view-x))
    (defun s-input-view-y (client-id)
      (with-controller client-id #'view-y))
    (defun s-input-jump (client-id)
      (with-controller client-id #'jump)))
      
