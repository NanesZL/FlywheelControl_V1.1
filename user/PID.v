`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:03:46 07/15/2018 
// Design Name: 
// Module Name:    PID 
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
module PID(clk,rst_n,PID_a0,PID_a1,PID_a2,PID_rt,PID_yt,PID_clr,PID_start,PID_end,PID_out,PID_insdata);
input clk,rst_n,PID_clr,PID_start;
input [11:0] PID_rt,PID_yt,PID_insdata;
input [9:0] PID_a0,PID_a1,PID_a2;
output reg PID_end; 
//output [27:0] PID_out;
output [13:0]PID_out;    //[27:14]
//output [22:0] PID_val0;   //test
//wire [22:0] PID_val0;
wire [22:0] PID_val0,PID_val1,PID_val2;
reg [12:0]  ek0_temp2;
reg [12:0]  ek1_temp2,ek2_temp2;
//reg [27:0] PID_outreg,PID_outregtemp2;
reg [13:0] PID_outreg;
reg [27:0] PID_outregtemp2;
reg [26:0] PID_outregtemp1;
//output reg [4:0] PID_state;
reg [4:0] PID_state;
reg [5:0] PIDWAIT1_count,PIDWAIT2_count,PIDOUT_count,PIDPRMUL_count;
reg [22:0]  PID_val0_temp,PID_val1_temp,PID_val2_temp;
reg [23:0]  PID_fval_temp1;        
reg [26:0]  PID_fval_temp2;

 /////////////////////////////////////


parameter 	PID_IDLE =5'd0, GETNUM = 5'd1, WAITMUL = 5'd2, WAITERROR = 5'd3,COMPUTE1 = 5'd4, COMPUTE2 = 5'd5,
          	COMPUTE3= 5'd6, COMPUTE4 = 5'd7, COMPUTE5 = 5'd8, COMPUTE6 = 5'd9,OUTPUT = 5'd10,PIDCLR = 5'd11;       		
 
reg PID_Clrflag,Error_clk; 
reg [11:0] PID_rt_reg,PID_yt_reg;
reg [12:0] ek0_r,ek1_r,ek2_r;
reg [9:0] PID_a0_r,PID_a1_r,PID_a2_r;
 
always @(posedge clk or negedge rst_n)
  if(!rst_n)
   	PID_Clrflag <= 0;
  else 
   	PID_Clrflag <= PID_clr;
 
always @(posedge clk or negedge rst_n)
  if(!rst_n)
  	begin
	   PID_a0_r <= 10'd0;
	   PID_a1_r <= 10'd0;
	   PID_a2_r <= 10'd0;
  	end
  else 
  	begin
   	  PID_a0_r <= PID_a0;
   	  PID_a1_r <= PID_a1;
   	  PID_a2_r <= PID_a2;
  	end
always @(posedge clk or negedge rst_n)
  if(!rst_n)
    begin 
      PIDWAIT1_count <= 6'b0;
      PIDWAIT2_count <= 6'b0;
      PIDOUT_count <= 6'b0;
      PIDPRMUL_count <=6'b0;    
      Error_clk <= 0;
      PID_end <= 1'b0;
     //PID_clrend <= 1'b0; 	  
 	    PID_outreg <= 0;
      PID_outregtemp2 <= 0;
      PID_outregtemp1 <= 0;    
      PID_state <= PID_IDLE;
      PID_rt_reg <= 0;
      PID_yt_reg <= 0;    
      PID_val0_temp <= 0;
      PID_val1_temp <= 0;
      PID_val2_temp <= 0;
      ek0_temp2 <= 0;
      ek1_temp2 <= 0;
      ek2_temp2 <= 0;     
      PID_fval_temp1 <=0;
      PID_fval_temp2 <=0;
    
    end
  else
  	case(PID_state)  
  	PID_IDLE: 
      if(PID_Clrflag)
    	PID_state <= PIDCLR;
      else   
        begin
          PID_end <=1'b0;
          if(PID_start) PID_state <= GETNUM;
          else 
        	  begin
              PID_state <= PID_IDLE; 
              PIDWAIT1_count <= 6'b0;
              PIDWAIT2_count <= 6'b0;  
              PIDOUT_count <= 6'b0;
          	  PIDPRMUL_count <= 6'b0;          
              Error_clk <= 0;    
            end
      	end     
   	GETNUM:
   	  if(PID_Clrflag)
     	PID_state <= PIDCLR;
      else  
       	begin
          Error_clk <= 0; 
          if(PIDWAIT1_count > 6'd5 )
        	  begin
              PIDWAIT1_count <= 6'd0;       
              PID_rt_reg <= PID_rt ;
              PID_yt_reg <= PID_yt; 
              PID_state <= WAITERROR; 
           	end
          else
            begin
              PIDWAIT1_count <= PIDWAIT1_count + 1'b1;
              PID_state <= GETNUM; 
        	end             
        end   
   	WAITERROR:
   	  if(PID_Clrflag)
    	PID_state <= PIDCLR;
      else  
      	begin
          Error_clk <= 1; 
          if(PIDWAIT2_count > 6'd10 )
        	  begin
           	  PIDWAIT2_count <= 6'd0; 
         	    ek0_temp2 <= ek0_r;
              ek1_temp2 <= ek1_r;
              ek2_temp2 <= ek2_r;
              PID_state <= WAITMUL;
          	end
          else
          	begin
              PIDWAIT2_count <= PIDWAIT2_count + 1'b1;
              PID_state <= WAITERROR; 
            end                   
      	end       
  	WAITMUL:
  	  if(PID_Clrflag)
    	PID_state <= PIDCLR;
      else  
       	begin
//          if(PIDPRMUL_count > 6'd4 )
          if(PIDPRMUL_count > 6'd8 )
          begin
           	PIDPRMUL_count <= 0; 
         	  PID_val0_temp <= PID_val0;
         	  PID_val1_temp <= PID_val1;
         	  PID_val2_temp <= PID_val2;
           	PID_state <= COMPUTE1;
          	end
          else
           	begin
           	  PIDPRMUL_count  <= PIDPRMUL_count  + 1'b1;
              PID_state <=WAITMUL; 
           	end                   
      	end     
   	COMPUTE1: 
      if(PID_Clrflag)
    	PID_state <= PIDCLR;
      else  
        begin
         //PID_fval_temp1 <= {PID_val0_temp[22],PID_val0_temp} - {PID_val1_temp[22],PID_val1_temp} + {PID_val2_temp[22],PID_val2_temp}; //maybe over
          PID_fval_temp1 <= {PID_val0_temp[22],PID_val0_temp[22],PID_val0_temp[22:1]}          //to avoid over,PID_val_temp/2,
                          - {PID_val1_temp[22],PID_val1_temp[22],PID_val1_temp[22:1]}         //so valid value change to 22bit(signed),
                           + {PID_val2_temp[22],PID_val2_temp[22],PID_val2_temp[22:1]};       //3 22bit(signed) +/-,valid bit will be 24bit
     
          PID_state <= COMPUTE2;
      end      
 	COMPUTE2: 
      if(PID_Clrflag)
    	PID_state <= PIDCLR;
      else  
        begin
          if(PID_fval_temp1[23]==0) 
           	begin
              PID_fval_temp2 <= {3'b000,PID_fval_temp1};
              PID_state <= COMPUTE3;
           end
          else  
           	begin
              PID_fval_temp2 <= {3'b111,PID_fval_temp1};
              PID_state <= COMPUTE3;
           	end
      	end   
      
  	COMPUTE3: 
      if(PID_Clrflag)
    	PID_state <= PIDCLR;
      else  
        begin
          if(PID_outregtemp2[27]==0)
          	PID_outregtemp1 <= {1'b0,PID_outregtemp2[25:0]};
          else
          	PID_outregtemp1 <= 0;          
       	  PID_state <= COMPUTE4;
      	end       
  	COMPUTE4: 
      if(PID_Clrflag)
    	PID_state <= PIDCLR;
      else  
       	begin
          PID_outregtemp2 <={PID_outregtemp1[26],PID_outregtemp1} + {PID_fval_temp2[26],PID_fval_temp2};
          PID_state <= COMPUTE5;
      	end   
  	COMPUTE5: 
      if(PID_Clrflag)
     	PID_state <= PIDCLR;
      else  
        begin
          if(PID_outregtemp2[27]==1)
          	PID_outregtemp2 <= 0;
       	  else if(PID_outregtemp2[26]==1)
        	PID_outregtemp2 <=28'b0011111111111111111111111111;         
          PID_state <= COMPUTE6;
      	end 
   	COMPUTE6: 
      if(PID_Clrflag)
     	PID_state <= PIDCLR;
      else  
       	begin
       	  if(PID_rt < 12'd2)               //clr intergral
        	begin
        	  PID_outreg <= 14'b0;  
         	  PID_outregtemp2  <= 28'b0;     
        	  PID_state <= OUTPUT;
        	end
      	  else
          	begin
         	  PID_outreg <= PID_outregtemp2[27:14];       
         	  PID_state <= OUTPUT;
          	end
      	end  
  	PIDCLR:
      begin
     	PIDWAIT1_count <= 6'b0;
     	PIDWAIT2_count <= 6'b0;
     	PIDOUT_count <= 6'b0;
     	PIDPRMUL_count <=6'b0;    
     	Error_clk <= 0;
     	PID_end <=1'b0;    
    //PID_clrend <= 1'b1;
    
     PID_outreg <= {2'b00,PID_insdata};
     PID_outregtemp2 <= {2'b00,PID_insdata,14'd0};
     PID_outregtemp1 <= {1'b0,PID_insdata,14'd0};  
    	PID_val0_temp <= 0;
    	PID_val1_temp <= 0;
    	PID_val2_temp <= 0;
     	PID_fval_temp1 <=0;
      PID_fval_temp2 <=0;  
    	PID_state <= OUTPUT;
   	  end
   	OUTPUT:  
      begin      
        PID_end <=1'b1;
        Error_clk <= 0;
         //PID_clrend <= 1'b0;            
        if(PIDOUT_count > 6'd3) 
          begin        
            PID_state <= PID_IDLE;
            PIDOUT_count <= 0;
          end
        else 
          begin
           	PID_state <= OUTPUT;
          	PIDOUT_count <= PIDOUT_count + 1'b1;
          end
      end         
  	default: PID_state <= PID_IDLE;               
  	endcase  
//assign PID_out = PID_outreg[27:14];
assign PID_out = PID_outreg;

reg error_clk_r1;
reg error_clk_r2;
wire error_clk_pos;
wire [12:0] rt_temp,yt_temp,ek0_temp;

assign rt_temp={1'b0,PID_rt_reg};
assign yt_temp=~{1'b0,PID_yt_reg} + 1'b1; 
assign ek0_temp = rt_temp+ yt_temp;

always @(posedge clk or negedge rst_n)
  if(!rst_n)
    begin
      error_clk_r1 <= 0;
      error_clk_r2 <= 0;
    end
  else
    begin
      error_clk_r1 <= Error_clk;
      error_clk_r2 <= error_clk_r1;
    end
	  
assign error_clk_pos = ~error_clk_r2 & error_clk_r1;
	  
	  

always @(posedge clk or negedge rst_n)
  if(!rst_n)
    begin
      ek0_r <= 0;
      ek1_r <= 0;
      ek2_r <= 0;
    end
  else 
   	begin
      if(error_clk_pos)
      	begin
          ek0_r <= ek0_temp;
          ek1_r <= ek0_r;
          ek2_r <= ek1_r;
      	end
	  end 	

Multi_13_11 multiply1(
  	.clk(clk), 
  	.a(ek0_temp2), 
  	.b(PID_a0_r), 
  	.p(PID_val0)
);

Multi_13_11 multiply2(
  	.clk(clk), 
  	.a(ek1_temp2), 
  	.b(PID_a1_r), 
  	.p(PID_val1)
);

Multi_13_11 multiply3(
  	.clk(clk), 
  	.a(ek2_temp2), 
  	.b(PID_a2_r), 
  	.p(PID_val2)
);














endmodule
