"""Load and preprocess the MNIST dataset"""

__author__ = 'Jens-Peter M. Zemke, Jonas Grams'
__version__ = '1.1'

__name__ = 'amllib.utils.mnist'
__package__ = 'amllib.utils'

import importlib.resources

import numpy as np

from .. import utils


def load_data() -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """
    Load the MNIST dataset and preprocess the
    input data.

    The MNIST dataset is loaded, and the input
    data is preprocessed, i.e. the input data
    is scaled to the interval $[0,1]$.

    Returns
    -------
    x_train: np.ndarray
        Input training data of shape (60000, 28, 28)
    y_train: np.ndarray
        Training labels of shape (60000,)
    x_test: np.ndarray
        Input test data of shape (10000, 28, 28)
    y_test: np.ndarray
        Test labels of shape (10000,)
    """
    with importlib.resources.path(utils, 'mnist.npz') as path:
        data = np.load(path.as_posix())

    x_train = data['x_train'] / 255.0
    y_train = data['y_train']

    x_test = data['x_test'] / 255.0
    y_test = data['y_test']

    return x_train, y_train, x_test, y_test


def encode_labels(labels: np.ndarray) -> np.ndarray:
    """
    One-hot encode MNIST labels.

    Parameters
    ----------
    labels : np.ndarray
        MNIST labels.

    Returns
    -------
    np.ndarray
        One-hot encoded labels.
    """

    I = np.eye(10)
    return I[labels, :]


def flatten_input(x: np.ndarray) -> np.ndarray:
    """
    Flatten the input data to a 2-dimensional array.

    This function takes MNIST input data of shape
    (n, 28, 28) and reshapes it to (n, 784).

    Parameters
    ----------
    x : np.ndarray
        Input data of shape (n, 28, 28)

    Returns
    -------
    np.ndarray
        Flattened input data of shape (n, 784)
    """

    return x.reshape(-1, 28 * 28)
