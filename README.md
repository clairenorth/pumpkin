# pumpkin
SmartDeco iOS client app

## Models:
- User Information: User (val userName: String, val password: String, connectedDevice: List[ConnectedDevice], animations: List[Animation])
  - ID 
  - Username
  - Password
  - Devices
  - Animations
- ConnectedDevice
  - Type
  - Description
- Animation
  - ID
  
## Behaviors:
- Login or Signup:
  - Store account/user information
  - Get/Post to service to get/set account information
- Add Device(s):
  - Bluetooth/wifi connect to devices
  - Post the new devices up to backend for this user
- Purchase Animations
  - "Store" of animations
  - User can interact with store
  - Post the new "purchased" animation up to backend for this user

