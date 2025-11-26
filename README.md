

# MIPS Assembly – Dynamic Bin Packing (First Fit & Best Fit)

This project implements the **Bin Packing problem** in **MIPS Assembly**, supporting both:

* **First Fit (FF)**
* **Best Fit (BF)**

The program reads floating-point item sizes from an input file, dynamically allocates memory for items and bins, applies the selected packing algorithm, and writes the results to an output file.

---

## Features

* Reads file path from user input
* Parses floating-point numbers manually
* Dynamic allocation of:

  * Items array
  * Bins array
* Implements FF and BF packing strategies
* Tracks which item goes to which bin
* Writes results to an external output file
* Includes custom implementations of:

  * `strcmp`
  * `int_to_string`
  * `strcat`

---

## Input Format

The input file should contain item sizes separated by spaces, for example:

```
0.20 0.55 0.10 0.40 0.80
```

---

## Output Format

Example lines written to the output file:

```
I1 was added to bin 1
I2 was added to bin 2
I3 was added to bin 1
minimum bins: 2
```

---

## Running the Program

1. Open MARS or QtSpim
2. Load the assembly file
3. Run the program
4. Enter the input file path
5. Choose:

   * `FF` for First Fit
   * `BF` for Best Fit
   * `Q` to quit

---

## Recommended Repository Structure

```
project1/
│── arc.asm
│── input.txt
│── output.txt
│── README.md
```

---
