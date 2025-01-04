"""Implementation of the Sign activation function."""

__author__ = "Jens-Peter M. Zemke, Jonas Grams"
__version__ = "1.1"

__name__ = "amllib.activations.sign"
__package__ = "amllib.activations"

import numpy as np

from .activation import Activation

class Sign(Activation):
    """
    Class representation of the Sign activation function.

    This class represents the Sign activation function
    $$
    \\text{Sign}(x) = \\begin{cases} 
    -1 & \\text{if } x < 0 \\\\
    0 & \\text{if } x = 0 \\\\
    1 & \\text{if } x > 0 
    \\end{cases}
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
        Initialize the Sign activation function.
        """
        super().__init__()
        self.name = 'Sign'
        self.data = None

    def __call__(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Sign activation function.

        This method applies the Sign activation function
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
        return np.sign(x)

    def derive(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the derivative of the Sign activation function.

        This method applies the derivative of the Sign function
        componentwise to an array.

        **Note**: The Sign function is not differentiable at `x = 0`.
        For practical purposes, the derivative at `x = 0` can be set to 0.

        Parameters
        ----------
        x : np.ndarray
            Input array of arbitrary shape and dimension.

        Returns
        -------
        np.ndarray:
            Output array, has the same shape as the input `x`.
        """
        return np.zeros_like(x)

    def feedforward(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Sign activation function and cache the data.

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
        Apply the derivative of the Sign function and multiply with the input.

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