# Stage 1: Compile the planner
Bootstrap: docker
From: ubuntu:22.04
Stage: build

%files
    planners/odin /planners/odin

%post
    ## Install all necessary dependencies.
    apt-get update
    apt-get -y install --no-install-recommends cmake g++ make python3.11 autoconf automake

    ## Clear build directory.
    rm -rf /planners/odin/builds

    ## Build planner.
    cd /planners/odin
    python3.11 build.py

    ## Strip binaries.
    strip --strip-all /planners/odin/builds/release/bin/downward /planners/odin/builds/release/bin/preprocess-h2

# Stage 2: Run the planner
Bootstrap: docker
From: ubuntu:22.04
Stage: run

%files from build
    /planners/odin/driver
    /planners/odin/fast-downward.py
    /planners/odin/builds/release/bin

%post
    apt-get update
    apt-get -y install --no-install-recommends python3.11
    rm -rf /var/lib/apt/lists/*


%runscript
    DOMAINFILE="$1"
    PROBLEMFILE="$2"
    PLANFILE="$3"

    python3.11 /planners/odin/fast-downward.py --translate "$DOMAINFILE" "$PROBLEMFILE"
    python3.11 /planners/odin/fast-downward.py --portfolio /planners/odin/driver/portfolios/seq_opt_odin.py --search-time-limit 30m output.sas

%labels
Name        Odin
Description Classical planning system with transition cost partitioning algorithms
Authors     Dominik Drexler <dominik.drexler@liu.se>, Jendrik Seipp <jendrik.seipp@liu.se>, David Speck <david.speck@liu.se>
License     GPL 3
Tracks      optimal
SupportsDerivedPredicates                       no
SupportsUniversallyQuantifiedPreconditions      yes
SupportsExistentiallyQuantifiedPreconditions    yes
SupportsUniversallyQuantifiedEffects            yes
SupportsNegativePreconditions                   yes
SupportsEqualityPreconditions                   yes
SupportsInequalityPreconditions                 yes
SupportsConditionalEffects                      yes
SupportsImplyPreconditions                      yes