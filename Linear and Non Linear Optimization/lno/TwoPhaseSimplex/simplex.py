from program import Program
from certificate import Certificate
import numpy as np

class Simplex(Program):
    def __init__(self, lp, solution=None, basis=None, identifier='Original LP'):
        super().__init__()
        self.lp = lp  # The LP problem
        self.solution = solution  # Stores the feasible solution if one exists
        self.basis = basis if basis is not None else np.arange(self.lp.A.shape[0])
        self.simplex_format_initializer()  # Ensure LP is maximized if needed
        self.identifier = identifier

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
        iteration_count = 0  # Initialize iteration counter

        while True:
            iteration_count += 1  # Increment iteration counter
            # print("\n-------------------------------------------")
            print("\n\n****************************")
            print(f"        ITERATION {iteration_count}")
            print("****************************\n")

            # Print current variables in the basis in the format (x1, x2, ..., xn)
            print("At start of iteration, variables in basis are : x" + ", x".join(map(str, basis + 1)) + "")
            
            # Update LP components based on the current basis
            A, b, c = self.update_lp_components(basis)

            # Update objective value correctly using the current solution
            c_current = c.T  # Select the reduced coefficient vector
            self.lp.objective_value =  np.dot(self.lp.c.T, self.solution) + self.lp.constant_term

            # Create a certificate object to check optimality
            optimality_certificate = Certificate(self.lp, self.solution)

            if optimality_certificate.check_optimality():
                print("\nOptimal solution confirmed.")
                print(f"The Simplex Algorithm has returned an optimal solution for the {self.identifier} after {iteration_count} iterations.")
                if self.identifier == "Auxiliary LP":
                    print(f"The optimal value for the Auxiliary LP is {self.lp.objective_value.item()}.")
                    print("\n-----------------------------------------------------------------------------------------------")
                else:
                    print("Algorithm stops here.")
                    print("\n-----------------------------------------------------------------------------------------------")
                break  # Optimal solution found
            else:
                print("\nCurrent solution is not optimal.")
                print("Attempting to update basis using Bland's rule.")
                basis, self.solution = self.find_new_basis(A, b, c, basis)

                # If the basis is full of -1, the LP is unbounded
                if np.all(basis == -1):
                    print("LP Unboundedness confirmed.")
                    print(f"The Simplex Algorithm has found that the {self.identifier} is unbounded after {iteration_count} iterations.")
                    print("Algorithm stops here.")
                    print("\n-----------------------------------------------------------------------------------------------")
                    break # Unbounded LP case

                print("\nAt end of iteration, variables in basis are : x" + ", x".join(map(str, basis + 1)) + "")

        # print(f"Total Iterations: {iteration_count}")
        return self.solution, self.lp.objective_value

    def find_new_basis(self, A, b, c, basis):
        """
        Computes the new basis for the Linear Program using Bland's Rule.
        """
        # Initialize the leaving variable index as None
        leaving_variable_index = None
        
        
        # Step 1: Find the entering variable index
        c_positive = np.where((c > 0) & ~np.isin(range(len(c)+1), basis))[0]
        if c_positive.size == 0:
            raise ValueError("No entering variable found. LP might already be optimal.")
        print("Basis Array contains : ", basis+1)
        print("Positive Coefficients in c: ", c_positive+1)
        entering_variable_index = c_positive[0]

        print(f"Entering Variable is set to x{entering_variable_index + 1}.")
        # Step 2: Find the leaving variable index

        # Retrieve the column of the constraint matrix corresponding to the entering variable
        A_entering = A[:, entering_variable_index]

        # Initialize the ratios array with infinity
        # This ensures that only valid ratios will be considered
        ratios = np.full_like(b, np.inf, dtype=float)
        

        # Calculate the ratios for each variable in the basis
        for i in range(len(self.basis)):
            if A_entering[i] > 0:  # Only consider positive entries in A_entering
                ratios[i] = b[i] / A_entering[i]

        # Find the index of the minimum ratio
        # This corresponds to the leaving variable
        leaving_variable_index = np.argmin(ratios)

        # If the minimum ratio is infinity, the LP is unbounded
        # Create a certificate object to check unboundedness
        if np.isinf(ratios[leaving_variable_index]):
            unbounded_certificate = Certificate(self.lp, self.solution, x_bar = self.construct_xbar(b, basis), r = self.construct_r(entering_variable_index, A_entering, basis, b) )
            print("A suitable leaving variable cannot be found at the moment.")
            if(unbounded_certificate.certify_unboundedness()):
                #Return basis full of -1 to indicate unboundedness
                return np.full(len(basis), -1), self.solution

        # We need to update the solution as well, with the minimum ratio and re-calculate the value of each variable in the feasible solution.
        # The new feasible solution will have the new entering variable and the leaving variable as non-zero values.
        # The other variables will be zero.
        new_solution = np.zeros(len(c))
        # Updating the Basis solution values as per minimum ratio calculated. There can be multiple variables in the basis.
        new_solution[entering_variable_index] = ratios[leaving_variable_index]
        # All other basis variables would be calculated as per b - ratios[leaving_variable_index] * A_entering
        for i in range(len(self.basis)):
            if i != leaving_variable_index:
                new_solution[self.basis[i]] = self.solution[self.basis[i]] - ratios[leaving_variable_index] * A[i, entering_variable_index]
        
        
        print(f"Entering Variable is set to x{entering_variable_index + 1} and Leaving Variable is set to x{basis[leaving_variable_index] + 1}.")

        # Update the basis
        basis[leaving_variable_index] = entering_variable_index

        
        return basis, new_solution

    def update_lp_components(self, basis):
        """
        Update LP components (A, b, c) to canonical form based on the new basis.
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

        # Ensure A_current_basis is square
        if A_current_basis.shape[0] != A_current_basis.shape[1]:
            raise ValueError("A_current_basis must be square. Check the basis initialization.")

        c_current_basis = np.zeros(len(basis_current))
        for i in range(len(basis_current)):
            c_current_basis[i] = c_current[int(basis_current[i])]

        # Part 1: Rewriting the Objective Function
        A_current_basis_inv = np.linalg.inv(A_current_basis)  # Calculate the inverse of the basis matrix
        y = np.dot(A_current_basis_inv.T, c_current_basis)

        c_rewritten = c_current.T - np.dot(y.T, A_current)
        constant_term += np.dot(y.T, b_current).item()

        # Part 2: Rewriting the Constraints
        A_rewritten = np.dot(A_current_basis_inv, A_current)
        b_rewritten = np.dot(A_current_basis_inv, b_current)

        # Update LP directly
        self.lp.c = c_rewritten.T  # Transpose back to column vector
        self.lp.A = A_rewritten
        self.lp.b = b_rewritten
        self.lp.constant_term = constant_term
        self.lp.signs = signs

        # Print updated LP using the `print_equations` method
        print(f"Rewriting {self.identifier} to canonical form for new basis, \n")
        self.lp.print_equations()  # Display updated LP

        return self.lp.A, self.lp.b, self.lp.c
    
    def construct_xbar(self, b, basis):
        """
        Construct the x_bar vector for the Certificate object
        It must be possible to perform dot product with A matrix.
        """
        x_bar = np.zeros(self.lp.A.shape[1])
        for i in range(len(basis)):
            x_bar[basis[i]] = b[i]
        return x_bar
    
    def construct_r(self, entering_variable_index, A_entering, basis, b):
        """
        Construct the r vector for the Certificate object.
        """
        r = np.zeros(self.lp.A.shape[1])

        # print("basis is : ", basis)
        # print("A_entering is: ", A_entering)
        # print("entering_variable_index ", entering_variable_index)
        # print("b ", b)

        # We shall construct r by mapping the basis variables to the ratios calculated.
        # The entering variable will recieve the minimum value in b, and the other basis variables will be assigned the A_entering value.
        # All other variables will be zero.
        r[entering_variable_index] = b.min()

        #As per basis indexes, we will assign the A_entering values to the basis variables.
        for i in range(len(basis)):
            # print("Checking for i: ", i)
            if basis[i] != entering_variable_index:
                r[basis[i]] = -1*A_entering[i]
                # print("r basis[i] is: ", basis[i])
        
        return r