;;; -*-  Mode: Lisp; Package: Maxima; Syntax: Common-Lisp; Base: 10 -*- ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     The data in this file contains enhancments.                    ;;;;;
;;;                                                                    ;;;;;
;;;  Copyright (c) 1984,1987 by William Schelter,University of Texas   ;;;;;
;;;     All rights reserved                                            ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; If you see bogus or missing data here, please tell GJC or JPG.	 ;;;
;;;       (c) Copyright 1982 Massachusetts Institute of Technology       ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "MAXIMA")
(macsyma-module trdata)

;;; N.B. This is some data. Boy, does it have subtle effect on the code
;;; produced by TRANSLATE. It should be carefully checked and updated.
;;; Since it is so small, and compiles so quickly it sometimes serves
;;; as a fix (i.e. hack) file. so be careful.


(transl-module trdata)

(eval-when (compile)
  (setq *def%tr-produces-autoload-file* nil))

;; this should go someplace else perhaps.

(def-autoload-translate $romberg $interpolate)

;;; MODEDECLARE(FUNCTION(LENGTH),FIXNUM)

;;I think all this can be done at load time only:--wfs
(eval-when (load)

  (mapc #'(lambda (x) (putprop x '$fixnum 'function-mode))
	'($length $nterms random $nroots $rank $polysign $time
	  $array_dimension_n))

;;; MODEDECLARE(FUNCTION(ROMBERG_SUBR),FLOAT)
;;; ROMBERG is a macsyma macro.

  (mapc #'(lambda (x) (putprop x '$float 'function-mode))
	'($romberg_subr $interpolate_subr))

;;; Functions of BOOLEAN return VALUE. i.e. PREDICATES

  (mapc #'(lambda (x) (putprop x '$boolean 'function-mode))
	'($array $bfloatp $listp $matrixp $ratnump $constantp
	  $atom $freeof $subvarp $symbolp
	  $evenp $oddp $orderlessp $ordergreatp $mapatom
	  $integerp $floatnump $nonscalarp $numberp $ratp $member
	  $emptyp))

;;; MODEDECLARE(TRUE,BOOLEAN)

  (mapc #'(lambda (x) (putprop x '$boolean 'mode))
	'($true $false $doallmxops $domxmxops $doscmxops $detout
	  $dotassoc $dotdistrib $dotscrules $exponentialize
	  $keepfloat $listarith $logsimp
	  $maxapplyheight $maxapplydepth $maperror $powerdisp
	  $scalarmatrix $simp $ttyoff $underflow $infeval
	  $xaxis $yaxis $ratfac))

  (mapc #'(lambda (x) (putprop x (stripdollar x) 'lisp-function-to-use))
	'(%log %sin %cos %tan %cot %csc %sec %acot
	  %asin %acos %acsc %asec
	  %sinh %cosh %tanh %coth %csch %sech %asinh %acsch %erf))

  (mapc #'(lambda (x) (putprop x t 'implied-quotep))
	'($eval $done $%i $%pi $%e $%phi $%gamma
	  mqapply	; important for array referencing conventions.
	  ))


;;; The result of a part function never needs simplification.
;;;  $CONS for example has the same property, although it
;;; is not a "PART" function.

;;; ELL has just shown a bug with FIRST and REST interaction with
;;; DEFMATCH and MATCHDECLARE. The extra simplification needed
;;; it seems. LIST mode must be implemented, untill then the
;;; cost of the extra SIMPLFY call is not much compared with the
;;; consing involved. Above all, we must have correct code !!!

  (mapc #'(lambda (l) (putprop l t 'tr-nosimp))
	'(				;$FIRST $REST $LAST
	  $print
	  $num $denom $lhs $rhs $part
	  $cons $reverse $endcons $append
	  $union $intersection $setdiff $symdiff
	  $mapset $predset |${| $elementof
	  ))

  (defprop $realpart $realpart lisp-function-to-use)


  (setq transl-modules '(

			 transs
			 transl
			 trutil
			 trans1
			 trans2
			 trans3
			 trans4
			 trans5
			 transf
			 troper
			 trpred

			 mtags
			 mdefun
			 transq
			 fcall
			 acall
			 trdata
			 mcompi
			 trmode
			 trhook
			 ))

  )