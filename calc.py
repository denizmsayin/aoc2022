from sys import argv
from subprocess import run

n = int(argv[1])

step_s = 1051
h_s = 1643

step_period = 2791 - step_s
h_period = 4359 - h_s

q = (n - step_s) // step_period
rem = (n - step_s) % step_period

# print(q, rem)

qh = h_s + q * h_period

with open('io/day17/input.txt', 'r') as fp:
    proc = run(['luajit', 'day17.lua', '1', str(rem), '6039', '2'], stdin=fp, capture_output=True)
    v = int(proc.stdout.decode().strip())

# print(qh, rem, qh + v)
print(qh + v)
