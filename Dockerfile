from ubuntu:16.04
maintainer OJ
user root

ENV USER_PASS=Scientific LANG=C.UTF-8 LC_ALL=C.UTF-8 RUNTIME=3.7 ETS_TOOLKIT=qt4 VTK=8 INSTALL_EDM_VERSION=2.0.0 PYTHONUNBUFFERED="1" PYBIND11_VERSION=2.2.3 FENICS_VERSION=2019.1.0 OMP_NUM_THREADS=4 DOLFIN_VERSION="2019.1.0.post0"  PYPI_FENICS_VERSION=">=2019.1.0,<2019.2.0" MSHR_VERSION="2019.1.0"

RUN apt-get update --fix-missing && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y tzdata wget bzip2 ca-certificates software-properties-common curl grep sed dpkg \
    wget htop mc git  xvfb x11vnc x11-xkb-utils xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic sudo

RUN add-apt-repository -y ppa:fenics-packages/fenics  && apt-get update


RUN apt-get install -y libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion build-essential gmsh git \
    libpcre3-dev cmake bison flex autotools-dev automake libx11-dev \
    mesa-common-dev freeglut3-dev libfreetype6-dev libc6-dev \
    libstdc++6 libstdc++-4.8-dev gcc g++ libftgl-dev \
    xorg-dev tcl-dev tk-dev python3-dev swig libglu1-mesa \
    g++-multilib libgmp-dev libmpfr-dev libmpc-dev lib32z1 lib32ncurses5 \
    libgmp-dev libmpfr-dev fenics \
	texlive-xetex texlive-fonts-recommended texlive-generic-recommended
run curl -sL https://deb.nodesource.com/setup_15.x | sudo -E bash - && apt-get install -y nodejs

# Non-Python utilities and libraries
RUN apt-get -qq update && \
    apt-get -y --with-new-pkgs \
        -o Dpkg::Options::="--force-confold" upgrade && \
    apt-get -y install curl && \
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
    apt-get -y install \
        bison \
        ccache \
        cmake \
        doxygen \
        flex \
        g++ \
        gfortran \
        git \
        git-lfs \
        graphviz \
        libboost-filesystem-dev \
        libboost-iostreams-dev \
        libboost-math-dev \
        libboost-program-options-dev \
        libboost-system-dev \
        libboost-thread-dev \
        libboost-timer-dev \
        libeigen3-dev \
        libfreetype6-dev \
        liblapack-dev \
        libmpich-dev \
        libopenblas-dev \
        libpcre3-dev \
        libpng-dev \
        libhdf5-mpich-dev \
        libgmp-dev \
        libcln-dev \
        libmpfr-dev \
        man \
        mpich \
        nano \
        pkg-config \
        wget \
        bash-completion && \
    git lfs install 
    

RUN git clone --recursive https://github.com/samgiles/docker-xvfb
RUN cp docker-xvfb/xvfb_init /etc/init.d/xvfb && chmod a+x /etc/init.d/xvfb && cp docker-xvfb/xvfb_daemon_run /usr/bin/xvfb-daemon-run && chmod a+x /usr/bin/xvfb-daemon-run
ENV DISPLAY :99

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.anaconda.com/archive/Anaconda3-2020.11-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh
ENV PATH /opt/conda/bin:$PATH
RUN echo "source activate base" > ~/.bashrc
SHELL ["conda", "run", "-n", "base",  "/bin/bash", "--login", "-c"]
run conda config --set allow_conda_downgrades true
run conda install  -y  mamba -c conda-forge
run mamba install -y -vv  -c conda-forge   pythonocc-core CadQuery \
	   'jupyterlab>=2.2,<3.0.0a0' xeus-python=0.6.7 notebook>=6 vtk PyQt5 numpy fenics  \
	    fenics-ffc fenics-dijitso fenics-fiat fenics-ufl fenics-dolfin fenics-libdolfin \
	    gmsh python-gmsh openmp    apptools envisage traitsui \
	traits pyface configobj xvfbwrapper itkwidgets pyvista \
	pip ptvsd nbconvert pandoc python-language-server notebook jupyterhub sudospawner npm nodejs>=10.0.0

RUN pip install 'fenics${PYPI_FENICS_VERSION}' && \
                  git clone https://bitbucket.org/fenics-project/dolfin.git && \
                  cd dolfin && \
                  git checkout ${DOLFIN_VERSION} && \
                  mkdir build && \
                  cd build && \
                  cmake ../ && \
                  make && \
                  make install && \
                  mv /usr/local/share/dolfin/demo /tmp/demo && \
                  mkdir -p /usr/local/share/dolfin/demo && \
                  mv /tmp/demo /usr/local/share/dolfin/demo/cpp && \
                  cd ../python && \
                  pip install . && \
                  cd demo && \
                  python3 generate-demo-files.py && \
                  mkdir -p /usr/local/share/dolfin/demo/python && \
                  cp -r documented /usr/local/share/dolfin/demo/python && \
                  cp -r undocumented /usr/local/share/dolfin/demo/python && \
                  cd /tmp/ && \
                  git clone https://bitbucket.org/fenics-project/mshr.git && \
                  cd mshr && \
                  git checkout ${MSHR_VERSION} && \
                  mkdir build && \
                  cd build && \
                  cmake ../ && \
                  make && \
                  make install && \
                  cd ../python && \
                  pip install . && \
                  ldconfig 

run which python && python -c "import numpy; print(numpy.__path__); from dolfin import *;"

run git clone https://github.com/enthought/mayavi.git && cd mayavi && pip install -r requirements.txt && python setup.py install
run pip install --pre  ipyevents jupyter-lsp jupyterhub-dummyauthenticator jupyterhub-firstuseauthenticator jupyterhub-systemdspawner
    
#run jupyter labextension install @krassowski/jupyterlab-lsp
run pip install jupyter-tabnine && \
    jupyter labextension install @jupyterlab/debugger  && \
    jupyter nbextension install --py jupyter_tabnine && \
    jupyter nbextension enable --py jupyter_tabnine && \
    jupyter serverextension enable --py jupyter_tabnine && \
    jupyter nbextension enable --py widgetsnbextension && \
    jupyter nbextension enable --py ipyevents &&\
    jupyter nbextension install --py mayavi --user && \
    jupyter nbextension enable --py mayavi --user
SHELL ["/bin/bash", "--login", "-c"]
run  wget https://raw.githubusercontent.com/bernhard-42/jupyter-cadquery/v1.0.0/environment.yml && \
wget https://raw.githubusercontent.com/bernhard-42/jupyter-cadquery/v1.0.0/labextensions.txt 
run jupyter-labextension install  $(cat labextensions.txt)
run jupyter lab build --dev-build=False --minimize=False
run jupyter labextension install jupyter-matplotlib jupyterlab-datawidgets itkwidgets 
SHELL ["conda", "run", "-n", "base",  "/bin/bash", "--login", "-c"]
run which python
run which python3
#Download spbuCAE/PyCAE does not exist
#Create admin user with given password 
#Allow users group /opt/notebooks directory access
#Start jupyterhub looking at /opt/notebooks folder for all users

cmd  /bin/bash -c "mkdir -p /opt/jupyterhub && mkdir -p /opt/notebooks && cd  /opt/notebooks && git clone --recursive https://github.com/spbuCAE/PyCAE ; cd /opt/jupyterhub && useradd --create-home --no-log-init --shell /bin/bash -g root admin && usermod -aG sudo admin  && usermod -aG users admin &&  echo \"admin:\$USER_PASS\" | chpasswd && mkdir -p /home/admin/notebooks  && chgrp -R users /opt/notebooks/ && chmod  -R g+rwx /opt/notebooks/ && jupyterhub --ip=0.0.0.0 --port=8892 --no-ssl  --JupyterHub.admin_access=True   --Authenticator.password=\"\$USER_PASS\" --Authenticator.whitelist=\"{'admin'}\" --Authenticator.admin_users=\"{'admin'}\" --JupyterHub.authenticator_class='firstuseauthenticator.FirstUseAuthenticator' --Spawner.args=\"['--NotebookApp.iopub_data_rate_limit=10000000000', '--SingleUserNotebookApp.shutdown_no_activity_timeout=3600', '--MappingKernelManager.cull_interval=120']\"  --JupyterHub.cleanup_proxy=True --Spawner.notebook_dir='/opt/notebooks/' --Spawner.default_url='/lab' --FirstUseAuthenticator.create_users=False"
