`timescale 1ns/1ns

`define         JESD_FIFO_TEST
`define         JESD_DATA_WIDTH 12
`define         JESD_FIFO_DEPTH 128

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
   reg          sysclk=0;       

   //reset
   initial begin
      M_CLK  = 0 ;
      rstn      = 0 ;
      #50 rstn  = 1 ;
   end

   //clock
   parameter CYCLE_FRE_KHZ = 30720;
   localparam CYCLE_TARGET_CNT = 1000_000 / CYCLE_FRE_KHZ / 2;
   always #(CYCLE_TARGET_CNT) M_CLK = ~M_CLK ;
   always #(7.57575) sysclk = ~sysclk;
   //data generate
   initial begin
      din       = 12'h321 ;
      wait (rstn) ;
      proc_start = 1;
      #200 proc_start = 0;
      //(1) test prog_full and full
      btn_tx_nrx   = 1'b0;
      repeat(32) begin
         @(negedge F_CLK) ;
         din    = {$random()} % 4096;
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
         din    = {$random()} % 4096;
      end
      #10000;
      //(3) test again: prog_full and full
      proc_start = 1;
      #200 proc_start = 0;
      
      btn_tx_nrx    = 1'b1;
      repeat(18) begin
         @(negedge F_CLK or posedge F_CLK) ;
         din    = {$random()} % 4096;
      end
      #10000;
      //(4) test read and empty
      proc_start = 1;
      #200 proc_start = 0;
      #15000;

      //(5) test uart debug ram
      u_data_buf2.u_spi_uart.u_uart_data.u_uart_rx.o_uart_data = "T";
      #1000;
      u_data_buf2.u_spi_uart.u_uart_data.u_uart_rx.o_uart_data = 'd0;
   end

   wire fifo_empty, fifo_full, prog_full ;
   //data buffer
   top_JESD207_FIFO #(
      .ADDR_WID($clog2(`JESD_FIFO_DEPTH)),
      .DATA_WID(`JESD_DATA_WIDTH),
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
      .prog_full      (prog_full),
      .sysclk         (sysclk),
      .i_uart_rx      (),
      .o_uart_tx      (),
      .o_SCLK         (),
      .o_MOSI         ()
   );

`endif
   //stop sim
   initial begin
      forever begin
         #100;
         if ($time >= 5_000_000)  $stop ;
      end
   end

endmodule // test
