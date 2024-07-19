`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:14:58 07/14/2018 
// Design Name: 
// Module Name:    B128S102 
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
module B128S102(clk, 
          		rst_n, 
           		sclk, 
           		dout, 
           		din, 
           		channel,		////channel select
           		AD_Start_Flag,
           		AD_Complete_Flag,
           		AD128_Data);

input 	clk;
input 	rst_n;
input  	[2:0] channel;
input  	AD_Start_Flag;
input 	dout;		////SPI SOMI 

output 	reg din;		////SPI SIMO
output	reg sclk;		////SPI CLK
output	reg AD_Complete_Flag;	////once Analog to Digital complete flag
output  reg [11:0]AD128_Data;	////once Analog to Digital data

reg add2;		////channel select d2
reg add1;		////channel select d1
reg add0;		////channel select d0
reg [11:0] data;	////put dout to data 
reg [5:0] B128_state;
parameter B128_IDLE = 6'd0, B128_S1_N = 6'd1, 	B128_S1_P = 6'd2, 	B128_S2_N = 6'd3, 	B128_S2_P = 6'd4, 
							B128_S3_N = 6'd5, 	B128_S3_P = 6'd6, 	B128_S4_N = 6'd7, 	B128_S4_P = 6'd8,
							B128_S5_N = 6'd9, 	B128_S5_P = 6'd10, 	B128_S6_N = 6'd11, 	B128_S6_P = 6'd12,
							B128_S7_N = 6'd13, 	B128_S7_P = 6'd14, 	B128_S8_N = 6'd15, 	B128_S8_P = 6'd16,
							B128_S9_N = 6'd17, 	B128_S9_P = 6'd18, 	B128_S10_N = 6'd19, B128_S10_P = 6'd20,
							B128_S11_N = 6'd21, B128_S11_P = 6'd22, B128_S12_N = 6'd23, B128_S12_P = 6'd24,
							B128_S13_N = 6'd25, B128_S13_P = 6'd26, B128_S14_N = 6'd27, B128_S14_P = 6'd28,
							B128_S15_N = 6'd29, B128_S15_P = 6'd30, B128_S16_N = 6'd31, B128_S16_P = 6'd32,
							B128_FINISH = 6'd33;

always @(posedge clk or negedge rst_n)
  if(!rst_n)
  	begin
  	  sclk <= 1'b1;
  	  data <= 12'h000;  	   
      add2 <= 1'b0;
      add1 <= 1'b0;
      add0 <= 1'b0;
      AD128_Data <= 12'd0;
      B128_state <= B128_IDLE;
  	end
  else begin
    case(B128_state)
    B128_IDLE:
      begin
      	AD_Complete_Flag <= 1'b0;
      	data <= 12'h000;
      	sclk <= 1'b1;
      	if(AD_Start_Flag)
      	  begin
      	  	add2 <= channel[2];
      	  	add1 <= channel[1];
      	  	add0 <= channel[0];      	  	
      	  	B128_state <= B128_S1_N;
      	  end      	  
      	else begin
      		B128_state <= B128_IDLE; 
      		add2 <= 1'b0;
      		add1 <= 1'b0;
      		add0 <= 1'b0;
      	end      	
      end
    B128_S1_N:			////1st sclk negedge
       begin
      	sclk <= 1'b0;
      	din <= 1'b0;
      	B128_state <= B128_S1_P;      	
      end
    B128_S1_P:			////1st sclk posedge
      begin
      	sclk <= 1'b1;
      	B128_state <= B128_S2_N;       	
      end
	B128_S2_N:	
	  begin
      	sclk <= 1'b0;
      	din <= 1'b0;
      	B128_state <= B128_S2_P;      	
      end
    B128_S2_P:			
      begin
      	sclk <= 1'b1;
      	B128_state <= B128_S3_N;       	
      end
    B128_S3_N:			//3rd sclk negedge,write to add2
      begin
      	sclk <= 1'b0;
      	din <= add2;
      	B128_state <= B128_S3_P;      	
      end
    B128_S3_P:			//3rd sclk posedge
      begin
      	sclk <= 1'b1;
      	B128_state <= B128_S4_N;       	
      end
    B128_S4_N:			//4th sclk negedge,write to add1
      begin
      	sclk <= 1'b0;
      	din <= add1;
      	B128_state <= B128_S4_P;      	
      end
    B128_S4_P:			//4th sclk posedge    
      begin
      	sclk <= 1'b1;
      	B128_state <= B128_S5_N;       	
      end
    B128_S5_N:			//5th sclk negedge,write to add0
      begin
      	sclk <= 1'b0;
      	din <= add0;
      	B128_state <= B128_S5_P;      	
      end
    B128_S5_P:			//5th sclk posedge,read DB11
      begin
      	sclk <= 1'b1;
      	data[11] <= dout;
      	B128_state <= B128_S6_N;       	
      end
    B128_S6_N:			//6th sclk negedge,write to 0
      begin
      	sclk <= 1'b0;
      	din <= 1'b0;
      	B128_state <= B128_S6_P;      	
      end
    B128_S6_P:			//6th sclk posedge,read DB10
      begin
      	sclk <= 1'b1;
      	data[10] <= dout;
      	B128_state <= B128_S7_N;       	
      end
    B128_S7_N:			//7th sclk negedge,write to 0
      begin
      	sclk <= 1'b0;
      	din <= 1'b0;
      	B128_state <= B128_S7_P;      	
      end
    B128_S7_P:			//7th sclk posedge,read DB9
      begin
      	sclk <= 1'b1;
      	data[9] <= dout;
      	B128_state <= B128_S8_N;       	
      end
    B128_S8_N:			//8th sclk negedge,write to 0
      begin
      	sclk <= 1'b0;
      	din <= 1'b0;
      	B128_state <= B128_S8_P;      	
      end
    B128_S8_P:			//8th sclk posedge,read DB8
      begin
      	sclk <= 1'b1;
      	data[8] <= dout;
      	B128_state <= B128_S9_N;       	
      end
    B128_S9_N:			//9th sclk negedge,write to 0
      begin
      	sclk <= 1'b0;
      	din <= 1'b0;
      	B128_state <= B128_S9_P;      	
      end
    B128_S9_P:			//9th sclk posedge,read DB7
      begin
      	sclk <= 1'b1;
      	data[7] <= dout;
      	B128_state <= B128_S10_N;       	
      end
    B128_S10_N:			//10th sclk negedge,write to 0
      begin
      	sclk <= 1'b0;
      	din <= 1'b0;
      	B128_state <= B128_S10_P;      	
      end
    B128_S10_P:			//10th sclk posedge,read DB6
      begin
      	sclk <= 1'b1;
      	data[6] <= dout;
      	B128_state <= B128_S11_N;       	
      end
    B128_S11_N:			//11th sclk negedge,write to 0
      begin
      	sclk <= 1'b0;
      	din <= 1'b0;
      	B128_state <= B128_S11_P;      	
      end
    B128_S11_P:			//11th sclk posedge,read DB5
      begin
      	sclk <= 1'b1;
      	data[5] <= dout;
      	B128_state <= B128_S12_N;       	
      end
    B128_S12_N:			//12th sclk negedge,write to 0
      begin
      	sclk <= 1'b0;
      	din <= 1'b0;
      	B128_state <= B128_S12_P;      	
      end
    B128_S12_P:			//12th sclk posedge,read DB4
      begin
      	sclk <= 1'b1;
      	data[4] <= dout;
      	B128_state <= B128_S13_N;       	
      end
    B128_S13_N:			//13th sclk negedge,write to 0
      begin
      	sclk <= 1'b0;
      	din <= 1'b0;
      	B128_state <= B128_S13_P;      	
      end
    B128_S13_P:			//13th sclk posedge,read DB3
      begin
      	sclk <= 1'b1;
      	data[3] <= dout;
      	B128_state <= B128_S14_N;       	
      end
    B128_S14_N:			//14th sclk negedge,write to 0
      begin
      	sclk <= 1'b0;
      	din <= 1'b0;
      	B128_state <= B128_S14_P;      	
      end
    B128_S14_P:			//14th sclk posedge,read DB2
      begin
      	sclk <= 1'b1;
      	data[2] <= dout;
      	B128_state <= B128_S15_N;       	
      end
    B128_S15_N:			//15th sclk negedge,write to 0
      begin
      	sclk <= 1'b0;
      	din <= 1'b0;
      	B128_state <= B128_S15_P;      	
      end
    B128_S15_P:			//15th sclk posedge,read DB1
      begin
      	sclk <= 1'b1;
      	data[1] <= dout;
      	B128_state <= B128_S16_N;       	
      end
    B128_S16_N:			//16th sclk negedge,write to 0
      begin
      	sclk <= 1'b0;
      	din <= 1'b0;
      	B128_state <= B128_S16_P;      	
      end
    B128_S16_P:			//16th sclk posedge,read DB0
      begin
      	sclk <= 1'b1;
      	data[0] <= dout;
      	B128_state <= B128_FINISH;       	
      end
    B128_FINISH:		//ad finish for once
      begin
      	sclk <= 1'b1;	//keep sclk hign for next ad cycle
      	AD128_Data <= data;		//AD128_Data 
      	AD_Complete_Flag <= 1'b1;	//AD complete
      	B128_state <= B128_IDLE;
      end
    endcase  	
  end





endmodule
