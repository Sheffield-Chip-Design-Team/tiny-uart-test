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
  wire       tx_handshake;

  // Mux window counters (2-cycle pulse)
  reg  [1:0] rx_win;   // counts down from 2 when rx handshake fires
  reg  [1:0] tx_win;   // counts down from 2 when tx handshake fires

  wire       rx_active = (rx_win != 2'b00);
  wire       tx_active = (tx_win != 2'b00);

  // Latch to hold tx_data during the mux window
  reg  [7:0] tx_data_r;

  bss_uart u_bss_uart (
    .clk         (clk),
    .rst_n       (rst_n),
    .uart_rx     (uart_rx),
    .uart_tx     (uart_tx),
    .baud_select (baud_select),
    .parity_en   (parity_en),
    .parity_odd  (parity_odd),
    .rx_valid    (rx_valid),
    .rx_ready    (rx_ready),
    .rx_data     (rx_data),
    .tx_valid    (tx_valid),
    .tx_ready    (tx_ready),
    .tx_data     (tx_data)
  );

  // ------------------------------------------------------------------ 
  //  Handshake detection                                                 
  // ------------------------------------------------------------------ 

  assign rx_handshake = rx_valid & rx_ready;
  assign tx_handshake = tx_valid & tx_ready;

  // ------------------------------------------------------------------ 
  //  Mux window counters                                                 
  // ------------------------------------------------------------------

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_win <= 2'b00;
      tx_win <= 2'b00;
    end else begin
      // RX window: open for 2 cycles on handshake
      if (rx_handshake)
        rx_win <= 2'b10;
      else if (rx_win != 2'b00)
        rx_win <= rx_win - 1'b1;

      // TX window: open for 2 cycles on handshake
      if (tx_handshake)
        tx_win <= 2'b10;
      else if (tx_win != 2'b00)
        tx_win <= tx_win - 1'b1;
    end
  end

  // ------------------------------------------------------------------ 
  //  TX data latch                                                       
  //  Capture ui_in as a full byte during the tx mux window.            
  //  Outside the window ui_in[0] is rx_ready so we must not use it.     
  // ------------------------------------------------------------------ 
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      tx_data_r <= 8'b0;
    else if (tx_active)
      tx_data_r <= ui_in;   // full 8-bit capture
  end

  // ------------------------------------------------------------------ 
  //  Static control signal mapping (idle / outside mux windows)         
  // ------------------------------------------------------------------ 
 
  assign uart_rx     = uio_in[0];      
  assign uart_tx     = uio_out[1];

  assign baud_select = uio_in[4:2];    
  assign parity_en   = uio_in[5];
  assign parity_odd  = uio_in[6];

  assign tx_valid    = uio_out[7];
  assign rx_ready    = ui_in[0];

  // tx_data uses the latch; during tx_active the latch is being updated
  assign tx_data = tx_data_r;

  // ------------------------------------------------------------------ 
  //  Output mux                                                          
  // ------------------------------------------------------------------ 

  wire [7:0] status_word = {6'b0, rx_valid, tx_ready};

  // uo_out: rx data during rx window, status otherwise
  assign uo_out       = rx_active ? rx_data : status_word;
  assign uio_out[6:2] = 0;
  assign uio_out[0]   = 0; 


  wire unused_ok_ = &uio_in[7];
  assign uio_oe  = 8'b1000_0010;

endmodule
