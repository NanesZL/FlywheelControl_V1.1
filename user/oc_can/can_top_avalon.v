module can_top_avalon(

     //Avalon common
    input                   av_clk,
    input                   av_reset,
    //Avalon control port
    input  [7:0]            av_address,
    input                   av_chipselect,
    input                   av_write,
    input                   av_read,
    input  [7:0]            av_writedata,
    output [7:0]            av_readdata,
    output                  av_waitrequest_n,

	// CAN interface
	input		CAN_clk,
	input		CAN_reset,
	input		CAN_rx,
	output		CAN_tx,
	output      CAN_irq,
	output      CAN_clkout

);


wire wb_ack_o;

assign av_waitrequest_n = wb_ack_o;

reg loc_read,loc_write;
always@(posedge av_clk)
if( av_waitrequest_n | av_reset )
loc_write <= 1'b0;
else if( av_write )
loc_write <= 1'b1;

always@(posedge av_clk)
if( av_waitrequest_n | av_reset )
loc_read <= 1'b0;
else if( av_read )
loc_read <= 1'b1;




can_top wishbone_can_inst
( 
  .wb_clk_i(av_clk),
  .wb_rst_i(av_reset | CAN_reset),
  .wb_dat_i(av_writedata[7:0]),
  .wb_dat_o(av_readdata[7:0]),
  .wb_cyc_i(loc_write | loc_read),
  .wb_stb_i(av_chipselect & (loc_write | loc_read)),
  .wb_we_i (loc_write & ~loc_read),
  .wb_adr_i(av_address[7:0]),
  .wb_ack_o(wb_ack_o),
//  .cs_can_i(av_chipselect),
  .clk_i(CAN_clk),
  .rx_i(CAN_rx),
  .tx_o(CAN_tx),
  .irq_on(CAN_irq),
  .clkout_o(CAN_clkout)

);

endmodule
