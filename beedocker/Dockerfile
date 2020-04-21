FROM ubuntu:latest

RUN apt-get update && \ 
    apt-get install -y software-properties-common wget unzip build-essential && \
    apt-add-repository ppa:swi-prolog/stable && \
    apt-get update && \
    apt-get install -y swi-prolog-nox && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/1.4/julia-1.4.1-linux-x86_64.tar.gz && \
    tar -xzf julia-1.4.1-linux-x86_64.tar.gz && \
    rm -f julia-1.4.1-linux-x86_64.tar.gz && \
    echo "export PATH=\"\$PATH:`realpath julia-1.4.1/bin`\"" >> /root/.bashrc && \
    wget -q http://amit.metodi.me/research/bee/bee20170615.zip && \
    unzip -q -d bee bee20170615.zip && \
    rm -f bee20170615.zip && \
    (cd ./bee/satsolver_src && CPATH="/usr/lib/swi-prolog/include/" make satSolvers) && \
    (cd ./bee/beeSolver/ && make) && \
    echo "export PATH=\"\$PATH:`realpath bee`\"" >> /root/.bashrc && \
    ./julia-1.4.1/bin/julia -e "using Pkg; Pkg.add(PackageSpec(url=\"https://github.com/newptcai/BEE.jl\"))" && \
    apt-get autoremove -y software-properties-common wget unzip build-essential vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
