import Program from program
import Phase1_TwoPhaseSimplex from phase1_twophasesimplex
import Simplex from simplex

## To be defined once base Simplex class is implemented

class Phase2_TwoPhaseSimplex(Program):
    def __init__(self, phase_1_solution, lp):
        super().__init__()
        self.phase_1_solution = phase_1_solution
        self.simplex = Simplex(lp)  # Use the Simplex class with the Phase 2 LP
        self.phase_2_solution = None
        self.certificate = Certificate(self)

    def phase_2(self):
        """
        Implement Phase 2 of the Simplex method.

        Returns:
        - None
        """
        self.phase_2_solution = self.simplex.solve()
        self.check_certificate_phase_2()

    def check_certificate_phase_2(self):
        if self.simplex.check_optimality():
            print("Phase 2: The solution is optimal.")
        else:
            print("Phase 2: No certificate found. Further adjustments might be needed.")

    def print_results(self):
        """
        Display the results from Phase 2.

        Returns:
        - None
        """
        pass
