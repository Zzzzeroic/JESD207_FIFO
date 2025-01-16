`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:33:56 11/20/2024 
// Design Name: 
// Module Name:    uart_data_controller 
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
module uart_data_controller
#(
    parameter SPI_ADDR_WIDTH = 6,
    parameter SPI_DATA_WIDTH = 20,
    parameter CLK_FRE = 66,         //时钟频率，默认时钟频率为66MHz
    parameter UART_DATA_WIDTH = 8,  //有效数据位，缺省为8位
    parameter PARITY_ON = 1,        //校验位，1为有校验位，0为无校验位，缺省为0
    parameter PARITY_TYPE = 0,      //校验类型，1为奇校验，0为偶校验，缺省为偶校验
    parameter BAUD_RATE = 9600,     //波特率，缺省为9600
    parameter RAM_ADDR_WID = 7,     //调试用ram地址位宽
    parameter RAM_DATA_WID = 12     //调试用ram数据位宽
)
(
    input       i_clk_sys,
    input       i_rst_n,
    input       i_uart_rx,          //uart rec
    output      o_uart_tx,          //uart trans
    output      o_ld_parity,
    output[6:0] o_ld_debug,
    //SPI_interface
    input                       i_spi_data_valid,
    //input                       i_spi_busy, 
    input  [SPI_DATA_WIDTH-1:0] i_spi_data, //从spi读取到的寄存器信息
    output                      o_spi_start,
    output                      o_spi_rw,
    output [SPI_ADDR_WIDTH-1:0] o_spi_addr, //地址
    output [SPI_DATA_WIDTH-1:0] o_spi_data, //通过spi写入到寄存器的信息

    output debug_ram_en,
    output [RAM_ADDR_WID-1:0] debug_addr,
    input  [RAM_DATA_WID-1:0] debug_data
    );

    wire[UART_DATA_WIDTH-1:0]   w_data;
    wire                        w_rx_done;

    uart_rx
    #(
        .CLK_FRE(CLK_FRE),         		//时钟频率，时钟频率为66MHz
        .UART_DATA_WIDTH(UART_DATA_WIDTH),   //有效数据位，缺省为8位
        .PARITY_ON(PARITY_ON),     //校验位，1为有校验位，0为无校验位，缺省为0
        .PARITY_TYPE(PARITY_TYPE), //校验类型，1为奇校验，0为偶校验，缺省为偶校验
        .BAUD_RATE(BAUD_RATE)      //波特率，缺省为115200
    ) u_uart_rx
    (
        .i_clk_sys(i_clk_sys),      //系统时钟
        .i_rst_n(i_rst_n),        	//全局异步复位,低电平有效
        .i_uart_rx(i_uart_rx),      //UART输入
        .o_uart_data(w_data),    	//UART接收数据
        .o_ld_parity(o_ld_parity),  //校验位检验LED，高电平位为校验正确
        .o_rx_done(w_rx_done)       //UART数据接收完成标志
    );

    wire uart_tx_idle, uart_tx_busy;
    wire [UART_DATA_WIDTH-1:0] uart_tx_data;
    wire uart_tx_data_valid;

    uart_tx //该模块i_data_tx与i_data_valid同时高电平一个时钟即可完成uart的tx端输出
    #(
        .CLK_FRE(CLK_FRE),         		//时钟频率，时钟频率为66MHz
        .UART_DATA_WIDTH(UART_DATA_WIDTH),    //有效数据位，缺省为8位
        .PARITY_ON(PARITY_ON),      //校验位，1为有校验位，0为无校验位，缺省为0
        .PARITY_TYPE(PARITY_TYPE),  //校验类型，1为奇校验，0为偶校验，缺省为偶校验
        .BAUD_RATE(BAUD_RATE)      	//波特率，缺省为9600
    ) u_uart_tx
    (   .i_clk_sys(i_clk_sys),      //系统时钟
        .i_rst_n(i_rst_n),        	//全局异步复位
        //todo: 利用其它模块自行向tx端输入数据
        .i_data_tx(uart_tx_data),   //传输数据输入
        .i_data_valid(uart_tx_data_valid),//传输数据有效
        .o_uart_idle(uart_tx_idle), //UART空闲
        .o_uart_tx(o_uart_tx)       //UART输出
        );

    uart_state_ctrl
    #(
        .SPI_ADDR_WIDTH(SPI_ADDR_WIDTH),
        .SPI_DATA_WIDTH(SPI_DATA_WIDTH),
        .UART_DATA_WIDTH(UART_DATA_WIDTH)
    ) u_uart_ctrl
    (
        .i_clk_sys(i_clk_sys),
        .i_rst_n(i_rst_n),
        //UART rx params
        .i_uart_data(w_data),
        .i_rx_done(w_rx_done),

        //UART tx params
        .i_uart_idle(uart_tx_idle),
        .o_data_tx(uart_tx_data),
        .o_data_valid(uart_tx_data_valid),

        //SPI params
        .i_spi_data_valid(i_spi_data_valid),
        .o_spi_start(o_spi_start),
        .o_spi_rw(o_spi_rw),
        .o_spi_write_address(o_spi_addr),
        .o_spi_write_data(o_spi_data),
        .i_spi_read_data(i_spi_data),

        //debug
        .o_ld_debug(o_ld_debug),
        .debug_ram_en(debug_ram_en),
        .debug_addr(debug_addr),
        .debug_data(debug_data)
    );
endmodule
