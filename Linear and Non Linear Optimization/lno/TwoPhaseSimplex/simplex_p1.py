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
        self.auxiliary_lp, self.initial_basis_indices = self.construct_auxiliary_lp(lp)
        
        # #Print the Auxiliary LP matrices c equations
        # print("Auxiliary LP:")
        # self.auxiliary_lp.print_matrices()
        # self.auxiliary_lp.print_equations()

        #Run Phase 1 of the Simplex method
        self.solution, self.objective_value = self.phase_1(self.auxiliary_lp)       


    def phase_1(self, auxiliary_lp):
        """
        Implement Phase 1 of the Simplex method.

        Returns:
        - None
        """

        print("We will now proceed to Phase 1 of the Two-Phase Simplex Method.")
        print("Our first step is to construct and solve the Auxiliary LP construction for the given LP. \n")
        
   
        print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
        print(">>                                       <<")
        print(">>             Phase 1 - Simplex         <<")
        print(">>                                       <<")
        print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n")
            
        # Initialize the Simplex solver for the Auxiliary LP

        # Use the initial basis indices for the Auxiliary LP
        basis = self.initial_basis_indices
        print("Inital Basis : ", basis)  

        # The initial solution for the Auxiliary LP is to set all non-auxiliary variables to zero and set the auxiliary variables to the right-hand side values from the constraints (b).
        # So, since the auxiliary variables are at the end of the solution vector, we set the original variables to zero and the auxiliary variables to the right-hand side values with the appropriate dimensions
        solution = np.zeros((auxiliary_lp.A.shape[1], 1))
        solution[-auxiliary_lp.basis_size:] = auxiliary_lp.b
        # Format the solution for neater printing
        formatted_solution = ", ".join(
            f"x{i+1} = {solution[i, 0]:.2f}" for i in range(solution.shape[0])
        )
        print("Initial Solution: ", formatted_solution)



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
        # Before constructing the Auxiliary LP, we need to ensure that the original LP has non-negative right-hand side values.
        # If any right-hand side value is negative, we multiply the corresponding constraint by -1 to make it non-negative.
        for i in range(len(original_b)):
            if original_b[i] < 0:
                original_A[i] = -original_A[i]
                original_b[i] = -original_b[i]


        # Define the Auxiliary LP:
        # - Augment the constraint matrix A with an identity matrix to include auxiliary variables.
        # - Set the objective function c to minimize the sum of the auxiliary variables.
        # - The right-hand side vector b remains the same as the original LP.
        # - The objective type is set to 'min' to find a feasible solution. For input to Simplex, we will convert it to 'max', and negate the objective function.
        # - The signs of the constraints remain unchanged.
        # - ensure that the constraint right hand side (b) is always non-negative, if negative then multiply the corresponding constraint with -1
        auxiliary_lp = Program()
        auxiliary_lp.A = np.hstack((original_A, np.eye(original_A.shape[0])))
        auxiliary_lp.b = np.copy(original_b)      
        auxiliary_lp.c = np.vstack((np.zeros((original_A.shape[1], 1)), np.ones((original_basis_size, 1))))
        auxiliary_lp.c = -auxiliary_lp.c
        # We must also rewrite the objective function to be in canonical form for the given basis. This can simply be done by adding the objective function and the relevant constraints element wise, along with the sum of negation of b vector recorded as the constant term.
        # So c = sum(c, A1, A2, A3, ..., An)
        auxiliary_lp.c = auxiliary_lp.c + np.sum(auxiliary_lp.A, axis=0).reshape(-1, 1)
        auxiliary_lp.constant_term = -np.sum(auxiliary_lp.b)      
        auxiliary_lp.objective_type = 'max'
        auxiliary_lp.signs = original_signs
        auxiliary_lp.calculate_basis_size()

        # Calculate the initial basis indices for the Auxiliary LP
        initial_basis_indices = np.arange(original_A.shape[1], original_A.shape[1] + original_basis_size)

        return auxiliary_lp , initial_basis_indices