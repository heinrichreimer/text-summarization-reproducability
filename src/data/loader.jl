using PyCall
using Conda

Conda.add("pytorch")
torch = pyimport("torch")

# Load preprocessed data from a single PyTorch Pickle file.
# As Julia does not support parsing PyTorch files itself,
# delegate to the Python package instead. 
function load_torch(path::String)
    @info "Loading PyTorch file '$path'."
    dataset = torch.load(abspath(path))
    return dataset
end

include("model.jl")

# Create an iterator for rows of the preprocessed data.
function data_loader(paths::Array{String})::Channel{SummaryPair}
	return Channel{SummaryPair}() do channel
		for path ∈ paths
			data = load_torch(path)
			@info "Loaded $(length(data)) rows."
			for dict ∈ data
				push!(channel, SummaryPair(dict))
			end
		end
	end
end

# Check if the file is of the given corpus type.
function is_corpus_type(path::String, corpus_type::String)
	@assert corpus_type ∈ ["train", "valid", "test"]
	isfile(path) && occursin(corpus_type, basename(path))
end

function filter_corpus_type!(paths::Array{String}, corpus_type::String)
    filter!(path -> is_corpus_type(path, corpus_type), paths)
end

# Create an iterator for rows of the preprocessed training/test/validation data.
function data_loader(path::String, corpus_type::String)::Channel{SummaryPair}
	paths = readdir(path, join=true, sort=true)
	filter_corpus_type!(paths, corpus_type)

	return Channel{SummaryPair}() do channel
		loader = data_loader(paths)
		for row ∈ loader
			push!(channel, row)
		end
	end
end