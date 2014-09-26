'''
SCRIPT EXAMPLE BY: BLENDERSENSEI
VISIT: BLENDERSENSEI.com
SUBSCRIVE AT: Youtube.com/Blendersensei

If you're creating your own buttons (and not just using pre-built in Blender
operators like "mesh.primitive_cube_add" then you'll likely need to store
the values of these buttons into property variables. These variables can all
be declared into a special class called "PropertyGroup" which takes care of
registering and unregistering them for use in your script or as an addon. Make
sure your PropertyGroup class is placed just above the #REGISTRATION bits other-
-wise errors may occur.

Common property types are integer, float, string and boolean. Integer is
for basic whole numbers. Say you had a button that made cubes but you 
wanted the user to be able to decide how many, you would use an integer. Float
is decimal numbers, same concept basically. String stores words and what have 
you inside of "". Boolean properties use states of True or False also represented 
by 1 or 0. These are good for buttons you wish to use as switches.

Sometimes you want buttons that set values, later to be acted upon, taking my
example from earlier, you could have an input button (the property) where you 
set the ammount of cubes you want and then a button that actually makes them. 
Other times you want the buttons to automatically do stuff when they're changed. 
To do this, you can include update = "mySuperCoolFunction" in your property 
which will then take that input data and send it straight to a function you 
create outside of that class to be acted upon. 

You can copy and paste the different types of property variables outside
of the tripple quote marks near the bottom and into the working space of the 
myBlendProperties class to create your own. Property names can be like this 
"i_am_a_property" or like this "iAmAProperty". #This script draws shape 
adding buttons into the Create tab of the Tool shelf. Click "Run Script" near
the bottom to observe.
'''  

import bpy


#Define main cone adding function
def coneAdderMain(self,context):
    #Grab the value of cones supplied by the user
    numberOfConesAuto = bpy.context.window_manager.numberOfConesAuto
    
    #The for loop will repeat the actions indented inside of it
    #the ammount of times that numberOfConesAuto has been set to
    for i in range(numberOfConesAuto):
        #Store 3D Cursor location
        cursorX = bpy.context.scene.cursor_location.x
        cursorY = bpy.context.scene.cursor_location.y
        cursorZ = bpy.context.scene.cursor_location.z
        
        #Create new cone
        bpy.ops.mesh.primitive_cone_add()
        
        #Move object to new x,y,z positions
        bpy.context.object.location[0] = cursorX + (i*3)
        bpy.context.object.location[1] = cursorY
        bpy.context.object.location[2] = cursorZ
    
    #return the property value back to zero to avoid badness
    bpy.context.window_manager.numberOfConesAuto = 0
    
    
#Add class for operator to add cubes
class addTheCubes(bpy.types.Operator):
    bl_idname="object.add_the_cubes"
    bl_label="Add The Cubes"
    bl_description="Add the cubes now"
    
    def execute(self,context):
        #Tidy up variable names for convenience
        wm = bpy.context.window_manager
        #Now store the value of the property we created into numberOfCubes
        numberOfCubes = bpy.context.window_manager.numberOfCubes
        
        #The for loop will repeat the actions indented inside of it
        #the ammount of times that numberOfCubes has been set to
        for i in range(numberOfCubes):
            #Store 3D Cursor location
            cursorX = bpy.context.scene.cursor_location.x
            cursorY = bpy.context.scene.cursor_location.y
            cursorZ = bpy.context.scene.cursor_location.z
            
            #Create new cube
            bpy.ops.mesh.primitive_cube_add()
            
            #Move object to new x,y,z positions
            bpy.context.object.location[0] = cursorX + (i*3)
            bpy.context.object.location[1] = cursorY
            bpy.context.object.location[2] = cursorZ
        
        return{'FINISHED'} 
        #Functions nestled in a class that are not of the type "draw"
        #need this at the end (and sometimes other stuff)



#This class just draws our buttons into the panel
class buttonsDrawer(bpy.types.Panel):
    bl_label = "Stuff Adder Panel" #Title 
    bl_space_type = "VIEW_3D" #Puts it into the basic 3D View
    bl_region_type = "TOOLS" #Where in the 3D View? Tool properties
    bl_category = "Create" #Which tab to draw the button into
    
    def draw(self, context): #draw our properties and buttons
        
        #Tidy up variable names for convenience
        wm = context.window_manager
        layout = self.layout
        row = layout.row()
        
        #CUBE ADDER================================
        row.label("Cube Adder:")#Add a sub title
        row = layout.row() #Add space between buttons
        
        #Now draw the property into the panel.
        row.prop(wm, "numberOfCubes")
        row = layout.row() #Add space between buttons
        #Now draw the actual button to create the cubes
        row.operator("object.add_the_cubes")
        row = layout.row()
        row = layout.row()
        
        
        #AUTO CONE ADDER================================
        row.label("Auto Cone Adder:")#Add a sub title
        row = layout.row() #Add space between buttons
        
        #Now draw the property into the panel.
        row.prop(wm, "numberOfConesAuto", text = "Create Cones")
        #We can create custom text for our properties or operators by adding
        #a coma followed by text = ""
        
         

#This class stores all of our behind the scenes properties.
class myBlendProperties(bpy.types.PropertyGroup):
    
    #Simple integer property
    bpy.types.WindowManager.numberOfCubes = bpy.props.IntProperty(
    name="Number of Cubes",
    description="The number of cubes to add",
    default = 10,
    min = 0 #Can't make negative cubes, so we add a minimum val of 0 
    )
    
    #Simple integer property that will auto update
    bpy.types.WindowManager.numberOfConesAuto = bpy.props.IntProperty(
    name="Number of Cones Auto",
    description="The number of cones to instantly add",
    default = 0,
    min = 0, #Can't make negative ammount of cones, so add a minimum val of 0 
    update = coneAdderMain
    )
    
    '''
    #Property templates you can copy and paste
    
    #Float (decimal number) property
    bpy.types.WindowManager.myFloatProp = bpy.props.FloatProperty(
    name="My Float Property", 
    #description = "whatever",
    #default = 0, 
    #min = 0,
    #precision = 0,
    #step = 0
    #update = #put a function here you would like automatically executed
    #when this value is changed by the user. 
    )
    
    #Integer (whole number) property
    bpy.types.WindowManager.myIntProp = bpy.props.IntProperty(
    name="My Integer Property",
    #description = "whatever",
    #default = 0, 
    #subtype="PERCENTAGE", min=0, max=100, #for turning into a percent
    #update = #put a function here you would like automatically executed
    #when this value is changed by the user. 
    )
    
    #String (words, text, letters etc...) property
    bpy.types.WindowManager.myStringProp = bpy.props.StringProperty(
    name="My String Property",
    #description = "whatever",
    #default = "Pancakes", 
    #update = #put a function here you would like automatically executed
    #when this value is changed by the user. 
    )
            
    #Boolean (true or false) property
    bpy.types.WindowManager.myBoolProp = bpy.props.BoolProperty(
    name = "My Boolean Property", 
    #description = "whatever",
    #default = False
    #update = #put a function here you would like automatically executed
    #when this value is changed by the user 
    )
    '''

#REGISTRATION======================================
def register():
    bpy.utils.register_module(__name__) 
 
def unregister():
    bpy.utils.unregister_module(__name__) 
    
if __name__ == "__main__":
    register()