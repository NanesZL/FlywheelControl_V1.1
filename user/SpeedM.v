`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:30:23 07/14/2018 
// Design Name: 
// Module Name:    SpeedM 
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
module SpeedM(
	clk120,
 	rst_n,
 	Hall_a,
 	Hall_b,
 	Hall_c,
 	Speed_Value,
 	sv_h,
 	time_sv
    );
input clk120,rst_n;
input Hall_a,Hall_b,Hall_c;
output reg [30:0] Speed_Value; //SV for FPGA
output reg [31:0] sv_h;		//high speed value
output reg[30:0] time_sv;		//make sv_h_cnt out;

wire hallwave;

assign hallwave=(Hall_a^Hall_b)^Hall_c;

reg hallwave1,hallwave2,hallwave3,hallwave4;


always @(posedge clk120 or negedge rst_n)
   if(!rst_n) begin
	  hallwave1 <= 1'b0;
   	  hallwave2 <= 1'b0;
      hallwave3 <= 1'b0;
	  hallwave4 <= 1'b0;
	end
   else  begin
      hallwave1 <= hallwave;
	  hallwave2 <= hallwave1;
	  hallwave3 <= hallwave2;
	  hallwave4 <= hallwave3;
   end

wire hallwave_neg = hallwave4 & ~hallwave3;
wire hallwave_pos = ~hallwave4 & hallwave3;
wire hallwave_pn = hallwave_neg | hallwave_pos;







////////////////////////********Speed_Value for low speed**********///////////////////////////
parameter SV_IDLE_PN = 3'd0,WT_POS_PN = 3'd1,WT_POS2_PN = 3'd2,
          SpeedZero_PN = 3'd3; 

reg[29:0] SVCnt_PN;
reg[29:0] SVMema_PN[1:0];
reg SV_EN_FLAG_PN;
reg [2:0] SVstate_PN;


always @(posedge clk120 or negedge rst_n)			//pos count
  if(!rst_n)
  	begin
  	  SVCnt_PN <=30'd0;
  	  SVMema_PN[0] <= 30'd0;
      SVMema_PN[1] <= 30'd0;
	  SV_EN_FLAG_PN <= 1'b0;			//0----sp = 0;1----sp != 0;
	  SVstate_PN <= SV_IDLE_PN;
  	end
  else 
  	begin
  	  case(SVstate_PN)
  		SV_IDLE_PN:
  	    begin
		  if(hallwave_pn) 
		    begin
   		  	  SVstate_PN <= WT_POS_PN;
			  SVCnt_PN <=30'b0;
			end
          else if(SVCnt_PN > 30'd240000000)	//2s
		    begin
			  SVstate_PN <= WT_POS_PN;
			  SVCnt_PN <= 30'd0;
			 end
		  else 
            begin		  
		      SVstate_PN <= SV_IDLE_PN;
			  SVCnt_PN <= SVCnt_PN + 1'b1;		  
            end				
        end
        WT_POS_PN:
        begin
		  if(hallwave_pn)
		    begin
		      SVstate_PN <= WT_POS2_PN;	
			  SVCnt_PN <=30'b0;
            end				
          else if(SVCnt_PN > 30'd240000000) //2s
		    begin
		      SVstate_PN <= SpeedZero_PN;
			  SVCnt_PN <= 30'd0;
			end
		  else
            begin
			   SVstate_PN <= WT_POS_PN;
			   SVCnt_PN <= SVCnt_PN + 1'b1;
			end
		end
		WT_POS2_PN:
	    begin
          if(hallwave_pn)
		  	begin
		  	  SV_EN_FLAG_PN <= 1'b1;
		      SVstate_PN <= WT_POS2_PN;		      
              SVMema_PN[0] <= SVCnt_PN;
              SVMema_PN[1] <= SVMema_PN[0];
	          SVCnt_PN <= 30'd0;
          	end	
          else if(SVCnt_PN > 30'd240000000) //2s
		  	begin 
			  SVCnt_PN <= 30'd0;
			  SVstate_PN <= SpeedZero_PN;
		  	end
		  else 
		  	begin
			  SVCnt_PN <= SVCnt_PN + 1'b1;
			  SVstate_PN <=  WT_POS2_PN;    	
          	end				
       	end
       	SpeedZero_PN:
       	begin
       	  SV_EN_FLAG_PN <= 1'b0;				//speed = 0
       	  SVstate_PN <= SV_IDLE_PN;      	  
       	end
       	default:
       	begin
       	  SV_EN_FLAG_PN <= 1'b0;				//speed = 0
       	  SVstate_PN <= SV_IDLE_PN;    	
       	end
      endcase

  	end

parameter Filter_IDLE = 2'd0,FILTER_A = 2'd1;

reg [1:0] Filter_State;
always @ (posedge clk120 or negedge rst_n)
if(!rst_n)
  begin
    Filter_State <= Filter_IDLE; 
    Speed_Value <= 31'd0;
  end
else 
  begin
	case(Filter_State)
	Filter_IDLE:
	  begin	    
	  	if(SV_EN_FLAG_PN == 1'b1)
	  	  Filter_State <= FILTER_A;
	  	else 
	  	  begin
	  		Filter_State <= Filter_IDLE;
	  		Speed_Value <= 31'd0;
	  	  end	  		
	  end
	FILTER_A:
	  begin
	  	Speed_Value <= {1'b0,SVMema_PN[0]} + {1'b0,SVMema_PN[1]};
	  	Filter_State <= Filter_IDLE;	  		
	  end
	default:
      begin
      	Filter_State <= Filter_IDLE;       	    	
      end
    endcase 	
  end



////////////////////////************SpeedValue for high speed************////////////////////////////////////////


parameter SV_IDLE_H = 3'd0,WT_NEG_H = 3'd1,WT_POS_H = 3'd2,WT_POS2_H = 3'd3; 
parameter COUNT0 = 6'd0,COUNT1 = 6'd1,COUNT2 = 6'd2,COUNT3 = 6'd3, COUNT4 = 6'd4,COUNT5 = 6'd5,COUNT6 = 6'd6,COUNT7 = 6'd7,
		  COUNT8 = 6'd8,COUNT9 = 6'd9,COUNT10 = 6'd10,COUNT11 = 6'd11,COUNT12 = 6'd12,COUNT13 = 6'd13, COUNT14 = 6'd14,COUNT15 = 6'd15,
		  COUNT16 = 6'd16,COUNT17 = 6'd17,COUNT18 = 6'd18,COUNT19 = 6'd19,COUNT20 = 6'd20,COUNT21 = 6'd21,COUNT22 = 6'd22,COUNT23 = 6'd23, 
		  COUNT24 = 6'd24,COUNT25 = 6'd25,COUNT26 = 6'd26,COUNT27 = 6'd27,COUNT28 = 6'd28,COUNT29 = 6'd29,COUNT30 = 6'd30,COUNT31 = 6'd31,
		  COUNT32 = 6'd32,COUNT33 = 6'd33,COUNT34 = 6'd34,COUNT35 = 6'd35;

reg[5:0] cnt_count; 		//36 for 1s
reg [35:0] count_start_flag;
reg[5:0] refresh_flag;
reg[2:0] SVstate_H;
reg[28:0] SVCnt_H;




always @(posedge clk120 or negedge rst_n)			//30pos count for high speed(1000r/min+),10 counts for all
  if(!rst_n)
  	begin
  	  cnt_count <= COUNT0;
	  count_start_flag  <= 36'b0; 	  //stop count0~count17
	  refresh_flag <= 6'd60;
	  SVstate_H <= SV_IDLE_H;
	  SVCnt_H <=29'd0;
  		
  	end
  else 
  	begin
  	  case(SVstate_H)
  		SV_IDLE_H:
  		begin
  		  cnt_count <= COUNT0;
  		  count_start_flag  <= 36'b0;	//stop count0~count35
		  refresh_flag <= 6'b111111;	//clear sv_h  
		  SVstate_H <= WT_NEG_H;
		  SVCnt_H <=29'd0;
  		end
  		WT_NEG_H:
  	    begin
		  if(hallwave_pn) 
		    begin
   		  	  SVstate_H <= WT_POS_H;
			//  SVCnt_H <=21'd0;
			  SVCnt_H <=29'd0;
			end
        //  	else if(SVCnt_H > 21'd1666667)		//55.556ms = 1.001s/r = 0.999r/s = 59.9r/min = less than 59.9r/min,no count (for 6 couple poles)
          	else if(SVCnt_H > 29'd400000008)		//3.3333s = 60s/r = 0.016667r/s = 1r/min = less than 1r/min,no count (for 6 couple poles)
		    begin
			  SVstate_H <= WT_POS_H;
			  SVCnt_H <= 29'd0;
			 end
		  else 
			  SVCnt_H <= SVCnt_H + 1'b1;			
        end
        WT_POS_H:
        begin
		  if(hallwave_pn)
		    begin
		      SVstate_H <= WT_POS2_H;	
			  SVCnt_H <=29'b0;
            end				
          else if(SVCnt_H > 29'd400000008)
		    begin
		      SVstate_H <= SV_IDLE_H;	//less than 231r/min,stop pos count
			  SVCnt_H <= 29'd0;
			end
		  else
			   SVCnt_H <= SVCnt_H + 1'b1;
		end
		WT_POS2_H:
		begin
		  case(cnt_count)		//0~35loop
		  	COUNT0:
		  	begin
		  	//  count0_start_flag <= 1'b1;	//start count0;
		  	  count_start_flag[0]  <= 1'b1;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT1;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[1] == 1'b1) refresh_flag <= 6'd1; //refresh count1 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
			  	begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;			  	 	
			  	end 
		  	end
		  	COUNT1:
		  	begin
		  	  count_start_flag[1] <= 1'b1;	//start count1;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT2;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[2] == 1'b1) refresh_flag <= 6'd2; //refresh count2 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end		  	  	
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else
			  	begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;			  	 	
			  	end 
		  	end
		  	COUNT2:
		  	begin
		  	  count_start_flag[2] <= 1'b1;	//start count2;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT3;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[3] == 1'b1) refresh_flag <= 6'd3; //refresh count3 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end		  	  
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT3:
		  	begin
		  	  count_start_flag[3] <= 1'b1;	//start count3;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT4;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[4] == 1'b1) refresh_flag <= 6'd4; //refresh count4 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT4:
		  	begin
		  	  count_start_flag[4] <= 1'b1;	//start count4;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT5;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[5] == 1'b1) refresh_flag <= 6'd5; //refresh count5 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT5:
		  	begin
		  	  count_start_flag[5] <= 1'b1;	//start count5;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT6;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[6] == 1'b1) refresh_flag <= 6'd6; //refresh count6 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT6:
		  	begin
		  	  count_start_flag[6] <= 1'b1;	//start count6;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT7;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[7] == 1'b1) refresh_flag <= 6'd7; //refresh count7 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT7:
		  	begin
		  	  count_start_flag[7] <= 1'b1;	//start count7;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT8;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[8] == 1'b1) refresh_flag <= 6'd8; //refresh count8 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT8:
		  	begin
		  	  count_start_flag[8] <= 1'b1;	//start count8;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT9;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[9] == 1'b1) refresh_flag <= 6'd9; //refresh count9 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT9:
		  	begin
		  	  count_start_flag[9] <= 1'b1;	//start count9;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT10;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[10] == 1'b1) refresh_flag <= 6'd10; //refresh count10 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT10:
		  	begin
		  	  count_start_flag[10] <= 1'b1;	//start count10;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT11;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[11] == 1'b1) refresh_flag <= 6'd11; //refresh count11 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT11:
		  	begin
		  	  count_start_flag[11] <= 1'b1;	//start count11;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT12;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[12] == 1'b1) refresh_flag <= 6'd12; //refresh count12 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT12:
		  	begin
		  	  count_start_flag[12] <= 1'b1;	//start count12;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT13;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[13] == 1'b1) refresh_flag <= 6'd13; //refresh count13 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT13:
		  	begin
		  	  count_start_flag[13] <= 1'b1;	//start count13;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT14;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[14] == 1'b1) refresh_flag <= 6'd14; //refresh count14 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT14:
		  	begin
		  	  count_start_flag[14] <= 1'b1;	//start count14;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT15;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[15] == 1'b1) refresh_flag <= 6'd15; //refresh count15 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT15:
		  	begin
		  	  count_start_flag[15] <= 1'b1;	//start count15;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT16;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[16] == 1'b1) refresh_flag <= 6'd16; //refresh count16 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT16:
		  	begin
		  	  count_start_flag[16] <= 1'b1;	//start count16;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT17;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[17] == 1'b1) refresh_flag <= 6'd17; //refresh count17 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT17:
		  	begin
		  	  count_start_flag[17] <= 1'b1;	//start count17;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT18;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[18] == 1'b1) refresh_flag <= 6'd18; //refresh count18 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT18:
		  	begin
		  	  count_start_flag[18] <= 1'b1;	//start count18;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT19;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[19] == 1'b1) refresh_flag <= 6'd19; //refresh count19 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT19:
		  	begin
		  	  count_start_flag[19] <= 1'b1;	//start count19;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT20;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[20] == 1'b1) refresh_flag <= 6'd20; //refresh count20 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT20:
		  	begin
		  	  count_start_flag[20] <= 1'b1;	//start count20;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT21;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[21] == 1'b1) refresh_flag <= 6'd21; //refresh count21 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT21:
		  	begin
		  	  count_start_flag[21] <= 1'b1;	//start count21;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT22;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[22] == 1'b1) refresh_flag <= 6'd22; //refresh count22 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT22:
		  	begin
		  	  count_start_flag[22] <= 1'b1;	//start count22;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT23;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[23] == 1'b1) refresh_flag <= 6'd23; //refresh count23 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT23:
		  	begin
		  	  count_start_flag[23] <= 1'b1;	//start count23;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT24;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[24] == 1'b1) refresh_flag <= 6'd24; //refresh count24 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT24:
		  	begin
		  	  count_start_flag[24] <= 1'b1;	//start count24;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT25;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[25] == 1'b1) refresh_flag <= 6'd25; //refresh count25 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT25:
		  	begin
		  	  count_start_flag[25] <= 1'b1;	//start count25;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT26;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[26] == 1'b1) refresh_flag <= 6'd26; //refresh count26 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT26:
		  	begin
		  	  count_start_flag[26] <= 1'b1;	//start count26;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT27;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[27] == 1'b1) refresh_flag <= 6'd27; //refresh count27 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT27:
		  	begin
		  	  count_start_flag[27] <= 1'b1;	//start count17;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT28;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[28] == 1'b1) refresh_flag <= 6'd28; //refresh count28 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT28:
		  	begin
		  	  count_start_flag[28] <= 1'b1;	//start count28;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT29;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[29] == 1'b1) refresh_flag <= 6'd29; //refresh count29 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT29:
		  	begin
		  	  count_start_flag[29] <= 1'b1;	//start count29;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT30;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[30] == 1'b1) refresh_flag <= 6'd30; //refresh count30 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT30:
		  	begin
		  	  count_start_flag[30] <= 1'b1;	//start count30;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT31;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[31] == 1'b1) refresh_flag <= 6'd31; //refresh count31 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT31:
		  	begin
		  	  count_start_flag[31] <= 1'b1;	//start count31;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT32;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[32] == 1'b1) refresh_flag <= 6'd32; //refresh count32 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT32:
		  	begin
		  	  count_start_flag[32] <= 1'b1;	//start count32;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT33;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[33] == 1'b1) refresh_flag <= 6'd33; //refresh count33 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT33:
		  	begin
		  	  count_start_flag[33] <= 1'b1;	//start count33;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT34;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[34] == 1'b1) refresh_flag <= 6'd34; //refresh count34 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT34:
		  	begin
		  	  count_start_flag[34] <= 1'b1;	//start count34;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT35;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[35] == 1'b1) refresh_flag <= 6'd35; //refresh count35 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	COUNT35:
		  	begin
		  	  count_start_flag[35] <= 1'b1;	//start count35;
		  	  if(hallwave_pn)
		  	  	begin
		  	  	  cnt_count <= COUNT0;
		  	  	  SVCnt_H <= 29'd0;
		  	  	  if(count_start_flag[0] == 1'b1) refresh_flag <= 6'd0; //refresh count0 and deliver speed data for 1T	
		  	  	  else refresh_flag <= 6'd60;		//0 change to 60	
		  	  	end
		  	  else if(SVCnt_H > 29'd400000008)
		  	  	begin 
				  SVCnt_H <= 29'd0;
				  SVstate_H <= SV_IDLE_H;
				end
			  else 
				begin
			  	  SVCnt_H <= SVCnt_H + 1'b1;
			  	  refresh_flag <= 6'd60;
			  	end
		  	end
		  	default:
		  	begin
		  	  SVCnt_H <= 29'd0;
			  SVstate_H <= SV_IDLE_H;
			  refresh_flag <= 6'd60;	
		  	end
		  endcase
		end
		default:
		begin
		  SVstate_H <= SV_IDLE_H;
		  SVCnt_H <= 29'd0;			
		end
	  endcase
	end


reg[31:0] count_cnt[35:0];
reg[30:0] sv_h_cnt;		//to count time between 2 sv_h

reg [35:0] ref_flag;
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	begin
  	  sv_h <= 32'd0;
  	  ref_flag <= 36'b0;
  	  sv_h_cnt <= 31'd0;
  	  time_sv <= 31'd0;
  	end
  else 
  	begin
  	  
  	  case(refresh_flag)
  	  	6'd60:
  	  	begin
		  ref_flag <= 36'b0;  	
  	  	end
  	  	6'd0:
  	  	begin
  	  	  ref_flag[0] <= 1'b1;sv_h <= count_cnt[0];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd1:
  	  	begin
  	  	  ref_flag[1] <= 1'b1;sv_h <= count_cnt[1];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd2:
  	  	begin
  	  	  ref_flag[2] <= 1'b1;sv_h <= count_cnt[2];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd3:
  	  	begin
  	  	  ref_flag[3] <= 1'b1;sv_h <= count_cnt[3];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd4:
  	  	begin
  	  	  ref_flag[4] <= 1'b1;sv_h <= count_cnt[4];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd5:
  	  	begin
  	  	  ref_flag[5] <= 1'b1;sv_h <= count_cnt[5];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd6:
  	  	begin
  	  	  ref_flag[6] <= 1'b1;sv_h <= count_cnt[6];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd7:
  	  	begin
  	  	  ref_flag[7] <= 1'b1;sv_h <= count_cnt[7];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd8:
  	  	begin
  	  	  ref_flag[8] <= 1'b1;sv_h <= count_cnt[8];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd9:
  	  	begin
  	  	  ref_flag[9] <= 1'b1;sv_h <= count_cnt[9];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd10:
  	  	begin
  	  	  ref_flag[10] <= 1'b1;sv_h <= count_cnt[10];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd11:
  	  	begin
  	  	  ref_flag[11] <= 1'b1;sv_h <= count_cnt[11];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd12:
  	  	begin
  	  	  ref_flag[12] <= 1'b1;sv_h <= count_cnt[12];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd13:
  	  	begin
  	  	  ref_flag[13] <= 1'b1;sv_h <= count_cnt[13];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd14:
  	  	begin
  	  	  ref_flag[14] <= 1'b1;sv_h <= count_cnt[14];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd15:
  	  	begin
  	  	  ref_flag[15] <= 1'b1;sv_h <= count_cnt[15];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd16:
  	  	begin
  	  	  ref_flag[16] <= 1'b1;sv_h <= count_cnt[16];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd17:
  	  	begin
  	  	  ref_flag[17] <= 1'b1;sv_h <= count_cnt[17];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd18:
  	  	begin
  	  	  ref_flag[18] <= 1'b1;sv_h <= count_cnt[18];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd19:
  	  	begin
  	  	  ref_flag[19] <= 1'b1;sv_h <= count_cnt[19];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd20:
  	  	begin
  	  	  ref_flag[20] <= 1'b1;sv_h <= count_cnt[20];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd21:
  	  	begin
  	  	  ref_flag[21] <= 1'b1;sv_h <= count_cnt[21];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd22:
  	  	begin
  	  	  ref_flag[22] <= 1'b1;sv_h <= count_cnt[22];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd23:
  	  	begin
  	  	  ref_flag[23] <= 1'b1;sv_h <= count_cnt[23];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd24:
  	  	begin
  	  	  ref_flag[24] <= 1'b1;sv_h <= count_cnt[24];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd25:
  	  	begin
  	  	  ref_flag[25] <= 1'b1;sv_h <= count_cnt[25];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd26:
  	  	begin
  	  	  ref_flag[26] <= 1'b1;sv_h <= count_cnt[26];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd27:
  	  	begin
  	  	  ref_flag[27] <= 1'b1;sv_h <= count_cnt[27];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd28:
  	  	begin
  	  	  ref_flag[28] <= 1'b1;sv_h <= count_cnt[28];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd29:
  	  	begin
  	  	  ref_flag[29] <= 1'b1;sv_h <= count_cnt[29];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd30:
  	  	begin
  	  	  ref_flag[30] <= 1'b1;sv_h <= count_cnt[30];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd31:
  	  	begin
  	  	  ref_flag[31] <= 1'b1;sv_h <= count_cnt[31];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd32:
  	  	begin
  	  	  ref_flag[32] <= 1'b1;sv_h <= count_cnt[32];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd33:
  	  	begin
  	  	  ref_flag[33] <= 1'b1;sv_h <= count_cnt[33];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd34:
  	  	begin
  	  	  ref_flag[34] <= 1'b1;sv_h <= count_cnt[34];time_sv <= sv_h_cnt;
  	  	end
  	  	6'd35:
  	  	begin
  	  	  ref_flag[35] <= 1'b1;sv_h <= count_cnt[35];time_sv <= sv_h_cnt;
  	  	end
  	  	6'b111111:
  	  	begin
  	  	  ref_flag <= 36'b0;
	  	  sv_h <= 32'd0;
  	  	end
  	  	default:begin
  	  	  ref_flag <= 36'b0;
	  	  sv_h <= 32'd0;
  	  	end
  	  endcase
  	  sv_h_cnt <= sv_h_cnt + 1'b1;  		
  	end


always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[0] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[0] == 1'b1)
  	  	begin if(ref_flag[0] == 1'b1)   count_cnt[0] <= 32'd0;		  	  	  
  	  	  else count_cnt[0] <= count_cnt[0] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[0] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[1] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[1] == 1'b1)
  	  	begin if(ref_flag[1] == 1'b1)   count_cnt[1] <= 32'd0;		  	  	  
  	  	  else count_cnt[1] <= count_cnt[1] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[1] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[2] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[2] == 1'b1)
  	  	begin if(ref_flag[2] == 1'b1)   count_cnt[2] <= 32'd0;		  	  	  
  	  	  else count_cnt[2] <= count_cnt[2] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[2] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[3] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[3] == 1'b1)
  	  	begin if(ref_flag[3] == 1'b1)   count_cnt[3] <= 32'd0;		  	  	  
  	  	  else count_cnt[3] <= count_cnt[3] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[3] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[4] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[4] == 1'b1)
  	  	begin if(ref_flag[4] == 1'b1)   count_cnt[4] <= 32'd0;		  	  	  
  	  	  else count_cnt[4] <= count_cnt[4] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[4] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[5] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[5] == 1'b1)
  	  	begin if(ref_flag[5] == 1'b1)   count_cnt[5] <= 32'd0;		  	  	  
  	  	  else count_cnt[5] <= count_cnt[5] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[5] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[6] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[6] == 1'b1)
  	  	begin if(ref_flag[6] == 1'b1)   count_cnt[6] <= 32'd0;		  	  	  
  	  	  else count_cnt[6] <= count_cnt[6] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[6] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[7] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[7] == 1'b1)
  	  	begin if(ref_flag[7] == 1'b1)   count_cnt[7] <= 32'd0;		  	  	  
  	  	  else count_cnt[7] <= count_cnt[7] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[7] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[8] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[8] == 1'b1)
  	  	begin if(ref_flag[8] == 1'b1)   count_cnt[8] <= 32'd0;		  	  	  
  	  	  else count_cnt[8] <= count_cnt[8] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[8] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[9] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[9] == 1'b1)
  	  	begin if(ref_flag[9] == 1'b1)   count_cnt[9] <= 32'd0;		  	  	  
  	  	  else count_cnt[9] <= count_cnt[9] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[9] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[10] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[10] == 1'b1)
  	  	begin if(ref_flag[10] == 1'b1)   count_cnt[10] <= 32'd0;		  	  	  
  	  	  else count_cnt[10] <= count_cnt[10] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[10] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[11] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[11] == 1'b1)
  	  	begin if(ref_flag[11] == 1'b1)   count_cnt[11] <= 32'd0;		  	  	  
  	  	  else count_cnt[11] <= count_cnt[11] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[11] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[12] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[12] == 1'b1)
  	  	begin if(ref_flag[12] == 1'b1)   count_cnt[12] <= 32'd0;		  	  	  
  	  	  else count_cnt[12] <= count_cnt[12] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[12] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[13] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[13] == 1'b1)
  	  	begin if(ref_flag[13] == 1'b1)   count_cnt[13] <= 32'd0;		  	  	  
  	  	  else count_cnt[13] <= count_cnt[13] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[13] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[14] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[14] == 1'b1)
  	  	begin if(ref_flag[14] == 1'b1)   count_cnt[14] <= 32'd0;		  	  	  
  	  	  else count_cnt[14] <= count_cnt[14] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[14] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[15] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[15] == 1'b1)
  	  	begin if(ref_flag[15] == 1'b1)   count_cnt[15] <= 32'd0;		  	  	  
  	  	  else count_cnt[15] <= count_cnt[15] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[15] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[16] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[16] == 1'b1)
  	  	begin if(ref_flag[16] == 1'b1)   count_cnt[16] <= 32'd0;		  	  	  
  	  	  else count_cnt[16] <= count_cnt[16] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[16] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[17] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[17] == 1'b1)
  	  	begin if(ref_flag[17] == 1'b1)   count_cnt[17] <= 32'd0;		  	  	  
  	  	  else count_cnt[17] <= count_cnt[17] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[17] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[18] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[18] == 1'b1)
  	  	begin if(ref_flag[18] == 1'b1)   count_cnt[18] <= 32'd0;		  	  	  
  	  	  else count_cnt[18] <= count_cnt[18] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[18] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[19] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[19] == 1'b1)
  	  	begin if(ref_flag[19] == 1'b1)   count_cnt[19] <= 32'd0;		  	  	  
  	  	  else count_cnt[19] <= count_cnt[19] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[19] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[20] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[20] == 1'b1)
  	  	begin if(ref_flag[20] == 1'b1)   count_cnt[20] <= 32'd0;		  	  	  
  	  	  else count_cnt[20] <= count_cnt[20] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[20] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[21] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[21] == 1'b1)
  	  	begin if(ref_flag[21] == 1'b1)   count_cnt[21] <= 32'd0;		  	  	  
  	  	  else count_cnt[21] <= count_cnt[21] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[21] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[22] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[22] == 1'b1)
  	  	begin if(ref_flag[22] == 1'b1)   count_cnt[22] <= 32'd0;		  	  	  
  	  	  else count_cnt[22] <= count_cnt[22] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[22] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[23] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[23] == 1'b1)
  	  	begin if(ref_flag[23] == 1'b1)   count_cnt[23] <= 32'd0;		  	  	  
  	  	  else count_cnt[23] <= count_cnt[23] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[23] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[24] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[24] == 1'b1)
  	  	begin if(ref_flag[24] == 1'b1)   count_cnt[24] <= 32'd0;		  	  	  
  	  	  else count_cnt[24] <= count_cnt[24] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[24] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[25] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[25] == 1'b1)
  	  	begin if(ref_flag[25] == 1'b1)   count_cnt[25] <= 32'd0;		  	  	  
  	  	  else count_cnt[25] <= count_cnt[25] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[25] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[26] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[26] == 1'b1)
  	  	begin if(ref_flag[26] == 1'b1)   count_cnt[26] <= 32'd0;		  	  	  
  	  	  else count_cnt[26] <= count_cnt[26] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[26] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[27] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[27] == 1'b1)
  	  	begin if(ref_flag[27] == 1'b1)   count_cnt[27] <= 32'd0;		  	  	  
  	  	  else count_cnt[27] <= count_cnt[27] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[27] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[28] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[28] == 1'b1)
  	  	begin if(ref_flag[28] == 1'b1)   count_cnt[28] <= 32'd0;		  	  	  
  	  	  else count_cnt[28] <= count_cnt[28] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[28] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[29] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[29] == 1'b1)
  	  	begin if(ref_flag[29] == 1'b1)   count_cnt[29] <= 32'd0;		  	  	  
  	  	  else count_cnt[29] <= count_cnt[29] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[29] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[30] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[30] == 1'b1)
  	  	begin if(ref_flag[30] == 1'b1)   count_cnt[30] <= 32'd0;		  	  	  
  	  	  else count_cnt[30] <= count_cnt[30] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[30] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[31] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[31] == 1'b1)
  	  	begin if(ref_flag[31] == 1'b1)   count_cnt[31] <= 32'd0;		  	  	  
  	  	  else count_cnt[31] <= count_cnt[31] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[31] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[32] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[32] == 1'b1)
  	  	begin if(ref_flag[32] == 1'b1)   count_cnt[32] <= 32'd0;		  	  	  
  	  	  else count_cnt[32] <= count_cnt[32] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[32] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[33] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[33] == 1'b1)
  	  	begin if(ref_flag[33] == 1'b1)   count_cnt[33] <= 32'd0;		  	  	  
  	  	  else count_cnt[33] <= count_cnt[33] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[33] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[34] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[34] == 1'b1)
  	  	begin if(ref_flag[34] == 1'b1)   count_cnt[34] <= 32'd0;		  	  	  
  	  	  else count_cnt[34] <= count_cnt[34] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[34] <= 32'd0;	
	end
always @(posedge clk120 or negedge rst_n)
  if(!rst_n)
  	count_cnt[35] <= 32'd0;	  	  	
  else 
  	begin
  	  if(count_start_flag[35] == 1'b1)
  	  	begin if(ref_flag[35] == 1'b1)   count_cnt[35] <= 32'd0;		  	  	  
  	  	  else count_cnt[35] <= count_cnt[35] + 1'b1;
  	  	end
  	  else 
  	  	count_cnt[35] <= 32'd0;	
	end


endmodule
