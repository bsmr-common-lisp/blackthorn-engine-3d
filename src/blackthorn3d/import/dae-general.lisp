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

(in-package :blackthorn3d-import)

;;;
;;; Functions, data structures, and constants
;;; common to many collada elements
;;;

(defvar +geometry-library+   "library_geometries")
(defvar +controller-library+ "library_controllers")
(defvar +material-library+   "library_materials")
(defvar +image-library+      "library_images")
(defvar +effect-library+     "library_effects")
(defvar +scene-library+      "library_visual_scenes")
(defvar +light-library+      "library_lights")
(defvar +animation-library+  "library_animations")

(defvar +instance-geometry+ "instance_geometry")
(defvar +instance-controller+ "instance_controller")
(defvar +instance-material+ "instance_material")

;;;
;;; Collada helper objects
;;;

(defclass source ()
  ((id
    :accessor src-id
    :initarg :id)
   (array
    :accessor src-array
    :initarg :array)
   (stride
    :accessor src-stride
    :initarg :stride
    :initform 1)
   (components
    :accessor src-components
    :initarg :components)))

(defun src-accessor (src index)
  (with-slots (stride array) src
  ;  (subseq array (* index stride) (+ (* index stride) stride))
  ;  #+disabled
    (let ((val (subseq array (* index stride) (+ (* index stride) stride))))
      (if (= stride 16)
          (transpose (reshape val '(4 4)))
          val))))

(defun (setf src-accessor) (vec src index)
  (with-slots (stride array) src
    (iter (with start = (* index stride))
          (for i from start below (+ start stride))
          (for e in-vector vec)
          (setf (svref array i) e))
    vec))

;;;
;;; Collada helper functions
;;;

(defvar *dbg-level* 0)
(defun dae-debug (&rest args)
  (dotimes (i *dbg-level*)
    (format t "~2T"))
  (apply #'format t args))


;; Source related functions

(defun src-expand (source)
  (with-slots (array stride) source
    (let* ((len (/ (length array) stride))
           (exp-arr (make-array len)))
      (iter (for i below len)
            (setf (svref exp-arr i) (src-accessor source i)))
      exp-arr)))

(defun make-accessor (accessor-lst array)
  "Returns a function that takes an index and returns a vector containing
   the data for that index"
  (let ((stride (parse-integer
                 (get-attribute "stride" (attributes accessor-lst)))))
    #'(lambda (index)
        (subseq array (* index stride) (+ (* index stride) stride)))))

(defun make-components (accessor-lst)
  (mapcar #'(lambda (child)
              (get-attribute "name" (attributes child)))
          (children-with-tag "param" accessor-lst)))

(defun get-stride (accessor-lst)
  (if-let (it (get-attribute "stride" (attributes accessor-lst)))
          (parse-integer it)
          1))

(defun make-source (src-lst)
  (let ((accessor-lst (find-tag +accessor+ (children src-lst)))
        (array (string->sv (car (children (first-child src-lst))))))
    (make-instance 'source
                   :id (get-attribute "id" (attributes src-lst))
                   :array array
                   :stride (get-stride accessor-lst)
                 ;  :accessor (make-accessor accessor-lst array)
                   :components (make-components accessor-lst))))

(defun hash-sources (xml-lsts)
  (let ((src-lsts (children-with-tag "source" xml-lsts))
        (src-table (make-id-table)))
    (iter (for src-lst in src-lsts)
          (let ((src (make-source src-lst)))
            (setf (gethash (src-id src) src-table) src)))
    src-table))

;; Input related
;; (can be used for primitive blocks or any other block
;;  that uses the input-source model)

(defun input->source (str source-table)
  (gethash str source-table))

(defun build-input-lst (prim-lst sources)
  (iter (for input in (children-with-tag "input" prim-lst))
        (let ((attribs (attributes input)))
          (collect (list (intern (get-attribute "semantic" attribs) "KEYWORD")
                         (input->source (uri-indirect
                                         (get-attribute "source" attribs))
                                        sources)
                         (if-let (it (get-attribute "offset" attribs))
                                 (parse-integer it)))))))

(defun input-by-semantic (semantic inputs)
  (second (find semantic inputs :key #'car)))

;; Other...

;; Helper function to construct a 4x4 matrix (should probably be
;; extended to support arbitrary sized matrices
;; note that collada gives us row-major matrices
(defun matrix-tag->matrix (xml-lst &key (tag "matrix"))
  (when (equal tag (tag-name xml-lst))
    (transpose (reshape (string->sv (third xml-lst)) '(4 4)))))

(defun portal-name (id)
  (subseq id 7))



;; Returns a list of (fn . array) where calling fn with an index modifies array
;; fn is designed to take in index to a source and add the corresponding value
;; to array.
(defun get-source-functions (sources)
  (iter (for src in sources)
        (collect
         (let* ((source (second src))
                (attrib-len (/ (length (src-array source))
                               (length (src-components source))))
                (attrib-vec (make-array attrib-len
                                        :fill-pointer 0
                                        :adjustable t)))
           (list #'(lambda (index)
                     (let ((src-vec (src-accessor source index)))
                       (vector-push-extend src-vec attrib-vec))0)
                 attrib-vec
                 (third src))))))


(defun duplicate-indices (elements index times)
  "updates the indices in elements to have index # index
   repeated times number of times at the end of the index list"
  (iter (for elt in elements)
        (let* ((indices (element-indices elt))
               (count (element-count elt))
               (stride (/ (length indices) count 3))
               (new-indices (make-array (* (+ stride times) count 3))))
          (iter (with ni = -1)
                (for i below (length indices) by stride)
                (for base = (subseq indices i (+ i stride)))
                (for copy = (svref base index))
                (iter (for j in-vector base)
                      (setf (svref new-indices (incf ni)) j))
                (iter (for j below times)
                      (setf (svref new-indices (incf ni)) copy)))
          (print (subseq new-indices 0 100))
          (setf (element-indices elt) new-indices)
          #+disabled
          (setf
           (element-indices elt)
           (apply
            #'vector
            (apply
             #'append
             (iter (for i below (length indices) by stride)
                   (collect
                       (let ((base (iter (for k from i below (+ i stride))
                                         (collect (svref indices k)))))
                         (append base
                                 (iter (with copy = (elt base index))
                                       (for j below times)
                                       (collect copy)))))))))))
  elements)

;; combines the vertex data so there is only one indice per vertex
;; returns  (ELEMENTS VERTEX-STREAMS) where elements is a list
;; of elem objects and VERTEX-STREAMS is a list of vertex-stream objects
(defun unify-indices (elements inputs)
  (let ((n-inputs (length inputs))
        (stride (1+ (apply #'max (mapcar #'third inputs))))
        (src-fns (get-source-functions inputs))
        (vertex-ht (make-hash-table :test #'equalp)))
    (format t "lenght of ")
    (list
     ;; ELEMENTS
     (iter
      (with curr-index = 0)
      (for elt in elements)
      (let* ((indices (element-indices elt))
             (n-verts (/ (length indices) stride))
             (new-indices (make-array n-verts :fill-pointer 0)))

        ;; for each index in this element, build the array of unified
        ;; vertex streams
        (iter (for i below (length indices) by stride)
              (let ((vertex (subseq indices i (+ i stride))))
                (if-let (it (gethash vertex vertex-ht))
                        (vector-push it new-indices)
                        (progn
                          (setf (gethash vertex vertex-ht)
                                curr-index)
                          (vector-push curr-index new-indices)
                          (iter (for f in src-fns)
                                ;;(for i in-vector vertex)
                                (funcall (first f) (svref vertex (third f))))
                          (incf curr-index)))))
        (collect (make-element
                  :indices new-indices
                  :material (element-material elt)
                  :count (element-count elt)
                  ))))

     ;; VERTEX-STREAMS
     (iter (for (semantic source) in inputs)
           (for fn in src-fns)
           (collect
            (make-instance 'vertex-stream
                           :semantic semantic
                           :stream (second fn)
                           :stride (length (src-components source))))))))


(defun mesh-list->blt-mesh (mesh-lst)
  "Converts a list of form (id (element*) (input*)) into a
   blt-mesh object"
  (destructuring-bind (id elements inputs) mesh-lst
    (destructuring-bind (new-elements vertex-streams)
        (unify-indices elements inputs)
          (make-blt-mesh :id id
                     :vertex-streams vertex-streams
                     :elements new-elements))))
