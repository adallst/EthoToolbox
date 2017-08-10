ETable
======
_Tablular data management for EthoToolbox_

Objective
---------
The ETable functions aim to provide a lightweight suite of tools for working
with tabular data in a variety of data structures.

Rationale
---------
Until circa R2017a, Matlab had no built-in best-choice datatype for storing
tabular data (like R's data.frame type). Consequently, tabular data is best
represented in a variety of data structures depending on what functions will be
used, what toolboxes, what kinds of analyses will be run, etc. Converting data
from one structure to another (e.g., struct with parallel array fields, cell
array of parallel arrays, or 2D cell array) is repetitive and can end up
requiring dozens or hundreds of lines of code in some cases, meaning tedious
labor and numerous opportunities for bugs to arise.

The functions here aim to obviate this need by providing a lightweight,
content-agnostic set of functions for converting tabular data between various
common Matlab data structures, and additionally providing better tools for
reading and writing common tabular data formats (e.g., CSV).

Approach
--------
The ETable functions can work with the following data structures for tabular
data:

* _cellarray_
    * An R-by-C `cell` array accessed as `table{r,c}`
* _columns_
    * A C-by-1 `cell` array accessed as `table{c}{r}`
* _struct_
    * A scalar `struct` accessed as `table.(fields{c})(r,:)`

Any Matlab variable that adheres to one of these formats can be used with the
ETable functions, and converted amongst them using `ETableConvert`.
