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
;; $fiHeader: dev-load-xm.lisp,v 1.3 92/02/26 10:24:03 cer Exp $

(excl::free (excl::malloc 131072))

(setq *ignore-package-name-case* t)
(set-case-mode :case-insensitive-lower)

(tenuring
 (let ((*load-source-file-info* t)
       (*load-xref-info* nil))
   (let ((*enable-package-locked-errors* nil))
     (load "sys/defsystem"))
   (load "sys/sysdcl")))


(tenuring 
 (let ((*load-source-file-info* t)
       (*load-xref-info* nil)
       (excl:*global-gc-behavior* nil))
   (defsys::load-system 'motif-clim)))

(compile-file-if-needed "test/test-suite")

(tenuring
 (load "test/test-suite") 
 (load "misc/clos-preload.fasl" :if-does-not-exist nil))

(load "demo/sysdcl")
(tenuring
 (defsys::load-system 'clim-demo))