#' @title merge_swarms
#' 
#' @param nmmso_state Structure holding state of swarm.
#' @param problem_function String containing name of function to be optimised.
#' @param problem_function_params Meta-parameters needed by problem function.
#' @param mn Minimum design parameter values (a vector with param_num elements).
#' @param mx Maximum design parameter values (a vector with param_num elements).
#' @return 
#' nmmso_state = Structure holding state of swarm.
#' number_of_mid_evals = Number of evaluations done for the merging.
#' 
#' @export
merge_swarms <- function(nmmso_state, problem_function, mn, mx) {  
  # only concern ourselves with modes that have actually shifted, or are new
  # since the last generation, as no need to check others
  I = which(nmmso_state$swarms_changed == 1)
  nmmso_state$swarms_changed = nmmso_state$swarms_changed * 0 # reset
  n = length(I)
  number_of_mid_evals = 0
    # only compare if there is a changed mode, and more than on mode in system
  if (n >= 1 && (length(nmmso_state$swarms) > 1)) {
    to_compare = matrix(0, n, 2)
    to_compare[, 1] = I
    for (i in 1:n) {      
      # calculate euclidean distance     
      to_compare = rbind(to_compare)

      d = new_dist2(rbind(nmmso_state$mode_locations[I[i],]), nmmso_state$mode_locations)
      # will be closest to itself, so need to get second closest
      d[I[i]] = Inf
      tmp = min(d)
      to_compare[i, 2] = which.min(d)
      # track euclidean distance to nearest neighbour mode
      nmmso_state$swarms[[I[i]]]$dist = sqrt(tmp)

      if (nmmso_state$swarms[[I[i]]]$number_of_particles == 1) {
        reject = 0
        # in situation where a new swarm, and therefore distance to neighbor swarm now calculated
        # so set the initial velocity at a more reasonable value for the first particle, rather than using the uniform in design space
        temp_vel = mn - 1
        while (sum(temp_vel < mn) > 0 || sum(temp_vel > mx) > 0) {
          temp_vel = uniform_sphere_points(1, length(nmmso_state$swarms[[I[i]]]$new_location))*(nmmso_state$swarms[[I[i]]]$dist / 2)
          reject = reject + 1
          
          # rejecting lots, so likely in a corner of design space where a significant volume of the sphere lies outside
          # the bounds, so will make do with a random legal velocity in bounds
          if (reject > 20) {
            new_location_size = nmmso_state$swarms[[I[i]]]$new_location
            temp_vel = matrix(runif(size(new_location_size)[1]*size(new_location_size)[2]), size(new_location_size)[1]) * (mx-mn) + mn
          }
        }
        nmmso_state$swarms[[I[i]]]$velocities = add_row(nmmso_state$swarms[[I[i]]]$velocities, 1, temp_vel)
      }
    }
    
    # to_compare now contains the pairs of indices of closest modes, where at least one mode has shifted location / is new
    # since last generation. However, there may be duplicated pairs (through reversals), so need to omit these.
    # now sort it so that first column elements are always smaller than second
    to_compare = t(apply(to_compare, 1, sort))
    # now sort it so that first column is sorted smallest to highest
    to_compare = apply(to_compare, 2, sort)
    to_compare = rbind(to_compare)
    
    # TODO: this is weird
    # column elements on same row
    # Remove duplicates for matrices with more than one row
    if(n >= 2){
      for (i in seq(n, 2, -1)) { #change in the decrement for (from n to 2 by -2)
        # get indices of all with first index element same
        I = which(to_compare[, 1] == to_compare[, 1])
        # replicate matrix
      repeat_matrix = repmat(to_compare[i, ], length(I), 1)
        # compare to matlab line 259, reconstructed it due to complications
      inner = apply((repeat_matrix == to_compare[I, ]), 2, sum)
        # if more than one vector duplication
      if (sum(inner == 2) > 1) {
        to_compare = to_compare[-i, ]
        to_compare = rbind(to_compare)
      }
    }
  }
  # Check for merging
  n = size(to_compare)[1]
  number_of_mid_evals = 0
  to_merge = 0
  
  for (i in 1:n) {
    # merge if sufficiently close
    distance = new_dist2(nmmso_state$swarms[[to_compare[i, 1]]]$mode_location, nmmso_state$swarms[[to_compare[i, 2]]]$mode_location)
    if (sqrt(distance) < nmmso_state$tolerance_value) {
      # can't preallocate, as don't know the size
      to_merge = c(to_merge, i)
    } else {
      # evaluate exact mid point between modes, and add to mode 2
      # history
      mid_loc = 0.5 * (nmmso_state$swarms[[to_compare[i, 1]]]$mode_location - nmmso_state$swarms[[to_compare[i, 2]]]$mode_location)+ nmmso_state$swarms[[to_compare[i, 2]]]$mode_location
      # little sanity check
      if (sum(mid_loc < mn) > 0 || sum(mid_loc > mx) > 0) {
        warning("Mid point out of range!")
      }

      nmmso_state$swarms[[to_compare[i, 2]]]$new_location = mid_loc
      evaluate_mid = evaluate_mid(nmmso_state, to_compare[i, 2], problem_function)
      nmmso_state = evaluate_mid$nmmso_state
      mode_shift = evaluate_mid$mode_shift
      y = evaluate_mid$y

      # if a swarm was shifted
      if (mode_shift == 1) {
        nmmso_state$mode_locations = add_row(nmmso_state$mode_locations, I[i], nmmso_state$swarms[[to_compare[i, 2]]]$mode_location)   
        nmmso_state$mode_values[to_compare[i, 2]] = nmmso_state$swarms[[to_compare[i, 2]]]$mode_value
        to_merge = rbind(to_merge, i)
        # track that the mode value has improved
        nmmso_state$swarms_changed[to_compare[i, 2]] = 1
        #better than mode 1 current mode, so merge
      } else if (nmmso_state$swarms[[to_compare[i, 2]]]$mode_value < y) {
        to_merge = rbind(to_merge, i)
      }

      number_of_mid_evals = number_of_mid_evals + 1
    }
  }

  # merge those marked pairs, and flag the lower one for deletion
  delete_index = replicate(1, to_merge) * 0
  to_merge = to_merge[-which(to_merge == 0)] 
  if(length(to_merge > 0)){ 
    for (i in 1:length(to_merge)) {
      # little sanity check
      if (to_compare[to_merge[i], 2] == to_compare[to_merge[i], 1]) {
        stop('Indices should not be equal')
      }
      # if peak of mode 1 is higher than mode 2, then replace
      if (nmmso_state$swarms[[to_compare[to_merge[i], 1]]]$mode_value > nmmso_state$swarms[[to_compare[to_merge[i], 2]]]$mode_value) {
        delete_index = c(delete_index, to_compare[to_merge[i], 2])
        nmmso_state$swarms[[to_compare[to_merge[i], 1]]] = merge_swarms_together(nmmso_state$swarms[[to_compare[to_merge[i], 1]]], nmmso_state$swarms[[to_compare[to_merge[i], 2]]])
      #track that the mode value has been merge and should be compared again
        nmmso_state$swarms_changed[[to_compare[i, 1]]] = 1
      } else {
        delete_index = c(delete_index, to_compare[to_merge[i], 1])
        nmmso_state$swarms[[to_compare[to_merge[i], 2]]] = merge_swarms_together(nmmso_state$swarms[[to_compare[to_merge[i], 2]]], nmmso_state$swarms[[to_compare[to_merge[i], 1]]])
        # track that the mode value has merge and should be compared again
        nmmso_state$swarms_changed[to_compare[i, 2]] = 1
      }
    }

    # remove one of the merged pair
    prev_merge = -1
    # delete initial 0 from delete indices
    delete_index = delete_index[-which(delete_index == 0)]
    delete_index = sort(delete_index, decreasing = TRUE)
    for (i in seq(length(delete_index), 1, -1)) {
      if (delete_index[i] != prev_merge) {
        prev_merge = delete_index[i]
        nmmso_state$swarms[[delete_index[i]]] <- NULL
        nmmso_state$mode_locations = nmmso_state$mode_locations[-(delete_index[i]), ,drop = FALSE]
        nmmso_state$mode_values = nmmso_state$mode_values[-delete_index[i]]
        nmmso_state$converged_modes = nmmso_state$converged_modes[-delete_index[i]]
        nmmso_state$swarms_changed = nmmso_state$swarms_changed[-delete_index[i]]
      }
    }
  }
  


  # only one mode, so choose dist for it (smallest design dimension)
  if (length(nmmso_state$swarms) == 1) {
    nmmso_state$swarms[[1]]$dist = min(mx - mn)
    if (length(nmmso_state$active_modes) == 1) {
      nmmso_state$active_modes[[1]]$swarm$dist = min(mx - mn)
    }
  # return the values
    
  }
}
list("nmmso_state" = nmmso_state, "number_of_merge_evals" = number_of_mid_evals)
}