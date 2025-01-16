module  ccnt
  #(parameter W = 4)
   (
    input              rstn ,
    input              clk ,
    input              en ,
    output [W-1:0]     count
    );

   reg [W-1:0]          count_r_p, count_r_n ;
   always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         count_r_p        <= 'b0 ;
      end
      else if (en) begin
         count_r_p        <= (count_r_p + 1'b1);
      end
   end

   always @(negedge clk or negedge rstn) begin
      if (!rstn) begin
         count_r_n        <= 'b0 ;
      end
      else if (en) begin
         count_r_n        <= (count_r_n + 1'b1);
      end
   end

   assign count = count_r_n + count_r_p ;

endmodule
