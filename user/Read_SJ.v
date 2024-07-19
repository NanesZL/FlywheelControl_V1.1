`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:44:08 07/14/2018 
// Design Name: 
// Module Name:    Read_SJ 
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
module Read_SJ(
	input	write_en,		// flag to start write operation
	input read_en,    // flag to start read operation
	output reg read_finish_flag ,	// read operation end flag,1 - finish
	input	 clk,
	input	 rst_n,
	input  [7:0] addr,
	output  reg [7:0] data,
	inout   [7:0] SJ_AD,
	output 	reg SJ_ALE,
	output 	reg SJ_CS_n,
	output 	reg SJ_RD_n,
	output 	reg SJ_WR_n
		);
assign SJ_AD = (SJ_out_en)? {SJ_AD_r} :8'hzzzz; //  SJ_out_en : 0 - SJ data in, 1 - SJ data out   
reg	[3:0]RD_state;
reg [7:0]SJ_AD_r;
reg SJ_out_en;

parameter RD_IDLE = 4'd0, RD_C0 = 4'd1, RD_AL_HOLD = 4'd2, RD_C1 = 4'd3, 
          RD_C2 = 4'd4, RD_C3 = 4'd5, RD_C4 = 4'd6, RD_RD_HOLD = 4'd7, 
          RD_C5=4'd10, RD_C6 = 4'd8, RD_C7 = 4'd9;

always @(posedge clk or negedge rst_n)
  if (!rst_n)
  	begin
  		SJ_ALE <= 1'b0;
      SJ_RD_n <= 1'b1;
      SJ_WR_n <= 1'b1;
      SJ_CS_n <= 1'b1;
      SJ_AD_r <= 8'h00;
      SJ_out_en <= 1'b0;
      read_finish_flag <= 1'b0;
      RD_state <= RD_IDLE;
  	end
  else begin
  	case(RD_state)
  	RD_IDLE:
  	  begin
  	  	if((!write_en)&&(read_en))  // write_en = 0 && read_en = 1, start read operation
  	  	  begin
  	  	  	RD_state <= RD_C0;   //CLK0,1 clk time = 33.33ns
  	  	  end
  	  	else 
  	  	  begin
            SJ_ALE <= 1'b0;
            SJ_RD_n <= 1'b1;
            SJ_WR_n <= 1'b1;
            SJ_CS_n <= 1'b1;
            SJ_AD_r <= 8'h00;
            SJ_out_en <= 1'b0;
            read_finish_flag <= 1'b0;
  	  	  	RD_state <= RD_IDLE;
  	  	  end
  	  end
    RD_C0:  // ALE = 1,addr out
      begin
        SJ_ALE <= 1'b1;
        SJ_out_en <= 1'b1;    //SJ_AD out
        SJ_AD_r  <= addr;  
        RD_state <= RD_AL_HOLD;      
      end
    RD_AL_HOLD:    // ALE hold for 1 clk time 
      begin
        RD_state <= RD_C1;
      end
    RD_C1:  // ALE = 0,addr out hold
      begin
        RD_state <= RD_C2;
        SJ_ALE <= 1'b0;
      end
    RD_C2:  // cs_n = 0, SJ_out_en = 0, prepare for addr data in
      begin
        RD_state <= RD_C3;
        SJ_out_en = 1'b0;
        SJ_CS_n <= 1'b0;
      end
    RD_C3:  // rd_n = 0
      begin
        RD_state <= RD_C4;
        SJ_RD_n <= 1'b0;
      end
    RD_C4:  // hold for data valid 
      begin       
        RD_state <= RD_RD_HOLD1;
      end
    RD_RD_HOLD1:   // rd hold for 1 clk time(datasheet need at least 40ns)
      begin
        RD_state <= RD_RD_HOLD2; 
       end 
    RD_RD_HOLD2:   // rd hold for 1 clk time
      begin
        RD_state <= RD_C5; 
       end 
    RD_C5:    //rd_n = 1, read addr data
      begin
        SJ_RD_n <= 1'b1;
        data <= SJ_AD;
        RD_state <= RD_C6; 
      end
    RD_C6:    // cs_n = 1 
      begin
        SJ_CS_n <= 1'b1;
        RD_state <= RD_C7; 
      end
    RD_C7:    // finish flag out 
      begin
        read_finish_flag <= 1'b1;
        RD_state <= RD_IDLE; 
      end
    default:
      begin
        RD_state <= RD_IDLE;
      end
  	endcase
  end

endmodule
