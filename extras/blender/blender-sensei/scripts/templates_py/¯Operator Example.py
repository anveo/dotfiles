'''
SCRIPT EXAMPLE BY: BLENDERSENSEI
VISIT: BLENDERSENSEI.com
SUBSCRIVE AT: Youtube.com/Blendersensei

This is a simple operator example. The operator is defined and created within the
class, so it follows that the class and operator would be named the same. The
name of the class can use lower or uppercase letters but the operator ID name,
"bl_idname" must only use lowercase so _ is usually used to separate the words.
Prefacing the operator with "object." is the most common option. "bl_label" is how 
the title of this operator will appear to the user. Following these standards you 
can name the class, bl_idname (which is the operator name), and the bl_label, 
whatever you wish. You can also create multiple classes like this for your script 
to run.

You will see examples of code where people register/unregister their classes at the
bottom of their script. For the most part this is unnecessary. Everything 
under the '#REGISTRATION' line takes care of registering and unregistering your 
classes whether running your script from here (Hit the "Run Script" Button) or if 
you create an addon, though in some cases you will need to register special classes.

"def" is how Python declairs a new function. The function here, named "execute", is 
a defualt way of executing the code when the class or operator is called. Once you 
fill the area '#Code goes here' with your own commands and hit the "Run Script"
button, you can hit Space (Ctrl-Space Sensei Format) and type in the name of the 
operator or operators to use them. 
'''

import bpy

class myOperator(bpy.types.Operator):
    bl_idname = "object.my_operator"
    bl_label = "My Operator"
    
    def execute(self,context):
        #Your code goes here========================
        
        #Makes a cube.
        bpy.ops.mesh.primitive_cube_add() 
        
        #End of your code===========================
        return{'FINISHED'}


#REGISTRATION======================================
def register():
    bpy.utils.register_module(__name__) 
 
def unregister():
    bpy.utils.unregister_module(__name__) 
    
if __name__ == "__main__":
    register()
