(import argparse)
(import rich [print])
(import boardgames.turingmachine.solve *)
(import boardgames.turingmachine.card *)

(defn banner []
  "[yellow]

           ████████╗██╗   ██╗██████╗ ██╗███╗   ██╗ ██████╗         
           ╚══██╔══╝██║   ██║██╔══██╗██║████╗  ██║██╔════╝         
              ██║   ██║   ██║██████╔╝██║██╔██╗ ██║██║  ███╗        
              ██║   ██║   ██║██╔══██╗██║██║╚██╗██║██║   ██║        
              ██║   ╚██████╔╝██║  ██║██║██║ ╚████║╚██████╔╝        
              ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝         
                                                                
        ███╗   ███╗ █████╗  ██████╗██╗  ██╗██╗███╗   ██╗███████╗
        ████╗ ████║██╔══██╗██╔════╝██║  ██║██║████╗  ██║██╔════╝
        ██╔████╔██║███████║██║     ███████║██║██╔██╗ ██║█████╗  
        ██║╚██╔╝██║██╔══██║██║     ██╔══██║██║██║╚██╗██║██╔══╝  
        ██║ ╚═╝ ██║██║  ██║╚██████╗██║  ██║██║██║ ╚████║███████╗
        ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝

[/yellow]")

(defn cmd-solve [args]
  (print (solve-machine card-09-quantity-of-3
                        card-16-even-vs-odd
                        card-25-ascending-descending
                        card-26-color-less-3
                        card-47-quantity-of-1-or-4
                        card-48-digit-to-digit)))

(defn main []
  (print (banner))
  (setv parser (argparse.ArgumentParser
                 :description "Turing Machine https://turingmachine.info/"))
  (setv subparsers (parser.add_subparsers
                     :dest "command"))
  (setv solve-parser (subparsers.add_parser "solve"
                                            :help "Solve machine"))
  (setv args (parser.parse_args))
  
  (if (= args.command "solve")
      (cmd-solve args)
      (parser.print_help))

  )

(when (= __name__ "__main__") (main))
