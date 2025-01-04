"""Implementation of the Modified Heaviside activation function."""

__author__ = "Jens-Peter M. Zemke, Jonas Grams"
__version__ = "1.1"

__name__ = "amllib.activations.modified_heaviside"
__package__ = "amllib.activations"

import numpy as np

from .activation import Activation

class ModifiedHeaviside(Activation):
    """
    Class representation of the Modified Heaviside activation function.

    This class represents the Modified Heaviside activation function
    $$
    H(x) = \\begin{cases} 
    0 & \\text{if } x < 0 \\\\
    \\frac{1}{2} & \\text{if } x = 0 \\\\
    1 & \\text{if } x > 0 
    \\end{cases}.
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
        Initialize the Modified Heaviside activation function.
        """
        super().__init__()
        self.name = 'Modified Heaviside'
        self.data = None

    def __call__(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Modified Heaviside activation function.

        This method applies the Modified Heaviside activation function
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
        
        return np.where(x > 0, 1, np.where(x < 0, 0, 0.5))

    def derive(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the derivative of the Modified Heaviside activation function.

        This method applies the derivative of the Modified Heaviside function
        componentwise to an array.

        **Note**: The Heaviside function is not differentiable at `x = 0`.
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
        Apply the Modified Heaviside activation function.

        This method applies the Modified Heaviside function
        componentwise to an array. Data is cached
        for later backpropagation.

        Parameters
        ----------
        x : np.ndarray
            Input array of arbitrary shape and dimension.

        Returns
        -------
        np.ndarray
            Output array, has the same shape as the input `x`.
        """

        self.data = x
        return np.where(x > 0, 1, np.where(x < 0, 0, 0.5))

    def backprop(self, delta: np.ndarray) -> np.ndarray:
        """
        Apply the derivative of the Modified Heaviside function and
        multiply the result with the input.

        This method applies the derivative of the Modified Heaviside
        function componentwise to the last input of the `feedforward`
        method. The result is then multiplied with the input.

        **Note**: The Heaviside function is not differentiable at `x = 0`.
        For practical purposes, the derivative at `x = 0` can be set to 0.

        Parameters
        ----------
        delta : np.ndarray
            Input array of arbitrary shape and dimension.

        Returns
        -------
        np.ndarray
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

        return np.zeros_like(delta)