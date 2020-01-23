# PyCAE
A Multiuser CAE solution including CAD-to-FEM workflow and live in-browser 3d previews. Docker based, Python3 Focused utilizing Conda, CadQuery, FEniCS, PythonOCC, JupyterHub, JupyterLab.

[![CircleCI](https://circleci.com/gh/spbuCAE/PyCAE.svg?style=svg)](https://circleci.com/gh/spbuCAE/PyCAE)	
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This is ***a local team environment*** meaning one file system for all instance users. An instance is contained inside a docker container (so only folders that you explicitly provide will be visible to it). 

Environment includes:
 - **CAD** tools: *pythonocc-core* and *CadQuery*
 - **FEM** tools: *fenics-dolfin*
 - **Visualization** tools: *pyvista*, *itkwidgets* (in-browser), *mayavi* (on-server)

Note that as any real CAE software docker image file is big and requires at least **17GB** 

## Install

### From source
1) get code:
```bash
git clone --recursive https://github.com/spbuCAE/PyCAE/
cd PyCAE/
```
2) start building as a detached process:
```bash
nohup docker build -t spbu/cae:latest --squash . > build-logs.out 2>&1&
```
3) build takes time (1h+).
4) check build-logs.out:
```bash
tail build-logs.out
```
5) when build process have finished you shall see something like:
```bash
Removing intermediate container dccc972021d9
---> 513eafc3124f
Successfully built 3b4292862131
Successfully tagged spbu/cae:latest
```
6) start
on 0.0.0.0 (localhost and public IP if node has one) 
on port 8890 (port can be changed)
with admin user password `Scientific`
```bash
 docker run -d -p 8890:8892  -e USER_PASS=Scientific -d /full/path/to/a/shared/folder:/opt/notebook/ spbu/cae:latest
```

## Login
On navigating to it you shall see login screen:
<br/><img src="https://user-images.githubusercontent.com/2915361/73006355-6bf07980-3e02-11ea-964e-6f604c69cf41.png" width="300"/>

Enter `admin` as login with `Scientific` password - this will bring you to the JupiterLab

## Add a new user
1) Login into an administrator
2) Go to `/tree` view (url like ``) open 
3) Add user to JupiterHub (needed for abilety to login)
<br/><img src="https://user-images.githubusercontent.com/2915361/72955755-20ec4d00-3d95-11ea-8fe2-5288b2bee750.png" width=600>
4) Open a new termnal
5) Check that `sudo` works for you with
```
#will ask for user password e.g. Scientific
sudo ls
```
6) Add system user (needed for shared folder access)
```bash
sudo useradd --create-home --no-log-init --shell /bin/bash -g users test 
```
7) Provide user with login and JupyterHub website addres. On his first entrence what ever he will write as a `password` will be saved as his password.


## Help
Currently this project is in search for Collaboration and Funding. Please contribute.

### Cite Articles
 - [Creating A Tool For Stress Computation With Respect To Surface Defects. / Sedova, O.; Iakushkin O.; Kondratiuk. A.](http://ceur-ws.org/Vol-2507/371-375-paper-68.pdf) (OpenAccess)
 - [Jupyter extension for creating CAD designs and their subsequent analysis by the finite element method. / Iakushkin, O.; Sedova, O.; Grishkin, V. In: CEUR Workshop Proceedings, Vol. 1787, 2016, p. 530-534.](http://ceur-ws.org/Vol-1787/530-534-paper-92.pdf) (OpenAccess)
 - [Creating CAD designs and performing their subsequent analysis using opensource solutions in Python. / Iakushkin, Oleg O.; Sedova, Olga S. In AIP Computer Methods in Mechanics, CMM 2017: Proceedings of the 22nd International Conference on Computer Methods in Mechanics. Vol. 1922 American Institute of Physics, 2018. 140011.](https://aip.scitation.org/doi/abs/10.1063/1.5019153)

### Contribute
Current most-wanted features include:
 - Add Samples
 - Add OpenFOAM
 - Show CAD->OpenFOAM+FEniCS pipeline
 - Add CUDA (server side rendering) 
 - Add CUDA (PETSc, FEniCS buils)
 - Add CI
 
 Any other fixes, features and extensions are welcome and will be reviewed from GitHub pull requests.
 

### Funding
We seek for Grant and Cooperation opportunities. Please contact Ph.D., Vladimir Korkhov Associate Professor of Department of Computer Modelling and Multiprocessor Systems via email `v.korkhov at spbu.ru` for and cooperation details.

## License
PyCAE is first of all a preconfigured environment combining a wide set of OpenSource Python Packages, we encourage you to view their various License files. 

PyCAE provides Sample files and Utilities combining CAD, Meshing, FEM and other CAE required activities. We distribute them under MIT license
