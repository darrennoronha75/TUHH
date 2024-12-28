import numpy as np
from program import Program
from simplex import Simplex
from certificate import Certificate
from simplex_p1 import Simplex_P1

# Phase 2 of the Two-Phase Simplex Method

class Simplex_P2(Program):
    def __init__(self, phase_1_solution, phase_1_objective_value, lp):
        super().__init__()
        self.lp = lp
        self.phase_1_solution = phase_1_solution
        self.phase_1_objective_value = phase_1_objective_value

        # Run Phase 2 of the Simplex method
        solution, objective_value = self.phase_2(phase_1_solution, phase_1_objective_value, lp)
        self.print_results()
       

    def phase_2(self, phase_1_solution, phase_1_objective_value, lp):
        """
        Implement Phase 2 of the Simplex method.

        Returns:
        - None
        """        

        # We will assume the original LP is infeasible if the objective value from Phase 1 is not zero.
        if phase_1_objective_value != 0:
            print("\n\nAs the Auxiliary LP returns a non-zero objective value, the original LP is infeasible.")
            print("Algorithm stops here.")
            return None, None
        else:
            print("\n\nSince the Auxiliary LP returns a zero objective value, the original LP is feasible.")
            print("We will now proceed to Phase 2 of the Two-Phase Simplex Method. \n")
            print("\n-----------------------------------------------------------------------------------------------")


        print("*******************************************")
        print("###########################################\n")
        print("           Phase 2 - Simplex               ")
        print("\n###########################################")
        print("*******************************************")


        # We will calculate the basis indexes for the original LP using the solution from Phase 1.
        # The basis indexes are the indexes of the non-auxiliary variables in the original LP, that have a non-zero value in the solution from Phase 1.
        
        basis = np.where(phase_1_solution[:lp.A.shape[1]] != 0)[0]
        print(f"\nAs per results recieved from Phase 1 Auxiliary LP Simplex run, starting variables in basis : x{', x'.join(map(str, basis + 1))}")

        # The initial solution for the original LP is set to the solution from Phase 1. We will remove the auxiliary variables from the solution.
        solution = phase_1_solution[:lp.A.shape[1]]
        
        print("Initial Solution : ", solution)

        simplex_solver = Simplex(self.lp, basis=basis, solution=solution, identifier="Original LP")
        solution, objective_value = simplex_solver.solve()

        return solution, objective_value
        

    def print_results(self):
        """
        Display the results from Phase 2.

        Returns:
        - None
        """
        pass
