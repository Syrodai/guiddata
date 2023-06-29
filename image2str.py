from PIL import Image

def charColor(c):
    color = {
        (0,0,0): '-',       #   NONE
        (195,155,109): '1', #   WARRIOR
        (244,140,186): '2', #   PALADIN
        (170,211,114): '3', #   HUNTER
        (255,244,104): '4', #   ROGUE
        (255,255,255): '5', #   PRIEST
        (0,112,221): '6',   #   SHAMAN
        (63,199,235): '7',  #   MAGE
        (135,135,238): '8', #   WARLOCK
        (255,124,10): '9',  #   DRUID
        (196,30,58): '0',   #   DEATHKNIGHT
    }
    return color[c]

# Read image from file
img = Image.open('classdata_51636000.png')

long_string = ''

# Iterate through image pixels
for j in range(img.size[1]):
    for i in range(img.size[0]):
        color = img.getpixel((i, j))
        char = charColor(color)
        long_string += char

# Save string to file
with open('long_string.txt', 'w') as f:
    f.write(long_string)

print('Done!')