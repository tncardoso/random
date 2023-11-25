(import boardgames.turingmachine.subcard *)

(setv card-09-quantity-of-3 [(create-subcard subcard-number-of-target 3 0)
                             (create-subcard subcard-number-of-target 3 1)
                             (create-subcard subcard-number-of-target 3 2)
                             (create-subcard subcard-number-of-target 3 3)])

(setv card-16-even-vs-odd [(create-subcard subcard-even-vs-odd np.greater)
                           (create-subcard subcard-even-vs-odd np.less)])

(setv card-25-ascending-descending [(create-subcard subcard-ascending-descending 0)
                                    (create-subcard subcard-ascending-descending 1)
                                    (create-subcard subcard-ascending-descending 2)])

(setv card-26-color-less-3 [(create-subcard subcard-digit-comparator triangle np.less 3)
                            (create-subcard subcard-digit-comparator square np.less 3)
                            (create-subcard subcard-digit-comparator circle np.less 3)])

(setv card-47-quantity-of-1-or-4 [(create-subcard subcard-number-of-target 1 0)
                                  (create-subcard subcard-number-of-target 1 1)
                                  (create-subcard subcard-number-of-target 1 2)
                                  (create-subcard subcard-number-of-target 4 0)
                                  (create-subcard subcard-number-of-target 4 1)
                                  (create-subcard subcard-number-of-target 4 2)])

(setv card-48-digit-to-digit [
    (create-subcard subcard-digit-to-digit-comparator triangle np.less square)
    (create-subcard subcard-digit-to-digit-comparator triangle np.equal square)
    (create-subcard subcard-digit-to-digit-comparator triangle np.greater square)
    (create-subcard subcard-digit-to-digit-comparator triangle np.less circle)
    (create-subcard subcard-digit-to-digit-comparator triangle np.equal circle)
    (create-subcard subcard-digit-to-digit-comparator triangle np.greater circle)
    (create-subcard subcard-digit-to-digit-comparator square np.less circle)
    (create-subcard subcard-digit-to-digit-comparator square np.equal circle)
    (create-subcard subcard-digit-to-digit-comparator square np.greater circle)])

(setv card-by-id [card-09-quantity-of-3
                  card-16-even-vs-odd
                  card-25-ascending-descending
                  card-26-color-less-3
                  card-47-quantity-of-1-or-4
                  card-48-digit-to-digit])
