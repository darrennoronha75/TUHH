import numpy as np

# Defining the callable ReLU class

class ReLU():
    
    def __init__(self):
        self.name = 'ReLU'
        pass

    def __call__(self, x):
        return np.maximum(0, x)
    
if __name__ == '__main__':
    # Define a sample input
    x = np.array([[-1, 0, 1, 2],
                  [-1, 0, -1, 2],
                  [-1, 2, 1, 2]])
    
    # Create an instance of the ReLU class
    relu = ReLU()
    
    # Apply the ReLU activation function to the input
    output = relu(x)
    
    # Print the output
    print(output)
