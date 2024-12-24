# Import necessary libraries
import numpy as np


# Define a function that returns the affine linear combination of the input matrix and the weights plus the bias
def affine_linear_combination(x, w, b):
    e = np.ones((1,x.shape[1]))
    return w.T @ x + b.T @ e

# Define ReLU activation function
def ReLU(x):
    return np.maximum(0, x)

# Define the input matrix for a logical bivariate function
# Each column represents a different input combination
x = np.array([
    [0, 0, 1, 1],
    [0, 1, 0, 1]
])

# Layer 1 - Universal Layer to identify Points
#----------------------------------------------

# Define the weights and bias for the first layer
w1 = np.array([[-1, -1, 1, 1],
              [-1, 1, -1, 1]])

b1 = np.array([[1, 0, 0, -1]])

# Compute the output of the first layer
out1 = affine_linear_combination(x, w1, b1)
print(out1)

# Apply the ReLU activation function to output of the first layer
activation1 = ReLU(out1)

# Print the activation of the first layer
print(activation1)

# Layer 2 - Layer to Map Points to Logical Functions
#---------------------------------------------------

# Define the weights and bias for the second layer
w2 = np.array([[0, 0, 0],
               [0, 1, 1],
               [0, 1, 1],
               [1, 1, 0]])

b2 = np.array([[0, 0, 0]])

# Compute the output of the second layer
out2 = affine_linear_combination(activation1, w2, b2)
print(out2)

# Apply the ReLU activation function to output of the second layer
activation2 = ReLU(out2)

# Print the activation of the second layer
print(activation2)
