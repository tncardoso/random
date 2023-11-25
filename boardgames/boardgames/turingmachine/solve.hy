(import numpy :as np)
(import itertools [product permutations combinations])
(import functools [reduce])
(import copy [copy])
(import tqdm [tqdm])
(import cProfile)
(require hyrule [ncut])
(import boardgames.turingmachine.base *)
(import boardgames.turingmachine.card *)
(import boardgames.turingmachine.log *)

(defn new-board []
  "Return all posible code combinations."
  (let [opts (np.arange 1 6)]
    (np.array (list (product opts opts opts)) :dtype int)))

(defn run-machine [board #* subcards]
  "
  Run a given machine and return the resulting board
  "
  (reduce (fn [board subcard-func] (subcard-func board))
          subcards
          board))

(defn machine-combinations [machine]
  "
  Compute the number of possible subcard combinations in this machine.
  "
  (reduce (fn [x acc] (* x acc)) (map len machine) 1))

(defn softmax [x]
  "
  Softmax implementation for sampling distribution
  "
  (let [exp (np.exp x)]
    (/ exp (np.sum exp))))

(defn sample-by-improvement [improvements temperature]
  "
  Given a vector of expected improvements, sample based on the softmax.
  If the temperature is 0, then argmax is always sampled.
  "
  (if (= temperature 0.0)
    ; if temperature is 0.0, use argmax instead of sampling
    (np.argmax improvements)
    ; sample otherwise
    (let [distribution (softmax (/ improvements temperature))]
      (np.random.choice (np.arange (len improvements)) :p distribution)
      )))

(defn clean-board [machine board [progress False]]
  "
  Not every code is possible for the given card combination. After
  new information is discovered, and the machine is pruned, we clean
  the board. The process of cleaning remove any combination that is not
  possible in the current scenario.

  Every subcard combination is used to validate the board.
  "
  (setv possible-codes #{})
  (setv solutions [])
  (let [combinations (machine-combinations machine)
        submachines (if progress (tqdm (product #* machine) :total combinations)
                      (product #* machine))
        ]
    ;(for [submachine (tqdm (product #* machine) :total combinations)]
    (for [submachine submachines]
      (let [result (run-machine (new-board) #* submachine)
            result-size (len result)]

        ; if has more than one possible code, it is not our solution
        (when (= result-size 1)
          (do 
            (.append solutions #(submachine result))
            (.add possible-codes (tuple (get result 0)))))))

     ; return only valid comabinations
     (setv board-ret (np.array (list possible-codes)))
     (if (> (len board-ret) 0)
      (ncut board-ret (np.lexsort (. (np.fliplr board-ret) T)))
      board-ret)))

(defn update-machine [machine card-idx code output]
  "
  Update machine given we know the outcome of given card
  "
  (let [subcards (np.array (get machine card-idx))
        code-board (np.array [code])
        evaluated-cards (list (map
                                (fn [subcard-func] (len (subcard-func code-board)))
                                subcards))
        subcards-true (np.equal evaluated-cards 1)
        subcards-false (np.equal evaluated-cards 0)
        ]

    (setv new-machine (list (copy machine)))
    (if output
      ; if output is true, than only machines with true can be kept
      (setv (get new-machine card-idx) (.tolist (ncut subcards subcards-true)))
      ; if output is false, only machines with false for this code can be kept
      (setv (get new-machine card-idx) (.tolist (ncut subcards subcards-false))))

    new-machine))


(defn cards-candidate-improvement [machine board cards-idx code outcomes]
  ;(reduce (fn [x acc] (* x acc)) (map len machine) 1))
  (let [res-machine (reduce (fn [new-machine data] (update-machine 
                                                    new-machine
                                                    (get data 0)
                                                    code
                                                    (get data 1)))
                    (list (zip cards-idx outcomes))
                    machine)
        ; FIXME: we could take into account the resulting board as well
        pre-combinations (machine-combinations machine)
        res-combinations (machine-combinations res-machine)
        improvement (/ (- pre-combinations res-combinations) pre-combinations)]

    ; for now entropy considers only card combinations

    ;(log/succ "    machine_comb=" combinations
    ;          "machine_comb_after=" res-combinations
    ;          "candidates=" (len board)
    ;          "candidates_after=" (len new-board)
    ;          "total-combinations=" total-combinations)
    improvement))

(defn cards-candidate-min-improvement [machine board cards-idx code]
  "
  This function computes the expected entropy reduction in the machine
  if cards are chosen. Every possibility of outcome is calculated:
  TTT, TTF...

  The optimal test order is not considered in this function.
  "
  (let [outcomes (list (product [True False] :repeat 3))
        improvements (list (map (fn [outcome] (cards-candidate-improvement
                                          machine board
                                          cards-idx code outcome)) outcomes))]
    (np.min (list improvements))))

(defn choose-test-order [machine board cards-idx code]
  "
  Choose in which order cards should be tested. Currently it uses a greedy approach.
  "
  (setv cards-idx (list cards-idx))
  (setv test-order [])
  (setv test-order-improvements [])
  (while (> (len cards-idx) 0)
    (setv improvements (list (map (fn [card-idx] (cards-candidate-min-improvement
                                                   machine
                                                   board
                                                   (+ test-order [card-idx])
                                                   code)) cards-idx)))
    (setv best-card (get cards-idx (np.argmax improvements)))
    (.append test-order best-card)
    (.append test-order-improvements (np.max improvements))
    (.pop cards-idx (np.argmax improvements)))
  #(test-order test-order-improvements))


(defn choose-action [machine board [temperature 0.0]]
  "
  Choose best action for current machine and board combination
  "
  (let [current-machine-combinations (machine-combinations machine)
        candidates (len board)
        card-combinations (combinations (range (len machine)) 3)
        code-card-combinations (list (product board card-combinations))
        total-tests (len code-card-combinations)
        entropy-reduction (np.array (list (map 
                            (fn [code-card]
                              (setv #(code cards-idx) code-card)
                              (cards-candidate-min-improvement machine
                                                               board
                                                               cards-idx
                                                               code))
                            (tqdm code-card-combinations :total total-tests))))
        best-idx (sample-by-improvement entropy-reduction temperature)
        best-code (get (get code-card-combinations best-idx) 0)
        best-cards (get (get code-card-combinations best-idx) 1)
        #(best-cards-order best-cards-improvements) (choose-test-order
                                                      machine board
                                                      best-cards best-code)
        best-expected (get entropy-reduction best-idx)
        ]
    ; for every 3 machine combination, candidate
    ; compute entropy reduction
  #(best-code best-cards-order best-cards-improvements)))


(defn read-response [s]
  "
  Read outcome of machine from stdin. Only three values are accepted:
    t => card output is true
    f => card output is false
    n => didn't test machine
  "
  (log/print s :end " ")
  (setv resp (input "=> "))
  (while (and (!= resp "t") (!= resp "f") (!= resp "n"))
    (log/print s :end " ")
    (setv resp (input "=> ")))
  resp)

(defn do-action [machine board]
  "
  Given a machine, choose the best action to play.
  "
  ; test machine/code combinations to find best action
  (log/info "searching for good a candidate")
  (setv #(code cards improvements) (choose-action machine board))
  (log/succ "code=" code
            "cards=" (str cards)
            f"improvements="
            (.join ", " (list (map (fn [v] (.format "{:0.2f}" v)) improvements))))

  (for [card-idx cards]
    ; FIXME: get name of first subcard
    ; FIXME: decide when to stop
    (setv outcome (read-response (+ f"        card[{card-idx}]=" 
                                 (. (get (get machine card-idx) 0) __name__)
                                 "([bold white]t/f/n[/bold white]) => ")))
    (setv machine (if (= outcome "t")
                      (update-machine machine card-idx code True)
                      (if (= outcome "f")
                        (update-machine machine card-idx code False)
                        (break))))

    (log/info "updating machine belief")
    (setv board-cln (clean-board machine board))
    (log/succ "before_size=" (len board) "after_size=" (len board-cln))
    (setv board board-cln)
    (when (= (len board) 1)
      (break))
    )
    #(machine board)
  )

(defn solve-machine [#* machine]
  "
  Solve specific machine interactively. At each step clean board,
  choose which code and cards to test, ask for user input with
  outcome, and repeat until only one code is left.
  "
  (log/info "solving new machine")
  (setv board (new-board))

  ; the first step is to clean the board
  (log/info "cleaning board")
  (setv board-cln (clean-board machine board :progress True))
  (log/succ "before_size=" (len board) "after_size=" (len board-cln))

  ; we are done here!
  (when (= (len board-cln) 1)
    (return board))

  ; iterate until no codes are left
  (setv board board-cln)
  (while (> (len board) 1)
    (setv #(machine board) (do-action machine board)))

  board)

