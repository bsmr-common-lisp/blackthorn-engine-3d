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

(in-package :blackthorn3d-physics)

;; This is our intermediate representation, basically just a
;; representation/organization of all the data we loaded from
;; the dae file
;;
;; In it's current state, it only holds dae-mesh objects
;; (ie, no scene data).
(defclass blt-model ()
  ((mesh-nodes
    :accessor mesh-nodes
    :initarg :nodes)
   (animations
    :accessor animations
    :initarg :animations)))

(defun instance-model (model)
  "Creates an instance of MODEL. the instance will link to all the same
   mesh data as the original, but have separate nodes, allowing the application
   to specify different transforms, animation states, and materials.
   Will also register the instance in the table"
  (with-slots (mesh-nodes animations) model
    (make-instance 'blt-model
                   :mesh-nodes (iter (for node in mesh-nodes)
                                     (collect (copy-node node)))
                   :animations (copy-anim-controller animations))))

(defun get-model-instance (key)
  (make-instance (get-model key)))

;; We will need the capability to add/remove nodes
(defmethod find-node (obj (model blt-model))
  (iter (for node in (mesh-nodes model))
        (if-let (it (find-node obj node))
                (return-from find-node it))))


(defmethod attach-obj-to-model (obj (node-id string) transform
                                (model blt-model))
  (let ((node (make-model-node "FIXME" transform nil obj nil)))
    (attach-node-to-model node node-id model)))


(defmethod attach-node-to-model ((new-node node)
                                 (node-id string)
                                 (model blt-model))
  (format t "~%ATTACHING node to model at node ~a~%" node-id)
  (if-let (it (find-node node-id model))
          (attach-node new-node it)))

(defmethod detach-node-from-model ((node-id string) (model blt-model))
  (labels ((detach-helper (id node)
             (iter (for child in (child-nodes node))
                   (if (equal id (id child))
                       (progn
                         (setf (child-nodes node)
                               (delete child (child-nodes node)))
                         (return-from detach-helper child))
                       (if-let (it (detach-helper id child))
                               (return-from detach-helper it))))))

    (iter (for node in (mesh-nodes model))
          (for test = (detach-helper node-id node))
          (until test)
          (finally (return test)))))

(defmethod expand-bounding-spheres ((this blt-model))
  "sets each nodes bounding sphere to be the union of it's bounding
   sphere with all its children's bounding spheres"
  (labels ((recurse-nodes (node)
             (let ((children-bounding-spheres
                    (iter (for c in (child-nodes node))
                          (collect (recurse-nodes (child-nodes node))))))
               (setf (node-bounding-volume node)
                     (combine-bounding-spheres
                      (remove-if #'null
                                 (cons (node-bounding-volume node)
                                       children-bounding-spheres)))))))
    (node-bounding-volume (car (mesh-nodes this)))
    #+disabled
    (combine-bounding-spheres
     (iter (for node in (mesh-nodes this))
           (collect  (recurse-nodes node))))))

(defmethod apply-transform ((this blt-model) xform)
  "applies transform matrix to the nodes of this blt-model"
  (labels ((apply-helper (node)
             (with-slots (transform bounding-volume) node
               ;; set transform
               (setf transform
                     (matrix-multiply-m xform transform))
               ;; and transformed bv
               (setf bounding-volume
                     (transform-bounding-volume bounding-volume xform))
               ;; do the children
               #+disabled
               (iter (for child in (child-nodes node))
                     (apply-helper child))
               bounding-volume)))

    (when (animations this)
      (format t "transforming!!~%")
    ;  (apply-transform (animations this) xform)
      )
    (combine-bounding-spheres
     (iter (for node in (mesh-nodes this))
           (collect (apply-helper node))))
    this))




(defmethod play-model-animation ((self blt-model) clip-name
                                 &optional (mode :play))
  (play-clip (animations self) clip-name mode))


(defclass vertex-stream ()
  ((semantic
    :accessor vs-semantic
    :initarg :semantic)
   (stream
    :accessor vs-stream
    :initarg :stream)
   (stride
    :accessor vs-stride
    :initarg :stride)))

(defun vs-ref (vs index)
  (with-slots (stream) vs
    (aref stream index)))

;; for now i'm going to assume no one is being dumb and putting
;; wrong things in streams
(defun (setf vs-ref) (vec vs index)
  (with-slots (stream stride) vs
    (setf (aref stream index) vec)
    #+disabled
    (iter (for elt in-vector vec)
          (for i below stride)
          (setf (svref stream (+ i (* index stride))) elt))))

(defclass element ()
  ((indices
    :accessor element-indices
    :initarg :indices)
   (count
    :accessor element-count
    :initarg :count)
   (material
    :accessor element-material
    :initarg :material)
   (unifiedp
    :initarg :unifiedp
    :initform nil)))

(defun make-element (&key indices count material)
  (make-instance 'element
                 :indices indices
                 :count count
                 :material material))

(defclass blt-material ()
  ((ambient
    :initarg :ambient
    :initform #(0.0 0.0 0.0 1.0))
   (diffuse
    :initarg :diffuse
    :initform #(1.0 1.0 1.0 1.0))
   (specular
    :initarg :specular
    :initform #(0.0 0.0 0.0 1.0))
   (shininess
    :initarg :shininess
    :initform 0.0)
   (textures
    :initarg :textures
    :initform nil)))

(defun make-blt-material (&key ambient diffuse specular shininess textures)
  (make-instance 'blt-material
                 :ambient ambient
                 :diffuse diffuse
                 :specular specular
                 :shininess shininess
                 :textures textures))


;;;
;;; Model loading-specific code.
;;;


;; Note that this assumes that all the semantics in order exist in
;; vertex-streams. The behavior is currently incorrect if this isn't true
;; It is fine to have extra semantics in vertex-streams, they will
;; be dropped
(defun order-streams (vertex-streams order)
  "@arg[order]{A list of form (SEMANTIC SEMANTIC ... ) specifiying
               a desired order for the streams}"
  (iter (for vs in vertex-streams)
        (for o in order)
        (format t "order semantic: ~a   VS semantic: ~a~%" o (vs-semantic vs)))
  (iter (for o in order)
        (collect (find o vertex-streams
                       :key #'(lambda (vs) (vs-semantic vs))))))

(defun get-vs-fns (vertex-streams format)
  (iter (for (semantic n-elts) in format)
        (collect
         (if-let (it (find semantic vertex-streams :key #'vs-semantic))
                 (let ((len n-elts))
                   #'(lambda (index)
                       ;;(format t "original vector: ~a~%" (vs-ref it index))
                       (concatenate
                        'vector
                        (subseq (vs-ref it index)
                                0 (min len (vs-stride it)))
                        (iter (for i below (- len (vs-stride it)))
                              (collect 0.0 result-type 'vector)))))
                 (let ((zero-vec (iter (for i below n-elts)
                                       (collect 0.0 result-type 'vector))))
                   #'(lambda (index) zero-vec))))))


;; combines unified vertex-streams into one large 2-d array
;; If you want a specific order, re-order/prune the data before
;; calling this function on it.
;; Returns (2d-array indexing-fn)
;; indexing-fn is a function that returns a list
;; containing (SEMANTIC VECTOR) elements for each stream that
;; was interleaved into the array
(defun interleave (vertex-streams format)
  (let ((vs-fns (get-vs-fns vertex-streams format))
        (size (length (vs-stream (car vertex-streams)))
          #+disabled(iter (for vs in vertex-streams)
                    (minimizing (length (vs-stream vs)))))
        (depth (iter (for f in format)
                     (sum (second f)))))

    (let ((interleaved (make-array (list size depth)))
          (index 0))
      ;(format t "size: ~a depth: ~a~%" size depth)
      ;; For each vertex
      (iter (for i below size)
            (iter (for fn in vs-fns)
                  (iter (for elt in-vector (funcall fn i))
                        (setf (row-major-aref interleaved index)
                              (float elt))
                        (incf index))))

      (values
       interleaved
       #'(lambda (index)
           (iter (for (semantic n-elts) in format)
                 (for fn in vs-fns)
                 (collect (list semantic (funcall fn index)))))))))


;;;
;;; Triangle access
;;;

;; I will represent a triangle using 3 vertices and a face normal
;; This will be represented by an array #(v0 v1 v2 n centroid)
;;

(defun make-triangle (v0 v1 v2)
  (let ((normal (norm3 (cross3 (vec3- v1 v0)
                               (vec3- v2 v0))))
        (centroid (tri-centroid v0 v1 v2)))
    (vector v0 v1 v2 normal centroid)))

;; Returns the triangle at index from the blt-mesh
;; If the mesh has multiple elements, the indexes are treated
;; as incrementing accross elements. The first element has
;; indices [0 elem1.count) the next one has [elem1.count elem2.count)
;; etc.

(defun tri-in-elt (elem vs index)
  (with-slots (indices) elem
    (let ((i (* 3 index)))
      (make-triangle
       (to-float (vs-ref vs (aref indices i)))
       (to-float (vs-ref vs (aref indices (+ i 1))))
       (to-float (vs-ref vs (aref indices (+ i 2))))))))

(defmethod triangle-at ((this blt-mesh) index)
  (with-slots (elements vertex-streams) this
    ;; First find the element we're in
    (multiple-value-bind (elt start-index)
        (iter (for elt in elements)
              (for s first 0 then (+ s (slot-value elt count)))
              (for last-s previous s initially 0)
              (finding elt such-that (> s index) into first-elt)
              (finally (return (values first-elt (- index last-s)))))
      (let ((vertices (find :vertex vertex-streams :key #'vs-semantic)))
        ;; MUST have vertex positions!
        (unless (null vertices)
          (tri-in-elt elt vertices start-index))))))

(defmethod build-triangle-array ((this blt-mesh))
  (with-slots (elements vertex-streams) this
    (let ((vertices (find :vertex vertex-streams :key #'vs-semantic))
          (triangles (make-array (iter (for elt in elements)
                                       (sum (slot-value elt 'count)))))
          (index 0))

      (iter (for element in elements)
            (iter (for i below (slot-value element 'count))
                  (setf (svref triangles index)
                        (tri-in-elt element vertices i))
                  (incf index)))
      triangles)))


(defmethod build-triangle-list ((this blt-mesh))
  (with-slots (elements vertex-streams) this
    (let ((vertices (find :vertex vertex-streams :key #'vs-semantic)))
      (iter (for element in elements)
            (iter (for i below (slot-value element count))
                  (collect (tri-in-elt element vertices i)))))))

#+disabled
(defun tri-bounds (tri)
  (find-bounding-points (subseq tri 0 3)))

;;;
;;; Bounding Volume stuff herr
;;;
#+disabled
(defmethod calc-bounding-volume ((this blt-model))
  (combine-bounding-volume
   (iter (for node in (mesh-nodes this))
         (collect (bounding-volume
                   (mesh node))))))
