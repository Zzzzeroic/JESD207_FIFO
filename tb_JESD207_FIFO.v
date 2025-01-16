`timescale 1ns/1ns

`define         JESD_FIFO_TEST
`define         JESD_DATA_WIDTH 12
`define         JESD_FIFO_DEPTH 64

module tb_JESD207_FIFO ;

`ifdef JESD_FIFO_TEST
   reg          proc_start = 0;
   reg          btn_tx_nrx = 0;
   wire         tx_nrx;
   wire         jesd_en;
   reg          rstn ;
   reg          M_CLK ;
   wire         F_CLK ;
   reg [`JESD_DATA_WIDTH-1:0]    din ;
   wire [`JESD_DATA_WIDTH-1:0]  dout ;

   //reset
   initial begin
      M_CLK  = 0 ;
      rstn      = 0 ;
      #50 rstn  = 1 ;
   end

   //clock
   parameter CYCLE_FRE_KHZ = 5120;
   localparam CYCLE_TARGET_CNT = 1000_000 / CYCLE_FRE_KHZ / 2;
   always #(CYCLE_TARGET_CNT) M_CLK = ~M_CLK ;
   assign #(CYCLE_TARGET_CNT/2) F_CLK = M_CLK ;

   //data generate
   initial begin
      din       = 16'h4321 ;
      wait (rstn) ;
      proc_start = 1;
      #200 proc_start = 0;
      //(1) test prog_full and full
      btn_tx_nrx   = 1'b0;
      repeat(32) begin
         @(negedge F_CLK) ;
         din    = {$random()} % 16;
      end

      //(2) test read and write fifo
      #500 ;
      rstn = 0 ;
      #10 rstn = 1 ;
      proc_start = 1;
      #200 proc_start = 0;

      btn_tx_nrx    = 1'b0;
      repeat(100) begin
         @(negedge F_CLK or posedge F_CLK) ;
         din    = {$random()} % 16;
      end

      //(3) test again: prog_full and full
      proc_start = 1;
      #200 proc_start = 0;
      
      btn_tx_nrx    = 1'b1;
      repeat(18) begin
         @(negedge F_CLK or posedge F_CLK) ;
         din    = {$random()} % 16;
      end
      //(4) test read and empty
      #80000;
   end

   wire fifo_empty, fifo_full, prog_full ;
   //data buffer
   top_JESD207_FIFO #(
      .AWI($clog2(`JESD_FIFO_DEPTH)),
      .AWO($clog2(`JESD_FIFO_DEPTH)),
      .DWI(`JESD_DATA_WIDTH),
      .DWO(`JESD_DATA_WIDTH),
      .PROG_DEPTH(`JESD_FIFO_DEPTH)
   )
   u_data_buf2
   (
        .proc_start     (proc_start),
        .btn_tx_nrx     (btn_tx_nrx),
        .tx_nrx         (tx_nrx),
        .jesd_en        (jesd_en),
        .rstn           (rstn),
        .wdata          (din),
        .mclk           (M_CLK),

        .rdata          (dout),
        .fclk           (F_CLK),
        .rempty         (fifo_empty),
        .wfull          (fifo_full),
        .prog_full      (prog_full)
        );

`endif
   //stop sim
   initial begin
      forever begin
         #100;
         if ($time >= 200000)  $finish ;
      end
   end

endmodule // test
