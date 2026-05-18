// Baud RATE parameters

localparam CLK_FREQ   = 64_000_000;
localparam OVERSAMPLE = 4;

parameter [3:0] BAUD_MODE = 4'd7;

// Fractional-N divider (NCO)
localparam integer ACC_W = 32;

// Pre-compute the increment values for each baud rate (considering oversampling)
localparam [ACC_W-1:0] INC_1200   = (((64'd1 << ACC_W) * (1200*OVERSAMPLE))   + (CLK_FREQ/2)) / CLK_FREQ;
localparam [ACC_W-1:0] INC_2400   = (((64'd1 << ACC_W) * (2400*OVERSAMPLE))   + (CLK_FREQ/2)) / CLK_FREQ;
localparam [ACC_W-1:0] INC_4800   = (((64'd1 << ACC_W) * (4800*OVERSAMPLE))   + (CLK_FREQ/2)) / CLK_FREQ;
localparam [ACC_W-1:0] INC_9600   = (((64'd1 << ACC_W) * (9600*OVERSAMPLE))   + (CLK_FREQ/2)) / CLK_FREQ;
localparam [ACC_W-1:0] INC_19200  = (((64'd1 << ACC_W) * (19200*OVERSAMPLE))  + (CLK_FREQ/2)) / CLK_FREQ;
localparam [ACC_W-1:0] INC_38400  = (((64'd1 << ACC_W) * (38400*OVERSAMPLE))  + (CLK_FREQ/2)) / CLK_FREQ;
localparam [ACC_W-1:0] INC_57600  = (((64'd1 << ACC_W) * (57600*OVERSAMPLE))  + (CLK_FREQ/2)) / CLK_FREQ;
localparam [ACC_W-1:0] INC_115200 = (((64'd1 << ACC_W) * (115200*OVERSAMPLE)) + (CLK_FREQ/2)) / CLK_FREQ;
localparam [ACC_W-1:0] INC_230400 = (((64'd1 << ACC_W) * (230400*OVERSAMPLE)) + (CLK_FREQ/2)) / CLK_FREQ;
localparam [ACC_W-1:0] INC_460800 = (((64'd1 << ACC_W) * (460800*OVERSAMPLE)) + (CLK_FREQ/2)) / CLK_FREQ;
localparam [ACC_W-1:0] INC_921600 = (((64'd1 << ACC_W) * (921600*OVERSAMPLE)) + (CLK_FREQ/2)) / CLK_FREQ;

