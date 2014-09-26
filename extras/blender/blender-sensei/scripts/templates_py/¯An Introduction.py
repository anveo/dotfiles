'''
SCRIPT EXAMPLE BY: BLENDERSENSEI
VISIT: BLENDERSENSEI.com
SUBSCRIVE AT: Youtube.com/Blendersensei

Here is a quick introduction to using Python in Blender. A few quick notes
before we get started:

Big blocks of text (like this one) are commented out using tripple quote marks
(single or double work fine.) Everything written under and above these marks will
not be read by Blender.
'''

#Hashtags are another way to comment out text in Python. Faster for writing one or
#two quick notes.

import bpy #Always include this "import bpy" bit at the top of your code

#import bpy imports Blender Python terms into this Python console.
#As you see, hashtag comments can be put over, under, and after the code with no 
#problem.

#You can put as many lines above or below your code with no problem, but Python is 
#very picky about indentations and capitalization. Typically hitting the Tab button 
#will do the trick when things need to be indented but you can also just hit Space 
#4 times in a row. Likewise Truth is not the same as TRUTH to Python. You can also
#select a bunch of lines and hit Shift-Tab to backwards indent them.

#If you're gettin indentation errors in your code try selecting all of the code
#(ctrl-A) and clicking the header icon (three stacked lines) and select "Format"
#Convert white spaces to spaces.

#Delete the tripple quote marks above and below this bit of code.
'''
x = "spaghetti" #inform Blender that x means spaghetti with this =
if x == "spaghetti": #ask if x equals spaghetti with ==
    print(x) #print spaghetti
    print(x + x + x)  #print spaghetti 3 times
'''

#To see the results of this code hit "Run Script" and then hit the Console
#button to the right of the "Autocomplete" button a little bit below the text editor.
#What pops up is called the Console. DON'T HIT X! This will close Blender. Hit the
# - sign instead to minimize it.

#When you're ready, delete the tripple quote marks above and below this next bit of
#code to see what it does. Might want to re-add the quote marks around the first bit
#of code above, so it doesn't print again (though you'll still see the results in the
#console window from the first time you ran the code, but atleast it won't print again.

'''
x = "spaghetti" #store the string of text "spaghetti" into x
if x is "spaghetti": #ask if x equals spaghetti with "is" this time (works the same).
    print(x + " " + x + " " + x)  #print spaghetti 3 times but add spaces
'''

#Just to be clean, go ahead and close the last example up with tripple quote marks
#like it was before, then delete the tripple quotes below. You get the drill.
'''    
someOtherVar = 55 #Store a number in someOtherVar
if someOtherVar != 69: #Ask if someOtherVar does not equal 69
    print("I definitely don't equal 69!")
else:
    print("Now I equal 69.")
'''
#If you want, try changing someOtherVar from 55 to 69, then run the code and see
#what happens. Likely, you'll never guess what will happen do to the fact your father
#put you in a dryer when you were a child, permanently damaging your abillity to
#perform basic reasoning.

#The console will tell you many useful things about your script. Mostly errors and
#stuff you print to it. If there are errors you can most of the time find the same
#error information if you scroll down the Info space screen which is the screen 
#farthest below this text editor. This area will also give you awesome information
#which you can copy and paste into this text editor to run as code.
 
#You can go to File/User Preferences and under the Interface tab turn on "Python 
#Tool Tips". When you do you'll often see helpful information about a button or 
#option's code. Most of the time when you see this information you can then press 
#Ctrl-C (Cmnd-C Mac) to copy that code so you can paste it into the script editor.

#For instance if you're in the 3D View (while in Object Mode) and you select the
#"Create" tab and hover over the Cube option and hit Ctrl-C you can then paste that
#line into this text editor.

#Paste the code to the left or under this line.

#If you then right click and put your mouse somewhere in the 3D View, and hit the 
#"Run Script" button at the bottom of this editor, you will make a cube.
#You can find lots of commands this way and stack them up to do helpful things.

#In the bottom menu of this text editor there is an icon which looks like 3 horizontal
#lines, click it. Under "Text" you can save your script (be sure to include .py after
#the name.) A little bit to the right of that is a folder icon you can use to load
#scripts, and of course run them by hitting "Run Script". You can also select
#"Templates/Python" for several code templates provided by Blender. The templates
#prefaced with ° are templates created by Blender Sensei which will be very helpful
#for beginers. From here check out the operators example, next hotkeys and then 
#buttons. Be sure to check the PDF documentation that came with Sensei Format for
#a helpful chart of the features of this workspace "Hacker". Also see the video at
#Youtube.com/blendersensei for an introduction to Hacker and using Python.
