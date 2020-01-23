from ubuntu:16.04
maintainer OJ
user root

ENV USER_PASS=Scientific LANG=C.UTF-8 LC_ALL=C.UTF-8 RUNTIME=3.7 ETS_TOOLKIT=qt4 VTK=8 INSTALL_EDM_VERSION=2.0.0 PYTHONUNBUFFERED="1" PYBIND11_VERSION=2.2.3 FENICS_VERSION=2019.1.0 

RUN apt-get update --fix-missing && \
    apt-get install -y wget bzip2 ca-certificates software-properties-common curl grep sed dpkg \
    wget htop mc git  xvfb x11vnc x11-xkb-utils xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic sudo

RUN add-apt-repository -y ppa:fenics-packages/fenics && add-apt-repository -y ppa:timsc/swig-3.0.12 && apt-get update

RUN apt-get install -y libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion build-essential gmsh git \
    libpcre3-dev cmake bison flex autotools-dev automake libx11-dev \
    mesa-common-dev freeglut3-dev libfreetype6-dev libc6-dev \
    libstdc++6 libstdc++-4.8-dev gcc g++ libftgl-dev \
    xorg-dev tcl-dev tk-dev python3-dev swig libglu1-mesa \
    g++-multilib libgmp-dev libmpfr-dev libmpc-dev lib32z1 lib32ncurses5 \
    libgmp-dev libmpfr-dev fenics

RUN git clone --recursive https://github.com/samgiles/docker-xvfb
RUN cp docker-xvfb/xvfb_init /etc/init.d/xvfb && chmod a+x /etc/init.d/xvfb && cp docker-xvfb/xvfb_daemon_run /usr/bin/xvfb-daemon-run && chmod a+x /usr/bin/xvfb-daemon-run
ENV DISPLAY :99

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/archive/Anaconda3-5.3.1-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh
ENV PATH /opt/conda/bin:$PATH

run conda install  -c conda-forge -c CadQuery CadQuery::pythonocc-core CadQuery::CadQuery=master fenics mayavi=4.7.1 \
    vtk  numpy apptools envisage traitsui traits pyface configobj ipyevents xvfbwrapper itkwidgets pyvista pip conda jupyterlab \
    fenics-ffc fenics-dijitso fenics-fiat fenics-ufl fenics-dolfin fenics-libdolfin && \
	conda update  -c conda-forge  -c CadQuery -y --all

run conda install -y -c conda-forge python-language-server notebook jupyterhub nodejs sudospawner && \
    pip install --pre jupyter-lsp jupyterhub-dummyauthenticator jupyterhub-firstuseauthenticator jupyterhub-systemdspawner && \
    jupyter labextension install @krassowski/jupyterlab-lsp

run pip install jupyter-tabnine && \
    jupyter nbextension install --py jupyter_tabnine && \
    jupyter nbextension enable --py jupyter_tabnine && \
    jupyter serverextension enable --py jupyter_tabnine && \
    jupyter nbextension enable --py widgetsnbextension && \
    jupyter nbextension enable --py ipyevents && \
    jupyter nbextension install --py mayavi --user && \
    jupyter nbextension enable --py mayavi --user && \
    wget https://raw.githubusercontent.com/bernhard-42/jupyter-cadquery/v0.9.4/environment.yml && \
    wget https://raw.githubusercontent.com/bernhard-42/jupyter-cadquery/v0.9.4/labextensions.txt && \
	jupyter labextension install @jupyter-widgets/jupyterlab-manager jupyter-matplotlib jupyterlab-datawidgets itkwidgets && \
	jupyter-labextension install --no-build $(cat labextensions.txt) && jupyter lab build --dev-build=True --minimize=False
	
cmd  /bin/bash -c "mkdir -p /opt/notebooks && cd  /opt/notebooks && git clone --recursive https://github.com/spbuCAE/PyCAE && useradd --create-home --no-log-init --shell /bin/bash -g root admin && usermod -aG sudo admin  && usermod -aG users admin &&  echo "admin:$USER_PASS" | chpasswd && mkdir -p /home/admin/notebooks  && chgrp -R users /opt/notebooks/ && chmod  -R g+rwx /opt/notebooks/ && jupyterhub --ip=0.0.0.0 --port=8892 --no-ssl  --JupyterHub.admin_access=True   --Authenticator.password=\"$USER_PASS\" --Authenticator.whitelist=\"{'admin'}\" --Authenticator.admin_users=\"{'admin'}\" --JupyterHub.authenticator_class='firstuseauthenticator.FirstUseAuthenticator' --Spawner.args=\"['--NotebookApp.iopub_data_rate_limit=10000000000', '--SingleUserNotebookApp.shutdown_no_activity_timeout=3600', '--MappingKernelManager.cull_interval=120']\"  --JupyterHub.cleanup_proxy=True --Spawner.notebook_dir='/opt/notebooks/' --Spawner.default_url='/lab' --FirstUseAuthenticator.create_users=False"
