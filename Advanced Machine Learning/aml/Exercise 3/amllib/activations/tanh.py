"""Implementation of the Tanh activation function."""

__author__ = "Jens-Peter M. Zemke, Jonas Grams"
__version__ = "1.1"

__name__ = "amllib.activations.tanh"
__package__ = "amllib.activations"

import numpy as np

from .activation import Activation

class Tanh(Activation):
    """
    Class representation of the Tanh activation function.

    This class represents the Tanh activation function
    $$
    \\tanh(x) = \\frac{e^x - e^{-x}}{e^x + e^{-x}}
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
        Initialize the Tanh activation function.
        """
        super().__init__()
        self.name = 'Tanh'
        self.data = None

    def __call__(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Tanh activation function.

        This method applies the Tanh activation function
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
        return np.tanh(x)

    def derive(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the derivative of the Tanh activation function.

        This method applies the derivative of the Tanh function
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
        return 1 - np.tanh(x) ** 2

    def feedforward(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Tanh activation function and cache the data.

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
        Apply the derivative of the Tanh function and multiply with the input.

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