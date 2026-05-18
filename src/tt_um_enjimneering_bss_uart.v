/*
 * Copyright (c) 2024  James Ashie Kotey, Kreesha Ramachandran
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_enjimneering_bss_uart (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  // Internal signals
  wire       uart_rx;
  wire       uart_tx;
  wire [2:0] baud_select;
  wire       parity_en;
  wire       parity_odd;
  wire       tx_valid;
  wire       rx_ready;
  wire [7:0] tx_data;
  wire [7:0] rx_data;
  wire       tx_ready;
  wire       rx_valid;
  wire       rx_handshake;

  // Mux window counter for RX output (2-cycle pulse)
  reg  [1:0] rx_win;  // counts down from 2 when rx handshake fires

  wire       rx_active = (rx_win != 2'b00);

  bss_uart u_bss_uart (
      .clk        (clk),
      .rst_n      (rst_n),
      .uart_rx    (uart_rx),
      .uart_tx    (uart_tx),
      .baud_select(baud_select),
      .parity_en  (parity_en),
      .parity_odd (parity_odd),
      .rx_valid   (rx_valid),
      .rx_ready   (rx_ready),
      .rx_data    (rx_data),
      .tx_valid   (tx_valid),
      .tx_ready   (tx_ready),
      .tx_data    (tx_data)
  );

  // ------------------------------------------------------------------ 
  //  Handshake detection                                                 
  // ------------------------------------------------------------------ 

  assign rx_handshake = rx_valid & rx_ready;

  // ------------------------------------------------------------------ 
  //  Mux window counters                                                 
  // ------------------------------------------------------------------

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_win <= 2'b00;
    end else begin
      // RX window: open for 2 cycles on handshake
      if (rx_handshake) rx_win <= 2'b10;
      else if (rx_win != 2'b00) rx_win <= rx_win - 1'b1;
    end
  end

  // ------------------------------------------------------------------ 
  //  Control signal mapping                                              
  // ------------------------------------------------------------------ 

  assign uart_rx     = uio_in[0];
  assign uio_out[1]  = uart_tx;

  assign baud_select = uio_in[4:2];
  assign parity_en   = uio_in[5];
  assign rx_valid    = uio_in[6];

  // ui_in[7] = tx_valid strobe (pulse high for 1 cycle to queue a byte)
  // ui_in[6:0] = tx_data (7-bit, covers full ASCII range)
  assign tx_valid    = ui_in[7];
  assign tx_data     = {1'b0, ui_in[6:0]};

  // ------------------------------------------------------------------ 
  //  Output mux                                                          
  // ------------------------------------------------------------------ 

  wire [7:0] status_word = {6'b0, rx_ready, tx_ready};

  // uo_out: rx data during rx window, status otherwise
  assign uo_out       = rx_active ? rx_data : status_word;
  assign uio_out[7]   = tx_ready;
  assign uio_out[6:2] = 0;
  assign uio_out[0]   = 0;

  /* verilator lint_off UNUSEDSIGNAL */
  wire unused_ok_ = &{ena, uio_in[7], uio_in[1]};
  /* verilator lint_on UNUSEDSIGNAL */

  assign uio_oe = 8'b1000_0010;

endmodule
