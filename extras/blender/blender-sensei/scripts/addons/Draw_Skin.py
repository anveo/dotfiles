#==================================================================
#Copyright (C) 6/27/2014  Blender Sensei (Seth Fentress)
#
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.
#====================================================================
#To report a bug or suggest a feature visit:
#blendersensei.com/forums/addons
#VISIT Blendersensei.com for more information.
#SUBSCRIBE at Youtube.com/Blendersensei
#====================================================================


bl_info = {  
 "name": "Draw Skin",  
 "author": "Blender Sensei",  
 "location": "Add Mesh Menu (Shift-A/Mesh/DrawMesh)",  
 "description": "Skin modifier object. Also, allows you to scale(skin resize) with S instead of Ctrl-S",  
 "wiki_url": "http://blendersensei.com",  
 "category": "Sensei Format"}  

import bpy

def add_to_menu(self, context):
    self.layout.operator("object.draw_skin", icon = "LINE_DATA")

class drawSkin(bpy.types.Operator):
    bl_idname = "object.draw_skin"
    bl_label = "Draw Skin"
    bl_description = "Add a skin object."
    
    def execute(self, context):
        #Add a cube and name it Skin
        bpy.ops.mesh.primitive_cube_add()
        ob = bpy.context.active_object
        ob.name = "Skin"
        #Crush into one vert point
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.merge(type='CENTER')
        #Add skin modifier
        bpy.ops.object.modifier_add(type='SKIN')
        skin = bpy.context.object.modifiers["Skin"]
        skin.use_smooth_shade = True

        #Add subsurf
        bpy.ops.object.modifier_add(type='SUBSURF')
        sub = bpy.context.object.modifiers["Subsurf"]
        sub.show_on_cage = True
        sub.levels = 3
        sub.render_levels = 3
        
        #Make verts and edges visible and change to vert selection
        bpy.context.space_data.use_occlude_geometry = False
        bpy.ops.mesh.select_mode(type="VERT")
        
        #Turn on x,y,z symmetry
        bpy.context.object.modifiers["Skin"].use_x_symmetry = True
        bpy.context.object.modifiers["Skin"].use_y_symmetry = True
        bpy.context.object.modifiers["Skin"].use_z_symmetry = True

        return{'FINISHED'}
    
    
#REGISTRATION AND UNREGISTRATION FOR ADDON==================     
def register():
    bpy.utils.register_module(__name__)
    bpy.types.INFO_MT_mesh_add.append(add_to_menu)
    
def unregister():
    bpy.utils.unregister_module(__name__)
    bpy.types.INFO_MT_mesh_add.remove(add_to_menu)
    
if __name__ == "__main__":
    register()