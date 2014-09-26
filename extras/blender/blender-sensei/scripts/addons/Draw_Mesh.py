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
 "name": "Draw Mesh",  
 "author": "Blender Sensei",  
 "location": "Add Mesh Menu (Shift-A/Mesh/DrawMesh)",  
 "description": "An object to use with BSurfaces.",  
 "wiki_url": "http://blendersensei.com",  
 "category": "Sensei Format"}  

import bpy

def add_to_menu(self, context):
    self.layout.operator("object.draw_mesh", icon = "LINE_DATA")

class drawMesh(bpy.types.Operator):
    bl_idname = "object.draw_mesh"
    bl_label = "Draw Mesh"
    bl_description = "Hold V to draw and Shift-V to create mesh. Make sure strokes are in order."
    
    def execute(self, context):
        #Add cube and name it DrawMesh
        bpy.ops.mesh.primitive_cube_add()
        ob = bpy.context.active_object
        ob.name = "DrawMesh"
        
        #Turn on xray and merge cube into single vert
        ob.show_x_ray = True
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.merge(type='CENTER')
        
        #Add solidify modifier
        bpy.ops.object.modifier_add(type='SOLIDIFY')
        sol = bpy.context.object.modifiers["Solidify"]
        sol.thickness = 0.045
        sol.offset = 1
        
        #Add subsurf
        bpy.ops.object.modifier_add(type='SUBSURF')
        sub = bpy.context.object.modifiers["Subsurf"]
        sub.show_on_cage = True
        sub.levels = 1
        sub.render_levels = 3
        
        #Add grease pencil layer and set to surface draw mode.
        bpy.ops.gpencil.data_add()
        bpy.context.active_object.grease_pencil.draw_mode = 'SURFACE'
        
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