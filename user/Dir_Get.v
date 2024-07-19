`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:17:47 07/14/2018 
// Design Name: 
// Module Name:    Dir_Get 
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
module Dir_Get(clk,rst_n, 
     Hall_a,Hall_b,Hall_c,Speed_Dir);

input clk,rst_n;
input Hall_a,Hall_b,Hall_c;
output Speed_Dir; 

reg [2:0] HallReg_1,HallReg_2,HallReg_3,HallReg_4;
reg [2:0] Hall_State;

always @ (posedge clk or negedge rst_n)
  if (!rst_n) 
   begin
    HallReg_1 <=3'b000;
    HallReg_2 <=3'b000;
    HallReg_3 <=3'b000;
    HallReg_4 <=3'b000;
   end
  else 
   begin
    HallReg_4 <= HallReg_3;
    HallReg_3 <= HallReg_2;
    HallReg_2 <= HallReg_1;
    HallReg_1 <= {Hall_c,Hall_b,Hall_a};   
   end

always @ (posedge clk or negedge rst_n)
  if(!rst_n)
   	Hall_State <= 0;
  else if((HallReg_4==HallReg_3)&&(HallReg_3 == HallReg_2) && (HallReg_2 == HallReg_1))
   	Hall_State <= HallReg_4;
  
reg [3:0] FWD_Cnt,REV_Cnt;		//forward cnt, reverse cnt
reg [2:0] Dir_Get_State;		

always @ (posedge clk or negedge rst_n) 
  if(!rst_n)
   begin
   	FWD_Cnt <= 4'b0;
   	REV_Cnt <= 4'b0;
   	Dir_Get_State <=3'b0;
   end
  else 
   case(Dir_Get_State)
   3'b000:
    begin 	
      case(Hall_State)
      3'b000: begin
       	FWD_Cnt <= 4'b0;
       	REV_Cnt <= 4'b0;
       	Dir_Get_State <=3'b0;
       end
      3'b101: begin
       	FWD_Cnt <= 4'b1;
       	REV_Cnt <= 4'b1;	
       	Dir_Get_State <=3'b101;
       end
      3'b100: begin
       	FWD_Cnt <= 4'b1;
       	REV_Cnt <= 4'b1;	
       	Dir_Get_State <=3'b100;	 
       end  
      3'b110: begin
       	FWD_Cnt <= 4'b1;
       	REV_Cnt <= 4'b1;	
       	Dir_Get_State <=3'b110;	 
       end  
      3'b010: begin
       	FWD_Cnt <= 4'b1;
       	REV_Cnt <= 4'b1;	
       	Dir_Get_State <=3'b010;	 
       end  
      3'b011: begin
       	FWD_Cnt <= 4'b1;
       	REV_Cnt <= 4'b1;	
       	Dir_Get_State <=3'b011;	 
       end  
      3'b001: begin
       	FWD_Cnt <= 4'b1;
       	REV_Cnt <= 4'b1;	
       	Dir_Get_State <=3'b001;	 
       end 
      default: begin 
       	FWD_Cnt <= 4'b0;
       	REV_Cnt <= 4'b0;	
       	Dir_Get_State <=3'b000;
       end
      endcase 
     end

   3'b101:
     begin
     if(Hall_State == 3'b100) 
       begin
        FWD_Cnt <= FWD_Cnt + 1;
        REV_Cnt <= 4'b1;
        Dir_Get_State <=3'b100; 
       end
     else if(Hall_State == 3'b001) 
       begin
        FWD_Cnt <= 4'b1;
        REV_Cnt <= REV_Cnt + 1;
        Dir_Get_State <=3'b001;
       end
     else if(Hall_State == 3'b101)
	    Dir_Get_State <=3'b101;     
     else  
       begin 
        FWD_Cnt <= 4'b0;
        REV_Cnt <= 4'b0;	
        Dir_Get_State <=3'b000;
       end
     end

   3'b100:
     begin
      if(Hall_State == 3'b110) 
       begin
	    FWD_Cnt <= FWD_Cnt + 1;
        REV_Cnt <= 4'b1;
        Dir_Get_State <=3'b110; 
       end
     else if(Hall_State == 3'b101) 
       begin
	    FWD_Cnt <= 4'b1;
        REV_Cnt <= REV_Cnt + 1;
        Dir_Get_State <=3'b101;
       end
     else if(Hall_State == 3'b100)
	    Dir_Get_State <=3'b100;     
     else  
       begin 
        FWD_Cnt <= 4'b0;
        REV_Cnt <= 4'b0;	
        Dir_Get_State <=3'b000;
       end

     end

   3'b110:
     begin
       if(Hall_State == 3'b010) 
       begin
	    FWD_Cnt <= FWD_Cnt + 1;
        REV_Cnt <= 4'b1;
        Dir_Get_State <=3'b010; 
       end
     else if(Hall_State == 3'b100) 
       begin
	    FWD_Cnt <= 4'b1;
        REV_Cnt <= REV_Cnt + 1;
        Dir_Get_State <=3'b100;
       end
     else if(Hall_State == 3'b110)
	    Dir_Get_State <=3'b110;     
     else  
       begin 
        FWD_Cnt <= 4'b0;
        REV_Cnt <= 4'b0;	
        Dir_Get_State <=3'b000;
       end
     end

   3'b010:
     begin
      if(Hall_State == 3'b011) 
       begin
		FWD_Cnt <= FWD_Cnt + 1;
        REV_Cnt <= 4'b1;
        Dir_Get_State <=3'b011; 
       end
     else if(Hall_State == 3'b110) 
       begin
		FWD_Cnt <= 4'b1;
        REV_Cnt <= REV_Cnt + 1;
        Dir_Get_State <=3'b110;
       end
     else if(Hall_State == 3'b010)
		Dir_Get_State <=3'b010;     
     else  
       begin 
        FWD_Cnt <= 4'b0;
        REV_Cnt <= 4'b0;	
        Dir_Get_State <=3'b000;
       end
     end

   3'b011:
     begin
      if(Hall_State == 3'b001) 
       begin
		FWD_Cnt <= FWD_Cnt + 1;
        REV_Cnt <= 4'b1;
        Dir_Get_State <=3'b001; 
       end
     else if(Hall_State == 3'b010) 
       begin
		FWD_Cnt <= 4'b1;
        REV_Cnt <= REV_Cnt + 1;
        Dir_Get_State <=3'b010;
       end
     else if(Hall_State == 3'b011)
		Dir_Get_State <=3'b011;     
     else  
       begin 
        FWD_Cnt <= 4'b0;
        REV_Cnt <= 4'b0;	
        Dir_Get_State <=3'b000;
       end
     end

   3'b001:
     begin
     if(Hall_State == 3'b101) 
       begin
		FWD_Cnt <= FWD_Cnt + 1;
        REV_Cnt <= 4'b1;
        Dir_Get_State <=3'b101; 
       end
     else if(Hall_State == 3'b011) 
       begin
		FWD_Cnt <= 4'b1;
        REV_Cnt <= REV_Cnt + 1;
        Dir_Get_State <=3'b011;
       end
     else if(Hall_State == 3'b001)
		Dir_Get_State <=3'b001;     
     else  
       begin 
        FWD_Cnt <= 4'b0;
        REV_Cnt <= 4'b0;	
        Dir_Get_State <=3'b000;
       end
     end

   default:
      begin
      	FWD_Cnt <= 4'b0;
      	REV_Cnt <= 4'b0;
      	Dir_Get_State <=3'b0;
      end		 
   endcase

reg SpeedDir_Reg;

always @ (posedge clk or negedge rst_n)
  if(!rst_n)
    begin
     SpeedDir_Reg <= 1'b0;
    end
//  else if(FWD_Cnt == 4'b0111)
//     SpeedDir_Reg <= 1'b0;  
  else if(FWD_Cnt == 4'b0010)
    SpeedDir_Reg <= 1'b0; 		//JDJ_2Nm
//  else if(REV_Cnt == 4'b0111)   	  
//     SpeedDir_Reg <= 1'b1;
  else if(REV_Cnt == 4'b0010)   
    SpeedDir_Reg <= 1'b1;     //JDJ_2Nm
assign Speed_Dir = SpeedDir_Reg;


endmodule
