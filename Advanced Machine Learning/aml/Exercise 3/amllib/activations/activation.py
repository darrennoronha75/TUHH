"""Module containing an abstract base class for activation functions."""

__author__ = "Jens-Peter M. Zemke, Jonas Grams"
__version__ = "1.1"

__name__ = "amllib.activations.activation"
__package__ = "amllib.activations"

from abc import ABCMeta, abstractmethod
import numpy as np

class Activation(metaclass=ABCMeta):
    """
    Abstract base class for Activation functions.

    This abstract base class provides the required methods
    for activation functions. All activation functions have to
    provide the methods of this class.

    Notes
    -----
    This class can be used for implementing new activation function.
    Through this class all activation functions share a common type.
    Therefore this class can be used for type hints whenever an activation
    function is expected.

    Attributes
    ----------
    data: np.ndarray
        Cached data from the feedforward method.
    name: str
        Name of the activation function.
    """
    data: np.ndarray
    name: str

    @abstractmethod
    def __call__(self, x: np.ndarray) -> np.ndarray:
        """
        Evaluation of the activation function.

        This method applies the activation function
        to an input arry. It is expected to be implemented by any
        sub class implementing an activation function.

        Parameters
        ----------
        x : np.ndarray
            Input array.

        Returns
        -------
        np.ndarray
            Activated output.
        """
        pass

    @abstractmethod
    def derive(self, x: np.ndarray) -> np.ndarray:
        """
        Evaluate the derivative of the activation function.

        This method applies the derivative of the activation function
        to an input array. It is expected to be implemented by any
        sub class implementing an activation function. This method
        is needed for backpropagation.

        Parameters
        ----------
        x : np.ndarray
            Input array.

        Returns
        -------
        np.ndarray
            Output array, derivative applied to the input array.
        """
        pass

    @abstractmethod
    def feedforward(self, x: np.ndarray) -> np.ndarray:
        """
        Evaluation of the activation function.

        This method applies the activation function
        to an input arry. It is expected to be implemented by any
        sub class implementing an activation function.
        In contrast to the **__call__** method, data is cached
        for the computation of the derivative.

        Parameters
        ----------
        x : np.ndarray
            Input array.

        Returns
        -------
        np.ndarray
            Activated output.
        """
        pass

    @abstractmethod
    def backprop(self, delta: np.ndarray) -> np.ndarray:
        """
        Evaluate the derivative of the activation function, and multiply
        it with the input.

        This method applies the derivative of the activation function
        to the last input of the `feedforward` method, and then multiplies
        the result with the input. It is expected to be implemented by any
        sub class implementing an activation function.

        Parameters
        ----------
        delta : np.ndarray
            Input array.

        Returns
        -------
        np.ndarray
            Output array, derivative applied to the input array.
        """
        pass

