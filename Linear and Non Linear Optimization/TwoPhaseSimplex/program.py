from numpy import np

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


    # --------- Objective Function Methods ---------

    def create_objective_function(self, variable_number):
        """
        Constructs the objective function by gathering coefficients, specifying the type (min/max), and adding a constant term.
        """
        print("\nObjective Function Setup")
        print("--------------------------")

        # Initialize coefficients as a column vector
        self.c = np.zeros((variable_number, 1))

        # Populate coefficients
        for i in range(variable_number):
            prompt = f"Enter the coefficient of x{i+1}: "
            self.c[i][0] = self.get_valid_number(prompt, number_type=float, error_message="Please enter a valid number (e.g., 2.5 or -3).")

        # Get constant term
        prompt = "Enter the constant term in the objective function: "
        self.constant_term = self.get_valid_number(prompt, number_type=float, error_message="Please enter a valid number (e.g., 2.5 or -3).")

        # Set objective type (min/max)
        self.objective_type = self.get_objective_type()

        # Construct objective expression for display
        terms = [f"{coeff:.2f}x{i+1}" for i, coeff in enumerate(self.c.flatten())]
        if self.constant_term != 0:
            terms.append(f"{self.constant_term:.2f}")
        prefix = "Minimize:" if self.objective_type == 'min' else "Maximize:"
        self.objective_expression = f"{prefix} {' + '.join(terms)}"

        # Display the objective expression
        print(self.objective_expression)

    # --------- Constraint Methods ---------

    def create_constraint_matrix(self, constraint_number, variable_number):
        """
        Constructs the constraint matrix (A), the constraint vector (b), and stores the inequality signs.
        """
        print("\nConstraint Setup")
        print("-----------------")

        # Initialize matrices and signs
        self.A = np.zeros((constraint_number, variable_number))
        self.b = np.zeros((constraint_number, 1))
        self.signs = []

        # Populate the constraint matrix, vector, and signs
        for i in range(constraint_number):
            print(f"\nConstraint {i+1}:")
            for j in range(variable_number):
                prompt = f"Enter the coefficient of x{j+1}: "
                self.A[i][j] = self.get_valid_number(prompt, number_type=float, error_message="Please enter a valid number (e.g., 2.5 or -3).")

            # Get constraint type, only allow equality constraints
            sign = self.get_valid_sign()
            if sign != '=':
                print("Only '=' constraints are allowed. Please enter '='.")
                sign = '='  # Override non-equality sign input
            self.signs.append(sign)

            # Get constant term
            prompt = "Enter the constant: "
            self.b[i][0] = self.get_valid_number(prompt, number_type=float, error_message="Please enter a valid number (e.g., 2.5 or -3).")

    # --------- Display Methods ---------

    def print_matrices(self):
        """
        Prints the constraint matrix (A) and vector (b).
        """
        print("\nConstraint Matrix A:")
        print(self.A)
        print("\nConstraint Vector b:")
        print(self.b)

    def print_equations(self):
        """
        Prints the formatted objective function and constraints, reflecting the updated coefficients and constant term.
        """
        print("\n---- Program Summary ----")

        # Display the objective function
        print("Objective Function:")
        terms = [f"{self.c[i, 0]:.2f}x{i+1}" for i in range(self.c.shape[0])]
        if self.constant_term != 0:
            terms.append(f"{self.constant_term:.2f}")
        prefix = "Minimize:" if self.objective_type == 'min' else "Maximize:"
        print(f"{prefix} {' + '.join(terms)}")

        # Display constraints
        print("\nConstraints:")
        for i in range(self.A.shape[0]):
            equation = " + ".join(f"{self.A[i][j]:.2f}x{j+1}" for j in range(self.A.shape[1]))
            print(f"{equation} {self.signs[i]} {self.b[i, 0]:.2f}")

        # Display non-negativity constraint message
        print("\nNote: All variables are constrained to be non-negative.")
        print("\n--------------------------------")
