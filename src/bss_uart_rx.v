module bss_uart_rx #(
    parameter integer OVERSAMPLE = 4
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       baud_tick,
    input  wire       parity_en,
    input  wire       parity_odd,
    input  wire       rx,
    output reg  [7:0] data_out,
    output reg        data_valid
);
  // FSM states
  localparam [2:0] IDLE = 3'd0;
  localparam [2:0] START = 3'd1;
  localparam [2:0] DATA = 3'd2;
  localparam [2:0] PARITY = 3'd3;
  localparam [2:0] STOP = 3'd4;

  // Calculate TICK_W based on OVERSAMPLE
  localparam integer TICK_W = (OVERSAMPLE <= 2) ? 1 : $clog2(OVERSAMPLE);
  /* verilator lint_off WIDTHTRUNC */
  localparam [TICK_W-1:0] LAST_TICK = OVERSAMPLE - 1;
  localparam [TICK_W-1:0] START_TICK = (OVERSAMPLE / 2) - 1;
  /* verilator lint_on WIDTHTRUNC */

  /* verilator lint_off PROCASSINIT */
  reg  [       2:0] state = IDLE;

  reg  [       2:0] bit_index = 0;
  reg  [       7:0] rx_shift = 0;
  reg  [TICK_W-1:0] tick_count = 0;
  reg               parity_calc = 0;
  reg               parity_ok = 1;
  reg               parity_en_latched = 0;
  reg               parity_odd_latched = 0;
  /* verilator lint_on PROCASSINIT */
  wire              rx_clean;

  // Synchronize RX (2-stage data synchroniser)
  reg rx_d1, rx_d2;
  
  always @(posedge clk) begin
      rx_d1 <= rx;
      rx_d2 <= rx_d1;
  end

  assign rx_clean = rx_d2;

  always @(posedge clk) begin
      if (rst) begin
          state      <= IDLE;
          data_valid <= 0;
          bit_index  <= 0;
          tick_count <= 0;
          parity_calc <= 0;
          parity_ok <= 1;
          parity_en_latched <= 0;
          parity_odd_latched <= 0;
      end else begin
          data_valid <= 0;
          case (state)
            IDLE: begin
                bit_index <= 0;
                tick_count <= 0;
                parity_calc <= 0;
                parity_ok <= 1;
                if (rx_clean == 0) begin
                    parity_en_latched <= parity_en;
                    parity_odd_latched <= parity_odd;
                    state <= START;
                end
            end

            START: begin
                if (baud_tick) begin
                    if (tick_count == START_TICK) begin
                        if (rx_clean == 0) begin
                            tick_count <= 0;
                            state <= DATA;
                        end else begin
                            state <= IDLE;
                            tick_count <= 0;
                        end
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
            end

            DATA: begin
                if (baud_tick) begin
                    if (tick_count == LAST_TICK) begin
                        tick_count <= 0;
                        rx_shift[bit_index] <= rx_clean;
                        parity_calc <= parity_calc ^ rx_clean;

                        if (bit_index == 7) begin
                            bit_index <= 0;
                            state <= parity_en_latched ? PARITY : STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
            end

            PARITY: begin
                if (baud_tick) begin
                    if (tick_count == LAST_TICK) begin
                        tick_count <= 0;
                        parity_ok <= (rx_clean == (parity_odd_latched ? ~parity_calc : parity_calc));
                        state <= STOP;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
            end

            STOP: begin
                if (baud_tick) begin
                    if (tick_count == LAST_TICK) begin
                        data_out   <= rx_shift;
                        data_valid <= parity_ok;
                        state      <= IDLE;
                        tick_count <= 0;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
            end

            default: begin
                state <= IDLE;
                tick_count <= 0;
                bit_index <= 0;
                parity_calc <= 0;
                parity_ok <= 1;
                parity_en_latched <= 0;
                parity_odd_latched <= 0;
            end
          endcase
      end
  end

endmodule
