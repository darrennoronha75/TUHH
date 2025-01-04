"""First implementation of an FNN"""

__author__ = 'Jens-Peter M. Zemke, Jonas Grams'
__version__ = '1.1'

__name__ = 'amllib.networks.feedforward'
__package__ = 'amllib.networks'

from typing import Optional

import numpy as np
import matplotlib.pyplot as plt

from ..activations import Activation, ReLU, LeakyReLU


class FeedforwardNet:
    """
    Feedforward neural network class.

    This class is a first implementation of a
    Feedforward neural network.

    Attributes
    ----------
    layers: np.ndarray
        Array filled with the number of neurons for
        each layer.
    weights : list[np.ndarray]
        List of weight matrices of the network.
    biases : list[np.ndarray]
        List of biases of the network.
    afuns : list[Activation]
        List of activation functions for each layer.
    __z : list[np.ndarray]
        List of last computed affine linear combinations for each layer.
    __a : list[np.ndarray]
        List of last computed activations for each layer.
    """

    def __init__(self,
                 layers: list[int],
                 afun: Optional[Activation] = ReLU) -> None:
        """
        Initialize the Feedforward network.

        Parameters
        ----------
        layers : list[int]
            List of layer sizes. The first entry is the number
            of inputs of the network and the last entry is the
            number of outputs of the network.
        """
        # Initialization function for weight matrices
        wfun = (lambda m, n:
                np.random.randn(m, n) * np.sqrt(4 / (m + n)))

        # Initialize network structure
        self.layers = np.array(layers)
        self.weights = [wfun(m, n) for m, n in zip(layers[1:], layers[:-1])]
        self.biases = [np.zeros((m, 1)) for m in layers[1:]]
        self.afuns = [afun() for _ in layers[1:]]

        # set up for training
        self.__a = [None for m in layers]
        self.__z = [None for m in layers[1:]]
        self.dW = [np.zeros_like(W) for W in self.weights]
        self.db = [np.zeros_like(b) for b in self.biases]

    def __call__(self, x: np.ndarray) -> np.ndarray:
        """
        Evaluate the network.

        For each layer compute the affine linear combination
        with the corresponding weight matrix and the bias, and
        activate the result.

        Parameters
        ----------
        x : np.ndarray
            Input for the network.

        Returns
        -------
        np.ndarray
            Activated output of the last layer.
        """

        a = x

        # Iterate through each hidden layer.
        for W, b, afun in zip(self.weights, self.biases, self.afuns):
            z = W @ a + b
            a = afun(z)

        return a

    def set_weights(self, W: np.ndarray, index: int) -> None:
        """
        Set the weight matrix of a layer.

        Set the weight matrix of layer `index`.

        Parameters
        ----------
        W : np.ndarray
            Source weight matrix.
        index : int
            Index of the layer.

        Raises
        ------
        ValueError
            Raised if the index is out of bounds or the shape
            of the new weight matrix does not match the
            layer sizes.
        """
        if not index < len(self.weights):
            raise ValueError("Index out of bounds!")
        if not self.weights[index].shape == W.shape:
            raise ValueError("The shape of the new weight matrix "
                             "does not match the size of the layers. "
                             f"It should be {self.weights[index].shape}, "
                             f"but is {W.shape}.")

        self.weights[index] = W

    def set_bias(self, b: np.ndarray, index: int) -> None:
        """
        Set the bias of a layer.

        Set the bias of layer `index`.

        Parameters
        ----------
        b : np.ndarray
            Source bias.
        index : int
            Index of the layer.

        Raises
        ------
        ValueError
            Raised if the index is out of bounds or the shape
            of the new weight matrix does not match the
            layer sizes.
        """

        if not index < len(self.biases):
            raise ValueError("Index out of bounds!")
        if not self.biases[index].shape == b.shape:
            raise ValueError("The shape of the new bias "
                             "does not match the size of the layer."
                             f"It should be {self.biases[index].shape}, "
                             f"but is {b.shape}")

        self.biases[index] = b

    def feedforward(self, x: np.ndarray) -> np.ndarray:
        """
        Evaluate the network.

        For each layer compute the affine linear combination
        with the corresponding weight matrix and the bias, and
        activate the result. Data is cached for backpropagation.

        Parameters
        ----------
        x : np.ndarray
            Input for the network.

        Returns
        -------
        np.ndarray
            Activated output of the last layer.
        """

        ############################################################
        # TODO: Implement the feedforward for training.            #
        # The input / activated outputs should cached in self.__a, #
        # the affine linear combinations in self.__z.              #
        # Additionally the activation function should be called    #
        # with its feedforward method.                             #
        ############################################################

    def backprop(self, x: np.ndarray, y: np.ndarray) -> None:
        """
        Backpropagate through the FNN

        Propagate backwards through each layer and compute
        updates for the weight matrices and biases.

        Parameters
        ----------
        x : np.ndarray
            Input data.
        y : np.ndarray
            Labels for the input data.
        """
        _, k = x.shape
        delta = None

        #############################################################
        # TODO: Propagate backwards through each layer to compute   #
        # the updates for the weights and biases, and store them in #
        # self.dW and self.db, respectively.                        #
        # The array delta should contain the current \delta_i.      #
        # See the lecture notes, Thm. 2.1 for more information.     #
        #############################################################

    def update(self, learning_rate: float = 0.01) -> None:
        """
        Update the networks parameters.

        Update the parameters of the network with the
        SGD method. The updates are computed by the
        backprop method.

        Parameters
        ----------
        learning_rate : float
            Learning rate, used as scaling factor for
            the updates.
        """
        #########################################################
        # TODO: Use the data stored in self.dW and self.db to   #
        # update the weights and the biases with the GD method. #
        #########################################################

    def train(self,
              x: np.ndarray,
              y: np.ndarray,
              batch_size: int = 1,
              epochs: int = 10,
              learning_rate: float = 0.01) -> None:
        """
        Train the network.

        The network is trained with backpropagation and
        the SGD method. For whole batches the backpropagation
        is performed, after which the parameters get updated.

        Parameters
        ----------
        x : np.ndarray
            Input training data.
        y : np.ndarray
            Output for the training data.
        batch_size : int, optional
            Batch size, by default 1.
        epochs : int, optional
            Number of training epochs, by default 10.
        learning_rate : float, optional
            Learning rate, by default 0.01
        """
        n_data = x.shape[1]
        n_batches = int(np.ceil(n_data / batch_size))

        for e in range(epochs):

            #####################################################
            # TODO: Generate a random permuatation.             #
            # You can use the function permutation from numpy's #
            # random package (np.random.permutation).           #
            #####################################################
            for j in range(n_batches):

                print(f'Epoch {e+1}/{epochs}, batch {j+1}/{n_batches}',
                      end='\r')
                ##############################################
                # TODO: Use the backprop method to propagate #
                # backwards through the layers.              #
                # Use the random batch                       #
                # x[:, j * batch_size:(j+1) * batch_size]    #
                # as input data.                             #
                ##############################################

                ##############################################
                # TODO: Update all weights and biases with   #
                # the update method                          #
                ##############################################

            print(f'Epoch {e+1}/{epochs}')

    def draw(self, file_name: Optional[str] = None) -> None:
        """
        Draw the network.

        Each layer is drawn as a vertical line of circles
        representing the neurons of this layer.

        Parameters
        ----------
        file_name : str | None
            If `file_name` is not `None`, the image
            is written to a corresponding pdf file.
            Otherwise it is just displayed.
        """

        num_layers = len(self.layers)
        max_neurons_per_layer = np.amax(self.layers)
        dist = 2 * max(1, max_neurons_per_layer / num_layers)
        y_shift = self.layers / 2 - .5
        rad = .3

        fig = plt.figure(frameon=False)
        ax = fig.add_axes([0, 0, 1, 1])
        ax.axis('off')

        # Draw all circles
        for i in range(num_layers):
            for j in range(self.layers[i]):
                circle = plt.Circle((i * dist, j - y_shift[i]),
                                    radius=rad, fill=False)
                ax.add_patch(circle)

        # Draw the lines between the layers.
        for i in range(num_layers-1):
            for j in range(self.layers[i]):
                for k in range(self.layers[i+1]):
                    angle = \
                      np.arctan((j - k + y_shift[i+1] - y_shift[i]) \
                                / dist)
                    x_adjust = rad * np.cos(angle)
                    y_adjust = rad * np.sin(angle)
                    line = plt.Line2D((i * dist + x_adjust,
                                       (i+1) * dist - x_adjust),
                                      (j - y_shift[i] - y_adjust,
                                       k - y_shift[i+1] + y_adjust),
                                      lw = 2 / np.sqrt(self.layers[i]
                                                       + self.layers[i+1]),
                                      color='b')
                    ax.add_line(line)

        ax.axis('scaled')

        if file_name is None:
            plt.show()
        else:
            fig.savefig(file_name, bbox_inches='tight', format='pdf')
