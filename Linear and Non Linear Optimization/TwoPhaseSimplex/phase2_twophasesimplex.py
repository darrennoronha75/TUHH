import Program from program
import Phase1_TwoPhaseSimplex from phase1_twophasesimplex
import Phase2_TwoPhaseSimplex from phase2_twophasesimplex

class Run_TwoPhaseSimplex(Program):
    def __init__(self, lp_phase_1, lp_phase_2):
        super().__init__()
        self.phase_1_solver = Phase1_TwoPhaseSimplex(lp_phase_1)
        self.phase_2_solver = None
        self.lp_phase_2 = lp_phase_2

    def run(self):
        self.phase_1_solver.phase_1()
        if self.phase_1_solver.simplex.check_infeasibility():
            print("Exiting: Problem is infeasible.")
            return
        elif self.phase_1_solver.simplex.check_unboundedness():
            print("Exiting: Problem is unbounded.")
            return

        self.phase_2_solver = Phase2_TwoPhaseSimplex(self.phase_1_solver.phase_1_solution, self.lp_phase_2)
        self.phase_2_solver.phase_2()
        self.phase_2_solver.check_certificate_phase_2()
        self.phase_2_solver.print_results()
