module bss_fifo #(
    parameter FIFO_DEPTH = 4,
    parameter DATA_WIDTH = 8
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire                  write_en,
    input  wire                  read_en,
    output reg  [DATA_WIDTH-1:0] data_out,
    output reg                   empty,
    output reg                   full
);

  reg [7:0] fifo[FIFO_DEPTH-1:0];

  /* verilator lint_off PROCASSINIT */
  reg [$clog2(FIFO_DEPTH)-1:0] head = 0;
  reg [$clog2(FIFO_DEPTH)-1:0] tail = 0;
  reg [$clog2(FIFO_DEPTH):0] count = 0;
  /* verilator lint_on PROCASSINIT */

  /* verilator lint_off SYNCASYNCNET */
  always @(posedge clk) begin
    if (~rst_n) begin
      head  <= 0;
      tail  <= 0;
      count <= 0;
      empty <= 1;
      full  <= 0;
    end else begin
      if (write_en && !full) begin
        fifo[tail] <= data_in;
        tail <= tail + 1;
        count <= count + 1;
      end

      if (read_en && !empty) begin
        data_out <= fifo[head];
        head <= head + 1;
        count <= count - 1;
      end

      empty <= (count == 0);
      full  <= (count == FIFO_DEPTH);
    end
  end
  /* verilator lint_on SYNCASYNCNET */
endmodule
