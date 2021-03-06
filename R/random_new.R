#' @title random_new
#'
#' @param nmmso_state Structure holding state of swarm.
#' @param problem_function String containing name of function to be optimised.
#' @param mn Minimum design parameter values (a vector with param_num elements).
#' @param mx Maximum design parameter values (a vector with param_num elements).
#' @param problem_function_params Meta-parameters needed by problem function.
#' @param swarm_size Maximum number of elements (particles) per swarm.
#' @return
#' nmmso_state = Structure holding state of swarm.
#' number_rand_modes = Number of random modes (Apparently always 1).
#'
#' @export
random_new <- function(nmmso_state, problem_function, mn, mx, swarm_size) {
    number_rand_modes = 1

    x = matrix(runif(size(mx)[1]*size(mx)[2]), size(mx)[1]) * (mx - mn) + mn

    nmmso_state$swarms_changed = add_row(nmmso_state$swarms_changed, size(nmmso_state$swarms_changed)[1] + 1, 1)
    nmmso_state$converged_modes = c(nmmso_state$converged_modes, 0)
    #create new swarm
    swarm <- list("new_location" = x[1,])

    result = evaluate_first(swarm, problem_function, nmmso_state, swarm_size, mn, mx)

    swarm = result$swarm

    nmmso_state = result$nmmso_state

    nmmso_state$swarms = c(nmmso_state$swarms, list(swarm))
    nmmso_state$mode_locations = rbind(nmmso_state$mode_locations, x)
    nmmso_state$mode_values = c(nmmso_state$mode_values, swarm$mode_value) 
    
    list("nmmso_state" = nmmso_state, "number_rand_modes" = number_rand_modes)
}