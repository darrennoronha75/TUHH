"""Implementation of the Logistic (Sigmoid) activation function."""

__author__ = "Jens-Peter M. Zemke, Jonas Grams"
__version__ = "1.1"

__name__ = "amllib.activations.logistic"
__package__ = "amllib.activations"

import numpy as np

from .activation import Activation

class Logistic(Activation):
    """
    Class representation of the Logistic (Sigmoid) activation function.

    This class represents the Logistic (Sigmoid) activation function
    $$
    \\sigma(x) = \\frac{1}{1 + e^{-x}}
    $$

    Attributes
    ----------
    data: np.ndarray
        Cached data from the `feedforward` method.
    name: str
        Name of the activation function.
    """

    def __init__(self):
        """
        Initialize the Logistic activation function.
        """
        super().__init__()
        self.name = 'Logistic'
        self.data = None

    def __call__(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Logistic activation function.

        This method applies the Logistic activation function
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
        return 1 / (1 + np.exp(-x))

    def derive(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the derivative of the Logistic activation function.

        This method applies the derivative of the Logistic function
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
        sigmoid = self.__call__(x)
        return sigmoid * (1 - sigmoid)

    def feedforward(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Logistic activation function and cache the data.

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
        Apply the derivative of the Logistic function and multiply with the input.

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