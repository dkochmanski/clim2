;; -*- mode: common-lisp; package: xm-silica -*-
;;
;;				-[]-
;; 
;; copyright (c) 1985, 1986 Franz Inc, Alameda, CA  All rights reserved.
;; copyright (c) 1986-1991 Franz Inc, Berkeley, CA  All rights reserved.
;;
;; The software, data and information contained herein are proprietary
;; to, and comprise valuable trade secrets of, Franz, Inc.  They are
;; given in confidence by Franz, Inc. pursuant to a written license
;; agreement, and may be stored and used only in accordance with the terms
;; of such license.
;;
;; Restricted Rights Legend
;; ------------------------
;; Use, duplication, and disclosure of the software, data and information
;; contained herein by any agency, department or entity of the U.S.
;; Government are subject to restrictions of Restricted Rights for
;; Commercial Software developed at private expense as specified in FAR
;; 52.227-19 or DOD FAR Supplement 252.227-7013 (c) (1) (ii), as
;; applicable.
;;
;; $fiHeader: ol-gadgets.lisp,v 1.15 92/06/29 14:05:10 cer Exp Locker: cer $


(in-package :xm-silica)

(defmethod make-pane-class ((framem openlook-frame-manager) class &rest options) 
  (declare (ignore options))
  (second (assoc class '(
			 ;; An experiment
			 (outlined-pane openlook-frame-pane)
			 ;;
			 (scroll-bar openlook-scroll-bar)
			 (slider openlook-slider)
			 (push-button openlook-push-button)
			 (label-pane openlook-label-pane)
			 (text-field openlook-text-field)
			 (text-editor openlook-text-editor)
			 (toggle-button openlook-toggle-button)
			 (menu-bar openlook-menu-bar)
			 (viewport ol-viewport)
			 (radio-box openlook-radio-box)
			 (frame-pane openlook-frame-pane)
			 (top-level-sheet openlook-top-level-sheet)
			 (list-pane openlook-list-pane)
			 (option-pane openlook-option-pane)))))


;;;;;;;;;;;;;;;;;;;;

(defclass openlook-scroll-bar (scroll-bar
			       xt-leaf-pane)
	  ())

(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet openlook-scroll-bar))
  (with-accessors ((orientation gadget-orientation)) sheet
		  (values 'tk::scrollbar
			  (list :orientation orientation))))

(defmethod (setf scroll-bar-size) (nv (sb openlook-scroll-bar))
  ;; (tk::set-values (sheet-direct-mirror sb) :slider-size nv)
  nv)

(defmethod (setf scroll-bar-value) (nv (sb openlook-scroll-bar))
  (tk::set-values (sheet-direct-mirror sb) :slider-value nv)
  nv)

(defmethod change-scroll-bar-values ((sb openlook-scroll-bar) &key slider-size value)
  (let ((mirror (sheet-direct-mirror sb)))
    (multiple-value-bind
	(mmin mmax) (tk::get-values mirror :slider-min :slider-max)
      (multiple-value-bind
	  (real-value real-size) (compute-new-scroll-bar-values sb mmin mmax value slider-size)
	(tk::set-values
	 mirror
	 :proportion-length  real-size
	 :slider-value real-value)))))

(defmethod add-sheet-callbacks :after  ((port openlook-port) (sheet openlook-scroll-bar) (widget t))
  (tk::add-callback widget
		    :slider-moved
		    'scroll-bar-changed-callback-1
		    sheet))

(defmethod scroll-bar-changed-callback-1 ((widget t) (sheet openlook-scroll-bar))
  (multiple-value-bind
      (smin smax) (gadget-range* sheet)
    (multiple-value-bind
	(value size mmin mmax)
	(tk::get-values widget :slider-value :proportion-length :slider-min :slider-max)
      (scroll-bar-value-changed-callback
       sheet
       (gadget-client sheet)
       (gadget-id sheet)
       (compute-symmetric-value
	mmin mmax value smin smax)
       (compute-symmetric-value
	mmin mmax size smin smax)))))

(defmethod compose-space ((m openlook-scroll-bar) &key width height)
  (let ((x 16))
    (ecase (gadget-orientation m)
      (:vertical
       (make-space-requirement :width x
			       :min-height x
			       :height (* 2 x)
			       :max-height +fill+))
      (:horizontal
       (make-space-requirement :height x
			       :min-width x
			       :width (* 2 x)
			       :max-width +fill+)))))

;;; Ol DrawArea Widgets require all of this

(ff:defun-c-callable ol-ignore-help-function (id-type id src-x src-y)
  (declare (ignore id-type id src-x src-y))
  nil)

(defvar *ol-ignore-help-function-address* (ff:register-function 'ol-ignore-help-function))

(defmethod add-sheet-callbacks :after  ((port openlook-port) (sheet t) (widget tk::draw-area))
  (tk::add-callback widget 
		    :expose-callback 
		    'sheet-mirror-exposed-callback
		    sheet)
  (tk::add-event-handler widget
			 '(:key-press 
			   :key-release
			   :button-press 
			   :button-release
			   ;; 
			   :enter-window 
			   :leave-window
			   :pointer-motion-hint
			   :pointer-motion
			   :button1-motion
			   :button2-motion
			   :button3-motion
			   :button4-motion
			   :button5-motion
			   :button-motion
			   )
			 1
			 'sheet-mirror-event-handler
			 sheet)
  (tk::ol_register_help
   tk::ol_widget_help
   widget
   "foo"
   tk::ol_transparent_source
   *ol-ignore-help-function-address*
   ))

;;; top level sheet

(defclass openlook-top-level-sheet (top-level-sheet) ())

(defmethod add-sheet-callbacks :after ((port openlook-port) 
				       (sheet openlook-top-level-sheet)
				       widget)
  (tk::add-callback widget 
		    :resize-callback 'sheet-mirror-resized-callback
		    sheet))

(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet openlook-top-level-sheet))
  (values 'tk::draw-area (list :layout :ignore)))


;;

(defclass openlook-frame-pane (sheet-single-child-mixin
			       sheet-permanently-enabled-mixin
			       wrapping-space-mixin
			       pane)
	  ())

(defmethod initialize-instance :after ((fr openlook-frame-pane) &key frame frame-manager contents thickness)
  (declare (ignore frame frame-manager thickness))
  (sheet-adopt-child fr contents))

;; OpenLook viewport

(defclass ol-viewport
	  (mirrored-sheet-mixin
	   viewport)
    ())

(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet ol-viewport))
  (values 'tk::draw-area
	  '(:layout :ignore)))

(defmethod add-sheet-callbacks  :after ((port openlook-port) (sheet ol-viewport) widget)
  ;; I wonder whether this is needed since it should not be resized by
  ;; the toolkit and only as part of the goe management code that will
  ;; recurse to children anyway
  (tk::add-callback widget 
		    :resize-callback 
		    'sheet-mirror-resized-callback
		    sheet)
;  (tk::add-callback widget 
;		    :expose-callback 
;		    'sheet-mirror-exposed-callback
;		    sheet)
;  (tk::add-callback widget 
;		    :input-callback 
;		    'sheet-mirror-input-callback
;		    sheet)
;  (tk::add-event-handler widget
;			 '(:enter-window 
;			   :leave-window
;			   :pointer-motion-hint
;			   :pointer-motion
;			   :button1-motion
;			   :button2-motion
;			   :button3-motion
;			   :button4-motion
;			   :button5-motion
;			   :button-motion
;			   )
;			 0
;			 'sheet-mirror-event-handler
;			 sheet)
  )

(defclass openlook-menu-bar (xt-leaf-pane) 
	  ((command-table :initarg :command-table)))

(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet openlook-menu-bar))
  (values 'tk::control nil))

(defmethod realize-mirror :around ((port openlook-port) (sheet openlook-menu-bar))

  ;; This code fills the menu-bar. If top level items do not have
  ;; submenus then it creates one with a menu of its own
  
  (let ((mirror (call-next-method)))
    (labels ((make-menu-for-command-table (command-table parent top)
	       (map-over-command-table-menu-items
		#'(lambda (menu keystroke item)
		    (declare (ignore keystroke))
		    (let ((type (command-menu-item-type item)))
		      (case type
			(:divider)
			(:function
			 ;;--- Do this sometime
			 )
			(:menu
			 (let* ((mb (make-instance 'tk::menu-button
						  :parent parent
						  :label menu)))
			   (make-menu-for-command-table
			    (find-command-table (second item))
			    (tk::get-values mb :menu-pane)
			    nil)))
			(t
			 (let ((button 
				(make-instance 'tk::oblong-button
					       :label menu
					       :managed t
					       :parent parent)))
			   (tk::add-callback
			    button
			    :select
			    'command-button-callback-ol
			    (slot-value sheet 'silica::frame)
			    command-table
			    item))))))
		command-table)))
      (make-menu-for-command-table
       (slot-value sheet 'command-table)
       mirror
       t))
    mirror))

(defun command-button-callback-ol (button frame command-table item)
  (command-button-callback button nil frame command-table item))


;;; Label pane

(defclass openlook-label-pane (label-pane xt-leaf-pane) 
	  ())

(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet openlook-label-pane))
  (with-accessors ((label gadget-label)
		   (alignment gadget-alignment)) sheet
    (values 'tk::static-text
	    (append
	     (list :alignment 
		   (ecase alignment
		     ((:left nil) :left)
		     (:center :center)
		     (:right :right)))
	     (and label (list :string label))))))
  
;;; Push button

(defclass openlook-push-button (push-button
				openlook-action-pane
				xt-leaf-pane) 
	  ())



(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet openlook-push-button))
  (with-accessors ((label gadget-label)) sheet
    (values 'tk::oblong-button 
	    (and label (list :label label)))))

;;


(defclass openlook-action-pane () ())

(defmethod add-sheet-callbacks :after ((port openlook-port) (sheet openlook-action-pane) (widget t))
  (tk::add-callback widget
		    :select
		    'queue-active-event-ol
		    sheet))

(defmethod queue-active-event-ol (widget (sheet openlook-action-pane))
  (declare (ignore widget))
  (distribute-event
   (port sheet)
   (make-instance 'activate-gadget-event
		  :gadget sheet)))


;;; Text field

(defclass openlook-text-field (text-field xt-leaf-pane)
	  ())

(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet openlook-text-field))
  (with-accessors ((value gadget-value)) sheet
    (values 'tk::text-field
	    (append
	     (and value `(:string ,value))))))

(defun openlook-text-field-edit-widget (tf &optional (mirror (sheet-direct-mirror tf)))
  (tk::get-values mirror :text-edit-widget))

(defmethod add-sheet-callbacks :after ((port openlook-port) 
				       (sheet openlook-text-field) 
				       (widget t))
  (tk::add-callback (openlook-text-field-edit-widget sheet widget)
		    :post-modify-notification
		    'queue-value-changed-event
		    sheet))

(defmethod gadget-value ((gadget openlook-text-field))
  (if (sheet-direct-mirror gadget)
      (text-editor-text (openlook-text-field-edit-widget gadget))
    (call-next-method)))


(defmethod (setf gadget-value) :after 
	   (nv (gadget openlook-text-field) &key invoke-callback)
  (declare (ignore invoke-callback))
  (when (sheet-direct-mirror gadget)
    (setf (text-editor-text (openlook-text-field-edit-widget gadget)) nv)))

;;--- We need to implement the activate callback stuff so that when
;;--- the user hits return we invoke the callback. I guess we need to
;;-- look at whats been inserted.


;;; Value stuff
;;; I suspect that this is worthless

(defclass openlook-value-pane () ())

(defmethod add-sheet-callbacks :after ((port openlook-port) 
				       (sheet openlook-value-pane) (widget t))
  #+igore
  (tk::add-callback widget
		    :value-changed-callback
		    'queue-value-changed-event
		    sheet))

(defmethod gadget-value ((gadget openlook-value-pane))
  (if (sheet-direct-mirror gadget)
      (tk::get-values (sheet-mirror gadget) :value)
    (call-next-method)))

(defmethod (setf gadget-value) :after 
	   (nv (gadget openlook-value-pane) &key invoke-callback)
  (declare (ignore invoke-callback))
  (when (sheet-direct-mirror gadget)
    (tk::set-values (sheet-mirror gadget) :value nv)))

;;;

(defclass openlook-labelled-gadget () ())

(defmethod find-widget-class-and-initargs-for-sheet
    :around ((port openlook-port)
	     (parent t)
	     (sheet openlook-labelled-gadget))
  (multiple-value-bind
      (class initargs)
      (call-next-method)
    (with-accessors ((alignment gadget-alignment)
		     (label gadget-label)) sheet
      (when label
	(unless (getf initargs :label)
	  (setf (getf initargs :label) label)))
      (unless (getf initargs :label-justify)
	(setf (getf initargs :label-justify) 
	  (ecase alignment
	    (:center :left)
	    ((:left :right)  alignment)))))
    (values class initargs)))

(defmethod (setf gadget-label) :after (nv (sheet openlook-labelled-gadget))
  (when (sheet-direct-mirror sheet)
    (tk::set-values (sheet-direct-mirror sheet) :label (or nv ""))))

(defmethod (setf gadget-alignment) :after (nv (sheet openlook-labelled-gadget))
  (when (sheet-direct-mirror sheet)
    (tk::set-values (sheet-direct-mirror sheet) 
		    :label-justify (ecase nv
				     (:center nv)
				     ((:left :right) nv)))))

;; Toggle button

(defclass openlook-toggle-button (toggle-button
				openlook-labelled-gadget
				openlook-value-pane
				xt-leaf-pane)
	  ())

(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet openlook-toggle-button))
  (with-accessors ((set gadget-value)
		   (indicator-type gadget-indicator-type)) sheet
    (values (typecase (sheet-parent sheet)
	      (openlook-radio-box 'xt::rect-button)
	      (openlook-check-box 'xt::rect-button)
	      (t 'xt::check-box))
	    (append (list :set set)
		    #+dunno
		    (list :indicator-type 
			  (ecase indicator-type
			    (:one-of :one-of-many)
			    (:some-of :n-of-many)))))))

;; check-box, rect  select, unselect callback, :set resource

(defmethod add-sheet-callbacks :after ((port openlook-port) 
				       (sheet openlook-toggle-button) 
				       (widget t))
  (tk::add-callback widget
		    :select
		    'queue-value-changed-event
		    sheet)
  (tk::add-callback widget
		    :unselect
		    'queue-value-changed-event
		    sheet))

(defmethod gadget-value ((gadget openlook-toggle-button))
  (if (sheet-direct-mirror gadget)
      (tk::get-values (sheet-mirror gadget) :set)
    (call-next-method)))

(defmethod (setf gadget-value) :after 
	   (nv (gadget openlook-toggle-button) &key invoke-callback)
  (declare (ignore invoke-callback))
  (when (sheet-direct-mirror gadget)
    (tk::set-values (sheet-mirror gadget) :set nv)))




;;; 

;; Openlook-orriented-gadget

(defclass openlook-oriented-gadget () ())

(defmethod find-widget-class-and-initargs-for-sheet :around ((port openlook-port)
							     (parent t)
							     (sheet openlook-oriented-gadget))
  (multiple-value-bind
      (class initargs)
      (call-next-method)
    (with-accessors ((orientation gadget-orientation)) sheet
      (unless (getf initargs :orientation)
	(setf (getf initargs :orientation) orientation)))
    (values class initargs)))

(defmethod (setf gadget-orientation) :after (nv (gadget openlook-oriented-gadget))
  (when (sheet-direct-mirror gadget)
    (tk::set-values (sheet-direct-mirror gadget) :orientation nv)))


;;

(defclass openlook-radio-box (openlook-geometry-manager 
			      mirrored-sheet-mixin
			      #+ignore ;;-- Need to decide
			      openlook-oriented-gadget
			      sheet-multiple-child-mixin
			      sheet-permanently-enabled-mixin
			      radio-box
			      ask-widget-for-size-mixin
			      pane)
	  ())

(defmethod sheet-adopt-child :after ((gadget openlook-radio-box) child)
  (setf (gadget-client child) gadget))

(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet openlook-radio-box))
  (values 'xt::exclusives nil))

(defmethod value-changed-callback :around ((v gadget)
					   (client openlook-radio-box)
					   (id t)
					   (value t))
  (when (eq value t)
    (setf (radio-box-current-selection client) v)
    (value-changed-callback client 
			    (gadget-client client)
			    (gadget-id client) 
			    v))
  (call-next-method))

(defmethod compose-space ((rb openlook-radio-box) &key width height)
  (declare (ignore width height))
  (let ((w 0)
	(h 0))
    (dolist (child (tk::widget-children (sheet-direct-mirror rb)))
      (multiple-value-bind
	  (ignore-x igore-y width height)
	  (xt::widget-best-geometry child)
	(maxf h height)
	(incf w width)))
    (make-space-requirement :width w :height h)))
;;;


(defclass openlook-check-box (openlook-geometry-manager
			      mirrored-sheet-mixin
			      #+Dunno ;;--- what do do about tihs
			      openlook-oriented-gadget
			      sheet-multiple-child-mixin
			      sheet-permanently-enabled-mixin
			      check-box
			      ask-widget-for-size-mixin
			      pane)
	  ())

(defmethod sheet-adopt-child :after ((gadget openlook-check-box) child)
  (setf (gadget-client child) gadget))

(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet openlook-check-box))
  
  (values 'xt::nonexclusives nil))

(defmethod value-changed-callback :around ((v gadget)
					   (client openlook-check-box)
					   (id t)
					   (value t))
  (if (eq value t)
      (push v (check-box-current-selection client))
    (setf (check-box-current-selection client)
      (delete v (check-box-current-selection client))))
  (value-changed-callback client 
			  (gadget-client client)
			  (gadget-id client) 
			  (check-box-current-selection client))
  (call-next-method))

;;

;; Openlook-orriented-gadget


(defclass openlook-slider (#+ignore openlook-range-pane
			   #+ignore openlook-oriented-gadget
			   xt-leaf-pane
			   slider)
	  ())


(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet openlook-slider))
  (with-accessors ((label gadget-label)
		   (show-value-p gadget-show-value-p)
		   (value gadget-value)
		   (orientation gadget-orientation)) sheet
    (multiple-value-bind
	(smin smax) (gadget-range* sheet)
      (let ((mmin 0) 
	    (mmax 100))
	(values 'tk::slider
		(append
		 (list :orientation orientation)
		 #+dunno
		 (and label (list :title-string label))
		 (list :slider-min mmin
		       :slider-max mmax)
		 (and value 
		      (list :slider-value 
			    (fix-coordinate 
				    (compute-symmetric-value
				     smin smax value mmin
				     mmax))))))))))

(defmethod gadget-value ((slider openlook-slider))
  (if (sheet-direct-mirror slider)
      (compute-slider-value slider)
    (call-next-method)))

(defmethod (setf gadget-value) :after  (nv (slider openlook-slider) &key invoke-callback)
  (declare (ignore invoke-callback))
  (when (sheet-direct-mirror slider)
    (set-slider-value slider nv)))

(defun compute-slider-value (sheet)
  (let ((widget (sheet-direct-mirror sheet)))
    (multiple-value-bind
	(smin smax) (gadget-range* sheet)
      (multiple-value-bind
	  (value mmin mmax)
	  (tk::get-values widget :slider-value :slider-min :slider-max)
	(compute-symmetric-value
			 mmin mmax value smin smax)))))


(defun set-slider-value (sheet nv)
  (let ((widget (sheet-direct-mirror sheet)))
    (multiple-value-bind
	(smin smax) (gadget-range* sheet)
      (multiple-value-bind
	  (mmin mmax)
	  (tk::get-values widget :slider-min :slider-max)
	(tk::set-values widget
			:slider-value
			(round
			 (compute-symmetric-value
			   smin smax  nv mmin mmax)))))))

(defmethod add-sheet-callbacks :after ((port openlook-port) 
				       (sheet openlook-slider)
				       (widget t))
  (tk::add-callback widget :slider-moved 'slider-changed-callback-1 sheet))

(defmethod slider-changed-callback-1 ((widget t) (sheet openlook-slider))
  (queue-value-changed-event widget sheet))

(defmethod compose-space ((m openlook-slider) &key width height)
  (declare (ignore width height))
  (let ((sr (copy-space-requirement (call-next-method))))
    (ecase (gadget-orientation m)
      (:vertical
       (setf (space-requirement-max-height sr) +fill+))
      (:horizontal
       (setf (space-requirement-max-width sr) +fill+)))
    sr))

#+dunno
(defmethod (setf gadget-show-value-p) :after (nv (sheet openlook-slider)) 
  (when (sheet-direct-mirror sheet)
    (tk::set-values (sheet-direct-mirror sheet) :show-value nv)))

#+dunno 
(defmethod (setf gadget-label) :after (nv (sheet openlook-slider))
  (when (sheet-direct-mirror sheet)
    (tk::set-values (sheet-direct-mirror sheet) :title-string (or nv ""))))

;;; 

(defclass openlook-text-editor (text-editor xt-leaf-pane)
	  ())

(defmethod text-editor-text ((te openlook-text-editor))
  (let ((widget (sheet-direct-mirror te)))
    (tk::with-ref-par ((end 0)
		       (string 0))
      (assert (not (zerop (tk::ol_text_edit_get_last_position widget end))))
      (assert (not (zerop (tk::ol_text_edit_read_substring 
			   widget string 0 (aref end 0)))))
      (ff::char*-to-string (aref string 0)))))


(defmethod (setf text-editor-text) (nv (te openlook-text-editor))
  (let ((widget (sheet-direct-mirror te)))
    (assert (not (zerop (tk::ol_text_edit_clear_buffer widget))))
    (assert (not (zerop (tk::ol_text_edit_insert widget nv (length nv))))))
  nv)


(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet
						      openlook-text-editor))
  (with-accessors ((value gadget-value)
		   (ncolumns silica::gadget-columns)
		   (nlines silica::gadget-lines)) sheet
    (values 'tk::text-edit
	    (append
	     (and ncolumns (list :chars-visible ncolumns))
	     (and nlines (list :lines-visible nlines))
	     (and value `(:source ,value))))))

(defmethod add-sheet-callbacks :after ((port openlook-port) 
				       (sheet openlook-text-editor) 
				       (widget t))
  (tk::add-callback widget
		    :post-modify-notification
		    'queue-value-changed-event
		    sheet))

(defmethod compose-space ((te openlook-text-editor) &key width height)
  (declare (ignore width height))
  (let ((sr (call-next-method)))
    (setq sr (copy-space-requirement sr))
    ;;-- What it the correct thing to do???
    (setf (space-requirement-max-width sr) +fill+
	  (space-requirement-max-height sr) +fill+)
    sr))

(defmethod gadget-value ((gadget openlook-text-editor))
  (if (sheet-direct-mirror gadget)
      (text-editor-text gadget)
    (call-next-method)))

(defmethod (setf gadget-value) :after 
	   (nv (gadget openlook-text-editor) &key invoke-callback)
  (declare (ignore invoke-callback))
  (when (sheet-direct-mirror gadget)
    (setf (text-editor-text gadget) nv)))


(defmethod gadget-supplies-scrolling-p ((contents openlook-text-editor))
  t)

;;;
;;;--- This code is so much like the motif one I think we could share
;;;--- code.

(defclass openlook-scrolling-window (scroller-pane
				     openlook-geometry-manager
				     ask-widget-for-size-mixin
				     mirrored-sheet-mixin
				     sheet-multiple-child-mixin
				     sheet-permanently-enabled-mixin
				     pane)
	  ;;-- probably one of the options is whether to have vertical
	  ;;-- and/or horizontal scrollbars
	  ())


;;-- Very similar to the motif code.

(defmethod initialize-mirror :after ((port openlook-port)
				     (parent openlook-geometry-manager)
				     (parent-widget t)
				     (sheet t)
				     (widget t))
  ;; This is a pane in the butt since you only get configure-notify
  ;; events after you have been created
  ;; Really Xt should have a callback for this. Not the drawing area.
  (typecase widget
    (tk::draw-area
     (tk::add-callback widget 
      :resize-callback 
      'sheet-mirror-resized-callback
      sheet))
    (t
     (tk::add-event-handler widget
			    '(:structure-notify)
			    1
			    'sheet-mirror-event-handler
			    sheet))))


;;--- this is almost identical to the motif code

(defmethod initialize-instance :after ((sp openlook-scrolling-window)
				       &key scroll-bars contents frame-manager frame)
  (if (setf (silica::scroller-pane-gadget-supplies-scrolling-p sp)
	(gadget-supplies-scrolling-p contents))
      (sheet-adopt-child sp contents)
    (with-look-and-feel-realization (frame-manager frame)
      (when (member scroll-bars '(:both :dynamic :vertical))
	(let ((sb (make-pane 'scroll-bar :orientation :vertical :id :vertical :client sp)))
	  (setf (silica::scroller-pane-vertical-scroll-bar sp) sb)
	  (sheet-adopt-child sp sb)))
      (when (member scroll-bars '(:both :dynamic :horizontal))
	(let ((sb (make-pane 'scroll-bar :orientation :horizontal :id :horizontal :client sp)))
	  (setf (silica::scroller-pane-horizontal-scroll-bar sp) sb)
	  (sheet-adopt-child sp sb)))
      (sheet-adopt-child sp (setf (slot-value sp 'viewport) (make-pane 'viewport :scroller-pane sp)))
      (sheet-adopt-child (slot-value sp 'viewport) contents))))

(defmethod realize-widget-mirror ((port openlook-port) (parent-sheet openlook-scrolling-window)
						       (parent-widget t)
						       (sheet openlook-scroll-bar))
  (tk::get-values parent-widget
   (ecase (gadget-orientation sheet)
     (:horizontal :h-scrollbar)
     (:vertical  :v-scrollbar))))

(defmethod gadget-supplies-scrolling-p ((contents t))
  nil)

(defmethod make-pane-class ((framem openlook-frame-manager) 
			    (class (eql 'silica::generic-scroller-pane)) 
			    &rest options
			    &key contents)
  (declare (ignore options))
  (if (gadget-includes-scrollbars-p contents)
      'openlook-frame-pane
    'openlook-scrolling-window))

(defmethod gadget-includes-scrollbars-p ((pane t))
  nil)

#+ignore
(defmethod initialize-instance :after ((pane openlook-scrolling-window) &key contents)
  (sheet-adopt-child pane contents))

(defmethod compose-space ((fr openlook-scrolling-window) &key width height)
  (declare (ignore width height))
  ;;--- This is not quite right because I think scrollbars are a bit
  ;;--- bigger than this. But atleast its a start
  ;;-- We check to see which scrollbars we have

  (let* (
	 (spacing 0 #+ignore (tk::get-values (sheet-mirror fr) :spacing))
	 (sr (copy-space-requirement (compose-space (silica::pane-contents fr)))))

    ;;--- if scroller-pane-gadget-supplies-scrolling-p is true we should
    ;;--- do something different. Perhaps we can ask the widget itself
    ;;--  for the overall size but what about the min size. Otherwise we
    ;;-- might need to do this is a grubby way.
    ;; Perhaps we just call compose-space on the child and then add in
    ;; the size of the scroll-bars.
    (if (silica::scroller-pane-gadget-supplies-scrolling-p fr)
	(multiple-value-bind
	    (hb vb)
	    (tk::get-values (sheet-direct-mirror fr) :h-scrollbar :v-scrollbar)
	  (let ((ha (and hb (xt::is-managed-p hb) (tk::get-values hb :height)))
		(va (and vb (xt::is-managed-p vb) (tk::get-values vb :width))))
	    (when va (maxf (space-requirement-height sr) (+ spacing (* 2 va))))
	    (when ha (incf (space-requirement-height sr) (+ spacing ha)))
	    (when va (maxf (space-requirement-min-height sr) (+ spacing (* 2 va))))
	    (when ha (incf (space-requirement-min-height sr) (+ spacing ha)))
	    (maxf (space-requirement-max-height sr) (space-requirement-height sr))
    
	    (when ha (maxf (space-requirement-width sr) (+ spacing (* 2 ha))))
	    (when va (incf (space-requirement-width sr) (+ spacing va)))
	    (when ha (maxf (space-requirement-min-width sr) (+ spacing (* 2 ha))))
	    (when va (incf (space-requirement-min-width sr) (+ spacing va)))
	    (maxf (space-requirement-max-width sr) (space-requirement-width sr))))
      (let* ((vsb (silica::scroller-pane-vertical-scroll-bar fr))
	     (vsb-sr (and vsb (compose-space vsb)))
	     (hsb (silica::scroller-pane-horizontal-scroll-bar fr))
	     (hsb-sr (and hsb (compose-space hsb))))
	(when vsb-sr (maxf (space-requirement-height sr) (+ spacing (space-requirement-min-height vsb-sr))))
	(when hsb-sr (incf (space-requirement-height sr) (+ spacing (space-requirement-height hsb-sr))))
	(when vsb-sr (maxf (space-requirement-min-height sr) (+ spacing (space-requirement-min-height vsb-sr))))
	(when hsb-sr (incf (space-requirement-min-height sr) (+ spacing (space-requirement-height hsb-sr))))
	(maxf (space-requirement-max-height sr) (space-requirement-height sr))
    
	(when hsb-sr (maxf (space-requirement-width sr) (+ spacing (space-requirement-min-width hsb-sr))))
	(when vsb-sr (incf (space-requirement-width sr) (+ spacing (space-requirement-width vsb-sr))))
	(when hsb-sr (maxf (space-requirement-min-width sr) (+ spacing (space-requirement-min-width hsb-sr))))
	(when vsb-sr (incf (space-requirement-min-width sr) (+ spacing (space-requirement-width vsb-sr))))
	(maxf (space-requirement-max-width sr) (space-requirement-width sr))))
    sr))

#+ignore
(defmethod compose-space ((fr openlook-scrolling-window) &key width height)
  (declare (ignore width height))
  ;;--- This is not quite right because I think scrollbars are a bit
  ;;--- bigger than this. But atleast its a start
  (let ((fudge-factor (+ 21
			 #+ignore
			 (tk::get-values (sheet-mirror fr)
					 :spacing)))
	(sr (copy-space-requirement (compose-space (silica::pane-contents fr)))))
    (incf (space-requirement-width sr) fudge-factor)
    (incf (space-requirement-height sr) fudge-factor)
    ;;--- Is this the correct thing to do???
    (setf (space-requirement-min-width sr) fudge-factor
	  (space-requirement-min-height sr) fudge-factor)
    sr))


(ff:defun-c-callable scrolling-window-geometry-function ((content :unsigned-long)
							 (geometries :unsigned-long))
  (let* ((viewport (find-sheet-from-widget-address content))
	 (scrolling-window (sheet-parent viewport)))
    (multiple-value-bind
	(swidth sheight) (tk::get-values (sheet-direct-mirror
					  scrolling-window) :width :height)
      (let ((hsb-height (tk::ol-sw-geometries-hsb-height geometries))
	    (vsb-width (tk::ol-sw-geometries-vsb-width geometries)))
	(let ((w (- swidth vsb-width))
	      (h (- sheight hsb-height)))
	  (setf (tk::ol-sw-geometries-force-hsb geometries) 
	    (if (silica::scroller-pane-horizontal-scroll-bar scrolling-window) 1 0))
	  (setf (tk::ol-sw-geometries-force-vsb geometries) 
	    (if (silica::scroller-pane-vertical-scroll-bar scrolling-window) 1 0))
	  (when (plusp w) (setf (tk::ol-sw-geometries-bbc-width geometries) w))
	  (when (plusp h) (setf (tk::ol-sw-geometries-bbc-height geometries) h)))))))

(defvar *scrolling-window-geometry-function-address* 
    (ff::register-function 'scrolling-window-geometry-function))

(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet openlook-scrolling-window))
  (values 'xt::scrolled-window 
	  (and (not (gadget-supplies-scrolling-p (silica::pane-contents sheet)))
	       `(:h-auto-scroll nil 
				:v-auto-scroll nil
				:compute-geometries ,*scrolling-window-geometry-function-address*
				))))



;;; 

(defclass openlook-list-pane (list-pane xt-leaf-pane)
	  ((item-list :accessor list-pane-item-list)
	   (token-list :accessor list-pane-token-list)
	   (current-tokens :initform nil :accessor list-pane-current-tokens)))


(defmethod gadget-includes-scrollbars-p ((gadget openlook-list-pane))
  gadget)

(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet openlook-list-pane))
  (with-accessors ((items set-gadget-items)
		   (value gadget-value)
		   (value-key set-gadget-value-key)
		   (test set-gadget-test)
		   (mode list-pane-mode)
		   (name-key set-gadget-name-key)) sheet
    (values 'xt::ol-list nil)))

(defmethod realize-mirror :around ((port openlook-port) (sheet openlook-list-pane))
  (let ((widget (call-next-method))
	(item-list nil)
	(token-list nil)
	selected-tokens
	(count 0))
    (with-accessors ((items set-gadget-items)
		     (value gadget-value)
		     (value-key set-gadget-value-key)
		     (test set-gadget-test)
		     (mode list-pane-mode)
		     (name-key set-gadget-name-key)) sheet
      (dolist (item items)
	(let ((x (tk::make-ol-list-item :in-foreign-space t))
	      (selected-p (list-pane-selected-item-p sheet item)))
	  (setf (tk::ol-list-item-label-type x) tk::ol-string
		(tk::ol-list-item-label x) (tk::string-to-char* (funcall name-key item))
		(tk::ol-list-item-mnemonic x) 0
		(tk::ol-list-item-attr x)
		(dpb (if selected-p 1 0)
		     '#.tk::ol_b_list_attr_current
		     (dpb count '#.tk::ol_b_list_attr_appl 0)))
	  (let ((token
		 (tk::ol_appl_add_item
		 (tk::get-values widget :appl-add-item)
		 widget
		 0
		 0
		 x)))
	    (push (list token count) token-list)
	    (when selected-p (push token selected-tokens))
	    (push x item-list))
	  (incf count)))
      (setf (list-pane-item-list sheet) (nreverse item-list)
	    (list-pane-token-list sheet) token-list
	    (list-pane-current-tokens sheet) selected-tokens)
      widget)))

(defmethod add-sheet-callbacks :after ((port openlook-port) 
				       (sheet openlook-list-pane) 
				       (widget t))
  (tk::add-callback widget
		    :user-make-current
		    'list-pane-value-changed
		    sheet))

(defun list-pane-value-changed (widget token sheet)
  ;; Need to decide between exclusive and nonexclusive etc etc
  (let ((item (find-list-pane-item-from-token token)))
    (with-accessors ((items set-gadget-items)
		     (value gadget-value)
		     (value-key set-gadget-value-key)
		     (test set-gadget-test)
		     (mode list-pane-mode)
		     (name-key set-gadget-name-key)) sheet
      (flet ((item-from-token (token)
	       (nth (second (assoc token (list-pane-token-list sheet))) items)))
	(ecase mode
	  (:exclusive
	   (unless (member token (list-pane-current-tokens sheet))
	     (let* ((old-token (car (list-pane-current-tokens sheet)))
		    (old-item (find-list-pane-item-from-token old-token)))
	       (setf (tk::ol-list-item-attr old-item)
		 (dpb 0 '#.tk::ol_b_list_attr_current (tk::ol-list-item-attr old-item))
		 (tk::ol-list-item-attr item)
		 (dpb 1 '#.tk::ol_b_list_attr_current (tk::ol-list-item-attr item)))
	       (touch-list-pane-item widget old-token)
	       (touch-list-pane-item widget token))
	     (setf (list-pane-current-tokens sheet) (list token)))
	   (queue-value-changed-event
	    widget sheet (funcall value-key 
				  (item-from-token 
				   (car (list-pane-current-tokens sheet))))))
	  (:nonexclusive
	   (if (member token (list-pane-current-tokens sheet))
	       (progn
		 (setf (list-pane-current-tokens sheet)
		   (delete token (list-pane-current-tokens sheet))
		   (tk::ol-list-item-attr item)
		   (dpb 0 '#.tk::ol_b_list_attr_current (tk::ol-list-item-attr item))))
	     (progn
	       (push token (list-pane-current-tokens sheet))
	       (setf (tk::ol-list-item-attr item)
		 (dpb 1 '#.tk::ol_b_list_attr_current
		      (tk::ol-list-item-attr item)))))
	   (touch-list-pane-item widget token)
	   (queue-value-changed-event
	    widget sheet (mapcar value-key (mapcar 
					    #'item-from-token
					    (list-pane-current-tokens sheet))))))))))



(defun touch-list-pane-item (widget token)
  (tk::ol_appl_touch_item (tk::get-values widget :appl-touch-item) widget token))

(defun find-list-pane-item-from-token (token)
  (tk::ol_list_item_pointer token))

;;;

(defclass openlook-option-pane (option-pane xt-leaf-pane)
	  ((buttons :accessor option-menu-buttons)))

(defmethod find-widget-class-and-initargs-for-sheet ((port openlook-port)
						     (parent t)
						     (sheet openlook-option-pane))
  (values 'xt::control nil))

(defmethod realize-mirror ((port openlook-port) (sheet openlook-option-pane))
  (with-accessors ((items set-gadget-items)
		   (name-key set-gadget-name-key)
		   (value-key set-gadget-value-key)
		   (test set-gadget-test)
		   (label gadget-label)) sheet
    (let* ((control (call-next-method))
	   (label (apply #'make-instance 'tk::static-text
			 :parent control
			 (append 
			  (and label `(:string ,label)))))
	   (widget (apply #'make-instance 
			  'xt::abbrev-menu-button
			  :parent control nil))
	   (preview (make-instance 'tk::static-text
				   :string "xxxxxxxxxxxxxxxxxxxxxxxx"
				   :parent control))
	   (menu-pane (tk::get-values widget :menu-pane)))
      (setf (option-menu-buttons sheet)
	(mapcar #'(lambda (item)
		    (let* ((currentp (funcall
				      test (funcall value-key item)
				      (gadget-value sheet)))
			   (label (funcall name-key item))
			   (button (make-instance 'tk::oblong-button
						  :default currentp
						  :label label
						  :parent menu-pane)))
		      (tk::add-callback button
					:select
					#'(lambda (&rest ignore)
					    (declare (ignore ignore))
					    (queue-value-changed-event
					     widget sheet (funcall
							   value-key item))
					    (tk::set-values button :default t)
					    (tk::set-values preview :string label)))
		      (when currentp
			(tk::set-values preview :string label))
		      (list button item)))
		items))
      (tk::set-values widget :preview-widget preview)
      control)))

(defmethod (setf gadget-value) :after (nv (sheet openlook-option-pane) &key invoke-callback)
  (declare (ignore invoke-callback))
  (with-accessors ((items set-gadget-items)
		   (value-key set-gadget-value-key)
		   (test set-gadget-test)) sheet
    (let ((item (find nv items :test test :key value-key)))
      (assert item)
      (let ((button (find item (option-menu-buttons sheet) :key #'second)))
	(tk::set-values button :default t)))))
