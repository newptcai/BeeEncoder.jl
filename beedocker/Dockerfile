FROM ubuntu:latest

RUN apt-get update

RUN apt-get install -y software-properties-common gpg

RUN apt-add-repository ppa:swi-prolog/stable

RUN apt-get update

RUN apt-get install -y swi-prolog-nox

RUN apt-get install -y wget

RUN wget -q https://julialang-s3.julialang.org/bin/linux/x64/1.4/julia-1.4.1-linux-x86_64.tar.gz

RUN tar -xzf julia-1.4.1-linux-x86_64.tar.gz

RUN echo "export PATH=\"\$PATH:`realpath julia-1.4.1/bin`\"" >> /root/.bashrc

RUN wget -q http://amit.metodi.me/research/bee/bee20170615.zip

RUN apt-get install -y unzip 

RUN apt-get install -y build-essential

RUN unzip -q -d bee bee20170615.zip 

RUN cd ./bee/satsolver_src && CPATH="/usr/lib/swi-prolog/include/" make satSolvers

RUN cd ./bee/beeSolver/ && make

RUN echo "export PATH=\"\$PATH:`realpath bee`\"" >> /root/.bashrc

RUN ./julia-1.4.1/bin/julia -e "using Pkg; Pkg.add(PackageSpec(url=\"https://github.com/newptcai/BEE.jl\"))"

RUN apt-get autoremove -y software-properties-common gpg wget unzip build-essential && \
    rm -f julia-1.4.1-linux-x86_64.tar.gz bee20170615.zip

RUN apt-get clean
