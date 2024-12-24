"""Implementation of the Scaled Tanh activation function."""

__author__ = "Jens-Peter M. Zemke, Jonas Grams"
__version__ = "1.1"

__name__ = "amllib.activations.scaled_tanh"
__package__ = "amllib.activations"

import numpy as np

from .activation import Activation

class ScaledTanh(Activation):
    """
    Class representation of the Scaled Tanh activation function.

    This class represents the Scaled Tanh activation function
    $$
    \\tanh_k(x) = k \\tanh(x)
    $$

    Attributes
    ----------
    data: np.ndarray
        Cached data from the `feedforward` method.
    name: str
        Name of the activation function.
    k: float
        Scaling parameter for the output.
    """

    def __init__(self, k: float = 1.0):
        """
        Initialize the Scaled Tanh activation function.

        Parameters
        ----------
        k : float, optional
            Scaling parameter for the output (default is 1.0).
        """
        super().__init__()
        self.name = 'Scaled Tanh'
        self.k = k
        self.data = None

    def __call__(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Scaled Tanh activation function.

        This method applies the Scaled Tanh activation function
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
        return self.k * np.tanh(x)

    def derive(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the derivative of the Scaled Tanh activation function.

        This method applies the derivative of the Scaled Tanh function
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
        return self.k * (1 - np.tanh(x) ** 2)

    def feedforward(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Scaled Tanh activation function and cache the data.

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
        Apply the derivative of the Scaled Tanh function and multiply with the input.

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