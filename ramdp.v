module  ramdp
    #(  parameter       ADDR_WID     = 5 ,
        parameter       DATA_WID     = 64
        )
    (
         input                      CLK_WR ,
         input                      WR_EN ,
         input [ADDR_WID-1:0]       ADDR_WR ,
         input [DATA_WID-1:0]       D ,
         input                      CLK_RD ,
         input                      RD_EN ,
         input [ADDR_WID-1:0]       ADDR_RD ,
         output wire [DATA_WID-1:0] Q ,
         input                      CLK_DEBUG ,
         input                      DEBUG_EN,
         input [ADDR_WID-1:0]       ADDR_DEBUG,
         output reg[DATA_WID-1:0]   DATA_DEBUG                     

     );

      //data expanding: output width > input width
      //wr IQ data every clock
      reg [DATA_WID-1:0]           mem [(1<<ADDR_WID)-1 : 0] ;
      reg [DATA_WID-1:0]           mem_wr_p, mem_wr_n ;   
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

      reg [DATA_WID-1:0] Q_r_p = 'd0, Q_r_n ='d0 ;
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

      always @(posedge CLK_DEBUG) begin
         if(DEBUG_EN) begin
            DATA_DEBUG <= mem[ADDR_DEBUG];
         end
      end

endmodule
