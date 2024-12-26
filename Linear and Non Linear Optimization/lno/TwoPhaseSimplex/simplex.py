from program import Program
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

            certificate = Certificate(self.lp, self.solution)

            if certificate.check_optimality():
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
        # Step 1: Find the entering variable index
        c_positive = np.where((c > 0) & ~np.isin(range(len(c)), basis))[0]
        if c_positive.size == 0:
            raise ValueError("No entering variable found. LP might already be optimal.")
        entering_variable_index = c_positive[0]
        print("Entering Variable Index:", entering_variable_index)

        # Step 2: Check for unboundedness
        if np.all(A[:, entering_variable_index] <= 0):
            raise ValueError("LP is unbounded: the objective value can grow indefinitely.")

        # Step 3: Find the leaving variable index
        # Initialize Leaving Index to -1
        leaving_variable_index = -1
        # For the basic variables find the ratio of b for that particular constraint equation to the entering variable constraint coefficient for that equation
        # Entering Variable Constraint Coefficients
        A_entering_variable = A[:, entering_variable_index]
        # Ratio of b to the entering variable constraint coefficients
        b_division = b / A_entering_variable

        # Ensure we only consider positive ratios
        positive_ratios = np.where(A_entering_variable > 0, b_division, np.inf)
        positive_indices = np.where(positive_ratios < np.inf)[0]

        if positive_indices.size == 0:
            raise ValueError("LP is degenerate or has issues as no positive ratio found.")

        leaving_variable_index = positive_indices[np.argmin(positive_ratios[positive_indices])]
        t_value = b_division[leaving_variable_index]

        #Using t_value, recalculate Solution Vector
        self.solution = self.update_solution(A, b, basis)

        print("Leaving Variable Index:", leaving_variable_index)

        # Step 4: Update the basis
        loc = np.where(basis == leaving_variable_index)
        if loc[0].size > 0:
            basis[loc[0][0]] = entering_variable_index
        else:
            raise ValueError("Invalid leaving variable index; cannot update basis.")

        print("Updated Basis:", basis)

        # Step 5: Update Solution Vector for new basis computed, choose the smallest ratio to calculate the updated solution which should be basic and have shape according to the number of variables for the LP



        return basis

    def update_solution(self, A, b, basis):
      # Extract the basis matrix
      B = A[:, basis]

      # Compute the values of the basic variables
      basic_solution = np.linalg.solve(B, b).flatten()  # Flatten to ensure 1D

      # Create the full solution vector, setting non-basic variables to zero
      solution = np.zeros(A.shape[1])
      solution[basis] = basic_solution

      return solution

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
