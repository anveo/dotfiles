'''
SCRIPT EXAMPLE BY: BLENDERSENSEI
VISIT: BLENDERSENSEI.com
SUBSCRIVE AT: Youtube.com/Blendersensei

Once you hit 'Run Script' button, you can press Space (ctrl-space Sensei Format) 
and type "My Super Cool Operator" to run it. See the bottom of this script if you 
wish to map it to a hotkey instead.
'''

import bpy

class mySuperCoolClass(bpy.types.Operator): #Most common use of class
    bl_idname = "object.my_super_cool_operator" #how we'll reference the operator
    bl_label = "My Super Cool Operator" #What the user will see
    bl_description = "I make a big smooth monkey head" #Mouseover info
    
    def execute(self,context): #generic function that operator will run
        
        #Your code goes here========================
        bpy.ops.mesh.primitive_monkey_add() #add a monkey head
        bpy.ops.transform.resize(value=(3, 3, 3)) #make monkey head big
        bpy.ops.object.modifier_add(type='SUBSURF') #add subsurf modifier
        bpy.ops.object.shade_smooth() #turn on smooth shading
        
        #send a message to info header bar
        self.report({'INFO'}, "Blender made a giant monkey head.")
        #End of your code===========================
        
        return{'FINISHED'} #Common for execute functions within classes
    

#Registration======================================
#Create Keymaps list
addon_keymaps = []

def register():
    bpy.utils.register_module(__name__) 
    
    #To map your operator to a hotkey erase all the green sets of three quote marks
    #starting at line 90 and below and change the 'W' to whatever key you want. The
    #hotkey you choose needs to be capitalized. If you want it to include shift, alt, 
    #etc... then do it like this , shift = True making sure you add a comma before each 
    #added element. For a complete list of hotkey options click on Help/Python API 
    #Reference and search keymaps.new once you're directed to the site.
    
    #Space type reference (Where keys work). For name types see File/User Prefs/Input.
    #EMPTY’, ‘VIEW_3D’, ‘GRAPH_EDITOR’, ‘OUTLINER’, ‘PROPERTIES’, ‘FILE_BROWSER’,
    #‘IMAGE_EDITOR’, ‘INFO’, ‘SEQUENCE_EDITOR’, ‘TEXT_EDITOR’, ‘DOPESHEET_EDITOR’, 
    #‘NLA_EDITOR’, ‘TIMELINE’, ‘NODE_EDITOR’, ‘LOGIC_EDITOR’, ‘CONSOLE’, ‘USER_PREFERENCES’

    '''
    wm = bpy.context.window_manager
    
    #Define the name and space type hotkeys will use with km line
    km = wm.keyconfigs.addon.keymaps.new(name='Object Mode', space_type='EMPTY')
    #hotkeys use the kmi line. Choose your operator and hotkey
    kmi = km.keymap_items.new("object.my_super_cool_operator", 'W','PRESS')
    
    #Append keymap
    addon_keymaps.append(km)
    '''
            
def unregister():
    bpy.utils.unregister_module(__name__) 
    
    '''
    #Unregister keymaps
    wm = bpy.context.window_manager
    for km in addon_keymaps:
        wm.keyconfigs.addon.keymaps.remove(km)
    del addon_keymaps[:]
    '''
    
if __name__ == "__main__":
    register()

