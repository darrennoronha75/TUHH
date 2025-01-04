from program import Program
from simplex_p1 import Simplex_P1
from simplex_p2 import Simplex_P2
import time


class Simplex_Solver(Program):
    def __init__(self, lp):
        self.lp = lp
        self.phase_1 = None
        self.phase_2 = None

        # Run the Two-Phase Simplex Method
        self.run_two_phase_method(lp)

        
    def run_two_phase_method(self, lp):        
        # Phase 1 of the Two-Phase Simplex Method

        print("We will now proceed to Phase 1 of the Two-Phase Simplex Method.")
        print("Our first step is to construct and solve the Auxiliary LP construction for the given LP. \n")

        print("Beginning Algorithm run, ")

        # Applying the Two-Phase Simplex Method on the given LP

        start_time = time.time()
        self.phase_1 = Simplex_P1(self.lp)
        # Phase 2 of the Two-Phase Simplex Method
        self.phase_2 = Simplex_P2(self.phase_1.solution, self.phase_1.objective_value, self.lp)
        end_time = time.time()        

        print(f"\nTotal runtime for the Two-Phase Simplex method algorithm is {end_time - start_time:.4f} seconds.")


