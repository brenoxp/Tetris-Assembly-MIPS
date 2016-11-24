# Tetris Assembly MIPS
An implementation of Tetris in Assembly MIPS using infra red controller.

# Memory positions used
  **Memory address: ($sp - offset)**
  
* Number of players
    * Type: int
    * Size: 4 bytes
    * Offset: 000 - 004
    
* Registered keys of controller
    * Type: IrDA Type
    * Size: 64 bytes
    * Offset: 004 - 068

* Board positions
    * Type: int
    * Size: 16 bytes
    * Offset 068 - 084
