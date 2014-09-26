import bpy
user_preferences = bpy.context.user_preferences

user_preferences.edit.use_drag_immediately = False
user_preferences.edit.use_insertkey_xyz_to_rgb = True
user_preferences.inputs.invert_mouse_zoom = False
user_preferences.inputs.select_mouse = 'LEFT'
user_preferences.inputs.use_emulate_numpad = True
user_preferences.inputs.use_mouse_continuous = True
user_preferences.inputs.use_mouse_emulate_3_button = False
user_preferences.inputs.view_rotate_method = 'TURNTABLE'
user_preferences.inputs.view_zoom_axis = 'VERTICAL'
user_preferences.inputs.view_zoom_method = 'DOLLY'
