# Import necessary libraries
import numpy as np

# Define a function that returns the affine linear combination of the input matrix and the weights plus the bias
def affine_linear_combination(x, w, b):
    e = np.ones((1,x.shape[1]))
    return w.T @ x + b.T @ e

# Define ReLU activation function
def ReLU(x):
    return np.maximum(0, x)

# Define the input matrix for AND Logical Function

# Each column represents a different input combination
x = np.array([
    [0, 0, 1, 1],
    [0, 1, 0, 1]
])

# Layer 1 (No Hidden Layer)
#--------------------------

# Define the weights and bias for the first layer
w1 = np.array([[1],
               [1]])
b1 = np.array([[-1]])

# Compute the output of the first layer
out1 = affine_linear_combination(x, w1, b1)
print(out1)

# Apply the ReLU activation function to output of the first layer
activation1 = ReLU(out1)
print(activation1)