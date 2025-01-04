"""Implementation of the Scaled Logistic (Sigmoid) activation function."""

__author__ = "Jens-Peter M. Zemke, Jonas Grams"
__version__ = "1.1"

__name__ = "amllib.activations.scaled_logistic"
__package__ = "amllib.activations"

import numpy as np

from .activation import Activation

class ScaledLogistic(Activation):
    """
    Class representation of the Scaled Logistic (Sigmoid) activation function.

    This class represents the Scaled Logistic (Sigmoid) activation function
    $$
    \\sigma_k(x) = \\frac{1}{1 + e^{-kx}}
    $$

    Attributes
    ----------
    data: np.ndarray
        Cached data from the `feedforward` method.
    name: str
        Name of the activation function.
    k: float
        Scaling parameter for the input.
    """

    def __init__(self, k: float = 1.0):
        """
        Initialize the Scaled Logistic activation function.

        Parameters
        ----------
        k : float, optional
            Scaling parameter for the input (default is 1.0).
        """
        super().__init__()
        self.name = 'Scaled Logistic'
        self.k = k
        self.data = None

    def __call__(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Scaled Logistic activation function.

        This method applies the Scaled Logistic activation function
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
        return 1 / (1 + np.exp(-self.k * x))

    def derive(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the derivative of the Scaled Logistic activation function.

        This method applies the derivative of the Scaled Logistic function
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
        return self.k * sigmoid * (1 - sigmoid)

    def feedforward(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Scaled Logistic activation function and cache the data.

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
        Apply the derivative of the Scaled Logistic function and multiply with the input.

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