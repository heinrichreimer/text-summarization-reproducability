using Flux

struct Path{T}
    sequence::Array{T}
    log_probability::AbstractFloat
    score::AbstractFloat
end

function expand(
    path::Path{T},
    predict::Function,
    vocabulary::AbstractVector{T},
    length_normalization::AbstractFloat
)::AbstractVector{Path{T}} where T
    # Compute probabilities for next token.
    log_word_probabilities = predict(path.sequence |> gpu)

    # Combine with own log probability.
    # Addition because log(p1 * p2) = log(p1) + log(p2).
    log_probabilities = log_word_probabilities .+ path.log_probability

    # Compute length penalty for normalization.
    α = length_normalization
    length_penalty = ((5 + (length(path.sequence) + 1))^α) / ((5 + 1)^α)

    # Compute scores.
    scores = log_probabilities ./ length_penalty

    # Return expanded paths.
    return [
        Path(
            [path.sequence..., vocabulary[i]],
            log_probabilities[i],
            scores[i],
        )
        for i ∈ 1:length(vocabulary)
    ]
end

function expand(
    path::Path{T},
    predict::Function,
    vocabulary::AbstractVector{T},
    expandable::Function,
    length_normalization::AbstractFloat
)::AbstractVector{Path{T}} where T
    if expandable(path.sequence)
        # Expand next token.
        expand(path, predict, vocabulary, length_normalization)
    else
        # Otherwise, return as is.
        [path]
    end
end

function has_redundant_trigrams(sequence::AbstractVector)::Bool
    if length(sequence) <= 3
        return false
    end
    trigram = sequence[end - 2:end]
    for i ∈ 1:length(sequence) - 3
        if sequence[i:i + 2] == trigram
            @debug "Sequence $sequence has redundant trigram $trigram at position $i."
            return true
        end
    end
    return false
end

has_redundant_trigrams(path::Path)::Bool = has_redundant_trigrams(path.sequence)

has_no_redundant_trigrams(path::Path)::Bool = !has_redundant_trigrams(path.sequence)

function block_redundant_trigrams!(
    paths::AbstractVector{Path{T}}
)::AbstractVector{Path{T}} where T
    return filter!(has_no_redundant_trigrams, paths)
end

# Beam search for generating sequences.
function beam_search(
    width::Integer, 
    vocabulary::AbstractVector{T}, 
    # Function returning a column vector of log probabilities for each word 
    # in the vocabulary, given the current sequence.
    predict::Function,
    # Predicate to check whether a sequence is expandable.
    # One might for example check for an end token.
    expandable::Function;
    initial_sequence::AbstractVector{T}=[],
    length_normalization::AbstractFloat=0.0,
)::AbstractVector{T} where T
    # Best current path.
    best_path::Path{T} = Path(initial_sequence, 1.0, -Inf)
    # Paths to be considered as start for a single iteration.
    # Start with one initial path, the empty sequence.
    paths::AbstractVector{Path{T}} = [best_path]

    # Expand iteratively until no expandable path is left.
    i = 1
    while length(paths) > 0 && any(path -> expandable(path.sequence), paths)
        @debug "Predicting next token for iteration $i."
        
        # Calculate paths (hypotheses and probabilities).
        next_paths::AbstractVector{Path{T}} = vcat(
            [
                expand(path, predict, vocabulary, expandable, length_normalization)
                for path ∈ paths 
            ]...
        )

        # Block redundant trigrams to avoid repetition.
        # TODO Make configurable.
        # TODO Paulus et al. (2017, p.4) apply this only on the test set.
        block_redundant_trigrams!(next_paths)

        # Sort paths by descending score.
        sort!(next_paths, by=path -> path.score, rev=true)

        # Select best paths.
        paths = next_paths[1:min(length(next_paths), width)]

        local_best_path::Path{T} = first(paths)
        @info "Found best sequence for iteration $i with probability $(exp(local_best_path.log_probability)) (score $(local_best_path.score))."

        if local_best_path.score > best_path.score
            best_path = local_best_path
        end

        i += 1
    end

    @info "Found best sequence with probability $(exp(best_path.log_probability)) (score $(best_path.score))."
    return best_path.sequence
end

# Beam search for generating sequences.
function beam_search(
    width::Integer, 
    vocabulary::AbstractVector{T}, 
    # Function returning a column vector of log probabilities for each word 
    # in the vocabulary, given the current sequence.
    predict::Function,
    # Max steps to expand.
    steps::Integer;
    initial_sequence::AbstractVector{T}=[],
    length_normalization::AbstractFloat=0.0,
)::AbstractVector{T} where T
    beam_search(
        width,
        vocabulary,
        predict,
        sequence -> length(sequence) < length(initial_sequence) + steps,
        initial_sequence=initial_sequence,
        length_normalization=length_normalization,
    )
end

# Beam search for generating sequences.
function beam_search(
    width::Integer, 
    vocabulary::AbstractVector{T}, 
    # Function returning a column vector of log probabilities for each word 
    # in the vocabulary, given the current sequence.
    predict::Function,
    # Predicate to check whether a sequence is expandable.
    # One might for example check for an end token.
    expandable::Function,
    # Max steps to expand.
    steps::Integer;
    initial_sequence::AbstractVector{T}=[],
    length_normalization::AbstractFloat=0.0,
)::AbstractVector{T} where T
    beam_search(
        width,
        vocabulary,
        predict,
        sequence -> expandable(sequence) && (length(sequence) < length(initial_sequence) + steps),
        initial_sequence=initial_sequence,
        length_normalization=length_normalization,
    )
end

# Like beam search, but only the single locally best path is considered.
function greedy_search(
    vocabulary::AbstractVector{T},
    # Function returning a column vector of log probabilities for each word 
    # in the vocabulary, given the current sequence and input.
    predict::Function,
    # Predicate to check whether a sequence is expandable.
    # One might for example check for an end token.
    expandable::Function;
    initial_sequence::AbstractVector{T}=[],
)::AbstractVector{T} where T
    beam_search(
        1, 
        vocabulary, 
        predict, 
        expandable, 
        initial_sequence=initial_sequence,
    )
end

# Like beam search, but only the single locally best path is considered.
function greedy_search(
    vocabulary::AbstractVector{T},
    # Function returning a column vector of log probabilities for each word 
    # in the vocabulary, given the current sequence and input.
    predict::Function,
    # Max steps to expand.
    steps::Integer;
    initial_sequence::AbstractVector{T}=[]
)::AbstractVector{T} where T
    beam_search(
        1, 
        vocabulary, 
        predict, 
        steps, 
        initial_sequence=initial_sequence,
    )
end

# Like beam search, but only the single locally best path is considered.
function greedy_search(
    vocabulary::AbstractVector{T},
    # Function returning a column vector of log probabilities for each word 
    # in the vocabulary, given the current sequence and input.
    predict::Function,
    # Predicate to check whether a sequence is expandable.
    # One might for example check for an end token.
    expandable::Function,
    # Max steps to expand.
    steps::Integer;
    initial_sequence::AbstractVector{T}=[]
)::AbstractVector{T} where T
    beam_search(
        1, 
        vocabulary, 
        predict,
        expandable, 
        steps, 
        initial_sequence=initial_sequence,
    )
end
