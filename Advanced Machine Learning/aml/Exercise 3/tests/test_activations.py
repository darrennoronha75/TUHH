import numpy as np
import matplotlib.pyplot as plt
from amllib.activations import ReLU, LeakyReLU,ModifiedHeaviside


if __name__ == '__main__':

    # generate activation function of class ReLU
    f = ReLU()

    # evaluate activation function and derivative
    x = np.linspace(-5, 5, 1001)
    y = f(x)
    z = f.derive(x)

    # test feedfoward and backprop, should also give derivative
    a = f.feedforward(x)
    g = f.backprop(np.ones_like(x))

    # plot function and derivative
    plt.figure(figsize=(8, 6))
    plt.plot(x, y, '-', label=f"{f.name}")
    plt.plot(x, z, '--', label=f"{f.name}': derive")
    plt.plot(x, g, '-.', label=f"{f.name}': feedforward & backprop")
    plt.legend()
    plt.xlabel('x-axis')
    plt.ylabel('y-axis')
    plt.title(f'Activation function {f.name} w/ derivative')
    plt.show()

    f = LeakyReLU()

    # evaluate activation function and derivative
    x = np.linspace(-5, 5, 1001)
    y = f(x)
    z = f.derive(x)

    # test feedfoward and backprop, should also give derivative
    a = f.feedforward(x)
    g = f.backprop(np.ones_like(x))

    # plot function and derivative
    plt.figure(figsize=(8, 6))
    plt.plot(x, y, '-', label=f"{f.name}")
    plt.plot(x, z, '--', label=f"{f.name}': derive")
    plt.plot(x, g, '-.', label=f"{f.name}': feedforward & backprop")
    plt.legend()
    plt.xlabel('x-axis')
    plt.ylabel('y-axis')
    plt.title(f'Activation function {f.name} w/ derivative')
    plt.show()

    f = ModifiedHeaviside()

    # evaluate activation function and derivative
    x = np.linspace(-5, 5, 1001)
    y = f(x)
    z = f.derive(x)

    # test feedfoward and backprop, should also give derivative
    a = f.feedforward(x)
    g = f.backprop(np.ones_like(x))

    # plot function and derivative
    plt.figure(figsize=(8, 6))
    plt.plot(x, y, '-', label=f"{f.name}")
    plt.plot(x, z, '--', label=f"{f.name}': derive")
    plt.plot(x, g, '-.', label=f"{f.name}': feedforward & backprop")
    plt.legend()
    plt.xlabel('x-axis')
    plt.ylabel('y-axis')
    plt.title(f'Activation function {f.name} w/ derivative')
    plt.show()
