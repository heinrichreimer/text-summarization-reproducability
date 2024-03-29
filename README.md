[![CI](https://img.shields.io/github/actions/workflow/status/heinrichreimer/text-summarization-reproducability/ci.yml?branch=main&style=flat-square)](https://github.com/heinrichreimer/text-summarization-reproducability/actions/workflows/ci.yml)
[![Code coverage](https://img.shields.io/codecov/c/github/heinrichreimer/text-summarization-reproducability?style=flat-square)](https://codecov.io/github/heinrichreimer/text-summarization-reproducability/)
[![Issues](https://img.shields.io/github/issues/heinrichreimer/text-summarization-reproducability?style=flat-square)](https://github.com/heinrichreimer/text-summarization-reproducability/issues)
[![Commit activity](https://img.shields.io/github/commit-activity/m/heinrichreimer/text-summarization-reproducability?style=flat-square)](https://github.com/heinrichreimer/text-summarization-reproducability/commits)
[![License](https://img.shields.io/github/license/heinrichreimer/text-summarization-reproducability?style=flat-square)](LICENSE)

# 📝 text-summarization-reproducability

Reproducability study on the ["Text Summarization with Pretrained Encoders"](https://doi.org/10.18653/v1/D19-1387) paper
by Yang Liu and Mirella Lapata. In contrast to [the original implementation](https://github.com/nlpyang/PreSumm), we use
the [Julia Language](https://julialang.org/) with [Flux.jl](https://fluxml.ai/)
and [Transformers.jl](https://github.com/chengchingwen/Transformers.jl) for building the model.

_The study is conducted as part of
the [Data Mining](https://www.informatik.uni-halle.de/arbeitsgruppen/dbs/lehre/2757674_2757760/) lecture
at [Martin Luther University Halle-Wittenberg](https://uni-halle.de)._

## Usage

### Local machine

1. Install [Julia](https://julialang.org/downloads/).
1. Setup [PyCall.jl](https://github.com/JuliaPy/PyCall.jl) to use a Conda environment.

    ```shell script
    julia --project=./ ./src/setup_python.jl
    ```

1. Start [Pluto](https://github.com/fonsp/Pluto.jl) notebook.

    ```shell script
    julia --project=./ ./src/start_notebook.jl
    ```

    To train the model, tick the corresponding checkbox from the notebook.
    Alternatively, run `julia --project=./ ./src/training.jl` (which just runs the training from the notebook).

#### Local Julia installation

If needed (e.g., on a GPU cluster), you can install Julia locally.

```shell script
./install-julia.sh
```

You can then run Julia with `./julia`.

### Docker container

1. Install [Docker](https://docs.docker.com/get-docker/).
1. Build a Docker container with this project.

    ```shell script
    docker build -t text-summarization-reproducability .
    ```

1. Start [Pluto](https://github.com/fonsp/Pluto.jl) notebook.

    ```shell script
    docker run -p 1234:1234 -it text-summarization-reproducability
    ```

   Note that Julia runs rather slow inside Docker.

## Code quality

To keep code quality at a high level, all commits are atomic, which can be checked using the following command.

```shell script
git --no-pager log --all --graph --no-color --date=short --pretty='format:%h%d (%s, %ad)'
```

## License

This project is [MIT licensed](LICENSE), so you can use the code for whatever you want as long as you mention this
repository.
