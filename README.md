# SmartRotation
A wow add-on for maximizing dps. 

SmartRotation is a minimalist dps rotation addon. \
Provides optimized damage rotation using minimal display icons. \
The rotation is derived from Simc's profiles to achieve maxmium dps. 

Now supports: \
Shadow Priest \
Havoc Demon Hunter \
Retribution Paladin \
Frost Mage

Files: \
SmartRotation.lua:      Main program, creates Bliz UI interfaces \
[ClassSpec].lua:        Base class of rotation for a certain spec, inherits PlayerRotation \
PlayerRotation.lua:     Provides common features for a player \
PlayerStatus.lua:       Tracks buff, debuff, cd, etc. \
CleaveLog.lua:          Tests aoe and cleave status \
LabeledMatrix.lua:      Labeled matrices, to store player buff, debuff, cd, etc. 
