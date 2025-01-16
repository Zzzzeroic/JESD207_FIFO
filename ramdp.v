module  ramdp
    #(  parameter       AWI     = 5 ,
        parameter       AWO     = 7 ,
        parameter       DWI     = 64 ,
        parameter       DWO     = 16
        )
    (
        input                   CLK_WR ,
        input                   WR_EN ,
        input [AWI-1:0]         ADDR_WR ,
        input [DWI-1:0]         D ,
        input                   CLK_RD ,
        input                   RD_EN ,
        input [AWO-1:0]         ADDR_RD ,
        output wire [DWO-1:0]   Q
     );

   genvar i ;
   generate
      //data expanding: output width > input width
      if (DWO >= DWI) begin
         //wr IQ data every clock
         reg [DWI-1:0]           mem [(1<<AWI)-1 : 0] ;
         reg [DWI-1:0]           mem_wr_p, mem_wr_n ;   
         //write Q data
         always @(posedge CLK_WR) begin
            if (WR_EN) begin
               mem[ADDR_WR]   <= D ;
               mem[ADDR_WR+1] <= mem_wr_n ;
            end
         end

         //write I data
         always @(negedge CLK_WR) begin
            if (WR_EN) begin
               mem_wr_n       <= D ;
            end
         end

         reg [DWI-1:0] Q_r_p = 'd0, Q_r_n ='d0 ;
         //rd IQ data every clock
         always @(posedge CLK_RD) begin
            if (RD_EN) begin
               Q_r_p  <= mem[ADDR_RD] ^ Q_r_n ;
            end
         end

         always @(negedge CLK_RD) begin
            if (RD_EN) begin
               Q_r_n  <= mem[ADDR_RD] ^ Q_r_p ;
            end
         end
         assign Q = Q_r_n ^ Q_r_p ;
      end
   endgenerate

endmodule
