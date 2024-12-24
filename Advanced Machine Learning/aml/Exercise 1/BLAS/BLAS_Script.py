import numpy as np
import time

# Print the configuration of NumPy - Commented out for GitHub
# np.__config__.show()

# Taking Input n, k from User
n = int(input("Enter the value of n: "))
k = int(input("Enter the value of k: "))

# Randomize matrices A and B
A = np.random.rand(n, k)
B = np.random.rand(k, n)

# Level 1 BLAS: Vector-vector multiplication
# We will perform vector-vector multiplication for each column of A, B
start_time = time.time()
C_level1 = np.zeros((n, n))
for i in range(n):
    for j in range(n):
        C_level1[i, j] = A[i, :] @ B[:,j]
time_level1 = time.time() - start_time

# Level 2 BLAS: Matrix-vector multiplication
# We will perform matrix-vector multiplication for each column of B
start_time = time.time()
C_level2 = np.zeros((n, n))
for i in range(n):
    C_level2[:, i] = A @ B[:, i]
end_time = time.time()
time_level2 = end_time - start_time

# Level 3 BLAS: Matrix-matrix multiplication using @ operator
start_time = time.time()
C_level3 = A @ B
end_time = time.time()
time_level3 = end_time - start_time

# Print the results
print("Matrix A:")
print(A)
print("\nMatrix B:")
print(B)

# print("\nProduct using Level 1 BLAS (Vector-Vector Multiplication):")
# print(C_level1)
print("\nTime taken for Level 1 BLAS: {:.6f} seconds".format(time_level1))
# print("\nProduct using Level 2 BLAS (Matrix-Vector Multiplication):")
# print(C_level2)
print("\nTime taken for Level 2 BLAS: {:.6f} seconds".format(time_level2))
# print("\nProduct using Level 3 BLAS (Matrix-Matrix Multiplication):")
# print(C_level3)
print("\nTime taken for Level 3 BLAS: {:.6f} seconds".format(time_level3))