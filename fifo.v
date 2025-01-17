module  fifo
    #(  parameter       ADDR_WID        = 7 ,
        parameter       DATA_WID        = 16 ,
        parameter       PROG_DEPTH = 64) //programmable full
    (
        input                   rstn,
        input                   wclk,
        input                   winc,
        output [ADDR_WID-1: 0]  waddr,

        input                   rclk,
        input                   rinc,
        output [ADDR_WID-1 : 0] raddr,

        output                  wfull,
        output                  rempty,
        output                  prog_full
     );

   localparam       EXTENT       = DATA_WID/DATA_WID ;
   localparam       EXTENT_BIT   = ADDR_WID-ADDR_WID ;
   localparam       SHRINK       = DATA_WID/DATA_WID ;
   localparam       SHRINK_BIT   = ADDR_WID-ADDR_WID ;

   //======================= push counter =====================

   wire                         wover_flag ;  //counter overflow
   ccnt         #(.W(ADDR_WID+1))             //128
   u_push_cnt(
              .rstn           (rstn),
              .clk            (wclk),
              .en             (winc && !wfull),
              .count          ({wover_flag, waddr})
              );

   //========================== pop counter ==================================

   wire                      rover_flag ;   //counter overflow
   ccnt         #(.W(ADDR_WID+1))         //128
   u_pop_cnt(
             .rstn           (rstn),
             .clk            (rclk),
             .en             (rinc & !rempty), //read forbidden when empty
             .count          ({rover_flag, raddr})
             );

   //==============================================
   //small in and big out
   //=====================================

      //gray code
      wire [ADDR_WID:0] wptr    = ({wover_flag, waddr}>>1) ^ ({wover_flag, waddr}) ;
      //sync wr ptr
      reg [ADDR_WID:0]  rq2_wptr_r0 ;
      reg [ADDR_WID:0]  rq2_wptr_r1 ;
      always @(posedge rclk or negedge rstn) begin
         if (!rstn) begin
            rq2_wptr_r0     <= 'b0 ;
            rq2_wptr_r1     <= 'b0 ;
         end
         else begin
            rq2_wptr_r0     <= wptr ;
            rq2_wptr_r1     <= rq2_wptr_r0 ;
         end
      end

      //gray code
      wire [ADDR_WID-1:0] raddr_ex = raddr << EXTENT_BIT ;
      wire [ADDR_WID:0]   rptr     = ({rover_flag, raddr_ex}>>1) ^ ({rover_flag, raddr_ex}) ;
      //sync rd ptr
      reg [ADDR_WID:0]    wq2_rptr_r0 ;
      reg [ADDR_WID:0]    wq2_rptr_r1 ;
      always @(posedge wclk or negedge rstn) begin
         if (!rstn) begin
            wq2_rptr_r0     <= 'b0 ;
            wq2_rptr_r1     <= 'b0 ;
         end
         else begin
            wq2_rptr_r0     <= rptr ;
            wq2_rptr_r1     <= wq2_rptr_r0 ;
         end
      end

      //decode
      reg [ADDR_WID:0]       wq2_rptr_decode ;
      reg [ADDR_WID:0]       rq2_wptr_decode ;
      integer           i ;
      always @(*) begin
         wq2_rptr_decode[ADDR_WID] = wq2_rptr_r1[ADDR_WID];
         for (i=ADDR_WID-1; i>=0; i=i-1) begin
            wq2_rptr_decode[i] = wq2_rptr_decode[i+1] ^ wq2_rptr_r1[i] ;
         end
      end
      always @(*) begin
         rq2_wptr_decode[ADDR_WID] = rq2_wptr_r1[ADDR_WID];
         for (i=ADDR_WID-1; i>=0; i=i-1) begin
            rq2_wptr_decode[i] = rq2_wptr_decode[i+1] ^ rq2_wptr_r1[i] ;
         end
      end


      assign rempty    = (rover_flag == rq2_wptr_decode[ADDR_WID]) &&
                         (raddr_ex >= rq2_wptr_decode[ADDR_WID-1:0]);
      assign wfull     = (wover_flag != wq2_rptr_decode[ADDR_WID]) &&
                         (waddr >= wq2_rptr_decode[ADDR_WID-1:0]) ;
      assign prog_full  = (wover_flag == wq2_rptr_decode[ADDR_WID]) ?
                          waddr - wq2_rptr_decode[ADDR_WID-1:0] >= PROG_DEPTH-1 :
                          waddr + (1<<ADDR_WID) - wq2_rptr_decode[ADDR_WID-1:0] >= PROG_DEPTH-1;


endmodule
