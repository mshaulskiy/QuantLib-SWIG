; Copyright (C) 2000, 2001, 2002 RiskMap srl
;
; This file is part of QuantLib, a free-software/open-source library
; for financial quantitative analysts and developers - http://quantlib.org/
;
; QuantLib is free software developed by the QuantLib Group; you can
; redistribute it and/or modify it under the terms of the QuantLib License;
; either version 1.0, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; QuantLib License for more details.
;
; You should have received a copy of the QuantLib License along with this
; program; if not, please email ferdinando@ametrano.net
;
; The QuantLib License is also available at http://quantlib.org/license.html
; The members of the QuantLib Group are listed in the QuantLib License
;
; $Id$

(use-modules (QuantLib))
(load "common.scm")

(define (Distribution-test)
  (define (check-difference f1 f2 h tolerance f1-name f2-name)
    (let ((e (norm (difference f1 f2) h)))
      (if (> e tolerance)
          (let ((error-msg
                 (string-append
                  (format "norm of ~a minus ~a: ~a:~n"
                          f1-name f2-name e)
                  (format "tolerance exceeded~n"))))
            (error error-msg)))))
  (define (difference f1 f2)
    (map - f1 f2))

  (deleting-let* ((average 0.0 do-not-delete)
                  (sigma 1.0 do-not-delete)
                  (normal-dist (new-NormalDistribution average sigma)
                               delete-NormalDistribution)
                  (cumul-dist (new-CumulativeNormalDistribution 
                               average sigma)
                               delete-CumulativeNormalDistribution)
                  (inverse-dist (new-InvCumulativeNormalDistribution
                                 average sigma)
                                delete-InvCumulativeNormalDistribution)
                  (inverse-dist-2 (new-InvCumulativeNormalDistribution2
                                   average sigma)
                                  delete-InvCumulativeNormalDistribution2))
    (let* ((N 10001)
           (xmin (- average (* 4.0 sigma)))
           (xmax (+ average (* 4.0 sigma)))
           (h (grid-step xmin xmax N))
           (x (grid xmin xmax N)))

        (define pi (acos -1.0))
        (define (gaussian x)
          (let ((dx (- x average)))
            (/ (exp (/ (- (* dx dx)) (* 2.0 sigma sigma)))
               (* sigma (sqrt (* 2.0 pi))))))
        (define (gaussian-derivative x)
          (let ((dx (- x average)))
            (/ (* (- dx) (exp (/ (- (* dx dx)) (* 2.0 sigma sigma))))
               (* sigma sigma sigma (sqrt (* 2 pi))))))
        (define (normal x)
          (NormalDistribution-call normal-dist x))
        (define (normal-derivative x)
          (NormalDistribution-derivative normal-dist x))
        (define (cumulative x)
          (CumulativeNormalDistribution-call cumul-dist x))
        (define (cumulative-derivative x)
          (CumulativeNormalDistribution-derivative cumul-dist x))
        (define (inverse-cumulative x)
          (InvCumulativeNormalDistribution-call inverse-dist x))
        (define (inverse-cumulative-2 x)
          (InvCumulativeNormalDistribution2-call inverse-dist-2 x))

        (let* ((y (map gaussian x))
               (y-int (map cumulative x))
               (y-temp (map normal x))
               (y2-temp (map cumulative-derivative x))
               (x-temp (map inverse-cumulative y-int))
               (x-temp-2 (map inverse-cumulative-2 y-int))
               (yd (map normal-derivative x))
               (yd-temp (map gaussian-derivative x)))
          
          (check-difference y y-temp h 1.0e-16
                            "C++ normal distribution"
                            "analytic Gaussian")
          (check-difference x x-temp h 1.0e-3
                            "C++ invCum(cum(.))"
                            "identity")
          (check-difference x x-temp-2 h 1.0e-3
                            "C++ invCum2(cum(.))"
                            "identity")
          (check-difference y y2-temp h 1.0e-16
                            "C++ Cumulative.derivative"
                            "analytic Gaussian")
          (check-difference yd yd-temp h 1.0e-16
                            "C++ NormalDist.derivative"
                            "analytic Gaussian derivative")))))


