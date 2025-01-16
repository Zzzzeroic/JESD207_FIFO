`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:43:32 12/06/2024 
// Design Name: 
// Module Name:    clock_divider 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module clock_divider
#(
    parameter DIV_PARAM = 4
    )
    (
    input i_clk_sys,
    input i_rst_n,
    output o_clk_sys_div
    );

    reg [DIV_PARAM-1:0] div_cnt = 0;

    always @(posedge i_clk_sys or negedge i_rst_n) begin
        if(~i_rst_n) begin
            div_cnt <= 1'b0;
        end
        else begin
            div_cnt <= div_cnt + 1'b1;
        end
    end
    assign o_clk_sys_div = div_cnt[DIV_PARAM-1];
endmodule
