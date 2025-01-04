"""Implementation of the Leaky ReLU activation function."""

__author__ = "Jens-Peter M. Zemke, Jonas Grams"
__version__ = "1.1"

__name__ = "amllib.activations.relu"
__package__ = "amllib.activations"

import numpy as np

from .activation import Activation

class LeakyReLU(Activation):
    """
    Class representation of the Leaky ReLU activation function.

    This class represents the Leaky ReLU activation function
    $$
    \\text{ReLU}(x) = \\begin{cases}x, \\quad
    x \\geq 0 \\\\ 0, \\quad x < 0 \\end{cases}.
    $$

    Attributes
    ----------
    data: np.ndarray
        Cached data from the `feedforward` method.
    name: str
        Name of the activation function.
    factor: float
        Scaling factor for weight initialization. This factor is shared
        by all ReLU like activation functions. It is set to $\\sqrt{2}$.
    """

    def __init__(self, alpha: float = 0.01):
        """
        Initialize the ReLU activation function.
        """
        super().__init__()
        self.name = 'Leaky ReLU'
        self.alpha = alpha
        self.data = None

    def __call__(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the Leaky ReLU activation function.

        This method applies the ReLU activation function
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

        return np.where(x >= 0, x, self.alpha * x)

    def derive(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the derivative of the ReLU activation function.

        This method applies the derivative of the ReLU function
        componentwise to an array.

        **Note**: Since the ReLU function is not differentiable
        in `x = 0`, a weak derivative is used here. The point `0` is
        evaluated to 1.

        Parameters
        ----------
        x : np.ndarray
            Input array of arbitrary shape and dimension.

        Returns
        -------
        np.ndarray:
            Output array, has the same shape as the input `x`.
        """
        return np.where(x >= 0, 1 , self.alpha)

    def feedforward(self, x: np.ndarray) -> np.ndarray:
        """
        Apply the ReLU activation function.

        This method applies the ReLU function
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
        return np.where(x >= 0, x, self.alpha * x)

    def backprop(self, delta: np.ndarray) -> np.ndarray:
        """
        Apply the derivative of the ReLU function and
        multiply the result with the input.

        This method applies the derivative of the ReLU
        function componentwise to the last input of the
        `feedforward` method. The result is then multiplied
        with the input.

        **Note**: Since the ReLU function is not differentiable
        in `x = 0`, a weak derivative is used here. The point
        `0` is evaluated to `1`.

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

        return np.where(self.data >= 0, 1, self.alpha) * delta
