;; -*- mode: common-lisp; package: user -*-
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
;; $fiHeader: dev-load-xm.lisp,v 1.5 92/03/04 16:23:12 cer Exp Locker: cer $

(excl::free (excl::malloc 131072))

(setq *ignore-package-name-case* t)
(set-case-mode :case-insensitive-lower)

(tenuring
   (let ((*load-source-file-info* t)
	 (*load-xref-info* nil))
     (let ((*enable-package-locked-errors* nil))
       (load "sys/defsystem"))
     (load "sys/sysdcl")))

(defun load-it (sys)
  
  (tenuring 
   (let ((*load-source-file-info* t)
	 (*load-xref-info* nil)
	 (excl:*global-gc-behavior* nil))
     (ecase sys
       (motif-clim
	(load "climg.fasl")
	(load "climxm.fasl")
	(load "clim-debug.fasl"))
       (openlook-clim
	(load "climg.fasl")
	(load "climol.fasl")
	(load "clim-debug.fasl")))))

  ;;-- What would be good is to mark the files in the system as having
  ;;-- been loaded
  
  (compile-file-if-needed "test/test-suite")

  (tenuring
   (load "test/test-suite") 
   (load "misc/clos-preload.fasl" :if-does-not-exist nil))

  (load "demo/sysdcl")
  (tenuring
   (defsys::load-system 'clim-demo))
  
  (when (probe-file "/net/jeff/scm/4.1/sparc/src/code/")
    (let ((sys::*require-search-list*
	   (cons (make-pathname :directory "/net/jeff/scm/4.1/sparc/src/code/"
				:type "fasl")
		 sys::*require-search-list*))
	  (sys::*load-search-list*
	   (cons
	    (make-pathname :directory "/net/jeff/scm/4.1/sparc/src/code/")
	    sys::*load-search-list*)))
      (tenuring (require :composer)))
  
    (set (intern :*clm-binary-directory* ':xtk) "/scm/4.1/sparc/src/")))