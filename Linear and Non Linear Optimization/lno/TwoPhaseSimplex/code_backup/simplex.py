from program import Program
from certificate import Certificate
import numpy as np

class Simplex(Program):
    def __init__(self, lp, solution=None, basis=None):
        super().__init__()
        self.lp = lp  # The LP problem
        self.solution = solution  # Stores the feasible solution if one exists
        self.basis = basis if basis is not None else np.arange(self.lp.A.shape[0])
        self.simplex_format_initializer()  # Ensure LP is maximized if needed

    def simplex_format_initializer(self):
        """
        If given Linear Program is a Minimization Problem, make it a Maximization Problem.
        """
        if self.lp.objective_type == 'min':
            self.lp.objective_type = 'max'
            self.lp.c = -self.lp.c
            self.lp.constant_term = -self.lp.constant_term

    def solve(self):
        A, b, c = self.lp.A, self.lp.b, self.lp.c
        basis = self.basis

        while True:
            # Update LP components based on the current basis
            A, b, c = self.update_lp_components(basis)

            # Update objective value correctly using the current solution
            c_current = c.T # Select the reduced coefficient vector
            self.lp.objective_value = np.dot(c_current, self.solution)

            # Create a certificate object to check optimality
            optimality_certificate = Certificate(self.lp, self.solution)

            if optimality_certificate.check_optimality():
                print("Optimal solution confirmed.")
                break  # Optimal solution found
            else:
                print("Current solution not optimal, updating basis using Bland's rule.")
                basis = self.find_new_basis(A, b, c, basis)

        return self.solution, self.lp.objective_value
    
    def find_new_basis(self, A, b, c, basis):
        """
        Computes the new basis for the Linear Program using Bland's Rule.
        """
        # Initialize the leaving variable index as None
        leaving_variable_index = None

        # Step 1: Find the entering variable index
        c_positive = np.where((c > 0) & ~np.isin(range(len(c)), basis))[0]
        if c_positive.size == 0:
            raise ValueError("No entering variable found. LP might already be optimal.")
        entering_variable_index = c_positive[0]
        print("Entering Variable Index:", entering_variable_index)

        # Step 2: Find the leaving variable index

        # Retrieve the column of the constraint matrix corresponding to the entering variable
        A_entering = self.A[:, entering_variable_index]

        # Initialize the ratios array with infinity
        # This ensures that only valid ratios will be considered
        ratios = np.full_like(self.b, np.inf, dtype=float)

        # Calculate the ratios for each variable in the basis
        for i in range(len(self.basis)):
            if A_entering[i] > 0:  # Only consider positive entries in A_entering
                ratios[i] = self.b[i] / A_entering[i]

        # Find the index of the minimum ratio
        # This corresponds to the leaving variable
        leaving_variable_index = np.argmin(ratios)
        
        # If the minimum ratio is infinity, the LP is unbounded
        # Create a certificate object to check unboundedness
        if np.isinf(ratios[leaving_variable_index]):
            unbounded_certificate = Certificate(self.lp, self.solution, x_bar=A_entering, r=ratios)
            unbounded_certificate.certify_unboundedness()
            raise ValueError("LP is unbounded: the objective value can grow indefinitely.")
        
        # Update the basis
        basis[leaving_variable_index] = entering_variable_index
        
        return basis


    def update_lp_components(self, basis):
        """
        Update LP components (A, b, c) based on the new basis.
        """
        c_current, A_current, b_current, constant_term, signs = (
            self.lp.c,
            self.lp.A,
            self.lp.b,
            self.lp.constant_term,
            self.lp.signs,
        )
        basis_current = self.basis

        # Construct Basic Sub-Matrix for A_current as per variables present in the basis
        A_current_basis = np.zeros((A_current.shape[0], len(basis_current)))
        for i in range(len(basis_current)):
            A_current_basis[:, i] = A_current[:, basis_current[i]]

        c_current_basis = np.zeros(len(basis_current))
        for i in range(len(basis_current)):
            c_current_basis[i] = c_current[int(basis_current[i])]

        # Part 1: Rewriting the Objective Function
        y = np.linalg.solve(A_current_basis.T, c_current_basis)
        c_rewritten = c_current.T - np.dot(y.T, A_current)
        constant_term += np.dot(y.T, b_current).item()

        # Part 2: Rewriting the Constraints
        A_rewritten = np.linalg.solve(A_current_basis, A_current)
        b_rewritten = np.linalg.solve(A_current_basis, b_current)

        # Update LP directly
        self.lp.c = c_rewritten.T  # Transpose back to column vector
        self.lp.A = A_rewritten
        self.lp.b = b_rewritten
        self.lp.constant_term = constant_term
        self.lp.signs = signs

        # Print updated LP using the `print_equations` method
        print("\nCanonical Form at this step is given below:")
        self.lp.print_equations()  # Display updated LP

        return self.lp.A, self.lp.b, self.lp.c
