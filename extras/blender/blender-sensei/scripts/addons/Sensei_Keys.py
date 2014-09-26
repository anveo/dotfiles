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
#Blendersensei.com/forums/addons
#VISIT Blendersensei.com for more information.
#SUBSCRIBE at Youtube.com/Blendersensei
#====================================================================


bl_info = {  
 "name": "Sensei Keys",  
 "author": "Blender Sensei",  
 "location": "File>User Preferences>Input",  
 "description": "Sensei Format Advanced Hot Keys",  
 "wiki_url": "http://blendersensei.com",  
 "category": "Sensei Format"}  

import bpy  

#Sub Magic: multires and subsurf levels with W key
class subMagic(bpy.types.Operator):  
    bl_idname = "object.sub_magic"  
    bl_label = "Sub Magic"
    bl_options = {'REGISTER', 'UNDO'}   
    
    def execute(self, context):  
        
        #Store variables to save time.
        scene = bpy.context.scene
        selected = bpy.context.selected_objects

        for ob in selected:
            scene.objects.active = ob
            
            #Make sure the object is of type mesh and not a camera or something
            if (ob.type == 'MESH' and 'MULTIRES' not in (mod.type for mod in ob.modifiers)):
            
                try:
                    #Turn subsurf visibility back on automatically if off
                    if bpy.context.object.modifiers["Subsurf"].show_viewport == False:
                        bpy.context.object.modifiers["Subsurf"].show_viewport = True

                    bpy.context.object.modifiers["Subsurf"].levels += 1
                    bpy.context.object.modifiers["Subsurf"].render_levels += 1
                    bpy.ops.object.shade_smooth()
                except:
                    #For object mode give defualt Subsurf Modifier
                    if bpy.context.mode == 'OBJECT':
                        bpy.ops.object.modifier_add(type='SUBSURF')
                        bpy.context.object.modifiers["Subsurf"].show_on_cage = True
                        bpy.context.object.modifiers["Subsurf"].levels = 1
                        bpy.context.object.modifiers["Subsurf"].render_levels = 1
                        bpy.ops.object.shade_smooth()
                        
                    #For sculpt mode give defualt Multires Modifier
                    if bpy.context.mode == 'SCULPT':
                        bpy.ops.object.modifier_add(type='MULTIRES')
                        bpy.ops.object.shade_smooth()
                        
                        #Make sure multires modifier is at top of stack
                        a = 20        
                        while a > 0:
                            a -= 20
                            bpy.ops.object.modifier_move_up(modifier="Multires")
                            
                        #Add smoothing
                        bpy.ops.object.shade_smooth()
                        
            
            #If has subsurf in Sculpt then delete subsurf
            if bpy.context.mode == 'SCULPT':
                ob = bpy.context.scene.objects.active
                subsurf = len([mod for mod in ob.modifiers if mod.type == 'SUBSURF'])
                if subsurf:
                    newLevels = bpy.context.object.modifiers["Subsurf"].levels
                    bpy.ops.object.modifier_remove(modifier="Subsurf")
                    bpy.ops.object.modifier_add(type='MULTIRES')
                    #substitute multires levels with old subsurf levels
                    while newLevels > 1:
                        bpy.ops.object.multires_subdivide(modifier="Multires")
                        bpy.context.object.modifiers["Multires"].levels += 1 
                        newLevels -= 1
                             
            #Check if modifier is multires modifier to increase its levels
            multires = len([mod for mod in ob.modifiers if mod.type == 'MULTIRES']) 
            if multires:
                bpy.ops.object.shade_smooth()
                #Subdivide multires modifier
                bpy.ops.object.multires_subdivide(modifier="Multires")
                #Increase Preview levels of the multires  
                bpy.context.object.modifiers["Multires"].levels += 1
                
                #Change mode back and forth to update object
                myMode = bpy.context.mode
                if myMode == 'OBJECT':
                    bpy.ops.object.mode_set(mode='SCULPT')
                else:
                    bpy.ops.object.mode_set(mode='OBJECT')
                bpy.ops.object.mode_set(mode=myMode)
                            
        return {'FINISHED'}
    
#Array Magic:
class arrayMagic(bpy.types.Operator):  
    bl_idname = "object.array_magic"  
    bl_label = "Array Magic"
    bl_options = {'REGISTER', 'UNDO'}   
    
    def execute(self, context):  
        
        #Store variables to save time.
        scene = bpy.context.scene
        selected = bpy.context.selected_objects

        #The For loop anaylizes every selected object.
        for ob in selected:
            scene.objects.active = ob
            
            if (ob.type == 'MESH'):
            
                try:
                    bpy.context.object.modifiers["Array"].count += 1
                except:
                    bpy.ops.object.modifier_add(type='ARRAY')
                    bpy.context.object.modifiers["Array"].show_on_cage = True
                                
        return {'FINISHED'}


#Quick X: Delete with X key without calling a menu.
#Also delete mesh selection based on selection type automatically.
class quickX(bpy.types.Operator):  
    bl_idname = "object.quick_x"  
    bl_label = "Quick X"
    bl_options = {'REGISTER', 'UNDO'} 
    
    def execute(self, context):
        #Only try to delete objects if in object mode.
        if  bpy.context.mode.startswith('OBJECT'):
            bpy.ops.object.delete()
            bpy.ops.object.select_all(action='INVERT')
            
            for ob in bpy.context.selected_objects:
                bpy.context.scene.objects.active = ob
                
            #Do required returns for the delete operator.
            return {'RUNNING_MODAL', 'CANCELLED', 'FINISHED', 'PASS_THROUGH'}
        
        #Delete mesh selections only if in edit mode.
        if  bpy.context.mode.startswith('EDIT'):
            #Store variables for the different mesh selection types.
            vert_sel, edge_sel, face_sel = bpy.context.tool_settings.mesh_select_mode
            if vert_sel:
                bpy.ops.mesh.delete(type='VERT')
            elif edge_sel:
                bpy.ops.mesh.delete(type='EDGE')
            elif face_sel:
                bpy.ops.mesh.delete(type='FACE')
            return {'RUNNING_MODAL', 'CANCELLED', 'FINISHED', 'PASS_THROUGH'}


#Separate Objects: separate objects by loose parts
class sepObjects(bpy.types.Operator):  
    bl_idname = "object.sep_objects"  
    bl_label = "Separate Objects" 
    bl_options = {'REGISTER', 'UNDO'}  
    
    def execute(self, context):
        scene = bpy.context.scene
        selected = bpy.context.selected_objects

        for ob in selected:
            scene.objects.active = ob
            #apply array modifier if has one
            array = len([mod for mod in ob.modifiers if mod.type == 'ARRAY'])
            if array:
                bpy.ops.object.modifier_apply(apply_as='DATA', modifier="Array")
            bpy.ops.object.mode_set(mode='EDIT')
            bpy.ops.mesh.separate(type='LOOSE')
            bpy.ops.object.mode_set(mode='OBJECT')
            bpy.ops.object.origin_set(type='ORIGIN_CENTER_OF_MASS')
        return {'FINISHED'}
    
#Apply texture: applies drag and drop textures
class sepObjects(bpy.types.Operator):  
    bl_idname = "object.apply_tex"  
    bl_label = "Apply Texture" 
    bl_options = {'REGISTER', 'UNDO'}  
    
    def execute(self, context):
        scene = bpy.context.scene
        selected = bpy.context.selected_objects

        for ob in selected:
            scene.objects.active = ob
            try:
                bpy.ops.view3d.texface_to_material()
                bpy.ops.object.reset_uvs()
                bpy.context.space_data.viewport_shade = 'TEXTURED'
                mat = bpy.context.active_object.active_material
                tSlot = mat.active_texture_index
                mTex = mat.texture_slots[tSlot]
                mTex.use_map_normal = True 
                mTex.bump_method = 'BUMP_MEDIUM_QUALITY'
                mTex.normal_factor = 0.0
            except:
                pass
        return {'FINISHED'}


#Draw Mesh: For fine tuning Bsurfaces
class smoothHelper(bpy.types.Operator):  
    bl_idname = "object.smooth_helper"  
    bl_label = "Smooth Helper" 
    
    def execute(self, context):
        #Object mode for smooth then back to Edit  
        bpy.ops.object.mode_set(mode = 'OBJECT')
        bpy.ops.object.shade_smooth()
        bpy.ops.object.mode_set(mode = 'EDIT')
        
        return {'FINISHED'}

#Simultaneously open tool and properties shelf
class toolShelfQuick(bpy.types.Operator):  
    bl_idname = "object.tool_shelf_quick"  
    bl_label = "Tool Shelf Quick"

    def execute(self, context):
        try:
            bpy.ops.view3d.toolshelf()
            bpy.ops.view3d.properties()
        except:
            pass
        try:
            bpy.ops.node.toolbar()
            bpy.ops.node.properties()
        except:
            pass
        try:
            bpy.ops.clip.tools()
            bpy.ops.clip.properties()
        except:
            pass  
        try:
            bpy.ops.image.toolshelf()
            bpy.ops.image.properties()
        except:
            pass            
        return {'FINISHED'}

#Keyframe insertion
#Insert keyframe and advance timeline
class frameFast(bpy.types.Operator):  
    bl_idname = "object.frame_fast"  
    bl_label = "Keyframe Fast"
    bl_options = {'REGISTER', 'UNDO'}  
    
    def execute(self,context):
        try:
            #Change active keying set for pose mode
            if bpy.context.mode.startswith('POSE'):
                bpy.ops.anim.keying_set_active_set(type='WholeCharacter')
            else:
                bpy.ops.anim.keying_set_active_set(type='LocRotScale')
            #insert keyframe
            bpy.ops.anim.keyframe_insert(type='__ACTIVE__', confirm_success=True)
            #collapse all chanels
            screenType = bpy.context.area.type
            if screenType != 'DOPESHEET_EDITOR':
                bpy.context.area.type = 'DOPESHEET_EDITOR'
            #Turn off summary
            for area in bpy.context.screen.areas:
                if area.type == 'DOPESHEET_EDITOR':
                    area.spaces.active.dopesheet.show_summary = False
                    break
            bpy.ops.anim.channels_collapse()
            #move timeline down 1 sec.
            fps = bpy.context.scene.render.fps
            bpy.ops.screen.frame_offset(delta=fps)
            #Return to original screen type
            bpy.context.area.type = screenType
        except:
            pass
        return{'FINISHED'}
    
class frameFastBack(bpy.types.Operator):  
    bl_idname = "object.frame_fast_back"  
    bl_label = "Keyframe Fast Back"
    
    def execute(self,context):
        #move timeline back to last frame.
        bpy.ops.screen.keyframe_jump(next=False)
        return{'FINISHED'}
    
class insertKey(bpy.types.Operator):  
    bl_idname = "object.insert_key"  
    bl_label = "Insert Keyframe"
    bl_options = {'REGISTER', 'UNDO'}  
    
    def execute(self,context):
        try:
            #Change active keying set for pose mode
            if bpy.context.mode.startswith('POSE'):
                bpy.ops.anim.keying_set_active_set(type='WholeCharacter')
            else:
                bpy.ops.anim.keying_set_active_set(type='LocRotScale')
            #insert keyframe
            bpy.ops.anim.keyframe_insert(type='__ACTIVE__', confirm_success=True)
            #collapse all chanels
            screenType = bpy.context.area.type
            if screenType != 'DOPESHEET_EDITOR':
                bpy.context.area.type = 'DOPESHEET_EDITOR'
            #Turn off summary
            for area in bpy.context.screen.areas:
                if area.type == 'DOPESHEET_EDITOR':
                    area.spaces.active.dopesheet.show_summary = False
                    break
            bpy.ops.anim.channels_collapse()
            #Return to original screen type
            bpy.context.area.type = screenType
        except:
            pass
        return{'FINISHED'}
    

#Toggle viewport shading contextually
class zToggle(bpy.types.Operator):
    bl_idname = "object.z_toggle"
    bl_label = "Z Toggle"
    bl_description = "Toggle between Wireframe and previous viewport shading mode"
    
    def execute(self,context):
        shadeMode = bpy.context.space_data.viewport_shade
        
        if shadeMode != 'WIREFRAME':
            bpy.context.window_manager.shadeState = shadeMode 
            bpy.context.space_data.viewport_shade = 'WIREFRAME'
            print(shadeMode)
        else:
            bpy.context.space_data.viewport_shade = bpy.context.window_manager.shadeState
            print(shadeMode)
        return{'FINISHED'}
    
    
#Toggle pivot center type
class pivotToggle(bpy.types.Operator):
    bl_idname = "object.pivot_toggle"
    bl_label = "Pivot Toggle"
    bl_description = "Toggle pivot center type"
    
    def execute(self,context):
        piv = bpy.context.space_data.pivot_point
        if piv != 'CURSOR':
           bpy.context.space_data.pivot_point = 'CURSOR'
        else:
           bpy.context.space_data.pivot_point = 'MEDIAN_POINT'

        return{'FINISHED'}


#Space toggle Rendered and turn on lights for Blender 2.71 bug
class spaceRender(bpy.types.Operator):
    bl_idname = "object.space_render"
    bl_label = "Space Renter"
    
    def execute(self,context):
        if bpy.context.space_data.viewport_shade == 'RENDERED':
            bpy.context.space_data.viewport_shade = 'TEXTURED'
            for ob in bpy.data.objects:
                if ob.type == 'LAMP':
                    ob.hide = True
        else:  
            bpy.context.space_data.viewport_shade = 'RENDERED'
            for ob in bpy.data.objects:
                if ob.type == 'LAMP':
                    ob.hide = False
        
        return{'FINISHED'}
    

class myBlendProperties(bpy.types.PropertyGroup):

    bpy.types.WindowManager.shadeState = bpy.props.StringProperty(
    name="Viewport Shading State",
    )

   
#REGISTRATION AND UNREGISTRATION FOR ADDON==================
#Create Keymaps list
addon_keymaps = [] 
     
def register():
    #Register all classes
    bpy.utils.register_module(__name__)

    wm = bpy.context.window_manager
    
    #Hotkeys: global 3D View
    km = wm.keyconfigs.addon.keymaps.new(name='3D View', space_type='VIEW_3D')
    kmi = km.keymap_items.new("object.z_toggle", 'Z','PRESS')
    kmi = km.keymap_items.new("object.pivot_toggle", 'SPACE','PRESS', shift = True)
    
    #Hotkeys: Object Mode
    km = wm.keyconfigs.addon.keymaps.new(name='Object Mode', space_type='EMPTY')
    #=====basic object keys
    kmi = km.keymap_items.new("object.sub_magic", 'W','PRESS')
    kmi = km.keymap_items.new("object.array_magic", 'D','PRESS', shift = True)
    kmi = km.keymap_items.new("object.quick_x", 'X','PRESS')
    kmi = km.keymap_items.new("object.sep_objects", 'J','PRESS', alt = True)
    kmi = km.keymap_items.new("object.apply_tex", 'Q','PRESS', shift = True)
    kmi = km.keymap_items.new("object.space_render", 'SPACE','PRESS')
    #====keyframe keys
    kmi = km.keymap_items.new("object.frame_fast", 'F','PRESS')
    kmi = km.keymap_items.new("object.frame_fast_back", 'F','PRESS', ctrl = True)
    kmi = km.keymap_items.new("object.insert_key", 'I','PRESS')
    
    #Hotkeys: Edit Mode
    km = wm.keyconfigs.addon.keymaps.new(name='Mesh', space_type='EMPTY')
    kmi = km.keymap_items.new("object.quick_x", 'X','PRESS')
    kmi = km.keymap_items.new("object.smooth_helper", 'V','RELEASE', shift = True)
    #====overide skin resize to scale with just S
    kmi = km.keymap_items.new("transform.skin_resize", 'S','PRESS')
    
    #Hotkeys: DopeSheet
    km = wm.keyconfigs.addon.keymaps.new(name='Dopesheet', space_type='DOPESHEET_EDITOR')
    #====keyframe keys
    kmi = km.keymap_items.new("object.insert_key", 'I','PRESS')
    kmi = km.keymap_items.new("object.frame_fast", 'F','PRESS')
    kmi = km.keymap_items.new("object.frame_fast_back", 'F','PRESS', ctrl = True)
    
    #Hotkeys: Pose Mode
    km = wm.keyconfigs.addon.keymaps.new(name='Pose', space_type='EMPTY')
    #====keyframe keys
    kmi = km.keymap_items.new("object.insert_key", 'I','PRESS')
    kmi = km.keymap_items.new("object.frame_fast", 'F','PRESS')
    kmi = km.keymap_items.new("object.frame_fast_back", 'F','PRESS', ctrl = True)
    
    #Toolshelf and properties open together
    screenType = ['VIEW_3D','IMAGE_EDITOR','NODE_EDITOR', 'CLIP_EDITOR']
    screenName = ['3D View Generic','Image Generic','Node Generic', 'Clip']
    i = 0
    for st in screenType:
        sn = screenName[i]
        km = wm.keyconfigs.addon.keymaps.new(name= sn, space_type= st)
        kmi = km.keymap_items.new("object.tool_shelf_quick", 'T','PRESS')
        i += 1
        
    #Append keymap
    addon_keymaps.append(km)
            
def unregister():
    #Unregister all classes
    bpy.utils.unregister_module(__name__)
    
    #Unregister keymaps (takes care of all)
    wm = bpy.context.window_manager
    for km in addon_keymaps:
        wm.keyconfigs.addon.keymaps.remove(km)
    del addon_keymaps[:]
    
if __name__ == "__main__":
    register()





