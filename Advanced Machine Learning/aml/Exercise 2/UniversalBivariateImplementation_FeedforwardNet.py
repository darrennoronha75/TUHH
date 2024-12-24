import numpy as np
from feedforward_skel import FeedforwardNet

# Define the network architecture
layers = [2,4,3]

# Create an instance of the FeedforwardNet
network = FeedforwardNet(layers)

# Create some new weights and biases for the first layer
new_weights = np.array([[-1,-1],[-1,1],[1,-1],[1,1]])
new_biases = np.array([[1],[0],[0],[-1]])

# Set the weights and biases for the first layer (index 0)
network.set_weights(new_weights, 0)
network.set_bias(new_biases, 0)

# Create some new weights and biases for the second layer
new_weights = np.array([[0,0,0,1],[0,1,1,1],[0,1,1,0]])
new_biases = np.array([[0],[0],[0]])

network.set_weights(new_weights, 1)
network.set_bias(new_biases, 1)

# Create some test input data - Test Case 1
test_input = np.array([[1],[1]])
# Call the network with the test input
output = network(test_input)
print(output)

# Create some test input data - Test Case 1
test_input = np.array([[0],[0]])
# Call the network with the test input
output = network(test_input)
print(output)
