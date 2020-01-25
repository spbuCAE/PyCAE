##Copyright 2020 Oleg Iakushkin (oleg.jakushkin@gmail.com)
##
##This file is part of PyCAE.

import os
import subprocess
import random
import time

os.environ['ETS_TOOLKIT']='null'
import numpy

from xvfbwrapper import Xvfb
from IPython.display import Image
from mayavi import mlab

def init():
    display = Xvfb(width=500, height=500)
    display.start()
    mlab.init_notebook()
init()

from occ_utils import *
from OCC.Display.WebGl.x3dom_renderer import *
from IPython.display import display, HTML
from OCC.Display.WebGl import x3dom_renderer
from OCC.Core.BRepPrimAPI import *
from OCC.Core.BRepMesh import *
from OCC.Core.gp import gp_Vec
from OCC.Core.StlAPI import StlAPI_Writer
from OCC.Core.BRepPrimAPI import BRepPrimAPI_MakeTorus
from OCC.Core.BRepMesh import BRepMesh_IncrementalMesh
from OCC.Display.WebGl.x3dom_renderer import *

import cadquery as cq
from cadquery  import exporters

import dolfin
from dolfin import *

from itkwidgets import view
import pyvista
from pyvista import *

caller_id = 0
geom_counter = 0
geoCounter = 0
mgeoCounter = 0
stepCounter = 0
fem_counter = 0


def DisplayShape(shape,
                     local_display_id=0,
                     vertex_shader=None,
                     fragment_shader=None,
                     export_edges=False,
                     color=(random.random(), random.random(), random.random()),
                     specular_color=(1, 1, 1),
                     shininess=0.9,
                     transparency=0.,
                     line_color=(0, 0., 0.),
                     line_width=2.,
                     mesh_quality=1.):
        global caller_id
        caller_id = caller_id + 1

        def Show(src="<shape><appearance><material diffuseColor='0.603 0.894 0.909'></material></appearance> <box></box></shape>   ", height=400,  width=400):
            width=str(width)
            height=str(height)
            result = ""
            if(local_display_id <1):
                result += " <script type='text/javascript' src='http://www.x3dom.org/download/x3dom.js'> </script>  <link rel='stylesheet' type='text/css' href='http://www.x3dom.org/download/x3dom.css'></link>"

            result +="<div style='height: "+height+"px;width: 100%;' id='x3dholder_"+str(caller_id)+"'  width='100%' height='"+height+"px'><x3d style='height: "+height+"px;width: 100%;' id='x3d"+str(caller_id)+"' width='100%' height='"+height+"px'><scene id='scene_"+str(caller_id)+"'>"+src+"   </scene></x3d> </div>"
            return result
        x3d_exporter = X3DExporter(shape, vertex_shader, fragment_shader,
                                   export_edges, color,
                                   specular_color, shininess, transparency,
                                   line_color, line_width, mesh_quality)
        x3d_exporter.compute()

        tmp = x3d_exporter.to_x3dfile_string(shape_id=caller_id)
        temp_file_name = "tmp_"+str(caller_id)+".x3d"
        if os.path.exists(temp_file_name): os.remove(temp_file_name)
        text_file = open(temp_file_name, "w")
        text_file.write(tmp)
        text_file.close()
        time.sleep(1)
        return HTML(Show("<inline url='./"+temp_file_name+"'> </inline> "))


def execute(command, show_log=True):
    if show_log:
        print("calling command >\n" + command + "\n----------------------\n")
    out = ""
    try:
        out = subprocess.check_output(
                [command],
                stderr=subprocess.STDOUT,
                shell=True
                ).strip().decode('utf8')
    except subprocess.CalledProcessError as e:
        out = e.output
    if show_log:
        print(out)


def get_merged_geo(filename):
    global mgeoCounter
    geoCounter = mgeoCounter+1
    geoFile = "Merge \""+filename+"\";\n"
    temp_file_name = "tmp_mgeo_"+str(mgeoCounter)+".geo"
    if os.path.exists(temp_file_name):
        os.remove(temp_file_name)

    text_file = open(temp_file_name, "w")
    text_file.write(geoFile)
    text_file.close()
    time.sleep(1)
    return temp_file_name


def step2stl(step_filename, emax=1, algorithm="del2d", show_log=False):
    global mgeoCounter
    temp_file_name = get_merged_geo(step_filename)
    out_file_name = "tmp_SFM_" + str(mgeoCounter) + ".stl"
    execute("OMP_NUM_THREADS=40 gmsh -2 -algo "+algorithm + " -clmax  " + str(emax) + " " + temp_file_name + " -o " + out_file_name, \
            show_log)
    time.sleep(1)
    return out_file_name


def getStl(g, step=0.6):
    global geom_counter
    geom_counter = geom_counter + 1
    name_base = "./tmp_g_"+ str(fem_counter);
    stl_file = name_base +".stl"
    mesh = BRepMesh_IncrementalMesh(g, step)
    mesh.Perform()
    stl_exporter = StlAPI_Writer()
    stl_exporter.SetASCIIMode(True)  # change to False if you need binary export
    stl_exporter.Write(g, stl_file)
    return stl_file


def show_geom(g, local=False, step=0.6, show_surface=True):
    if not local:
        stl_file = getStl(g, step=step)
        time.sleep(3)
        print(stl_file)
        mlab.init_notebook()
        mlab.clf()

        s = mlab.pipeline.open(stl_file)

        if show_surface:
            s = mlab.pipeline.surface(s)
        return s
    else:
        result = DisplayShape(trans_box, export_edges=True, color=rnd_color, transparency=random.random())
        return display(result)


def getGeo(stl_filename):
    global geoCounter
    geoCounter = geoCounter+1
    geoFile = "Merge \""+stl_filename+"\";\nSurface Loop(1) = {1};\nVolume(1) = {1};\nPhysical Volume(1) = {1};\n"
    temp_file_name = "tmp_geo_"+str(geoCounter)+".geo"
    if os.path.exists(temp_file_name): os.remove(temp_file_name)
    text_file = open(temp_file_name, "w")
    text_file.write(geoFile)
    text_file.close()
    time.sleep(1)
    return temp_file_name;


def stl2msh(stl_filename, algo="meshadapt", show_log=False):
    global geoCounter
    temp_file_name = getGeo(stl_file)
    out_file_name = "tmp_SFM_"+str(geoCounter)+".msh"
    execute("gmsh -3 -algo "+algo+" "+temp_file_name+" -o "+out_file_name, show_log)
    time.sleep(1)
    return out_file_name


def msh2xml(msh_filename):
    global geoCounter
    out_file_name = "tmp_MSH_" + str(geoCounter) + ".xml"
    execute("dolfin-convert " + msh_filename + " " + out_file_name)
    time.sleep(1)
    return out_file_name


#Turns a PythonOOC geometry into a FEniCS Mesh (stl->msh->xml)
def make_mesh(g):
    f = getStl(g)
    f = stl2msh(f)
    f = msh2xml(f)
    return dolfin.Mesh(f)


def show_cad(mesh, emax=1, show_log=False):
    global mgeoCounter
    temp_file_name = "tmp_step_" + str(stepCounter) + ".step"
    val = mesh.val()
    val.exportStep(temp_file_name)
    time.sleep(1)
    stl_file = step2stl(temp_file_name, emax=emax)
    time.sleep(1)
    vol = pyvista.read(stl_file)
    v = view(geometries=[vol])
    return v


def show_fem(u, local=False, show_volume=True, show_plane=True):
    global fem_counter
    fem_counter = fem_counter + 1
    mlab.init_notebook()
    mlab.clf()
    name_base = "./tmp_u_" + str(fem_counter)
    dolfin.File(name_base+".pvd") << u
    time.sleep(1)
    s = mlab.pipeline.open(name_base + '000000.vtu')
    #mlab.pipeline.volume(s)
    #mlab.contour3d(s)
    if show_volume:
        scp = mlab.pipeline.volume(s)
    if show_plane:
        scp = mlab.pipeline.scalar_cut_plane(s, view_controls=True)
    return scp