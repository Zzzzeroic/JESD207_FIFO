`define STATE_IDLE  3'b000
`define STATE_BEGIN 3'b001
`define STATE_TRANS 3'b010
`define STATE_END   3'b011
module top_JESD207_FIFO
#(
    parameter ADDR_WID = 7,
    parameter DATA_WID = 12,
    parameter PROG_DEPTH = 64
)
(
    input proc_start,
    input btn_tx_nrx,
    output reg tx_nrx,
    output reg jesd_en,
    input rstn,
    output fclk,
    input [DATA_WID-1:0] wdata,
    input mclk,
    output [DATA_WID-1:0] rdata,
    output wfull,
    output rempty,
    output prog_full,
    
    input sysclk,

    input i_uart_rx,
    output o_uart_tx,
    
    //SPI param
    output o_SCLK,
    output o_MOSI,
    input  i_MISO,
    output o_SEN
);

pllClk_66M_30p72M upll(
    .clk_in1(sysclk),
    .clk_out1(fclk)
);

reg [2:0] currState;
reg [1:0] cnt;
reg wr_en, rd_en;

always @(negedge fclk or negedge rstn) begin
    if (~rstn) begin
        currState   <= `STATE_BEGIN;
        cnt         <= 'd0;   
        tx_nrx      <= 'd1;
        wr_en       <= 'b0;
        rd_en       <= 'b0;
        jesd_en     <= 'b0;
    end
    else begin
        case (currState)
            `STATE_IDLE: begin
                jesd_en <= 1'b0;
                if(proc_start) begin
                    currState <= `STATE_BEGIN;
                end
            end
            `STATE_BEGIN: begin
                if(cnt==0) begin
                    cnt <= 'd1;
                    tx_nrx <= btn_tx_nrx;
                    jesd_en <= 'b1;
                end
                else begin
                    jesd_en <= 'b0;
                    if(cnt>=2) begin
                        cnt <= 'd0;
                        currState <= `STATE_TRANS;
                        if(tx_nrx) rd_en <= 'b1; else wr_en <= 'b1;
                    end
                    else cnt <= cnt + 1;
                end
            end
            `STATE_TRANS: begin
                if(wfull || rempty) begin
                    if(tx_nrx && rempty) begin //tx mode
                        rd_en <= ~rempty; 
                        currState <= `STATE_END;
                    end
                    else if(~tx_nrx && wfull)begin
                        wr_en <= ~wfull;
                        currState <= `STATE_END;
                    end
                end
            end
            `STATE_END: begin
                currState <= `STATE_IDLE;
                jesd_en   <= 1'b1;
            end
        endcase
    end
end

wire [ADDR_WID-1:0] waddr, raddr;
wire [ADDR_WID-1:0] debug_addr;
wire [DATA_WID-1:0] debug_data;

fifo #(
    .ADDR_WID(ADDR_WID),
    .DATA_WID(DATA_WID),
    .PROG_DEPTH(PROG_DEPTH)
)
u_data_buf2
(
    .rstn(rstn),
    .waddr(waddr),
    .wclk(mclk),
    .winc(wr_en),
    .raddr(raddr),
    .rclk(fclk),
    .rinc(rd_en),
    .rempty(rempty),
    .wfull(wfull),
    .prog_full(prog_full)
);
wire debug_ram_en;
jt201D_spi_top #(
    .RAM_ADDR_WID(ADDR_WID),
    .RAM_DATA_WID(DATA_WID)
) u_spi_uart(
    .i_clk_sys(sysclk),
    .i_rst_n(rstn),
    .i_uart_rx(i_uart_rx),
    .o_uart_tx(o_uart_tx),
    .o_ld_parity(),
    .o_ld_debug(),
    .o_SCLK(o_SCLK),
    .o_MOSI(o_MOSI),
    .i_MISO(i_MISO),
    .o_SEN(o_SEN),
    .debug_ram_en(debug_ram_en),
    .debug_addr(debug_addr),
    .debug_data(debug_data)
);

ramdp
#(  .ADDR_WID     (ADDR_WID),
    .DATA_WID     (DATA_WID))
u_ramdp
(
    .CLK_WR             (mclk),
    .WR_EN              (wr_en & !wfull),
    .ADDR_WR            (waddr),
    .D                  (wdata[DATA_WID-1:0]),
    .CLK_RD             (fclk),
    .RD_EN              (rd_en & !rempty),
    .ADDR_RD            (raddr),
    .Q                  (rdata[DATA_WID-1:0]),
    .CLK_DEBUG          (sysclk),
    .DEBUG_EN           (debug_ram_en),
    .ADDR_DEBUG         (debug_addr),
    .DATA_DEBUG         (debug_data)
    );

endmodule
