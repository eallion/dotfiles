# Windows Terminal Settings

# Tips

### Terminal windows size
```
"initialCols": 131, //Cols
"initialRows": 31, //Rows
```

### Icons
- **Recommend:**
```
"icon": "ms-appdata:///roaming/icons/ubuntu.ico"
```
Put the icon files into:
```
%LOCALAPPDATA%\packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\RoamingState
```

- **Another way:**
```
"icon": "D:/xxx/icons/ubuntu.ico"
```

### GUID
Generate a GUID or [Google a generator](https://www.google.com/search?q=guid+generator).
- <https://www.guidgenerator.com/online-guid-generator.aspx>



### WSL starting directory

- Ubuntu
```
"commandline" : "wsl.exe ~"
```
or
```
"startingDirectory": "//wsl$/Ubuntu/home/'YOUR_USER_NAME'/"
```

- Debian
```
"startingDirectory": "//wsl$/Debian/home/'YOUR_USER_NAME'/"
```

### SSH Terminal
```
"commandline": "ssh -i id_rsa root@host -p 8888"
```
`-i` with a key  
`id_rsa` is the key  
`root` is your username  
`host` is your server ip  
`-p` with a port  
`8888` is the port if not default  

### Color schemes
```
"colorScheme":"Ubuntu"
```
The color scheme's name must be the same.
```
"schemes": [
    {
        ......
        "name": "Ubuntu"
        ......
        ......
    }
]
```

### Hotkeys
Example:
```
"keybindings": [
    {
        "command" : "copy",
        "keys" :["ctrl+shift+c"]
    },
    {
        "command" : "paste",
        "keys" : ["ctrl+shift+v"]
    }
]
```