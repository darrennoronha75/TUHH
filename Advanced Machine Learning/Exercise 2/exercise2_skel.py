"""MNIST FNN with Tensorflow"""

import numpy as np
import matplotlib.pyplot as plt
import tensorflow as tf
from typing import Optional
from numpy.typing import ArrayLike
from matplotlib.gridspec import GridSpec

def load_mnist_tf() -> tuple[tuple[ArrayLike, ArrayLike],
                             tuple[ArrayLike, ArrayLike]]:
    """
    Load the MNIST dataset and preprocess the data.

    
    The MNIST dataset is loaded from `tensorflow` and
    then gets preprocessed. The training labels are
    one-hot encoded, and the input data is reshaped
    from shape (60000, 28, 28) to (60000, 784) and
    (10000, 28, 28) to (10000, 784), respectively.

    Returns
    -------
    x_train: ArrayLike
        Training dataset, reshaped to (60000, 784)
    y_train: ArrayLike
        Training labels one-hot encoded.
    x_test: ArrayLike
        Test dataset, reshaped to (10000, 784)
    y_test: ArrayLike
        Test labels of shape (10000,)
    """

    (x_train, y_train), (x_test, y_test) =\
      tf.keras.datasets.mnist.load_data()

    # Reshape and scale input data
    x_train = np.reshape(x_train, (-1, 28 * 28)) / 255.0
    x_test = np.reshape(x_test, (-1, 28 * 28)) / 255.0

    # One-hot-encode training labels
    y_train = tf.keras.utils.to_categorical(y_train)

    return (x_train, y_train), (x_test, y_test)

def get_model(
    hidden_neurons: int, activation: str,
    output_activation: str) -> tf.keras.Sequential:
    """
    Generate a FNN for the MNIST dataset.

    A FNN with one hidden layer is generated. The
    activation function and the number of neurons
    of the hidden layer are given as arguments.

    Parameters
    ----------
    hidden_neurons : int
        Number of neurons in the hidden layer.
    activation: str
        Activation function for the hidden layer.
        One of the following activation functions can be used:
        - 'relu': The ReLU activation function
        - 'linear': The linear identity activation function
        - 'sigmoid': The logistic function
        - 'tanh': The TanH activation function
        - 'abs': The Abs activation function
    output_activation: str
        Activation function for the output layer. The
        usable activation function are the same as above.

    Returns
    -------
    tf.keras.Sequential
        MNIST FNN with one hidden layer.
    """
    # Overwrite activation with the Abs activation function if necessary
    if activation == 'abs':
        activation = tf.math.abs
    if output_activation == 'abs':
        output_activation = tf.math.abs

    model = tf.keras.Sequential()
    # Add the input layer. For MNIST we have 784 inputs.
    model.add(tf.keras.layers.Input(shape=(784,)))

    # Add the hidden layer.
    model.add(tf.keras.layers.Dense(hidden_neurons, activation))

    # Add the output layer of size 10.
    model.add(tf.keras.layers.Dense(10, output_activation))

    # Set the optimizer and the loss
    opt = 'adam'
    loss = 'mse'
    model.compile(opt, loss, metrics=['accuracy'])

    return model

def plot_mnist(
    inputs: ArrayLike, pred: ArrayLike,
    label: ArrayLike, file_name: Optional[str] = None
    ) -> None:
    """
    Plot evaluated MNIST data.

    All images in the inputs array are plotted,
    where the color depends on the predicted labels.
    If a predicted label equals the MNIST label,
    the image is plotted in green, otherwise it
    is plotted in red.

    Parameters
    ----------
    inputs : ArrayLike
        Collection of MNIST images as 2-dimensional array.
    pred : ArrayLike
        Array of predicted labels.
    label : ArrayLike
        Collection of MNIST labels corresponding to the input.
    file_name : Optional[str], optional
        If not None, the plot is saved as pdf file with the
        corresponding name.
    """
    ndata, _ = inputs.shape

    nrow, ncol = int(np.floor(np.sqrt(ndata))), int(np.ceil(np.sqrt(ndata)))

    gs = GridSpec(nrow, ncol, wspace=0.0,
                  hspace=0.0, top=1.-0.5 / (nrow+1),
                  bottom=0.5 / (nrow+1),
                  left=0.5 / (ncol+1),
                  right=1-0.5 / (ncol+1))

    for i in range(nrow):
        for j in range(ncol):
            n = i + j * nrow
            if n < ndata:
                ax = plt.subplot(gs[i, j])
                cmap = plt.get_cmap(
                    'Greens') if pred[n] == label[n] else plt.get_cmap('Reds')
                ax.imshow(inputs[n, :].reshape(28, 28),
                          cmap=cmap)
                ax.set_xticklabels([])
                ax.set_yticklabels([])
                plt.axis('off')

    if file_name is not None:
        plt.savefig(file_name, bbox_inches='tight', format='pdf')
    else:
        plt.show()

if __name__ == '__main__':

    """
    Train a FNN with one hidden layer on the MNIST dataset.
    """

    hidden_neurons = 100

    # Load test and training data
    (x_train, y_train), (x_test, y_test) = load_mnist_tf()

    #########################################################
    # TODO Generate the network with the get_model function #
    #########################################################
    model = None

    # Train the model. In TensorFlow/Keras the training is
    # implemented in the fit method.
    model.fit(x_train, y_train, batch_size=100, epochs=10)

    # Evaluate the model with the test data and decode the output
    y_tilde = model.predict(x_test)
    y_tilde = np.argmax(y_tilde, axis=1)

    # Compare the evaluated labels to the expected ones
    accuracy = np.sum(y_tilde == y_test) / 10000

    # Print the Test accuracy
    print(f'Test accuracy: {accuracy * 100}%')

    # Plot random chosen data depending on the predictions
    i = np.random.randint(0, 10000, 100)
    plot_mnist(x_test[i], y_tilde[i], y_test[i])
