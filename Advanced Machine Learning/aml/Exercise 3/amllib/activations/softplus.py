"""Implementation of the Softplus activation function."""

__author__ = "Jens-Peter M. Zemke, Jonas Grams"
__version__ = "1.1"

__name__ = "amllib.activations.softplus"
__package__ = "amllib.activations"

import numpy as np

from .activation import Activation

class Softplus(Activation):
    """
    Class representation of the Softplus activation function.

    This class represents the Softplus activation function
    $$
    \\text{Softplus}(x) = \\log(1 + e^x)
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
        Initialize the Softplus activation function.
        """
        super().__init__()
        self.name = 'Softplus'
        self.data = None

    def __call__(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Softplus activation function.

        This method applies the Softplus activation function
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
        return np.log1p(np.exp(x))

    def derive(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the derivative of the Softplus activation function.

        This method applies the derivative of the Softplus function
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

    def feedforward(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Softplus activation function and cache the data.

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
        Apply the derivative of the Softplus function and multiply with the input.

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