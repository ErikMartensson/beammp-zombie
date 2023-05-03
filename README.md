### How to package:
* server/* -> Resources/Server/Zombie
* client/* -> Resources/Client/Zombie.zip

Need 7-Zip installed to run `reload.ps1`

Should make a symlink from ./server to C:\BeamMpServer\Resources\Server\Zombie

---

### How to get collisions:
map.objects[vehicleGameID].objectCollisions
print(jsonEncode(map.objects[74493].objectCollisions))
--> { otherVehicleGameID: 1 } | {}
