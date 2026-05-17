/*
 * Copyright (c) 2024  James Ashie Kotey, Kreesha Ramachandran
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_enjimneering_bss_uart (
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // IO mapping
  wire       uart_rx;
  wire       uart_tx;
  wire [3:0] baud_select;
  wire       parity_en;
  wire       parity_odd;
  wire       tx_valid;
  wire       rx_ready;

  wire [7:0] tx_data;
  wire [7:0] rx_data;
  wire       tx_ready;
  wire       rx_valid;
  wire [7:0] status_word;
  wire       rx_handshake;

  reg  [1:0] rx_disp_cnt;

  bss_uart u_bss_uart (
    .clk            (clk),
    .rst_n          (rst_n),
    .uart_rx        (uart_rx),
    .uart_tx        (uart_tx),
    .baud_select    (baud_select),
    .parity_en      (parity_en),
    .parity_odd     (parity_odd),
    .rx_valid       (rx_valid),
    .rx_ready       (rx_ready),
    .rx_data        (rx_data),
    .tx_valid       (tx_valid),
    .tx_ready       (tx_ready),
    .tx_data        (tx_data)
  );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_disp_cnt <= 2'b00;
    end else begin
      if (rx_handshake) begin
        rx_disp_cnt <= 2'b10;
      end else if (rx_disp_cnt != 2'b00) begin
        rx_disp_cnt <= rx_disp_cnt - 1'b1;
      end
    end
  end

  assign uart_rx = uio_in[0];
  assign baud_select = uio_in[4:1];
  assign parity_en = uio_in[5];
  assign parity_odd = uio_in[6];
  assign tx_valid = uio_in[7];
  assign rx_ready = 1'b1;

  assign tx_data = ui_in;
  assign rx_handshake = rx_valid & rx_ready;
  assign status_word = {5'b0, rx_valid, tx_ready, uart_tx};

  assign uo_out = (rx_disp_cnt != 2'b00) ? rx_data : status_word;
  assign uio_out = status_word;
  assign uio_oe = 8'b0000_0111;

endmodule
