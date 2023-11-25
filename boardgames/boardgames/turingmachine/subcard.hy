; This file implements the subcard strategy. In the subcard strategy
; instead of choosing the codes that should be tested, we evaluate
; which combination of cards generates valid machines.

(import numpy :as np)
(import itertools [product permutations])
(import functools [reduce])
(import copy [copy])
(require hyrule [ncut])
(import boardgames.turingmachine.base *)
(import boardgames.turingmachine.log *)


(defn subcard-number-of-target [board target-digit target-count]
  "
  Subcard that computes if the candidate has a certain number of
  specific digit.
  "
  (let [board-target-count (.sum (np.equal board target-digit) :axis 1)]
    (ncut board (np.equal board-target-count target-count))))

(defn subcard-even-vs-odd [board operator-func]
  "
  Subcard that compares the number of even and odd digits in code.
  The number is compared using `operator-func`.
  "
  (let [board-parity (np.mod board 2)
        board-even-count (np.sum (np.equal board-parity 0) :axis 1)
        board-odd-count (np.sum (np.equal board-parity 1) :axis 1)
        board-result (operator-func board-even-count board-odd-count)
        ]
    (ncut board board-result)))

(defn subcard-ascending-descending [board n]
  "
  Subcard that checks if there are sequences of numbers in ascending or
  descending order. n is the number of ascending/descending *pairs*.

  Examples:
  - 135 | 531 => 0 pairs
  - _23_5 | 5_32_ => 1 pair
  - 234 | 432 => 2 pairs
  "
  (let [diff-01 (- (ncut board : 1) (ncut board : 0))
        diff-12 (- (ncut board : 2) (ncut board : 1))
        diff-01-ascending (.astype (np.equal diff-01 1) int)
        diff-12-ascending (.astype (np.equal diff-12 1) int)
        diff-ascending (+ diff-01-ascending diff-12-ascending)
        diff-ascending-target (np.equal diff-ascending n)
        diff-01-descending (.astype (np.equal diff-01 -1) int)
        diff-12-descending (.astype (np.equal diff-12 -1) int)
        diff-descending (+ diff-01-descending diff-12-descending)
        diff-descending-target (np.equal diff-descending n)
        diff-target (np.logical_or diff-ascending-target diff-descending-target)]
    (if (= n 0)
      (ncut board (np.logical_and diff-ascending-target diff-descending-target))
      (ncut board (np.logical_or diff-ascending-target diff-descending-target)))))

(defn subcard-digit-comparator [board digit comparator value]
  "
  This subcard compares a specific digit (triangle, square, circle)
  to a given number.
  "
  (let [target (comparator (ncut board : digit) value)]
    (ncut board target)))

(defn subcard-digit-to-digit-comparator [board digit1 comparator digit2]
  (let [digit1-value (ncut board : digit1)
        digit2-value (ncut board : digit2)
        target (comparator digit1-value digit2-value)]
    (ncut board target)))

(defn create-subcard [subcard-func #* args]
  "
  Creates an specific instantiation of subcard. For example,
  a subcard that checks if the number of (1) is equal to (2)
  could be reused to create a function that checks if the number
  of (1) is equal to (3).
  "
  (let [subcard-fname (. subcard-func __name__)
        fname (+ subcard-fname "_" (.join "_" (map str args)))
        f (fn [board] (subcard-func board #* args))]
    (setv f.__name__ fname)
    f))
    
