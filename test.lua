os.loadAPI("/sys/api/nfs.lua")

nfs.write("/a.ab", "sd", true)

print(nfs.getUsedSpacePercentage("/"))