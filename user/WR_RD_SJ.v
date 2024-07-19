`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:43:42 07/14/2018 
// Design Name: 
// Module Name:    Write_SJ 
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
module WR_RD_SJ(
	input	[1:0] write_read_en,		// flag to start write/read operation, 10 - write, 01 - read
  output reg finish_flag ,	// write/read operation end flag,1 - finish
	input	clk,
	input	rst_n,
  input [7:0]addr,
  input [7:0]data_2_sj, //data write to SJA1000
  output reg [7:0]data_4_sj, //data read from SJA1000
	inout [7:0] SJ_AD,
  output reg SJ_out_en,   //SJA_DIR,0 - SJ data in, 1 - SJ data out 
  output reg SJ_ALE,
  output reg SJ_CS_n,
  output reg SJ_RD_n,
  output reg SJ_WR_n
    );
reg [7:0]SJ_AD_r;
assign SJ_AD = (SJ_out_en)? {SJ_AD_r} :8'hzz; //  SJ_out_en : 0 - SJ data in, 1 - SJ data out   
reg	[4:0]WR_state;  //write and read state

parameter WR_IDLE = 5'd0, WR_C0 = 5'd1, WR_AL_HOLD = 5'd2, WR_C1 = 5'd3, 
          WR_C2 = 5'd4, WR_C3 = 5'd5, WR_C4 = 5'd6, WR_WR_HOLD = 5'd7, 
          WR_C5 = 5'd8, WR_C6 = 5'd9, WR_C7 = 5'd10,
          RD_C0 = 5'd11,RD_AL_HOLD= 5'd12, RD_C1= 5'd13, RD_C2= 5'd14,
          RD_C3= 5'd15, RD_C4= 5'd16, RD_RD_HOLD1= 5'd17, RD_RD_HOLD2= 5'd18,
          RD_C5= 5'd19, RD_C6= 5'd20, RD_C7= 5'd21;



always @(posedge clk or negedge rst_n)
  if (!rst_n)
  	begin
  		SJ_ALE <= 1'b0;
      SJ_RD_n <= 1'b1;
      SJ_WR_n <= 1'b1;
      SJ_CS_n <= 1'b1;
      SJ_AD_r <= 8'h00;
      SJ_out_en <= 1'b0;
      finish_flag <= 1'b0;
      WR_state <= WR_IDLE;
  	end
  else begin
  	case(WR_state)
  	WR_IDLE:
  	  begin
  	  	if(write_read_en == 2'b10)  // write_read_en == 2'b10, start write operation
  	  	  	WR_state <= WR_C0;   //CLK0,1 clk time = 33.33ns
        else if (write_read_en == 2'b01)  //// write_read_en == 2'b01, start read operation
            WR_state <= RD_C0;
  	  	else 
  	  	  begin
            SJ_ALE <= 1'b0;
            SJ_RD_n <= 1'b1;
            SJ_WR_n <= 1'b1;
            SJ_CS_n <= 1'b1;
            SJ_AD_r <= 8'h00;
            SJ_out_en <= 1'b0;
            finish_flag <= 1'b0;
  	  	  	WR_state <= WR_IDLE;
  	  	  end
  	  end
    WR_C0:  // ALE = 1,addr out
      begin
        SJ_ALE <= 1'b1;
        SJ_out_en <= 1'b1;    //SJ_AD out
        SJ_AD_r  <= addr;  
        WR_state <= WR_AL_HOLD;      
      end
    WR_AL_HOLD:    // ALE hold for 1 clk time 
      begin
        WR_state <= WR_C1;
      end
    WR_C1:  // ALE = 0,addr out hold
      begin
        WR_state <= WR_C2;
        SJ_ALE <= 1'b0;
      end
    WR_C2:  // cs_n = 0
      begin
        WR_state <= WR_C3;
        SJ_CS_n <= 1'b0;
      end
    WR_C3:  // wr_n = 0
      begin
        WR_state <= WR_C4;
        SJ_WR_n <= 1'b0;
      end
    WR_C4:  // addr out 
      begin
        SJ_out_en <= 1'b1;    //SJ_AD out
        SJ_AD_r  <= data_2_sj;
        WR_state <= WR_WR_HOLD;
      end
    WR_WR_HOLD:   // WR and data hold for 1 clk time
      begin
        WR_state <= WR_C5; 
       end 
    WR_C5:    //wr_n = 1
      begin
        SJ_WR_n <= 1'b1;
        WR_state <= WR_C6; 
      end
    WR_C6:    // cs_n = 1 
      begin
        SJ_CS_n <= 1'b1;
        WR_state <= WR_C7; 
      end
    WR_C7:    // finish flag out 
      begin
        finish_flag <= 1'b1;
        WR_state <= WR_IDLE; 
      end    
    RD_C0:  // ALE = 1,addr out
      begin
        SJ_ALE <= 1'b1;
        SJ_out_en <= 1'b1;    //SJ_AD out
        SJ_AD_r  <= addr;  
        WR_state <= RD_AL_HOLD;      
      end
    RD_AL_HOLD:    // ALE hold for 1 clk time 
      begin
        WR_state <= RD_C1;
      end
    RD_C1:  // ALE = 0,addr out hold
      begin
        WR_state <= RD_C2;
        SJ_ALE <= 1'b0;
      end
    RD_C2:  // cs_n = 0, SJ_out_en = 0, prepare for addr data in
      begin
        WR_state <= RD_C3;
        SJ_out_en <= 1'b0;
        SJ_CS_n <= 1'b0;
      end
    RD_C3:  // rd_n = 0
      begin
        WR_state <= RD_C4;
        SJ_RD_n <= 1'b0;
      end
    RD_C4:  // hold for data valid 
      begin       
        WR_state <= RD_RD_HOLD1;
      end
    RD_RD_HOLD1:   // rd hold for 1 clk time(datasheet need at least 40ns)
      begin
        WR_state <= RD_RD_HOLD2; 
       end 
    RD_RD_HOLD2:   // rd hold for 1 clk time
      begin
        WR_state <= RD_C5; 
       end 
    RD_C5:    //rd_n = 1, read SJA1000 data
      begin
        SJ_RD_n <= 1'b1;
        data_4_sj <= SJ_AD;
        WR_state <= RD_C6; 
      end
    RD_C6:    // cs_n = 1 
      begin
        SJ_CS_n <= 1'b1;
        WR_state <= RD_C7; 
      end
    RD_C7:    // finish flag out 
      begin
        finish_flag <= 1'b1;
        WR_state <= WR_IDLE; 
      end
    default:
      begin
        WR_state <= WR_IDLE;
      end
  	endcase
  end


endmodule
