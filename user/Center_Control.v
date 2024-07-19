`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:53:57 07/14/2018 
// Design Name: 
// Module Name:    Center_Control 
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
module Center_Control(
	clk,rst_n,Modechg_flag,BrakeMode,LT1800_Flag,start_flag,
	AD_Current,AD_Torque,torque_flag,ctrl_data,Clr_flag,ModeNH_Over_Flag,Insert_Data);
	
	input clk,rst_n,Modechg_flag,start_flag,Clr_flag;
	input LT1800_Flag;
	input [1:0] BrakeMode;
	input [11:0]AD_Current,AD_Torque;	
	output reg torque_flag;	//start flag(0--stop;1--start control)
	output [11:0]ctrl_data;
	output ModeNH_Over_Flag;	// in nenghao mode ,if pwm > 4090 and last for 2 times ,over_flag = 1	
	input  [11:0]Insert_Data;

/*************************** PID&operate flag**************************/
wire PID_end;
reg PID_end_r,start_flag_r;
always @(posedge clk or negedge rst_n)
 if(!rst_n) 
   begin
   	PID_end_r <= 0;
   	start_flag_r <= 0;
   end
 else
   begin 
   	PID_end_r <= PID_end;
   	start_flag_r <= start_flag;
   end

/**********************MainCnt&MainGo*************************/
/*************to determine control period*************************/

//reg [11:0] Main_Cnt;
reg [8:0] Main_Cnt;		// cycle time cnt,17us
reg MainGo,MainGo1,MainGo2;
wire MainGo_Pos;
			 			 					 
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
  	Main_Cnt <= 9'd0;
  else if(Main_Cnt >= 9'd210)		//210/30M=7uS
  	Main_Cnt <= 9'd0;
  else 
	Main_Cnt <= Main_Cnt + 1'b1;	
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
  	MainGo <= 1'b0;
  else if(Main_Cnt<9'd105)	
	MainGo <= 1'b1;
  else MainGo <= 1'b0; 	
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
   	begin
  	  MainGo1 <= 0 ;
	  MainGo2 <= 0;
	end
  else
	begin
      MainGo1 <= MainGo;
	  MainGo2 <= MainGo1;
	end

assign MainGo_Pos =  ~MainGo2&MainGo1;

/********************** PID Value *************************/
/*************to determine PID Value*************************/
reg[9:0]M2P_a0;
reg[9:0]M2P_a1;
//reg[9:0]M2P_a2;		//M2P_a2 ===== 0 
reg[2:0] PIDCtr_state;
reg[19:0] PIDCtr_Cnt;
//reg chg2fanjie_flag;
parameter PIDCTR_IDLE = 3'b0, PIDCTR_A = 3'b001, PIDCTR_B= 3'b010, PIDCTR_C = 3'b011,
          PIDCTR_D = 3'b100;
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
    begin
	  PIDCtr_state <= PIDCTR_IDLE;
	  PIDCtr_Cnt <=20'b0;
//	  M2P_a0 <=10'd62;
//	  M2P_a1 <=10'd50;
//	  M2P_a2 <=10'd0;
	  M2P_a0 <=10'd124;
	  M2P_a1 <=10'd100;
//	  M2P_a2 <=10'd0;
//	  chg2fanjie_flag <= 1'b0;
	 end
  else 
  	case(PIDCtr_state)
  	PIDCTR_IDLE:
    begin
	  PIDCtr_Cnt <=20'b0;
      if(Modechg_flag)
	  	PIDCtr_state <= PIDCTR_A;
	  else 
	  	PIDCtr_state <= PIDCTR_IDLE;
   	end	
 	PIDCTR_A:
    begin
	  if(BrakeMode==2'b00)		//Mode_qudong
      begin
//		M2P_a0 <=10'd62;
//	   	M2P_a1 <=10'd50;
//	   	M2P_a2 <=10'd0;
		M2P_a0 <=10'd124;
	   	M2P_a1 <=10'd100;
//	   	M2P_a2 <=10'd0;
	  end
    else if(BrakeMode==2'b01)	//Mode_fanjie
      begin
//		M2P_a0 <=10'd90;
//		M2P_a1 <=10'd80;
//		M2P_a2 <=10'd0;
		M2P_a0 <=10'd360;
		M2P_a1 <=10'd320;
//		M2P_a2 <=10'd0;
//		chg2fanjie_flag <= 1'b1;
      end	  
    else if(BrakeMode==2'b10)	//Mode_nenghao
      begin 
//		M2P_a0 <=10'd64;	
//		M2P_a1 <=10'd32;	
//		M2P_a2 <=10'd0;	 
		M2P_a0 <=10'd128;	
		M2P_a1 <=10'd64;	
//		M2P_a2 <=10'd0;	 	   	
	  end
    else if(BrakeMode==2'b11)	//Mode_anquan
      begin
//		M2P_a0 <=10'd2;
//		M2P_a1 <=10'd1;
//		M2P_a2 <=10'd0;
		M2P_a0 <=10'd2;
		M2P_a1 <=10'd1;
//		M2P_a2 <=10'd0;
	  end     
	  if(PIDCtr_Cnt > 20'd500000)	//16.7ms
	    begin
	      PIDCtr_state <= PIDCTR_B;
		  PIDCtr_Cnt <= 20'd0;
//		  chg2fanjie_flag <= 1'b0;
		end
	  else
	    begin
    	  PIDCtr_state <= PIDCTR_A;  
		  PIDCtr_Cnt <= PIDCtr_Cnt + 1'b1; 
		end
    end 
	 
 	PIDCTR_B:
   	begin
   	  if(BrakeMode==2'b00)		//Mode_qudong
      	begin
//	  	  M2P_a0 <=10'd62;
//	 	  M2P_a1 <=10'd50;
//	  	  M2P_a2 <=10'd0;
	  	  M2P_a0 <=10'd124;
	 	  M2P_a1 <=10'd100;
//	  	  M2P_a2 <=10'd0;
	 	end
   	  else if(BrakeMode==2'b01)	//Mode_fanjie
      	begin
//	  	  M2P_a0 <=10'd90;
//	  	  M2P_a1 <=10'd80;
//	  	  M2P_a2 <=10'd0;
	  	  M2P_a0 <=10'd360;
	  	  M2P_a1 <=10'd320;
//	  	  M2P_a2 <=10'd0;
      	end	  
     else if(BrakeMode==2'b10)	//Mode_nenghao
      	begin 
//	  	  M2P_a0 <=10'd64;			
//	  	  M2P_a1 <=10'd32;			
//	  	  M2P_a2 <=10'd0;
	  	  M2P_a0 <=10'd128;			
	  	  M2P_a1 <=10'd64;			
//	  	  M2P_a2 <=10'd0;			
	 	end
     else if(BrakeMode==2'b11)	//Mode_anquan
      	begin
//	  	  M2P_a0 <=10'd2;
//	  	  M2P_a1 <=10'd1;
//	  	  M2P_a2 <=10'd0;
	  	  M2P_a0 <=10'd2;
	  	  M2P_a1 <=10'd1;
//	  	  M2P_a2 <=10'd0;
	  	end 
		  PIDCtr_state <= PIDCTR_IDLE;
  	end
  
 	default:  PIDCtr_state <= PIDCTR_IDLE;
 
 	endcase





///////////////////////////////////////////////////////////////////////
//////////////...............MainCtrl..............////////////////////
///////////////////////////////////////////////////////////////////////	
reg [11:0]AD_Current_r;
reg [11:0]AD_Torque_r; 
//wire [27:0] PIDOut_data;
wire [13:0] PIDOut_data;		//[13:0] ==== [27:14]
reg [11:0] PwmCrtl_data_temp;
reg [11:0] PwmCrtl_data;
reg PID_start;
reg [10:0] Wait_cnt1;	//watch dog
reg [11:0] OF_cnt;		//Over_Flag_cnt
reg Over_Flag;


reg [2:0] Main_State;
parameter Main_IDLE = 3'd0, WT_ST = 3'd1, ST_PID = 3'd2,
          ST_PID_2=3'd3,WT_PID = 3'd4, END1 = 3'd5,END2 = 3'd6;
//parameter PIDSFTNUM = 5'd14;

always @ (posedge clk or negedge rst_n)
  if(!rst_n)
    begin
	  Main_State <= 3'b0;
	  PID_start <=0;
	  Wait_cnt1 <=0;
	  OF_cnt <= 12'b0;
	  PwmCrtl_data_temp<=0;
	  PwmCrtl_data <= 0;
      AD_Current_r <= 0;
	  AD_Torque_r <=0;
      torque_flag <= 1'b0;
      Over_Flag <= 1'b0;
	end
  else
  	case(Main_State)
  	Main_IDLE:
      begin  
		PID_start <=0;
		Wait_cnt1 <=0;
		if(MainGo_Pos)
    	  Main_State <= WT_ST;
		else Main_State <= Main_IDLE; 
	  end
  	WT_ST:
      begin
     	if(start_flag_r)
		  Main_State <= ST_PID;
		else 
		  Main_State <= WT_ST;
      end  
  	ST_PID:
      begin
//      	if(BrakeMode==2'b01) 
//   			AD_Current_r <= {AD_Current[10:0],1'b0};
//    	else
    	AD_Current_r <= AD_Current;
		torque_flag <=1'b1;
		Main_State <= ST_PID_2;  
		AD_Torque_r <= AD_Torque;   
//      	if(BrakeMode==2'b01) AD_Torque_r <= {1'b0,AD_Torque[11:1]};
//      	if(BrakeMode==2'b01) AD_Torque_r <= {2'b0,AD_Torque[11:2]};(too small)
//      	if(BrakeMode==2'b01) AD_Torque_r <= {1'b0,AD_Torque[11:1]} + {2'b0,AD_Torque[11:2]};
//      	else AD_Torque_r <= AD_Torque;
  	  end
  	ST_PID_2:
      begin
		PID_start <= 1'b1 ;
		Main_State <= WT_PID;
	  end
	WT_PID:	  
	  begin
	    if(PID_end_r) 
		  begin 
		  	PID_start <= 1'b0;	//clear PID_start flag after reveive PID_end	
			Wait_cnt1 <= 0;
			Main_State <= END1;
          end				
		else 
		  begin
			Wait_cnt1 <= Wait_cnt1 + 1'b1;
		 	if(Wait_cnt1 > 12'd4090)
			  Main_State <= Main_IDLE;
		    else  Main_State <= WT_PID;
		  end
	  end			  
	END1:
      begin	
//        if(PIDOut_data[27]==0)
          if(PIDOut_data[13]==0)		//[13:0] ==== [27:14]
          begin
//			PwmCrtl_data_temp <= PIDOut_data[PIDSFTNUM+11:PIDSFTNUM];
//			PwmCrtl_data_temp <= PIDOut_data[25:14];
			PwmCrtl_data_temp <= PIDOut_data[11:0];
			Main_State <= END2;
		  end
		else
		  begin
         	PwmCrtl_data_temp <= 0;
		   	Main_State <= END2;		  
		  end
		end
		
   	END2:
	  begin
	  	Main_State <= Main_IDLE;
        if(PwmCrtl_data_temp > 12'd4090)
		  begin
		  	PwmCrtl_data <= 12'd4090; 
		  	if(OF_cnt >= 12'd3)   
		  	  begin
		  	  	OF_cnt <= 12'd3;
		  	  	Over_Flag <= 1'b1;
		  	  end
		  	else
		  	  begin
		  	  	OF_cnt <= OF_cnt + 1'b1;
		  	   	Over_Flag <= 1'b0;
		  	  end 		  	  
		  end
      	else
      	  begin
      	  	PwmCrtl_data <= PwmCrtl_data_temp;
      	  	Over_Flag <= 1'b0;
      	  	OF_cnt <= 12'b0;		
      	  end      	  
      end

   	default: 
	  begin
		Main_State <= Main_IDLE;
	  end
  endcase


reg [11:0] PID_insdata;
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
    begin
      PID_insdata <= 12'b0;
    end
  else 
  	begin
  	  if((BrakeMode == 2'b10)&&(LT1800_Flag == 1'b1))	//1-nenghao to 2-nenghao 
  	  	PID_insdata <= {2'b0,PwmCrtl_data[11:2]} + {3'b0,PwmCrtl_data[11:3]} + {6'b0,PwmCrtl_data[11:6]};
  	  else if(BrakeMode == 2'b01) 
  	  	PID_insdata <= Insert_Data;
  	  else 
  	  	PID_insdata <= 12'b0;  		
  	end


wire [11:0]MainPID_rt;
wire [11:0]MainPID_yt;

assign ModeNH_Over_Flag = ((BrakeMode == 2'b10)&&(Over_Flag == 1'b1))?1:0;
assign ctrl_data = PwmCrtl_data;
assign MainPID_yt = AD_Current_r;
assign MainPID_rt = AD_Torque_r;

PID PID_0(
	.clk(clk),
	.rst_n(rst_n),
	.PID_a0(M2P_a0),
	.PID_a1(M2P_a1),
//	.PID_a2(M2P_a2),
	.PID_a2(10'd0),
	.PID_rt(MainPID_rt),
	.PID_yt(MainPID_yt),
	.PID_clr(Clr_flag),
	.PID_start(PID_start),
	.PID_end(PID_end),
	.PID_out(PIDOut_data),
	.PID_insdata(PID_insdata)
    );

endmodule
