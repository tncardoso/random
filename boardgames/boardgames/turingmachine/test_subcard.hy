(import boardgames.turingmachine.subcard *)

(defn test-subcard-number-of-target []
  (let [board (np.array [[1 1 1]
                         [3 1 1]
                         [2 3 2]
                         [4 5 3]
                         [3 3 1]
                         [5 3 3]
                         [3 2 3]
                         [3 3 3]])
        board-3-0 (subcard-number-of-target board 3 0)
        board-3-0-expected (np.array [[1 1 1]])
        board-3-1 (subcard-number-of-target board 3 1)
        board-3-1-expected (np.array [[3 1 1]
                                    [2 3 2]
                                    [4 5 3]])
        board-3-2 (subcard-number-of-target board 3 2)
        board-3-2-expected (np.array [[3 3 1]
                                    [5 3 3]
                                    [3 2 3]])
        board-3-3 (subcard-number-of-target board 3 3)
        board-3-3-expected (np.array [[3 3 3]])]
  (assert (np.array_equal board-3-0 board-3-0-expected))
  (assert (np.array_equal board-3-1 board-3-1-expected))
  (assert (np.array_equal board-3-2 board-3-2-expected))
  (assert (np.array_equal board-3-3 board-3-3-expected))))

(defn test-subcard-even-vs-odd []
  (let [board-0 (np.array [[1 1 1]
                         [3 1 1]
                         [2 3 2]
                         [4 5 3]
                         [3 3 1]
                         [5 3 3]
                         [3 2 3]
                         [4 4 3]])
        board-0-gt (subcard-even-vs-odd board-0 np.greater)
        board-0-gt-expected (np.array [[2 3 2]
                                       [4 4 3]])
        board-0-lt (subcard-even-vs-odd board-0 np.less)
        board-0-lt-expected (np.array [[1 1 1]
                                       [3 1 1]
                                       [4 5 3]
                                       [3 3 1]
                                       [5 3 3]
                                       [3 2 3]])]
  (assert (np.array_equal board-0-gt board-0-gt-expected))
  (assert (np.array_equal board-0-lt board-0-lt-expected))))

(defn test-subcard-ascending-descending []
  (let [board-0 (np.array [[1 1 1]
                           [1 2 3]
                           [3 1 1]
                           [2 3 2]
                           [4 5 3]
                           [3 3 1]
                           [5 3 3]
                           [3 2 3]
                           [4 4 3]])
        board-0-0 (subcard-ascending-descending board-0 0)
        board-0-0-expected (np.array [[1 1 1]
                                      [3 1 1]
                                      [3 3 1]
                                      [5 3 3]])
        board-0-1 (subcard-ascending-descending board-0 1)
        board-0-1-expected (np.array [[2 3 2]
                                      [4 5 3]
                                      [3 2 3]
                                      [4 4 3]])
        board-0-2 (subcard-ascending-descending board-0 2)
        board-0-2-expected (np.array [[1 2 3]])]
  (assert (np.array_equal board-0-0 board-0-0-expected))
  (assert (np.array_equal board-0-1 board-0-1-expected))
  (assert (np.array_equal board-0-2 board-0-2-expected))))

