module Apb_slave_spi_master(pclk,preset_n,paddr,pwrite,penable,psel,pwdata,prdata,pready,pslverr,
                            ss,sclk,mosi,miso,spi_interrupt_request);

input pclk,preset_n,pwrite,penable,psel,miso;
input [2:0]paddr;
input [7:0]pwdata;

output pready,pslverr,ss,sclk,mosi,spi_interrupt_request;
output [7:0]prdata;

wire [1:0]spi_mode;
wire spiswai,cpol,cpha,miso_receive_pos,miso_receive_neg,mosi_send_pos,mosi_send_neg;
wire [2:0]sppr,spr;
wire [11:0]baud_rate_divisor;
wire send_data,lsbfe,receive_data;
wire [7:0]data_mosi,data_miso;
wire tip,mstr;


spi_baud_gen block1(pclk,preset_n,spi_mode,spiswai,sppr,spr,cpol,cpha,ss,sclk,
                    miso_receive_pos,miso_receive_neg,mosi_send_pos,mosi_send_neg,baud_rate_divisor);

shift_register block2(pclk,preset_n,ss,send_data,lsbfe,cpha,cpol,
                      miso_receive_pos,miso_receive_neg,mosi_send_pos,mosi_send_neg,data_mosi,miso,
							 receive_data,mosi,data_miso);

apb_slave_interface block3(pclk,preset_n,paddr,pwrite,psel,penable,pwdata,ss,data_miso,receive_data,tip,
                           prdata,mstr,cpol,cpha,lsbfe,spiswai,sppr,spr,spi_interrupt_request,
									pready,pslverr,send_data,data_mosi,spi_mode);

slave_control_select block4(pclk,preset_n,mstr,spiswai,spi_mode,send_data,baud_rate_divisor,receive_data,ss,tip);

endmodule