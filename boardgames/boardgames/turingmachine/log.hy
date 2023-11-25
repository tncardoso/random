(import rich [print])

(defn log/info [#* args]
  (print "[[bold white]![/bold white]]" #* args))

(defn log/succ [#* args #** kwargs]
  (print "[[bold green]+[/bold green]]" #* args #** kwargs))

(defn log/print [#* args #** kwargs]
  (print #* args #** kwargs))
