import Program from program
import Simplex from simplex


## To be defined once base Simplex class is implemented

class Phase1_TwoPhaseSimplex(Program):
    def __init__(self, lp):
        super().__init__()
        self.simplex = Simplex(lp)  # Use the Simplex class with the Phase 1 LP
        self.phase_1_solution = None
        self.certificate = Certificate(self)

    def phase_1(self):
        """
        Implement Phase 1 of the Simplex method.

        Returns:
        - None
        """
        self.phase_1_solution = self.simplex.solve()
        self.check_certificate_phase_1()

    def check_certificate_phase_1(self):
        if self.simplex.check_infeasibility():
            print("Phase 1: The problem is infeasible.")
        elif self.simplex.check_unboundedness():
            print("Phase 1: The problem is unbounded.")
        else:
            print("Phase 1: No certificate found. Continue with Phase 2.")
