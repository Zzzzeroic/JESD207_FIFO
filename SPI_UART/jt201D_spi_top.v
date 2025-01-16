//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:19:55 11/20/2024 
// Design Name: 
// Module Name:    jt201D_test_top 
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
module jt201D_spi_top
#(  parameter RAM_ADDR_WID = 7,
    parameter RAM_DATA_WID = 12 )
(   input i_clk_sys,            //system input 66M clock
    input i_rst_n,
    input i_uart_rx,
    output o_uart_tx,
    output o_ld_parity,
    output [6:0] o_ld_debug,
    
    //SPI param
    output o_SCLK,
    output o_MOSI,
    input  i_MISO,
    output o_SEN,

    output debug_ram_en,
    output [RAM_ADDR_WID-1:0] debug_addr,
    input  [RAM_DATA_WID-1:0] debug_data
    );
    wire w_clk_sys;

    localparam DIV_PARAM = 2;
    localparam SPI_DATA_WIDTH = 20;
    localparam SPI_ADDR_WIDTH = 6;
    localparam UART_DATA_WIDTH = 8;
    localparam BAUD_RATE = 115200;
    localparam PARITY_ON = 0;
    localparam PARITY_TYPE = 1;
    localparam sys_clk = 66_000_000/(2**DIV_PARAM);

    clock_divider
    #(
        .DIV_PARAM(DIV_PARAM)
    ) u_clk_div
    (
        .i_clk_sys(i_clk_sys),
        .i_rst_n(i_rst_n),
        .o_clk_sys_div(w_clk_sys)
    );

    //wire spi_busy;
    wire spi_start, spi_rw, spi_data_valid;
    wire [SPI_DATA_WIDTH-1:0] spi_read_data, spi_write_data;
    wire [SPI_ADDR_WIDTH-1:0] spi_addr;
    uart_data_controller
    #(
        .SPI_ADDR_WIDTH(SPI_ADDR_WIDTH),
        .SPI_DATA_WIDTH(SPI_DATA_WIDTH),
        .CLK_FRE(sys_clk),         		//时钟频率，时钟频率为66MHz
        .UART_DATA_WIDTH(UART_DATA_WIDTH),   //有效数据位，缺省为8位
        .PARITY_ON(PARITY_ON),     //校验位，1为有校验位，0为无校验位，缺省为0
        .PARITY_TYPE(PARITY_TYPE), //校验类型，1为奇校验，0为偶校验，缺省为偶校验
        .BAUD_RATE(BAUD_RATE)      //波特率，缺省为115200
    ) u_uart_data
    (
        .i_clk_sys(w_clk_sys),
        .i_rst_n(i_rst_n),
        .i_uart_rx(i_uart_rx),
        .o_uart_tx(o_uart_tx),
        .o_ld_parity(o_ld_parity),

        .i_spi_data_valid(spi_data_valid),
        //.i_spi_busy(spi_busy), //unused
        .i_spi_data(spi_read_data),
        .o_spi_start(spi_start),
        .o_spi_rw(spi_rw),
        .o_spi_addr(spi_addr),
        .o_spi_data(spi_write_data),
        .o_ld_debug(o_ld_debug),
        
        //debug
        .debug_ram_en(debug_ram_en),
        .debug_addr(debug_addr),
        .debug_data(debug_data)
    );

    SPI_Controller u_spi
    (
        .i_clk_sys(w_clk_sys),
        .i_rst_n(i_rst_n),
        .i_start(spi_start),
        .i_rw(spi_rw),
        .i_address(spi_addr),
        .i_write_data(spi_write_data),
        .o_read_data(spi_read_data),
        .o_data_valid(spi_data_valid),
        .i_MISO(i_MISO),
        .o_SCLK(o_SCLK),
        .o_MOSI(o_MOSI),
        .o_SEN(o_SEN)
        //.o_busy(spi_busy)
    );

endmodule
