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
;;; Collada Tag names
;;;

(defvar +instance-geometry+ "instance_geometry")


;;;
;;; Collada load functions
;;;

;; this'll be fun....
;; gets a function that will modify a slot/location based on an id...
;; Note: for starters will only support one level.
;; nodes is a list of scene nodes (
(defun get-location-fn (loc nodes)
  (labels ((node-finder (node-id nodes)
             (iter (for node in nodes)
                   (if (equal node-id (id node)) (return node))
                   (node-finder node-id (children node))))

           (split-loc (str start)
             (let ((p1 (position #\/ str :start start)))
               (if p1
                   (cons (subseq str start p1)
                         (tokenize-loc str (1+ p1)))
                   (if (< start (length str))
                       (cons (subseq str start) nil)
                       nil))))))

  (destructuring-bind (node-id location &rest dc) (split-loc loc 0)
    (let ((node (node-finder node-id nodes)))
      ;; Set up the function, and stuff
      #'(lambda (val) (setf (slot-value node transform) val)))))


;; Responsible for taking the table in the tables
;; and compiling it to a dae-object
(defun compile-dae-data (&key geometry scenes materials animations)
  (let ((meshes 
         (iter (for (node xform mesh-id mats) in scenes)
               (let* ((mesh (gethash mesh-id geometry))
                      (mat-array (make-array (length (elements mesh)))))
                 ;; Build the material-array (mat-id: (index . material-id))
                 (iter (for elt in (elements mesh))
                       (with-slots ((mat-id material)) elt
                         (setf (aref mat-array (car mat-id)) 
                               (aif (find (cdr mat-id) 
                                          mats :test #'equal :key #'car)
                                    (gethash (second it) materials)
                                    nil))
                                        ;(setf mat-id (car mat-id))
                         ))
                 (collect (make-model-node :transform xform
                                           :material-array mat-array
                                           :mesh mesh)))
               ;; T0D0: stuff
               ))
        (anims     
         ;; Need to update the animation clips with the proper target fn
         (when animations
           (iter (for (anim-id clip) in-hashtable animations)
                 (iter (for ch in (channel-list clip))
                       (setf (target ch) (get-location-fn (target ch) meshes)))
                 (collect clip)))))

    (make-instance 
     'blt-model
     :nodes meshes
     :animations anims)))


(defvar *geometry-table* nil)
(defvar *scene-table* nil)
(defvar *material-table* nil)

;; Returns an intermediate representation of the dae file
(defun load-dae (filename)
  "Loads the objects from a dae file"
  (let ((dae-file (cxml:parse-file filename
                   #+disabled(blt3d-res:resolve-resource filename) 
                                   (cxml-xmls:make-xmls-builder))))
    
    (let ((*material-table* 
           (process-materials
            (find-tag-in-children +material-library+ dae-file)
            (find-tag-in-children +image-library+ dae-file)
            (find-tag-in-children +effect-library+ dae-file)))
          (*geometry-table* 
           (process-geometry 
            (find-tag-in-children +geometry-library+ dae-file)))
          (*scene-table*    
           (process-scene 
            (find-tag-in-children +scene-library+ dae-file))))
      ;; Combine all the tables into a list of model-shape objects
      (compile-dae-data :geometry *geometry-table*
                        :scenes   *scene-table*
                        :materials *material-table*
                        ;; TODO: implement animations
                        ;;:animations *animation-table*
                        ))))