;;; -*-  Mode: Lisp; Package: Maxima; Syntax: Common-Lisp; Base: 10 -*- ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     The data in this file contains enhancments.                    ;;;;;
;;;                                                                    ;;;;;
;;;  Copyright (c) 1984,1987 by William Schelter,University of Texas   ;;;;;
;;;     All rights reserved                                            ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     (c) Copyright 1982 Massachusetts Institute of Technology         ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "MAXIMA")
(macsyma-module trigi)

(load-macsyma-macros mrgmac)

(declare-top(genprefix tri)
	    (special varlist errorsw $demoivre)
	    (flonum (tan) (cot) (sec) (csc)
		    (atan2) (atan1) (acot)
		    (sinh) (cosh) (tanh) (coth) (csch) (sech)
		    (asinh) (acsch)
		    (t//$ flonum flonum notype))
	    (*expr $bfloat teval signum1 zerop1 islinear expand1
		   timesk addk maxima-integerp evod logarc
		   mevenp eqtest halfangle coeff))

(defmvar $%piargs t)
(defmvar $%iargs t)
(defmvar $triginverses '$all)
(defmvar $trigexpand nil)
(defmvar $trigexpandplus t)
(defmvar $trigexpandtimes t)
(defmvar $trigsign t)
(defmvar $exponentialize nil)
(defmvar $logarc nil)
(defmvar $halfangles nil)

(defmvar 1//2 '((rat simp) 1 2))
(defmvar -1//2 '((rat simp) -1 2))
(defmvar %pi//4 '((mtimes simp) ((rat simp) 1 4.) $%pi))
(defmvar %pi//2 '((mtimes simp) ((rat simp) 1 2) $%pi))
(defmvar sqrt2//2 '((mtimes simp) ((rat simp) 1 2)
		    ((mexpt simp) 2 ((rat simp) 1 2))))
(defmvar -sqrt2//2 '((mtimes simp) ((rat simp) -1 2)
		     ((mexpt simp) 2 ((rat simp) 1 2))))
(defmvar sqrt3//2 '((mtimes simp) ((rat simp) 1 2)
		    ((mexpt simp) 3 ((rat simp) 1 2))))
(defmvar -sqrt3//2 '((mtimes simp) ((rat simp) -1 2)
		     ((mexpt simp) 3 ((rat simp) 1 2))))

;;; Arithmetic utilities.

(defmfun sqrt1-x^2 (x) (power (sub 1 (power x 2)) 1//2))

(defmfun sqrt1+x^2 (x) (power (add 1 (power x 2)) 1//2))

(defmfun sqrtx^2-1 (x) (power (add (power x 2) -1) 1//2))

(defmfun sq-sumsq (x y) (power (add (power x 2) (power y 2)) 1//2))

(defmfun trigp (func) (memq func '(%sin %cos %tan %csc %sec %cot
				   %sinh %cosh %tanh %csch %sech %coth)))

(defmfun arcp (func) (memq func '(%asin %acos %atan %acsc %asec %acot
				  %asinh %acosh %atanh %acsch %asech %acoth)))

(defprop %sin simp-%sin operators)
(defprop %cos simp-%cos operators)
(defprop %tan simp-%tan operators)
(defprop %cot simp-%cot operators)
(defprop %csc simp-%csc operators)
(defprop %sec simp-%sec operators)
(defprop %sinh simp-%sinh operators)
(defprop %cosh simp-%cosh operators)
(defprop %tanh simp-%tanh operators)
(defprop %coth simp-%coth operators)
(defprop %csch simp-%csch operators)
(defprop %sech simp-%sech operators)
(defprop %asin simp-%asin operators)
(defprop %acos simp-%acos operators)
(defprop %atan simp-%atan operators)
(defprop %acot simp-%acot operators)
(defprop %acsc simp-%acsc operators)
(defprop %asec simp-%asec operators)
(defprop %asinh simp-%asinh operators)
(defprop %acosh simp-%acosh operators)
(defprop %atanh simp-%atanh operators)
(defprop %acoth simp-%acoth operators)
(defprop %acsch simp-%acsch operators)
(defprop %asech simp-%asech operators)

(defmfun simp-%sin (form y z) 
  (oneargcheck form)
  (setq y (simpcheck (cadr form) z))
  (cond ((floatp y) (sin y))
	((and $numer (integerp y))
	 (sin (float y 2.0d0 )))
	(($bfloatp y) ($bfloat form))
	((and $%piargs (cond ((zerop1 y) 0) ((linearp y '$%pi) (%piargs-sin\Cos y)))))
	((and $%iargs (multiplep y '$%i)) (mul '$%i (cons-exp '%sinh (coeff y '$%i 1))))
	((and $triginverses (not (atom y))
	      (cond ((eq '%asin (setq z (caar y))) (cadr y))
		    ((eq '%acos z) (sqrt1-x^2 (cadr y)))
		    ((eq '%atan z) (div (cadr y) (sqrt1+x^2 (cadr y))))
		    ((eq '%acot z) (div 1 (sqrt1+x^2 (cadr y))))
		    ((eq '%asec z) (div (sqrtx^2-1 (cadr y)) (cadr y)))
		    ((eq '%acsc z) (div 1 (cadr y)))
		    ((eq '$atan2 z) (div (cadr y) (sq-sumsq (cadr y) (caddr y)))))))
	((and $trigexpand (trigexpand '%sin y)))
	($exponentialize (exponentialize '%sin y))
	((and $halfangles (halfangle '%sin y)))
	((and $trigsign (mminusp* y)) (neg (cons-exp '%sin (neg y))))
	(t (eqtest (list '(%sin) y) form))))

(defmfun simp-%cos (form y z) 
  (oneargcheck form)
  (setq y (simpcheck (cadr form) z))
  (cond ((floatp y) (cos y))
	((and $numer (integerp y))
	 (cos (float y 2.0d0 )))
	(($bfloatp y) ($bfloat form))
	((and $%piargs (cond ((zerop1 y) 1) ((linearp y '$%pi) (%piargs-sin\Cos (add %pi//2 y))))))
	((and $%iargs (multiplep y '$%i)) (cons-exp '%cosh (coeff y '$%i 1)))
	((and $triginverses (not (atom y))
	      (cond ((eq '%acos (setq z (caar y))) (cadr y))
		    ((eq '%asin z) (sqrt1-x^2 (cadr y)))
		    ((eq '%atan z) (div 1 (sqrt1+x^2 (cadr y))))
		    ((eq '%acot z) (div (cadr y) (sqrt1+x^2 (cadr y))))
		    ((eq '%asec z) (div 1 (cadr y)))
		    ((eq '%acsc z) (div (sqrtx^2-1 (cadr y)) (cadr y)))
		    ((eq '$atan2 z) (div (caddr y) (sq-sumsq (cadr y) (caddr y)))))))
	((and $trigexpand (trigexpand '%cos y)))
	($exponentialize (exponentialize '%cos y))
	((and $halfangles (halfangle '%cos y)))
	((and $trigsign (mminusp* y)) (cons-exp '%cos (neg y)))
	(t (eqtest (list '(%cos) y) form))))

(defun %piargs-sin\Cos (x)
  (let ($float coeff ratcoeff zl-rem)
    (setq ratcoeff (coefficient x '$%pi 1)
	  coeff (linearize ratcoeff) zl-rem (coefficient x '$%pi 0))
    (cond ((zerop1 zl-rem) (%piargs coeff ratcoeff))
	  ((not (mevenp (car coeff))) nil)
	  ((equal 0 (setq x (mmod (cdr coeff) 2))) (cons-exp '%sin zl-rem))
	  ((equal 1 x) (neg (cons-exp '%sin zl-rem)))
	  ((alike1 1//2 x) (cons-exp '%cos zl-rem))
	  ((alike1 '((rat) 3 2) x) (neg (cons-exp '%cos zl-rem))))))

(defmfun simp-%tan (form y z)
  (oneargcheck form)
  (setq y (simpcheck (cadr form) z))
  (cond ((floatp y) (tan y))
	((and $numer (integerp y))
	 (tan (float y 2.0d0 )))
	(($bfloatp y) ($bfloat form))
	((and $%piargs (cond ((zerop1 y) 0) ((linearp y '$%pi) (%piargs-tan\Cot y)))))
	((and $%iargs (multiplep y '$%i)) (mul '$%i (cons-exp '%tanh (coeff y '$%i 1))))
	((and $triginverses (not (atom y))
	      (cond ((eq '%atan (setq z (caar y))) (cadr y))
		    ((eq '%asin z) (div (cadr y) (sqrt1-x^2 (cadr y))))
		    ((eq '%acos z) (div (sqrt1-x^2 (cadr y)) (cadr y)))
		    ((eq '%acot z) (div 1 (cadr y)))
		    ((eq '%asec z) (sqrtx^2-1 (cadr y)))
		    ((eq '%acsc z) (div 1 (sqrtx^2-1 (cadr y))))
		    ((eq '$atan2 z) (div (cadr y) (caddr y))))))
	((and $trigexpand (trigexpand '%tan y)))
	($exponentialize (exponentialize '%tan y))
	((and $halfangles (halfangle '%tan y)))
	((and $trigsign (mminusp* y)) (neg (cons-exp '%tan (neg y))))
	(t (eqtest (list '(%tan) y) form))))

(defmfun simp-%cot (form y z)
  (oneargcheck form)
  (setq y (simpcheck (cadr form) z))
  
  (cond ((floatp y) (cot y))
	((and $numer (integerp y))
	 (cot (float y 2.0d0 )))
	(($bfloatp y) ($bfloat form))
	((and $%piargs (cond ((zerop1 y) (dbz-err1 'cot))
			     ((and (linearp y '$%pi) (setq z (%piargs-tan\Cot (add %pi//2 y)))) (neg z)))))
	((and $%iargs (multiplep y '$%i)) (mul -1 '$%i (cons-exp '%coth (coeff y '$%i 1))))
	((and $triginverses (not (atom y))
	      (cond ((eq '%acot (setq z (caar y))) (cadr y))
		    ((eq '%asin z) (div (sqrt1-x^2 (cadr y)) (cadr y)))
		    ((eq '%acos z) (div (cadr y) (sqrt1-x^2 (cadr y))))
		    ((eq '%atan z) (div 1 (cadr y)))
		    ((eq '%asec z) (div 1 (sqrtx^2-1 (cadr y))))
		    ((eq '%acsc z) (sqrtx^2-1 (cadr y)))
		    ((eq '$atan2 z) (div (caddr y) (cadr y))))))
	((and $trigexpand (trigexpand '%cot y)))
	($exponentialize (exponentialize '%cot y))
	((and $halfangles (halfangle '%cot y)))
	((and $trigsign (mminusp* y)) (neg (cons-exp '%cot (neg y))))
	(t (eqtest (list '(%cot) y) form))))

(defun %piargs-tan\Cot (x)
  (prog ($float coeff zl-rem)
     (setq coeff (linearize (coefficient x '$%pi 1)) zl-rem (coefficient x '$%pi 0))
     (return (cond ((and (zerop1 zl-rem)
			 (setq zl-rem (%piargs coeff nil))
			 (setq coeff (%piargs (cons (car coeff) (rplus 1//2 (cdr coeff)))
					      nil)))
		    (div zl-rem coeff))
		   ((not (mevenp (car coeff))) nil)
		   ((integerp (setq x (mmod (cdr coeff) 2))) (cons-exp '%tan zl-rem))
		   ((or (alike1 1//2 x) (alike1 '((rat) 3 2) x)) (neg (cons-exp '%cot zl-rem)))))))

(defmfun simp-%csc (form y z)
  (oneargcheck form)
  (setq y (simpcheck (cadr form) z))
  (cond ((floatp y) (csc y))
	((and $numer (integerp y))
	 (csc (float y 2.0d0 )))
	(($bfloatp y) ($bfloat form))
	((and $%piargs (cond ((zerop1 y) (dbz-err1 'csc))
			     ((linearp y '$%pi) (%piargs-csc\Sec y)))))
	((and $%iargs (multiplep y '$%i)) (mul -1 '$%i (cons-exp '%csch (coeff y '$%i 1))))
	((and $triginverses (not (atom y))
	      (cond ((eq '%acsc (setq z (caar y))) (cadr y))
		    ((eq '%asin z) (div 1 (cadr y)))
		    ((eq '%acos z) (div 1 (sqrt1-x^2 (cadr y))))
		    ((eq '%atan z) (div (sqrt1+x^2 (cadr y)) (cadr y)))
		    ((eq '%acot z) (sqrt1+x^2 (cadr y)))
		    ((eq '%asec z) (div (cadr y) (sqrtx^2-1 (cadr y))))
		    ((eq '$atan2 z) (div (sq-sumsq (cadr y) (caddr y)) (cadr y))))))
	((and $trigexpand (trigexpand '%csc y)))
	($exponentialize (exponentialize '%csc y))
	((and $halfangles (halfangle '%csc y)))
	((and $trigsign (mminusp* y)) (neg (cons-exp '%csc (neg y))))
	
	(t (eqtest (list '(%csc) y) form))))

(defmfun simp-%sec (form y z)
  (oneargcheck form)
  (setq y (simpcheck (cadr form) z))
  (cond ((floatp y) (sec y))
	((and $numer (integerp y))
	 (sec (float y 2.0d0 )))
	(($bfloatp y) ($bfloat form))
	((and $%piargs (cond ((zerop1 y) 1) ((linearp y '$%pi) (%piargs-csc\Sec (add %pi//2 y))))))
	((and $%iargs (multiplep y '$%i)) (cons-exp '%sech (coeff y '$%i 1)))
	((and $triginverses (not (atom y))
	      (cond ((eq '%asec (setq z (caar y))) (cadr y))
		    ((eq '%asin z) (div 1 (sqrt1-x^2 (cadr y))))
		    ((eq '%acos z) (div 1 (cadr y)))
		    ((eq '%atan z) (sqrt1+x^2 (cadr y)))
		    ((eq '%acot z) (div (sqrt1+x^2 (cadr y)) (cadr y)))
		    ((eq '%acsc z) (div (cadr y) (sqrtx^2-1 (cadr y))))
		    ((eq '$atan2 z) (div (sq-sumsq (cadr y) (caddr y)) (caddr y))))))
	((and $trigexpand (trigexpand '%sec y)))
	($exponentialize (exponentialize '%sec y))
	((and $halfangles (halfangle '%sec y)))
	((and $trigsign (mminusp* y)) (cons-exp '%sec (neg y)))
	
	(t (eqtest (list '(%sec) y) form))))

(defun %piargs-csc\Sec (x)
  (prog ($float coeff zl-rem)
     (setq coeff (linearize (coefficient x '$%pi 1)) zl-rem (coefficient x '$%pi 0))
     (return (cond ((and (zerop1 zl-rem) (setq zl-rem (%piargs coeff nil))) (div 1 zl-rem))
		   ((not (mevenp (car coeff))) nil)
		   ((equal 0 (setq x (mmod (cdr coeff) 2))) (cons-exp '%csc zl-rem))
		   ((equal 1 x) (neg (cons-exp '%csc zl-rem)))
		   ((alike1 1//2 x) (cons-exp '%sec zl-rem))
		   ((alike1 '((rat) 3 2) x) (neg (cons-exp '%sec zl-rem)))))))

(defmfun simp-%atan (form y z)
  (oneargcheck form)
  (setq y (simpcheck (cadr form) z))
  (cond ((floatp y) (atan1 y))
	((and $numer (integerp y))
	 (atan1 (float y 2.0d0 )))
	(($bfloatp y) ($bfloat form))
	((and $%piargs
	      (cond ((zerop1 y) 0) ((equal 1 y) %pi//4) ((equal -1 y) (neg %pi//4)))))
	((and $%iargs (multiplep y '$%i)) (mul '$%i (cons-exp '%atanh (coeff y '$%i 1))))
	((and (eq $triginverses '$all) (not (atom y))
	      (if (eq (caar y) '%tan) (cadr y))))
	($logarc (logarc '%atan y))
	((and $trigsign (mminusp* y)) (neg (cons-exp '%atan (neg y))))
	(t (eqtest (list '(%atan) y) form))))

(defun %piargs (x ratcoeff)
  (cond ((and (integerp (car x)) (integerp (cdr x))) 0)
	((not (mevenp (car x))) 
	 (cond ((null ratcoeff) nil)
	       ((alike1 (cdr x) '((rat) 1 2))
		(power -1 (add ratcoeff -1//2)))))
	((or (alike1 '((rat) 1 6) (setq x (mmod (cdr x) 2))) (alike1 '((rat) 5 6) x)) 1//2)
	((or (alike1 '((rat) 1 4) x) (alike1 '((rat) 3 4) x)) (div (power 2 1//2) 2))
	((or (alike1 '((rat) 1 3) x) (alike1 '((rat) 2 3) x)) (div (power 3 1//2) 2))
	((alike1 1//2 x) 1)
	((or (alike1 '((rat) 7 6) x) (alike1 '((rat) 11 6) x)) -1//2)
	((or (alike1 '((rat) 4 3) x) (alike1 '((rat) 5 3) x)) (div (power 3 1//2) -2))
	((or (alike1 '((rat) 5 4) x) (alike1 '((rat) 7 4) x)) (mul -1//2 (power 2 1//2)))
	((alike1 '((rat) 3 2) x) -1)))

(defun linearize (form)
  (cond ((integerp form) (cons 0 form))
	((numberp form) nil)
	((atom form)
	 (let (dum)
	   (cond ((setq dum (evod form))
		  (if (eq '$even dum) '(2 . 0) '(2 . 1)))
		 ((maxima-integerp form) '(1 . 0)))))
	((eq 'rat (caar form)) (cons 0 form))
	((eq 'mplus (caar form)) (lin-mplus form))
	((eq 'mtimes (caar form)) (lin-mtimes form))
	((eq 'mexpt (caar form)) (lin-mexpt form))))

(defun lin-mplus (form)
  (do ((tl (cdr form) (cdr tl)) (dummy) (coeff 0) (zl-rem 0))
      ((null tl) (cons coeff (mmod zl-rem coeff)))
    (setq dummy (linearize (car tl)))
    (if (null dummy) (return nil)
	(setq coeff (rgcd (car dummy) coeff) zl-rem (rplus (cdr dummy) zl-rem)))))

(defun lin-mtimes (form)
  (do ((fl (cdr form) (cdr fl)) (dummy) (coeff 0) (zl-rem 1))
      ((null fl) (cons coeff (mmod zl-rem coeff)))
    (setq dummy (linearize (car fl)))
    (cond ((null dummy) (return nil))
	  (t (setq coeff (rgcd (rtimes coeff (car dummy))
			       (rgcd (rtimes coeff (cdr dummy)) (rtimes zl-rem (car dummy))))
		   zl-rem (rtimes (cdr dummy) zl-rem))))))

(defun lin-mexpt (form)
  (prog (dummy)
     (cond ((and (integerp (caddr form)) (not (minusp (caddr form)))
		 (not (null (setq dummy (linearize (cadr form))))))
	    (return (cons (car dummy) (mmod (cdr dummy) (caddr form))))))))

#-cl
(defun lcm (x y) (quotient (times x y) (gcd x y)))

(defun rgcd (x y)
  (cond ((integerp x)
	 (cond ((integerp y) (gcd x y))
	       (t (list '(rat) (gcd x (cadr y)) (caddr y)))))
	((integerp y) (list '(rat) (gcd (cadr x) y) (caddr x)))
	(t (list '(rat) (gcd (cadr x) (cadr y)) (lcm (caddr x) (caddr y))))))

(defun maxima-reduce (x y)
  (prog (gcd)
     (setq gcd (gcd x y) x (quotient x gcd) y (quotient y gcd))
     (if (minusp y) (setq x (minus x) y (minus y)))
     (return (if (equal y 1) x (list '(rat simp) x y)))))

;; The following four functions are generated in code by TRANSL. - JPG 2/1/81

(defmfun rplus (x y) (addk x y))

(defmfun rdifference (x y) (addk x (timesk -1 y)))

(defmfun rtimes (x y) (timesk x y))

(defmfun rremainder (x y)
  (cond ((equal 0 y) (dbz-err))
	((integerp x)
	 (cond ((integerp y) (maxima-reduce x y))
	       (t (maxima-reduce (times x (caddr y)) (cadr y)))))
	((integerp y) (maxima-reduce (cadr x) (times (caddr x) y)))
	(t (maxima-reduce (times (cadr x) (caddr y)) (times (caddr x) (cadr y))))))

(defmfun $exponentialize (exp)
  (let ($demoivre)
    (cond ((atom exp) exp)
	  ((trigp (caar exp))
	   (exponentialize (caar exp) ($exponentialize (cadr exp))))
	  (t (recur-apply #'$exponentialize exp)))))

(defmfun exponentialize (op arg)
  (cond ((eq '%sin op)
	 (div (sub (power '$%e (mul '$%i arg)) (power '$%e (mul -1 '$%i arg)))
	      (mul 2 '$%i)))
	((eq '%cos op)
	 (div (add (power '$%e (mul '$%i arg)) (power '$%e (mul -1 '$%i arg))) 2))
	((eq '%tan op)
	 (div (sub (power '$%e (mul '$%i arg)) (power '$%e (mul -1 '$%i arg)))
	      (mul '$%i (add (power '$%e (mul '$%i arg))
			     (power '$%e (mul -1 '$%i arg))))))
	((eq '%cot op)
	 (div (mul '$%i (add (power '$%e (mul '$%i arg))
			     (power '$%e (mul -1 '$%i arg))))
	      (sub (power '$%e (mul '$%i arg)) (power '$%e (mul -1 '$%i arg)))))
	((eq '%csc op)
	 (div (mul 2 '$%i)
	      (sub (power '$%e (mul '$%i arg)) (power '$%e (mul -1 '$%i arg)))))
	((eq '%sec op)
	 (div 2 (add (power '$%e (mul '$%i arg)) (power '$%e (mul -1 '$%i arg)))))
	((eq '%sinh op)
	 (div (sub (power '$%e arg) (power '$%e (neg arg))) 2))
	((eq '%cosh op)
	 (div (add (power '$%e arg) (power '$%e (mul -1 arg))) 2))
	((eq '%tanh op)
	 (div (sub (power '$%e arg) (power '$%e (neg arg)))
	      (add (power '$%e arg) (power '$%e (mul -1 arg)))))
	((eq '%coth op)
	 (div (add (power '$%e arg) (power '$%e (mul -1 arg)))
	      (sub (power '$%e arg) (power '$%e (neg arg)))))
	((eq '%csch op)
	 (div 2 (sub (power '$%e arg) (power '$%e (neg arg)))))
	((eq '%sech op)
	 (div 2 (add (power '$%e arg) (power '$%e (mul -1 arg)))))))

(defun coefficient (exp var pow) (coeff (expand1 exp 1 0) var pow))

(defun mmod (x mod)
  (cond ((and (integerp x) (integerp mod))
	 (if (minusp (if (zerop mod) x (setq x (f- x (f* mod (// x mod))))))
	     (f+ x mod)
	     x))
        ((and ($ratnump x) ($ratnump mod))
	 (let
	     ((d (lcm ($denom x) ($denom mod))))
	   (setq x (mul* d x))
	   (setq mod (mul* d mod))
	   (div (mod x mod) d)))
	(t nil)))
;;	((AND (NOT (ATOM X)) (EQ 'RAT (CAAR X)))
;;	 (LIST '(RAT) (MMOD (CADR X) (f* MOD (CADDR X))) (CADDR X))


(defun multiplep (exp var)
  (and (not (zerop1 exp)) (zerop1 (sub exp (mul var (coeff exp var 1))))))

(defun linearp (exp var)
  (and (setq exp (islinear (expand1 exp 1 0) var)) (not (equal (car exp) 0))))

(defmfun mminusp (x) (= -1 (signum1 x)))

(defmfun mminusp* (x)
  (let (sign)
    (setq sign (csign x))
    (or (memq sign '($neg $nz))
	(and (mminusp x) (not (memq sign '($pos $pz)))))))

;; This should give more information somehow.

(defun dbz-err ()
  (cond ((not errorsw) (merror "Division by zero"))
	(t (throw 'errorsw t))))

(defun dbz-err1 (func)
  (cond ((not errorsw) (merror "Division by zero in ~A function" func))
	(t (throw 'errorsw t))))

;; Only used by LAP code right now.

#+pdp10
(defun numeric-err (x msg) (merror "~A in ~A function" msg x))

;; Trig, hyperbolic functions, and inverses, which take real floating args
;; and return real args.  Checks made for overflow and out of range args.
;; The following are read-time constants.
;; This seems bogus.  Probably want (FSC (LSH 1 26.) 0) for the PDP10. -cwh

#.(setq eps #+pdp10 (fsc 1.0 -26.)
	#+cl			    ;(ASH 1.0 #+3600 -24. #-3600 -31.)
	(scale-float 1.0 -24)
	#-(or pdp10 cl) 1.4e-8)

#-cl ;;it already has a value thank you very much
(setq pi #.(atan 0.0 -1.0))
(eval-when (load eval compile)
  (defvar piby2 (coerce (/ pi 2.0) 'double-float)))

;; This function is in LAP for PDP10 systems.  On the Lisp Machine and
;; in NIL, this should CONDITION-BIND the appropriate arithmetic overflow
;; signals and do whatever NUMERIC-ERR or DBZ-ERR does.  Fix later.

#-(or pdp10 cl) (defmacro t//$ (x y function) function ;Ignored
			  `(//$ ,x ,y))
#+cl
(defmacro t//$ (x y function)
  (if (equal y 0.0)
      ;; DEFEAT INCOMPETENTLY DONE COMPILER:OPTIMIZATION.
      `(t//$-foo ,x ,y ,function)
      `(//$ ,x ,y)))
#+cl
(defun t//$-foo (x y function) function
       (//$ x y))

#+pdp10 (lap-a-list '(

		      (lap 	t//$ subr)
		      (args 	t//$ (nil . 3))
		      (push p (% 0 0 float1))
		      (jrst 2 @ (% 0 0 nexta))
		      nexta	(move tt 0 a)
		      (fdvr tt 0 b)	;DIVIDE TT BY SECOND ARG
		      (jfcl 10 uflow)
		      ans	(popj p)
		      uflow	(move a c)
		      (skipn 0 0 b)
		      (jcall 1 'dbz-err1)
		      (movei b 'overflow)
		      (jsp t nextb)
		      nextb	(tlnn t 64.)
		      (jcall 2 'numeric-err)
		      (movei b 'underflow)
		      (skipn 0 (special zunderflow))
		      (jcall 2 'numeric-err)
		      (movei tt 0)
		      (jrst 0 ans)
		      nil ))

;; Numeric functions (SIN, COS, LOG, EXP are built in to Lisp).

(defmfun tan (x) (t//$ (sin x) (cos x) 'tan))

(defmfun cot (x) (t//$ (cos x) (sin x) 'cot))

(defmfun sec (x) (t//$ 1.0 (cos x) 'sec))

(defmfun csc (x) (t//$ 1.0 (sin x) 'csc))

;; #.<form> means to evaluate <form> at read-time.

(declare-top (flonum yy yflo))

#-franz
(defmfun asin (num)
  (let ((yflo (float num)))
    (cond ((> (abs yflo) 1.0) (logarc '%asin yflo))
	  ((< (abs yflo) #.(sqrt eps)) yflo)
	  (t (*$ (atan (abs yflo) (sqrt (-$ 1.0 (*$ yflo yflo))))
		 (if (< yflo 0.0) -1.0 1.0))))))

#-franz
(defmfun acos (num) 
  (let ((yflo (float num)))
    (cond ((> (abs yflo) 1.0) (logarc '%acos yflo))
	  ((< (abs yflo) #.(sqrt eps)) (-$ #.piby2 yflo))
	  (t (atan (sqrt (-$ 1.0 (*$ yflo yflo))) yflo)))))

#+maclisp
(defun atan2 (y x)
  (let ((yflo (atan (abs y) x))) (if (minusp y) (-$ yflo) yflo)))

(defmfun atan1 (num)
  (let ((yflo (float num)))
    (*$ (atan (abs yflo) 1.0) (if (minusp yflo) -1.0 1.0))))

(defmfun acot (num)
  (let ((yflo (float num)))
    (*$ (atan 1.0 (abs yflo)) (if (minusp yflo) -1.0 1.0))))

(defmfun asec (num)
  (let ((yflo (float num)))
    (if (< (abs yflo) 1.0) (logarc '%asec yflo)) (acos (//$ yflo))))

(defmfun acsc (num)
  (let ((yflo (float num)))
    (if (< (abs yflo) 1.0) (logarc '%acsc yflo)) (asin (//$ yflo))))

(defmfun sinh (num)
  (let ((yy (float num)) (yflo 0.0))
    (cond ((< (abs yy) #.(sqrt eps)) yy)
	  (t (setq yflo (exp (abs yy)) yflo (//$ (-$ yflo (//$ yflo)) 2.0))
	     (if (< yy 0.0) (-$ yflo) yflo)))))

(defmfun cosh (num)
  (let ((yflo (float num)))
    (setq yflo (exp (abs yflo))) (//$ (+$ yflo (//$ yflo)) 2.0)))

(defmfun tanh (num)
  (let ((yy (float num)) (yflo 0.0))
    (cond ((< (abs yy) #.(sqrt eps)) yy)
	  (t (setq yflo (exp (*$ -2.0 (abs yy))) yflo (//$ (1-$ yflo) (1+$ yflo)))
	     (if (plusp yy) (-$ yflo) yflo)))))

(defmfun coth (num)
  (let ((yy (float num)) (yflo 0.0))
    (cond ((< (abs yy) #.(sqrt eps)) (//$ yy))
	  (t (setq yflo (exp (*$ -2.0 (abs yy))) yflo (t//$ (1+$ yflo) (1-$ yflo) 'coth))
	     (if (plusp yy) (-$ yflo) yflo)))))

(defmfun csch (num)
  (let ((yy (float num)) (yflo 0.0))
    (cond ((< (abs yy) #.(sqrt eps)) (//$ yy))
	  (t (setq yflo (exp (-$ (abs yy)))
		   yflo (t//$ (*$ 2.0 yflo)
			      (1-$ (if (< yflo #.(sqrt eps)) 0.0 (*$ yflo yflo))) 'csch))
	     (if (plusp yy) (-$ yflo) yflo)))))

(defmfun sech (num)
  (let ((yflo (float num))) (setq yflo (exp (-$ (abs yflo))))
       (//$ yflo 0.5 (1+$ (if (< yflo #.(sqrt eps)) 0.0 (*$ yflo yflo))))))

(defmfun acosh (num)
  (let ((yflo (float num)))
    (cond ((< yflo 1.0) (logarc '%acosh yflo))
	  ((> yflo #.(sqrt (//$ eps))) (log (*$ 2.0 yflo)))
	  (t (log (+$ (sqrt (1-$ (*$ yflo yflo))) yflo))))))

(defmfun asinh (num)
  (let* ((yy (float num))
	 (yflo (abs yy)))
    (cond ((< yflo #.(sqrt eps)) yflo)
	  (t (setq yflo (log (cond ((> yflo #.(sqrt (//$ eps))) (*$ 2.0 yflo))
				   (t (+$ (sqrt (1+$ (*$ yflo yflo))) yflo)))))
	     (cond ((minusp yy) (-$ yflo)) (t yflo))))))

(defmfun atanh (num)
  (let ((yflo (float num)))
    (cond ((< (abs yflo) #.(sqrt eps)) yflo)
	  ((< (abs yflo) 1.0) (//$ (log (t//$ (1+$ yflo) (-$ 1.0 yflo) 'atanh)) 2.0))
	  ((= 1.0 (abs yflo)) (t//$ 1.0 0.0 'atanh))
	  (t (logarc '%atanh yflo)))))

(defmfun acoth (num)
  (let ((yflo (float num)))
    (cond ((> (abs yflo) 1.0)
	   (//$ (log (//$ (+$ 1.0 yflo) (+$ -1.0 yflo))) 2.0))
	  ((= 1.0 (abs yflo)) (t//$ 1.0 0.0 'acoth))
	  (t (logarc '%acoth yflo)))))

(defmfun asech (num)
  (let ((yflo (float num)))
    (cond ((or (minusp yflo) (> yflo 1.0)) (logarc '%asech yflo)))
    (acosh (t//$ 1.0 yflo 'asech))))

(defmfun acsch (num) (asinh (t//$ 1.0 (float num) 'acsch)))

