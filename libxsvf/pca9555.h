// PCA9555I2C - using only port 1
// with 100kHz we can use all jtag pins via I2C but TCK.
#define I2C_ADDRESS            0x20
#define I2C_BAUDRATE           100000
#define I2C_CMD_INPUT0         0x00
#define I2C_CMD_INPUT1         0x01
#define I2C_CMD_OUTPUT0        0x02
#define I2C_CMD_OUTPUT1        0x03
#define I2C_CMD_CONFIG0        0x06
#define I2C_CMD_CONFIG1        0x07

/* 
    Register addresses :
    Command Register
    0 Input port 0
    1 Input port 1
    2 Output port 0
    3 Output port 1
    4 Polarity Inversion port 0
    5 Polarity Inversion port 1
    6 Configuration port 0
    7 Configuration port 1
*/

typedef union {
    struct {
        unsigned char FTDO     : 1;
        unsigned char FTDI     : 1;
        unsigned char FTCK     : 1;
        unsigned char FTMS     : 1;
        unsigned char FJTAGENB : 1;
        unsigned char FPROG    : 1;
        unsigned char FINIT    : 1;
        unsigned char FDONE    : 1;
    } fields;
    char byte;
} fpga_ctrl;
