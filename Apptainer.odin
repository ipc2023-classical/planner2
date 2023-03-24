# Stage 1: Compile the planner
Bootstrap: docker
From: ubuntu:22.04
Stage: build

%files
    planners/odin /planners/odin
    planners/scorpion /planners/scorpion

%post
    ## Install all necessary dependencies.
    apt-get update
    apt-get -y install --no-install-recommends cmake g++ make python3.11 autoconf automake pypy3

    ## Build planners.
    for planner in odin scorpion; do
        cd /planners/${planner}
        pypy3 build.py
    done

    ## Strip binaries.
    strip --strip-all /planners/odin/builds/release/bin/downward /planners/odin/builds/release/bin/preprocess-h2
    strip --strip-all /planners/scorpion/builds/release/bin/downward /planners/scorpion/builds/release/bin/preprocess-h2

# Stage 2: Run the planner
Bootstrap: docker
From: ubuntu:22.04
Stage: run

%files
    dispatch.py /dispatch.py
    plan.py /plan.py
    driver /driver

%files from build
    /planners/odin/driver
    /planners/odin/fast-downward.py
    /planners/odin/builds/release/bin

    /planners/scorpion/driver
    /planners/scorpion/fast-downward.py
    /planners/scorpion/builds/release/bin
    # /driver/run_components.py points to the src directory.
    /planners/scorpion/src/translate

%post
    apt-get update
    apt-get -y install --no-install-recommends pypy3
    apt-get clean
    rm -rf /var/lib/apt/lists/*


%runscript
    DOMAINFILE="$1"
    PROBLEMFILE="$2"
    PLANFILE="$3"

    pypy3 /plan.py \
        --overall-time-limit 30m \
        --transform-task /planners/odin/builds/release/bin/preprocess-h2 \
        --transform-task-options h2_time_limit,180 \
        --alias seq-opt-odin \
        --plan-file "$PLANFILE" \
        "$DOMAINFILE" "$PROBLEMFILE"


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