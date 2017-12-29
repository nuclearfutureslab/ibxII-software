# IBX ]\[ Software

This is the Software for the IBX ]\[, presented at 34C3. IBX ]\[ is an information barrier setup for nuclear warhead verification with an Apple II ([Details](http://www.vintageverification.org)). It is written in 6502 Assembler, binary code can be created with [ca65](http://www.cc65.org). 
The `Makefile` assembles, links and creates a bootable Apple II disk image. 

## Requirements 
* [ca65 assembler](http://www.cc65.org)
* [dos33fsprogs](https://github.com/deater/dos33fsprogs) (Tools do manipulate DOS 3.3 disk images)
* [AppleCommander](https://applecommander.github.io/) - The JAR file should be placed directly outside this project's directory and renamed as `ac.jar` to allow `make` to find it. 
