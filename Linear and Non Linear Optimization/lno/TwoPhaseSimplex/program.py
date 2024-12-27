import numpy as np

class Program:
    def __init__(self):
        # Attributes for the program
        self.c = None  # Objective function coefficients
        self.constant_term = 0  # Constant term in the objective function
        self.A = None  # Constraint matrix
        self.b = None  # Constraint vector
        self.signs = None  # Constraint inequality signs
        self.objective_type = None  # Type of objective ('min' or 'max')
        self.objective_expression = None  # Formatted objective function expression
        self.basis_size = None
        self.free_variables = []  # List of free variables
        self.objective_value = None  # Objective value at the optimal solution

        # Verbose Flag to control the verbosity of the output
        self.verbose = False

    # --------- Utility Methods ---------

    def get_positive_integer(self, prompt, number_type=int, condition=None, error_message="Invalid input."):
        """
        Repeatedly prompts the user for a valid number of the specified type and meeting the given condition.
        """
        while True:
            try:
                value = number_type(input(prompt))
                if condition and not condition(value):
                    print(error_message)
                    continue
                return value
            except ValueError:
                print(error_message)

    def get_valid_number(self, prompt, number_type=float, error_message="Invalid input."):
        """
        Prompts the user for a valid number of the specified type, allowing negative values.
        """
        while True:
            try:
                value = number_type(input(prompt))
                return value
            except ValueError:
                print(error_message)

    def get_objective_type(self):
        """
        Prompts the user to specify whether the objective is 'min' or 'max'.
        """
        while True:
            choice = input("Enter 'min' for minimization or 'max' for maximization: ").strip().lower()
            if choice in ['min', 'max']:
                return choice
            print("Invalid choice. Please enter 'min' or 'max'.")

    def get_valid_sign(self):
        """
        Prompts the user for a valid inequality sign ('<=', '>=', '=').
        """
        while True:
            sign = input("Enter the constraint type ('<=', '>=', '='): ").strip()
            if sign in ['<=', '>=', '=']:
                return sign
            print("Invalid input. Please enter one of '<=', '>=', or '='.")

    def confirm_free_variables(self, variable_number):
        """
        Prompts the user to specify the number of free variables and identify them.
        """
        print("Free variable definition is disabled.")
        self.free_variables = []

    def calculate_basis_size(self):
        """
        Calculates the size of the basis.
        """
        if self.A is not None:
            self.basis_size = self.A.shape[0]  # Basis size depends on number of constraints
        else:
            self.basis_size = 0

    # --------- Display Methods ---------

    def print_matrices(self):
        """
        Prints the constraint matrix (A) and vector (b).
        """
        # Commented out the print statements for A and b
        # print("\nConstraint Matrix A:")
        # print(self.A)
        # print("\nConstraint Vector b:")
        # print(self.b)

    def print_equations(self):
        """
        Prints the formatted objective function and constraints, reflecting the updated coefficients and constant term.
        """
        if not self.verbose:
            # print("===========================================")
            # print("||           Program Summary - Step      ||")
            # print("===========================================\n")

            
            # Display the objective function
            print("\tObjective Function:")
            terms = []
            for i in range(self.c.shape[0]):
                coefficient = self.c[i, 0]
                if coefficient != 0:
                    sign = "+" if coefficient > 0 and i != 0 else ""
                    terms.append(f"{sign}{coefficient:.2f}x{i+1}")
            if self.constant_term != 0:
                sign = "+" if self.constant_term > 0 else ""
                terms.append(f"{sign}{self.constant_term:.2f}")
            prefix = "Minimize:" if self.objective_type == 'min' else "Maximize:"
            print(f"\t{prefix} {' '.join(terms)}")

            
            
            # Display constraints
            print("\tConstraints:")
            for i in range(self.A.shape[0]):
                equation_terms = []
                for j in range(self.A.shape[1]):
                    coefficient = self.A[i][j]
                    if coefficient != 0:
                        sign = "+" if coefficient > 0 and j != 0 else ""
                        equation_terms.append(f"{sign}{coefficient:.2f}x{j+1}")
                equation = " ".join(equation_terms)
                print(f"\t{equation} {self.signs[i]} {self.b[i, 0]:.2f}")

            
            
            # Display Basis Size
            print("\tBasis Size:", self.basis_size)

            
            
            # Display non-negativity constraint message
            print("\tNote: All variables are constrained to be non-negative.")
            