module LCD_SPI_Interface (
  input wire clk,
  input wire rst,
  output wire reg_rs,
  output wire reg_en,
  output reg [7:0] reg_ldata,
  output wire reg_clk,
  output wire reg_din,
  input wire reg_dout,
  output wire reg_cs,
  output reg [15:0] spi_adc_value,
  output reg [15:0] temp
);

reg [15:0] count;
reg [3:0] state;

parameter IDLE = 4'b0000, START = 4'b0001, SINGLE_ENDED = 4'b0010, D2 = 4'b0011, D1 = 4'b0100, D0 = 4'b0101, T_SAMPLE = 4'b0110, NULL_BIT = 4'b0111;

initial begin
  count <= 0;
  state <= IDLE;
  temp <= 0;
end

always @(posedge clk or posedge rst) begin
  if (rst) begin
    count <= 0;
    state <= IDLE;
  end else begin
    if (count < 11) begin
      count <= count + 1;
    end else begin
      count <= 0;
      state <= state + 1;
    end
  end
end

assign reg_rs = (state == IDLE) ? 1'b0 : 1'b1;
assign reg_en = (state == START || state == SINGLE_ENDED || state == D2 || state == D1 || state == D0 || state == T_SAMPLE || state == NULL_BIT) ? 1'b1 : 1'b0;

always @(posedge clk or posedge rst) begin
  if (rst) begin
    reg_ldata <= 8'h00;
    reg_clk <= 1'b0;
    reg_din <= 1'b0;
    reg_cs <= 1'b1;
  end else begin
    case (state)
      IDLE: begin
        reg_ldata <= 8'h00;
        reg_clk <= 1'b0;
        reg_din <= 1'b0;
        reg_cs <= 1'b1;
      end
      START: begin
        reg_clk <= 1'b0;
        reg_din <= 1'b1;
        reg_cs <= 1'b0;
      end
      SINGLE_ENDED: begin
        reg_clk <= 1'b0;
        reg_din <= 1'b0;
      end
      D2, D1, D0: begin
        reg_clk <= 1'b0;
        reg_din <= 1'b0;
      end
      T_SAMPLE, NULL_BIT: begin
        reg_clk <= 1'b0;
        reg_din <= 1'b1;
      end
      default: begin
        reg_clk <= 1'b0;
        reg_din <= 1'b0;
        reg_cs <= 1'b1;
      end
    endcase
  end
end

always @(posedge clk or posedge rst) begin
  if (rst) begin
    spi_adc_value <= 16'h0000;
  end else begin
    case (state)
      D2, D1, D0: begin
        reg_clk <= 1'b1;
        if (reg_dout == 1'b1) begin
          spi_adc_value <= spi_adc_value | (1 << (11 - count));
        end
      end
      default: begin
        reg_clk <= 1'b0;
      end
    endcase
  end
end

always @(posedge clk or posedge rst) begin
  if (rst) begin
    temp <= 16'h0000;
  end else begin
    if (state == T_SAMPLE) begin
      temp <= spi_adc_value / 8.5;
    end
  end
end

endmodule
