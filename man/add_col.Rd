% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/add_col.R
\name{add_col}
\alias{add_col}
\title{add_col}
\usage{
add_col(original, row_index, new_object)
}
\arguments{
\item{original}{Initial variable where the final matrix will be stored, it can be already matrix.}

\item{row_index}{Numeric index representing the col where the new line should be inserted.}

\item{new_object}{col or matrix to be inserted in the original one.}
}
\value{
The matrix with the changes done after the function was run.
}
\description{
Function that adds new cols into a matrix/vector (depending the case).
It works simulating the behavior of a matrix in Matlab.
Everytime you want to add a col or a full matrix in an out of bounds index, automatically is created with the col given.
}

