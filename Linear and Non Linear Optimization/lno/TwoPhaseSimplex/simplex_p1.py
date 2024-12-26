from program import Program
from simplex import Simplex
from certificate import Certificate
import numpy as np

# Phase 1 of the Two-Phase Simplex Method

class Simplex_P1(Program):
    def __init__(self, lp):
        super().__init__()

        # Construct the Auxiliary LP for the provided LP.
        # The Auxiliary LP has the same constraints as the original LP,
        # but with an amended objective function to minimize the sum of the auxiliary variables.
        # Auxiliary variables are added to the original LP constraints to convert them into equations.
        self.auxiliary_lp = self.construct_auxiliary_lp(lp)
        
        #Print the Auxiliary LP matrices and equations
        print("Auxiliary LP:")
        self.auxiliary_lp.print_matrices()
        self.auxiliary_lp.print_equations()

        #Run Phase 1 of the Simplex method
        self.solution, self.objective_value = self.phase_1(self.auxiliary_lp)       


    def phase_1(self, auxiliary_lp):
        """
        Implement Phase 1 of the Simplex method.

        Returns:
        - None
        """
        # Initialize the Simplex solver for the Auxiliary LP

        # The basis is set to the identity matrix
        basis = np.arange(auxiliary_lp.basis_size)

        # The initial solution for the Auxiliary LP is to set all non-auxiliary variables to zero and set the auxiliary variables to the right-hand side values from the constraints (b).
        solution = np.zeros((auxiliary_lp.A.shape[1], 1))
        solution[:auxiliary_lp.basis_size] = auxiliary_lp.b

        auxiliary_solver = Simplex(auxiliary_lp, basis=basis, solution=solution, identifier="Auxiliary LP")
        solution, objective_value = auxiliary_solver.solve()

        return solution, objective_value


    def construct_auxiliary_lp(self, lp):
        # Store the original LP attributes
        original_A = lp.A
        original_b = lp.b
        original_c = lp.c
        original_signs = lp.signs
        original_objective_type = lp.objective_type
        original_constant_term = lp.constant_term
        original_basis_size = lp.basis_size

        # Define the Auxiliary LP:
        # - Augment the constraint matrix A with an identity matrix to include auxiliary variables.
        # - Set the objective function c to minimize the sum of the auxiliary variables.
        # - The right-hand side vector b remains the same as the original LP.
        # - The objective type is set to 'min' to find a feasible solution.
        # - The signs of the constraints remain unchanged.
        auxiliary_lp = Program()
        auxiliary_lp.A = np.hstack((original_A, np.eye(original_A.shape[0])))
        auxiliary_lp.b = original_b
        auxiliary_lp.c = np.vstack((np.zeros((original_A.shape[1], 1)), np.ones((original_basis_size, 1))))
        auxiliary_lp.objective_type = 'min'
        auxiliary_lp.constant_term = original_constant_term
        auxiliary_lp.signs = original_signs
        auxiliary_lp.calculate_basis_size()

        return auxiliary_lp