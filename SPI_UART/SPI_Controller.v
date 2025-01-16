//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:20:24 11/20/2024 
// Design Name: 
// Module Name:    spi 
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
module SPI_Controller(
    input i_clk_sys,
    input i_rst_n,
    input i_start,
    input i_rw,                       //0->Write, 1->Read

    input[5:0] i_address,
    input[19:0] i_write_data,         //data from PoolCache, transfer to jt201D
    output reg[19:0] o_read_data,     //data from jt201D, display for user
    output reg o_data_valid,          //able to receive data from cache pool
    //SPI
    input i_MISO,
    output reg o_SCLK,
    output reg o_MOSI,
    output reg o_SEN
    //testSignal
    //output reg o_busy
    //output reg o_send_done
    );

    parameter IDLE = 3'b000, START = 3'b001, SEND_ADDR = 3'b010, SEND_DATA = 3'b011, 
                WAIT_READ = 3'b100, READ_DATA = 3'b101, DONE = 3'b110;

    reg [2:0] state, next_state;
    reg [4:0] bit_cnt;           // 位计数器，用于控制位发送与接收
    reg [19:0] shift_reg;        // 数据移位寄存器
    reg [5:0] addr_reg;          // 地址寄存器

    always @(posedge i_clk_sys or negedge i_rst_n) begin
        if (!i_rst_n)
            state <= IDLE;
        else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state) 
        IDLE:       next_state = (i_start==1'b1)?START:IDLE;
        START:      next_state = SEND_ADDR;
        SEND_ADDR:
        begin
            if(bit_cnt == 5'd6) 
                next_state = (i_rw)?WAIT_READ:SEND_DATA;// swtich to write mode or read mode
            else
                next_state = SEND_ADDR;
        end
        SEND_DATA:  next_state = (bit_cnt==5'd26)?DONE:SEND_DATA;
        WAIT_READ:  next_state = (bit_cnt==5'd10)? READ_DATA:WAIT_READ;
        READ_DATA:  next_state = (bit_cnt==5'd31)?DONE:READ_DATA;
        DONE:       next_state = IDLE;
        default:    next_state = IDLE;
        endcase
    end

    always @(posedge i_clk_sys or negedge i_rst_n) begin
        if(~i_rst_n) begin
            o_SEN         <= 1'b1;
            o_data_valid  <= 1'b0;
            o_SCLK        <= 1'b0;
            o_MOSI        <= 1'b0;
            bit_cnt     <= 5'd0;
            shift_reg   <= 20'd0;
            addr_reg    <= 5'd0;
            //o_send_done   <= 1'b0;
            //o_busy        <= 1'b1;
            o_read_data   <= 20'd0;
        end else begin
            case (state)
            IDLE:
            begin
                o_SEN           <= 1'b1;
                //o_busy        <= 1'b0;
                o_data_valid    <= (i_start==1'b1)?1'b0:1'b1;
                bit_cnt         <= 5'd0;
            end
            START:
            begin
                //o_busy        <= 1'b1;
                o_SEN           <= 1'b0;
                addr_reg        <= i_address;
                shift_reg       <= i_write_data;
                o_data_valid    <= 1'b0;
                bit_cnt         <= 5'd0;
                o_MOSI          <= i_rw;
            end
            SEND_ADDR:
            begin
                o_SCLK    <= ~o_SCLK;
                if(o_SCLK) begin // negedge
                    o_MOSI      <= addr_reg[5];
                    addr_reg    <= addr_reg << 1;
                    bit_cnt     <= bit_cnt+1'b1;
                end
            end
            SEND_DATA:
            begin
                o_SCLK    <= ~o_SCLK;
                if(o_SCLK) begin
                    o_MOSI      <= shift_reg[19];
                    shift_reg   <= shift_reg << 1'b1;
                    bit_cnt     <= bit_cnt+1'b1;
                end
            end
            WAIT_READ:  
            begin
                o_SCLK      <= 1'b0;
                o_SEN       <= (bit_cnt<10)?1'b1:1'b0;
                bit_cnt     <= bit_cnt+1'b1;
            end
            READ_DATA:
            begin
                o_SEN     <= 1'b0;
                o_SCLK    <= ~o_SCLK;
                if(!o_SCLK)begin
                    shift_reg <= {shift_reg[18:0], i_MISO};
                    bit_cnt <= bit_cnt+1'b1;
                end
                else if(bit_cnt == 30 &&o_SCLK) begin //make sure this state can exit at the negedge of SCLK
                    bit_cnt <= bit_cnt+1'b1;
                end

            end
            DONE: begin
                if (i_rw==1) o_read_data <= shift_reg;
                o_SEN  <= 1'b1;
                o_SCLK <= 1'b0;
                //o_busy <= 1'b0;
            end
            endcase
        end
    end
endmodule

