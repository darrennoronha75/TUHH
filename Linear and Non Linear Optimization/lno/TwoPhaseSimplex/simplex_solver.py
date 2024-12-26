from program import Program
from simplex_p1 import Simplex_P1
from simplex_p2 import Simplex_P2


class Simplex_Solver(Program):
    def __init__(self, lp):
        self.lp = lp
        self.phase_1 = None
        self.phase_2 = None

        # Run the Two-Phase Simplex Method
        self.run_two_phase_method(lp)

        
    def run_two_phase_method(self, lp):        
        # Phase 1 of the Two-Phase Simplex Method
        self.phase_1 = Simplex_P1(self.lp)
        # Phase 2 of the Two-Phase Simplex Method
        self.phase_2 = Simplex_P2(self.phase_1.solution, self.lp)


