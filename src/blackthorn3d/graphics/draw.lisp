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

(defun draw-cube (&key (color #(1.0 1.0 1.0)))
  (gl:color (r color) (g color) (b color))
  (gl:with-primitive :quads

    ;; front face
    (gl:vertex -1.0 1.0 1.0)
    (gl:vertex -1.0 -1.0 1.0)
    (gl:vertex 1.0 -1.0 1.0)
    (gl:vertex 1.0 1.0 1.0)
        
    ;; top face
    (gl:vertex -1.0 1.0 -1.0)
    (gl:vertex -1.0 1.0 1.0)
    (gl:vertex 1.0 1.0 1.0)
    (gl:vertex 1.0 1.0 -1.0)
        
    ;; right face
    (gl:vertex 1.0 1.0 1.0)
    (gl:vertex 1.0 -1.0 1.0)
    (gl:vertex 1.0 -1.0 -1.0)
    (gl:vertex 1.0 1.0 -1.0)
        
    ;; back face
    (gl:vertex 1.0 1.0 -1.0)
    (gl:vertex 1.0 -1.0 -1.0)
    (gl:vertex -1.0 -1.0 -1.0)
    (gl:vertex -1.0 1.0 -1.0)
        
    ;; left face
    (gl:vertex -1.0 1.0 -1.0)
    (gl:vertex -1.0 -1.0 -1.0)
    (gl:vertex -1.0 -1.0 1.0)
    (gl:vertex -1.0 1.0 1.0)
        
    ;; bottom face
    (gl:vertex -1.0 -1.0 -1.0)
    (gl:vertex 1.0 -1.0 -1.0)
    (gl:vertex 1.0 -1.0 1.0)
    (gl:vertex -1.0 -1.0 1.0)))

(defun draw-triangle (&key (color #(1.0 1.0 1.0)))
  (gl:color (r color) (g color) (b color))
  (gl:with-primitive :triangles
    (gl:vertex 0.0 1.0 0.0)
    (gl:vertex -1.0 0.0 0.0)
    (gl:vertex 1.0 0.0 0.0)))
    
(gl:define-gl-array-format position
  (gl:vertex :type :float :components (x y z)))
 
(defun set-vec-in-glarray (a i v)
  (setf (gl:glaref a i 'x) (x v))
  (setf (gl:glaref a i 'y) (y v))
  (setf (gl:glaref a i 'z) (z v)))
      
(defun set-quad-indices (a i v)
  (iter (for j from (* i 4) below (+ (* i 4) 4))
        (for k below 4)
    (setf (gl:glaref a j) (nth k v))))

(defun make-cube ()
  (let ((vert-arr (gl:alloc-gl-array 'position 8))
        (ind-arr  (gl:alloc-gl-array :unsigned-short 24)))
        
    ;; Vertex Array
    (set-vec-in-glarray vert-arr 0 #(-1.0 -1.0 -1.0))
    (set-vec-in-glarray vert-arr 1 #(-1.0 -1.0  1.0))
    (set-vec-in-glarray vert-arr 2 #(-1.0  1.0 -1.0))
    (set-vec-in-glarray vert-arr 3 #(-1.0  1.0  1.0))
    (set-vec-in-glarray vert-arr 4 #( 1.0 -1.0 -1.0))
    (set-vec-in-glarray vert-arr 5 #( 1.0 -1.0  1.0))
    (set-vec-in-glarray vert-arr 6 #( 1.0  1.0 -1.0))
    (set-vec-in-glarray vert-arr 7 #( 1.0  1.0  1.0))
    
    ;; Index array
    (set-quad-indices ind-arr 0 '(4 5 1 0))
    (set-quad-indices ind-arr 1 '(2 3 7 6))
    (set-quad-indices ind-arr 2 '(1 5 7 3))
    (set-quad-indices ind-arr 3 '(7 5 4 6))
    (set-quad-indices ind-arr 5 '(2 0 1 3))
    (set-quad-indices ind-arr 4 '(6 4 0 2))
    (list vert-arr ind-arr)))

(defun draw-vert-array (vert-arr ind-arr)
  (gl:enable-client-state :vertex-array)
  (gl:bind-gl-vertex-array vert-arr)
  (gl:draw-elements :quads ind-arr)
  (gl:flush))