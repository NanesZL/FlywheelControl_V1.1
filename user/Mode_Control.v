`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:50:59 07/14/2018 
// Design Name: 
// Module Name:    Mode_Control 
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
module Mode_Control(clk,rst_n,Torque_Dir,Speed_Dir,sv_h,LT1800_Flag,
    GT100_Flag,MainQ_BrakeMode,Clr_flag,Modechg_flag,ModeNH_Over_Flag);
input clk,rst_n,Torque_Dir,Speed_Dir,ModeNH_Over_Flag;
input [31:0]sv_h;
output LT1800_Flag,Clr_flag,GT100_Flag,Modechg_flag;
output reg [1:0]MainQ_BrakeMode;


//////////////////////////////////////////////////////////////////////
//////////////.............. BrakeMode..............//////////////////
//////////////////////////////////////////////////////////////////////


wire Torque_Dir;    //dsp-->this module
reg Torque_Dir_r1;
reg Torque_Dir_r2;
wire Speed_Dir;     // SM module-->this module
reg Speed_Dir_r;    // Main determination
reg ModeNH_Over_Flag_r;



always @ (posedge clk or negedge rst_n)
  if(!rst_n)
    begin
      Torque_Dir_r1  <= 1'b0;
      Torque_Dir_r2  <= 1'b0;
      Speed_Dir_r <= 1'b0;
      ModeNH_Over_Flag_r <= 1'b0;
    end
  else
    begin
      Torque_Dir_r1 <=Torque_Dir;
      Torque_Dir_r2 <=Torque_Dir_r1;
      Speed_Dir_r <=Speed_Dir;   //update SM speed dir
      ModeNH_Over_Flag_r <= ModeNH_Over_Flag;
  end

reg EQ0_Flag;
reg [27:0] EQ0_Cnt;


reg LT1800_Flag;     //Speed value is less than 1800r/s and stay more than 10ms 
reg [19:0] LT1800_Cnt;

reg LT950_Flag;     //Speed value is less than 950r/s and stay more than 10ms 
reg GT100_Flag;
    

reg [19:0] LT950_Cnt; 
reg [19:0] GT100_Cnt; 

reg LT6250_Flag;     //Speed value is less than 6250r/s and stay more than 10ms  
reg [19:0] LT6250_Cnt; 

reg GT6400_Flag;     //Speed value is greater than 6400r/s and stay more than 10ms 
reg [19:0] GT6400_Cnt; 
  
///*******for firsrt time,after 33.3ms(1000000),EQ0_Flag=1********************/// 
///*******if speed not 0, after 1s(30000000),EQ0_Flag=0********************/// 
///*******after start the motor,EQ0_Flag will normally be 0*******************/// 
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
    begin
    EQ0_Cnt  <= 28'd29000000;   
    end
    else if(sv_h == 32'd0) 
    begin 
    if(EQ0_Cnt < 28'd30000000)
        EQ0_Cnt <= EQ0_Cnt + 1'b1;
    else  EQ0_Cnt <= 28'd30000000; 
  end
  else
    begin 
    if(EQ0_Cnt >= 28'd1)
        EQ0_Cnt <= EQ0_Cnt - 1'b1;
    else  EQ0_Cnt <= 28'd0; 
  end
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
   begin
    EQ0_Flag  <= 1'b0;
   end
 else if(EQ0_Cnt >= 28'd30000000)
    EQ0_Flag  <= 1'b1;
 else if(EQ0_Cnt <= 28'd100)
    EQ0_Flag  <= 1'b0;  


    
//////////////////////////////////////////////////////////////////////
//////////////.......... Speed determination .........////////////////
//////////////.......... 300000=10ms .........////////////////
///////if 6pole, r*j=f*10/3 if 10pole ,r*j=f*2(j=speed_value,f=fclock) /////////
  
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
  LT1800_Cnt  <= 20'b0;
  else if(sv_h == 32'd0)   
    begin
    if(LT1800_Cnt < 20'd310000)
      LT1800_Cnt <= LT1800_Cnt + 1'b1;
    else
      LT1800_Cnt <= 20'd310000;
  end 
  else if(sv_h < 32'd4000000)  ///if speed>1800, LT1800_Flag=0***6pole
  LT1800_Cnt <= 0 ;
  else
    begin
      if(LT1800_Cnt < 20'd310000)  ///if 0<speed<2200, after 10ms, LT1800_Flag=1
      LT1800_Cnt <= LT1800_Cnt + 1'b1;
    else
      LT1800_Cnt <= 20'd310000;
    end 
   
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
  LT1800_Flag  <= 1'b0;
  else if(LT1800_Cnt > 20'd300000)
  LT1800_Flag <= 1'b1 ;
  else   
  LT1800_Flag <= 1'b0 ;  
   
//////////////////////////////////////////////////////////////
  
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
  LT950_Cnt  <= 20'b0;
  else if(sv_h == 32'd0) 
    begin
    if(LT950_Cnt < 20'd310000)
      LT950_Cnt <= LT950_Cnt + 1'b1;
    else
      LT950_Cnt <= 20'd310000;
    end 
//  else if(sv_h < 32'd9600000)  ///if speed>750, LT950_Flag=0***6pole
  else if(sv_h < 32'd7200000)  ///if speed>1000, LT950_Flag=0***6pole
    begin
    LT950_Cnt <= 0 ;
  end
  else
    begin
      if(LT950_Cnt < 20'd310000)     ///if 0<speed<900, after 10ms, LT950_Flag=1
      LT950_Cnt <= LT950_Cnt + 1'b1;
    else
      LT950_Cnt <= 20'd310000;
    end 

     
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
  LT950_Flag  <= 1'b0;
 else if(LT950_Cnt > 20'd300000 )
    LT950_Flag <= 1'b1 ;
 else    
    LT950_Flag <= 1'b0 ;  


 /**********************************************************/ 
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
  GT100_Cnt  <= 20'b0;
  else if(sv_h == 32'd0) 
  GT100_Cnt <= 0; 
  else if(sv_h < 32'd72000000)   //100rpm***6pole
    begin
    if(GT100_Cnt < 20'd310000)
      GT100_Cnt <= GT100_Cnt + 1'b1 ;
    else
      GT100_Cnt <= 20'd310000 ;
  end
  else
  GT100_Cnt <= 0;
  

always @ (posedge clk or negedge rst_n)
  if(!rst_n)
  GT100_Flag  <= 1'b0;
  else if(GT100_Cnt > 20'd300000 )   //10ms
  GT100_Flag <= 1'b1 ;
  else   
  GT100_Flag <= 1'b0 ; 
   
   
/**********************************************************/   
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
  LT6250_Cnt  <= 20'b0;
  else if(sv_h == 32'd0) 
    begin
    if(LT6250_Cnt < 20'd310000)
      LT6250_Cnt <= LT6250_Cnt + 1'b1;
    else
      LT6250_Cnt <= 20'd310000;
  end 
  else if(sv_h < 32'd1152000)   ///if speed>6250, LT6250_Flag=0***6pole
  LT6250_Cnt <= 0 ;
  else
    begin
      if(LT6250_Cnt < 20'd310000)    ///if 0<speed<6250, after 10ms, LT6250_Flag=1
      LT6250_Cnt <= LT6250_Cnt + 1'b1;
    else
      LT6250_Cnt <= 20'd310000;
    end 


   
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
  LT6250_Flag  <= 1'b0;
  else if(LT6250_Cnt > 20'd300000)
    LT6250_Flag <= 1'b1 ;
  else   
    LT6250_Flag <= 1'b0 ;  
   
/**********************************************************/   
   
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
  GT6400_Cnt  <= 20'b0;
  else if(sv_h == 32'd0) 
  GT6400_Cnt <=0 ;
  else if(sv_h < 32'd1125000)   //if speed > 6400rpm,after 10ms, GT6400_Flag = 1***6pole
  begin
    if(GT6400_Cnt < 20'd310000)    
    GT6400_Cnt <= GT6400_Cnt + 1'b1 ;
    else
      GT6400_Cnt <= 20'd310000;
  end
  else                            ///if 0<speed<6400, GT6400_Flag = 0
  GT6400_Cnt <= 0;

always @ (posedge clk or negedge rst_n)
  if(!rst_n)
    GT6400_Flag  <= 1'b0;
  else if(GT6400_Cnt > 20'd300000)
    GT6400_Flag <= 1'b1 ;
  else   
    GT6400_Flag <= 1'b0 ;
      
/************************anquan mode***********************/     
reg anquan_Flag;
reg [1:0] anquan_state;

always @ (posedge clk or negedge rst_n)
  if(!rst_n)
    begin
      anquan_Flag  <= 1'b0;
    anquan_state <=2'b00;
    end
  else
    case(anquan_state)
    2'b00:
      begin
      anquan_Flag  <= 1'b0;
      if(GT6400_Flag)
        anquan_state <=2'b01;
      else
         anquan_state <=2'b00;  
    end
    2'b01:
      begin
    anquan_Flag  <= 1'b1;
      if(LT6250_Flag)
        anquan_state <=2'b10;
      else
          anquan_state <=2'b01; 
    end
    2'b10:    
      begin
    anquan_Flag  <= 1'b0;
    anquan_state <=2'b00;
    end
   
  default: 
      begin
    anquan_Flag  <= 1'b0;
    anquan_state <=2'b00;
    end
    endcase
/**********************************************************/  
reg [1:0] BrakeMode;

always @ (posedge clk or negedge rst_n)
  if(!rst_n)
    BrakeMode <= 2'b00;
  else 
    begin
      if(Torque_Dir_r2 == Speed_Dir_r)
        begin
          if(anquan_Flag==0)
            BrakeMode <= 2'b00;   //qudong
          else 
            BrakeMode <= 2'b11;   //anquan
        end
      else begin
        if(BrakeMode == 2'b01)    //once fanjie,always fanjie
          BrakeMode <= 2'b01;   //fanjie
        else 
          begin
            if(ModeNH_Over_Flag_r == 1'b0)
              BrakeMode <= 2'b10;   //nenghao
            else if(LT950_Flag == 1'b1)
              BrakeMode <= 2'b01;   //fanjie
            else 
              BrakeMode <= 2'b10;   //nenghao
          end
      end
    end



/********************************************************************/

reg [1:0] BrakeMode_r1,BrakeMode_r2;
reg LT1800_Flag_r1,LT1800_Flag_r2;
reg Modechg_flag;
reg [1:0] Clrpulse_state;
reg Clr_flag;
reg [1:0] Clrpulse_cnt;

parameter CP_IDLE = 2'b00, CP_A = 2'b01, CP_B = 2'b10;

always @ (posedge clk or negedge rst_n)
  if(!rst_n)
    begin
    BrakeMode_r1 <=2'b0;
    BrakeMode_r2 <=2'b0;
    LT1800_Flag_r1 <=1'b0;
    LT1800_Flag_r2 <=1'b0;
  end
  else
    begin 
      BrakeMode_r1 <= BrakeMode;
    BrakeMode_r2 <= BrakeMode_r1;
    LT1800_Flag_r1 <= LT1800_Flag;
    LT1800_Flag_r2 <= LT1800_Flag_r1;
  end 
  
always @ (posedge clk or negedge rst_n)
  if(!rst_n)
    begin
    MainQ_BrakeMode <= 2'b11;
  end
  else 
    begin
      if(EQ0_Flag == 1'b1)
        MainQ_BrakeMode <= 2'b00;
      else 
        MainQ_BrakeMode <= BrakeMode;
    end

//////////////////////////////////////////////////
//////////////////////////////////////////////////


always @ (posedge clk or negedge rst_n)
  if(!rst_n)
    begin
    Modechg_flag <=1'b0;
  end
  else 
    begin  
      if(BrakeMode_r2 != BrakeMode)
        Modechg_flag <=1'b1;
      else if((BrakeMode ==2'b10)&&(LT1800_Flag_r2 != LT1800_Flag))
        Modechg_flag <=1'b1;
      else 
        Modechg_flag <=1'b0;
    end  

always @ (posedge clk or negedge rst_n)
  if(!rst_n)
    begin
      Clr_flag <=0;
      Clrpulse_state <= CP_IDLE;
      Clrpulse_cnt <= 2'b0;
    end
  else 
  case(Clrpulse_state)
    CP_IDLE:
      begin
        Clr_flag <=0;
      Clrpulse_cnt <= 2'b0;
      if(Modechg_flag)
        Clrpulse_state <= CP_A;
      else
          Clrpulse_state <= CP_IDLE;
      end
  
    CP_A: 
      begin  
      Clr_flag <= 1; 
      if(Clrpulse_cnt > 2'b10) 
        Clrpulse_state <= CP_B;
      else
        begin
          Clrpulse_state <= CP_A; 
          Clrpulse_cnt <= Clrpulse_cnt + 1'b1;
        end  
      end
    
    CP_B: 
      begin
        Clr_flag <= 0;  
        Clrpulse_cnt <= 2'b0;
        Clrpulse_state <= CP_IDLE; 
      end    

    default:
      begin
        Clr_flag <= 0;  
        Clrpulse_cnt <= 2'b0;
        Clrpulse_state <= CP_IDLE; 
      end      
  endcase   


endmodule
