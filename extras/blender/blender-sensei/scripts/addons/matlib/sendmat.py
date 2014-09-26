import bpy
with bpy.data.libraries.load("") as (data_from, data_to):
 data_to.materials = ["aGreatMat"]
mat = bpy.data.materials["aGreatMat"]
mat.use_fake_user=True
bpy.ops.wm.save_mainfile(filepath="C:\\Users\\GhostNinja\\AppData\\Roaming\\Blender Foundation\\Blender\\2.71\\scripts\\addons\\matlib\\materials.blend", check_existing=False, compress=True)
