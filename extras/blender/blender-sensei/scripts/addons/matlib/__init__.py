# #####BEGIN GPL LICENSE BLOCK #####
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software Foundation,
#  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# #####END GPL LICENSE BLOCK #####

bl_info = {
    "name": "Material Library",
    "author": "Mackraken (mackraken2023@hotmail.com)",
    "version": (0, 5, 5),
    "blender": (2, 6, 6),
    "api": 54697,
    "location": "Properties > Material",
    "description": "Material Library VX (Edited for Sensei Format:Interface by Blender Sensei)",
    "warning": "",
    "wiki_url": "https://sites.google.com/site/aleonserra/home/scripts/matlib-vx",
    "tracker_url": "",
    "category": "System"}


import bpy, os, inspect
from xml.dom import minidom
from xml.dom.minidom import Document


#Paths must be absolute
matlibpath = inspect.getfile(inspect.currentframe())[0:-len("__init__.py")] + "materials.blend"
catspath = inspect.getfile(inspect.currentframe())[0:-len("__init__.py")] + "categories.xml"
matlibpath = matlibpath.replace("\\", "\\\\")


class matlibPropGroup(bpy.types.PropertyGroup):
    category = bpy.props.StringProperty(name="Category")
    lastselected = None
bpy.utils.register_class(matlibPropGroup)

bpy.types.Scene.matlib_index = bpy.props.IntProperty(min = -1, default = -1)
bpy.types.Scene.matlib = bpy.props.CollectionProperty(type=matlibPropGroup)
#??? is this needed?
bpy.props.matlib_link = bpy.props.BoolProperty(name = "matlib_link", default = False)


bpy.types.Scene.matlib_cats_index = bpy.props.IntProperty(min = -1, default = -1)
bpy.types.Scene.matlib_cats = bpy.props.CollectionProperty(type=matlibPropGroup)

def update_index(self, context):
    search = self.matlib_search
    for i, it in enumerate(self.matlib):
        if it.name==search:
            self.matlib_index = i
            break
    
    
bpy.types.Scene.matlib_search = bpy.props.StringProperty(name="matlib_search", update=update_index)

bpy.props.link = False
bpy.props.relpath = False

def createDoc(path):
    file = open(path, "w")
    doc = Document()
    wml = doc.createElement("data")
    doc.appendChild(wml)
    file.write(doc.toprettyxml(indent=" "))
    file.close()            
if os.path.exists(catspath)==False:
    createDoc(catspath)

def saveDoc(path, doc):
    file = open(path, "w")
    file.write(doc.toprettyxml(indent="  "))
    file.close()
    
    #clean xml
    file = open(path)
    text = ""
    line = file.readline()
    
    while (line!=""):
        line = file.readline()
        if line.find("<")>-1:
            text+=line
    file.close()
    file = open(path, "w")
    file.write(text)
    file.close()

def deleteNode(c):
    parent = c.parentNode
    parent.removeChild(c)
    
def listmaterials(libpath):
    list = []
    with bpy.data.libraries.load(libpath) as (data_from, data_to):
        for mat in data_from.materials:
            list.append(mat)
    return list

def sendmat(name):
    import subprocess
    print("-----------------------")
    
    thispath = bpy.data.filepath
    bin = bpy.app.binary_path

    bin = bin.replace("\\", "\\\\")
    thispath = thispath.replace("\\", "\\\\")

    nl = "\n"
    tab = " "
    list = listmaterials(matlibpath)
            
    add = True
    for it in list:
        if it == name:
            add = False
            break
        
    bpy.ops.wm.save_mainfile(check_existing=True)
    
    if add:
        # Add material
        print("Add material "+name)
        scriptpath = inspect.getfile(inspect.currentframe())[0:-len("__init__.py")] + "sendmat.py"
        scriptpath = scriptpath.replace("\\", "\\\\")

        file = open(scriptpath, "w")
        file.write("import bpy"+nl)
        file.write('with bpy.data.libraries.load("'+thispath+'") as (data_from, data_to):'+nl)
        file.write(tab+'data_to.materials = ["'+name+'"]'+nl)
        file.write('mat = bpy.data.materials["'+name+'"]'+nl)
        file.write("mat.use_fake_user=True"+nl)
        file.write('bpy.ops.wm.save_mainfile(filepath="'+matlibpath+'", check_existing=False, compress=True)'+nl)
        file.close()

        subprocess.call([bin, "-b", matlibpath, "-P", scriptpath]) 

        print(bin)
        print(thispath)
        print(scriptpath)
        
    else:
        # overwrite material
        scriptpath = inspect.getfile(inspect.currentframe())[0:-len("__init__.py")] + "overwmat.py"
        scriptpath = scriptpath.replace("\\", "\\\\")
        
        print("sendmat: Exists, Overwrite"+name)
        print(thispath)
        file = open(scriptpath, "w")
        file.write("import bpy"+nl)
        file.write('mat = bpy.data.materials["'+name+'"]'+nl)
        file.write('mat.name = "tmp"'+nl)
        file.write('mat.user_clear()'+nl)
        file.write('with bpy.data.libraries.load("'+thispath+'") as (data_from, data_to):'+nl)
        file.write(tab+'data_to.materials = ["'+name+'"]'+nl)
        file.write('mat = bpy.data.materials["'+name+'"]'+nl)
        file.write("mat.use_fake_user=True"+nl)
        file.write('bpy.ops.wm.save_mainfile(filepath="'+matlibpath+'", check_existing=False, compress=True)'+nl)
        file.close()

        subprocess.call([bin, "-b", matlibpath, "-P", scriptpath])
        
    return add
    

def getmat(name, link=False, rel=False):
    with bpy.data.libraries.load(matlibpath, link, rel) as (data_from, data_to):
        data_to.materials = [name]
        if link:
            print(name + " linked.")
        else:
            print(name + " appended.")

def removemat(name):
    import subprocess

    bin = bpy.app.binary_path
    bin = bin.replace("\\", "\\\\")
    
    scriptpath = bpy.app.binary_path[0:-len("blender.exe")] + "removemat.py"
    scriptpath = scriptpath.replace("\\", "\\\\")
     
    thispath = bpy.data.filepath
    thispath = thispath.replace("\\", "\\\\")
    
    nl = "\n"
    tab = " "

    list = listmaterials(matlibpath)
    #check if exists 
    remove = False
    for it in list:
        print(it)
        if it == name:
            remove = True
            break
    
    if remove:
        
        file = open(scriptpath, "w")
        file.write("import bpy"+nl)
        file.write('mat = bpy.data.materials["'+name+'"]'+nl)
        file.write("mat.use_fake_user=False"+nl)
        file.write("mat.user_clear()"+nl)   
        file.write('bpy.ops.wm.save_mainfile(filepath="'+matlibpath+'", check_existing=False, compress=True)'+nl)
        file.close()

        subprocess.call([bin, "-b", matlibpath, "-P", scriptpath])

### Categories Block    
def reloadcats(context):
    if os.path.exists(catspath)==False:
        createDoc(catspath)
    
    doc = minidom.parse(catspath)
    wml = doc.firstChild
    
    catstext = []
    for catnode in wml.childNodes:
        if catnode.nodeType!=3:
            catstext.append(catnode.attributes['name'].value)

    catstext.sort()
    catstext.insert(0, "All")
    
    scn = context.scene
    cats = scn.matlib_cats
    
    for it in cats:
        cats.remove(0)
    
    for it in catstext:
        item = cats.add()
        item.name = it

        
def reloadlib(context):
    print("reloading library")
    
    matlib = context.scene.matlib
    matlib_cats = context.scene.matlib_cats
    list = listmaterials(matlibpath)
    reloadcats(context)
    
    context.scene.matlib_index = -1
    for it in matlib:
        matlib.remove(0)
    
    doc = minidom.parse(catspath)
    wml = doc.firstChild
    
    
    list.sort()
    print("--------------")
    for it in list:
        
        cat=""
        
        for xmlcat in wml.childNodes:
            if xmlcat.nodeType!=3:
                for xmlmat in xmlcat.childNodes:
                    if xmlmat.nodeType!=3:
                        matname = xmlmat.attributes['name'].value
                        if matname==it:
                            cat = xmlcat.attributes['name'].value
                            break

        item = matlib.add()
        item.name = it
        item.category = cat
        
    #reload categories
    return "Reloading libary"


class matlibDialogOperator(bpy.types.Operator):
    bl_idname = "matlib.cats_dialog"
    bl_label = "Add Category"

    my_string = bpy.props.StringProperty(name="Name")

    def execute(self, context):
        print(self.my_string)
        msg=""
        msgtype={"ERROR"}
        print("--------------------")
        tmpname = self.my_string
        
        #remove initial spaces
        for car in tmpname:
            if car==" ":
                tmpname=tmpname[1::]
            else:
                break
            
        #pretty cat
        name = tmpname.capitalize()
        print(name)
        
        doc = minidom.parse(catspath)
        wml = doc.firstChild
        
        #fix with getelements
        doname = 1
        for catnode in wml.childNodes:
            if catnode.nodeType!=3:
                catname = catnode.attributes['name'].value
                if catname == name:
                    doname=0
                    break

        if doname:
            node = doc.createElement("category")
            node.setAttribute("name", name)
            wml.appendChild(node)
            saveDoc(catspath, doc)
            reloadcats(context)
        else:
            print(name +" already exists")
            
        return {'FINISHED'}

    def invoke(self, context, event):
        wm = context.window_manager
        return wm.invoke_props_dialog(self)

    
class matlibcatsAddRemoveOperator(bpy.types.Operator):
    '''Categories operators'''
    bl_idname = "matlib.cats_add_operator"
    bl_label = "Add/Remove Categories"
    bl_description = "View/Select material category. Delete/Add new category"
    
    add = bpy.props.StringProperty()
    
    @classmethod
    def poll(cls, context):
        return context.active_object != None

    def draw(self, context):
        print(self.add)
        
    def execute(self, context):
        add=self.add
        if add=="ADD":
            print("adding")
            bpy.ops.matlib.cats_dialog('INVOKE_DEFAULT')
        elif add=="REMOVE":
            print("removing")
            
            scn = context.scene
            cats = scn.matlib_cats
            index = scn.matlib_cats_index
            
            #any than "All"
            if index>0:
                
                name =cats[index].name
                
                #XML VERSION
                doc = minidom.parse(catspath)
                wml = doc.firstChild
                
                for cat in wml.childNodes:
                    if cat.nodeType!=3:
                        catname=cat.attributes['name'].value
                        if catname==name:
                            deleteNode(cat)
                            saveDoc(catspath, doc)
                            scn.matlib_cats_index -=1
                            cats.remove(index)
                            break
            
        elif add == "SET":
            #set categories
            scn = context.scene
            matlib = scn.matlib
            matindex = scn.matlib_index
            
            cats = scn.matlib_cats
            index = scn.matlib_cats_index
            
            
            if index>0:
                catname = cats[index].name
                matlib[matindex].category= catname
                matname = matlib[matindex].name
                
                #save xml
                doc = minidom.parse(catspath)
                wml = doc.firstChild
                
                for xmlcat in wml.childNodes:
                    if xmlcat.nodeType!=3:
                        xmlcatname=xmlcat.attributes['name'].value
                        for xmlmat in xmlcat.childNodes:
                            if xmlmat.nodeType!=3:
                                xmlmatname = xmlmat.attributes['name'].value
                                if xmlmatname==matname:
                                    deleteNode(xmlmat)
                                    
                        if xmlcatname==catname:
                            newmat=doc.createElement("material")
                            newmat.setAttribute("name", matname)
                            xmlcat.appendChild(newmat)
                        
                saveDoc(catspath, doc)
    
        elif add == "FILTER":
            
            scn = context.scene
            
            cats = scn.matlib_cats
            index = scn.matlib_cats_index
            scn.matlib_search=""
            matlib = scn.matlib
            matindex = scn.matlib_index
            reloadlib(context)
            
            if index==0:
                print("Show All")
                
                
            elif index>0:
                print("---------------------")  
                scn.matlib_index=-1
                
                catname = cats[index].name
                items = []
                for i, it in enumerate(matlib):

                    if it.category==catname:
                        print(it.name)
                        items.append([it.name, it.category])

                for it in matlib:
                    matlib.remove(0)
                    
                for it in items:
                    item = matlib.add()
                    item.name = it[0]
                    item.category=it[1]
                        
                print("Show "+ catname)
                
        return {'FINISHED'}

class matlibcatsSelectOperator(bpy.types.Operator):
    '''Categories'''
    bl_idname = "matlib.cats_select_operator"
    bl_label = "Select Category"

    name = bpy.props.StringProperty()
    add = bpy.props.IntProperty(default=-1, min=-1)
    @classmethod
    def poll(cls, context):
        return context.active_object != None

    def execute(self, context):
        
        scn = context.scene
        scn.matlib_cats_index=self.add
        
        cats = scn.matlib_cats
        catname = cats[self.add].name

        if self.add==0:
            reloadlib(context)
            
        print(self.add, catname)
        return {'FINISHED'}


class matlibcatsMenu(bpy.types.Menu):
    bl_idname = "matlib.cats_menu"
    bl_label = "Categories Menu"

    def draw(self, context):
        scn = context.scene
        
        layout = self.layout
        cats = scn.matlib_cats
        catindex = scn.matlib_cats_index
        for i, cat in enumerate(cats):
            layout.operator("matlib.cats_select_operator", text=cat.name).add=i
            
    
class matlibvxOperator(bpy.types.Operator):
    bl_label = "matlib operators"
    bl_idname = "matlib.add_remove_matlib"
    bl_description = "Save | Delete | Use Material | Reload Library"

    add = bpy.props.StringProperty()
    
    def invoke(self, context, event):
        add = self.add
        scn = context.scene

        mat = context.active_object.active_material  
        matlib = scn.matlib
        index = scn.matlib_index
        msg = ""
        msgtype = {"INFO"}

        #check files
        if os.path.exists(matlibpath)==False:
            add = -1
            msg = matlibpath+" doesnt exists!. Please create materials.blend at that path."
            msgtype={"WARNING"}

        if add=="ADD":
            ### Add material
            print("Creating " + mat.name)
            self.report({'INFO'}, "NOTICE: To save materials in the material library, your Blender file must be saved at least once.")
            send = sendmat(mat.name)
            if send:
                item = matlib.add()
                item.name = mat.name
                

        elif add=="REMOVE":
            ### remove items
            print(len(matlib))
            if len(matlib)>0:
                print("Removing "+matlib[index].name)
                removemat(matlib[index].name)
                matlib.remove(index)
        
        elif add == "RELOAD":
            ### reload library
            msg = reloadlib(context)

        elif add=="APPLY":
            ### apply material
            if len(matlib)>0 and index>-1:
                matl = matlib[index].name

                if context.object.name=="Material_Preview":
                    msg = "Apply is disabled for Material Preview Object"
                else:
    
                    mat = None
                    #search into current libraries 
                    for lib in bpy.data.libraries:
                        if bpy.path.abspath(lib.filepath) == matlibpath:
                            for id in lib.users_id:
                                if id.bl_rna.identifier=="Material" and id.name==matl:
                                    mat = id
                                    break
                
                    if mat==None:
                        nmats = len(bpy.data.materials)
                        getmat(matl)
                        
                        if nmats == len(bpy.data.materials):
                            msg = matl+" doesnt exists at Library."
                            msgtype="ERROR"
                                
                        else:
                            for mat in reversed(bpy.data.materials):
                                if mat.library==None and mat.name[0:len(matl)]==matl:
                                    break

                            obj = bpy.context.object
                            matindex = obj.active_material_index
                            mat.use_fake_user=False #line must be duplicated
                            obj.material_slots[matindex].material=None  
                            
                            obj.material_slots[matindex].material = mat
                            
                            mat.use_fake_user=False
                            
                            bpy.ops.object.make_single_user(type='SELECTED_OBJECTS',
                                                    object=False,
                                                    obdata=False,
                                                    material=True,
                                                    texture=True,
                                                    animation=False)
                                                    
                            print("importado correctamente ", mat, mat.use_fake_user)
                    else:

                        obj = bpy.context.object
                        
                        matindex = obj.active_material_index
                        mat.use_fake_user=False #line must be duplicated
                        obj.material_slots[matindex].material=None  
                        obj.material_slots[matindex].material = mat
                        mat.use_fake_user=False
                        
                        bpy.ops.object.make_local(type="SELECT_OBDATA_MATERIAL")
                
        return {'FINISHED'}


class matlibvxPanel(bpy.types.Panel):
    bl_label = "Material Library"
    bl_space_type = "PROPERTIES"
    bl_region_type = "WINDOW"
    bl_context = "material"
    
    @classmethod
    def poll(self, context):
        return context.active_object.active_material!=None

    def draw(self, context):
        layout = self.layout
        scn = bpy.context.scene

        entry = ""
        nmats = len(scn.matlib)
        index = scn.matlib_index
        #Mat names
        if nmats >0:
            if index<nmats:
                entry = scn.matlib[scn.matlib_index].category
                entry = entry.upper()
        #Category names
        cats = scn.matlib_cats
        catindex = scn.matlib_cats_index
        if catindex==-1 or len(cats)<=1:
            name="Categories"
        else:
            name = cats[catindex].name
            

        box = layout.box()
        sub = box.row(True)
        sub.operator("matlib.cats_add_operator", icon="RESTRICT_VIEW_OFF", 
        text="View Category").add="FILTER"
        
        sub.menu("matlib.cats_menu",text=name)
        sub = box.row(True)
        sub.scale_x = 0.9
        sub.operator("matlib.cats_add_operator", icon="ZOOMOUT", text="").add="REMOVE"
        sub.operator("matlib.cats_add_operator", icon="ZOOMIN", text="").add="ADD"
        sub.label(entry)
        sub.operator("matlib.cats_add_operator", icon="FILE_PARENT", 
        text="Add To Category").add="SET"
        
        box = layout.box()
        sub = box.row(True)
        sub.operator("matlib.add_remove_matlib", icon="ZOOMIN", text="Save").add = "ADD"
        sub.operator("matlib.add_remove_matlib", icon="ZOOMOUT", text="Delete").add = "REMOVE"
        sub.operator("matlib.add_remove_matlib", icon="MATERIAL", text="Use").add = "APPLY"
        sub.separator()
        sub.operator("matlib.add_remove_matlib", icon="FILE_REFRESH", text="").add = "RELOAD"
        sub = box.row()
        sub.template_list("UI_UL_list", "  ", scn, "matlib", scn, "matlib_index")
        

def register():
    bpy.utils.register_module(__name__) 
 
def unregister():
    bpy.utils.unregister_module(__name__) 
    
if __name__ == "__main__":
    register()

























