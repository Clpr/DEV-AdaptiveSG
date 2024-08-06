export update!
export update_all!


# ------------------------------------------------------------------------------
"""
    update!(G::AdaptiveSparseGrid{d}) where d

Update the adaptive sparse grid `G` by doing residual fitting for the nodes with
NaN coefficients. This function is often used after adding new nodes to the grid

Without requiring the true function, this function simply uses the interpolant
to approximate the function value at the invalid node values.

## Notes
- If the objective function is available, then use `update!(G, f2fit)` is more
recommended in most cases.
- If `G` is well-trained, then one can expect that the residual fitting leads to
very small hierarchical coefficients within the tolerance `G.rtol`. However, the
function is usually essential for the self-containedness.
"""
function update!(G::AdaptiveSparseGrid{d}) where d
    for (node, nval) in pairs(G.nv)
        if !isvalid(nval)
            x  = get_x(node)
            f  = evalaute(
                G, x,
                untildepth = 0,
                validonly  = true
            )
            ff = evaluate(
                G, x,
                untildepth = node.depth - 1,
                validonly  = true
            ) # use ancestors only
            α  = f - ff
            G.nv[node] = NodeValue{d}(f, α)
        end
    end
    return nothing
end # update!()


# ------------------------------------------------------------------------------
"""
    update!(G::AdaptiveSparseGrid{d}) where d

Update the adaptive sparse grid `G` by doing residual fitting for the nodes with
NaN coefficients. This function is often used after adding new nodes to the grid

Without requiring the true function, this function simply uses the interpolant
to approximate the function value at the invalid node values.

## Notes
- If the objective function is available, then use `update!(G, f2fit)` is more
recommended in most cases.
- If `G` is well-trained, then one can expect that the residual fitting leads to
very small hierarchical coefficients within the tolerance `G.rtol`. However, the
function is usually essential for the self-containedness.
"""
function update!(G::AdaptiveSparseGrid{d}, f2fit::Function) where d
    validate_f2fit!(f2fit, d)
    for (node, nval) in pairs(G.nv)
        if !isvalid(nval)
            x = get_x(node)
            f = f2fit(x)
            α = f - evaluate(
                G, x, 
                untildepth = node.depth - 1,
                validonly  = true
            )
            G.nv[node] = NodeValue{d}(f, α)
        end
    end
    return nothing
end # update!()


# ------------------------------------------------------------------------------
"""
    update_all!(
        G::AdaptiveSparseGrid{d}, 
        f2fit::Function ; 
        printlevel::String = "iter"
    ) where d

Update/re-train the entire adaptive sparse grid `G` while keeping the current
grid structure (i.e. the set of nodes) unchanged. The `f2fit` is a function that
is likely to be different from the original function used for training.

## Notes
- This function is NOT parallelized by assuming sparsity in the grid structure,
and there is no need to try potential children nodes as the `train!()` function.
- If the grid is empty, then this function throws an error
"""
function update_all!(
    G::AdaptiveSparseGrid{d},
    f2fit::Function ;
    printlevel::String = "iter"
) where d
    validate_f2fit!(f2fit, d)
    if length(G) == 0
        throw(ArgumentError("empty grid. Consider train!() instead."))
    end

    # determine true depth of the grid
    maxdepth = 0
    for node in keys(G.nv)
        maxdepth = max(maxdepth, node.depth)
    end
    # update the grid depth information
    G.depth = maxdepth

    # check self-containedness and udpate the information
    G.selfcontained = is_selfcontained(G)

    # finally, update the node values, starting from depth = 2
    for lnow in 2:maxdepth
        if printlevel == "iter"
            println("updating depth = $lnow...")
        end
        for node in keys(G.nv)
            if node.depth == lnow
                x = get_x(node)
                f = f2fit(x)
                α = f - evaluate(
                    G, x,
                    untildepth = node.depth - 1,
                    validonly  = true
                )
                G.nv[node] = NodeValue{d}(f, α)
            end # if
        end # node
    end # lnow, (node, nval)
    if (printlevel == "iter") || (printlevel == "final")
        println("The entire ASG is updated.")
    end 
    return nothing
end # update_all!()


# ------------------------------------------------------------------------------
"""
    update_all!(
        G::AdaptiveSparseGrid{d}, 
        fnew::Dictionary{Node{d}, Float64} ;
        printlevel::String = "iter"
    ) where d

Update the entire adaptive sparse grid `G` while keeping the current grid struc-
ture. The `fnew` is a dictionary mapping from nodes to the new function values,
i.e. the nodal coefficients. `keys(G.nv)` must be a subseteq of `keys(fnew)`.

## Notes
- The key set of `fnew` is usually the same as the set of nodes in `G`. But it
is okay to have more nodes in `fnew` than in `G`. These extra nodes are ignored.
"""
function update_all!(
    G::AdaptiveSparseGrid{d},
    fnew::Dictionary{Node{d}, Float64} ;
    printlevel::String = "iter"
) where d
    validate_f2fit!(f2fit, d)
    if length(G) == 0
        throw(ArgumentError("empty grid. Consider train!() instead."))
    end

    # determine true depth of the grid
    maxdepth = 0
    for node in keys(G.nv)
        maxdepth = max(maxdepth, node.depth)
    end
    # update the grid depth information
    G.depth = maxdepth

    # check self-containedness and udpate the information
    G.selfcontained = is_selfcontained(G)

    # finally, update the node values (starting from depth 2)
    for lnow in 2:maxdepth
        if printlevel == "iter"
            println("updating depth = $lnow...")
        end
        for node in keys(G.nv)
            if node.depth == lnow
                x = get_x(node)
                f = fnew[node]
                α = f - evaluate(
                    G, x,
                    untildepth = node.depth - 1,
                    validonly  = true
                )
                G.nv[node] = NodeValue{d}(f, α)
            end # if
        end # node
    end # lnow, (node, nval)
    if (printlevel == "iter") || (printlevel == "final")
        println("The entire ASG is updated.")
    end 
    return nothing
end # update_all!()





