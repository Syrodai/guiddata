print("Importing Packages...")
import numpy as np
from PIL import Image
import re

print("Reading Class Data String...")
filename = 'Saved Variable Filepath Here'
with open(filename, 'r') as f:
    data = f.read()
    match = re.findall(r'classStr = "(.*?)"', data)
classStr = "-" + match[0]

def classColor(c):
    color = {
        '-': [0,0,0],       #   NONE
        '1': [195,155,109], #   WARRIOR
        '2': [244,140,186], #   PALADIN
        '3': [170,211,114], #   HUNTER
        '4': [255,244,104], #   ROGUE
        '5': [255,255,255], #   PRIEST
        '6': [0,112,221],   #   SHAMAN
        '7': [63,199,235],  #   MAGE
        '8': [135,135,238], #   WARLOCK
        '9': [255,124,10],  #   DRUID
        '0': [196,30,58],   #   DEATHKNIGHT
    }
    return color[c]

numChars = len(classStr)
horizontalLength = 1000

x = horizontalLength
y = int(numChars/horizontalLength)
maxChars = y*x
arr = np.zeros((y, x, 3))



print("Creating Image...")
index = 0
for c in classStr:
    arr[int(index/horizontalLength),index%horizontalLength] = classColor(c)
    index = index+1
    if index >= maxChars:
        break


savefile = "classdata_" + str(maxChars) + ".png"
print("Saving as " + savefile + "...")

img = Image.fromarray(arr.astype('uint8'), 'RGB')


# Save the image
img.save(savefile)
print("Done!")
