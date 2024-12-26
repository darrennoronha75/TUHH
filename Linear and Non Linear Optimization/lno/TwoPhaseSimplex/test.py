import numpy as np
from program import Program
from simplex import Simplex  # Import the Simplex class

def test_program_1():
    # Original test case data
    A = np.array([[3, 2, 1, 0], [1, 1, 0, 1]])
    b = np.array([[2], [1]])
    c = np.array([[4], [3], [0], [0]])
    signs = ['=', '=']
    objective_type = 'max'
    constant_term = 7

    # Create an instance of the Program class
    program = Program()

    # Manually set the attributes to avoid user input
    program.A = A
    program.b = b
    program.c = c
    program.signs = signs
    program.objective_type = objective_type
    program.constant_term = constant_term

    # Calculate basis size
    program.calculate_basis_size()

    # Print matrices and equations
    print("Test Case 1:")
    program.print_matrices()
    program.print_equations()
    print("\n")
    
def test_program_2():
    # New test case data
    A = np.array([[1, 1, 2, 0], [0, 1, 1, 1]])
    b = np.array([[2], [5]])
    c = np.array([[0], [1], [3], [0]])
    signs = ['=', '=']
    objective_type = 'max'
    constant_term = 0

    # Create an instance of the Program class
    program = Program()

    # Manually set the attributes to avoid user input
    program.A = A
    program.b = b
    program.c = c
    program.signs = signs
    program.objective_type = objective_type
    program.constant_term = constant_term

    # Calculate basis size
    program.calculate_basis_size()

    # Print matrices and equations
    print("Test Case 2:")
    program.print_matrices()
    program.print_equations()
    print("\n")

    # Create an instance of the Simplex class and solve the LP
    basis = np.array([0, 3])  # Initial basis
    solution = np.array([2,0,0,5])  # Initial solution
    solver = Simplex(program, basis=basis, solution=solution)
    solution, objective_value = solver.solve()
    print("Optimal solution:", solution)
    print("Objective value:", objective_value)
    print("\n")

def test_program_3():
    # New test case data
    A = np.array([[1, -2, 1, 0, 0], [0, 5, -3, 1, 0], [0, 4, -2, 0, 1]])
    b = np.array([[1], [1], [2]])
    c = np.array([[0], [-4], [3], [0], [0]])
    signs = ['=', '=', '=']
    objective_type = 'max'
    constant_term = 0

    # Create an instance of the Program class
    program = Program()

    # Manually set the attributes to avoid user input
    program.A = A
    program.b = b
    program.c = c
    program.signs = signs
    program.objective_type = objective_type
    program.constant_term = constant_term

    # Calculate basis size
    program.calculate_basis_size()

    # Print matrices and equations
    print("Test Case 3:")
    program.print_matrices()
    program.print_equations()
    print("\n")

def test_program_4():
    # New test case data
    A = np.array([[1, 3, 1, 0], [-2, 6, 0, 1]])
    b = np.array([[4], [5]])
    c = np.array([[-1], [-4], [0], [0]])
    signs = ['=', '=']
    objective_type = 'max'
    constant_term = 4

    # Create an instance of the Program class
    program = Program()

    # Manually set the attributes to avoid user input
    program.A = A
    program.b = b
    program.c = c
    program.signs = signs
    program.objective_type = objective_type
    program.constant_term = constant_term

    # Calculate basis size
    program.calculate_basis_size()

    # Print matrices and equations
    print("Test Case 4:")
    program.print_matrices()
    program.print_equations()
    print("\n")

    # Create an instance of the SimplexSolver class and solve the LP
    basis = np.array([2, 3])  # Initial basis
    solution = np.array([0, 0, 4, 5])  # Initial solution
    solver = Simplex( program, solution=solution, basis = basis)
    solution, objective_value = solver.solve()
    print("Optimal solution:", solution)
    print("Objective value:", objective_value)
    print("\n")
    
if __name__ == '__main__':
    # test_program_1()
    test_program_2()
    # test_program_3()
    test_program_4()
