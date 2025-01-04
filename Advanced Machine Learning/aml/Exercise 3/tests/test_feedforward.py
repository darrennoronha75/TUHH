import importlib
import importlib.resources
import numpy as np

from amllib.activations import ReLU
from amllib.networks import FeedforwardNet
from amllib.utils import mnist

if __name__ == '__main__':

    # load and scale MNIST data
    x_train, y_train, x_test, y_test = mnist.load_data()

    # flatten 3-tensors to matrices
    x_train = mnist.flatten_input(x_train)
    x_test = mnist.flatten_input(x_test)

    # one-hot encode labels
    labels = mnist.encode_labels(y_train)

    ####################################################
    # TODO: Set up a single hidden layer feedforward   #
    # neural network with 100 hidden neurons based on  #
    # the ReLU activation function in all layers for   #
    # the MNIST dataset and train it with the .train   #
    # method. Try a batch size of 10 for 10 epochs and #
    # a learning rate of 0.02. With these parameters   #
    # you should reach an accuracy above 70%. Try more #
    # than once, the weights are initialized randomly. #
    ####################################################
    model = None

    y_tilde = np.argmax(model(x_test.T), axis=0)
    accuracy = np.sum(y_tilde == y_test) / 10000
    print(f'Accuracy: {accuracy * 100}%')
