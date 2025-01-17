`define STATE_IDLE  3'b000
`define STATE_BEGIN 3'b001
`define STATE_TRANS 3'b010
`define STATE_END   3'b011
module top_JESD207_FIFO
#(
    parameter AWI = 7,
    parameter AWO = 7,
    parameter DWI = 12,
    parameter DWO = 12,
    parameter PROG_DEPTH = 64
)
(
    input proc_start,
    input btn_tx_nrx,
    output reg tx_nrx,
    output reg jesd_en,
    input rstn,
    input fclk,
    input [DWI-1:0] wdata,
    input mclk,
    output [DWO-1:0] rdata,
    output wfull,
    output rempty,
    output prog_full
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
            end
        endcase
    end
end

fifo #(
    .AWI(AWI),
    .AWO(AWO),
    .DWI(DWI),
    .DWO(DWO),
    .PROG_DEPTH(PROG_DEPTH)
)
u_data_buf2
(
    .rstn(rstn),
    .wdata(wdata),
    .wclk(mclk),
    .winc(wr_en),
    .rdata(rdata),
    .rclk(fclk),
    .rinc(rd_en),
    .rempty(rempty),
    .wfull(wfull),
    .prog_full(prog_full)
);

endmodule
