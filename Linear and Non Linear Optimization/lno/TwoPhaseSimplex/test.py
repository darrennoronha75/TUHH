import numpy as np
from program import Program
from simplex_solver import Simplex_Solver  # Import the Simplex_Solver class

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

    # Create an instance of the Simplex_Solver class
    solver = Simplex_Solver(program)
    
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

    # Create an instance of the Simplex_Solver class
    solver = Simplex_Solver(program)

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
    program.verbose = False

    # Calculate basis size
    program.calculate_basis_size()
 
    # Create an instance of the Simplex_Solver class
    solver = Simplex_Solver(program)

def test_program_4():
    # New test case data
    A = np.array([[1, 3, 1, 0], [-2, 6, 0, 1]], dtype=float)
    b = np.array([[4], [5]],dtype=float)
    c = np.array([[-1], [-4], [0], [0]],dtype=float)
    signs = ['=', '=']
    objective_type = 'max'
    constant_term = 4.00

    # Create an instance of the Program class
    program = Program()

    # Manually set the attributes to avoid user input
    program.A = A
    program.b = b
    program.c = c
    program.signs = signs
    program.objective_type = objective_type
    program.constant_term = constant_term
    program.verbose = False

    # Calculate basis size
    program.calculate_basis_size()
 
    # Create an instance of the Simplex_Solver class
    solver = Simplex_Solver(program)


def test_program_5():
    # New test case data
    A = np.array([
        [1, -2, 1],
        [-1,3, -2]
    ])
    b = np.array([[2], [-3]])
    c = np.array([[1], [3], [2]])
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
    program.verbose = False

    # Calculate basis size
    program.calculate_basis_size()
 
    # Create an instance of the Simplex_Solver class
    solver = Simplex_Solver(program)
    
def test_program_6():
    # New test case data
    A = np.array([
        [2, -1, 4, -2, 1],
        [-1, 0, -3, 1, -1]
    ])
    b = np.array([[2], [1]])
    c = np.array([[-3], [-1], [1], [4], [7]])
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
    program.verbose = False

    # Calculate basis size
    program.calculate_basis_size()

    # Create an instance of the Simplex_Solver class
    solver = Simplex_Solver(program)

def test_program_7():
    # New test case data
    A = np.array([
        [-1, -1, 1, 0],
        [-2, 1, 0, 1]
    ])
    b = np.array([[2], [1]])
    c = np.array([[-1], [0], [0], [1]])
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
    program.verbose = False

    # Calculate basis size
    program.calculate_basis_size()

    # Create an instance of the Simplex_Solver class
    solver = Simplex_Solver(program)

def test_program_8():
    # New test case data
    A = np.array([
        [3, -2, -6, 7],
        [2, -1, -2, 4]
    ])
    b = np.array([[6], [2]])
    c = np.array([[3], [4], [-1], [2]])
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
    program.verbose = False

    # Calculate basis size
    program.calculate_basis_size()

    # Create an instance of the Simplex_Solver class
    solver = Simplex_Solver(program)

if __name__ == '__main__':

    #Infeasible Solution Test Cases
    # test_program_6()
    # test_program_8()    

    # Unbounded Solution Test Cases
    # test_program_3()
    # test_program_1()
    # test_program_2()
    # test_program_5()
    # test_program_7()
    

    #Optimal Solution Test Cases
    test_program_4()
    

   
