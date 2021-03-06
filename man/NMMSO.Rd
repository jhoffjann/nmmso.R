% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/nmmso.R
\name{NMMSO}
\alias{NMMSO}
\title{NMMSO}
\usage{
NMMSO(swarm_size, problem_function, max_evaluations, mn, mx, max_evol = 100,
  tolerance_value = 10^-6)
}
\arguments{
\item{swarm_size}{Maximum number of elements (particles) per swarm.}

\item{problem_function}{String containing name of function to be optimised.}

\item{max_evaluations}{Maximum number of evaluations to be taken through the problem function.}

\item{mn}{Minimum design parameter values (a vector with param_num elements).}

\item{mx}{Maximum design parameter values (a vector with param_num elements).}

\item{tolerance_value}{Tolerance value for merging automatically (default 10^-6).}

\item{max_evoluations}{Maximum number of swarms to update in a generation. If not provided this is set at 100.}
}
\value{
mode_loc_before = Design space location of current mode estimates (swarm gbests), note that at least one is likely to be very poor due to the
new swarm spawning at the end of each generation, and that these will be a combination of both global and local mode estimate.
mode_y_before = Function evalutions corresponding to the mode estimates.
evaluations_before = Number of problem function evaluations until this point.
nmmso_state = Structure holding the state of the swarms. Unless you want to pick apart the details of how the algorithm searchs the space,
then the only two elements you will probably be interested in are X and Y which are preallocated matrices to hold all locations visited
(therefore nmmso_state.X(1:evaluations,:) will hold all the design space locations visited by the optimiser thus far.
mode_loc_after = Design space location of mode estimates at end.
mode_y_after = Function evalutions corresponding to the mode estimates.
evaluations_after = Number of problem function evaluationsat end.
}
\description{
Implementation of the Niching Migratory Multi-Swarm Optimser.
}

