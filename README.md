
# Does the Small Business Program Benefit Self-Employed Workers? Evidence from Nicaragua

Authors: Booyuel Kim, Rony Rodríguez-Ramírez, and Hee-Seung Yang

This readme file contains general instructions on what these codes do,
and their sequence. All codes are written in Stata. You will need to
install the necessary Stata commands (see the STATA master file).

# Data folders structure

The data folder contains two subfolders: (1) raw and (2) intermediate.
The raw data folder contains three datasets, each located in different
folders. These are 2005, 2009, and 2014. The datasets used in this paper
are the Living Standards Measurement Study (LSMS). The intermediate
folder contains the datasets after cleaning and construction. The folder
structure is as follows:

    |-data            <- main data folder
    | |-raw           <- raw data
    |   |-2005
    |   |-2009
    |   |-2014
    | |-intermediate  <- intermediate data

# Codes folders structure

There is one main folder that contains all the Stata codes, and its
structure is as follows:

    |-dofiles         <- main dofiles folder
    | |-analysis      <- analysis
    | |-cleaning      <- cleaning
    | |-construct     <- construct
    | |-programs      <- programs
    |-0_main.do

## Main do file

The `0_main.do` do file sets the file paths, installs the required
commands, and runs all the dofiles. The order of execution is described
in the main do file. I recommend you to turn on all the execution
globals first in order to replicate all the tables. You can always turn
them off and execute each part separately. You will only need to change
the root project folder. Each of the do files contain an outline that
describes what the do files creates, modifies, or executes. The
subfolders contain the following dofiles:

    |-analysis
    | |-01_analysis.do
    |-cleaning
    | |-00_cuaen_codes.do
    | |-01_emnv_2005_population.do
    | |-02_emnv_2009_population.do
    | |-03_emnv_2014_population.do
    | |-04_append_datasets.do
    |-construct
    | |-01_construct.do
    |-programs
    | |-packages.do
    | |-tvsc.do

## Programs

There are two programs to be installed. The first one, `packages`, helps
us install all the commands that are user written that are needed to
create new variabels and export outcomes. The second one, `tvsc`,
creates an easy-to-read comparison between two groups and export the
results to TeX format.

## Order of execution

The order of execution of the do files is:

    1. packages.do
    2. tvsc.do
    3. 01_emnv_2005_population.do
    4. 02_emnv_2009_population.do
    5. 03_emnv_2014_population.do
    6. 04_append_datasets.do
    7. 01_construct.do
    8. 01_analysis.do

Keep in mind that this is all done by the main do file, and you won’t
need to run each of these do files individually.

## Software requirements

All coders were last run using Stata version:

    . version
    version 16.1

Commands version:

    . which esttab
    *! version 2.0.9

    . which winsor2
    *! 1.1 2014.12.16

    . which psmatch2
    *! version 4.0.12

    . which reghdfe
    *! version 5.7.3

    . which ietoolkit
    *! version 6.3 

# LaTeX

In order to compile all the `tex` files properly, you should run the
main file called `data_analysis.tex` after running all Stata codes. This
`tex` file will call each of the chapters of the paper. You can use
either `PDFLaTeX` or `XeLaTeX` to compile the paper. We recommend using
the following recipe: pdflatex → bibtex → pdflatex → pdflatex
