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
(macsyma-module solve)

(load-macsyma-macros ratmac strmac)

(declare-top (genprefix v_)
	     (special var-list expsumsplit $dispflag $nolabels checkfactors *g
		      $algebraic equations ;List of E-labels
		      *power *varb *flg $derivsubst $numer $float
		      $%emode wflag genvar genpairs varlist broken-not-freeof
		      $factorflag
		      mult    ;Some crock which tracks multiplicities.
		      *roots ;alternating list of solutions and multiplicities
		      *failures	;alternating list of equations and multiplicities
		      *myvar $listconstvars
		      *has*var *var $dontfactor $linenum $linechar
		      linelable $keepfloat $ratfac
		      errrjfflag  ;A substitute for condition binding.
		      lsolveflag xm* xn* mul* solvexp)
	     (array* (notype xa* 2))
	     (fixnum thisn $linenum))

(defmvar $breakup t
  "Causes solutions to cubic and quartic equations to be expressed in
	 terms of common subexpressions.")

(defmvar $multiplicities '$not_set_yet
  "Set to a list of the multiplicities of the individual solutions
	 returned by SOLVE, REALROOTS, or ALLROOTS.")

(defmvar $linsolvewarn t
  "Needs to be documented.")

(defmvar $solve_inconsistent_error t
  "If T gives an MAXIMA-ERROR if SOLVE meets up with inconsistent linear
	 equations.  If NIL, returns ((MLIST SIMP)) in this case.")

(defmvar $programmode t
  "Causes SOLVE to return its answers explicitly as elements
	 in a list rather than printing E-labels.")

(defmvar $solvedecomposes t
  "Causes SOLVE to use POLYDECOMP in attempting to solve polynomials.")

(defmvar $solveexplicit nil
  "Causes SOLVE to return implicit solutions i.e. of the form F(x)=0.")

(defmvar $solvefactors t
  "If T, then SOLVE will try to factor the expression.  The FALSE
	 setting may be desired in zl-SOME cases where factoring is not
	 necessary.")

(defmvar $solvenullwarn t
  "Causes the user will be warned if SOLVE is called with either a
	 null equation list or a null variable list.  For example,
	 SOLVE([],[]); would print two warning messages and return [].")

(defmvar $solvetrigwarn t
  "Causes SOLVE to print a warning message when it is uses
	 inverse trigonometric functions to solve an equation,
	 thereby losing solutions.")

(defmvar $solveradcan nil
  "SOLVE will use RADCAN which will make SOLVE slower but will allow
	 certain problems containing exponentials and logs to be solved.")

;; Utility macros

;; In MacLisp, this turns into SUBRCALL if we are compiling, FUNCALL if
;; interpreted.  In LMLisp and other random systems, just turn into FUNCALL.

#+maclisp
(defmacro subr-funcall (function . args)
  (cond ((status feature complr) `(subrcall nil ,function . ,args))
	(t `(funcall ,function . ,args))))

#-maclisp
(defmacro subr-funcall (function . args) `(funcall ,function . ,args))

;; This macro returns the number of trivial equations.  It counts up the
;; number of zeros in a list.

(defmacro nzlist (llist)
  `(do ((l ,llist (cdr l))
	(zcount 0))
    ((null l) zcount)
    (if (and (integerp (car l)) (zerop (car l)))
	(increment zcount))))

;; This is only called on a variable.

(defmacro allroot (exp)
  `(setq *failures (list* (make-mequal-simp ,exp ,exp) 1 *failures)))


;; Finds variables, changes equations into expressions without MEQUAL.
;; Checks for consistency between the number of unknowns and equations.
;; Calls SOLVEX for simultaneous equations and SSOLVE for a single equation.

(defmfun $solve (*eql &optional (varl nil varl-p))
  (setq $multiplicities (make-mlist))
  (prog (eql		       ;Expressions and variables being solved
	 $keepfloat $ratfac	       ;In case the user has set these
	 *roots *failures ;*roots gets solutions, *failures "roots of"
	 broken-not-freeof) ;Has something to do with spliting up roots
     (setq eql
	   (cond ((atom *eql) (ncons *eql))
		 ((eq (g-rep-operator *eql) 'mlist)
		  (mapcar 'meqhk (mapcar 'meval (cdr *eql))))
		 ((memq (g-rep-operator *eql)
			'(mnotequal mgreaterp mlessp mgeqp mleqp))
		  (merror "Cannot solve inequalities. -SOLVE"))
		 (t (ncons (meqhk *eql)))))

     (cond ((null varl-p)	 ;If the variable list wasn't supplied
	    (setq varl		      ;we have to supply it ourselves.
		  (let (($listconstvars nil))
		    (cdr ($listofvars
					;If some trivial then use original equations
					;(primarily for case of X=X etc.)
			  (cond ((zerop (nzlist eql)) *eql)
				(t eql)))))) ;Usually throw trivia out!
	    (if varl (setq varl (remc varl)))) ;Remove all constants
	   (t (setq varl
		    (cond (($listp varl) (mapcar #'meval (cdr varl)))
			  (t (list varl))))))

     (if (and (null varl) $solvenullwarn)
	 (mtell "~&Got a null variable list, continuing - SOLVE~%"))
     (if (and (null eql) $solvenullwarn)
	 (mtell "~&Got a null equation list, continuing - SOLVE~%"))
     (if (ormapc #'mnump varl)
	 (merror "A number was found where a variable was expected -SOLVE"))

     (cond ((equal eql '(0)) (return '$all))
	   ((or (null varl) (null eql)) (return (make-mlist-simp)))
	   ((and (null (cdr varl)) (null (cdr eql)))
	    (return (ssolve (car eql) (car varl))))
	   ((or varl-p (= (length varl) (length eql)))
	    (setq eql (solvex eql varl (not $programmode) t))
	    (return (cond ((and (cdr eql) (not ($listp (cadr eql))))
			   (make-mlist eql))
			  (t eql)))))
     (let ((u (make-mlist-l varl))
	   (e (cond (($listp *eql) *eql)
		    (t (make-mlist *eql)))))
       ;; MFORMAT doesn't have ~:[~] yet, so I just change this to
       ;; make one of two possible calls to MERROR. Smaller codesize
       ;; then what was here before anyway.
       (if (> (length varl) (length eql))
	   (merror "More unknowns than equations -SOLVE~
		  ~%Unknowns given :  ~%~M~
		  ~%Equations given:  ~%~M"
		   u e)
	   (merror "More equations than unknowns -SOLVE~
		  ~%Unknowns given :  ~%~M~
		  ~%Equations given:  ~%~M"
		   u e)))))


;; Removes anything from its list arg which solve considers not to be a
;; variable, i.e.  constants, functions or subscripted variables without
;; numeric args.

(defun remc (lst)
  (do ((l lst (cdr l)) (fl) (vl)) ((null l) vl)
    (cond ((atom (setq fl (car l)))
	   (or (maxima-constantp fl) (setq vl (cons fl vl))))
	  ((andmapc #'$constantp (cdr fl)) (setq vl (cons fl vl))))))

;; List of multiplicities.  Why is this special?

(declare-top (special multi)) 

;; Solve a single equation for a single unknown.
;; Obtains roots via solve and prints them.

(defun ssolve (exp *var &aux equations multi)
  (let (($solvetrigwarn $solvetrigwarn))
    (cond ((null *var) '$all)
	  (t (solve exp *var 1)
	     (cond ((not (or *roots *failures)) (make-mlist))
		   ($programmode
		    (prog1 (make-mlist-l
			    (nreverse
			     (map2c #'(lambda (eqn mult) (push mult multi) eqn)
				    (if $solveexplicit
					*roots
					(nconc *roots *failures)))))
		      (setq $multiplicities
			    (make-mlist-l (nreverse multi)))))
		   (t (when (and *failures (not $solveexplicit))
			(if $dispflag (mtell "The roots of:~%"))
			(solve2 *failures))
		      (when *roots
			(if $dispflag (mtell "Solution:~%"))
			(solve2 *roots))
		      (make-mlist-l equations)))))))

;; Solve takes three arguments, the expression to solve for zero, the variable
;; to solve for, and what multiplicity this solution is assumed to have (from
;; higher-level Solve's).  Solve returns NIL.  Isn't that useful?  The lists
;; *roots and *failures are special variables to which Solve prepends solutions
;; and their multiplicities in that order: *roots contains explicit solutions
;; of the form <var>=<function of independent variables>, and *failures
;; contains equations which if solved would yield additional solutions.

;; Factors expression and reduces exponents by their gcd (via solventhp)

(defmfun solve (*exp *var mult
		     &aux (genvar nil)
		     ($derivsubst nil)
		     (exp (float2rat (mratcheck *exp)))
		     (*myvar *var)
		     ($savefactors t))
  (prog (factors *has*var genpairs $dontfactor temp symbol *g checkfactors 
	 varlist expsumsplit)
     (let (($ratfac t)) (setq exp (ratdisrep (ratf exp))))
					; Cancel out any simple 
					; (non-algebraic) common factors in numerator and 
					; denominator without altering the structure of the 
					; expression too much.
					; Also, RJFPROB in TEST;SOLVE TEST is now solved.
					; - JPG
     a (cond ((atom exp)
	      (cond ((eq exp *var)
		     (solve3 0 mult))
		    ((equal exp 0) (allroot *var))
		    (t nil)))
	     (t (setq exp (meqhk exp))
		(cond ((equal exp '(0))
		       (return (allroot *var)))
		      ((free exp *var)
		       (return nil)))
		(cond ((not (atom *var))
		       (setq symbol (gensym))
		       (setq exp (maxima-substitute symbol *var exp))
		       (setq temp *var)
		       (setq *var symbol)
		       (setq *myvar *var))) ;keep *MYVAR up-to-date
	      
		(cond ($solveradcan (setq exp (radcan1 exp))
				    (if (atom exp) (go a))))
	      
		(cond ((easy-cases exp *var)
		       (cond (symbol (setq *roots (subst temp *var *roots))
				     (setq *failures (subst temp *var *failures))))
		       (rootsort *roots)
		       (rootsort *failures)
		       (return nil)))
	      
		(cond ((setq factors (first-order-p exp *var))
		       (solve3 (ratdisrep
				(ratf (make-mtimes -1 (div* (cdr factors)
							    (car factors)))))
			       mult))
		    
		      (t (setq varlist (list *var))
			 (fnewvar exp)
			 (setq varlist (varsort varlist))
			 (let ((vartemp)
			       (ratnumer (mrat-numer (ratrep* exp)))
			       (numer-varlist varlist)
			       (subst-list (trig-subst-p varlist)))
			   (setq varlist (ncons *var))
			   (cond (subst-list
				  (setq exp (trig-subst exp subst-list))
				  (fnewvar exp)
				  (setq varlist (varsort varlist))
				  (setq exp (mrat-numer (ratrep* exp)))
				  (setq vartemp varlist))
				 (t (setq vartemp numer-varlist)
				    (setq exp ratnumer)))
			   (setq varlist vartemp))
		       
			 (cond ((atom exp) (go a))
			       ((specasep exp) (solve1a exp mult))
			       ((and (not (pcoefp exp))
				     (cddr exp)
				     (not (equal 1 (setq *g
							 (solventhp (cdddr exp) (cadr exp))))))
				(solventh exp *g))
			       (t (map2c #'solve1a
					 (cond ($solvefactors (pfactor exp))
					       (t (list exp 1))))))))))

     (cond (symbol (setq *roots (subst temp *var *roots))
		   (setq *failures (subst temp *var *failures))))
     (rootsort *roots)
     (rootsort *failures)
     (return nil)))

(defun float2rat (exp)
  (cond ((floatp exp) (setq exp (prep1 exp)) (make-rat-simp (car exp) (cdr exp)))
	((or (atom exp) (specrepp exp)) exp)
	(t (recur-apply #'float2rat exp))))

;;; The following takes care of cases where the expression is already in 
;;; factored form. This can introduce spurious roots if one of the factors
;;; is an expression that can be undefined or infinity for certain values of
;;; the variable in question. But soon this will be no worry because I will
;;; add a list of  "possible bad roots" to what $SOLVE returns.
;;; Solve is not fully recursive when it due to globals, $MULTIPLICIES
;;; may be screwed here. (Solve should be made recursive)

(defun easy-cases (*exp *var)
  (cond ((or (atom *exp) (atom (car *exp))) nil)
	((eq (caar *exp) 'mtimes)
	 (do ((terms (cdr *exp) (cdr terms)))
	     ((null terms))
	   (solve (car terms) *var 1))
	 'mtimes)))

;; This code is commented out because it exposes a bug in the way
;; solve (or its friends) handles multiplicities. A previous 
;; version (1.2) had a typo (caar *exp) 'mexp ...) that prevented this
;; bug from manifesting.  Barton Willis, 12 May 2004

;;	     ((EQ (CAAR *EXP) 'MEXPT)
;;	      (COND ((AND (INTEGERP  (CADDR *EXP))
;;			  (PLUSP (CADDR *EXP)))
;;		     (SOLVE (CADR *EXP) *VAR (CADDR *EXP))
;;		     'MEXPRAT)))))

;;; Predicate to test for presence of troublesome trig functions to be
;;; canonicalized.  A  table of when to make substitutions should
;;; be used here. 
;;;  trig kind                     => SIN | COS | TAN ...   subst to make
;;; number around in expression ->     1     1     0         ......
;;; what you want to be able to do for example is to see if SIN and COS^2 
;;; are around and then make a reasonable substitution.

(defun trig-subst-p (vlist)
  (and (not (trig-not-subst-p vlist))
       (do ((var (car vlist) (car vlist))
	    (vlist (cdr vlist) (cdr vlist))
	    (subst-list))
	   ((null var) subst-list)
	 (cond ((and (not (atom var))
		     (trig-cannon (g-rep-operator var))
		     (not (free var *var)))
		(push var subst-list))))))

;; Predicate to see when obviously not to substitute for trigs.
;; A hack in the direction of expression properties-table driven
;; substition. The "measure" of the expression is the total number
;; of different kinds of trig functions in the expression.

(defun trig-not-subst-p (vlist)
  (let ((trigs '(%sin %cos %tan %cot %csc %sec)))
    (< (measure #'sign-gjc (operator-frequency-table vlist trigs) trigs)
       2)))

;; To get the total "value" of things in a table, this case an assoc list.
;; (MEASURE FUNCTION ASSOCIATION-LIST SET) where FUNCTION is a function mapping
;; the range of the ASSOCIATION-LIST viewed as a function on the SET, to the
;; integers.

(defun measure (f alist set &aux (sum 0))
  (dolist (element set)
    (increment sum (funcall f (cdr (assq element alist)))))
  sum)

;; (defun MEASURE (F AL S)
;;        (do ((j 0 (f1+ j))
;;	       (sum 0))
;;	   ((= j (length S))  sum)
;;	   (setq sum (f+ sum (funcall F (cdr (assoc (nth j S) al)))))))

;; Named for uniqueness only

(defun sign-gjc (x)
  (cond ((or (null x) (= x 0)) 0)
	((< 0 x) 1)
	(t -1)))

;; A function that can EXTEND a function
;; over two association lists. Note that I have been using association lists
;; as mere functions (that is, as sets of ordered pairs).
;; (EXTEND '+ L1 L2 S) could also be to take the union of two multi-sets in the
;; sample space S. (what the '&%%#?& has this got to do with SOLVE?) 

(defun extend (f l1 l2 s)
  (do ((j 0 (f1+ j))
       (value nil))
      ((= j (length s)) value)
    (setq value (cons (cons (nth j s)
			    (funcall f (cdr (zl-assoc (nth j s) l1))
				     (cdr (zl-assoc (nth j s) l2))))
		      value))))

;; For the case where the value of assoc is NIL, we will need a special "+"

(defun +mset (a b) (f+ (or a 0) (or b 0)))

;; To recursively looks through a list
;; structure (the VLIST) for members of the SET appearing in the MACSYMA 
;; functional position (caar list). Returning an assoc. list of appearence
;; frequencies. Notice the use of EXTEND.

(defun operator-frequency-table (vlist set)
  (do ((j 0 (f1+ j))
       (it)
       (assl (do ((k 0 (f1+ k))
		  (made nil))
		 ((= k (length set)) made)
	       (setq made (cons (cons (nth k set) 0)
				made)))))
      ((= j (length vlist)) assl)
    (setq it (nth j vlist))
    (cond ((atom it))
	  (t (setq assl (extend #'+mset (cons (cons (caar it) 1) nil)
				assl set))
	     (setq assl (extend #'+mset assl
				(operator-frequency-table (cdr it) set)
				set))))))

(defun trig-subst (exp sub-list)
  (do ((exp exp)
       (sub-list (cdr sub-list) (cdr sub-list))
       (var (car sub-list) (car sub-list)))
      ((null var) exp)
    (setq exp
	  (maxima-substitute (funcall (trig-cannon (g-rep-operator var))
				      (make-mlist-l (g-rep-operands var)))
			     var exp))))

;; Here are the canonical trig substitutions.

(defun-prop (%sec trig-cannon) (x)
  (inv* (make-g-rep '%cos (g-rep-first-operand x))))

(defun-prop (%csc trig-cannon) (x)
  (inv* (make-g-rep '%sin (g-rep-first-operand x))))

(defun-prop (%tan trig-cannon) (x)
  (div* (make-g-rep '%sin (g-rep-first-operand x))
	(make-g-rep '%cos (g-rep-first-operand x))))

(defun-prop (%cot trig-cannon) (x)
  (div* (make-g-rep '%cos (g-rep-first-operand x))
	(make-g-rep '%sin (g-rep-first-operand x))))

(defun-prop (%sech trig-cannon) (x)
  (inv* (make-g-rep '%cosh (g-rep-first-operand x))))

(defun-prop (%csch trig-cannon) (x)
  (inv* (make-g-rep '%sinh (g-rep-first-operand x))))

(defun-prop (%tanh trig-cannon) (x)
  (div* (make-g-rep '%sinh (g-rep-first-operand x))
	(make-g-rep '%cosh (g-rep-first-operand x))))

(defun-prop (%coth trig-cannon) (x)
  (div* (make-g-rep '%cosh (g-rep-first-operand x))
	(make-g-rep '%sinh (g-rep-first-operand x))))

;; Predicate to replace ISLINEAR....Returns NIL if not of for A*X+B, A and B
;; freeof X, else returns (A . B)

(defun first-order-p (exp var &aux temp)
  ;; Expand the expression at one level, i.e. distribute products
  ;; over sums, but leave exponentiations alone.
  ;; (X+1)^2*(X+Y) --> X*(X+1)^2 + Y*(X+1)^2
  (setq exp (expand1 exp 1 1))
  (cond ((atom exp) nil)
	(t (case (g-rep-operator exp)
	     (mtimes
	      (cond ((setq temp (linear-term-p exp var))
		     (make-lineq temp 0))
		    (t nil)))
	     (mplus
	      (do ((arg  (car (g-rep-operands exp)) (car rest))
		   (rest (cdr (g-rep-operands exp)) (cdr rest))
		   (linear-term-list)
		   (constant-term-list)
		   (temp))
		  ((null arg)
		   (if linear-term-list
		       (make-lineq (make-mplus-l linear-term-list)
				   (if constant-term-list
				       (make-mplus-l constant-term-list)
				       0))))
		(cond ((setq temp (linear-term-p arg var))
		       (push temp linear-term-list))
		      ((broken-freeof var arg)
		       (push arg constant-term-list))
		      (t (return nil)))))
	     (t nil)))))

;; Function to test if a term from an expanded expression is a linear term
;; check and see that exactly one item in the product is the main var and
;; all others are free of the main var.  Returns NIL or a G-REP expression.

(defun linear-term-p (exp var)
  (cond ((atom exp)
	 (cond ((eq exp var) 1)
	       (t nil)))
	(t (case (g-rep-operator exp)
	     (mtimes
	      (do ((factor (car (g-rep-operands exp)) ;individual factors
			   (car rest))
		   (rest (cdr (g-rep-operands exp)) ;factors yet to be done
			 (cdr rest))
		   (main-var-p)	     ;nt -> main-var seen at top level
		   (list-of-factors))	;accumulate our factors
		  ((null factor)	;for all factors
		   (and main-var-p
					;no-main-var at top level -=> not linear
			(make-mtimes-l list-of-factors)))
		(cond ((eq factor var)  ;if it's our main var
					;note it...it has to be there to be a linear term
		       (setq main-var-p t))
		      ((broken-freeof var factor) ;if 
		       (push factor list-of-factors))
		      (t (return nil)))))
	     (t nil)))))


;;; DISPATCHING FUNCTION ON DEGREE OF EXPRESSION
;;; This is a crock of shit, it should be data driven and be able to
;;; dispatch to all manner of special cases that are in a table.
;;; EXP here is a polynomial in MRAT form.  All of this well-structured,
;;; intelligently-designed code works by side effect.  SOLVECUBIC
;;; takes something that looks like (G0003 3 4 1 1 0 10) as an argument
;;; and returns something like ((MEQUAL) $X ((MTIMES) ...)).  You figure
;;; out where the $X comes from.

;;; It comes from GENVARS/VARLIST, of course.  Isn't this wonderful rational
;;; function package irrational?  If you don't know about GENVARS and
;;; VARLIST, you'd better bite the bullet and learn...everything depends
;;; on them.  The canonical example of mis-use of special variables!
;;; --RWK

(defun solve1a (exp mult) 
  (let ((*myvar *myvar)
	(*g nil)) 
    (cond ((atom exp) nil)
	  ((not (memalike (setq *myvar (pdis (list (car exp) 1 1)))
			  *has*var))
	   nil)
	  ((equal (cadr exp) 1) (solvelin exp))
	  ((specasep exp) (solvespec exp t))
	  ((equal (cadr exp) 2) (solvequad exp))
	  ((not (equal 1 (setq *g (solventhp (cdddr exp) (cadr exp)))))
	   (solventh exp *g))
	  ((equal (cadr exp) 3) (solvecubic exp))
	  ((equal (cadr exp) 4) (solvequartic exp))
	  (t (let ((tt (solve-by-decomposition exp *myvar)))
	       (setq *failures (append (solution-losses tt) *failures))
	       (setq *roots    (append (solution-wins tt) *roots)))))))

(defun solve-simplist (list-of-things)
  (g-rep-operands (simplifya (make-mlist-l list-of-things) nil)))

;; The Solve-by-decomposition program returns the cons of (ROOTS . FAILURES).
;; It returns a "Solution" object, that is, a CONS with the CAR being the
;; failures and the CDR being the successes.
;; It takes a POLY as an argument and returns a SOLUTION.

(defun solve-by-decomposition (poly *$var)
  (let ((decomp))
    (cond ((or (not $solvedecomposes)
	       (= (length (setq decomp (polydecomp poly (poly-var poly)))) 1))
	   (make-solution nil `(,(make-mequal 0 (pdis poly)) 1)))
	  (t (decomp-trace (make-mequal 0 (rdis (car decomp)))
			   decomp
			   (poly-var poly) *$var 1)))))

;; DECOMP-TRACE is the recursive function which maps itself down the
;; intermediate solutions until the end is reached.  If it encounters
;; non-solvable equations it stops.  It returns a SOLUTION object, that is, a
;; CONS with the CAR being the failures and the CDR being the successes.

(defun decomp-trace (eqn decomp var *$var mult &aux sol chain-sol wins losses)
  (setq sol (if decomp
		(re-solve eqn *$var mult)
		(make-solution `(,eqn 1) nil)))
  (cond ((solution-losses sol) sol)
	;; End test
	((null decomp) sol)
	(t (do ((l (solution-wins sol) (cddr l)))
	       ((null l))
	     (setq chain-sol
		   (decomp-chain (car l) (cdr decomp) var *$var (cadr l)))
	     (setq wins (nconc wins
			       (copy-top-level (solution-wins chain-sol))))
	     (setq losses (nconc losses
				 (copy-top-level (solution-losses chain-sol)))))
	   (make-solution wins losses))))

;; Decomp-chain is the function which formats the mess for the recursive call.
;; It returns a "Solution" object, that is, a CONS with the CAR being the
;; failures and the CDR being the successes.

(defun decomp-chain (rsol decomp var *$var mult)
  (let ((sol (simplify (make-mequal (rdis (if decomp (car decomp)
					      ;; Include the var itself in the decomposition
					      (make-mrat-body (make-mrat-poly var '(1 1)) 1)))
				    (mequal-rhs rsol)))))
    (decomp-trace sol decomp var *$var mult)))

;; RE-SOLVE calls SOLVE recursively, returning a SOLUTION object.
;; Will not decompose or factor.

(defun re-solve (eqn var mult)
  (let ((*roots nil)
	(*failures nil)
	;; We've already decomposed and factored
	($solvedecomposes)
	($solvefactors))
    (solve eqn var mult)
    (make-solution *roots *failures)))

;; SOLVENTH programs test to see if the variable of interest appears 
;; to some power in all terms.  If so, a new variable is substituted for it
;; and the simpler expression solved with the multiplicity
;; adjusted accordingly.
;; SOLVENTHP returns gcd of exponents.

(defun solventhp (l gcd) 
  (cond ((null l) gcd)
	((equal gcd 1) 1)
	(t (solventhp (cddr l)
		      (gcd (car l) gcd)))))

;; Reduces exponents by their gcd.

(defun solventh (exp *g) 
  (let ((*varb (pdis (make-mrat-poly (poly-var exp) '(1 1))))
	(exp   (make-mrat-poly (poly-var exp) (solventh1 (poly-terms exp)))))
    (let* ((rts (re-solve-full (pdis exp) *varb))
	   (fails (solution-losses rts))
	   (wins (solution-wins rts))
	   (*power (make-mexpt *varb *g)))
      (map2c #'(lambda (w z)
		 (cond ((atom *varb)
			(solve (make-mequal *power (mequal-rhs w)) *varb z))
		       (t (let ((rts (re-solve-full
				      (make-mequal *power (mequal-rhs w))
				      *varb)))
			    (map2c #'(lambda (root mult)
				       (solve (make-mequal (mequal-rhs root) 0)
					      *myvar mult))
				   (solution-wins rts))))))
	     wins)
      (map2c #'(lambda (w z)
		 (push z *failures)
		 (push (solventh3 w *power *varb) *failures))
	     fails)
      *roots)))

(defun solventh3 (w *power *varb &aux varlist genvar *flg w1 w2)
  (cond ((broken-freeof *varb w) w)
	(t (setq w1 (ratf (cadr w)))
	   (setq w2 (ratf (caddr w)))
	   (setq varlist
		 (mapcar #'(lambda (h) 
			     (cond (*flg h)
				   ((alike1 h *varb)
				    (setq *flg t)
				    *power)
				   (t h)))
			 varlist))
	   (list (car w) (rdis (cdr w1)) (rdis (cdr w2))))))

(declare-top (muzzled t))
(defun solventh1 (l) 
  (cond ((null l) nil)
	(t (cons (quotient (car l) *g)
		 (cons (cadr l) (solventh1 (cddr l)))))))
(declare-top (muzzled nil))

;; Will decompose or factor

(defun re-solve-full (x var &aux *roots *failures)
  (solve x var mult)
  (make-solution *roots *failures))

;; Sees if expression is of the form A*F(X)^N+B.

(defun specasep (e)
  (and (memalike (pdis (list (car e) 1 1)) *has*var)
       (or (atom (caddr e))
	   (not (memalike (pdis (list (caaddr e) 1 1))
			  *has*var)))
       (or (null (cdddr e)) (equal (cadddr e) 0))))

;; Solves the special case A*F(X)^N+B.

(declare-top (muzzled t))
(defun solvespec (exp $%emode) 
  (prog (a b c) 
     (setq a (pdis (caddr exp)))
     (setq c (pdis (list (car exp) 1 1)))
     (cond ((null (cdddr exp))
	    (return (solve c *var (times (cadr exp) mult)))))
     (setq b (pdis (pminus (cadddr (cdr exp)))))
     (return (solvespec1 c
			 (simpnrt (div* b a) (cadr exp))
			 (make-rat 1 (cadr exp))
			 (cadr exp)))))
(declare-top (muzzled nil))

(defun solvespec1 (var root n thisn) 
  (do ((thisn thisn (f1- thisn))) ((zerop thisn))
    (solve (add* var (mul* -1 root
			   (power* '$%e (mul* 2 '$%pi '$%i thisn n))))
	   *var mult)))


;; ADISPLINE displays a line like DISPLINE, and in addition, notes that it is
;; not free of *VAR if it isn't.

(defun adispline (line)
  ;; This may be redundant, but nice if ADISPLINE gets used where not needed.
  (cond ((and $breakup (not $programmode))
	 (let ((linelabel (displine line)))
	   (cond ((broken-freeof *var line))
		 (t (setq broken-not-freeof
			  (cons linelabel broken-not-freeof))))
	   linelabel))
	(t (displine line))))

;; Predicate to check if an expression which may be broken up
;; is freeof

(setq broken-not-freeof nil)

;; For consistency, use backwards args.

(defun broken-freeof (var exp)
  (cond ($breakup
	 (do ((b-n-fo var (car b-n-fo-l))
	      (b-n-fo-l broken-not-freeof (cdr b-n-fo-l)))
	     ((null b-n-fo) t)
	   (and (not (argsfreeof b-n-fo exp))
		(return nil))))
	(t (argsfreeof var exp))))

;; Adds solutions to roots list.
;; Solves for inverse of functions (via USOLVE)

(defun solve3 (exp mult) 
  (setq exp (simplify exp))
  (cond ((not (broken-freeof *var exp))
	 (push mult *failures)
	 (push (make-mequal-simp (simplify *myvar) exp) *failures))
	(t (cond ((eq *myvar *var)
		  (push mult *roots)
		  (push (make-mequal-simp *var exp) *roots))
		 ((atom *myvar)
		  (push mult *failures)
		  (push (make-mequal-simp *myvar exp) *failures))
		 (t (usolve exp (g-rep-operator *myvar)))))))


;; Solve a linear equation.  Argument is a polynomial in pseudo-cre form.
;; This function is called for side-effect only.

(defun solvelin (exp) 
  (cond ((equal 0. (pterm (cdr exp) 0.))
	 (solve1a (caddr exp) mult)))
  (solve3 (rdis (ratreduce (pminus (pterm (cdr exp) 0.))
			   (caddr exp)))
	  mult))

;; Solve a quadratic equation.  Argument is a polynomial in pseudo-cre form.
;; This function is called for side-effect only.
;; The code for handling the case where the discriminant = 0 seems to never
;; be run.  Presumably, the expression is factored higher up.

(declare-top (muzzled t))
(defun solvequad (exp &aux discrim a b c)
  (setq a (caddr exp))
  (setq b (pterm (cdr exp) 1.))
  (setq c (pterm (cdr exp) 0.))
  (setq discrim (simplify (pdis (pplus (pexpt b 2.)
				       (pminus (ptimes 4. (ptimes a c)))))))
  (setq b (pdis (pminus b)))
  (setq a (pdis (ptimes 2. a)))
  ;; At this point, everything is back in general representation.
  (let ((varlist nil)) ;;2/6/2002 RJF
    (cond ((equal 0. discrim)
	   (solve3 (fullratsimp `((mquotient) ,b ,a))
		   (times 2. mult)))
	  (t (setq discrim (simpnrt discrim 2.))
	     (solve3 (fullratsimp `((mquotient) ((mplus) ,b ,discrim) ,a))
		     mult)
	     (solve3 (fullratsimp `((mquotient) ((mplus) ,b ((mminus) ,discrim)) ,a))
		     mult)))))
(declare-top (muzzled nil))

;; Reorders V so that members which contain the variable of
;; interest come first.

(defun varsort (v)
  (let ((*u nil)
	(*v (copy-top-level v)))
    (mapc #'(lambda (z) 
	      (cond ((broken-freeof *var z)
		     (setq *u (cons z *u))
		     (setq *v (zl-delete z *v 1)))))
	  v)
    (setq $dontfactor *u)
    (setq *has*var *v)
    (append *u *v)))

;; Solves for variable when it occurs within a function by taking the inverse.
;; When this code is fixed, the `((mplus) ,x ,y) forms should be rewritten as
;; (MAKE-MPLUS X Y).  I didn't do this because the code was buggy and it should
;; be fixed first.  - cwh
;; You mean you didn't do it because you were buggy.  Hope you're fixed soon!
;; --RWK

(defun usolve (exp op) 
  (prog (inverse) 
     (setq inverse
	   (cond
	     ((eq op 'mexpt)
	      (cond ((broken-freeof *var
				    (cadr *myvar))
		     (cond ((equal exp 0)
			    (go fail)))
		     `((mplus) ((mminus) ,(caddr *myvar))
		       ,(div* `((%log) ,exp)
			      `((%log) ,(cadr *myvar)))))
		    ((broken-freeof *var
				    (caddr *myvar))
		     (cond ((equal exp 0)
			    (cond ((mnegp (caddr *myvar))
				   (go fail))
				  (t (cadr *myvar))))
			   ;; There is a bug right here.
			   ;; SOLVE(SQRT(U)+1) should return U=1
			   ;; This code is entered with EXP = -1, OP = MEXPT
			   ;; *VAR = U, and *MYVAR = ((MEXPT) U ((RAT) 1 2))
			   ;; BULLSHIT -- RWK.  That is precisely the bug
			   ;; this code was added to fix!
			   ((and (not (eq (ask-integer (caddr *myvar)
						       '$integer)
					  '$yes))
				 (free exp '$%i)
				 (eq ($asksign exp) '$neg))
			    (go fail))				    
			   (t `((mplus) ,(cadr *myvar)
				((mminus)
				 ((mexpt) ,exp
				  ,(div* 1 (caddr *myvar))))))))
		    (t (go fail))))
	     ((setq inverse (get op '$inverse))
	      (when (and $solvetrigwarn
			 (memq op '(%sin %cos %tan %sec
				    %csc %cot %cosh %sech)))
		(mtell "~&SOLVE is using arc-trig functions to get ~
			    a solution.~%Some solutions will be lost.~%")
		(setq $solvetrigwarn nil))
	      `((mplus) ((mminus) ,(cadr *myvar))
		((,inverse) ,exp)))
	     ((eq op '%log)
	      `((mplus) ((mminus) ,(cadr *myvar))
		((mexpt) $%e ,exp)))
	     (t (go fail))))
     (return (solve (simplify inverse) *var mult))
     fail (return (setq *failures
			(cons (simplify `((mequal) ,*myvar ,exp))
			      (cons mult *failures))))))

;; Predicate for determining if an expression is messy enough to 
;; generate a new linelabel for it.
;; Expression must be in general form.

(defun complicated (exp)
  (and $breakup
       (not $programmode)
       (not (free exp 'mplus))))

(declare-top (muzzled t))
(defun rootsort (l) 
  (prog (a fm fm1) 
   g1   (cond ((null l) (return nil)))
   (setq a (car (setq fm l)))
   (setq fm1 (cdr fm))
   loop (cond ((null (cddr fm)) (setq l (cddr l)) (go g1))
	      ((alike1 (caddr fm) a)
	       (rplaca fm1 (plus (car fm1) (cadddr fm)))
	       (rplacd (cdr fm) (cddddr fm))
	       (go loop)))
   (setq fm (cddr fm))
   (go loop)))
(declare-top (muzzled nil))

;; Stuff moving in from MAT to get it out of core.

(defmfun $linsolve (eql varl)
  (let (($ratfac))
    (setq eql (cond (($listp eql) (cdr eql))
		    (t (ncons eql))))
    (setq varl (cond (($listp varl) (remred (cdr varl)))
		     (t (ncons varl))))
    (do ((varl varl (cdr varl))) ((null varl))
      (cond ((mnump (car varl))
	     (merror "Unacceptable variable to SOLVE: ~M"
		     (car varl)
		     ))))
    (cond ((null varl) (make-mlist-simp))
	  (t (solvex (mapcar 'meqhk eql) varl (not $programmode) nil)))
    ))

;; REMRED removes any repetition that may be in the variables list
;; The NREVERSE is significant here for some reason?

(defun remred (l) (if l (nreverse (union1 l nil))))

(defun solvex (eql varl ind flag &aux ($algebraic $algebraic))
  (declare (special xa*))
  (prog (*varl ans varlist genvar lsolveflag xm* xn* mul* solvexp)
     (setq *varl varl)
     (setq solvexp flag)
     (setq lsolveflag t)
     (setq eql
	   (mapcar #'(lambda (x) ($ratdisrep ($ratnumer x)))
		   eql))
     (cond ((atom (let ((errrjfflag  t))
		    (catch 'raterr (formx flag 'xa* eql varl))))
	    ;; This flag is T if called from SOLVE
	    ;; and NIL if called from LINSOLVE.
	    (cond (flag (return ($algsys (make-mlist-l eql)
					 (make-mlist-l varl))))
		  (t (merror "LINSOLVE ran into a nonlinear equation.")))))
     (setq ans (tfgeli 'xa* xn* xm*))
     (if (and $linsolvewarn (car ans))
	 (mtell "~&Dependent equations eliminated:  ~A~%" (car ans)))
     (if (cadr ans)
	 (if $solve_inconsistent_error
	     (merror "Inconsistent equations:  ~A" (cadr ans))
	     (return '((mlist simp)))))
     (do ((j 0 (f1+ j)))
	 ((> j xm*))
       ;;I put this in the value cell--wfs 
					; (STORE ( XA* 0 J) NIL))
       (store (arraycall t xa* 0 j) nil))
     (ptorat 'xa* xn* xm*)
     (setq varl
	   (xrutout 'xa* xn* xm* 
		    (mapcar #'(lambda (x) (ith varl x))
			    (caddr ans))
		    ind))
     (*rearray 'xa*)
     (if $programmode
	 (setq varl (make-mlist-l (linsort (cdr varl) *varl))))
     (return varl)))

;; (LINSORT '(((MEQUAL) A2 FOO) ((MEQUAL) A3 BAR)) '(A3 A2))
;; returns (((MEQUAL) A3 BAR) ((MEQUAL) A2 FOO)) .

(defun linsort (meq-list var-list)
  (mapcar #'(lambda (x) (cons (caar meq-list) x))
	  (sortcar (mapcar #'cdr meq-list)
		   #'(lambda (x y)
		       (zl-member y (zl-member x var-list))))))
