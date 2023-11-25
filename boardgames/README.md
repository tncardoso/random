# Boardgames

Random analysis and experiments related to boardgames.

 ## Turing Machine
 
[Turing Machine](https://turingmachine.info/) is a deduction game in which you need to find the secret code. This [solver](boardgames/turingmachine/solve.hy) works in two steps:

- Prune possible codes to given machine
- Choose the best test that will maximize the worst case scenario (machine outcome)
