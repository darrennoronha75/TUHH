"""
Activation function package of the neural network library
for "Advanced Machine Learning".
"""

__author__ = "Jens-Peter M. Zemke, Jonas Grams"
__version__ = "1.1"

__name__ = "amllib.activations"
__package__ = "amllib.activations"

from .activation import Activation

# Import ReLU activation function
from .relu import ReLU
from .leaky_relu import LeakyReLU
from .modified_heaviside import ModifiedHeaviside
