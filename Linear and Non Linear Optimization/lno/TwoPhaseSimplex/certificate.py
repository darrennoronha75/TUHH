import numpy as np

class Certificate:
    def __init__(self, lp, solution = None, y = None , x_bar = None, r = None):
        """
        Certificate class to check optimality, infeasibility, and unboundedness.

        Parameters:
        - lp (Program): An instance of the Program class.
        - solution: The solution vector to be checked.
        """
        self.lp = lp
        self.solution = solution
        self.y = y if y is not None else np.zeros(self.lp.A.shape[0])
        self.x_bar = x_bar if x_bar is not None else np.zeros(self.lp.A.shape[1])
        self.r = r if r is not None else np.zeros(self.lp.A.shape[0])

    def check_optimality(self):
        """
        Check for optimality.

        Returns:
        - bool: True if optimal, otherwise False.
        """
        
        feasible_solution = self.solution.flatten()  # Ensure feasible_solution is a 1D array

        # Print current variables in the solution in the format (x1 = val1, x2 = val2, ..., xn = valn)
        solution_str = ", ".join(f"x{i+1} = {feasible_solution[i]:.2f}" for i in range(len(feasible_solution)))
        print(f"\nCurrent Solution : ({solution_str})")
        # Print the solution in vector form with aligned values
        vector_form = "[" + " ".join(f"{val:8.2f}" for val in feasible_solution) + " ]"
        print("In Vector Form:", vector_form)
        
        current_objective_value = np.dot(self.lp.c.T, feasible_solution) + self.lp.constant_term
        print("Current Objective Value: ", current_objective_value)

        print("\nChecking Optimality of the current solution...")
        
        optimality_flag = False

        if np.all(self.lp.c <= 0):
            optimality_flag = True
            constant_term = self.lp.constant_term
            # print("Optimal Solution Value is ", constant_term)
        
        return optimality_flag

    # We verify infeasibility using Farkas' Lemma. We check if the provided 'y' satisfies the conditions of Farkas' Lemma.
    def certify_infeasibility(self):
        """
        Check for infeasibility.

        Returns:
        - bool: True if infeasible, otherwise False.
        """
        print("\nChecking Infeasibility of the current solution...")
        y = self.y
        infeasibility_flag = False

        # Check if the provided 'y' satisfies the conditions of Farkas' Lemma
        if np.all(np.dot(self.lp.A.T, y) >= 0) and np.dot(self.lp.b.T, y) < 0:
            infeasibility_flag = True
            print("Infeasible solution found.")        
        
    # We verify unboundedness by checking that the LP is unbounded in the direction indicated by x_bar and r.
    def certify_unboundedness(self):
        """
        Check for infeasibility.

        Returns:
        - bool: True if infeasible, otherwise False.
        """
        # Cumulatively - x¯ ≥ 0, r ≥ 0, Ax¯ = b, Ar = 0 and cTr > 0 must all hold.
        print("\nChecking Unboundedness of the current solution...")
        x_bar = self.x_bar
        r = self.r
        unboundedness_flag = False

        if np.all(x_bar >= 0) and np.all(r >= 0) and np.all(np.dot(self.lp.A, x_bar) == self.lp.b) and np.all(np.dot(self.lp.A.T, r) == 0) and np.dot(self.lp.c.T, r) > 0:
            unboundedness_flag = True
            print("LP is unbounded in the direction of x_bar and r.")
        
