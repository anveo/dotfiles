import bpy
mat = bpy.data.materials["Brushed Gold"]
mat.name = "tmp"
mat.user_clear()
with bpy.data.libraries.load("C:\\Users\\GhostNinja\\Desktop\\asdf.blend") as (data_from, data_to):
 data_to.materials = ["Brushed Gold"]
mat = bpy.data.materials["Brushed Gold"]
mat.use_fake_user=True
bpy.ops.wm.save_mainfile(filepath="C:\\Users\\GhostNinja\\AppData\\Roaming\\Blender Foundation\\Blender\\2.71\\scripts\\addons\\matlib\\materials.blend", check_existing=False, compress=True)
