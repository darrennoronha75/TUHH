"""Implementation of the Swish activation function."""

__author__ = "Jens-Peter M. Zemke, Jonas Grams"
__version__ = "1.1"

__name__ = "amllib.activations.swish"
__package__ = "amllib.activations"

import numpy as np

from .activation import Activation

class Swish(Activation):
    """
    Class representation of the Swish activation function.

    This class represents the Swish activation function
    $$
    \\text{Swish}(x) = x \\cdot \\sigma(x)
    $$
    where \\( \\sigma(x) \\) is the logistic sigmoid function.

    Attributes
    ----------
    data: np.ndarray
        Cached data from the `feedforward` method.
    name: str
        Name of the activation function.
    beta: float
        Scaling parameter for the input.
    """

    def __init__(self, beta: float = 1.0):
        """
        Initialize the Swish activation function.

        Parameters
        ----------
        beta : float, optional
            Scaling parameter for the input (default is 1.0).
        """
        super().__init__()
        self.name = 'Swish'
        self.beta = beta
        self.data = None

    def __call__(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Swish activation function.

        This method applies the Swish activation function
        componentwise to an array.

        Parameters
        ----------
        x : np.ndarray
            Input array of arbitrary shape and dimension.

        Returns
        -------
        np.ndarray:
            Output array, has the same shape as the input `x`.
        """
        self.data = x
        return x / (1 + np.exp(-self.beta * x))

    def derive(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the derivative of the Swish activation function.

        This method applies the derivative of the Swish function
        componentwise to an array.

        Parameters
        ----------
        x : np.ndarray
            Input array of arbitrary shape and dimension.

        Returns
        -------
        np.ndarray:
            Output array, has the same shape as the input `x`.
        """
        sigmoid = 1 / (1 + np.exp(-self.beta * x))
        return sigmoid + self.beta * x * sigmoid * (1 - sigmoid)

    def feedforward(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Swish activation function and cache the data.

        Parameters
        ----------
        x : np.ndarray
            Input array of arbitrary shape and dimension.

        Returns
        -------
        np.ndarray:
            Output array, has the same shape as the input `x`.
        """
        self.data = self.__call__(x)
        return self.data

    def backprop(self, delta: np.ndarray) -> np.ndarray:
        """
        Apply the derivative of the Swish function and multiply with the input.

        Parameters
        ----------
        delta : np.ndarray
            Input array of arbitrary shape and dimension.

        Returns
        -------
        np.ndarray:
            Output array, has the same shape as the input `delta`.

        Raises
        ------
        ValueError
            Raised if the `feedforward` method was not called before.
        """
        if self.data is None:
            raise ValueError('The feedforward method was not'
                             'called previously. No data'
                             'for backpropagation available')

        return self.derive(self.data) * delta