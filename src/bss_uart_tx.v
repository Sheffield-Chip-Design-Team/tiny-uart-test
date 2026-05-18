module bss_uart_tx #(
    parameter integer OVERSAMPLE = 4
) (
    input  wire       clk,
    input  wire       baud_tick,
    input  wire       rst,
    input  wire       parity_en,
    input  wire       parity_odd,
    input  wire [7:0] data_in,
    input  wire       start,
    output reg        tx,
    output reg        busy
);

    localparam [2:0] IDLE   = 3'd0;
    localparam [2:0] START  = 3'd1;
    localparam [2:0] DATA   = 3'd2;
    localparam [2:0] PARITY = 3'd3;
    localparam [2:0] STOP   = 3'd4;

  localparam integer TICK_W = (OVERSAMPLE <= 2) ? 1 : $clog2(OVERSAMPLE);
  /* verilator lint_off WIDTHTRUNC */
  localparam [TICK_W-1:0] LAST_TICK = OVERSAMPLE - 1;
  /* verilator lint_on WIDTHTRUNC */

  /* verilator lint_off PROCASSINIT */
  reg [       2:0] state = IDLE;

  reg [       2:0] bit_index = 0;
  reg [       7:0] tx_shift = 0;
  reg [TICK_W-1:0] tick_count = 0;
  reg              parity_bit = 0;
  reg              parity_en_latched = 0;
  /* verilator lint_on PROCASSINIT */

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            tx    <= 1;
            busy  <= 0;
            tick_count <= 0;
            bit_index <= 0;
            parity_bit <= 0;
            parity_en_latched <= 0;
        end else begin
            case (state)
            IDLE: begin
                tx   <= 1;
                busy <= 0;
                tick_count <= 0;
                bit_index <= 0;

                if (start) begin
                    tx_shift <= data_in;
                    parity_en_latched <= parity_en;
                    parity_bit <= parity_odd ? ~^data_in : ^data_in;
                    busy <= 1;
                    state <= START;
                end
            end
            START: begin
                tx <= 0;
                busy <= 1;

                if (baud_tick) begin
                    if (tick_count == LAST_TICK) begin
                        tick_count <= 0;
                        state <= DATA;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
            end

            DATA: begin
                tx <= tx_shift[bit_index];
                busy <= 1;

                if (baud_tick) begin
                    if (tick_count == LAST_TICK) begin
                        tick_count <= 0;

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
                tx <= parity_bit;
                busy <= 1;

                if (baud_tick) begin
                    if (tick_count == LAST_TICK) begin
                        tick_count <= 0;
                        state <= STOP;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
            end

            STOP: begin
                tx <= 1;
                busy <= 1;

                if (baud_tick) begin
                    if (tick_count == LAST_TICK) begin
                        state <= IDLE;
                        tick_count <= 0;
                    end else begin
                        tick_count <= tick_count + 1;
                    end
                end
            end

            default: begin
                state <= IDLE;
                tx <= 1;
                busy <= 0;
                tick_count <= 0;
                bit_index <= 0;
                parity_bit <= 0;
                parity_en_latched <= 0;
            end
            endcase
        end
    end

endmodule
