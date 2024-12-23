import numpy as np

"""Solution to exercise 4 of exercise sheet 1"""

class ReLU:

    """Implementation of the ReLU activation function."""

    def __init__(self):

        self.name = 'ReLU'

    def __call__(self, x: np.ndarray):

        return x.clip(min=0)


if __name__ == '__main__':

    fun = ReLU()
    x = np.arange(-5, 6, dtype=float)

    print(x)
    print(fun(x))
    """
    Expected output:
    >>> [-5. -4. -3. -2. -1.  0.  1.  2.  3.  4.  5.]
    >>> [0. 0. 0. 0. 0. 0. 1. 2. 3. 4. 5.]
    """
