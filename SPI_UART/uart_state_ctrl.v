//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:49:31 11/20/2024 
// Design Name: 
// Module Name:    uart_state_ctrl 
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
`define CHAR_ZERO 8'd48
`define CHAR_SWITCH_LINE 8'd10
`define CHAR_COMMA 8'd44
module uart_state_ctrl
#(
    parameter SPI_ADDR_WIDTH = 6,
    parameter SPI_DATA_WIDTH = 20,
    parameter UART_DATA_WIDTH = 8,
    parameter RAM_ADDR_WID = 7,     //调试用ram地址位宽
    parameter RAM_DATA_WID = 12     //调试用ram数据位宽
)
(
    input i_clk_sys,
    input i_rst_n,
    //UART rx params
    input [UART_DATA_WIDTH-1:0] i_uart_data,
    input i_rx_done,

    //UART tx params
    input                               i_uart_idle,
    output reg [UART_DATA_WIDTH-1:0]    o_data_tx,
    output reg                          o_data_valid,
    //SPI params
    input      i_spi_data_valid,
    output reg o_spi_start,
    output reg o_spi_rw,//0->write, 1->read
    output reg [SPI_ADDR_WIDTH-1:0] o_spi_write_address,
    output reg [SPI_DATA_WIDTH-1:0] o_spi_write_data,
    input  [SPI_DATA_WIDTH-1:0] i_spi_read_data,

    //debug
    output reg[6:0] o_ld_debug,
    //ram info
    output reg debug_ram_en,
    output reg[RAM_ADDR_WID-1:0] debug_addr,
    input  [RAM_DATA_WID-1:0] debug_data
    );

    localparam IDLE = 4'b0000, REC_ADDR_HEAD = 4'b0001, READ_ADDR=4'b0010, 
                REC_DATA_HEAD = 4'b0011, READ_DATA = 4'b0100, WRITE_DATA=4'b0101, 
                UART_TX=4'b0110, RAM_DEBUG=4'b0111, DONE = 4'b1111;
    
    localparam WRITE_STR = "Write\n";
    localparam READ_STR = "Read\n";

    reg [3:0] state, next_state;
    reg [4:0] bit_cnt;
    reg [19:0] shift_reg;

    wire [3:0] uart_data_hex;

    assign uart_data_hex = (i_uart_data>=48 && i_uart_data<=57)?i_uart_data[3:0]:
                            ((i_uart_data>=65 && i_uart_data<=70)||(i_uart_data>=97&&i_uart_data<=102))?{1'b1,{i_uart_data[2:0]}+1'b1}:
                             4'd0;
    //Finite State Machine
    //1st
    always @(posedge i_clk_sys or negedge i_rst_n) begin
        if (!i_rst_n) state <= IDLE;
        else state <= next_state;
    end
    //2nd
    always @(*) begin
        case (state)
        IDLE:           next_state = (i_uart_data=="T")?RAM_DEBUG : 
                                        (i_uart_data=="{")?REC_ADDR_HEAD:IDLE;
        REC_ADDR_HEAD:  next_state = (bit_cnt==2)? READ_ADDR : REC_ADDR_HEAD;//A->Read, a->Write
        READ_ADDR:
        begin
            if(bit_cnt==4)
                next_state = (o_spi_rw)?READ_DATA:REC_DATA_HEAD;
            else 
                next_state = READ_ADDR;
        end
        REC_DATA_HEAD:  next_state = (bit_cnt==6)?WRITE_DATA:REC_DATA_HEAD;
        WRITE_DATA:     next_state = (bit_cnt==11)?UART_TX:WRITE_DATA;
        READ_DATA:      next_state = (i_spi_data_valid 
                                        && ~o_spi_start
                                        && bit_cnt==5)?UART_TX:READ_DATA;
        UART_TX:        next_state = (bit_cnt==0)?DONE:UART_TX;
        RAM_DEBUG:      next_state = (debug_addr=={RAM_ADDR_WID{1'b1}})? DONE : RAM_DEBUG;
        DONE:           next_state = IDLE;  
        default:        next_state = IDLE;
        endcase
    end

    reg[2:0] debug_data_num_cnt;
    reg[2:0] debug_cnt_switch_line;//every 4th data, send one '\n', or send ','
    reg[7:0] debug_data_xxxx_bit;
    always @(*) begin
        case(debug_data_num_cnt)
            3'd0:   debug_data_xxxx_bit <= debug_data/1000 + `CHAR_ZERO;
            3'd1:   debug_data_xxxx_bit <= (debug_data%1000)/100 + `CHAR_ZERO;
            3'd2:   debug_data_xxxx_bit <= (debug_data%100)/10 + `CHAR_ZERO;
            3'd3:   debug_data_xxxx_bit <= (debug_data%10) + `CHAR_ZERO;
            default:debug_data_xxxx_bit <= 'd0;
        endcase
    end
    //3rd
    always @(posedge i_clk_sys or negedge i_rst_n) begin
        if(~i_rst_n) begin
            bit_cnt                 <= 5'd0;
            o_spi_start             <= 1'b0;
            o_spi_rw                <= 1'b0;
            o_spi_write_address     <= 6'd0;
            o_spi_write_data        <= 20'd0;
            o_data_tx               <= 8'd0;
            o_data_valid            <= 1'b0;
            o_ld_debug              <= 7'b111_1111;
            debug_ram_en            <= 1'b0;
            debug_addr              <= 'd0;
            debug_data_num_cnt      <= 'd0;
            debug_cnt_switch_line   <= 'd0;
            shift_reg               <= 'd0;
        end else begin
            case(state)
            IDLE: begin
                bit_cnt     <= 5'd0;
                o_ld_debug  <= 7'b111_0000;
                debug_addr  <= 'd0;
                debug_ram_en<= (i_uart_data=="T")?1'b1:1'b0;
            end
            REC_ADDR_HEAD: begin
                o_ld_debug <= 7'b000_0001;
                if(i_rx_done) begin
                    case(bit_cnt)
                    5'd0:begin
                        if(i_uart_data=="A") begin
                            o_spi_rw <= 1'b1;
                            bit_cnt <= bit_cnt+1'b1;
                        end
                        else if(i_uart_data=="a") begin
                            o_spi_rw <= 1'b0;
                            bit_cnt <= bit_cnt+1'b1;
                        end
                        else bit_cnt <= 5'd0;
                    end
                    5'd1:
                        if(i_uart_data==":") begin
                            bit_cnt <= bit_cnt+1'b1;
                        end
                        else bit_cnt <= 5'd0;
                    default: bit_cnt <= 5'd0;
                    endcase
                end
            end
            READ_ADDR: begin
                o_ld_debug <= 7'b000_0011;
                if(i_rx_done) begin
                    bit_cnt <= bit_cnt + 1'b1;
                    if(bit_cnt == 5'd2) begin   //i_uart_data - 8'b00110000
                        o_spi_write_address[5:4] <= uart_data_hex[1:0];
                    end
                    else if(bit_cnt == 5'd3) begin
                        o_spi_write_address[3:0] <= uart_data_hex[3:0];
                    end
                end
            end
            REC_DATA_HEAD: begin
                o_ld_debug <= 7'b000_0111;
                if(i_rx_done) begin
                    if(i_uart_data=="D" && bit_cnt == 5'd4)
                        bit_cnt <= bit_cnt+1'b1;
                    else if(i_uart_data==":" && bit_cnt == 5'd5)
                        bit_cnt <= bit_cnt+1'b1;
                end
            end
            WRITE_DATA: begin
                o_ld_debug <= 7'b000_1111;
                if(i_rx_done) begin
                    bit_cnt <= bit_cnt + 1'b1;
                    o_spi_write_data <= {o_spi_write_data[15:0], uart_data_hex};
                end
                if(bit_cnt == 5'd11) 
                    o_spi_start <= 1'b1;
            end
            READ_DATA: begin//begin to read and wait the result
                o_ld_debug <= 7'b001_1111;
                if(i_spi_data_valid && bit_cnt==4) begin
                    o_spi_start <= 1'b1;
                    bit_cnt <= bit_cnt+1'b1;
                end
                else o_spi_start <= 1'b0;
            end
            UART_TX: begin
                o_spi_start <= 1'b0;
                o_ld_debug  <= 7'b011_1111;
                if(i_uart_idle && o_data_valid == 1'b0) begin
                    o_spi_start <= 1'b0;
                    if(o_spi_rw==0) //write mode, bit_cnt starts from 11
                    begin
                        o_data_valid    <= 1'b1;
                        o_data_tx       <= (WRITE_STR)>>(8*(16-bit_cnt));
                        bit_cnt         <= (bit_cnt==16)?0:bit_cnt+1'b1;
                    end
                    else begin  //read mode, bit_cnt starts from 6, rec len=4
                        o_data_valid    <= 1'b1;
                        if(bit_cnt<=10) begin
                            o_data_tx       <= (READ_STR)>>(8*(10-bit_cnt));
                            shift_reg       <= i_spi_read_data;
                        end
                        else begin
                            if(shift_reg[19:16]<=4'd9)
                                o_data_tx   <= shift_reg[19:16] + "0";
                            else 
                                o_data_tx   <= shift_reg[19:16] + "A" - 8'd10;
                            shift_reg       <= shift_reg << 3'd4;
                        end
                        bit_cnt         <= (bit_cnt==15)?0:bit_cnt+1'b1;
                    end
                end
                else o_data_valid <= 1'b0;
            end
            RAM_DEBUG: begin
                if(i_uart_idle && o_data_valid==1'b0) begin
                    o_data_valid = 1'b1;
                    if(debug_data_num_cnt<3'd4) begin
                        o_data_tx <= debug_data_xxxx_bit; 
                        debug_data_num_cnt <= debug_data_num_cnt + 1'b1;
                    end else begin
                        if(debug_cnt_switch_line<3) begin
                            o_data_tx <= `CHAR_COMMA;
                            debug_cnt_switch_line = debug_cnt_switch_line + 1'b1;
                        end else begin
                            o_data_tx <= `CHAR_SWITCH_LINE;
                            debug_cnt_switch_line = 'd0;
                        end
                        debug_data_num_cnt <= 'd0;
                        debug_addr <= debug_addr + 1'b1;
                    end
                    if(debug_addr=={RAM_ADDR_WID{1'b1}}) debug_ram_en <= 1'b0;
                end
                else o_data_valid = 1'b0;
            end
            DONE: begin
                o_ld_debug <= 7'b111_1111;
                bit_cnt <= 5'd0;
            end
            endcase
        end
    end
endmodule
