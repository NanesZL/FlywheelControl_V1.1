`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:19:11 07/14/2018 
// Design Name: 
// Module Name:    Q_Control 
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
module Q_Control(
  clk,
  rst_n, 
  Hall_a,
  Hall_b,
  Hall_c,
  Torque_Dir, 
  Q1,
  Q2,
  Q3,
  Q4,
  Q5,
  Q6,
  Q7,
  Q8,
  Q9,
  GT100_Flag,
  LT1800_Flag,
  BrakeM,
  OE,
  ctrl_data,
  AD_Con   
    );
input clk,rst_n;
input Hall_a,Hall_b,Hall_c;
input Torque_Dir;
input OE;
input LT1800_Flag;
input GT100_Flag;
input [11:0] ctrl_data;

reg pwm_reg2;
reg pwm_reg5;

output reg AD_Con;  //to start an ad convert cycle for module AD
output reg Q1,Q2,Q3,Q4,Q5,Q6;             
output reg Q7,Q8,Q9;
input [1:0] BrakeM;  

//---------------------------------------------------------------------
//?????????         ??Speed_Dir==0??  not confirmed
//         s1 s2 s3 s4 s5 s6
//---------------------------------------------------------------------
//Hall_a   1  1  1  0  0  0
//Hall_b   0  0  1  1  1  0
//Hall_c   1  0  0  0  1  1
//---------------------------------------------------------------------
//Q6;      0  1  1  0  0  0
//Q5;      0  0  0  0  1  1
//Q4;      1  0  0  0  0  1
//Q3;      0  0  1  1  0  0
//Q2;      0  0  0  1  1  0
//Q1;      1  1  0  0  0  0
//----------------------------------------------------------------------

//--------------------------------------------------------------------
// ????????       ??Speed_Dir==1??  not confirmed
//         s1 s2 s3 s4 s5 s6
//---------------------------------------------------------------------
//Hall_a   1  1  1  0  0  0
//Hall_b   0  0  1  1  1  0
//Hall_c   1  0  0  0  1  1
//---------------------------------------------------------------------
//Q6;      0  0  0  0  1  1
//Q5;      0  1  1  0  0  0
//Q4;      0  0  1  1  0  0
//Q3;      1  0  0  0  0  1
//Q2;      1  1  0  0  0  0
//Q1;      0  0  0  1  1  0
//----------------------------------------------------------------------


reg [2:0] HallReg;
reg [1:0] BrakeMode;
reg out_en;
wire [1:0] BrakeM; 
wire LT1800_Flag;

//reg [10:0] ctrl_reg2;
reg [10:0] ctrl_reg5;
reg [9:0] ctrl_reg_buck;      //29.25k
reg ctrl_reg2;

always @(posedge clk or negedge rst_n)
  if(!rst_n)
    begin
    HallReg <=0;
    BrakeMode <=2'b00;
    out_en <= 1'b0;
    ctrl_reg2 <= 1'b0;
    ctrl_reg_buck <= 10'd0;    
  end
  else
    begin
    HallReg<={Hall_c,Hall_b,Hall_a};
    BrakeMode <= BrakeM;
    out_en <= OE;         // 0 - stop control cycle,1- start control cycle
//    ctrl_reg2 <= ctrl_data[11:1];
    ctrl_reg2 <= ctrl_data[1];      //{ctrl_reg_buck,ctrl_reg2}  =====   ctrl_data[11:1]
    ctrl_reg_buck <= ctrl_data[11:2];
    end
 
 

reg pwm_reg_buck;

reg [10:0] cnt2;
//reg [10:0] cnt5;    //cnt5 ===== cnt2
reg [9:0] cnt_buck;
reg [13:0] ctrl_reg5cnt;

always@(posedge clk or negedge rst_n)
  if(!rst_n)
    begin
      ctrl_reg5 <= 11'd0;  
      ctrl_reg5cnt <= 14'd0;
    end
  else 
    begin
      if(GT100_Flag == 1'b0)        // speed < 100rpm
        begin
          ctrl_reg5 <= {ctrl_reg_buck,ctrl_reg2} ;  //ctrl_data[11:1]
          ctrl_reg5cnt <= 14'd0;
        end
      else
        begin     
          if(ctrl_reg5 >= 11'd2046)  //slow start for once,then always full pwm
            begin
              ctrl_reg5 <= 11'd2046;
            end
          else if(ctrl_reg5cnt == 14'd16383)      //546us
            begin
              if(ctrl_reg5 < 11'd2046)
                ctrl_reg5 <=  ctrl_reg5 + 1'b1;
              else
                ctrl_reg5 <=  11'd2046;
              ctrl_reg5cnt <= 14'd0 ;
            end
          else 
            ctrl_reg5cnt <=  ctrl_reg5cnt + 1'b1;
        end
    end   

  
always@(posedge clk or negedge rst_n)
  if(!rst_n)
    pwm_reg2 <=  1'b0;
  else 
    begin
      if(cnt2 < {ctrl_reg_buck,ctrl_reg2} )    //ctrl_data[11:1]
        pwm_reg2 <= 1'b1;
      else pwm_reg2 <= 1'b0;
    end


always@(posedge clk or negedge rst_n)
  if(!rst_n)
   begin
    pwm_reg5 <=  1'b0;
   end
  else 
   begin
    if(ctrl_reg5 == 11'd2046)
      pwm_reg5 <= 1'b1;
//    else if(cnt5 < ctrl_reg5)   //cnt5 ===== cnt2
     else if(cnt2 < ctrl_reg5)   //cnt5 ===== cnt2
     pwm_reg5 <= 1'b1;
    else pwm_reg5 <= 1'b0;
   end

always@(posedge clk or negedge rst_n)
  if(!rst_n)
   begin
    pwm_reg_buck <=  1'b0;
   end
  else 
   begin
    if(cnt_buck < ctrl_reg_buck) 
      pwm_reg_buck <= 1'b1;
    else pwm_reg_buck <= 1'b0;
   end
  
always @(posedge clk or negedge rst_n)
  if(!rst_n) 
    begin
      cnt2 <= 11'b0;
//      cnt5 <= 11'b0;
      cnt_buck <= 10'b0;   
   end 
  else 
    begin
      cnt2 <= cnt2 + 1'b1;
//      cnt5 <= cnt5 + 1'b1;
      cnt_buck <= cnt_buck + 1'b1;
  end
 

always @(posedge clk or negedge rst_n)
  if(!rst_n) 
    begin
      AD_Con <= 1'b0;
    end
//  else if(cnt2 == {1'b0,ctrl_reg2[10:1]}) //if cycle start and cnt == ctrl_reg2/2,AD_Con = 1 and start an ad operation
    else if(cnt2 == {1'b0,ctrl_reg_buck}) //if cycle start and cnt == ctrl_reg2/2,AD_Con = 1 and start an ad operation

      AD_Con <= 1'b1;
    else
      AD_Con <= 1'b0;
 

  

//------------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
 if(!rst_n)
   begin
    Q6<=1'b0; Q5<=1'b0; Q4<=1'b0; Q3<=1'b0; Q2<=1'b0; Q1 <= 1'b0;
    Q7<=1'b0; Q8<=1'b0; Q9 <= 1'b0;
   end
 else
  begin
  if(out_en == 1'b0) 
      begin
        Q6<=1'b0; Q5<=1'b0; Q4<=1'b0; Q3<=1'b0; Q2<=1'b0; Q1 <= 1'b0;
        Q7<=1'b0; Q8<=1'b0; Q9 <= 1'b0;
      end
  else
  begin
    case(BrakeMode)
    2'b00:    
    begin  
//    Q7 <= pwm_reg_buck;
    Q8 <= 1'b0;
    Q9 <= 1'b0;  
    if(Torque_Dir==1)                                                                                                
      case(HallReg)            
      3'b101:begin Q6<=1'b0; Q5<=1'b0; Q4<=pwm_reg5; Q3<=1'b0; Q2<=1'b0; Q1 <=pwm_reg5;Q7 <= pwm_reg_buck;end
      3'b001:begin Q6<=pwm_reg5; Q5<=1'b0; Q4<=1'b0; Q3<=1'b0; Q2<=1'b0; Q1 <=pwm_reg5;Q7 <= pwm_reg_buck;end
      3'b011:begin Q6<=pwm_reg5; Q5<=1'b0; Q4<=1'b0; Q3<=pwm_reg5; Q2<=1'b0; Q1 <=1'b0;Q7 <= pwm_reg_buck;end
      3'b010:begin Q6<=1'b0; Q5<=1'b0; Q4<=1'b0; Q3<=pwm_reg5; Q2<=pwm_reg5; Q1 <=1'b0;Q7 <= pwm_reg_buck;end
      3'b110:begin Q6<=1'b0; Q5<=pwm_reg5; Q4<=1'b0; Q3<=1'b0; Q2<=pwm_reg5; Q1 <=1'b0;Q7 <= pwm_reg_buck;end
      3'b100:begin Q6<=1'b0; Q5<=pwm_reg5; Q4<=pwm_reg5; Q3<=1'b0; Q2<=1'b0; Q1 <=1'b0;Q7 <= pwm_reg_buck;end
      default:begin Q6<=1'b0; Q5<=1'b0; Q4<=1'b0; Q3<=1'b0; Q2<=1'b0; Q1 <=1'b0;Q7 <= 1'b0;end
      endcase
    else                            //******SpeedDir==1 
      case(HallReg)                
      3'b101: begin Q6<=1'b0; Q5<=1'b0; Q4<=1'b0; Q3<=pwm_reg5; Q2<=pwm_reg5; Q1<= 1'b0;Q7 <= pwm_reg_buck;end
      3'b001: begin Q6<=1'b0; Q5<=pwm_reg5; Q4<=1'b0; Q3<=1'b0; Q2<=pwm_reg5; Q1<= 1'b0;Q7 <= pwm_reg_buck;end
      3'b011: begin Q6<=1'b0; Q5<=pwm_reg5; Q4<=pwm_reg5; Q3<=1'b0; Q2<=1'b0; Q1<= 1'b0;Q7 <= pwm_reg_buck;end
      3'b010: begin Q6<=1'b0; Q5<=1'b0; Q4<=pwm_reg5; Q3<=1'b0; Q2<=1'b0; Q1<= pwm_reg5;Q7 <= pwm_reg_buck;end
      3'b110: begin Q6<=pwm_reg5; Q5<=1'b0; Q4<=1'b0; Q3<=1'b0; Q2<=1'b0; Q1<= pwm_reg5;Q7 <= pwm_reg_buck;end
      3'b100: begin Q6<=pwm_reg5; Q5<=1'b0; Q4<=1'b0; Q3<=pwm_reg5; Q2<=1'b0; Q1<= 1'b0;Q7 <= pwm_reg_buck;end
      default: begin Q6<=1'b0; Q5<=1'b0; Q4<=1'b0; Q3<=1'b0; Q2<=1'b0; Q1<= 1'b0;Q7 <= 1'b0;end      
      endcase
    end    
  2'b01:
   begin 
   Q7 <= pwm_reg_buck;  
   Q8 <= 1'b0;
   Q9 <= 1'b0;   
   if(Torque_Dir==1)                   //SpeedDir==0
    begin
      case(HallReg)
      3'b101: begin Q6<=1'b0; Q5<=1'b0; Q4<=pwm_reg2; Q3<=1'b0; Q2<=1'b0; Q1 <=pwm_reg2;  end
      3'b001: begin Q6<=pwm_reg2; Q5<=1'b0; Q4<=1'b0; Q3<=1'b0; Q2<=1'b0; Q1 <=pwm_reg2;  end
      3'b011: begin Q6<=pwm_reg2; Q5<=1'b0; Q4<=1'b0; Q3<=pwm_reg2; Q2<=1'b0; Q1 <= 1'b0; end
      3'b010: begin Q6<=1'b0; Q5<=1'b0; Q4<=1'b0; Q3<=pwm_reg2; Q2<=pwm_reg2; Q1 <= 1'b0; end
      3'b110: begin Q6<=1'b0; Q5<=pwm_reg2; Q4<=1'b0; Q3<=1'b0; Q2<=pwm_reg2; Q1 <= 1'b0; end
      3'b100: begin Q6<=1'b0; Q5<=pwm_reg2; Q4<=pwm_reg2; Q3<=1'b0; Q2<=1'b0; Q1 <= 1'b0; end
      default:begin Q6<=1'b0; Q5<=1'b0; Q4<=1'b0; Q3<=1'b0; Q2<=1'b0; Q1 <= 1'b0; end  
      endcase
    end   
   else                            //******SpeedDir==1 
    begin
     case(HallReg)
     3'b101: begin Q6<=1'b0; Q5<=1'b0; Q4<=1'b0; Q3<=pwm_reg2; Q2<=pwm_reg2; Q1 <= 1'b0;  end
     3'b001: begin Q6<=1'b0; Q5<=pwm_reg2; Q4<=1'b0; Q3<=1'b0; Q2<=pwm_reg2; Q1 <= 1'b0;  end
     3'b011: begin Q6<=1'b0; Q5<=pwm_reg2; Q4<=pwm_reg2; Q3<=1'b0; Q2<=1'b0; Q1 <= 1'b0;  end
     3'b010: begin Q6<=1'b0; Q5<=1'b0; Q4<=pwm_reg2; Q3<=1'b0; Q2<=1'b0; Q1 <=pwm_reg2;   end
     3'b110: begin Q6<=pwm_reg2; Q5<=1'b0; Q4<=1'b0; Q3<=1'b0; Q2<=1'b0; Q1 <=pwm_reg2;   end
     3'b100: begin Q6<=pwm_reg2; Q5<=1'b0; Q4<=1'b0; Q3<=pwm_reg2; Q2<=1'b0; Q1 <= 1'b0;  end
     default: begin Q6<=1'b0; Q5<=1'b0; Q4<=1'b0; Q3<=1'b0; Q2<=1'b0; Q1 <= 1'b0; end  
     endcase
    end
   end
  
 2'b10: 
    begin  
      if(LT1800_Flag) 
        begin
          Q7 <=1'b0;
//          Q8 <=pwm_reg2;
          Q8 <=1'b0;
          Q9 <=pwm_reg2;
          Q6 <=1'b0;
          Q5 <=1'b0;
          Q4 <=1'b0;
          Q3 <=1'b0;
          Q2 <=1'b0;
          Q1 <=1'b0;
        end
      else 
        begin 
          Q7 <= 1'b0;
          Q8 <= pwm_reg2;
          Q9 <= 1'b0;
          Q6 <=1'b0;
          Q5 <=1'b0;
          Q4 <=1'b0;
          Q3 <=1'b0;
          Q2 <=1'b0;
          Q1 <=1'b0;    
       end 
    end   
 2'b11: 
    begin
     Q7<=1'b0;
     Q8<=1'b0;
     Q9<=1'b0;
     Q6<=1'b0;
     Q5<=1'b0;
     Q4<=1'b0;
     Q3<=1'b0;
     Q2<=1'b0;
     Q1<=1'b0;
   end  

  default: 
   begin
     Q7<=1'b0;
     Q8<=1'b0;
     Q9<=1'b0;
     Q6<=1'b0;
     Q5<=1'b0;
     Q4<=1'b0;
     Q3<=1'b0;
     Q2<=1'b0;
     Q1<=1'b0;
   end
  endcase
  end
 end

endmodule
