
module bss_uart (
  input  wire       clk,
  input  wire       rst_n,

  input  wire       uart_rx,
  output wire       uart_tx,

  input  wire [2:0] baud_select,
  input  wire       parity_en,
  input  wire       parity_odd,

  input  wire       rx_valid,
  output wire       rx_ready,

  output wire [7:0] rx_data,

  input  wire       tx_valid,
  output wire       tx_ready,
  
  input  wire [7:0] tx_data
);
//--------------------------------------------------------------
// Baud Paramaters
//---------------------------------------------------------------

  `include "bss_uart_params.vh"
  
  parameter [2:0] DEFAULT_BAUD_MODE = 3'd7;

  //--------------------------------------------------------------
  // Internal Signals
  //---------------------------------------------------------------

  // baud clock generator
  wire [      2:0] baud_mode;
  reg  [ACC_W-1:0] baud_acc;
  reg  [ACC_W-1:0] baud_inc;
  reg              baud_tick_nx;

  // RX module
  wire [      7:0] rx_data_int;
  wire             rx_ready_int;

  // TX module
  reg  [      7:0] tx_data_reg;
  reg              tx_has_data;
  wire             tx_start;
  wire             tx_busy;

  // RX FIFO 
  wire [      7:0] rx_fifo_out;
  wire             rx_fifo_empty;
  wire             rx_fifo_full;
  wire             rx_fifo_write;
  wire             rx_fifo_read;

  // TX FIFO
  wire [      7:0] tx_fifo_out;
  wire             tx_fifo_empty;
  wire             tx_fifo_full;
  wire             tx_fifo_write;
  wire             tx_fifo_read;

  //--------------------------------------------------------------
  // Baud Selection logic
  //---------------------------------------------------------------

  assign baud_mode = (baud_select <= 3'd7) ? baud_select : DEFAULT_BAUD_MODE;

  always @(*) begin
    case (baud_mode)
      3'd0: baud_inc = INC_1200;
      3'd1: baud_inc = INC_2400;
      3'd2: baud_inc = INC_4800;
      3'd3: baud_inc = INC_9600;
      3'd4: baud_inc = INC_19200;
      3'd5: baud_inc = INC_38400;
      3'd6: baud_inc = INC_57600;
      3'd7: baud_inc = INC_460800;
      default: baud_inc = INC_460800;  // default to 460800 baud
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      baud_acc     <= {ACC_W{1'b0}};
      baud_tick_nx <= 1'b0;
    end else begin
      {baud_tick_nx, baud_acc} <= baud_acc + baud_inc;
    end
  end

  //--------------------------------------------------------------
  // Rx and Tx modules
  //---------------------------------------------------------------

  bss_uart_rx #(
      .OVERSAMPLE(OVERSAMPLE)
  ) u_uart_rx (
      .clk       (clk),
      .rst       (~rst_n),
      .baud_tick (baud_tick_nx),
      .parity_en (parity_en),
      .parity_odd(parity_odd),
      .rx        (uart_rx),
      .data_out  (rx_data_int),
      .data_valid(rx_ready_int)
  );

  bss_uart_tx #(
      .OVERSAMPLE(OVERSAMPLE)
  ) u_uart_tx (
      .clk       (clk),
      .rst       (~rst_n),
      .baud_tick (baud_tick_nx),
      .parity_en (parity_en),
      .parity_odd(parity_odd),
      .data_in   (tx_data_reg),
      .start     (tx_start),
      .tx        (uart_tx),
      .busy      (tx_busy)
  );

  //--------------------------------------------------------------
  // Data FIFOs 
  //---------------------------------------------------------------

  bss_fifo #(
      .FIFO_DEPTH(4),
      .DATA_WIDTH(8)
  ) u_rx_fifo (
      .clk     (clk),
      .rst_n   (rst_n),
      .data_in (rx_data_int),
      .write_en(rx_fifo_write),
      .read_en (rx_fifo_read),
      .data_out(rx_fifo_out),
      .empty   (rx_fifo_empty),
      .full    (rx_fifo_full)
  );

  bss_fifo #(
      .FIFO_DEPTH(4),
      .DATA_WIDTH(8)
  ) u_tx_fifo (
      .clk     (clk),
      .rst_n   (rst_n),
      .data_in (tx_data),
      .write_en(tx_fifo_write),
      .read_en (tx_fifo_read),
      .data_out(tx_fifo_out),
      .empty   (tx_fifo_empty),
      .full    (tx_fifo_full)
  );

  //--------------------------------------------------------------
  // FIFO Access logic
  //---------------------------------------------------------------

  assign rx_fifo_write = rx_ready_int & ~rx_fifo_full;
  assign rx_fifo_read  = rx_valid     & ~rx_fifo_empty;

  assign rx_ready      = ~rx_fifo_empty;
  assign rx_data       = rx_fifo_out;

  assign tx_ready      = ~tx_fifo_full;
  assign tx_fifo_write = tx_valid & tx_ready;

  assign tx_fifo_read  = (~tx_has_data) & (~tx_busy) & (~tx_fifo_empty);
  assign tx_start      = tx_has_data & ~tx_busy;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_data_reg <= 8'd0;
      tx_has_data <= 1'b0;
    end else begin
      if (tx_fifo_read) begin
        tx_data_reg <= tx_fifo_out;
        tx_has_data <= 1'b1;
      end else if (tx_start) begin
        tx_has_data <= 1'b0;
      end
    end
  end

endmodule
