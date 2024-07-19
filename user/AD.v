`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:16:03 07/14/2018 
// Design Name: 
// Module Name:    AD 
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
module AD(	clk, 
          	rst_n, 
           	sclk, 
           	dout, 
           	din, 
           	cs_n, 
           	AD_Con,
           	AD_Current,			// current value
           	AD_R_V				// resistance value
           	);

		

input 	clk;
input 	rst_n;
input  	AD_Con;				// module PWM offer, to start a control cycle AD
input 	dout;		//SPI SOMI 
output 	din;		//SPI SIMO
output 	reg cs_n;		//SPI CS
output	sclk;		//SPI CLK
output 	reg [11:0]AD_Current;
output 	reg [11:0]AD_R_V;
reg [11:0]AD_data0;	//AD_DATA0
reg [11:0]AD_data1;	//AD_DATA1
reg [11:0]AD_data2;	//AD_DATA2
reg [11:0]AD_data4;	//AD_DATA4





reg [2:0] channel;	 //to select AD channel
reg AD_Start_Flag;	 //to start a channel AD operation
wire AD_Complete_Flag;	//a channel AD operation complete flag
wire [11:0]AD128_Data;	//digital data from a channel AD operation

reg [11:0] Mema0[9:0];	//filter for current
reg [11:0] Mema1[9:0];  //filter for temperate 
reg [11:0] Mema0_Max;
reg [11:0] Mema0_Min;
reg [11:0] Mema1_Max;
reg [11:0] Mema1_Min;
reg [15:0] Mema0_Sum;
reg [15:0] Mema1_Sum;
reg [4:0] AD_CON_state;	 //state for control cycle operation 
reg [4:0] AD_10_state;	 //state for 10 times AD operation
reg AD_10_Start;
reg AD_10_Complete;
//reg [11:0] AD_data_empty;	//empty digital data
reg [7:0] WD_B128_Cnt;		//watch for B128S102 cnt
reg [11:0] AD_Current_temp;	//ad_current original value
reg [11:0] AD_R_V_temp;
reg [17:0] R_count;

parameter AD_CON_IDLE = 5'd0, AD_CON_READ_EMPTY = 5'd1, AD_CON_C0 = 5'd2,
		  AD_CON_READ_C0=5'd3, AD_CON_C1 = 5'd4, AD_CON_READ_C1=5'd5,AD_CON_C2 = 5'd6, 
		  AD_CON_READ_C2=5'd7, AD_CON_C4 = 5'd8, AD_CON_READ_C4=5'd9,AD_CON_Result_1 = 5'd10,
		  AD_CON_Result_2 = 5'd11,AD_CON_Result_3 = 5'd12,
		  AD_CON_READ_EMPTY_1 = 5'd13, AD_CON_C0_1 = 5'd14,
		  AD_CON_READ_C0_1=5'd15, AD_CON_C1_1 = 5'd16, AD_CON_READ_C1_1=5'd17, AD_CON_C4_1 = 5'd18, AD_CON_READ_C4_1=5'd19;
parameter AD_10_IDLE = 5'd0, AD_10_S1 = 5'd1, AD_10_S1_HOLD = 5'd2,  
		  AD_10_S2 = 5'd3, AD_10_S2_HOLD = 5'd4,AD_10_S3 = 5'd5, AD_10_S3_HOLD = 5'd6,
		  AD_10_S4 = 5'd7, AD_10_S4_HOLD = 5'd8,AD_10_S5 = 5'd9, AD_10_S5_HOLD = 5'd10,
		  AD_10_S6 = 5'd11, AD_10_S6_HOLD = 5'd12,AD_10_S7 = 5'd13, AD_10_S7_HOLD = 5'd14,
		  AD_10_S8 = 5'd15, AD_10_S8_HOLD = 5'd16,AD_10_S9 = 5'd17, AD_10_S9_HOLD = 5'd18,
		  AD_10_S10 = 5'd19, AD_10_S10_HOLD = 5'd20,AD_10_FILTER_A = 5'd21 ,AD_10_FILTER_B = 5'd22,
		  AD_10_FILTER_C = 5'd23;

always @(posedge clk or negedge rst_n)
  if (!rst_n)
	begin		
	  Mema0[0] <= 12'd0;Mema0[1] <= 12'd0;Mema0[2] <= 12'd0;Mema0[3] <= 12'd0;Mema0[4] <= 12'd0;
	  Mema0[5] <= 12'd0;Mema0[6] <= 12'd0;Mema0[7] <= 12'd0;Mema0[8] <= 12'd0;Mema0[9] <= 12'd0;
	  Mema1[0] <= 12'd0;Mema1[1] <= 12'd0;Mema1[2] <= 12'd0;Mema1[3] <= 12'd0;Mema1[4] <= 12'd0;
	  Mema1[5] <= 12'd0;Mema1[6] <= 12'd0;Mema1[7] <= 12'd0;Mema1[8] <= 12'd0;Mema1[9] <= 12'd0;	
	  Mema0_Max <= 12'd0;Mema0_Min <= 12'd0;Mema1_Max <= 12'd0;Mema1_Min <= 12'd0;
	  Mema0_Sum <= 16'd0;Mema1_Sum <= 16'd0;	
	  AD_Current <= 12'b0;
	  AD_R_V <= 12'b0;
	  AD_10_state <= AD_10_IDLE;
	  AD_10_Start <= 1'b0;
	end
  else 
	case(AD_10_state)
	AD_10_IDLE:
	  begin
	  	AD_10_Start <= 1'b0;
	  	Mema0[0] <= 12'd0;Mema0[1] <= 12'd0;Mema0[2] <= 12'd0;Mema0[3] <= 12'd0;Mema0[4] <= 12'd0;
	  	Mema0[5] <= 12'd0;Mema0[6] <= 12'd0;Mema0[7] <= 12'd0;Mema0[8] <= 12'd0;Mema0[9] <= 12'd0;
	  	Mema1[0] <= 12'd0;Mema1[1] <= 12'd0;Mema1[2] <= 12'd0;Mema1[3] <= 12'd0;Mema1[4] <= 12'd0;
	  	Mema1[5] <= 12'd0;Mema1[6] <= 12'd0;Mema1[7] <= 12'd0;Mema1[8] <= 12'd0;Mema1[9] <= 12'd0;
	  	Mema0_Max <= 12'd0;Mema0_Min <= 12'd0;Mema1_Max <= 12'd0;Mema1_Min <= 12'd0;
		Mema0_Sum <= 16'd0;Mema1_Sum <= 16'd0;	
	  	if(AD_Con == 1)		//wait for AD_Con from PWM module
	  	  AD_10_state <= AD_10_S1;
	  	else 
	  	  AD_10_state <= AD_10_IDLE;
	  end
	AD_10_S1:
	  begin
	  	AD_10_Start <= 1'b1;
	  	AD_10_state <= AD_10_S1_HOLD;
	  end
	AD_10_S1_HOLD:
	  begin
	  	AD_10_Start <= 1'b0; //once for an AD operation
	  	if(AD_10_Complete)
	  	  begin
	  	  	Mema0[0] <= AD_Current_temp;
	  	  	Mema1[0] <= AD_R_V_temp;
	  	  	AD_10_state <= AD_10_S2;
	  	  end
	  	else 
	  		AD_10_state <= AD_10_S1_HOLD;
	  end
	AD_10_S2:
	  begin
	  	Mema0_Max <= Mema0[0];
	  	Mema0_Min <= Mema0[0];
	  	Mema1_Max <= Mema1[0];
	  	Mema1_Min <= Mema1[0];
	  	Mema0_Sum <= Mema0_Sum + Mema0[0];
	  	Mema1_Sum <= Mema1_Sum + Mema1[0];
	  	AD_10_Start <= 1'b1;
	  	AD_10_state <= AD_10_S2_HOLD;
	  end
	AD_10_S2_HOLD:
	  begin
	  	AD_10_Start <= 1'b0; //once for an AD operation
	  	if(AD_10_Complete)
	  	  begin
	  	  	Mema0[1] <= AD_Current_temp;
	  	  	Mema1[1] <= AD_R_V_temp;
	  	  	AD_10_state <= AD_10_S3;
	  	  end
	  	else 
	  		AD_10_state <= AD_10_S2_HOLD;
	  end
	AD_10_S3:
	  begin
	  	if(Mema0[1] >= Mema0_Max)	Mema0_Max <= Mema0[1];
	  	if(Mema0[1] <= Mema0_Min)	Mema0_Min <= Mema0[1];
	  	if(Mema1[1] >= Mema1_Max)	Mema1_Max <= Mema1[1];
	  	if(Mema1[1] <= Mema1_Min)	Mema1_Min <= Mema1[1];
	  	Mema0_Sum <= Mema0_Sum + Mema0[1];
	  	Mema1_Sum <= Mema1_Sum + Mema1[1];
	  	AD_10_Start <= 1'b1;
	  	AD_10_state <= AD_10_S3_HOLD;
	  end
	AD_10_S3_HOLD:
	  begin
	  	AD_10_Start <= 1'b0; //once for an AD operation
	  	if(AD_10_Complete)
	  	  begin
	  	  	Mema0[2] <= AD_Current_temp;
	  	  	Mema1[2] <= AD_R_V_temp;
	  	  	AD_10_state <= AD_10_S4;
	  	  end
	  	else 
	  		AD_10_state <= AD_10_S3_HOLD;
	  end
	AD_10_S4:
	  begin
	  	if(Mema0[2] >= Mema0_Max)	Mema0_Max <= Mema0[2];
	  	if(Mema0[2] <= Mema0_Min)	Mema0_Min <= Mema0[2];
	  	if(Mema1[2] >= Mema1_Max)	Mema1_Max <= Mema1[2];
	  	if(Mema1[2] <= Mema1_Min)	Mema1_Min <= Mema1[2];
	  	Mema0_Sum <= Mema0_Sum + Mema0[2];
	  	Mema1_Sum <= Mema1_Sum + Mema1[2];
	  	AD_10_Start <= 1'b1;
	  	AD_10_state <= AD_10_S4_HOLD;
	  end
	AD_10_S4_HOLD:
	  begin
	  	AD_10_Start <= 1'b0; //once for an AD operation
	  	if(AD_10_Complete)
	  	  begin
	  	  	Mema0[3] <= AD_Current_temp;
	  	  	Mema1[3] <= AD_R_V_temp;
	  	  	AD_10_state <= AD_10_S5;
	  	  end
	  	else 
	  		AD_10_state <= AD_10_S4_HOLD;
	  end
	AD_10_S5:
	  begin
	  	if(Mema0[3] >= Mema0_Max)	Mema0_Max <= Mema0[3];
	  	if(Mema0[3] <= Mema0_Min)	Mema0_Min <= Mema0[3];
	  	if(Mema1[3] >= Mema1_Max)	Mema1_Max <= Mema1[3];
	  	if(Mema1[3] <= Mema1_Min)	Mema1_Min <= Mema1[3];
	  	Mema0_Sum <= Mema0_Sum + Mema0[3];
	  	Mema1_Sum <= Mema1_Sum + Mema1[3];
	  	AD_10_Start <= 1'b1;
	  	AD_10_state <= AD_10_S5_HOLD;
	  end
	AD_10_S5_HOLD:
	  begin
	  	AD_10_Start <= 1'b0; //once for an AD operation
	  	if(AD_10_Complete)
	  	  begin
	  	  	Mema0[4] <= AD_Current_temp;
	  	  	Mema1[4] <= AD_R_V_temp;
	  	  	AD_10_state <= AD_10_S6;
	  	  end
	  	else 
	  		AD_10_state <= AD_10_S5_HOLD;
	  end
	AD_10_S6:
	  begin
	  	if(Mema0[4] >= Mema0_Max)	Mema0_Max <= Mema0[4];
	  	if(Mema0[4] <= Mema0_Min)	Mema0_Min <= Mema0[4];
	  	if(Mema1[4] >= Mema1_Max)	Mema1_Max <= Mema1[4];
	  	if(Mema1[4] <= Mema1_Min)	Mema1_Min <= Mema1[4];
	  	Mema0_Sum <= Mema0_Sum + Mema0[4];
	  	Mema1_Sum <= Mema1_Sum + Mema1[4];
	  	AD_10_Start <= 1'b1;
	  	AD_10_state <= AD_10_S6_HOLD;
	  end
	AD_10_S6_HOLD:
	  begin
	  	AD_10_Start <= 1'b0; //once for an AD operation
	  	if(AD_10_Complete)
	  	  begin
	  	  	Mema0[5] <= AD_Current_temp;
	  	  	Mema1[5] <= AD_R_V_temp;
	  	  	AD_10_state <= AD_10_S7;
	  	  end
	  	else 
	  		AD_10_state <= AD_10_S6_HOLD;
	  end
	AD_10_S7:
	  begin
	  	if(Mema0[5] >= Mema0_Max)	Mema0_Max <= Mema0[5];
	  	if(Mema0[5] <= Mema0_Min)	Mema0_Min <= Mema0[5];
	  	if(Mema1[5] >= Mema1_Max)	Mema1_Max <= Mema1[5];
	  	if(Mema1[5] <= Mema1_Min)	Mema1_Min <= Mema1[5];
	  	Mema0_Sum <= Mema0_Sum + Mema0[5];
	  	Mema1_Sum <= Mema1_Sum + Mema1[5];
	  	AD_10_Start <= 1'b1;
	  	AD_10_state <= AD_10_S7_HOLD;
	  end
	AD_10_S7_HOLD:
	  begin
	  	AD_10_Start <= 1'b0; //once for an AD operation
	  	if(AD_10_Complete)
	  	  begin
	  	  	Mema0[6] <= AD_Current_temp;
	  	  	Mema1[6] <= AD_R_V_temp;
	  	  	AD_10_state <= AD_10_S8;
	  	  end
	  	else 
	  		AD_10_state <= AD_10_S7_HOLD;
	  end
	AD_10_S8:
	  begin
	  	if(Mema0[6] >= Mema0_Max)	Mema0_Max <= Mema0[6];
	  	if(Mema0[6] <= Mema0_Min)	Mema0_Min <= Mema0[6];
	  	if(Mema1[6] >= Mema1_Max)	Mema1_Max <= Mema1[6];
	  	if(Mema1[6] <= Mema1_Min)	Mema1_Min <= Mema1[6];
	  	Mema0_Sum <= Mema0_Sum + Mema0[6];
	  	Mema1_Sum <= Mema1_Sum + Mema1[6];
	  	AD_10_Start <= 1'b1;
	  	AD_10_state <= AD_10_S8_HOLD;
	  end
	AD_10_S8_HOLD:
	  begin
	  	AD_10_Start <= 1'b0; //once for an AD operation
	  	if(AD_10_Complete)
	  	  begin
	  	  	Mema0[7] <= AD_Current_temp;
	  	  	Mema1[7] <= AD_R_V_temp;
	  	  	AD_10_state <= AD_10_S9;
	  	  end
	  	else 
	  		AD_10_state <= AD_10_S8_HOLD;
	  end
	AD_10_S9:
	  begin
	  	if(Mema0[7] >= Mema0_Max)	Mema0_Max <= Mema0[7];
	  	if(Mema0[7] <= Mema0_Min)	Mema0_Min <= Mema0[7];
	  	if(Mema1[7] >= Mema1_Max)	Mema1_Max <= Mema1[7];
	  	if(Mema1[7] <= Mema1_Min)	Mema1_Min <= Mema1[7];
	  	Mema0_Sum <= Mema0_Sum + Mema0[7];
	  	Mema1_Sum <= Mema1_Sum + Mema1[7];
	  	AD_10_Start <= 1'b1;
	  	AD_10_state <= AD_10_S9_HOLD;
	  end
	AD_10_S9_HOLD:
	  begin
	  	AD_10_Start <= 1'b0; //once for an AD operation
	  	if(AD_10_Complete)
	  	  begin
	  	  	Mema0[8] <= AD_Current_temp;
	  	  	Mema1[8] <= AD_R_V_temp;
	  	  	AD_10_state <= AD_10_S10;
	  	  end
	  	else 
	  		AD_10_state <= AD_10_S9_HOLD;
	  end
	AD_10_S10:
	  begin
	  	if(Mema0[8] >= Mema0_Max)	Mema0_Max <= Mema0[8];
	  	if(Mema0[8] <= Mema0_Min)	Mema0_Min <= Mema0[8];
	  	if(Mema1[8] >= Mema1_Max)	Mema1_Max <= Mema1[8];
	  	if(Mema1[8] <= Mema1_Min)	Mema1_Min <= Mema1[8];
	  	Mema0_Sum <= Mema0_Sum + Mema0[8];
	  	Mema1_Sum <= Mema1_Sum + Mema1[8];
	  	AD_10_Start <= 1'b1;
	  	AD_10_state <= AD_10_S10_HOLD;
	  end
	AD_10_S10_HOLD:
	  begin
	  	AD_10_Start <= 1'b0; //once for an AD operation
	  	if(AD_10_Complete)
	  	  begin
	  	  	Mema0[9] <= AD_Current_temp;
	  	  	Mema1[9] <= AD_R_V_temp;
	  	  	AD_10_state <= AD_10_FILTER_A;
	  	  end
	  	else 
	  		AD_10_state <= AD_10_S10_HOLD;
	  end
	AD_10_FILTER_A:
	  begin
	  	if(Mema0[9] >= Mema0_Max)	Mema0_Max <= Mema0[9];
	  	if(Mema0[9] <= Mema0_Min)	Mema0_Min <= Mema0[9];
	  	if(Mema1[9] >= Mema1_Max)	Mema1_Max <= Mema1[9];
	  	if(Mema1[9] <= Mema1_Min)	Mema1_Min <= Mema1[9];
	  	Mema0_Sum <= Mema0_Sum + Mema0[9];
	  	Mema1_Sum <= Mema1_Sum + Mema1[9];
	  	AD_10_state <= AD_10_FILTER_B;
	  end
	AD_10_FILTER_B:
	  begin
	  	Mema0_Sum <= Mema0_Sum - Mema0_Max - Mema0_Min;
	  	Mema1_Sum <= Mema1_Sum - Mema1_Max - Mema1_Min;
	  	AD_10_state <= AD_10_FILTER_C;
	  end
	AD_10_FILTER_C:
	  begin
//	    	  	if(Mema0_Sum[14:3] >= 12'd4000 ) AD_Current <= 12'd1950;		//
//	    	  	else if(Mema0_Sum[14:3] <= 12'd98) AD_Current <= 12'd1950;
//	    	  	else if(Mema0_Sum[14:3] >= 12'h80D ) AD_Current <= Mema0_Sum[14:3] - 12'h80D;		//error is 13(D)
//	    	  	else  AD_Current <= 12'h80D - Mema0_Sum[14:3];
	  	AD_Current <= Mema0_Sum[14:3];
	  	AD_R_V <= Mema1_Sum[14:3];
	  	AD_10_state <= AD_10_IDLE;
	  end
	default:
	  begin
	  	Mema0[0] <= 12'd0;Mema0[1] <= 12'd0;Mema0[2] <= 12'd0;Mema0[3] <= 12'd0;Mema0[4] <= 12'd0;
			Mema0[5] <= 12'd0;Mema0[6] <= 12'd0;Mema0[7] <= 12'd0;Mema0[8] <= 12'd0;Mema0[9] <= 12'd0;
			Mema1[0] <= 12'd0;Mema1[1] <= 12'd0;Mema1[2] <= 12'd0;Mema1[3] <= 12'd0;Mema1[4] <= 12'd0;
			Mema1[5] <= 12'd0;Mema1[6] <= 12'd0;Mema1[7] <= 12'd0;Mema1[8] <= 12'd0;Mema1[9] <= 12'd0;
			Mema0_Max <= 12'd0;Mema0_Min <= 12'd0;Mema1_Max <= 12'd0;Mema1_Min <= 12'd0;
		Mema0_Sum <= 16'd0;Mema1_Sum <= 12'd0;	
			AD_10_state <= AD_10_IDLE;	    	  	
	  end
	endcase

always @(posedge clk or negedge rst_n)
  if (!rst_n)
  	begin
  	  AD_CON_state <= AD_CON_IDLE;
	  cs_n <= 1'b1;
	  AD_Start_Flag <= 1'b0;
	  channel <= 3'b000;
	  WD_B128_Cnt <= 8'b0;
	  AD_Current_temp <= 12'b0;	
	  AD_R_V_temp <= 12'b0;
	  AD_10_Complete <= 1'b0;
	  R_count <= 18'b0;
  	end
  else
	case(AD_CON_state)
	AD_CON_IDLE:		
   	  begin
 	    AD_10_Complete <= 1'b0;
 	    if(AD_10_Start == 1)		//wait for AD_10_Start
   	      begin
   	      if(R_count >18'd200000)
   	      	begin
   	      	  R_count <= 18'd0;
   	      	  channel <= 3'b000;
   	      	  cs_n <= 1'b0;	//start control cycle AD operation
	    	  AD_Start_Flag <= 1'b1;
	    	  AD_CON_state <= AD_CON_READ_EMPTY_1;
   	      	end
   	      else 
   	      	begin
   	      	  R_count <= R_count + 1'b1;
 	//	   	  channel <= 3'b000;
	   	      channel <= 3'b001;
	    	  cs_n <= 1'b0;	//start control cycle AD operation
	    	  AD_Start_Flag <= 1'b1;
	   	      AD_CON_state <= AD_CON_READ_EMPTY;   	      	
   	      	end
	      end
	   	else begin
	    	cs_n <= 1'b1;	//stop control cycle AD operation
	    	AD_CON_state <= AD_CON_IDLE;
	      end
	  end
	AD_CON_READ_EMPTY:		//read empty data
	  begin
	    AD_Start_Flag <= 1'b0;	//once for a channel 
	  	if(AD_Complete_Flag)	//a channel AD complete
	      begin
	      	WD_B128_Cnt <= 8'd0;
	      	AD_CON_state <= AD_CON_C0;
//	      	AD_data_empty <= AD128_Data;
	      end
	    else if(WD_B128_Cnt >= 8'd120)
	      begin
	      	WD_B128_Cnt <= 8'd0;
	      	AD_CON_state <= AD_CON_IDLE;
	      end
	    else begin
	      	AD_CON_state <= AD_CON_READ_EMPTY;
	      	WD_B128_Cnt <= WD_B128_Cnt + 1'b1;
	    end		    	  
	  end
	AD_CON_C0:			//start channel0, write channel 1, read AD_data0
	  begin
	    channel <= 3'b001;
	    AD_Start_Flag <= 1'b1;
	    AD_CON_state <= AD_CON_READ_C0;
	  end
	AD_CON_READ_C0:		//read AD_data0
	  begin
	    AD_Start_Flag <= 1'b0;	//once for a channel 
	  	if(AD_Complete_Flag)	//a channel AD complete
	      begin
	      	WD_B128_Cnt <= 8'd0;
	      	AD_CON_state <= AD_CON_C1;
//	      	AD_data0 <= AD128_Data;
	      	AD_data1 <= AD128_Data;
	      end
	    else if(WD_B128_Cnt >= 8'd120)
	      begin
	    	WD_B128_Cnt <= 8'd0;
	    	AD_CON_state <= AD_CON_IDLE;
	      end
	    else begin
	    	AD_CON_state <= AD_CON_READ_C0;
	    	WD_B128_Cnt <= WD_B128_Cnt + 1'b1;
	    end		    	  
	  end
	AD_CON_C1:			//start channel1, write channel 2, read AD_data1
	  begin
//	    channel <= 3'b010;  	//test 20200101
	    channel <= 3'b001;
	    AD_Start_Flag <= 1'b1;
	    AD_CON_state <= AD_CON_READ_C1;
	  end
	AD_CON_READ_C1:		//read AD_data1
	  begin
	    AD_Start_Flag <= 1'b0;	//once for a channel 
	  	if(AD_Complete_Flag)	//a channel AD complete
	      begin
	      	WD_B128_Cnt <= 8'd0;
	      	AD_CON_state <= AD_CON_C2;
	      	AD_data1 <= AD128_Data;
	      end
	    else if(WD_B128_Cnt >= 8'd120)
	      begin
	    	WD_B128_Cnt <= 8'd0;
	    	AD_CON_state <= AD_CON_IDLE;
	      end
	    else begin
	    	AD_CON_state <= AD_CON_READ_C1;
	    	WD_B128_Cnt <= WD_B128_Cnt + 1'b1;
	    end		    	  
	  end
	AD_CON_C2:			//start channel2, write channel 4, read AD_data2
	  begin
//	    channel <= 3'b100;  	//test 20200101
	    channel <= 3'b001;
	    AD_Start_Flag <= 1'b1;
	    AD_CON_state <= AD_CON_READ_C2;
	  end
	AD_CON_READ_C2:		//read AD_data2
	  begin
	    AD_Start_Flag <= 1'b0;	//once for a channel 
	  	if(AD_Complete_Flag)	//a channel AD complete
	      begin
	      	WD_B128_Cnt <= 8'd0;
	      	AD_CON_state <= AD_CON_C4;
	      	AD_data2 <= AD128_Data;
	      end
	    else if(WD_B128_Cnt >= 8'd120)
	      begin
	    	WD_B128_Cnt <= 8'd0;
	    	AD_CON_state <= AD_CON_IDLE;
	      end
	    else begin
	    	AD_CON_state <= AD_CON_READ_C2;
	    	WD_B128_Cnt <= WD_B128_Cnt + 1'b1;
	    end		    	  
	  end
	AD_CON_C4:			//start channel4, write channel 0, read AD_data4
	  begin
//	    channel <= 3'b000;
	    channel <= 3'b001;
	    AD_Start_Flag <= 1'b1;
	    AD_CON_state <= AD_CON_READ_C4;
	  end
	AD_CON_READ_C4:		//read AD_data4
	  begin
	    AD_Start_Flag <= 1'b0;	//once for a channel 
	  	if(AD_Complete_Flag)	//a channel AD complete
	      begin
	      	WD_B128_Cnt <= 8'd0;
	      	AD_CON_state <= AD_CON_Result_1;
	      	AD_data4 <= AD128_Data;
	      end
	    else if(WD_B128_Cnt >= 8'd120)
	      begin
	    	WD_B128_Cnt <= 8'd0;
	    	AD_CON_state <= AD_CON_IDLE;
	      end
	    else begin
	    	AD_CON_state <= AD_CON_READ_C4;
	    	WD_B128_Cnt <= WD_B128_Cnt + 1'b1;
	    end		    	  
	  end
	AD_CON_READ_EMPTY_1:
	  begin
		AD_Start_Flag <= 1'b0;	//once for a channel 
	  	if(AD_Complete_Flag)	//a channel AD complete
	      begin
	      	WD_B128_Cnt <= 8'd0;
	      	AD_CON_state <= AD_CON_C0_1;
//	      	AD_data_empty <= AD128_Data;
	      end
	    else if(WD_B128_Cnt >= 8'd120)
	      begin
	      	WD_B128_Cnt <= 8'd0;
	      	AD_CON_state <= AD_CON_IDLE;
	      end
	    else begin
	      	AD_CON_state <= AD_CON_READ_EMPTY_1;
	      	WD_B128_Cnt <= WD_B128_Cnt + 1'b1;
	    end		    	  
	  end
	AD_CON_C0_1:			//start channel0, write channel 1, read AD_data0
	  begin
	    channel <= 3'b000;
	    AD_Start_Flag <= 1'b1;
	    AD_CON_state <= AD_CON_READ_C0_1;
	  end
	AD_CON_READ_C0_1:		//read AD_data0
	  begin
	    AD_Start_Flag <= 1'b0;	//once for a channel 
	  	if(AD_Complete_Flag)	//a channel AD complete
	      begin
	      	WD_B128_Cnt <= 8'd0;
	      	AD_CON_state <= AD_CON_C1_1;
//	      	AD_data0 <= AD128_Data;
	      	AD_data0 <= AD128_Data;
	      end
	    else if(WD_B128_Cnt >= 8'd120)
	      begin
	    	WD_B128_Cnt <= 8'd0;
	    	AD_CON_state <= AD_CON_IDLE;
	      end
	    else begin
	    	AD_CON_state <= AD_CON_READ_C0_1;
	    	WD_B128_Cnt <= WD_B128_Cnt + 1'b1;
	    end		    	  
	  end
	AD_CON_C1_1:			//start channel1, write channel 2, read AD_data1
	  begin
//	    channel <= 3'b010;  	//test 20200101
	    channel <= 3'b000;
	    AD_Start_Flag <= 1'b1;
	    AD_CON_state <= AD_CON_READ_C1_1;
	  end
	AD_CON_READ_C1_1:		//read AD_data1
	  begin
	    AD_Start_Flag <= 1'b0;	//once for a channel 
	  	if(AD_Complete_Flag)	//a channel AD complete
	      begin
	      	WD_B128_Cnt <= 8'd0;
	      	AD_CON_state <= AD_CON_C4_1;
	      	AD_data0 <= AD128_Data;
	      end
	    else if(WD_B128_Cnt >= 8'd120)
	      begin
	    	WD_B128_Cnt <= 8'd0;
	    	AD_CON_state <= AD_CON_IDLE;
	      end
	    else begin
	    	AD_CON_state <= AD_CON_READ_C1_1;
	    	WD_B128_Cnt <= WD_B128_Cnt + 1'b1;
	    end		    	  
	  end
	AD_CON_C4_1:			//start channel4, write channel 0, read AD_data4
	  begin
//	    channel <= 3'b000;
	    channel <= 3'b000;
	    AD_Start_Flag <= 1'b1;
	    AD_CON_state <= AD_CON_READ_C4_1;
	  end
	AD_CON_READ_C4_1:		//read AD_data4
	  begin
	    AD_Start_Flag <= 1'b0;	//once for a channel 
	  	if(AD_Complete_Flag)	//a channel AD complete
	      begin
	      	WD_B128_Cnt <= 8'd0;
	      	AD_CON_state <= AD_CON_Result_1;
	      	AD_data0 <= AD128_Data;
	      end
	    else if(WD_B128_Cnt >= 8'd120)
	      begin
	    	WD_B128_Cnt <= 8'd0;
	    	AD_CON_state <= AD_CON_IDLE;
	      end
	    else begin
	    	AD_CON_state <= AD_CON_READ_C4_1;
	    	WD_B128_Cnt <= WD_B128_Cnt + 1'b1;
	    end		    	  
	  end
	AD_CON_Result_1:
	  begin
	  	AD_CON_state <= AD_CON_Result_2;	
/*	  	AD_R_V_temp <= AD_data1;
	  	if((AD_data0 >= AD_data2)&&(AD_data2 >= AD_data4))
	  	  AD_Current_temp <= AD_data2;
	  	else if((AD_data0 >= AD_data4)&&(AD_data4 >= AD_data2))
	  	  AD_Current_temp <= AD_data4;
	  	else if((AD_data2 >= AD_data0)&&(AD_data0 >= AD_data4))	 							
	  	  AD_Current_temp <= AD_data0;
	  	else if((AD_data2 >= AD_data4)&&(AD_data4 >= AD_data0))	 							
	  	  AD_Current_temp <= AD_data4;
	  	else if((AD_data4 >= AD_data0)&&(AD_data0 >= AD_data2))	 							
	  	  AD_Current_temp <= AD_data0;
	  	else 
	  	  AD_Current_temp <= AD_data2;
	  	  */
	  	AD_R_V_temp <= AD_data0;
	  	if((AD_data1 >= AD_data2)&&(AD_data2 >= AD_data4))
	  	  AD_Current_temp <= AD_data2;
	  	else if((AD_data1 >= AD_data4)&&(AD_data4 >= AD_data2))
	  	  AD_Current_temp <= AD_data4;
	  	else if((AD_data2 >= AD_data1)&&(AD_data1 >= AD_data4))	 							
	  	  AD_Current_temp <= AD_data1;
	  	else if((AD_data2 >= AD_data4)&&(AD_data4 >= AD_data1))	 							
	  	  AD_Current_temp <= AD_data4;
	  	else if((AD_data4 >= AD_data1)&&(AD_data1 >= AD_data2))	 							
	  	  AD_Current_temp <= AD_data1;
	  	else 
	  	  AD_Current_temp <= AD_data2;
	  end
	AD_CON_Result_2:
	  begin
		if(AD_Current_temp >= 12'd4000) AD_Current_temp <= 12'd1950;
		else if(AD_Current_temp <= 12'd98) AD_Current_temp <= 12'd1950;
		else if(AD_Current_temp >= 12'h809) AD_Current_temp <= AD_Current_temp -12'h809;
		else AD_Current_temp <= 12'h809 - AD_Current_temp;
		AD_CON_state <= AD_CON_Result_3;
	  end
	AD_CON_Result_3:
	  begin
		AD_CON_state <= AD_CON_IDLE;
		AD_10_Complete <= 1'b1;	
	  end
	default: AD_CON_state <= AD_CON_IDLE;
	endcase

////////////////////////////B128S102///////////////////////////////
B128S102  B128S102_0(
	.clk(clk), 
    .rst_n(rst_n), 
    .sclk(sclk), 
    .dout(dout), 
    .din(din), 
    .channel(channel),		////channel select
    .AD_Start_Flag(AD_Start_Flag),
    .AD_Complete_Flag(AD_Complete_Flag),
    .AD128_Data(AD128_Data)
    );






endmodule
