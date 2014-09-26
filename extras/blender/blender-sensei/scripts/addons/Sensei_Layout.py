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
 "name": "Sensei Layout",  
 "author": "Blender Sensei",  
 "location": "All over.",  
 "description": "Layout tweaks from your friendly neighborhood Blender Sensei.",  
 "wiki_url": "http://blendersensei.com",  
 "category": "Sensei Format"}  

import bpy
from bpy.types import Panel

def main(self,context):
    ob = bpy.context.active_object
    
    #RENDER MENU=============================================
    #use ambient or not
    if self.useAmbient == True:
        bpy.context.scene.world.light_settings.use_ambient_occlusion = True
    else:
        bpy.context.scene.world.light_settings.use_ambient_occlusion = False
        
    #use simplify or not
    if self.useSimplify == True:
        bpy.context.scene.render.use_simplify = True
        try:
            if bpy.data.window_managers["WinMan"].fast_mode == False:
                bpy.data.window_managers["WinMan"].fast_mode = True
        except:
            pass
    else:
        bpy.context.scene.render.use_simplify = False
        try:
            if bpy.data.window_managers["WinMan"].fast_mode == True:
                bpy.data.window_managers["WinMan"].fast_mode = False
        except:
            pass
    
    #CAMERA TRACKING===============================
    if len(self.cTarget) > 0:
        if 'Track To' in ob.constraints:
            ob.constraints['Track To'].target = bpy.data.objects[self.cTarget]
        else:
            wassOff = 0
            if ob.hide == True:
                ob.hide = False
                wasOff = 1
            bpy.ops.object.constraint_add(type='TRACK_TO')
            ob.constraints["Track To"].track_axis = 'TRACK_NEGATIVE_Z'
            ob.constraints["Track To"].up_axis = 'UP_Y'
            ob.constraints['Track To'].target = bpy.data.objects[self.cTarget]
            if wasOff == 1:
                ob.hide = True

#Draw object display into data tab display in properties
class displayInObject(bpy.types.Panel):
    bl_label = "Display"
    bl_space_type = "PROPERTIES"
    bl_region_type = "WINDOW"
    bl_context = "data"

    def draw(self, context):
        layout = self.layout

        obj = context.object
        obj_type = obj.type
        is_geometry = (obj_type in {'MESH', 'CURVE', 'SURFACE', 'META', 'FONT'})
        is_wire = (obj_type in {'CAMERA', 'EMPTY'})
        is_empty_image = (obj_type == 'EMPTY' and obj.empty_draw_type == 'IMAGE')
        is_dupli = (obj.dupli_type != 'NONE')

        split = layout.split()

        col = split.column()
        col.prop(obj, "show_name", text="Name")
        col.prop(obj, "show_axis", text="Axis")
        # Makes no sense for cameras, armatures, etc.!
        # but these settings do apply to dupli instances
        if is_geometry or is_dupli:
            col.prop(obj, "show_wire", text="Wire")
        if obj_type == 'MESH' or is_dupli:
            col.prop(obj, "show_all_edges")

        col = split.column()
        row = col.row()
        row.prop(obj, "show_bounds", text="Bounds")
        sub = row.row()
        sub.active = obj.show_bounds
        sub.prop(obj, "draw_bounds_type", text="")

        if is_geometry:
            col.prop(obj, "show_texture_space", text="Texture Space")
        col.prop(obj, "show_x_ray", text="X-Ray")
        if obj_type == 'MESH' or is_empty_image:
            col.prop(obj, "show_transparent", text="Transparency")

        split = layout.split()

        col = split.column()
        if is_wire:
            # wire objects only use the max. draw type for duplis
            col.active = is_dupli
            col.label(text="Maximum Dupli Draw Type:")
        else:
            col.label(text="Maximum Draw Type:")
        col.prop(obj, "draw_type", text="")

        col = split.column()
        if is_geometry or is_empty_image:
            # Only useful with object having faces/materials...
            col.label(text="Object Color:")
            col.prop(obj, "color", text="")
            

#Sensei Format Render Menu (below camera view)
class renderMenu(bpy.types.Panel):
    bl_label = "Render Menu"
    bl_space_type = "PROPERTIES"
    bl_region_type = "WINDOW"
    bl_context = "render"
    
    def draw(self, context):
        layout = self.layout
        
        #Render and play animation
        context = bpy.context
        wm = context.window_manager
        scene = context.scene
        rd = scene.render
        row = layout.row(align=True)

        row.operator("render.render", text="", icon='RENDER_STILL')
        row.operator("render.render", text="", icon='RENDER_ANIMATION').animation = True
        row.operator("render.play_rendered_anim", text="", icon="PLAY")
        row.separator()
        row.prop(rd, "resolution_percentage", text="")
        row.prop(scene, "frame_step", text="Skip")
        
        row = layout.row(align=True)
        #Use nodes/ambient/simplify
        row.prop(scene, "use_nodes", text="Nodes", icon='BLANK1')
        row.prop(wm, "useAmbient", text="Ambient", icon='BLANK1')
        row.prop(wm, "useSimplify", text="Simplify", icon='BLANK1')
        

#Camera tracking in camera layout
def cameraTracking(self, context):
    layout = self.layout
    context = bpy.context
    scene = context.scene 
    wm = context.window_manager
    
    ob = bpy.context.active_object
    
    #if 'Track To' in ob.constraints:
    row = layout.row()
    row = layout.row()
    row.prop_search(wm, "cTarget", scene, "objects")
        
        
#Animation controls in dopesheet
def animControls(self, context):
    layout = self.layout
    scene = context.scene
    toolsettings = context.tool_settings
    screen = context.screen
    
    #type of keyframes
    row = layout.row(align=True)
    row.prop_search(scene.keying_sets_all, "active", scene, "keying_sets_all", text="")
    #Record keyframes
    row.prop(toolsettings, "use_keyframe_insert_auto", text="", toggle=True)
    
    #Main stop/play animation controls
    row = layout.row(align=True)
    row.operator("screen.frame_jump", text="", icon='REW').end = False
    row.operator("screen.keyframe_jump", text="", icon='PREV_KEYFRAME').next = False
    if not screen.is_animation_playing:
        if scene.sync_mode == 'AUDIO_SYNC' and context.user_preferences.system.audio_device == 'JACK':
            sub = row.row(align=True)
            sub.scale_x = 2.25
            sub.operator("screen.animation_play", text="", icon='PLAY')
        else:
            #row.operator("screen.animation_play", text="", icon='PLAY_REVERSE').reverse = True
            sub = row.row(align=True)
            sub.scale_x = 2.25
            sub.operator("screen.animation_play", text="", icon='PLAY')
    else:
        sub = row.row(align=True)
        sub.scale_x =2.25
        sub.operator("screen.animation_play", text="", icon='PAUSE')
    row.operator("screen.keyframe_jump", text="", icon='NEXT_KEYFRAME').next = True
    row.operator("screen.frame_jump", text="", icon='FF').end = True

    #Start/End keyframes
    row.separator()
    sub = row.row(align=True)
    sub.scale_x = 0.9
    if not scene.use_preview_range:
        sub.prop(scene, "frame_start", text="Start")
        sub.prop(scene, "frame_end", text="End")
    else:
        sub.prop(scene, "frame_preview_start", text="Start")
        sub.prop(scene, "frame_preview_end", text="End")
    row.separator()
    
    #Frames per second
    rd = context.scene.render
    sub = row.row(align=True)
    sub.scale_x = 0.7
    sub.prop(rd, "fps")
    #Current frame
    sub = row.row(align=True)
    sub.scale_x = 0.8
    sub.prop(scene, "frame_current", text="")


#Put find menu in Text Editor Header
def findInHeader(self, context):
        layout = self.layout
        st = context.space_data
        text = st.text
        
        row = layout.row(align=True)
        row.operator("screen.screen_full_area", text = "", 
        icon = "FULLSCREEN_ENTER")
        
        sub = row.row(align=True)
        sub.scale_x = 0.8
        sub.operator("text.find")
        sub = row.row(align=True)
        sub.scale_x = 1
        sub.prop(st, "find_text", text="")

#Console edits  
def expandConsole(self, context):
    userpref = context.user_preferences
    view = userpref.view
    layout = self.layout
    row = layout.row(align=True)
    
    #toggle python tooltips
    row.operator("screen.screen_full_area", text = "", icon = "FULLSCREEN_ENTER")
    row.operator("wm.console_toggle", text="", icon ="CONSOLE")
    row.prop(view, "show_tooltips_python", text ="", icon='QUESTION')
    

#Simulation Controls (Rigid Body Tools)  
def simControl(self, context):
    layout = self.layout
    row = layout.row()
    scene = context.scene
    screen = context.screen
    wm = bpy.context.window_manager
    
    #Bake all cache or free all
    row = layout.row(align=True)
    row.operator("ptcache.bake_all", text = "Bake all")
    row.operator("ptcache.free_bake_all", text ="Free all")
    
    row.operator("screen.frame_jump", text="", icon='FRAME_PREV').end = False
    if not screen.is_animation_playing:
    	if scene.sync_mode == 'AUDIO_SYNC' and context.user_preferences.system.audio_device == 'JACK':
    		row.operator("screen.animation_play", text="", icon='PLAY')
    	else:
    		row.operator("screen.animation_play", text="", icon='PLAY')
    else:
    	row.operator("screen.animation_play", text="", icon='PAUSE')     
    
    row = layout.row()
    #Set as animated
    ob = context.object
    rbo = ob.rigid_body
    if rbo is not None:
        row.prop(rbo, "kinematic", text="Animated", icon="PHYSICS")
     
        
class myBlendProperties(bpy.types.PropertyGroup):
    #RENDER MENU==================================+

    #Use Ambient
    bpy.types.WindowManager.useAmbient = bpy.props.BoolProperty(
    name = "Use Ambient", 
    description = "Use ambient occlusion for realistic lighting",
    update = main  
    )
    
    #Use Simplify
    bpy.types.WindowManager.useSimplify = bpy.props.BoolProperty(
    name = "Use Simplify", 
    description = "Speed up Blender by working in a lower quality mode",
    update = main  
    )
    
    #CAMERA TRACKING===============================
    bpy.types.WindowManager.cTarget = bpy.props.StringProperty(
    name="Camera Target",
    description = "Choose object for camera to follow",
    update = main 
    )


def register():
    bpy.utils.register_module(__name__) 
    bpy.types.DATA_PT_camera_dof.append(cameraTracking)
    bpy.types.DOPESHEET_HT_header.prepend(animControls)
    bpy.types.GRAPH_HT_header.prepend(animControls)
    bpy.types.NLA_HT_header.prepend(animControls)
    bpy.types.CLIP_HT_header.prepend(animControls)
    bpy.types.SEQUENCER_HT_header.prepend(animControls)
    bpy.types.TEXT_HT_header.prepend(findInHeader)
    bpy.types.CONSOLE_HT_header.append(expandConsole)
    bpy.types.VIEW3D_PT_tools_rigid_body.append(simControl)
            
def unregister():
    bpy.utils.unregister_module(__name__) 
    bpy.types.DATA_PT_camera_dof.remove(cameraTracking)
    bpy.types.DOPESHEET_HT_header.remove(animControls)
    bpy.types.GRAPH_HT_header.remove(animControls)
    bpy.types.NLA_HT_header.remove(animControls)
    bpy.types.CLIP_HT_header.remove(animControls)
    bpy.types.SEQUENCER_HT_header.remove(animControls)
    bpy.types.TEXT_HT_header.remove(findInHeader)
    bpy.types.CONSOLE_HT_header.remove(expandConsole)
    bpy.types.VIEW3D_PT_tools_rigid_body.remove(simControl)
    
if __name__ == "__main__":
    register()







































