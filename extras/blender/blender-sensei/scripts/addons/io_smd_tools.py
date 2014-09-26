# ##### BEGIN GPL LICENSE BLOCK #####
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software Foundation,
#  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# ##### END GPL LICENSE BLOCK #####

# DISABLE SmdToolsUpdate IF YOU MAKE THIRD-PARTY CHANGES TO THE SCRIPT!

bl_info = {
	"name": "SMD\DMX Tools",
	"author": "Tom Edwards, EasyPickins",
	"version": (1, 6, 5),
	"blender": (2, 66, 0),
	"api": 54697,
	"category": "Import-Export",
	"location": "File > Import/Export, Scene properties",
	"wiki_url": "http://code.google.com/p/blender-smd/",
	"tracker_url": "http://code.google.com/p/blender-smd/issues/list",
	"description": "Importer and exporter for Valve Software's Source Engine. Supports SMD\VTA, DMX and QC."}

import math, os, time, bpy, bmesh, random, mathutils, re, struct, subprocess, io, datamodel, collections
from bpy import ops
from bpy.props import *
from struct import unpack,calcsize
from mathutils import *
from math import *
from bpy.app.handlers import persistent

intsize = calcsize("i")
floatsize = calcsize("f")

rx90 = Matrix.Rotation(radians(90),4,'X')
ry90 = Matrix.Rotation(radians(90),4,'Y')
rz90 = Matrix.Rotation(radians(90),4,'Z')
ryz90 = ry90 * rz90

rx90n = Matrix.Rotation(radians(-90),4,'X')
ry90n = Matrix.Rotation(radians(-90),4,'Y')
rz90n = Matrix.Rotation(radians(-90),4,'Z')

mat_BlenderToSMD = ry90 * rz90 # for legacy support only

epsilon = Vector([0.0001] * 3)

# SMD types
REF = 0x1 # $body, $model, $bodygroup->studio (if before a $body or $model)
REF_ADD = 0x2 # $bodygroup, $lod->replacemodel
PHYS = 0x3 # $collisionmesh, $collisionjoints
ANIM = 0x4 # $sequence, $animation
ANIM_SOLO = 0x5 # for importing animations to scenes without an existing armature
FLEX = 0x6 # $model VTA

mesh_compatible = [ 'MESH', 'TEXT', 'FONT', 'SURFACE', 'META', 'CURVE' ]
exportable_types = mesh_compatible[:]
exportable_types.append('ARMATURE')
shape_types = ['MESH' , 'SURFACE']

src_branches = (
('CUSTOM','Custom SDK',''),
('orangebox','Source MP',''),
('source2009','Source 2009',''),
('source2007','Source 2007',''),
('ep1','Source 2006',''),
('left 4 dead 2','Left 4 Dead 2',''),
('left 4 dead','Left 4 Dead',''),
('alien swarm','Alien Swarm',''),
('portal 2','Portal 2',''),
('Counter-Strike Global Offensive','Counter-Strike: GO',''),
('SourceFilmmaker', 'Source Filmmaker', '')
)

# [encoding,format]
dmx_versions = {
'ep1':[0,0],
'source2007':[2,1],
'source2009':[2,1],
'left 4 dead':[5,15],
'left 4 dead 2':[5,15],
'alien swarm':[5,18],
'orangebox':[5,18], # aka Source MP
'portal 2':[5,18],
'SourceFilmmaker':[5,18],
'Counter-Strike Global Offensive':[5,18]
}

global vproject
vproject = os.getenv('vproject')
if vproject: vproject = os.path.basename(vproject)

# I hate Python's var redefinition habits
class smd_info:
	def __init__(self):
		self.isDMX = 0 # version number, or 0 for SMD
		self.a = None # Armature object
		self.amod = {} # Armature modifiers
		self.m = None # Mesh datablock
		self.shapes = None
		self.g = None # Group being exported
		self.file = None
		self.jobName = None
		self.jobType = None
		self.startTime = 0
		self.uiTime = 0
		self.started_in_editmode = None
		self.append = False
		self.in_block_comment = False
		self.upAxis = bpy.context.scene.smd_up_axis
		self.rotMode = 'EULER' # for creating keyframes during import
		self.materials_used = set() # printed to the console for users' benefit

		# DMX stuff
		self.attachments = []
		self.meshes = []
		self.parent_chain = []
		self.dmxShapes = collections.defaultdict(list)

		self.frameData = []

		self.bakeInfo = []

		# boneIDs contains the ID-to-name mapping of *this* SMD's bones.
		# - Key: integer ID
		# - Value: bone name (storing object itself is not safe)
		self.boneIDs = {}
		self.boneNameToID = {} # for convenience during export
		self.phantomParentIDs = {} # for bones in animation SMDs but not the ref skeleton
		
		self.boneTransformIDs = {} # DMX animation import

class qc_info:
	def __init__(self):
		self.startTime = 0
		self.imported_smds = []
		self.vars = {}
		self.ref_mesh = None # for VTA import
		self.a = None
		self.origin = None
		self.upAxis = 'Z'
		self.upAxisMat = None
		self.numSMDs = 0
		self.makeCamera = False

		self.in_block_comment = False

		self.jobName = ""
		self.root_filedir = ""
		self.dir_stack = []

	def cd(self):
		return os.path.join(self.root_filedir,*self.dir_stack)
		
class KeyFrame:
	matrix = Matrix()
	pos = False
	rot = False
	
def makeSettingsBox(layout, text,icon='NONE'):
	box = layout.box()
	col = box.column()
	title_row = col.row()
	title_row.alignment = 'CENTER'
	title_row.label(text=text,icon=icon)
	col.separator()
	return col

class SMD_CT_ObjectExportProps(bpy.types.PropertyGroup):
	type = StringProperty()
	icon = StringProperty()
	item_name = StringProperty()
	
	def get_id(self):
		if self.type == 'GROUP':
			return bpy.data.groups[self.item_name]
		if self.type in ['ACTION', 'OBJECT']:
			return bpy.data.objects[self.item_name]
		else:
			raise TypeError("Unknown type in SMD_CT_ObjectExportProps")

# error reporting
class logger:
	def __init__(self):
		self.warnings = []
		self.errors = []
		self.startTime = time.time()
		self.wantDMXDownloadPrompt = False

	def warning(self, *string):
		message = " ".join(str(s) for s in string)
		printColour(STD_YELLOW," WARNING:",message)
		self.warnings.append(message)

	def error(self, *string):
		message = " ".join(str(s) for s in string)
		printColour(STD_RED," ERROR:",message)
		self.errors.append(message)

	def errorReport(self, jobName, output, caller, numOut):
		message = "{} {}{} {}".format(numOut,output,"s" if numOut != 1 else "",jobName)
		if numOut:
			message += " in {} seconds".format( round( time.time() - self.startTime, 1 ) )

		if len(self.errors) or len(self.warnings):
			message += " with {} errors and {} warnings:".format(len(self.errors),len(self.warnings))

			# like it or not, Blender automatically prints operator reports to the console these days
			'''print(message)
			stdOutColour(STD_RED)
			for msg in self.errors:
				print("  " + msg)
			stdOutColour(STD_YELLOW)
			for msg in self.warnings:
				print("  " + msg)
			stdOutReset()'''

			for err in self.errors:
				message += "\nERROR: " + err
			for warn in self.warnings:
				message += "\nWARNING: " + warn
			caller.report({'ERROR'},message)
		else:
			caller.report({'INFO'},message)
			print(message)

		if self.wantDMXDownloadPrompt:
			stdOutColour(STD_YELLOW)
			print("\nFor DMX support, download DMX-Model from http://code.google.com/p/blender-smd/downloads/list")
			stdOutReset()

log = None # Initialize this so it is easier for smd_test_suite to access

##################################
#        Shared utilities        #
##################################

def benchReset():
	global benchLast
	global benchStart
	benchStart = benchLast = time.time()
benchReset()
def bench(label):
	global benchLast
	now = time.time()
	print("{}: {:.4f}".format(label,now-benchLast))
	benchLast = now
def benchTotal():
	global benchStart
	return time.time() - benchStart
	
def smdBreak(line):
	line = line.rstrip('\n')
	return line == "end" or line == ""
	
def smdContinue(line):
	return line.startswith("//")

def ValidateBlenderVersion(op):
	try:		
		if int(bpy.app.build_revision[:5]) >= bl_info['api']:
			return True
		else:
			op.report({'ERROR'},"SMD Tools {} require Blender {} or later, but this is {}".format(PrintVer(bl_info['version']), PrintVer(bl_info['blender']), PrintVer(bpy.app.version)) )
			return False
	except ValueError:
		return True

def canExportDMX(scene):
	if scene.smd_studiomdl_branch == 'CUSTOM':
		dmx_versions['CUSTOM'] = [scene.smd_studiomdl_custom_path_dmx_encoding, scene.smd_studiomdl_custom_path_dmx_format]
	
	try: datamodel.check_support("binary",dmx_versions[scene.smd_studiomdl_branch][0])
	except: return False
	
	return dmx_versions[scene.smd_studiomdl_branch][1] in [18]
	
def shouldExportDMX(scene):
	if scene.smd_format != 'DMX': return False
	return canExportDMX(scene)	

def getFileExt(flex=False):
	if shouldExportDMX(bpy.context.scene):
		return ".dmx"
	else:
		if flex: return ".vta"
		else: return ".smd"

def isWild(in_str):
	wcards = [ "*", "?", "[", "]" ]
	for char in wcards:
		if in_str.find(char) != -1: return True

def getEngineBranchName():
	for branch in src_branches:
		if branch[0] == bpy.context.scene.smd_studiomdl_branch:
			return branch[1]

# rounds to 6 decimal places, converts between "1e-5" and "0.000001", outputs str
def getSmdFloat(fval):
	val = "{:.6f}".format(float(fval))
	return val

# joins up "quoted values" that would otherwise be delimited, removes comments
def parseQuoteBlockedLine(line,lower=True):
	if len(line) == 0:
		return ["\n"]

	words = []
	last_word_start = 0
	in_quote = in_whitespace = False

	# The last char of the last line in the file was missed
	if line[-1] != "\n":
		line += "\n"

	for i in range(len(line)):
		char = line[i]
		nchar = pchar = None
		if i < len(line)-1:
			nchar = line[i+1]
		if i > 0:
			pchar = line[i-1]

		# line comment - precedence over block comment
		if (char == "/" and nchar == "/") or char in ['#',';']:
			if i > 0:
				i = i-1 # last word will be caught after the loop
			break # nothing more this line

		#block comment
		global smd_manager
		if smd_manager.in_block_comment:
			if char == "/" and pchar == "*": # done backwards so we don't have to skip two chars
				smd_manager.in_block_comment = False
			continue
		elif char == "/" and nchar == "*": # note: nchar, not pchar
			smd_manager.in_block_comment = True
			continue

		# quote block
		if char == "\"" and not pchar == "\\": # quotes can be escaped
			in_quote = (in_quote == False)
		if not in_quote:
			if char in [" ","\t"]:
				cur_word = line[last_word_start:i].strip("\"") # characters between last whitespace and here
				if len(cur_word) > 0:
					if (lower and os.name == 'nt') or cur_word[0] == "$":
						cur_word = cur_word.lower()
					words.append(cur_word)
				last_word_start = i+1 # we are in whitespace, first new char is the next one

	# catch last word and any '{'s crashing into it
	needBracket = False
	cur_word = line[last_word_start:i]
	if cur_word.endswith("{"):
		needBracket = True

	cur_word = cur_word.strip("\"{")
	if len(cur_word) > 0:
		words.append(cur_word)

	if needBracket:
		words.append("{")

	if line.endswith("\\\\\n") and (len(words) == 0 or words[-1] != "\\\\"):
		words.append("\\\\") # macro continuation beats everything

	return words

def appendExt(path,ext):
	if not path.lower().endswith("." + ext) and not path.lower().endswith(".dmx"):
		path += "." + ext
	return path

def printTimeMessage(start_time,name,job,type="SMD"):
	elapsedtime = int(time.time() - start_time)
	if elapsedtime == 1:
		elapsedtime = "1 second"
	elif elapsedtime > 1:
		elapsedtime = str(elapsedtime) + " seconds"
	else:
		elapsedtime = "under 1 second"

	print(type,name,"{}ed successfully in".format(job),elapsedtime,"\n")

def PrintVer(in_seq,sep="."):
		rlist = list(in_seq[:])
		rlist.reverse()
		out = ""
		for val in rlist:
			if int(val) == 0 and not len(out):
				continue
			out = "{}{}{}".format(str(val),sep if sep else "",out) # NB last value!
		if out.count(sep) == 1:
			out += "0" # 1.0 instead of 1
		return out.rstrip(sep)

try:
	import ctypes
	kernel32 = ctypes.windll.kernel32
	STD_RED = 0x04
	STD_YELLOW = 0x02|0x04
	STD_WHITE = 0x01|0x02|0x04
	def stdOutColour(colour):
		kernel32.SetConsoleTextAttribute(kernel32.GetStdHandle(-11),colour|0x08)
	def stdOutReset():
		kernel32.SetConsoleTextAttribute(kernel32.GetStdHandle(-11),STD_WHITE)
	def printColour(colour,*string):
		stdOutColour(colour)
		print(*string)
		stdOutReset()
except:
	STD_RED = STD_YELLOW = STD_WHITE = None
	def stdOutColour(colour):
		pass
	def stdOutReset():
		pass
	def printColour(colour,*string):
		print(*string)

def getUpAxisMat(axis):
	if axis.upper() == 'X':
		return Matrix.Rotation(pi/2,4,'Y')
	if axis.upper() == 'Y':
		return Matrix.Rotation(pi/2,4,'X')
	if axis.upper() == 'Z':
		return Matrix.Rotation(0,4,'Z')
	else:
		raise AttributeError("getUpAxisMat got invalid axis argument '{}'".format(axis))

axes = (('X','X',''),('Y','Y',''),('Z','Z',''))

def MakeObjectIcon(object,prefix=None,suffix=None):
	if not (prefix or suffix):
		raise TypeError("A prefix or suffix is required")

	if object.type == 'TEXT':
		type = 'FONT'
	else:
		type = object.type

	out = ""
	if prefix:
		out += prefix
	out += type
	if suffix:
		out += suffix
	return out

def getObExportName(ob):
	if ob.get('smd_name'):
		return ob['smd_name']
	else:
		return ob.name

def removeObject(obj):
	d = obj.data
	type = obj.type

	if type == "ARMATURE":
		for child in obj.children:
			if child.type == 'EMPTY':
				removeObject(child)

	bpy.context.scene.objects.unlink(obj)
	if obj.users == 0:
		if type == 'ARMATURE' and obj.animation_data:
			obj.animation_data.action = None # avoid horrible Blender bug that leads to actions being deleted

		bpy.data.objects.remove(obj)
		if d and d.users == 0:
			if type == 'MESH':
				bpy.data.meshes.remove(d)
			if type == 'ARMATURE':
				bpy.data.armatures.remove(d)

	return None if d else type

def hasShapes(ob,groupIndex = -1):
	def _test(t_ob):
		return t_ob.type in shape_types and t_ob.data.shape_keys and len(t_ob.data.shape_keys.key_blocks) > 1

	if groupIndex != -1:
		for g_ob in ob.users_group[groupIndex].objects:
			if _test(g_ob): return True
		return False
	else:
		return _test(ob)

def shouldExportGroup(group):
	return group.smd_export and not group.smd_mute

def DatamodelEncodingVersion():
	if bpy.context.scene.smd_studiomdl_branch == 'CUSTOM':
		return bpy.context.scene.smd_studiomdl_custom_path_dmx_encoding
	else:
		return dmx_versions[bpy.context.scene.smd_studiomdl_branch][0]
	
def DatamodelFormatVersion():
	if bpy.context.scene.smd_studiomdl_branch == 'CUSTOM':
		return bpy.context.scene.smd_studiomdl_custom_path_dmx_format
	else:
		return dmx_versions[bpy.context.scene.smd_studiomdl_branch][1]
		
def hasFlexControllerSource(item):
	return bpy.data.texts.get(item.smd_flex_controller_source) or os.path.exists(bpy.path.abspath(item.smd_flex_controller_source))

########################
#        Import        #
########################

# Identifies what type of SMD this is. Cannot tell between reference/lod/collision meshes!
def scanSMD():
	for line in smd.file:
		if line == "triangles\n":
			smd.jobType = REF
			print("- This is a mesh")
			break
		if line == "vertexanimation\n":
			print("- This is a flex animation library")
			smd.jobType = FLEX
			break

	# Finished the file

	if smd.jobType == None:
		print("- This is a skeltal animation or pose") # No triangles, no flex - must be animation
		if smd.append:
			for object in bpy.context.scene.objects:
				if object.type == 'ARMATURE':
					smd.jobType = ANIM
		if smd.jobType == None: # support importing animations on their own
			smd.jobType = ANIM_SOLO

	smd.file.seek(0,0) # rewind to start of file

def uniqueName(name, nameList, limit):
	if name not in nameList and len(name) <= limit:
		return name
	name_orig = name[:limit-3]
	i = 1
	name = '%s_%.2d' % (name_orig, i)
	while name in nameList:
		i += 1
		name = '%s_%.2d' % (name_orig, i)
	return name

# Runs instead of readBones if an armature already exists, testing the current SMD's nodes block against it.
def validateBones(target):
	missing = 0
	validated = 0
	for line in smd.file:
		if smdBreak(line):
			break
		if smdContinue(line):
			continue
	
		values = parseQuoteBlockedLine(line,lower=False)
		values[0] = int(values[0])
		values[2] = int(values[2])

		targetBone = target.data.bones.get(values[1]) # names, not IDs, are the key
		if not targetBone:
			for bone in target.data.bones:
				if getObExportName(bone) == values[1]:
					targetBone = bone
		
		if targetBone:
			validated += 1
		else:
			missing += 1
			parentName = targetBone.parent.name if targetBone and targetBone.parent else ""
			if smd.boneIDs.get(values[2]) != parentName:
				smd.phantomParentIDs[values[0]] = values[2]	

		smd.boneIDs[values[0]] = targetBone.name if targetBone else values[1]
	
	if smd.a != target:
		removeObject(smd.a)
		smd.a = target

	print("- Validated {} bones against armature \"{}\"{}".format(validated, smd.a.name, " (could not find {})".format(missing) if missing > 0 else ""))

# nodes
def readNodes():
	if smd.append and findArmature():
		if smd.jobType == REF:
			smd.jobType = REF_ADD
		validateBones(smd.a)
		return

	# Got this far? Then this is a fresh import which needs a new armature.
	smd.a = createArmature(smd_manager.jobName)
	smd.a.data.smd_implicit_zero_bone = False # Too easy to break compatibility, plus the skeleton is probably set up already

	try:
		qc.a = smd.a
	except NameError:
		pass

	boneParents = {}
	renamedBones = []

	bpy.ops.object.mode_set(mode='EDIT',toggle=False)

	# Read bone definitions from disc
	for line in smd.file:		
		if smdBreak(line):
			break
		if smdContinue(line):
			continue

		values = parseQuoteBlockedLine(line,lower=False)
	
		bone = smd.a.data.edit_bones.new(values[1])
		bone.tail = 0,5,0 # Blender removes zero-length bones

		smd.boneIDs[int(values[0])] = bone.name
		boneParents[bone.name] = int(values[2])

	# Apply parents now that all bones exist
	for bone in smd.a.data.edit_bones:
		parentID = boneParents[bone.name]
		if parentID != -1:	
			bone.parent = smd.a.data.edit_bones[ smd.boneIDs[parentID] ]

	bpy.ops.object.mode_set(mode='OBJECT')
	print("- Imported {} new bones".format(len(smd.a.data.bones)) )

	if len(smd.a.data.bones) > 128:
		log.warning("Source only supports 128 bones!")

def findArmature():
	# Search the current scene for an existing armature - there can only be one skeleton in a Source model
	if bpy.context.active_object and bpy.context.active_object.type == 'ARMATURE':
		try:
			smd.a = bpy.context.active_object
		except:
			return bpy.context.active_object
	else:
		def isArmIn(list):
			for ob in list:
				if ob.type == 'ARMATURE':
					smd.a = ob
					return True

		isArmIn(bpy.context.selected_objects) # armature in the selection?

		if not smd.a:
			for ob in bpy.context.selected_objects:
				if ob.type == 'MESH':
					smd.a = ob.find_armature() # armature modifying a selected object?
					if smd.a:
						break
		if not smd.a:
			isArmIn(bpy.context.scene.objects) # armature in the scene at all?

	return smd.a

def createArmature(armature_name):

	if bpy.context.active_object:
		bpy.ops.object.mode_set(mode='OBJECT',toggle=False)
	a = bpy.data.objects.new(armature_name,bpy.data.armatures.new(armature_name))
	a.show_x_ray = True
	a.data.draw_type = 'STICK'
	bpy.context.scene.objects.link(a)
	for i in bpy.context.selected_objects: i.select = False #deselect all objects
	a.select = True
	bpy.context.scene.objects.active = a

	if not smd.isDMX:
		ops.object.mode_set(mode='OBJECT')

	return a

def readFrames():
	# We only care about pose data in some SMD types
	if smd.jobType not in [ REF, ANIM, ANIM_SOLO ]:
		for line in smd.file:			
			if smdBreak(line):
				return

	a = smd.a
	bones = a.data.bones
	bpy.context.scene.objects.active = smd.a
	ops.object.mode_set(mode='POSE')

	num_frames = 0
	keyframes = collections.defaultdict(dict)
	phantom_keyframes = collections.defaultdict(dict)	# bones that aren't in the reference skeleton
	
	for line in smd.file:
		if smdBreak(line):
			break
		if smdContinue(line):
			continue
			
		values = line.split()

		if values[0] == "time": # frame number is a dummy value, all frames are equally spaced
			if num_frames > 0:
				if smd.jobType == ANIM_SOLO and num_frames == 1:
					bpy.ops.pose.armature_apply()
				if smd.jobType == REF:
					log.warning("Found animation in reference mesh \"{}\", ignoring!".format(smd.jobName))
					for line in smd.file: # skip to end of block						
						if smdBreak(line):
							break
						if smdContinue(line):
							continue
			num_frames += 1
			continue
			
		# Read SMD data
		pos = Vector([float(values[1]), float(values[2]), float(values[3])])
		rot = Euler([float(values[4]), float(values[5]), float(values[6])])
		
		keyframe = KeyFrame()
		keyframe.matrix = Matrix.Translation(pos) * rot.to_matrix().to_4x4()
		keyframe.pos = keyframe.rot = True
		
		# store the keyframe
		values[0] = int(values[0])
		try:
			bone = smd.a.pose.bones[ smd.boneIDs[values[0]] ]
			if not bone.parent:
				keyframe.matrix = getUpAxisMat(smd.upAxis) * keyframe.matrix
			keyframes[bone][num_frames-1] = keyframe
		except KeyError:
			if not smd.phantomParentIDs.get(values[0]):
				keyframe.matrix = getUpAxisMat(smd.upAxis) * keyframe.matrix
			phantom_keyframes[values[0]][num_frames-1] = keyframe
		
	# All frames read, apply phantom bones
	for ID, parentID in smd.phantomParentIDs.items():		
		bone = smd.a.pose.bones.get( smd.boneIDs.get(ID) )
		if not bone: continue
		for f,phantom_keyframe in phantom_keyframes[bone].items():
			cur_parent = parentID
			if keyframes[bone].get(f): # is there a keyframe to modify?
				while phantom_keyframes.get(cur_parent): # parents are recursive
					phantom_frame = f				
					while not phantom_keyframes[cur_parent].get(phantom_frame): # rewind to the last value
						if phantom_frame == 0: continue # should never happen
						phantom_frame -= 1
					# Apply the phantom bone, then recurse
					keyframes[bone][f].matrix = phantom_keyframes[cur_parent][phantom_frame] * keyframes[bone][f].matrix
					cur_parent = smd.phantomParentIDs.get(cur_parent)
	
	applyFrames(keyframes,num_frames)

def applyFrames(keyframes,num_frames, fps = None): # this is called during DMX import too
	bpy.ops.object.mode_set(mode='POSE')
	if smd.jobType in [REF,ANIM_SOLO]:
		# Apply the reference pose
		for bone in smd.a.pose.bones:
			if keyframes.get(bone):
				bone.matrix = keyframes[bone][0].matrix
		bpy.ops.pose.armature_apply()
		
		# Get sphere bone mesh
		bone_vis = bpy.data.objects.get("smd_bone_vis")
		if not bone_vis:
			bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3,size=2)
			bone_vis = bpy.context.active_object
			bone_vis.data.name = bone_vis.name = "smd_bone_vis"
			bone_vis.use_fake_user = True
			bpy.context.scene.objects.unlink(bone_vis) # don't want the user deleting this
			bpy.context.scene.objects.active = smd.a
			
		# Calculate armature dimensions...Blender should be doing this!
		maxs = [0,0,0]
		mins = [0,0,0]
		for bone in smd.a.data.bones:
			for i in range(3):
				maxs[i] = max(maxs[i],bone.head_local[i])
				mins[i] = min(mins[i],bone.head_local[i])
    
		smd_manager.dimensions = dimensions = []
		for i in range(3):
			dimensions.append(maxs[i] - mins[i])
    
		length = max(0.001, (dimensions[0] + dimensions[1] + dimensions[2]) / 600) # very small indeed, but a custom bone is used for display
	
		# Apply spheres
		ops.object.mode_set(mode='EDIT')
		for bone in smd.a.data.edit_bones:
			bone.tail = bone.head + (bone.tail - bone.head).normalized() * length # Resize loose bone tails based on armature size
			smd.a.pose.bones[bone.name].custom_shape = bone_vis # apply bone shape
			
	
	if smd.jobType in [ANIM,ANIM_SOLO]:
		if not smd.a.animation_data:
			smd.a.animation_data_create()
		
		action = bpy.data.actions.new(smd.jobName)
		
		if 'ActLib' in dir(bpy.types):
			smd.a.animation_data.action_library.add()
		else:
			action.use_fake_user = True
			
		smd.a.animation_data.action = action
		
		if 'fps' in dir(action):
			action.fps = fps if fps else 30
			bpy.context.scene.render.fps = 60
			bpy.context.scene.render.fps_base = 1
	
		ops.object.mode_set(mode='POSE')
	
		# Create an animation
		if 'ActLib' in dir(bpy.types):
			bpy.context.scene.use_preview_range = bpy.context.scene.use_preview_range_action_lock = True
		else:
			bpy.context.scene.frame_start = 0
			bpy.context.scene.frame_end = num_frames - 1		
		
		for bone in smd.a.pose.bones:
			bone.rotation_mode = smd.rotMode
			
		for bone,frames in list(keyframes.items()):
			if len(frames) == 0:
				del keyframes[bone]
		
		if smd.isDMX == False:
			# Remove every point but the first unless there is motion
			still_bones = list(keyframes.keys())
			for bone in keyframes.keys():
				bone_keyframes = keyframes[bone]
				for f,keyframe in bone_keyframes.items():
					if f == 0: continue
					diff = keyframe.matrix.inverted() * bone_keyframes[0].matrix
					if diff.to_translation().length > 0.00001 or abs(diff.to_quaternion().w) > 0.0001:
						still_bones.remove(bone)
						break
			for bone in still_bones:
				keyframes[bone] = {0:keyframes[bone][0]}
		
		# Create keyframes
		def ApplyRecursive(bone):
			if keyframes.get(bone):
				# Generate curves
				curvesLoc = None
				curvesRot = None
				bone_string = "pose.bones[\"{}\"].".format(bone.name)				
				group = action.groups.new(name=bone.name)
				for keyframe in keyframes[bone].values():
					if curvesLoc and curvesRot: break
					if keyframe.pos and not curvesLoc:
						curvesLoc = []
						for i in range(3):
							curve = action.fcurves.new(data_path=bone_string + "location",index=i)
							curve.group = group
							curvesLoc.append(curve)
					if keyframe.rot and not curvesRot:
						curvesRot = []
						for i in range(3 if smd.rotMode == 'XYZ' else 4):
							curve = action.fcurves.new(data_path=bone_string + "rotation_" + ("euler" if smd.rotMode == 'XYZ' else "quaternion"),index=i)
							curve.group = group
							curvesRot.append(curve)
				
				# Key each frame
				for f,keyframe in keyframes[bone].items():
					# Transform
					if smd.a.data.smd_legacy_rotation:
						keyframe.matrix *= mat_BlenderToSMD.inverted()
					
					if bone.parent:
						if smd.a.data.smd_legacy_rotation: parentMat = bone.parent.matrix * mat_BlenderToSMD
						else: parentMat = bone.parent.matrix
						bone.matrix = parentMat * keyframe.matrix
					else:
						bone.matrix = getUpAxisMat(smd.upAxis) * keyframe.matrix
					
					# Key location					
					if keyframe.pos:
						for i in range(3):
							curvesLoc[i].keyframe_points.add(1)
							curvesLoc[i].keyframe_points[-1].co = [f, bone.location[i]]
					
					# Key rotation
					if keyframe.rot:
						if smd.rotMode == 'XYZ':
							for i in range(3):
								curvesRot[i].keyframe_points.add(1)
								curvesRot[i].keyframe_points[-1].co = [f, bone.rotation_euler[i]]
						else:
							for i in range(4):
								curvesRot[i].keyframe_points.add(1)
								curvesRot[i].keyframe_points[-1].co = [f, bone.rotation_quaternion[i]]

			# Recurse
			for child in bone.children:
				ApplyRecursive(child)
		
		# Start keying
		for bone in smd.a.pose.bones:			
			if not bone.parent:					
				ApplyRecursive(bone)
				
		# Smooth keyframe handles
		for bone in smd.a.data.bones:
			bone.select = True		
		oldType = bpy.context.area.type
		bpy.context.area.type = 'GRAPH_EDITOR'
		smd.a.select = True
		if bpy.ops.graph.handle_type.poll():
			bpy.ops.graph.handle_type(type='AUTO')
		bpy.context.area.type = oldType # in Blender 2.59 this leaves context.region blank, making some future ops calls (e.g. view3d.view_all) fail!
		for bone in smd.a.data.bones:
			bone.select = False

	# clear any unkeyed poses
	for bone in smd.a.pose.bones:
		bone.location.zero()
		if smd.rotMode == 'XYZ': bone.rotation_euler.zero()
		else: bone.rotation_quaternion.identity()
	scn = bpy.context.scene
	
	if scn.frame_current == 1: # Blender starts on 1, Source starts on 0
		scn.frame_set(0)
	else:
		scn.frame_set(scn.frame_current)
	ops.object.mode_set(mode='OBJECT')
	
	print( "- Imported {} frames of animation".format(num_frames) )

def getMeshMaterial(in_name):
	if in_name == "": # buggered SMD
		in_name = "Material"
	md = smd.m.data
	mat = None
	for candidate in bpy.data.materials: # Do we have this material already?
		if candidate.name == in_name:
			mat = candidate
	if mat:
		if md.materials.get(mat.name): # Look for it on this mesh
			for i in range(len(md.materials)):
				if md.materials[i].name == mat.name:
					mat_ind = i
					break
		else: # material exists, but not on this mesh
			md.materials.append(mat)
			mat_ind = len(md.materials) - 1
	else: # material does not exist
		print("- New material: {}".format(in_name))
		mat = bpy.data.materials.new(in_name)
		md.materials.append(mat)
		# Give it a random colour
		randCol = []
		for i in range(3):
			randCol.append(random.uniform(.4,1))
		mat.diffuse_color = randCol
		if smd.jobType != PHYS:
			mat.use_face_texture = True # in case the uninitated user wants a quick rendering
		else:
			smd.m.draw_type = 'SOLID'
		mat_ind = len(md.materials) - 1

	return mat, mat_ind

def setLayer():
	layers = [False] * len(smd.m.layers)
	layers[smd.layer] = bpy.context.scene.layers[smd.layer] = True
	smd.m.layers = layers
	if smd.jobType == PHYS:
		smd.a.layers[smd.layer] = True
		for child in smd.a.children:
			if child.type == 'EMPTY':
				child.layers[smd.layer] = True

# Remove doubles without removing entire faces
def removeDoublesPreserveFaces():
	for poly in smd.m.data.polygons:
		poly.select = True
	
	def getVertCos(poly):
		cos = []
		for vert_index in poly.vertices:
			cos.append(poly.id_data.vertices[vert_index].co)
		return cos
		
	def getEpsilonNormal(normal):
		norm_rounded = [0,0,0]
		for i in range(0,3):
			norm_rounded[i] = abs(round(normal[i],4))
		return tuple(norm_rounded)
	
	# First pass: make a hashed list of unsigned normals
	norm_dict = collections.defaultdict(list)
	for poly in smd.m.data.polygons:
		norm_dict[getEpsilonNormal(poly.normal)].append(poly.index)
	
	# Second pass: for each selected poly, check each poly with a matching normal vector
	# and determine if it shares the same verts. If it does, deselect it to avoid
	# destruction during Remove Doubles.
	for poly in smd.m.data.polygons:
		if not poly.select: continue
		norm_tuple = getEpsilonNormal(poly.normal)			
		poly_verts = getVertCos(poly)
		
		for candidate_index in norm_dict[norm_tuple]:
			if candidate_index == poly.index: continue
			candidate_poly = smd.m.data.polygons[candidate_index]
			if not candidate_poly.select: continue
			candidate_poly_verts = getVertCos(candidate_poly)
			different = False
			for poly_vert in poly_verts:
				if poly_vert not in candidate_poly_verts:
					different = True
					break
			candidate_poly.select = different
	
	# Now remove those doubles!
	ops.object.mode_set(mode='EDIT')
	ops.mesh.remove_doubles(threshold=0)
	bpy.ops.mesh.select_all(action='INVERT') # FIXME: the 'back' polys will not be connected to the main mesh
	ops.mesh.remove_doubles(threshold=0)
	bpy.ops.mesh.select_all(action='DESELECT')
	ops.object.mode_set(mode='OBJECT')

# triangles block
def readPolys():
	if smd.jobType not in [ REF, REF_ADD, PHYS ]:
		return

	# Create a new mesh object, disable double-sided rendering, link it to the current scene
	if smd.jobType == REF and not smd.jobName.lower().find("reference") and not smd.jobName.lower().endswith("ref"):
		meshName = smd.jobName + " ref"
	else:
		meshName = smd.jobName

	smd.m = bpy.data.objects.new(meshName,bpy.data.meshes.new(meshName))
	smd.m.data.show_double_sided = False
	smd.m.parent = smd.a
	bpy.context.scene.objects.link(smd.m)
	setLayer()
	if smd.jobType == REF: # can only have flex on a ref mesh
		try:
			qc.ref_mesh = smd.m # for VTA import
		except NameError:
			pass

	# Create weightmap groups
	for bone in smd.a.data.bones.values():
		smd.m.vertex_groups.new(bone.name)

	# Apply armature modifier
	modifier = smd.m.modifiers.new(type="ARMATURE",name="Armature")
	modifier.object = smd.a

	# Initialisation
	md = smd.m.data
	lastWindowUpdate = time.time()
	# Vertex values
	cos = []
	norms = []
	weights = []
	# Face values
	uvs = []
	mats = []

	bm = bmesh.new()
	bm.from_mesh(md)
	
	# *************************************************************************************************
	# There are two loops in this function: one for polygons which continues until the "end" keyword
	# and one for the vertices on each polygon that loops three times. We're entering the poly one now.	
	countPolys = 0
	badWeights = 0
	for line in smd.file:
		line = line.rstrip("\n")

		if smdBreak(line):
			break
		if smdContinue(line):
			continue

		mat, mat_ind = getMeshMaterial(line)
		mats.append(mat_ind)

		# ***************************************************************
		# Enter the vertex loop. This will run three times for each poly.
		vertexCount = 0
		faceVerts = []
		for line in smd.file:
			if smdContinue(line):
				continue
			values = line.split()

			vertexCount+= 1
			co = []
			#norm = []

			# Read co-ordinates and normals
			for i in range(1,4): # 0 is the deprecated bone weight value
				co.append( float(values[i]) )
				#norm.append( float(values[i+3]) ) # Blender currenty ignores this data!
			
			faceVerts.append( bm.verts.new(co) )
			
			# Can't do these in the above for loop since there's only two
			uvs.append( ( float(values[7]), float(values[8]) ) )

			# Read weightmap data
			weights.append( [] ) # Blank array, needed in case there's only one weightlink
			if len(values) > 10 and values[9] != "0": # got weight links?
				for i in range(10, 10 + (int(values[9]) * 2), 2): # The range between the first and last weightlinks (each of which is *two* values)
					try:
						bone = smd.a.data.bones[ smd.boneIDs[int(values[i])] ]
						weights[-1].append( [ smd.m.vertex_groups[bone.name], float(values[i+1]) ] )
					except KeyError:
						badWeights += 1
			else: # Fall back on the deprecated value at the start of the line
				try:
					bone = smd.a.data.bones[ smd.boneIDs[int(values[0])] ]				
					weights[-1].append( [smd.m.vertex_groups[bone.name], 1.0] )
				except KeyError:
					badWeights += 1

			# Three verts? It's time for a new poly
			if vertexCount == 3:
				bm.faces.new(faceVerts)
				break

		# Back in polyland now, with three verts processed.
		countPolys+= 1

	bm.to_mesh(md)
	bm.free()
	md.update()
	
	if countPolys:	
		md.polygons.foreach_set("material_index", mats)
		
		md.uv_textures.new()
		uv_data = md.uv_layers[0].data
		for i in range(len(uv_data)):
			uv_data[i].uv = uvs[md.loops[i].vertex_index]
		
		# Apply vertex groups
		for i in range(len(md.vertices)):
			for link in weights[i]:
				link[0].add( [i], link[1], 'REPLACE' )
        
		bpy.ops.object.select_all(action="DESELECT")
		smd.m.select = True
		bpy.context.scene.objects.active = smd.m
		
		ops.object.shade_smooth()
		
		for poly in smd.m.data.polygons:
			poly.select = True		
		
		removeDoublesPreserveFaces()
		
		smd.m.show_wire = smd.jobType == PHYS

		if smd_manager.upAxis == 'Y':
			md.transform(rx90)
			md.update()

		if badWeights:
			log.warning("{} vertices weighted to invalid bones on {}".format(badWeights,smd.jobName))
		print("- Imported {} polys".format(countPolys))

# vertexanimation block
def readShapes():
	if smd.jobType is not FLEX:
		return

	if not smd.m:
		try:
			smd.m = qc.ref_mesh
		except NameError: # user selection
			if bpy.context.active_object.type in shape_types:
				smd.m = bpy.context.active_object
			else:
				for obj in bpy.context.selected_objects:
					if obj.type in shape_types:
						smd.m = obj
			
	if not smd.m:
		log.error("Could not import shape keys: no valid target object found") # FIXME: this could actually be supported
		return
	
	smd.m.show_only_shape_key = True # easier to view each shape, less confusion when several are active at once
	
	co_map = {}
	mesh_cos = []
	for vert in smd.m.data.vertices:
		mesh_cos.append(vert.co)
	
	making_base_shape = True
	bad_vta_verts = num_shapes = 0
	md = smd.m.data

	for line in smd.file:
		line = line.rstrip("\n")
		
		if smdBreak(line):
			break
		if smdContinue(line):
			continue
			
		values = line.split()

		if values[0] == "time":
			if len(co_map):
				making_base_shape = False
				if bad_vta_verts > 0:
					log.warning(bad_vta_verts,"VTA vertices were not matched to a mesh vertex!")

			if making_base_shape:
				smd.m.shape_key_add("Basis")
			else:
				smd.m.shape_key_add(str(values[1]))
				num_shapes += 1

			continue # to the first vertex of the new shape

		cur_id = int(values[0])
		vta_co = Vector([ float(values[1]), float(values[2]), float(values[3]) ])

		if making_base_shape: # create VTA vert ID -> mesh vert ID dictionary
			try:
				co_map[cur_id] = mesh_cos.index(vta_co)
			except ValueError:
				bad_vta_verts += 1
		else: # write to the shapekey
			try:
				md.shape_keys.key_blocks[-1].data[ co_map[cur_id] ].co = vta_co
			except KeyError:
				pass

	print("- Imported",num_shapes,"flex shapes")

# Parses a QC file
def readQC( context, filepath, newscene, doAnim, makeCamera, rotMode, outer_qc = False):
	filename = os.path.basename(filepath)
	filedir = os.path.dirname(filepath)

	global qc
	if outer_qc:
		print("\nQC IMPORTER: now working on",filename)
		qc = qc_info()
		qc.startTime = time.time()
		qc.jobName = filename
		qc.root_filedir = filedir
		qc.makeCamera = makeCamera
		qc.animation_names = []
		if newscene:
			bpy.context.screen.scene = bpy.data.scenes.new(filename) # BLENDER BUG: this currently doesn't update bpy.context.scene
		else:
			bpy.context.scene.name = filename
		global smd_manager
		smd_manager = qc

	file = open(filepath, 'r')
	in_bodygroup = in_lod = False
	lod = 0
	for line_str in file:
		line = parseQuoteBlockedLine(line_str)
		if len(line) == 0:
			continue
		#print(line)

		# handle individual words (insert QC variable values, change slashes)
		i = 0
		for word in line:
			for var in qc.vars.keys():
				kw = "${}$".format(var)
				pos = word.lower().find(kw)
				if pos != -1:
					word = word.replace(word[pos:pos+len(kw)], qc.vars[var])			
			line[i] = word.replace("/","\\") # studiomdl is Windows-only
			i += 1
		
		# Skip macros
		if line[0] == "$definemacro":
			log.warning("Skipping macro in QC {}".format(filename))
			while line[-1] == "\\\\":
				line = parseQuoteBlockedLine( file.readline())

		# register new QC variable
		if line[0] == "$definevariable":
			qc.vars[line[1]] = line[2].lower()
			continue

		# dir changes
		if line[0] == "$pushd":
			if line[1][-1] != "\\":
				line[1] += "\\"
			qc.dir_stack.append(line[1])
			continue
		if line[0] == "$popd":
			try:
				qc.dir_stack.pop()
			except IndexError:
				pass # invalid QC, but whatever
			continue

		# up axis
		if line[0] == "$upaxis":
			qc.upAxis = bpy.context.scene.smd_up_axis = line[1].upper()
			qc.upAxisMat = getUpAxisMat(line[1])
			continue
	
		# bones in pure animation QCs
		if line[0] == "$definebone":
			pass # TODO

		def loadSMD(word_index,ext,type, append=True,layer=0,in_file_recursion = False):
			path = os.path.join( qc.cd(), appendExt(line[word_index],ext) )
			
			if not os.path.exists(path):
				if not in_file_recursion:
					if loadSMD(word_index,"dmx",type,append,layer,True):
						return True
					else:
						log.error("Could not open file",path)
						return False
			if not path in qc.imported_smds: # FIXME: an SMD loaded once relatively and once absolutely will still pass this test
				qc.imported_smds.append(path)
				if path.endswith("dmx"):
					readDMX(context,path,qc.upAxis,rotMode,False,type,append,from_qc=True,target_layer=layer)
				else:
					readSMD(context,path,qc.upAxis,rotMode,False,type,append,from_qc=True,target_layer=layer)		
				qc.numSMDs += 1			
			return True

		# meshes
		if line[0] in ["$body","$model"]:
			loadSMD(2,"smd",REF,append=False) # create new armature no matter what
			continue
		if line[0] == "$lod":
			in_lod = True
			lod += 1
			continue
		if in_lod:
			if line[0] == "replacemodel":
				loadSMD(2,"smd",REF_ADD,layer=lod)
				continue
			if "}" in line:
				in_lod = False
				continue
		if line[0] == "$bodygroup":
			in_bodygroup = True
			continue
		if in_bodygroup:
			if line[0] == "studio":
				loadSMD(1,"smd",REF) # bodygroups can be used to define skeleton
				continue
			if "}" in line:
				in_bodygroup = False
				continue

		# skeletal animations
		if doAnim and line[0] in ["$sequence","$animation"]:
			# there is no easy way to determine whether a SMD is being defined here or elsewhere, or even precisely where it is being defined
			num_words_to_skip = 0
			for i in range(2, len(line)):
				if num_words_to_skip:
					num_words_to_skip -= 1
					continue
				if line[i] == "{":
					break
				if line[i] in ["hidden","autolay","realtime","snap","spline","xfade","delta","predelta"]:
					continue
				if line[i] in ["fadein","fadeout","addlayer","blendwidth","node"]:
					num_words_to_skip = 1
					continue
				if line[i] in ["activity","transision","rtransition"]:
					num_words_to_skip = 2
					continue
				if line[i] in ["blend"]:
					num_words_to_skip = 3
					continue
				if line[i] in ["blendlayer"]:
					num_words_to_skip = 5
					continue
				# there are many more keywords, but they can only appear *after* an SMD is referenced
			
				if not qc.a: qc.a = findArmature()
			
				if line[i].lower() not in qc.animation_names:
					if not qc.a.animation_data: qc.a.animation_data_create()
					last_action = qc.a.animation_data.action
					loadSMD(i,"smd",ANIM)
					if line[0] == "$animation":
						qc.animation_names.append(line[1].lower())
					while i < len(line) - 1:
						if line[i] == "fps" and qc.a.animation_data.action != last_action:
							if 'fps' in dir(qc.a.animation_data.action):
								qc.a.animation_data.action.fps = float(line[i+1])
						i += 1
				break
			continue

		# flex animation
		if line[0] == "flexfile":
			loadSMD(1,"vta",FLEX)
			continue

		# naming shapes
		if line[0] in ["flex","flexpair"]: # "flex" is safe because it cannot come before "flexfile"
			for i in range(1,len(line)):
				if line[i] == "frame":
					shape = qc.ref_mesh.data.shape_keys.key_blocks.get(line[i+1])
					if shape: shape.name = line[1]
					break
			continue

		# physics mesh
		if line[0] in ["$collisionmodel","$collisionjoints"]:
			loadSMD(1,"smd",PHYS,layer=10) # FIXME: what if there are >10 LODs?
			continue

		# origin; this is where viewmodel editors should put their camera, and is in general something to be aware of
		if line[0] == "$origin":
			if qc.makeCamera:
				data = bpy.data.cameras.new(qc.jobName + "_origin")
				name = "camera"
			else:
				data = None
				name = "empty object"
			print("QC IMPORTER: created {} at $origin\n".format(name))

			origin = bpy.data.objects.new(qc.jobName + "_origin",data)
			bpy.context.scene.objects.link(origin)

			origin.rotation_euler = Vector([pi/2,0,pi]) + Vector(getUpAxisMat(qc.upAxis).inverted().to_euler()) # works, but adding seems very wrong!
			bpy.ops.object.select_all(action="DESELECT")
			origin.select = True
			bpy.ops.object.transform_apply(rotation=True)

			for i in range(3):
				origin.location[i] = float(line[i+1])
			origin.matrix_world = getUpAxisMat(qc.upAxis) * origin.matrix_world

			if qc.makeCamera:
				bpy.context.scene.camera = origin
				origin.data.lens_unit = 'DEGREES'
				origin.data.lens = 31.401752 # value always in mm; this number == 54 degrees
				# Blender's FOV isn't locked to X or Y height, so a shift is needed to get the weapon aligned properly.
				# This is a nasty hack, and the values are only valid for the default 54 degrees angle
				origin.data.shift_y = -0.27
				origin.data.shift_x = 0.36
				origin.data.passepartout_alpha = 1
			else:
				origin.empty_draw_type = 'PLAIN_AXES'

			qc.origin = origin

		# QC inclusion
		if line[0] == "$include":
			path = os.path.join(qc.root_filedir,line[1]) # special case: ignores dir stack

			if not path.endswith(".qc") and not path.endswith(".qci"):
				if os.path.exists(appendExt(path,".qci")):
					path = appendExt(path,".qci")
				elif os.path.exists(appendExt(path,".qc")):
					path = appendExt(path,".qc")
			try:
				readQC(context,path,False, doAnim, makeCamera, rotMode)
			except IOError:
				message = 'Could not open QC $include file "%s"' % path
				log.warning(message + " - skipping!")

	file.close()

	if qc.origin:
		qc.origin.parent = qc.a
		if qc.ref_mesh:
			size = min(qc.ref_mesh.dimensions) / 15
			if qc.makeCamera:
				qc.origin.data.draw_size = size
			else:
				qc.origin.empty_draw_size = size

	if outer_qc:
		printTimeMessage(qc.startTime,filename,"import","QC")
	return qc.numSMDs

def initSMD(filepath,smd_type,append,upAxis,rotMode,from_qc,target_layer):
	global smd
	smd	= smd_info()
	smd.jobName = os.path.splitext(os.path.basename(filepath))[0]
	smd.jobType = smd_type
	smd.append = append
	smd.startTime = time.time()
	smd.layer = target_layer
	smd.rotMode = rotMode
	if upAxis:
		smd.upAxis = upAxis
	smd.uiTime = 0
	if not from_qc:
		global smd_manager
		smd_manager = smd

	return smd

# Parses an SMD file
def readSMD( context, filepath, upAxis, rotMode, newscene = False, smd_type = None, append = True, from_qc = False,target_layer = 0):
	if filepath.endswith("dmx"):
		return readDMX( context, filepath, upAxis, newscene, smd_type, append, from_qc)

	global smd
	initSMD(filepath,smd_type,append,upAxis,rotMode,from_qc,target_layer)

	try:
		smd.file = file = open(filepath, 'r')
	except IOError as err: # TODO: work out why errors are swallowed if I don't do this!
		message = "Could not open SMD file \"{}\": {}".format(smd.jobName,err)
		log.error(message)
		return 0

	if newscene:
		bpy.context.screen.scene = bpy.data.scenes.new(smd.jobName) # BLENDER BUG: this currently doesn't update bpy.context.scene
	elif bpy.context.scene.name == "Scene":
		bpy.context.scene.name = smd.jobName

	print("\nSMD IMPORTER: now working on",smd.jobName)
	
	while True:
		header = parseQuoteBlockedLine(file.readline())
		if len(header): break
	
	if header != ["version" ,"1"]:
		log.warning ("Unrecognised/invalid SMD file. Import will proceed, but may fail!")

	if smd.jobType == None:
		scanSMD() # What are we dealing with?

	for line in file:
		if line == "nodes\n": readNodes()
		if line == "skeleton\n": readFrames()
		if line == "triangles\n": readPolys()
		if line == "vertexanimation\n": readShapes()

	file.close()
	'''
	if smd.m and smd.upAxisMat and smd.upAxisMat != 1:
		smd.m.rotation_euler = smd.upAxisMat.to_euler()
		smd.m.select = True
		bpy.context.scene.update()
		bpy.ops.object.transform_apply(rotation=True)
	'''
	printTimeMessage(smd.startTime,smd.jobName,"import")

	return 1

def readDMX( context, filepath, upAxis, rotMode,newscene = False, smd_type = None, append = True, from_qc = False,target_layer = 0):
	global smd
	initSMD(filepath,smd_type,append,upAxis,rotMode,from_qc,target_layer)
	smd.isDMX = 1
	target_arm = findArmature() if append else None
	if target_arm:
		smd.a = target_arm
		arm_hide = target_arm.hide
	benchReset()
	ob = bone = restData = smd.atch = smd.a = None
	smd.layer = target_layer
	starting_objects = set(bpy.context.scene.objects)
	if bpy.context.active_object: bpy.ops.object.mode_set(mode='OBJECT')
	
	print( "\nDMX IMPORTER: now working on",os.path.basename(filepath) )	
	
	import datamodel
	benchReset()
	error = None
	try:
		dm = datamodel.load(filepath)
		bench("Load DMX")
		
		if context.scene.name.startswith("Scene"):
			context.scene.name = smd.jobName
		
		if not smd_type: smd.jobType = REF if dm.root.get("model") else ANIM
		
		DmeModel = dm.root.get("skeleton")
		#if not DmeModel.get("model"): smd.jobType = ANIM
		FlexControllers = dm.root.get("combinationOperator")
		if DmeModel.get("upAxis"):
			smd.upAxis = DmeModel["upAxis"]
		
		def getBlenderQuat(datamodel_quat):
			return Quaternion([datamodel_quat[3], datamodel_quat[0], datamodel_quat[1], datamodel_quat[2]])
		def get_transform_matrix(elem,use_up_axis = True):
			out = Matrix()
			if elem == None: return out
			if use_up_axis:
				out = getUpAxisMat(smd.upAxis).copy()
			out *= Matrix.Translation(Vector(elem["position"]))
			out *= getBlenderQuat(elem["orientation"]).to_matrix().to_4x4()
			return out
		
		# Skeleton
		if target_arm:
			def validateSkeleton(elem,parent_bone):
				if elem.type == "DmeJoint":
					bone = smd.a.data.bones.get(elem.name)
					if not bone:
						log.warning("Could not find bone {}".format(elem.name))
						return
					
					smd.boneIDs[elem.id] = bone.name
					smd.boneTransformIDs[elem["transform"].id] = bone.name
					
					if elem.get("children"):
						for child in elem["children"]:
							validateSkeleton(child,bone)
			
			smd.a = findArmature()
			for child in DmeModel["children"]:
				validateSkeleton(child,None)
		else:
			if smd.jobType == ANIM: smd.jobType = ANIM_SOLO
			restData = {}
			if not findArmature():
				smd.append = False
			ob = smd.a = createArmature(DmeModel.name)
			smd.a.data.smd_implicit_zero_bone = False # Too easy to break compatibility, plus the skeleton is probably set up already
			if not smd_manager.a: smd_manager.a = ob
			bpy.context.scene.objects.active = smd.a
			bpy.ops.object.mode_set(mode='EDIT')
			
			smd.a.matrix_world = get_transform_matrix(DmeModel["transform"])
			
			bone_matrices = {}
			def parseSkeleton(elem,parent_bone):
				if elem.type in ["DmeJoint","DmeDag"]:
					if elem.get("shape") and elem["shape"].type == "DmeAttachment":
						atch = smd.atch = bpy.data.objects.new(name=elem.name, object_data=None)
						context.scene.objects.link(atch)
						atch.show_x_ray = True
						atch.empty_draw_type = 'ARROWS'

						atch.parent = smd.a
						if parent_bone:
							atch.parent_type = 'BONE'
							atch.parent_bone = parent_bone.name
						
						atch.matrix_local = get_transform_matrix(elem["transform"],use_up_axis = False)
					else:
						bone = smd.a.data.edit_bones.new(elem.name)
						bone.parent = parent_bone
						bone.tail = (0,5,0)
						bone_matrices[bone.name] = get_transform_matrix(elem["transform"],use_up_axis=False)
						smd.boneIDs[elem.id] = bone.name
						smd.boneTransformIDs[elem["transform"].id] = bone.name
						if elem.get("children"):
							for child in elem["children"]:
								parseSkeleton(child,bone)
			
			for child in DmeModel["children"]:
				parseSkeleton(child,None)
				
			bpy.ops.object.mode_set(mode='POSE')
			for bone in smd.a.pose.bones:
				keyframe = KeyFrame()
				keyframe.matrix = bone_matrices[bone.name]
				restData[bone] = {0:keyframe}
			applyFrames(restData,1,None)
		
		def parseModel(elem,matrix=Matrix()):
			if elem.type in ["DmeModel","DmeDag"]:
				matrix = get_transform_matrix(elem["transform"])
				if elem.get("children") and len(elem["children"]):
					subelems = elem["children"]
				elif elem["shape"]:
					subelems = [elem["shape"]]
				else:
					return
				for subelem in subelems:
					parseModel(subelem,matrix)
			elif elem.type == "DmeMesh":
				DmeMesh = elem
				bpy.ops.object.mode_set(mode='OBJECT')
				ob = smd.m = bpy.data.objects.new(name=DmeMesh.name, object_data=bpy.data.meshes.new(name=DmeMesh.name))
				ob.matrix_world = matrix
				context.scene.objects.link(ob)
				setLayer()
				ob.show_wire = smd.jobType == PHYS
				
				if smd.a:
					ob.parent = smd.a
					amod = ob.modifiers.new(name="Armature",type='ARMATURE')
					amod.object = smd.a
					amod.use_bone_envelopes = False
				
				print("Importing DMX mesh \"{}\"".format(DmeMesh.name))
				
				DmeVertexData = DmeMesh["currentState"]
				
				bm = bmesh.new()
				bm.from_mesh(ob.data)
				
				positions = DmeVertexData["positions"]
				positionsIndices = DmeVertexData["positionsIndices"]
				
				# Vertices
				for pos in positions:
					bm.verts.new( Vector(pos) )
				
				# Faces and Materials
				skipfaces = []
				for face_set in DmeMesh["faceSets"]:
					mat_path = face_set["material"]["mtlName"]
					bpy.context.scene.smd_material_path = os.path.dirname(mat_path).replace("\\","/")
					mat, mat_ind = getMeshMaterial(os.path.dirname(mat_path))
					face_verts = []
					dmx_face = 0
					for vert in face_set["faces"]:
						if vert == -1:
							try:
								face = bm.faces.new(face_verts)
								face.smooth = True
								face.material_index = mat_ind
							except ValueError: # can't have an overlapping face...this will be painful later
								skipfaces.append(dmx_face)
							dmx_face += 1
							face_verts = []
							continue
						face_verts.append(bm.verts[positionsIndices[vert]])
				
				# Move from BMesh to Blender
				bm.to_mesh(ob.data)
				ob.data.update()
				ob.matrix_world = matrix
				if smd.jobType == PHYS:
					ob.draw_type = 'SOLID'
				
				# Weightmap
				if "jointWeights" in DmeVertexData["vertexFormat"]:
					jointList = DmeModel["jointList"] if dm.format_ver >= 15 else DmeModel["jointTransforms"]
					jointWeights = DmeVertexData["jointWeights"]
					jointIndices = DmeVertexData["jointIndices"]
					jointRange = range(DmeVertexData["jointCount"])
					full_weights = collections.defaultdict(list)
					joint_index = 0
					for vert_index in range(len(ob.data.vertices)):
						for i in jointRange:
							weight = jointWeights[joint_index]
							if weight > 0:
								bone_id = jointList[jointIndices[joint_index]].id
								if dm.format_ver >= 15:
									bone_name = smd.boneIDs[bone_id]
								else:
									bone_name = smd.boneTransformIDs[bone_id]
								vg = ob.vertex_groups.get(bone_name)
								if not vg:
									vg = ob.vertex_groups.new(bone_name)
								if weight == 1:
									full_weights[vg].append(vert_index)
								else:
									vg.add([vert_index],weight,'REPLACE')
							joint_index += 1
							
					for vg,verts in iter(full_weights.items()):
						vg.add(verts,1,'REPLACE')
				
				# UV
				if "textureCoordinates" in DmeVertexData["vertexFormat"]:
					ob.data.uv_textures.new()
					uv_data = ob.data.uv_layers[0].data
					textureCoordinatesIndices = DmeVertexData["textureCoordinatesIndices"]
					textureCoordinates = DmeVertexData["textureCoordinates"]
					uv_vert=0
					dmx_face=0
					skipping = False
					for faceset in DmeMesh["faceSets"]:
						for vert in faceset["faces"]:
							if vert == -1:
								dmx_face += 1
								skipping = dmx_face in skipfaces
							if skipping: continue # need to skip overlapping faces which couldn't be imported
							
							if vert != -1:				
								uv_data[uv_vert].uv = textureCoordinates[ textureCoordinatesIndices[vert] ]
								uv_vert+=1
				
				# Shapes
				if DmeMesh.get("deltaStates"):
					for DmeVertexDeltaData in DmeMesh["deltaStates"]:
						if not ob.data.shape_keys:
							ob.shape_key_add("Basis")
							ob.show_only_shape_key = True				
						shape_key = ob.shape_key_add(DmeVertexDeltaData.name)
						
						if "positions" in DmeVertexDeltaData["vertexFormat"]:
							deltaPositions = DmeVertexDeltaData["positions"]
							for i,posIndex in enumerate(DmeVertexDeltaData["positionsIndices"]):
								shape_key.data[posIndex].co += Vector(deltaPositions[i])
					
						#if "wrinkle" in DmeVertexDeltaData["vertexFormat"]:
						#	wrinkle = DmeVertexDeltaData["wrinkle"]
						#	if len(wrinkle):
						#		vg = ob.vertex_groups.new(shape_key.name)
						#		for i,posIndex in enumerate(DmeVertexDeltaData["wrinkleIndices"]):
						#			vg.add([posIndex],wrinkle[i],'REPLACE') # FIXME
		
		if smd.jobType in [REF,REF_ADD,PHYS]:
			parseModel(DmeModel)
		
		if smd.jobType in [ANIM,ANIM_SOLO]:
			print("Importing DMX animation \"{}\"".format(smd.jobName))
			smd.jobType = ANIM
			
			animation = dm.root["animationList"]["animations"][0]
			
			frameRate = animation["frameRate"]			
			timeFrame = animation["timeFrame"]
			scale = timeFrame.get("scale",1.0)
			duration = timeFrame["duration"] if dm.format_ver >= 15 else timeFrame["durationTime"]
			offset = timeFrame.get("offset",0.0) if dm.format_ver >= 15 else timeFrame.get("offsetTime",0.0)
			
			if type(duration) == int: duration = datamodel.Time.from_int(duration)
			if type(offset) == int: offset = datamodel.Time.from_int(offset)
				
			total_frames = ceil(duration * frameRate) + 1 # need a frame for 0 too!
			
			keyframes = collections.defaultdict(lambda: collections.defaultdict(KeyFrame))
			missing_bones = []
			for channel in animation["channels"]:
				toElement = channel["toElement"]
				if not toElement: continue # SFM
				bone_name = smd.boneTransformIDs.get(toElement.id)
				bone = smd.a.pose.bones.get(bone_name) if bone_name else None
				if not bone:
					if bone_name and bone_name not in missing_bones:
						missing_bones.append(bone_name)
						log.warning("Animation contained unknown bone \"{}\"".format(bone_name))
					continue
				
				frame_log = channel["log"]["layers"][0]
				
				times = frame_log["times"]
				values = frame_log["values"]
				
				for i in range( len(times) ):
					frame_time = times[i]
					if type(frame_time) == int: frame_time = datamodel.Time.from_int(frame_time)
					frame_value = values[i]				
					frame = ceil(frame_time * frameRate)
					keyframe = keyframes[bone][frame]
					
					if channel["toAttribute"][0] == "p":
						if not bone.parent: keyframe.matrix *= getUpAxisMat(smd.upAxis).inverted()
						keyframe.matrix *= Matrix.Translation(frame_value)
						keyframe.pos = True
					elif channel["toAttribute"][0] == "o":
						keyframe.matrix *= getBlenderQuat(frame_value).to_matrix().to_4x4()
						keyframe.rot = True
			
			smd.a.hide = False
			bpy.context.scene.objects.active = smd.a
			applyFrames(keyframes,total_frames,frameRate)
	except datamodel.AttributeError as e:
		e.args = ["Invalid DMX model: {}".format(e.args[0])]
		raise e
	except Exception as e:
		raise e
	
	new_obs = set(bpy.context.scene.objects).difference(starting_objects)
	if len(new_obs) > 1:
		group = bpy.data.groups.new(smd.jobName)
		for ob in new_obs:
			if ob.type != 'ARMATURE':
				group.objects.link(ob)
				
	
	bench("DMX imported in")
	return 1

class SmdImporter(bpy.types.Operator):
	bl_idname = "import_scene.smd"
	bl_label = "Import SMD/VTA, DMX, QC"
	bl_description = "Imports uncompiled Source Engine model data"
	bl_options = {'UNDO'}

	# Properties used by the file browser
	filepath = StringProperty(name="File path", description="File filepath used for importing the SMD/VTA/DMX/QC file", maxlen=1024, default="")
	filter_folder = BoolProperty(name="Filter folders", description="", default=True, options={'HIDDEN'})
	filter_glob = StringProperty(default="*.smd;*.vta;*.dmx;*.qc;*.qci", options={'HIDDEN'})

	# Custom properties
	append = BoolProperty(name="Extend any existing model", description="Whether imports will latch onto an existing armature or create their own", default=True)
	doAnim = BoolProperty(name="Import animations (slow/bulky)", default=True)
	upAxis = EnumProperty(name="Up axis",items=axes,default='Z',description="Which axis represents 'up' (ignored for QCs)")
	makeCamera = BoolProperty(name="Make camera at $origin",description="For use in viewmodel editing; if not set, an empty will be created instead",default=False)
	rotModes = ( ('XYZ', "Euler XYZ", ''), ('QUATERNION', "Quaternion", "") )
	rotMode = EnumProperty(name="Rotation mode",items=rotModes,default='XYZ',description="Keyframes will be inserted in this rotation mode")
	
	def execute(self, context):
		if not ValidateBlenderVersion(self):
			return {'CANCELLED'}

		global log
		log = logger()
		
		pre_obs = set(bpy.context.scene.objects)

		filepath_lc = self.properties.filepath.lower()
		if filepath_lc.endswith('.qc') or filepath_lc.endswith('.qci'):
			self.countSMDs = readQC(context, self.properties.filepath, False, self.properties.doAnim, self.properties.makeCamera, self.properties.rotMode, outer_qc=True)
			bpy.context.scene.objects.active = qc.a
		elif filepath_lc.endswith('.smd'):
			self.countSMDs = readSMD(context, self.properties.filepath, self.properties.upAxis, self.properties.rotMode, append=self.properties.append)
		elif filepath_lc.endswith ('.vta'):
			self.countSMDs = readSMD(context, self.properties.filepath, self.properties.upAxis, self.properties.rotMode, smd_type=FLEX)
		elif filepath_lc.endswith('.dmx'):
			self.countSMDs = readDMX(context, self.properties.filepath, self.properties.upAxis, self.properties.rotMode, append=self.properties.append)
		else:
			if len(filepath_lc) == 0:
				self.report({'ERROR'},"No file selected")
			else:
				self.report({'ERROR'},"Format of {} not recognised".format(os.path.basename(self.properties.filepath)))
			return {'CANCELLED'}

		log.errorReport("imported","file",self,self.countSMDs)
		if self.countSMDs:
			bpy.ops.object.select_all(action='DESELECT')
			new_obs = set(bpy.context.scene.objects).difference(pre_obs)
			xy = xyz = 0
			for ob in new_obs:
				ob.select = True
				# FIXME: assumes meshes are centered around their origins
				xy = max(xy, int(max(ob.dimensions[0],ob.dimensions[1])) )
				xyz = max(xyz, max(xy,int(ob.dimensions[2])))
			if smd_manager.a: bpy.context.scene.objects.active = smd_manager.a
			for area in context.screen.areas:
				if area.type == 'VIEW_3D':
					space = area.spaces.active
					space.grid_lines = max(space.grid_lines, (xy * 1.2) / space.grid_scale )
					space.clip_end = max( space.clip_end, xyz * 2 )
		if bpy.context.area.type == 'VIEW_3D' and bpy.context.region:
			bpy.ops.view3d.view_selected()
		return {'FINISHED'}

	def invoke(self, context, event):
		if not ValidateBlenderVersion(self):
			return {'CANCELLED'}
		self.properties.upAxis = context.scene.smd_up_axis
		bpy.context.window_manager.fileselect_add(self)
		return {'RUNNING_MODAL'}

########################
#        Export        #
########################

# nodes block
def writeBones(quiet=False):

	smd.file.write("nodes\n")

	if not smd.a:
		smd.file.write("0 \"root\" -1\nend\n")
		if not quiet: print("- No skeleton to export")
		return
	
	curID = 0
	if smd.a.data.smd_implicit_zero_bone:
		smd.file.write("0 \"blender_implicit\" -1\n")
		curID += 1
	
	# Write to file
	for bone in smd.a.data.bones:		
		if not bone.use_deform:
			print("- Skipping non-deforming bone \"{}\"".format(bone.name))
			continue

		parent = bone.parent
		while parent:
			if parent.use_deform:
				break
			parent = parent.parent

		line = "{} ".format(curID)
		smd.boneNameToID[bone.name] = curID
		curID += 1

		bone_name = bone.get('smd_name')
		if bone_name:
			comment = " # smd_name override from \"{}\"".format(bone.name)
		else:
			bone_name = bone.name
			comment = ""	
		line += "\"" + bone_name + "\" "

		if parent:
			line += str(smd.boneNameToID[parent.name])
		else:
			line += "-1"

		smd.file.write(line + comment + "\n")

	smd.file.write("end\n")
	num_bones = len(smd.a.data.bones)
	if not quiet: print("- Exported",num_bones,"bones")
	
	max_bones = 1023 if smd.isDMX else 128
	if num_bones > max_bones:
		log.warning("{} bone limit is {}, you have {}!".format("DMX" if smd.isDMX else "SMD",max_bones,num_bones))

# skeleton block
def writeFrames():
	if smd.jobType == FLEX: # writeShapes() does its own skeleton block
		return

	smd.file.write("skeleton\n")

	if not smd.a:
		smd.file.write("time 0\n0 0 0 0 0 0 0\nend\n")
		return
	
	# remove any non-keyframed positions
	for posebone in smd.a.pose.bones:
		posebone.matrix_basis.identity()
	bpy.context.scene.update()

	# If this isn't an animation, mute all pose constraints
	if smd.jobType != ANIM:
		for bone in smd.a.pose.bones:
			for con in bone.constraints:
				con.mute = True

	# Get the working frame range
	num_frames = 1
	if smd.jobType == ANIM:
		action = smd.a.animation_data.action
		start_frame, last_frame = action.frame_range
		num_frames = int(last_frame - start_frame) + 1 # add 1 due to the way range() counts
		bpy.context.scene.frame_set(start_frame)
		
		if 'fps' in dir(action):
			bpy.context.scene.render.fps = action.fps
			bpy.context.scene.render.fps_base = 1

	# Start writing out the animation
	for i in range(num_frames):
		smd.file.write("time {}\n".format(i))

		for posebone in smd.a.pose.bones:
			if not posebone.bone.use_deform: continue
	
			parent = posebone.parent	
			# Skip over any non-deforming parents
			while parent:
				if parent.bone.use_deform:
					break
				parent = parent.parent
	
			# Get the bone's Matrix from the current pose
			PoseMatrix = posebone.matrix
			if smd.a.data.smd_legacy_rotation:
				PoseMatrix *= mat_BlenderToSMD 
			if parent:
				if smd.a.data.smd_legacy_rotation: parentMat = parent.matrix * mat_BlenderToSMD 
				else: parentMat = parent.matrix
				PoseMatrix = parentMat.inverted() * PoseMatrix
			else:
				PoseMatrix = getUpAxisMat(smd.upAxis).inverted() * smd.a.matrix_world * PoseMatrix				
	
			# Get position
			pos = PoseMatrix.to_translation()
	
			# Apply armature scale
			if posebone.parent: # already applied to root bones
				scale = smd.a.matrix_world.to_scale()
				for j in range(3):
					pos[j] *= scale[j]
	
			# Get Rotation
			rot = PoseMatrix.to_euler()

			# Construct the string
			pos_str = rot_str = ""
			for j in [0,1,2]:
				pos_str += " " + getSmdFloat(pos[j])
				rot_str += " " + getSmdFloat(rot[j])
	
			# Write!
			smd.file.write( str(smd.boneNameToID[posebone.name]) + pos_str + rot_str + "\n" )

		# All bones processed, advance the frame
		bpy.context.scene.frame_set(bpy.context.scene.frame_current + 1)	

	smd.file.write("end\n")

	bpy.ops.object.mode_set(mode='OBJECT')
	
	print("- Exported {} frames{}".format(num_frames," (legacy rotation)" if smd.a.data.smd_legacy_rotation else ""))
	return
	
def getWeightmap(ob):
	out = []
	amod = smd.amod.get(ob['src_name'])
	if not amod: return out
	
	amod_vg = ob.vertex_groups.get(amod.vertex_group)
	
	for v in ob.data.vertices:
		weights = []
		total_weight = 0
		
		if amod.use_vertex_groups:			
			for v_group in v.groups:
				if v_group.group < len(ob.vertex_groups):
					ob_group = ob.vertex_groups[v_group.group]
					group_name = ob_group.name
					group_weight = v_group.weight					
				else:
					continue # Vertex group might not exist on object if it's re-using a datablock				

				bone = amod.object.data.bones.get(group_name)
				if bone and bone.use_deform:
					weights.append([ smd.boneNameToID[bone.name], group_weight ])
					total_weight += group_weight			
				
		if amod.use_bone_envelopes and total_weight == 0: # vertex groups completely override envelopes
			for pose_bone in amod.object.pose.bones:
				if not pose_bone.bone.use_deform:
					continue
				weight = pose_bone.bone.envelope_weight * pose_bone.evaluate_envelope( ob.matrix_world * amod.object.matrix_world.inverted() * v.co )
				if weight:
					weights.append([ smd.boneNameToID[pose_bone.name], weight ])
					total_weight += weight
			
		# normalise weights, like Blender does. Otherwise Studiomdl puts anything left over onto the root bone.
		if total_weight not in [0,1]:
			for link in weights:
				link[1] *= 1/total_weight
		
		# apply armature modifier vertex group
		if amod_vg and total_weight > 0:
			amod_vg_weight = 0
			for v_group in v.groups:
				if v_group.group == amod_vg.index:
					amod_vg_weight = v_group.weight
					break
			if amod.invert_vertex_group:
				amod_vg_weight = 1 - amod_vg_weight
			for link in weights:
				link[1] *= amod_vg_weight

		out.append(weights)
	return out

# triangles block
def writePolys(internal=False):
	if not internal:
		smd.file.write("triangles\n")
		have_cleared_pose = False

		if not bpy.context.scene.smd_use_image_names:
			materials = []
			for baked in smd.bakeInfo:
				if baked.type == 'MESH':
					for mat_slot in baked.material_slots:
						mat = mat_slot.material
						if mat and mat.get('smd_name') and mat not in materials:
							smd.file.write( "// Blender material \"{}\" has smd_name \"{}\"\n".format(mat.name,mat['smd_name']) )
							materials.append(mat)

		for baked in smd.bakeInfo:
			if baked.type == 'MESH':
				# write out each object in turn. Joining them would destroy unique armature modifier settings
				smd.m = baked
				if len(smd.m.data.polygons) == 0:
					log.error("Object {} has no faces, cannot export".format(smd.jobName))
					continue

				if smd.amod.get(smd.m['src_name']) and not have_cleared_pose:
					# This is needed due to a Blender bug. Setting the armature to Rest mode doesn't actually
					# change the pose bones' data!
					for posebone in smd.amod[smd.m['src_name']].object.pose.bones:
						posebone.matrix_basis.identity()
					bpy.context.scene.update()
					have_cleared_pose = True
				bpy.ops.object.mode_set(mode='OBJECT')

				writePolys(internal=True)

		smd.file.write("end\n")
		return

	# internal mode:

	md = smd.m.data
	face_index = 0

	uv_loop = md.uv_layers.active.data
	uv_tex = md.uv_textures.active.data
	
	weights = getWeightmap(smd.m)
	
	ob_weight_str = None
	if smd.m.get('bp'):
		ob_weight_str = " 1 {} 1".format(smd.boneNameToID[smd.m['bp']])
	elif len(weights) == 0:
		ob_weight_str = " 0"
	
	bad_face_mats = 0
	for poly in md.polygons:
		mat_name = None
		if not bpy.context.scene.smd_use_image_names and len(smd.m.material_slots) > poly.material_index:
			mat = smd.m.material_slots[poly.material_index].material
			if mat:
				mat_name = getObExportName(mat)
		if not mat_name and uv_tex:
			image = uv_tex[face_index].image
			if image:
				mat_name = os.path.basename(image.filepath) # not using data name as it can be truncated and custom props can't be used here
		if mat_name:
			smd.materials_used.add(mat_name)
		else:
			mat_name = "no_material"
			if smd.m.draw_type == 'TEXTURED':
				bad_face_mats += 1
		
		smd.file.write(mat_name + "\n")
		
		for i in range(len(poly.vertices)):
			# Vertex locations, normal directions
			loc = norms = ""
			v = md.vertices[poly.vertices[i]]
			norm = v.normal if poly.use_smooth else poly.normal
			for j in range(3):
				loc += " " + getSmdFloat(v.co[j])
				norms += " " + getSmdFloat(norm[j])

			# UVs
			uv = ""
			for j in range(2):
				uv += " " + getSmdFloat(uv_loop[poly.loop_start + i].uv[j])

			# Weightmaps
			weight_string = ""
			if ob_weight_str:
				weight_string = ob_weight_str
			else:
				valid_weights = 0
				for link in weights[v.index]:
					if link[1] > 0:
						weight_string += " {} {}".format(link[0], getSmdFloat(link[1]))
						valid_weights += 1
				weight_string = " {}{}".format(valid_weights,weight_string)

			# Finally, write it all to file
			smd.file.write("0" + loc + norms + uv + weight_string + "\n")

		face_index += 1

	if bad_face_mats:
		log.warning("{} faces on {} did not have a texture{} assigned".format(bad_face_mats,smd.jobName,"" if bpy.context.scene.smd_use_image_names else " or material"))
	print("- Exported",face_index,"polys")
	removeObject(smd.m)
	return

# vertexanimation block
def writeShapes():
	num_verts = 0

	def _writeTime(time, shape = None):
		smd.file.write( "time {}{}\n".format(time, " # {}".format(shape['shape_name']) if shape else "") )

	# VTAs are always separate files. The nodes block is handled by the normal function, but skeleton is done here to afford a nice little hack
	smd.file.write("skeleton\n")
	for i in range(len(smd.bakeInfo)):
		shape = smd.bakeInfo[i]
		_writeTime(i, shape if i != 0 else None)
	smd.file.write("end\n")

	smd.file.write("vertexanimation\n")
	
	vert_offset = 0
	total_verts = 0
	smd.m = smd.bakeInfo[0]
	
	for cur_shape in range(len(smd.bakeInfo)):
		_writeTime(cur_shape)
		shape = smd.bakeInfo[cur_shape]
		start_time = time.time()
		num_bad_verts = 0
		smd_vert_id = 0
		for poly in smd.m.data.polygons:
			for vert in poly.vertices:
				shape_vert = shape.data.vertices[vert]
				mesh_vert = smd.m.data.vertices[vert]
				if cur_shape != 0:
					diff_vec = shape_vert.co - mesh_vert.co
					for ordinate in diff_vec:
						if ordinate > 8:
							num_bad_verts += 1
							break

				if cur_shape == 0 or (diff_vec > epsilon or shape_vert.normal - mesh_vert.normal > epsilon):
					cos = norms = ""
					for i in range(3):
						cos += " " + getSmdFloat(shape_vert.co[i])
						norms += " " + getSmdFloat(shape_vert.normal[i])
					smd.file.write(str(smd_vert_id) + cos + norms + "\n")
					total_verts += 1
			
				smd_vert_id +=1
		if num_bad_verts:
			log.error("Shape \"{}\" has {} vertex movements that exceed eight units. Source does not support this!".format(shape['shape_name'],num_bad_verts))		
		if shape != smd.m:
			removeObject(shape)
	
	removeObject(smd.m)
	smd.file.write("end\n")
	print("- Exported {} flex shapes ({} verts)".format(cur_shape,total_verts))
	return

# Creates a mesh with object transformations and modifiers applied
def bakeObj(in_object):
	if in_object.library:
		in_object = in_object.copy()
		bpy.context.scene.objects.link(in_object)
	if in_object.data and in_object.data.library:
		in_object.data = in_object.data.copy()
	
	bakes_in = []
	bakes_out = []
	for object in bpy.context.selected_objects:
		object.select = False
	bpy.context.scene.objects.active = in_object
	bpy.ops.object.mode_set(mode='OBJECT')
	
	def _ApplyVisualTransform(obj):
		if obj.data.users > 1:
			obj.data = obj.data.copy()
		
		top_parent = cur_parent = obj
		while(cur_parent):
			if not cur_parent.parent:
				top_parent = cur_parent
			cur_parent = cur_parent.parent

		bpy.context.scene.objects.active = obj
		bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
		obj.location -= top_parent.location # undo location of topmost parent (potentially the object itself)
		bpy.ops.object.transform_apply(location=not smd.isDMX)	

	if in_object.type == 'ARMATURE':
		_ApplyVisualTransform(in_object)
		smd.a = in_object
	elif in_object.type in mesh_compatible:
		# hide all metaballs that we don't want
		for object in bpy.context.scene.objects:
			if (smd.g or object != in_object) and object.type == 'META' and (not object.smd_export or not (smd.g and smd.g in object.users_group)):
				for element in object.data.elements:
					element.hide = True
		bpy.context.scene.update() # actually found a use for this!!

		# get a list of objects we want to bake
		if not smd.g:
			bakes_in = [in_object]
		else:
			have_baked_metaballs = False
			validObs = getValidObs()
			flex_obs = []
			for object in smd.g.objects:
				if object.smd_export and object in validObs and not (object.type == 'META' and have_baked_metaballs):
					bakes_in.append(object)
					if not have_baked_metaballs: have_baked_metaballs = object.type == 'META'
					
			if smd.jobType == FLEX: # we can merge everything because we only care about the verts
				for ob in bpy.context.scene.objects:
					ob.select = ob in bakes_in
				bpy.context.scene.objects.active = bakes_in[0]
				bpy.ops.object.join()
				bakes_in = [bpy.context.scene.objects.active]
		
	# bake the list of objects!
	for i in range(len(bakes_in)):
		obj = bakes_in[i]
		solidify_fill_rim = False

		if obj.type in shape_types and obj.data.shape_keys:
			shape_keys = obj.data.shape_keys.key_blocks
		else:
			shape_keys = []

		if smd.jobType == FLEX or (smd.isDMX and len(shape_keys)):
			if obj.type not in shape_types:
				raise TypeError( "Shapes found on unsupported object type (\"{}\", {})".format(obj.name,obj.type) )				
			num_out = len(shape_keys)
		else:
			num_out = 1
		
		bpy.ops.object.mode_set(mode='OBJECT')
		bpy.ops.object.select_all(action="DESELECT")
		obj.select = True
		bpy.context.scene.objects.active = obj
		
		if obj.type == 'CURVE':
			obj.data.dimensions = '3D'

		if smd.jobType != FLEX: # we've already messed about with this object during ref export
			found_envelope = False
			
			# Bone parent
			if obj.parent_bone and obj.parent_type == 'BONE':
				smd.a = obj.parent
				obj['bp'] = obj.parent_bone
				found_envelope = True				
				
			# Bone constraint
			for con in obj.constraints:
				if con.mute:
					continue
				con.mute = True
				if con.type in ['CHILD_OF','COPY_TRANSFORMS'] and con.target.type == 'ARMATURE' and con.subtarget:
					if found_envelope:
						log.warning("Bone constraint \"{}\" found on \"{}\", which already has an envelope. Ignoring.".format(con.name,obj.name))
					else:
						smd.a = con.target
						obj['bp'] = con.subtarget
						found_envelope = True
			
			# Armature modifier
			for mod in obj.modifiers:
				if mod.type == 'ARMATURE' and mod.object:
					if found_envelope:
						log.warning("Armature modifier \"{}\" found on \"{}\", which already has an envelope. Ignoring.".format(mod.name,obj.name))
					else:
						smd.a = mod.object
						smd.amod[obj.name] = mod
						found_envelope = True
		
			if obj.type == "MESH":
				bpy.ops.object.mode_set(mode='EDIT')
				bpy.ops.mesh.reveal()
				bpy.ops.mesh.select_all(action="SELECT")
				if obj.matrix_world.is_negative:
					bpy.ops.mesh.flip_normals()
				bpy.ops.object.mode_set(mode='OBJECT')
			
			_ApplyVisualTransform(obj)
			
			if obj.type != 'ARMATURE': # don't apply transforms to armatures until/unless actions are baked too
				obj.matrix_world *= getUpAxisMat(smd.upAxis).inverted()
				bpy.ops.object.transform_apply(scale=True,rotation=not smd.isDMX)
		
		# Apply modifiers; need to do this per shape key
		bpy.ops.object.mode_set(mode='OBJECT')
		for x in range(num_out):
			if shape_keys:
				cur_shape = shape_keys[x]
				obj.active_shape_key_index = x
				obj.show_only_shape_key = True
				if smd.jobType == FLEX and cur_shape.mute:
					log.warning("Skipping muted shape \"{}\"".format(cur_shape.name))
					continue
	
			if obj.type in mesh_compatible:
				has_edge_split = False
				for mod in obj.modifiers:
					if mod.type == 'EDGE_SPLIT':
						has_edge_split = True
					if mod.type == 'SOLIDIFY' and not solidify_fill_rim:
						solidify_fill_rim = mod.use_rim
					if smd.jobType == FLEX and mod.type == 'DECIMATE' and mod.decimate_type != 'UNSUBDIV':
						log.error("Cannot export shape keys from \"{}\" because it has a '{}' Decimate modifier. Only Un-Subdivide mode is supported.".format(obj.name,mod.decimate_type))
						return

				if not has_edge_split and obj.type == 'MESH':
					edgesplit = obj.modifiers.new(name="SMD Edge Split",type='EDGE_SPLIT') # creates sharp edges
					edgesplit.use_edge_angle = False
				
				data = obj.to_mesh(bpy.context.scene, True, 'PREVIEW') # bake it!
				baked = obj
				if obj.type == 'MESH':
					baked = baked.copy()
					baked.data = data
				else:
					baked = bpy.data.objects.new(obj.name, data)
				bpy.context.scene.objects.link(baked)
				bpy.context.scene.objects.active = baked
				baked.select = True
				baked['src_name'] = obj.name
				if smd.jobType == FLEX or (smd.isDMX and x > 0):
					baked.name = baked.data.name = baked['shape_name'] = cur_shape.name
				
				if smd.isDMX:
					if x == 0: bakes_out.append(baked)
					else: smd.dmxShapes[obj.name].append(baked)
					if smd.g:
						baked.smd_flex_controller_source = smd.g.smd_flex_controller_source
						baked.smd_flex_controller_mode = smd.g.smd_flex_controller_mode
				else:
					bakes_out.append(baked)
					bpy.ops.object.mode_set(mode='EDIT')
					bpy.ops.mesh.quads_convert_to_tris()
					bpy.ops.object.mode_set(mode='OBJECT')
					
				for mod in baked.modifiers:
					if mod.type == 'ARMATURE':
						mod.show_viewport = False
		
				# handle which sides of a curve should have polys
				if obj.type == 'CURVE':
					bpy.ops.object.mode_set(mode='EDIT')
					if obj.data.smd_faces == 'RIGHT':
						bpy.ops.mesh.duplicate()
						bpy.ops.mesh.flip_normals()
					if not obj.data.smd_faces == 'BOTH':
						bpy.ops.mesh.select_all(action='INVERT')
						bpy.ops.mesh.delete()
					elif solidify_fill_rim:
						log.warning("Curve {} has the Solidify modifier with rim fill, but is still exporting polys on both sides.".format(obj.name))
					bpy.ops.object.mode_set(mode='OBJECT')

				# project a UV map
				if smd.jobType != FLEX and len(baked.data.uv_textures) == 0:
					if len(baked.data.vertices) < 2000:
						bpy.ops.object.mode_set(mode='OBJECT')
						bpy.ops.object.select_all(action='DESELECT')
						baked.select = True
						bpy.ops.uv.smart_project()
					else:
						bpy.ops.object.mode_set(mode='EDIT')
						bpy.ops.mesh.select_all(action='SELECT')
						bpy.ops.uv.unwrap()
		
		bpy.ops.object.mode_set(mode='OBJECT')
		obj.select = False
	
	smd.bakeInfo.extend(bakes_out) # save to manager

# Creates an SMD file
def writeSMD( context, object, groupIndex, filepath, smd_type = None, quiet = False ):
	global smd
	smd	= smd_info()
	smd.jobType = smd_type
	smd.isDMX = filepath.endswith(".dmx")
	if groupIndex != -1:
		smd.g = object.users_group[groupIndex]
	smd.startTime = time.time()
	smd.uiTime = 0
	
	def _workStartNotice():
		if not quiet:
			print( "\nSMD EXPORTER: now working on {}{}".format(smd.jobName," (shape keys)" if smd.jobType == FLEX else "") )

	if object.type in mesh_compatible:
		# We don't want to bake any meshes with poses applied
		# NOTE: this won't change the posebone values, but it will remove deformations
		armatures = []
		for scene_object in bpy.context.scene.objects:
			if scene_object.type == 'ARMATURE' and scene_object.data.pose_position == 'POSE':
				scene_object.data.pose_position = 'REST'
				armatures.append(scene_object)

		if not smd.jobType:
			smd.jobType = REF
		if smd.g:
			smd.jobName = smd.g.name
		else:
			smd.jobName = getObExportName(object)
		smd.m = object
		_workStartNotice()
		#smd.a = smd.m.find_armature() # Blender bug: only works on meshes
		bakeObj(smd.m)
		if len(smd.bakeInfo) == 0:
			return False

		# re-enable poses
		for object in armatures:
			object.data.pose_position = 'POSE'
		bpy.context.scene.update()
	elif object.type == 'ARMATURE':
		if not smd.jobType:
			smd.jobType = ANIM
		smd.a = object
		smd.jobName = getObExportName(object.animation_data.action)
		_workStartNotice()
	else:
		raise TypeError("PROGRAMMER ERROR: writeSMD() has object not in",exportable_types)

	if smd.a and smd.jobType != FLEX:
		bakeObj(smd.a) # MUST be baked after the mesh		

	if smd.isDMX:
		return writeDMX( context, object, groupIndex, filepath, smd_type, quiet )
		
	smd.file = open(filepath, 'w')
	print("-",filepath)
		
	smd.file.write("version 1\n")

	# these write empty blocks if no armature is found. Required!
	writeBones(quiet = smd.jobType == FLEX)
	writeFrames()

	if smd.m:
		if smd.jobType in [REF,PHYS]:
			writePolys()
			print("- Exported {} materials".format(len(smd.materials_used)))
			for mat in smd.materials_used:
				print("   " + mat)
		elif smd.jobType == FLEX:
			writeShapes()

	smd.file.close()
	if not quiet: printTimeMessage(smd.startTime,smd.jobName,"export")

	return True

def getDatamodelQuat(blender_quat):
	return datamodel.Quaternion([blender_quat[1], blender_quat[2], blender_quat[3], blender_quat[0]])

def writeDMX( context, object, groupIndex, filepath, smd_type = None, quiet = False ):	
	start = time.time()
	print("-",filepath)
	benchReset()
	global log
	
	if len(smd.bakeInfo) and smd.bakeInfo[0].smd_flex_controller_mode == 'ADVANCED' and not hasFlexControllerSource(smd.bakeInfo[0]):
		log.error( "Could not find flex controllers for \"{}\"".format(smd.jobName) )
		return
	
	def makeTransform(name,matrix,object_name):
		trfm = dm.add_element(name,"DmeTransform",id=object_name+"transform")
		pos = matrix.to_translation()
		rot = matrix.to_quaternion()
				
		trfm["position"] = datamodel.Vector3(pos)
		trfm["orientation"] = getDatamodelQuat(rot)
		return trfm
	
	dm = datamodel.DataModel("model",DatamodelFormatVersion())
	root = dm.add_element("root",id="Scene"+context.scene.name)	
	DmeModel = dm.add_element(bpy.context.scene.name,"DmeModel",id="Object" + (smd.a.name if smd.a else smd.m.name))
	DmeModel["transform"] = makeTransform("upaxis",getUpAxisMat(smd.upAxis),"Scene"+context.scene.name)
	DmeModel_children = DmeModel["children"] = datamodel.make_array([],datamodel.Element)
	
	implicit_trfm = None
	
	if smd.jobType in [REF,ANIM]: # skeleton
		root["skeleton"] = DmeModel		
		jointList = DmeModel["jointList"] = datamodel.make_array([],datamodel.Element)
		jointTransforms = DmeModel["jointTransforms"] = datamodel.make_array([],datamodel.Element)
		bone_transforms = {}
		
		def writeBone(bone):
			bone_name = bone.name if bone else "blender_implicit"
			
			bone_elem = dm.add_element(bone_name,"DmeJoint",id=bone_name)
			jointList.append(bone_elem)
			smd.boneNameToID[bone_name] = len(smd.boneNameToID)
			
			relMat = None
			if bone:
				if bone.parent: relMat = bone.parent.matrix.inverted() * bone.matrix
				else: relMat = getUpAxisMat(smd.upAxis).inverted() * bone.matrix
			else:
				relMat = getUpAxisMat(smd.upAxis).inverted()
			
			trfm = makeTransform(bone_name,relMat,"bone"+bone_name)
			
			# Apply armature scale
			scale = smd.a.matrix_world.to_scale()
			for j in range(3):
				trfm["position"][j] *= scale[j]
			
			jointTransforms.append(trfm)
			if bone:
				bone_transforms[bone] = trfm
			else:
				implicit_trfm = trfm
			bone_elem["transform"] = trfm
			
			if bone:
				children = bone_elem["children"] = datamodel.make_array([],datamodel.Element)
				for child in bone.children:
					children.append( writeBone(child) )
			
			return bone_elem
	
		if smd.a:
			# remove any non-keyframed positions
			for posebone in smd.a.pose.bones:
				posebone.matrix_basis.identity()
			bpy.context.scene.update()
			
			if smd.a.data.smd_implicit_zero_bone:
				DmeModel_children.append(writeBone(None))
			
			for bone in smd.a.pose.bones:
				if not bone.parent:
					DmeModel_children.append(writeBone(bone))
					
		bench("skeleton")
		
	if smd.jobType == REF: # mesh
		root["model"] = DmeModel
				
		materials = {}
		dags = []
		for ob in smd.bakeInfo:
			ob_name = ob['src_name']
			src_ob = bpy.data.objects[ob_name]
			if ob.type != 'MESH': continue
			print("\n" + ob_name)
			vertex_data = dm.add_element("bind","DmeVertexData",id=ob_name+"verts")
			
			DmeMesh = dm.add_element(ob_name,"DmeMesh",id=ob_name)
			DmeMesh["visible"] = True			
			DmeMesh["bindState"] = vertex_data
			DmeMesh["currentState"] = vertex_data
			DmeMesh["baseStates"] = datamodel.make_array([vertex_data],datamodel.Element)
			
			trfm = makeTransform(ob_name,ob.matrix_world,"ob"+ob_name)
			jointTransforms.append(trfm)
			
			DmeDag = dm.add_element(ob_name,"DmeDag",id="ob"+ob_name+"dag")
			jointList.append(DmeDag)
			DmeDag["transform"] = trfm
			DmeDag["shape"] = DmeMesh
			dags.append(DmeDag)
			
			ob_weights = getWeightmap(ob)
			
			has_shapes = smd.dmxShapes.get(ob_name)
			
			jointCount = 0
			badJointCounts = 0
			if ob.get('bp'):
				jointCount = 1
			elif smd.amod.get(ob['src_name']):
				for vert_weights in ob_weights:
					count = len(vert_weights)
					if count > 3: badJointCounts += 1
					jointCount = max(jointCount,count)
				if smd.a.data.smd_implicit_zero_bone:
					jointCount += 1
					
			if badJointCounts:
				log.warning("{} verts on \"{}\" have over 3 weight links. Studiomdl does not support this!".format(badJointCounts,ob['src_name']))
			elif jointCount > 3: # due to implicit bone
				log.warning("Implicit motionless bone is pushing \"{}\" over the weight link limit.".format(ob['src_name']))
			
			format = [ "positions", "normals", "textureCoordinates" ]
			if jointCount: format.extend( [ "jointWeights", "jointIndices" ] )
			if has_shapes: format.append("balance")
			vertex_data["vertexFormat"] = datamodel.make_array( format, str)
			
			vertex_data["flipVCoordinates"] = True
			vertex_data["jointCount"] = jointCount
			
			pos = []
			norms = []
			texco = []
			texcoIndices = []
			jointWeights = []
			jointIndices = []
			balance = []
			
			Indices = []
			
			uv_layer = ob.data.uv_layers.active.data
			
			bench("setup")
			
			if ob.get('bp'):
				jointWeights = [ 1.0 ] * len(ob.data.vertices)
				jointIndices = [ smd.boneNameToID[ob['bp']] ] * len(ob.data.vertices)
			
			width = ob.dimensions.x * ( 1 - (src_ob.data.smd_flex_stereo_sharpness / 100) )
			for vert in ob.data.vertices:
				pos.append(datamodel.Vector3(vert.co))
				norms.append(datamodel.Vector3(vert.normal))
				vert.select = False
				
				if has_shapes:
					if width == 0:
						if vert.co.x == 0: balance_out = 0.5
						elif vert.co.x > 0: balance_out = 1
						else: balance_out = 0
					else:
						balance_out = (-vert.co.x / width / 2) + 0.5
						balance_out = min(1,max(0, balance_out))
					balance.append( float(balance_out) )
				
				if jointCount:
					weights = [0.0] * jointCount
					indices = [0] * jointCount
					i = 0
					total_weight = 0
					vert_weights = ob_weights[vert.index]
					for i in range(len(vert_weights)):
						indices[i] = vert_weights[i][0]
						weights[i] = vert_weights[i][1]
						total_weight += weights[i]
						i+=1
					if smd.a.data.smd_implicit_zero_bone and total_weight < 1:
						weights[-1] = float(1 - total_weight)
					
					jointWeights.extend(weights)
					jointIndices.extend(indices)
				
			bench("verts")
			for poly in ob.data.polygons:
				i=0
				for vert_index in poly.vertices:
					vert = ob.data.vertices[vert_index]
					
					Indices.append(vert_index)
					
					uv = datamodel.Vector2(uv_layer[poly.loop_start + i].uv)					
					try:
						texcoIndices.append(texco.index(uv))
					except ValueError:
						texco.append(uv)
						texcoIndices.append(len(texco) - 1)
					
					i+=1
			bench("polys")
			vertex_data["positions"] = datamodel.make_array(pos,datamodel.Vector3)
			vertex_data["positionsIndices"] = datamodel.make_array(Indices,int)
			
			vertex_data["normals"] = datamodel.make_array(norms,datamodel.Vector3)
			vertex_data["normalsIndices"] = datamodel.make_array(Indices,int)
			
			vertex_data["textureCoordinates"] = datamodel.make_array(texco,datamodel.Vector2)
			vertex_data["textureCoordinatesIndices"] = datamodel.make_array(texcoIndices,int)
			
			if jointCount:
				vertex_data["jointWeights"] = datamodel.make_array(jointWeights,float)
				vertex_data["jointIndices"] = datamodel.make_array(jointIndices,int)
			
			if has_shapes:
				vertex_data["balance"] = datamodel.make_array(balance,float)
				vertex_data["balanceIndices"] = datamodel.make_array(Indices,int)
			bench("insert")
			face_sets = {}
			bad_face_mats = 0
			vert_index = 0
			for poly in ob.data.polygons:
				mat_name = None
				if not bpy.context.scene.smd_use_image_names:
					try: mat_name = ob.material_slots[poly.material_index].material.name
					except: pass
				if not mat_name and smd.m.data.uv_textures.active:
					try: mat_name = os.path.basename(smd.m.data.uv_textures.active.data[poly.index].image.filepath)
					except: pass					
				if not mat_name:
					mat_name = "Material"
					bad_face_mats += 1
					
				if not face_sets.get(mat_name):
					material_elem = materials.get(mat_name)
					if not material_elem:
						materials[mat_name] = material_elem = dm.add_element(mat_name,"DmeMaterial",id=mat_name + "mat")
						material_elem["mtlName"] = bpy.context.scene.smd_material_path + mat_name
					
					faceSet = dm.add_element(mat_name,"DmeFaceSet",id=ob_name+mat_name+"faces")
					faceSet["material"] = material_elem
					faceSet["faces"] = datamodel.make_array([],int)
					
					face_sets[mat_name] = faceSet
				
				face_list = face_sets[mat_name]["faces"]
				for vert in poly.vertices:
					face_list.append(vert_index)
					vert_index += 1
				face_list.append(-1)
			
			DmeMesh["faceSets"] = datamodel.make_array(list(face_sets.values()),datamodel.Element)
			if bad_face_mats:
				log.warning("{} faces on {} did not have a texture{} assigned".format(bad_face_mats,ob['src_name'],"" if bpy.context.scene.smd_use_image_names else " or material"))
			bench("faces")
			
			# shapes
			if has_shapes:
				shape_elems = []
				shape_names = []
				control_elems = []
				control_values = []
				delta_state_weights = []
				for shape in smd.dmxShapes[ob_name]:
					shape_name = shape['shape_name']
					shape_names.append(shape_name)
					wrinkle_vg = ob.vertex_groups.get(shape_name)
					
					if src_ob.smd_flex_controller_mode == 'SIMPLE':
						DmeCombinationInputControl = dm.add_element(shape_name,"DmeCombinationInputControl",id=ob_name+shape_name+"controller")
						control_elems.append(DmeCombinationInputControl)
					
						DmeCombinationInputControl["rawControlNames"] = datamodel.make_array([shape_name],str)					
						if wrinkle_vg:
							DmeCombinationInputControl["wrinkleScales"] = datamodel.make_array([1.0],float)					
						control_values.append(datamodel.Vector3([0.5,0.5,0.5])) # ??
					
					delta_state_weights.append(datamodel.Vector2([0.0,0.0])) # ??
					
					DmeVertexDeltaData = dm.add_element(shape_name,"DmeVertexDeltaData",id=ob_name+shape_name)					
					shape_elems.append(DmeVertexDeltaData)
					
					vertexFormat = DmeVertexDeltaData["vertexFormat"] = datamodel.make_array([ "positions", "normals" ],str)
					
					wrinkle = []
					wrinkleIndices = []
					
					if wrinkle_vg: vertexFormat.append("wrinkle")
					
					# what do these do?
					#DmeVertexDeltaData["flipVCoordinates"] = False
					#DmeVertexDeltaData["corrected"] = True
					
					shape_pos = []
					shape_posIndices = []
					shape_norms = []
					shape_normIndices = []
					
					for i in range(len(ob.data.vertices)):
						ob_vert = ob.data.vertices[i]
						shape_vert = shape.data.vertices[i]
						
						if ob_vert.co != shape_vert.co:
							shape_pos.append(datamodel.Vector3(shape_vert.co - ob_vert.co))
							shape_posIndices.append(i)
							
						if ob_vert.normal != shape_vert.normal:
							shape_norms.append(datamodel.Vector3(shape_vert.normal))
							shape_normIndices.append(i)
						
						if wrinkle_vg:
							try:
								wrinkle.append(wrinkle_vg.weight(i))
								wrinkleIndices.append(i)
							except RuntimeError:
								pass
					
					DmeVertexDeltaData["positions"] = datamodel.make_array(shape_pos,datamodel.Vector3)
					DmeVertexDeltaData["positionsIndices"] = datamodel.make_array(shape_posIndices,int)
					DmeVertexDeltaData["normals"] = datamodel.make_array(shape_norms,datamodel.Vector3)
					DmeVertexDeltaData["normalsIndices"] = datamodel.make_array(shape_normIndices,int)
					if wrinkle_vg:
						DmeVertexDeltaData["wrinkle"] = datamodel.make_array(wrinkle,float)
						DmeVertexDeltaData["wrinkleIndices"] = datamodel.make_array(wrinkleIndices,int)
					
					removeObject(shape)
					
				DmeMesh["deltaStates"] = datamodel.make_array(shape_elems,datamodel.Element)
				DmeMesh["deltaStateWeights"] = datamodel.make_array(delta_state_weights,datamodel.Vector2)
				DmeMesh["deltaStateWeightsLagged"] = datamodel.make_array(delta_state_weights,datamodel.Vector2)
				
				first_pass = not root.get("combinationOperator")
				if ob.smd_flex_controller_mode == 'ADVANCED':
					if first_pass:
						text = bpy.data.texts.get(ob.smd_flex_controller_source)
						msg = "- Loading flex controllers from "
						element_path = [ "combinationOperator" ]
						if text:
							print(msg + "text block \"{}\"".format(text.name))
							controller_dm = datamodel.parse(text.as_string(),element_path=element_path)
						else:
							path = bpy.path.abspath(ob.smd_flex_controller_source)
							print(msg + path)
							controller_dm = datamodel.load(path=path,element_path=element_path)
					
						DmeCombinationOperator = controller_dm.root["combinationOperator"]
						root["combinationOperator"] = DmeCombinationOperator
					
					# replace target meshes
					targets = DmeCombinationOperator["targets"]
					added = False
					for elem in targets:
						if elem.type == "DmeFlexRules":
							if elem["deltaStates"][0].name in shape_names: # can't have the same delta name on multiple objects
								elem["target"] = DmeMesh
								added = True
						elif first_pass:
							targets.remove(elem)
					if not added:
						targets.append(DmeMesh)
				else:					
					if first_pass:
						DmeCombinationOperator = dm.add_element("combinationOperator","DmeCombinationOperator",id="controllers")
						DmeCombinationOperator["controls"] = datamodel.make_array([],datamodel.Element)
						DmeCombinationOperator["controlValues"] = datamodel.make_array([],datamodel.Vector3)
						DmeCombinationOperator["usesLaggedValues"] = False
						DmeCombinationOperator["targets"] = datamodel.make_array([],datamodel.Element)
						
						root["combinationOperator"] = DmeCombinationOperator
						
					DmeCombinationOperator["controls"].extend(control_elems)
					DmeCombinationOperator["controlValues"].extend(control_values)
					DmeCombinationOperator["targets"].append(DmeMesh)
				
				bench("shapes")			
		
			removeObject(ob)
		
		DmeModel_children.extend(dags)
	
	if smd.jobType == ANIM: # animation
		action = smd.a.animation_data.action
		
		if ('fps') in dir(action):
			fps = bpy.context.scene.render.fps = action.fps
			bpy.context.scene.render.fps_base = 1
		else:
			fps = bpy.context.scene.render.fps * bpy.context.scene.render.fps_base
		
		DmeChannelsClip = dm.add_element(action.name,"DmeChannelsClip",id=action.name+"clip")		
		DmeAnimationList = dm.add_element(smd.a.name,"DmeAnimationList",id=action.name+"list")
		DmeAnimationList["animations"] = datamodel.make_array([DmeChannelsClip],datamodel.Element)
		root["animationList"] = DmeAnimationList
		
		DmeTimeFrame = dm.add_element("timeframe","DmeTimeFrame",id=action.name+"time")
		DmeTimeFrame["duration"] = datamodel.Time(action.frame_range[1] / fps)
		DmeTimeFrame["scale"] = 1.0
		DmeChannelsClip["timeFrame"] = DmeTimeFrame
		DmeChannelsClip["frameRate"] = int(fps)
		
		channels = DmeChannelsClip["channels"] = datamodel.make_array([],datamodel.Element)
		bone_channels = {}
		def makeChannel(bone):
			if bone: bone_channels[bone] = []
			channel_template = [
				[ "_p", "position", "Vector3", datamodel.Vector3 ],
				[ "_o", "orientation", "Quaternion", datamodel.Quaternion ]
			]
			name = bone.name if bone else "blender_implicit"
			for template in channel_template:
				cur = dm.add_element(name + template[0],"DmeChannel",id=name+template[0])
				cur["toAttribute"] = template[1]
				cur["toElement"] = bone_transforms[bone] if bone else jointTransforms[0]
				cur["mode"] = 1				
				val_arr = dm.add_element(template[2]+" log","Dme"+template[2]+"LogLayer",cur.name+"loglayer")				
				cur["log"] = dm.add_element(template[2]+" log","Dme"+template[2]+"Log",cur.name+"log")
				cur["log"]["layers"] = datamodel.make_array([val_arr],datamodel.Element)				
				val_arr["times"] = datamodel.make_array([],datamodel.Time)
				val_arr["values"] = datamodel.make_array([],template[3])
				if bone: bone_channels[bone].append(val_arr)
				channels.append(cur)
		
		for bone in smd.a.pose.bones:
			makeChannel(bone)
		num_frames = int(action.frame_range[1] + 1)
		bench("Animation setup")
		prev_pos = {}
		prev_rot = {}
		
		for frame in range(0,num_frames):
			bpy.context.scene.frame_set(frame)
			keyframe_time = datamodel.Time(frame / fps)
			for bone in smd.a.pose.bones:
				if bone.parent: relMat = bone.parent.matrix.inverted() * bone.matrix
				else: relMat = getUpAxisMat(smd.upAxis).inverted() * bone.matrix
				
				pos = relMat.to_translation()
				
				# Apply armature scale
				scale = smd.a.matrix_world.to_scale()
				for j in range(3):
					pos[j] *= scale[j]
				
				if not prev_pos.get(bone) or pos - prev_pos[bone] > epsilon:
					bone_channels[bone][0]["times"].append(keyframe_time)
					bone_channels[bone][0]["values"].append(datamodel.Vector3(pos))
				prev_pos[bone] = pos
				
				rot = relMat.to_quaternion()
				rot_vec = Vector(rot.to_euler())
				if not prev_rot.get(bone) or rot_vec - prev_rot[bone] > epsilon:
					bone_channels[bone][1]["times"].append(keyframe_time)
					bone_channels[bone][1]["values"].append(getDatamodelQuat(rot))
				prev_rot[bone] = rot_vec
				
			bench("frame {}".format(frame+1))
	
	benchReset()
	if bpy.context.scene.smd_use_kv2:
		dm.write(filepath,"keyvalues2",1)
	else:
		dm.write(filepath,"binary",DatamodelEncodingVersion())
	bench("Writing")
	
	print("DMX export took",time.time() - start,"\n")
	
	return True
		
def getQCs(path = None):
	import glob
	ext = ".qc"
	out = []
	internal = False
	if not path:
		path = bpy.path.abspath(bpy.context.scene.smd_qc_path)
		internal = True
	for result in glob.glob(path):
		if result.endswith(ext):
			out.append(result)

	if not internal and not len(out) and not path.endswith(ext):
		out = getQCs(path + ext)
	return out

def compileQCs(path=None):
	scene = bpy.context.scene
	branch = scene.smd_studiomdl_branch
	print("\n")

	sdk_path = os.getenv('SOURCESDK')
	ncf_path = None
	if sdk_path:
		ncf_path = sdk_path + "\\..\\..\\common\\"
	else:
		for path in [ os.getenv('PROGRAMFILES(X86)'), os.getenv('PROGRAMFILES') ]:
			path += "\\steam\\steamapps\\common"
			if os.path.exists(path):
				ncf_path = path

	studiomdl_path = None
	if branch in ['ep1','source2007','source2009', 'orangebox'] and sdk_path:
		studiomdl_path = sdk_path + "\\bin\\" + branch + "\\bin\\"
	elif branch in ['left 4 dead', 'left 4 dead 2', 'alien swarm', 'portal 2', 'Counter-Strike Global Offensive'] and ncf_path:
		studiomdl_path = ncf_path + branch + "\\bin\\"
	elif branch in ['SourceFilmmaker']:
		studiomdl_path = ncf_path + branch + "\\game\\bin\\"
	elif branch == 'CUSTOM':
		studiomdl_path = scene.smd_studiomdl_custom_path = bpy.path.abspath(scene.smd_studiomdl_custom_path)

	if not studiomdl_path:
		log.error("Could not locate Source SDK installation. Launch it to create the relevant files, or run a custom QC compile")
	else:
		if studiomdl_path and studiomdl_path[-1] in ['/','\\']:
			studiomdl_path += "studiomdl.exe"

		if path:
			qc_paths = [path]
		else:
			qc_paths = getQCs()
		num_good_compiles = 0
		if len( qc_paths ) == 0:
			log.error("Cannot compile, no QCs provided. The SMD Tools do not generate QCs.")
		elif not os.path.exists(studiomdl_path):
			log.error( "Could not execute studiomdl from \"{}\"".format(studiomdl_path) )
		else:
			for qc in qc_paths:	
				# save any version of the file currently open in Blender
				qc_mangled = qc.lower().replace('\\','/')
				for candidate_area in bpy.context.screen.areas:
					if candidate_area.type == 'TEXT_EDITOR' and candidate_area.spaces[0].text and candidate_area.spaces[0].text.filepath.lower().replace('\\','/') == qc_mangled:
						oldType = bpy.context.area.type
						bpy.context.area.type = 'TEXT_EDITOR'
						bpy.context.area.spaces[0].text = candidate_area.spaces[0].text
						bpy.ops.text.save()
						bpy.context.area.type = oldType
						break #what a farce!
				
				print( "Running studiomdl for \"{}\"...\n".format(os.path.basename(qc)) )
				studiomdl = subprocess.Popen([studiomdl_path, "-nop4", qc])
				studiomdl.communicate()

				if studiomdl.returncode == 0:
					num_good_compiles += 1
				else:
					log.error("Compile of {}.qc failed. Check the console for details".format(os.path.basename(qc)))
		return num_good_compiles

class SMD_MT_ExportChoice(bpy.types.Menu):
	bl_label = "SMD/DMX export mode"

	# returns an icon, a label, and the number of valid actions
	# supports single actions, NLA tracks, or nothing
	def getActionSingleTextIcon(self,context,ob = None):
		icon = "OUTLINER_DATA_ARMATURE"
		count = 0
		text = "No Actions or NLA"
		export_name = False
		if not ob:
			ob = context.active_object
			export_name = True # slight hack since having ob currently aligns with wanting a short name
		if ob:
			ad = ob.animation_data
			if ad:
				if ad.action:
					icon = "ACTION"
					count = 1
					if export_name:
						text = os.path.join(ob.smd_subdir,ad.action.name + getFileExt())
					else:
						text = ad.action.name
				elif ad.nla_tracks:
					nla_actions = []
					for track in ad.nla_tracks:
						if not track.mute:
							for strip in track.strips:
								if not strip.mute and strip.action not in nla_actions:
									nla_actions.append(strip.action)
					icon = "NLA"
					count = len(nla_actions)
					text = "NLA actions (" + str(count) + ")"

		return text,icon,count

	# returns the appropriate text for the filtered list of all action
	def getActionFilterText(self,context):
		ob = context.active_object
		if ob.smd_action_filter:
			global cached_action_filter_list
			global cached_action_count
			if ob.smd_action_filter != cached_action_filter_list:
				cached_action_filter_list = ob.smd_action_filter
				cached_action_count = 0
				for action in bpy.data.actions:
					if action.name.lower().find(ob.smd_action_filter.lower()) != -1:
						cached_action_count += 1
			return "\"{}\" actions ({})".format(ob.smd_action_filter,cached_action_count), cached_action_count
		else:
			return "All actions ({})".format(len(bpy.data.actions)), len(bpy.data.actions)

	def draw(self, context):
		# This function is also embedded in property panels on scenes and armatures
		l = self.layout
		ob = context.active_object

		try:
			l = self.embed_scene
			embed_scene = True
		except AttributeError:
			embed_scene = False
		try:
			l = self.embed_arm
			embed_arm = True
		except AttributeError:
			embed_arm = False
			
		selected_groups = set()
		for ob in context.selected_objects:
			for group in ob.users_group:
				selected_groups.add(group)

		if embed_scene and (len(context.selected_objects) == 0 or not ob):
			row = l.row()
			row.operator(SmdExporter.bl_idname, text="No selection") # filler to stop the scene button moving
			row.enabled = False

		# Normal processing
		# FIXME: in the properties panel, hidden objects appear in context.selected_objects...in the 3D view they do not
		elif (ob and len(context.selected_objects) <= 1 and len(selected_groups) <= 1) or embed_arm:
			if ob.type in mesh_compatible:
				want_single_export = True
				# Groups
				if ob.users_group:
					for i in range(len(ob.users_group)):
						group = ob.users_group[i]
						if not group.smd_mute:
							want_single_export = False
							label = group.name + getFileExt()
							if bpy.context.scene.smd_format == 'SMD':
								if hasShapes(ob,i):
									label += "/.vta"

							op = l.operator(SmdExporter.bl_idname, text=label, icon="GROUP") # group
							op.exportMode = 'SINGLE' # will be merged and exported as one
							op.groupIndex = i
							break
				# Single
				if want_single_export:
					label = getObExportName(ob) + getFileExt()
					if bpy.context.scene.smd_format == 'SMD' and hasShapes(ob):
						label += "/.vta"
					l.operator(SmdExporter.bl_idname, text=label, icon=MakeObjectIcon(ob,prefix="OUTLINER_OB_")).exportMode = 'SINGLE'


			elif ob.type == 'ARMATURE':
				if embed_arm or ob.data.smd_action_selection == 'CURRENT':
					text,icon,count = SMD_MT_ExportChoice.getActionSingleTextIcon(self,context)
					if count:
						l.operator(SmdExporter.bl_idname, text=text, icon=icon).exportMode = 'SINGLE_ANIM'
					else:
						l.label(text=text, icon=icon)
				if embed_arm or (len(bpy.data.actions) and ob.data.smd_action_selection == 'FILTERED'):
					# filtered action list
					l.operator(SmdExporter.bl_idname, text=SMD_MT_ExportChoice.getActionFilterText(self,context)[0], icon='ACTION').exportMode= 'SINGLE'

			else: # invalid object
				label = "Cannot export " + ob.name
				try:
					l.label(text=label,icon=MakeObjectIcon(ob,prefix='OUTLINER_OB_'))
				except: # bad icon
					l.label(text=label,icon='ERROR')

		# Multiple objects
		elif (len(context.selected_objects) > 1 or len(selected_groups) > 1) and not embed_arm:
			l.operator(SmdExporter.bl_idname, text="Selected objects\\groups", icon='GROUP').exportMode = 'MULTI' # multiple obects

		if not embed_arm:
			l.operator(SmdExporter.bl_idname, text="Scene export ({})".format(count_exports(context)), icon='SCENE_DATA').exportMode = 'SCENE'

class SMD_OT_Compile(bpy.types.Operator):
	bl_idname = "smd.compile_qc"
	bl_label = "Compile QC"
	bl_description = "Compile QCs with the Source SDK"

	filepath = StringProperty(name="File path", description="QC to compile", maxlen=1024, default="", subtype='FILE_PATH')
	
	@classmethod
	def poll(self,context):
		return vproject != False

	def execute(self,context):
		global log
		log = logger()
		num = compileQCs(self.properties.filepath)
		if not self.properties.filepath:
			self.properties.filepath = "QC"
		log.errorReport("compiled","{} QC".format(getEngineBranchName()),self, num)
		return {'FINISHED'}

def getValidObs():
	validObs = []
	s = bpy.context.scene
	for o in s.objects:
		if o.type in exportable_types:
			if s.smd_layer_filter:
				for i in range( len(o.layers) ):
					if o.layers[i] and s.layers[i]:
						validObs.append(o)
						break
			else:
				validObs.append(o)
	return validObs

qc_path = qc_paths = qc_path_last_update = 0
class SMD_PT_Scene(bpy.types.Panel):
	bl_label = "Source Engine Export"
	bl_space_type = "PROPERTIES"
	bl_region_type = "WINDOW"
	bl_context = "scene"
	bl_default_closed = True

	def draw(self, context):
		l = self.layout
		scene = context.scene
		num_to_export = 0

		self.embed_scene = l.row()
		SMD_MT_ExportChoice.draw(self,context)

		l.prop(scene,"smd_path",text="Output Folder")
		l.prop(scene,"smd_studiomdl_branch",text="Target Engine")
		if scene.smd_studiomdl_branch == 'CUSTOM':
			l.prop(scene,"smd_studiomdl_custom_path",text="Studiomdl path")
			row = l.row(align=True)
			row.prop(scene,"smd_studiomdl_custom_path_dmx_encoding",text="DMX binary",slider=False)
			row.prop(scene,"smd_studiomdl_custom_path_dmx_format",text="Model format",slider=False)
		row = l.row().split(0.33)
		row.label(text="Output Format:")
		row.row().prop(scene,"smd_format",text="Format",expand=True)
		row.enabled = canExportDMX(scene)
		row = l.row().split(0.33)
		row.label(text="Target Up Axis:")
		row.row().prop(scene,"smd_up_axis", expand=True)
		if shouldExportDMX(scene):
			l.prop(scene,"smd_material_path",text="Material Path")
		row = l.row()
		row.alignment = 'CENTER'
		row.prop(scene,"smd_layer_filter",text="Visible layer(s) only")
		row.prop(scene,"smd_use_image_names",text="Ignore Blender materials")

		row = l.row(align=True)
		row.operator("wm.url_open",text="Help",icon='HELP').url = "http://developer.valvesoftware.com/wiki/Blender_SMD_Tools_Help#Exporting"
		row.operator(SmdToolsUpdate.bl_idname,text="Check for updates",icon='URL')		

class SMD_UL_ExportItems(bpy.types.UIList):
	def draw_item(self, context, layout, data, item, icon, active_data, active_propname, index):
		id = item.get_id()
		row = layout.row(align=True)
		if type(id) == bpy.types.Group:
			row.enabled = id.smd_mute == False
			
		row.prop(id,"smd_export",icon='CHECKBOX_HLT' if id.smd_export and row.enabled else 'CHECKBOX_DEHLT',text="",emboss=False)
		row.label(item.name,icon=item.icon)

class SMD_PT_Object_Config(bpy.types.Panel):
	bl_label = "Source Engine Exportables"
	bl_space_type = "PROPERTIES"
	bl_region_type = "WINDOW"
	bl_context = "scene"
	bl_default_closed = True
	
	def draw(self,context):
		l = self.layout
		scene = context.scene
		
		l.template_list("SMD_UL_ExportItems","",scene,"smd_export_list",scene,"smd_export_list_active",rows=3,maxrows=8)
		
		if not len(scene.smd_export_list):
			return
			
		active_item = scene.smd_export_list[scene.smd_export_list_active]
		item = (bpy.data.groups if active_item.type == 'GROUP' else bpy.data.objects)[active_item.item_name]
		
		validObs = getValidObs()
		
		want_shapes = False
		is_group = type(item) == bpy.types.Group
		
		col = l.column()
		
		if not (is_group and item.smd_mute):
			col.prop(item,"smd_subdir",text="Subfolder",icon='FILE_FOLDER')
		
		if is_group:
			col = makeSettingsBox(l,text="Group properties",icon='GROUP')
			if not item.smd_mute:				
				items = 0
				item_list = col.column(align=True)
				for g_ob in item.objects:
					if g_ob in validObs:
						if items % 2 == 0:
							row = item_list.row(align=True)
						row.prop(g_ob,"smd_export",icon=MakeObjectIcon(g_ob,suffix="_DATA"),text=g_ob.name)
						if hasShapes(g_ob,-1) and g_ob.smd_export: want_shapes = g_ob
						items += 1
				if items % 2 != 0: row.label(text="")
			
			suppress_row = col.row()
			suppress_row.alignment = 'CENTER'
			suppress_row.prop(item,"smd_mute",text="Suppress")
			if item.smd_mute:
				return
		elif item:
			armature = item.find_armature()
			if item.type == 'ARMATURE': armature = item
			if armature:
				col = makeSettingsBox(l,text="Armature properties ({})".format(armature.name),icon='OUTLINER_OB_ARMATURE')
				if armature == item: # only display action stuff if the user has actually selected the armature
					col.row().prop(armature.data,"smd_action_selection",expand=True)
					if armature.data.smd_action_selection == 'FILTERED':
						col.prop(armature,"smd_action_filter",text="Action Filter")

				col.prop(armature.data,"smd_implicit_zero_bone")
				if not shouldExportDMX(scene):
					col.prop(armature.data,"smd_legacy_rotation")
					
				if armature.animation_data and not 'ActLib' in dir(bpy.types):
					col.template_ID(armature.animation_data, "action", new="action.new")
			if item.type == 'CURVE':
				col = makeSettingsBox(l,text="Curve properties",icon='OUTLINER_OB_CURVE')
				col.label(text="Generate polygons on:")
				row = col.row()
				row.prop(item.data,"smd_faces",expand=True)
		
			if hasShapes(item,-1): want_shapes = item
		
		if want_shapes and bpy.context.scene.smd_format == 'DMX':
			col = makeSettingsBox(l,text="Flex properties",icon='SHAPEKEY_DATA')
			
			objects = item.objects if is_group else [item]
			
			col.row().prop(item,"smd_flex_controller_mode",expand=True)
			
			if item.smd_flex_controller_mode == 'ADVANCED':
				controller_source = col.row()
				controller_source.alert = hasFlexControllerSource(item) == False
				controller_source.prop(item,"smd_flex_controller_source",text="Controller source",icon = 'TEXT' if item.smd_flex_controller_source in bpy.data.texts else 'NONE')
				
				row = col.row(align=True)
				row.context_pointer_set("active_object",objects[0])
				row.operator(DmxWriteFlexControllers.bl_idname,icon='TEXT',text="Generate controllers")
				row.operator("wm.url_open",text="Flex controller help",icon='HELP').url = "http://developer.valvesoftware.com/wiki/Blender_SMD_Tools_Help#Flex_properties"
				
				datablocks_dispayed = []
				
				for ob in objects:
					if ob.smd_export and ob.type in shape_types and ob.active_shape_key and ob.data not in datablocks_dispayed:
						if not len(datablocks_dispayed): col.separator()
						col.prop(ob.data,"smd_flex_stereo_sharpness",text="Stereo sharpness ({})".format(ob.data.name))
						datablocks_dispayed.append(ob.data)
			
			num_shapes = 0
			num_wrinkle_maps = 0
			for ob in objects:
				if hasShapes(ob):
					for shape in ob.data.shape_keys.key_blocks[1:]:
						num_shapes += 1
						if ob.vertex_groups.get(shape.name):
							num_wrinkle_maps += 1
			
			col.separator()
			row = col.row()
			row.alignment = 'CENTER'
			row.label(icon='SHAPEKEY_DATA',text = "{} shape{}".format(num_shapes,"s" if num_shapes != 1 else ""))
			row.label(icon='GROUP_VERTEX',text="{} wrinkle map{}".format(num_wrinkle_maps,"s" if num_wrinkle_maps != 1 else ""))
			
class SMD_PT_Scene_QC_Complie(bpy.types.Panel):
	bl_label = "Source Engine QC Complies ({})".format(vproject if vproject else "no game")
	bl_space_type = "PROPERTIES"
	bl_region_type = "WINDOW"
	bl_context = "scene"
	bl_default_closed = True				
		
	def draw(self,context):
		l = self.layout
		scene = context.scene
		
		# QCs
		global qc_path
		global qc_paths
		global qc_path_last_update
		
		qc_path_row = l.row()
		if scene.smd_qc_path != qc_path or not qc_paths or time.time() > qc_path_last_update + 2:
			qc_paths = getQCs()
			qc_path = scene.smd_qc_path
		qc_path_last_update = time.time()
		have_qcs = len(qc_paths) > 0
	
		if have_qcs or isWild(qc_path):
			c = l.column_flow(2)
			for path in qc_paths:
				c.operator(SMD_OT_Compile.bl_idname,text=os.path.basename(path)).filepath = path
		
		error_row = l.row()
		compile_row = l.row()
		compile_row.prop(scene,"smd_qc_compile")
		compile_row.operator(SMD_OT_Compile.bl_idname,text="Compile all now",icon='SCRIPT')
		
		if not have_qcs:
			if scene.smd_qc_path:
				qc_path_row.alert = True
			compile_row.enabled = False
		qc_path_row.prop(scene,"smd_qc_path",text="QC file path") # can't add this until the above test completes!

class DmxWriteFlexControllers(bpy.types.Operator):
	'''Generate a simple Flex Controller DMX block'''
	bl_idname = "export_scene.dmx_flex_controller"
	bl_label = "Generate DMX Flex Controller block"
	
	@classmethod
	def poll(self, context):
		if context.active_object:
			group_index = -1
			for i,g in enumerate(context.active_object.users_group):
				if not g.smd_mute:
					group_index = i
					break
			return hasShapes(context.active_object,group_index)
		else:
			return False
	
	def execute(self, context):
		ob = bpy.context.active_object
		dm = datamodel.DataModel("model",18)
		
		root = dm.add_element("root",id=ob.name)
		DmeCombinationOperator = dm.add_element("combinationOperator","DmeCombinationOperator",id=ob.name+"controllers")
		root["combinationOperator"] = DmeCombinationOperator
		controls = DmeCombinationOperator["controls"] = datamodel.make_array([],datamodel.Element)
		
		text_name = ob.name
		objects = []
		shapes = []
		target = ob
		for g in ob.users_group:
			if not g.smd_mute:
				text_name = g.name
				target = g
				for g_ob in g.objects:
					if g_ob.smd_export and hasShapes(g_ob):
						objects.append(g_ob)
				break
		
		for ob in objects:
			for shape in ob.data.shape_keys.key_blocks[1:]:
				DmeCombinationInputControl = dm.add_element(shape.name,"DmeCombinationInputControl",id=ob.name+shape.name)
				controls.append(DmeCombinationInputControl)
				
				DmeCombinationInputControl["rawControlNames"] = datamodel.make_array([shape.name],str)
				DmeCombinationInputControl["stereo"] = False
				DmeCombinationInputControl["eyelid"] = False
				
				DmeCombinationInputControl["flexMax"] = 1.0
				DmeCombinationInputControl["flexMin"] = 0.0
				
				DmeCombinationInputControl["wrinkleScales"] = datamodel.make_array([1.0],float)
				
		controlValues = DmeCombinationOperator["controlValues"] = datamodel.make_array( [ [0.0,0.0,0.5] ] * len(controls), datamodel.Vector3)
		DmeCombinationOperator["controlValuesLagged"] = datamodel.make_array( controlValues, datamodel.Vector3)
		DmeCombinationOperator["usesLaggedValues"] = False
		
		DmeCombinationOperator["dominators"] = datamodel.make_array([],datamodel.Element)
		targets = DmeCombinationOperator["targets"] = datamodel.make_array([],datamodel.Element)
		
		for ob in objects:
			DmeFlexRules = dm.add_element("flexRules","DmeFlexRules",id=ob.name+"rules")
			targets.append(DmeFlexRules)
			
			delta_states = DmeFlexRules["deltaStates"] = datamodel.make_array([],datamodel.Element)
		
			for shape in ob.data.shape_keys.key_blocks[1:]:
				DmeFlexRule = dm.add_element(shape.name,"DmeFlexRulePassThrough",id=ob.name+shape.name+"passthrough")
				DmeFlexRule["result"] = 0.0
				DmeFlexRule["expr"] = "" # ignored unless element type is "DmeFlexRule"
				delta_states.append(DmeFlexRule)
				
			DmeFlexRules["deltaStateWeights"] = datamodel.make_array([ [0.0,0.0] ] * len(delta_states),datamodel.Vector2)
			DmeFlexRules["target"] = datamodel.make_array([],datamodel.Element)
		
		text = bpy.data.texts.new( "flex_{}".format(text_name) )
		text.use_tabs_as_spaces = False
		text.from_string(dm.echo("keyvalues2",1))
		
		if not target.smd_flex_controller_source:
			target.smd_flex_controller_source = text.name
		
		self.report({'INFO'},"DMX written to text block \"{}\"".format(text.name))		
		
		return {'FINISHED'}

class SmdExporter(bpy.types.Operator):
	'''Export SMD or DMX files and compile them with QC scripts'''
	bl_idname = "export_scene.smd"
	bl_label = "Export SMD/VTA/DMX"

	directory = StringProperty(name="Export root", description="The root folder into which SMDs from this scene are written", subtype='DIR_PATH')	
	filename = StringProperty(default="", options={'HIDDEN'})

	exportMode_enum = (
		('NONE','No mode','The user will be prompted to choose a mode'),
		('SINGLE','Active','Only the active object'),
		('SINGLE_ANIM','Current action',"Exports the active Armature's current Action"),
		('MULTI','Selection','All selected objects'),
		('SCENE','Scene','Export the objects and animations selected in Scene Properties'),
		)
	exportMode = EnumProperty(items=exportMode_enum,options={'HIDDEN'})
	groupIndex = IntProperty(default=-1,options={'HIDDEN'})

	def execute(self, context):
		if not ValidateBlenderVersion(self):
			return {'CANCELLED'}

		props = self.properties

		if props.exportMode == 'NONE':
			self.report({'ERROR'},"Programmer error: bpy.ops.{} called without exportMode".format(SmdExporter.bl_idname))
			return {'CANCELLED'}
			
		if context.scene.smd_format == 'DMX':
			datamodel.check_support("binary",DatamodelEncodingVersion())

		# Handle export root path
		if len(props.directory):
			# We've got a file path from the file selector (or direct invocation)
			context.scene['smd_path'] = props.directory
		else:
			# Get a path from the scene object
			export_root = context.scene.get("smd_path")

			# No root defined, pop up a file select
			if not export_root:
				props.filename = "*** [Please choose a root folder for exports from this scene] ***"
				context.window_manager.fileselect_add(self)
				return {'RUNNING_MODAL'}

			if export_root.startswith("//") and not bpy.context.blend_data.filepath:
				self.report({'ERROR'},"Relative scene output path, but .blend not saved")
				return {'CANCELLED'}

			if export_root[-1] not in ['\\','/']: # append trailing slash
				export_root += os.path.sep		

			props.directory = export_root

		global log
		log = logger()
		
		# Creating an undo level from edit mode is buggy in 2.64a
		prev_mode = None
		if bpy.context.active_object:
			prev_mode = bpy.context.mode.split("_")[0]
			bpy.ops.object.mode_set(mode='OBJECT')
		
		bpy.ops.ed.undo_push(message=self.bl_label)
		
		try:
			bpy.context.tool_settings.use_keyframe_insert_auto = False
			bpy.context.tool_settings.use_keyframe_insert_keyingset = False
			
			if props.exportMode == 'SINGLE_ANIM': # really hacky, hopefully this will stay a one-off!
				if context.active_object.type == 'ARMATURE':
					context.active_object.data.smd_action_selection = 'CURRENT'
				props.exportMode = 'SINGLE'

			print("\nSMD EXPORTER RUNNING")

			self.validObs = getValidObs()
			
			# lots of operators only work on visible objects
			for object in bpy.context.scene.objects:
				object.hide = False
			bpy.context.scene.layers = [True] * len(bpy.context.scene.layers)

			# check export mode and perform appropriate jobs
			self.countSMDs = 0
			if props.exportMode == 'SINGLE':
				ob = context.active_object
				group_name = None
				if props.groupIndex != -1:
					# handle the selected object being in a group, but disabled
					try:
						group_name = ob.users_group[props.groupIndex].name
						for g_ob in ob.users_group[props.groupIndex].objects:
							if g_ob.smd_export:
								ob = g_ob
								break
							else:
								ob = None
					except IndexError:
						pass # Blender saved settings from a previous run, doh!

				if ob:
					self.exportObject(context,context.active_object,groupIndex=props.groupIndex)
				else:
					log.error("The group \"" + group_name + "\" has no active objects")
					return {'CANCELLED'}


			elif props.exportMode == 'MULTI':
				exported_groups = []
				for object in context.selected_objects:
					if object.type in mesh_compatible:
						if object.users_group:
							if object.smd_export:
								for i in range(len(object.users_group)):
									if object.users_group[i] not in exported_groups:
										exported_groups.append(object.users_group[i])
										self.exportObject(context,object,groupIndex=i)
						else:
							self.exportObject(context,object)
					elif object.type == 'ARMATURE':
						self.exportObject(context,object)

			elif props.exportMode == 'SCENE':
				for group in bpy.data.groups:
					group_objects = group.objects[:] # avoid pollution from the baking process
					if shouldExportGroup(group):
						for object in group_objects:
							if object.smd_export and object in self.validObs and object.type != 'ARMATURE':
								g_index = -1
								for i in range(len(object.users_group)):
									if object.users_group[i] == group:
										g_index = i
										break
								self.exportObject(context,object,groupIndex=g_index)
								break # only export the first valid object
				for object in getValidObs():
					if object.smd_export:
						should_export = True
						if object.users_group and object.type != 'ARMATURE':
							for group in object.users_group:
								if not group.smd_mute:
									should_export = False
									break
						if should_export:
							self.exportObject(context,object)

			jobMessage = "exported"

			if self.countSMDs == 0:
				log.error("Found no valid objects for export")
			elif context.scene.smd_qc_compile and context.scene.smd_qc_path:
				# ...and compile the QC
				num_good_compiles = compileQCs()
				jobMessage += " and {} {} QC{} compiled".format(num_good_compiles, getEngineBranchName(), "" if num_good_compiles == 1 else "s")
				print("\n")
				
			log.errorReport(jobMessage,"file",self,self.countSMDs)
		finally:
			# Clean everything up
			bpy.ops.ed.undo_push(message=self.bl_label)
			bpy.ops.ed.undo()
			
			if prev_mode:
				bpy.ops.object.mode_set(mode=prev_mode)
			
			props.directory = ""
			props.groupIndex = -1

		return {'FINISHED'}

	# indirection to support batch exporting
	def exportObject(self,context,object,flex=False,groupIndex=-1):
		props = self.properties

		if groupIndex == -1:
			if not object in self.validObs:
				return
		else:
			if len(set(self.validObs).intersection( set(object.users_group[groupIndex].objects) )) == 0:
				return
				
		# handle subfolder
		if len(object.smd_subdir) == 0 and object.type == 'ARMATURE':
			object.smd_subdir = "anims"
		object.smd_subdir = object.smd_subdir.lstrip("/") # don't want //s here!

		if object.type == 'ARMATURE' and not object.animation_data:
			return; # otherwise we create a folder but put nothing in it

		# assemble filename
		path = os.path.join( bpy.path.abspath(os.path.dirname(props.directory)), object.smd_subdir)
		if not os.path.exists(path):
			os.makedirs(path)

		if object.type in mesh_compatible:
			if groupIndex == -1: path = os.path.join(path,getObExportName(object))
			else: path = os.path.join(path,object.users_group[groupIndex].name)
			
			if writeSMD(context, object, groupIndex, path + getFileExt()):
				self.countSMDs += 1
			if bpy.context.scene.smd_format == 'SMD' and hasShapes(object,groupIndex): # DMX will export mesh and shapes to the same file
				if writeSMD(context, object, groupIndex, path + getFileExt(flex=True), FLEX):
					self.countSMDs += 1
		elif object.type == 'ARMATURE':
			ad = object.animation_data
			
			if object.data.smd_action_selection == 'FILTERED':
				for action in bpy.data.actions:
					if action.users and (not object.smd_action_filter or action.name.lower().find(object.smd_action_filter.lower()) != -1):
						ad.action = action
						if writeSMD(context,object, -1, os.path.join(path, action.name + getFileExt() ), ANIM):
							self.countSMDs += 1
			elif object.animation_data:
				if ad.action:
					if writeSMD(context,object,-1, os.path.join(path, ad.action.name + getFileExt() ), ANIM):
						self.countSMDs += 1
				elif len(ad.nla_tracks):
					nla_actions = []
					for track in ad.nla_tracks:
						if not track.mute:
							for strip in track.strips:
								if not strip.mute and strip.action not in nla_actions:
									nla_actions.append(strip.action)
									ad.action = strip.action
									if writeSMD(context,object,-1,os.path.join(path, ad.action.name + getFileExt()), ANIM):
										self.countSMDs += 1

	def invoke(self, context, event):
		if not ValidateBlenderVersion(self):
			return {'CANCELLED'}
		if self.properties.exportMode == 'NONE':
			bpy.ops.wm.call_menu(name="SMD_MT_ExportChoice")
			return {'PASS_THROUGH'}
		else: # a UI element has chosen a mode for us
			return self.execute(context)

class SmdClean(bpy.types.Operator):
	bl_idname = "smd.clean"
	bl_label = "Clean SMD data"
	bl_description = "Deletes SMD-related properties"
	bl_options = {'REGISTER', 'UNDO'}

	mode = EnumProperty(items=( ('OBJECT','Object','Active object'), ('ARMATURE','Armature','Armature bones and actions'), ('SCENE','Scene','Scene and all contents') ),default='SCENE')

	def execute(self,context):
		self.numPropsRemoved = 0
		def removeProps(object,bones=False):
			if not bones:
				for prop in object.items():
					if prop[0].startswith("smd_"):
						del object[prop[0]]
						self.numPropsRemoved += 1

			if bones and object.type == 'ARMATURE':
				# For some reason deleting custom properties from bones doesn't work well in Edit Mode
				bpy.context.scene.objects.active = object
				object_mode = object.mode
				bpy.ops.object.mode_set(mode='OBJECT')
				for bone in object.data.bones:
					removeProps(bone)
				bpy.ops.object.mode_set(mode=object_mode)
			
			if type(object) == bpy.types.Object and object.type == 'ARMATURE': # clean from actions too
				if object.data.smd_action_selection == 'CURRENT':
					if object.animation_data and object.animation_data.action:
						removeProps(object.animation_data.action)
				else:
					for action in bpy.data.actions:
						if action.name.lower().find( object.data.smd_action_filter.lower() ) != -1:
							removeProps(action)

		active_obj = bpy.context.active_object
		active_mode = active_obj.mode if active_obj else None

		if self.properties.mode == 'SCENE':
			for object in context.scene.objects:
				removeProps(object)
					
			for group in bpy.data.groups:
				for g_ob in group.objects:
					if context.scene in g_ob.users_scene:
						removeProps(group)
			removeProps(context.scene)

		elif self.properties.mode == 'OBJECT':
			removeProps(active_obj)

		elif self.properties.mode == 'ARMATURE':
			assert(active_obj.type == 'ARMATURE')
			removeProps(active_obj,bones=True)			

		bpy.context.scene.objects.active = active_obj
		if active_obj:
			bpy.ops.object.mode_set(mode=active_mode)

		bpy.data.objects.is_updated = True
		self.report({'INFO'},"Deleted {} SMD properties".format(self.numPropsRemoved))
		return {'FINISHED'}		

########################
#        Update        #
########################
# DISABLE THIS if you make third-party changes to the script!

class SMD_MT_Updated(bpy.types.Menu):
	bl_label = "SMD Tools update"
	def draw(self,context):
		self.layout.operator("wm.url_open",text="View changes?",icon='TEXT').url = "http://code.google.com/p/blender-smd/wiki/Changelog"

updater_supported = True
try:
	import urllib.request, urllib.error, xml.parsers.expat, zipfile
except:
	updater_supported = False

class SmdToolsUpdate(bpy.types.Operator):
	bl_idname = "script.update_smd"
	bl_label = "Check for SMD Tools updates"
	bl_description = "Connects to https://code.google.com/p/blender-smd/"
	
	@classmethod
	def poll(self,context):
		return updater_supported

	def execute(self,context):	
		print("SMD Tools update...")
					
		self.cur_entry = \
		self.result = None
		self.rss_entries = []

		def startElem(name,attrs):
			if name == "entry":
				self.cur_entry = {'version': 0, 'bpy': 0 }
				self.rss_entries.append(self.cur_entry)
			if not self.cur_entry: return

			if name == "content":
				magic_words = [ "Blender SMD Tools ", " bpy-" ]

				def readContent(data):
					for i in range( len(magic_words) ):
						if data[: len(magic_words[i]) ] == magic_words[i]:
							self.cur_entry['version' if i == 0 else 'bpy'] = data[ len(magic_words[i]) :].split()[0].split(".")

					if self.cur_entry['version'] and self.cur_entry['bpy']:
						for val in self.cur_entry.values():
							while len(val) < 3:
								val.append('0')

				parser.CharacterDataHandler = readContent

		def endElem(name):
			if name == "entry": self.cur_entry = None
			if name == "feed":
				if len(self.rss_entries):
					self.update()
				else:
					self.result = 'FAIL_PARSE'
			elif name == "content":
				if not (self.cur_entry['version'] and self.cur_entry['bpy']):
					self.rss_entries.pop()
				parser.CharacterDataHandler = None # don't read chars until the next content elem

		try:
			# parse RSS
			feed = urllib.request.urlopen("https://code.google.com/feeds/p/blender-smd/downloads/basic")
			parser = xml.parsers.expat.ParserCreate()
			parser.StartElementHandler = startElem
			parser.EndElementHandler = endElem

			parser.Parse(feed.read())
			
		except urllib.error.URLError as err:		
			self.report({'ERROR'},"Could not complete download: " + str(err))
			return {'CANCELLED'}
		except xml.parsers.expat.ExpatError as err:
			print(err)
			self.report({'ERROR'},"Version information was downloaded, but could not be parsed.")
			print(feed.read())
			return {'CANCELLED'}
		except zipfile.BadZipfile:
			self.report({'ERROR'},"Update was downloaded, but was corrupt")
			return {'CANCELLED'}
		except IOError as err:
			self.report({'ERROR'},"Could not install update: " + str(err))
			return {'CANCELLED'}
	
		if self.result == 'INCOMPATIBLE':
			self.report({'ERROR'},"The latest SMD Tools require Blender {}. Please upgrade.".format( PrintVer(self.cur_entry['bpy']) ))
			return {'FINISHED'}
		elif self.result == 'LATEST':
			self.report({'INFO'},"The latest SMD Tools ({}) are already installed.".format( PrintVer(bl_info['version']) ))
			return {'FINISHED'}

		elif self.result == 'SUCCESS':
			bpy.ops.script.reload()
			self.report({'INFO'},"Upgraded to SMD Tools {}!".format(self.remote_ver_str))
			bpy.ops.wm.call_menu(name="SMD_MT_Updated")
			return {'FINISHED'}

		else:
			print("Unhandled error!")
			print(self.result)
			print(self.cur_entry)
			assert(0) # unhandled error!
			return {'CANCELLED'}

	def update(self):
		cur_ver = bl_info['version']
		self.cur_entry = None

		for entry in self.rss_entries:
			remote_ver = entry['version']
			remote_bpy = entry['bpy']
			stable_api = (2,58,0)
			for i in range(min( len(remote_bpy), len(bpy.app.version) )):
				if int(remote_bpy[i]) > stable_api[i] and int(remote_bpy[i]) > bpy.app.version[i]:
					remote_ver = None

			if not remote_ver:
				if not self.cur_entry:
					self.result = 'INCOMPATIBLE'
			else:
				for i in range(min( len(remote_ver), len(cur_ver) )):
					try:
						diff = int(remote_ver[i]) - int(cur_ver[i])
					except ValueError:
						continue
					if diff > 0:
						self.cur_entry = entry
						self.remote_ver_str = PrintVer(remote_ver)
						break
					elif diff < 0:
						break

		if not self.cur_entry:
			self.result = 'LATEST'
			return
		
		# Added dots support with 1.1 to avoid any future collisions between 1.0.1 and 10.1 etc.
		url_template = "https://blender-smd.googlecode.com/files/io_smd_tools-{}.zip"
		url_dots = url_template.format( PrintVer(self.cur_entry['version'],sep=".") )
		url = url_template.format( PrintVer(self.cur_entry['version'],sep="") )
		
		print("Found new version {}, downloading from {}...".format(self.remote_ver_str, url_dots))

		# we are already in a try/except block, any unhandled failures will be caught
		try:
			zip = urllib.request.urlopen(url_dots)
		except:
			zip = urllib.request.urlopen(url)
		zip = zipfile.ZipFile( io.BytesIO(zip.read()) )
		zip.extractall(path=os.path.dirname( os.path.abspath( __file__ ) ))
		self.result = 'SUCCESS'
		return


#####################################
#        Shared registration        #
#####################################

def menu_func_import(self, context):
	self.layout.operator(SmdImporter.bl_idname, text="Source Engine (.smd, .vta, .dmx, .qc)")

def menu_func_export(self, context):
	self.layout.operator(SmdExporter.bl_idname, text="Source Engine (.smd, .vta, .dmx)")

@persistent
def scene_update(scene):
	if not (bpy.data.groups.is_updated or bpy.data.objects.is_updated or bpy.data.scenes.is_updated or bpy.data.actions.is_updated or bpy.data.groups.is_updated):
		return
	
	scene.smd_export_list.clear()
	validObs = getValidObs()
	
	def makeDisplayName(item,action = None):
		out = os.path.join(item.smd_subdir, getObExportName(action if action else item) + getFileExt())
		#if hasShapes(item):
		#	out += " (shapes)"
		return out
	
	if len(validObs):
		validObs.sort(key=lambda ob: ob.name.lower())
		
		groups_sorted = bpy.data.groups[:]
		groups_sorted.sort(key=lambda g: g.name.lower())
		
		scene_groups = []
		for group in groups_sorted:
			valid = False
			for object in group.objects:
				if object in validObs:
					if not group.smd_mute:
						validObs.remove(object)
					valid = True
			if valid:
				scene_groups.append(group)
				
		for g in scene_groups:
			i = scene.smd_export_list.add()
			if g.smd_mute:
				i.name = g.name + " (suppressed)"
			else:
				i.name = makeDisplayName(g)
			i.item_name = g.name
			i.icon = i.type = "GROUP"
			
			
		for ob in validObs:
			i_name = i_type = i_icon = None
			if ob.type == 'ARMATURE':
				if ob.animation_data and ob.animation_data.action:
					i_name = makeDisplayName(ob,ob.animation_data.action)
					i_icon = i_type = "ACTION"
			else:
				i_name = makeDisplayName(ob)
				i_icon = MakeObjectIcon(ob,prefix="OUTLINER_OB_")
				i_type = "OBJECT"
			if i_name:
				i = scene.smd_export_list.add()
				i.name = i_name
				i.type = i_type
				i.icon = i_icon
				i.item_name = ob.name

def count_exports(context):
	num = 0
	for exportable in context.scene.smd_export_list:
		if exportable.get_id().smd_export:
			num += 1
	return num

def export_active_changed(self, context):
	id = context.scene.smd_export_list[context.scene.smd_export_list_active].get_id()
	
	if type(id) == bpy.types.Group and id.smd_mute: return
	for ob in context.scene.objects: ob.select = False
	
	if type(id) == bpy.types.Group:
		context.scene.objects.active = id.objects[0]
		for ob in id.objects: ob.select = True
	else:
		id.select = True
		context.scene.objects.active = id

def register():
	bpy.utils.register_module(__name__)
	bpy.types.INFO_MT_file_import.append(menu_func_import)
	bpy.types.INFO_MT_file_export.append(menu_func_export)
	bpy.app.handlers.scene_update_post.append(scene_update)

	global cached_action_filter_list
	cached_action_filter_list = 0

	bpy.types.Scene.smd_path = StringProperty(name="SMD Export Root",description="The root folder into which SMDs from this scene are written", subtype='DIR_PATH')
	bpy.types.Scene.smd_qc_compile = BoolProperty(name="Compile all on export",description="Compile all QC files whenever anything is exported",default=False)
	bpy.types.Scene.smd_qc_path = StringProperty(name="QC Path",description="Location of this scene's QC file(s); Unix wildcards supported", subtype="FILE_PATH")
	bpy.types.Scene.smd_studiomdl_branch = EnumProperty(name="SMD Target Engine Branch",items=src_branches,description="Determines DMX version and Studiomdl path",default='source2009')
	bpy.types.Scene.smd_studiomdl_custom_path = StringProperty(name="SMD Custom Studiomdl Path",description="Location of studiomdl.exe for a custom compile", subtype="FILE_PATH")
	bpy.types.Scene.smd_studiomdl_custom_path_dmx_encoding = IntProperty(name="SMD Custom DMX encoding",description="Version of the binary DMX encoding to export",subtype='UNSIGNED')
	bpy.types.Scene.smd_studiomdl_custom_path_dmx_format = IntProperty(name="SMD Custom DMX format",description="Version of the DMX model format to export",subtype='UNSIGNED')
	bpy.types.Scene.smd_up_axis = EnumProperty(name="SMD Target Up Axis",items=axes,default='Z',description="Use for compatibility with existing SMDs")
	formats = (
	('SMD', "SMD", "Studiomdl Data" ),
	('DMX', "DMX", "Data Model Exchange" )
	)
	bpy.types.Scene.smd_format = EnumProperty(name="SMD Export Format",items=formats,default='SMD')
	bpy.types.Scene.smd_use_image_names = BoolProperty(name="SMD Ignore Materials",description="Only export face-assigned image filenames",default=False)
	bpy.types.Scene.smd_layer_filter = BoolProperty(name="SMD Export visible layers only",description="Only consider objects in active viewport layers for export",default=False)
	bpy.types.Scene.smd_material_path = StringProperty(name="DMX material path",description="Folder relative to game root containing VMTs referenced in this scene (DMX only)")
	bpy.types.Scene.smd_export_list_active = IntProperty(name="SMD active object",default=0,update=export_active_changed)
	bpy.types.Scene.smd_export_list = CollectionProperty(type=SMD_CT_ObjectExportProps,options={'SKIP_SAVE'})	
	bpy.types.Scene.smd_use_kv2 = BoolProperty(name="SMD Write KeyValues2",description="Write ASCII DMX files",default=False)
		
	bpy.types.Object.smd_export = BoolProperty(name="SMD Scene Export",description="Export this item with the scene",default=True)
	bpy.types.Object.smd_subdir = StringProperty(name="SMD Subfolder",description="Optional path relative to scene output folder")
	bpy.types.Object.smd_action_filter = StringProperty(name="SMD Action Filter",description="Only actions with names matching this filter will be exported")
	flex_controller_modes = (
		('SIMPLE',"Simple","Generate one flex controller per shape key"),
		('ADVANCED',"Advanced","Insert the flex controllers of an existing DMX file")
	)
	bpy.types.Object.smd_flex_controller_mode = EnumProperty(name="DMX Flex Controller generation",description="How flex controllers are defined",items=flex_controller_modes,default='SIMPLE')
	bpy.types.Object.smd_flex_controller_source = StringProperty(name="DMX Flex Controller source",description="A DMX file (or Text datablock) containing flex controllers",subtype='FILE_PATH')
	
	bpy.types.Armature.smd_implicit_zero_bone = BoolProperty(name="Implicit motionless bone",default=True,description="Create a dummy bone for vertices which don't move. Emulates Blender's behaviour in Source, but may break compatibility with existing files")
	arm_modes = (
		('CURRENT',"Current / NLA","The armature's assigned action, or everything in an NLA track"),
		('FILTERED',"Action Filter","All actions that match the armature's filter term")
	)
	bpy.types.Armature.smd_action_selection = EnumProperty(name="Action Selection", items=arm_modes,description="How actions are selected for export",default='CURRENT')
	bpy.types.Armature.smd_legacy_rotation = BoolProperty(name="Legacy rotation",description="Remaps the Y axis of bones in this armature to Z, for backwards compatibility with old imports (SMD only)",default=False)

	bpy.types.Group.smd_export = bpy.types.Object.smd_export
	bpy.types.Group.smd_subdir = bpy.types.Object.smd_subdir
	bpy.types.Group.smd_expand = BoolProperty(name="SMD show expanded",description="Show the contents of this group in the Scene Exports panel",default=False)
	bpy.types.Group.smd_mute = BoolProperty(name="SMD ignore",description="Export this group's objects individually",default=False)
	bpy.types.Group.smd_flex_controller_mode = bpy.types.Object.smd_flex_controller_mode
	bpy.types.Group.smd_flex_controller_source = bpy.types.Object.smd_flex_controller_source
	
	bpy.types.Mesh.smd_flex_stereo_sharpness = FloatProperty(name="DMX stereo split sharpness",description="How sharply stereo flex shapes should transition from left to right",default=90,min=0,max=100,subtype='PERCENTAGE')
	
	bpy.types.Curve.smd_faces = EnumProperty(name="SMD export which faces",items=(
	('LEFT', 'Left side', 'Generate polygons on the left side'),
	('RIGHT', 'Right side', 'Generate polygons on the right side'),
	('BOTH', 'Both  sides', 'Generate polygons on both sides'),
	), description="Determines which sides of the mesh resulting from this curve will have polygons",default='LEFT')

def unregister():
	bpy.utils.unregister_module(__name__)
	bpy.types.INFO_MT_file_import.remove(menu_func_import)
	bpy.types.INFO_MT_file_export.remove(menu_func_export)
	bpy.app.handlers.scene_update_post.remove(scene_update)

	Scene = bpy.types.Scene
	del Scene.smd_path
	del Scene.smd_qc_compile
	del Scene.smd_qc_path
	del Scene.smd_studiomdl_branch
	del Scene.smd_studiomdl_custom_path
	del Scene.smd_studiomdl_custom_path_dmx_encoding
	del Scene.smd_studiomdl_custom_path_dmx_format
	del Scene.smd_up_axis
	del Scene.smd_format
	del Scene.smd_use_image_names
	del Scene.smd_layer_filter
	del Scene.smd_material_path
	del Scene.smd_use_kv2

	Object = bpy.types.Object
	del Object.smd_export
	del Object.smd_subdir
	del Object.smd_action_filter
	del Object.smd_flex_controller_mode
	del Object.smd_flex_controller_source

	del bpy.types.Armature.smd_implicit_zero_bone
	del bpy.types.Armature.smd_action_selection
	del bpy.types.Armature.smd_legacy_rotation

	Group = bpy.types.Group
	del Group.smd_export
	del Group.smd_subdir
	del Group.smd_expand
	del Group.smd_mute
	del Group.smd_flex_controller_mode
	del Group.smd_flex_controller_source

	del bpy.types.Curve.smd_faces
	
	del bpy.types.Mesh.smd_flex_stereo_sharpness

if __name__ == "__main__":
	register()

# Blender puts datamodel.py into the addons folder, then moans about it being there
scriptdir = os.path.dirname(__file__)
dm_module = "datamodel.py"
badpath = os.path.join(scriptdir,dm_module)
goodpath = os.path.join(os.path.dirname(scriptdir),"modules",dm_module)

if os.path.exists(badpath):
	try:
		os.makedirs(os.path.dirname(goodpath), exist_ok = True)
		if os.path.exists(goodpath): os.remove(goodpath)
		os.rename(badpath,goodpath)
	except:
		pass
