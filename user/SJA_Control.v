`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:56:38 07/14/2018 
// Design Name: 
// Module Name:    SJA_Control 
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
module SJA_Control(
	inout   [7:0] SJ_AD,
	input 	SJ_INT_n,
  output  SJA_Dir,
	output	SJ_RD_n,
	output	SJ_WR_n,
	output	SJ_ALE,
	output	SJ_CS_n,
	output	reg SJ_RST_n,
	input	  clk,
	input	  rst_n,
	input 	SJA_rst_en,		// 1-start SJA1000 reset for at least 2 clock cycles 
  input   CMD_Finish_Flag, // a CMD write operation finish
  input   [7:0]Cor_Com_Cnt_A,     //correct command cnt for CANA
  input   [7:0]Inv_Com_Cnt_A,     //invalid command cnt for CANA
  input   [7:0]Selftest_Sta,      //self test state from DSP
  input   [7:0] RXE_Cnt_A,          //RXE register for CANA
  input   [7:0] TXE_Cnt_A,          //TXE register for CANA 
  input   [7:0] Reset_CANA_Cnt,    //Reset of CANA cnt
  input   [15:0] Motor_Consumption_CAN, //Motor_Consumption from DSP
  input   [31:0] Motor_Speed_CAN,    //speed of float from DSP
  input   [31:0] Motor_Torque_CAN,   //torque of float from DSP
  input   [15:0] Motor_Currunt_CAN,  //currunt from DSP
  input   [15:0] Motor_Temperate_CAN,  //motor temperate from DSP 
  input   [15:0] Max_Torque_CAN,     //max torque from DSP
  input   [31:0] Motor_Torque_CMD,   //motor torque command 
  input   [15:0] Motor_Current_CMD,  //motor currunt command
  output  reg CMD_Start_Flag,  // to start a CMD write operation 
	output  reg [6:0] SJ_state,	
  output  reg [31:0] Max_Torque_B,    //Max_Torque set by CANB
  output  reg [31:0] Speed_CMD_B,     //Speed_Command set by CANB
  output  reg [15:0] Current_CMD_B,   //Current_Command set by CANB
  output  reg [31:0] Net_Torque_CMD_B,    //Net_Torque set by CANB
  output  reg [1:0] CR_CMD_B,         //communication reset by CANB
  output  reg [7:0]Inv_Com_Cnt_B,     //invalid command cnt for CANB
  output  reg [7:0]Cor_Com_Cnt_B,     //correct command cnt for CANB
  output  reg [7:0]Tor_Com_Cnt_B,     //torque command cnt for CANB
  output  reg [7:0] RXE_Cnt,          //RXE register for CANB
  output  reg [7:0] TXE_Cnt,           //TXE register for CANA 
  output  [7:0] Reset_CANB_Cnt,         //Reset of CANB cnt
  output  reg [3:0]CMD_State       //state of command  
    );


//reg [7:0]Inv_Com_Sta_B;     //invalid command state for CANB
reg [16:0] RST_Out_cnt;
reg [1:0] write_read_en;
reg [7:0] addr;
reg [7:0] data_2_sj;  // data to SJA1000
reg [7:0] Reset_CANB_Cnt_r; //Reset of CANB cnt register
reg CAN_start_flag; //can start flag:1 - start can send operation 
reg CAN_finish_flag;  //can finish flag:1 -  can send operation finish
reg [15:0] WD_cnt;  //watch dog cnt
reg [3:0] RX_frame_info;
reg [7:0] RX_D8,RX_D7,RX_D6,RX_D5,RX_D4,RX_D3,RX_D2,RX_D1;//RX_frame_info,RX_Id1,RX_Id2;
reg [7:0] TX_D8,TX_D7,TX_D6,TX_D5,TX_D4,TX_D3,TX_D2,TX_D1,TX_Id1,TX_Id2;//TX_frame_info;


parameter ACR0_F1 = 8'b00101101, ACR0_F2 = 8'b00110001, ACR0_F3 = 8'b00110101, ACR0_F4 = 8'b00111001, 
          ACR1_F1 = 8'b10001111, ACR1_F2 = 8'b10001111, ACR1_F3 = 8'b10001111, ACR1_F4 = 8'b10001111,
          ACR2_F1 = 8'b00101101, ACR2_F2 = 8'b00110001, ACR2_F3 = 8'b00110101, ACR2_F4 = 8'b00111001,
          ACR3_F1 = 8'b10001111, ACR3_F2 = 8'b10001111, ACR3_F3 = 8'b10001111, ACR3_F4 = 8'b10001111,
          AMR0_F1 = 8'b00000000, AMR0_F2 = 8'b00000000, AMR0_F3 = 8'b00000000, AMR0_F4 = 8'b00000000,
          AMR1_F1 = 8'b00001111, AMR1_F2 = 8'b00001111, AMR1_F3 = 8'b00001111, AMR1_F4 = 8'b00001111,
          AMR2_F1 = 8'b00000000, AMR2_F2 = 8'b00000000, AMR2_F3 = 8'b00000000, AMR2_F4 = 8'b00000000,
          AMR3_F1 = 8'b00001111, AMR3_F2 = 8'b00001111, AMR3_F3 = 8'b00001111, AMR3_F4 = 8'b00001111;
          
wire finish_flag;
wire [7:0] data_4_sj; // data from SJA1000
//reg [7:0] MR_temp;    // data read from MOD register
reg [1:0] MR_temp;      //only 2 bits useful
reg RX_Message_Flag;  // after receive 1 message , the flag = 1 for at least 2 clks 



parameter SJ_RST_IDLE = 7'd0, SJ_RST_S1 = 7'd1, SJ_RST_S2 = 7'd2, SJ_RST_WR_MR = 7'd3, SJ_RST_WR_MR_HOLD = 7'd4, 
          SJ_RST_RD_MR= 7'd5, SJ_RST_RD_MR_HOLD = 7'd6, SJ_RST_HOLD = 7'd7, SJ_RST_WR_CDR= 7'd8, SJ_RST_WR_CDR_HOLD= 7'd9,
          SJ_RST_WR_IER= 7'd10, SJ_RST_WR_IER_HOLD= 7'd11, SJ_RST_WR_BTR0= 7'd12, SJ_RST_WR_BTR0_HOLD= 7'd13, SJ_RST_WR_BTR1= 7'd14,
          SJ_RST_WR_BTR1_HOLD= 7'd15, SJ_RST_WR_OCR= 7'd16, SJ_RST_WR_OCR_HOLD= 7'd17, SJ_RST_WR_MR_1= 7'd18, SJ_RST_WR_MR_1_HOLD= 7'd19,
          SJ_RST_WR_ACR0= 7'd20, SJ_RST_WR_ACR0_HOLD= 7'd21, SJ_RST_WR_ACR1= 7'd22, SJ_RST_WR_ACR1_HOLD= 7'd23, SJ_RST_WR_ACR2= 7'd24,
          SJ_RST_WR_ACR2_HOLD= 7'd25, SJ_RST_WR_ACR3= 7'd26, SJ_RST_WR_ACR3_HOLD= 7'd27, SJ_RST_WR_AMR0= 7'd28, SJ_RST_WR_AMR0_HOLD= 7'd29,
          SJ_RST_WR_AMR1= 7'd30, SJ_RST_WR_AMR1_HOLD= 7'd31, SJ_RST_WR_AMR2= 7'd32, SJ_RST_WR_AMR2_HOLD= 7'd33, SJ_RST_WR_AMR3= 7'd34,
          SJ_RST_WR_AMR3_HOLD= 7'd35, SJ_RST_WR_MR_2= 7'd36, SJ_RST_WR_MR_2_HOLD= 7'd37, SJ_RST_RD_MR_1= 7'd38, SJ_RST_RD_MR_1_HOLD= 7'd39,
          SJ_QUIT_RST_HOLD= 7'd40, SJ_OPN_IDLE= 7'd41, SJ_OPN_RD_IR_HOLD= 7'd42, SJ_OPN_IR_CHECK= 7'd43, SJ_OPN_RX_S1= 7'd44,
          SJ_OPN_RX_S2= 7'd45, SJ_OPN_RX_S3= 7'd46, SJ_OPN_RX_S4= 7'd47, SJ_OPN_RX_S5= 7'd48, SJ_OPN_RX_S6= 7'd49,
          SJ_OPN_RX_S7= 7'd50, SJ_OPN_RX_S8= 7'd51, SJ_OPN_RX_S9= 7'd52, SJ_OPN_RX_S10= 7'd53, SJ_OPN_RX_S11= 7'd54,
          SJ_OPN_RX_S12= 7'd55, SJ_OPN_RX_S13= 7'd56, SJ_OPN_RX_S14= 7'd57, SJ_OPN_RX_S15= 7'd58, SJ_OPN_RX_S16= 7'd59,
          SJ_OPN_RX_S17= 7'd60, SJ_OPN_RX_S18= 7'd61, SJ_OPN_RX_S19= 7'd62, SJ_OPN_RX_S20= 7'd63, SJ_OPN_RX_S21= 7'd64,
          SJ_OPN_RX_S22= 7'd65, SJ_OPN_RX_S23= 7'd66, SJ_OPN_RX_S24= 7'd67, SJ_OPN_RXE_S1= 7'd68, SJ_OPN_RXE_S2= 7'd69,
          SJ_OPN_TXE_S1= 7'd70, SJ_OPN_TXE_S2= 7'd71, SJ_OPN_TX_S1= 7'd72, SJ_OPN_TX_S2= 7'd73, SJ_OPN_TX_S3= 7'd74,
          SJ_OPN_TX_S4= 7'd75,  SJ_OPN_TX_S4_HOLD= 7'd76, SJ_OPN_TX_S5= 7'd77,  SJ_OPN_TX_S5_HOLD= 7'd78,
          SJ_OPN_TX_S6= 7'd79,  SJ_OPN_TX_S6_HOLD= 7'd80, SJ_OPN_TX_S7= 7'd81,  SJ_OPN_TX_S7_HOLD= 7'd82,
          SJ_OPN_TX_S8= 7'd83,  SJ_OPN_TX_S8_HOLD= 7'd84, SJ_OPN_TX_S9= 7'd85,  SJ_OPN_TX_S9_HOLD= 7'd86,
          SJ_OPN_TX_S10= 7'd87,  SJ_OPN_TX_S10_HOLD= 7'd88, SJ_OPN_TX_S11= 7'd89,  SJ_OPN_TX_S11_HOLD= 7'd90,
          SJ_OPN_TX_S12= 7'd91,  SJ_OPN_TX_S12_HOLD= 7'd92, SJ_OPN_TX_S13= 7'd93,  SJ_OPN_TX_S13_HOLD= 7'd94,
          SJ_OPN_TX_S14= 7'd95,  SJ_OPN_TX_S14_HOLD= 7'd96, SJ_OPN_TX_S15= 7'd97,  SJ_OPN_TX_S16= 7'd98,
          SJ_OPN_TX_S17= 7'd99,  SJ_OPN_TX_S18= 7'd100,  SJ_OPN_TX_S19= 7'd101,  SJ_OPN_TX_S20= 7'd102;

always @(posedge clk or negedge rst_n)
  if (!rst_n)
  	begin
  	  RST_Out_cnt <= 17'd0;
  	  SJ_RST_n <= 1'b1;	
      write_read_en <= 2'b00;
      addr <= 8'b00000000;
      data_2_sj <= 8'b00000000;
      MR_temp <= 2'b00;
      SJ_state <= SJ_RST_IDLE;
      RX_Message_Flag <= 1'b0;
      RXE_Cnt <= 8'd0;
      TXE_Cnt <= 8'd0;
      Reset_CANB_Cnt_r <= 8'd0;
      WD_cnt <= 16'd0;
      CAN_finish_flag <= 1'b0;
    end
  else if(SJA_rst_en)     // rst at anytime when SJA_rst_en == 1
    begin
      RST_Out_cnt <= 17'd0;
      SJ_RST_n <= 1'b1;
      MR_temp <= 2'b00;
      SJ_state <= SJ_RST_S1;
    end
  else begin
  	case(SJ_state)
    /////////////////      rst     ////////////////////////////////////
  	SJ_RST_IDLE:
  	  begin
  		RST_Out_cnt <= 17'd0;
  		SJ_RST_n <= 1'b1;
      MR_temp <= 2'b00;
      RX_Message_Flag <= 1'b0;
  	  	if(SJA_rst_en)
  	  	  begin
  	  		SJ_state <= SJ_RST_S1;	
  	  	  end  	  	  
  	  	else 
  	  	  begin
  	  	 	SJ_state <= SJ_RST_IDLE;
  	  	  end
  	  end
  	SJ_RST_S1:			// generate 4ms SJA_RST 0
  	  begin
      RX_Message_Flag <= 1'b0;
  		if(RST_Out_cnt >= 17'd120000)
  		  begin
  			RST_Out_cnt <= 17'd0;
  			SJ_state <= SJ_RST_S2;	
  			SJ_RST_n <= 1'b1;	
  		  end
  		else 
  		  begin
  			SJ_RST_n <= 1'b0;		//SJ_RST_n 0 for SJA1000 reset
  			RST_Out_cnt <= RST_Out_cnt + 1'b1;
  		  end  	  	
  	  end
  	SJ_RST_S2:			// stand by 2ms after SJA_RST 0
  	  begin
  	  	if(RST_Out_cnt >= 17'd60000)
  	  	  begin
  	  		SJ_state <= SJ_RST_WR_MR;
  	  		RST_Out_cnt <= 17'd0;
  	  	  end
  	  	else begin
  	  		RST_Out_cnt <= RST_Out_cnt + 1'b1;
  	  	end 	  
  	  end
  	SJ_RST_WR_MR:  //write MOD register
  	  begin
        Reset_CANB_Cnt_r <= Reset_CANB_Cnt_r + 1'b1;
        write_read_en <= 2'b10;   //write
        addr <= 8'h00;    //0x00
        data_2_sj <= 8'h01;  //0x01 
        SJ_state <= SJ_RST_WR_MR_HOLD;    
      end
    SJ_RST_WR_MR_HOLD:  //write MOD register hold for finish
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            SJ_state <= SJ_RST_RD_MR;
          end
        else begin
            SJ_state <= SJ_RST_WR_MR_HOLD;
        end
      end
    SJ_RST_RD_MR:   //read MOD register
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h00;    //0x00
        SJ_state <= SJ_RST_RD_MR_HOLD; 
      end
    SJ_RST_RD_MR_HOLD:  //read MOD register hold for finish
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            MR_temp <= {data_4_sj[2],data_4_sj[0]};
            SJ_state <= SJ_RST_HOLD;
          end
        else begin
            SJ_state <= SJ_RST_RD_MR_HOLD;
        end
      end
    SJ_RST_HOLD:    // to check MR.0 = 1
      begin
        if(MR_temp[0] == 1'b1)
          SJ_state <= SJ_RST_WR_CDR;  // go to next step
        else
          SJ_state <= SJ_RST_S1;      // go to s1 for reset
      end
    SJ_RST_WR_CDR:  // write 0xC8 to CDR(0x1F)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h1F;    //0x1F
        data_2_sj <= 8'hC8;  //0xC8,PeliCAN mode
        SJ_state <= SJ_RST_WR_CDR_HOLD; 
      end
    SJ_RST_WR_CDR_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            SJ_state <= SJ_RST_WR_IER;
          end
        else begin
            SJ_state <= SJ_RST_WR_CDR_HOLD;
        end
      end
    SJ_RST_WR_IER:  // write 0x03 to IER(0x04)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h04;    //0x04
      //  data_2_sj <= 8'h03;  // enable TX an RS interrupt
        data_2_sj <= 8'h01;  // enable RS interrupt
        SJ_state <= SJ_RST_WR_IER_HOLD;        
      end
    SJ_RST_WR_IER_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            SJ_state <= SJ_RST_WR_BTR0;
          end
        else begin
            SJ_state <= SJ_RST_WR_IER_HOLD;
        end
      end
    SJ_RST_WR_BTR0:  // write 0x80 to BTR0(0x06)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h06;    //0x06
        data_2_sj <= 8'h80;   
        SJ_state <= SJ_RST_WR_BTR0_HOLD;        
      end
    SJ_RST_WR_BTR0_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            SJ_state <= SJ_RST_WR_BTR1;
          end
        else begin
            SJ_state <= SJ_RST_WR_BTR0_HOLD;
        end
      end
    SJ_RST_WR_BTR1:  // write 0x2B to BTR1(0x07)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h07;    //0x07
        data_2_sj <= 8'h2B;  
        SJ_state <= SJ_RST_WR_BTR1_HOLD;        
      end
    SJ_RST_WR_BTR1_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            SJ_state <= SJ_RST_WR_OCR;
          end
        else begin
            SJ_state <= SJ_RST_WR_BTR1_HOLD;
        end
      end
    SJ_RST_WR_OCR:  // write 0xDA to OCR(0x08)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h08;    //0xDA
        data_2_sj <= 8'hDA;  
        SJ_state <= SJ_RST_WR_OCR_HOLD;        
      end
    SJ_RST_WR_OCR_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            SJ_state <= SJ_RST_WR_MR_1;
          end
        else begin
            SJ_state <= SJ_RST_WR_OCR_HOLD;
        end
      end
    SJ_RST_WR_MR_1:  //write 0x01 to MR(0x00)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h00;    //0x00
        data_2_sj <= 8'h01;  //0x01 
        SJ_state <= SJ_RST_WR_MR_1_HOLD;    
      end
    SJ_RST_WR_MR_1_HOLD:  
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            SJ_state <= SJ_RST_WR_ACR0;
          end
        else begin
            SJ_state <= SJ_RST_WR_MR_1_HOLD;
        end
      end
    SJ_RST_WR_ACR0:  // write ACR0_F1 to ACR0(0x10)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h10;    //0x10
        data_2_sj <= ACR0_F1;  // FW1
        SJ_state <= SJ_RST_WR_ACR0_HOLD;        
      end
    SJ_RST_WR_ACR0_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_RST_WR_ACR1;          
        else
          SJ_state <= SJ_RST_WR_ACR0_HOLD;        
      end
    SJ_RST_WR_ACR1:  // write  ACR1_F1 to ACR1(0x11)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h11;    //0x11
        data_2_sj <= ACR1_F1;  // FW1
        SJ_state <= SJ_RST_WR_ACR1_HOLD;        
      end
    SJ_RST_WR_ACR1_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_RST_WR_ACR2;          
        else
          SJ_state <= SJ_RST_WR_ACR1_HOLD;        
      end
    SJ_RST_WR_ACR2:  // write ACR2_F1 to ACR2(0x12)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h12;    //0x12
        data_2_sj <= ACR2_F1;  // FW1
        SJ_state <= SJ_RST_WR_ACR2_HOLD;        
      end
    SJ_RST_WR_ACR2_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_RST_WR_ACR3;          
        else 
          SJ_state <= SJ_RST_WR_ACR2_HOLD;        
      end
    SJ_RST_WR_ACR3:  // write ACR3_F1 to ACR3(0x13)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h13;    //0x13
        data_2_sj <= ACR3_F1;  // FW1
        SJ_state <= SJ_RST_WR_ACR3_HOLD;        
      end
    SJ_RST_WR_ACR3_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          SJ_state <= SJ_RST_WR_AMR0;        
        else
          SJ_state <= SJ_RST_WR_ACR3_HOLD;        
      end
    SJ_RST_WR_AMR0:  // write AMR0_F1 to AMR0(0x14)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h14;    //0x14
        data_2_sj <= AMR0_F1;  // FW1
        SJ_state <= SJ_RST_WR_AMR0_HOLD;        
      end
    SJ_RST_WR_AMR0_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_RST_WR_AMR1;          
        else
          SJ_state <= SJ_RST_WR_AMR0_HOLD;        
      end
    SJ_RST_WR_AMR1:  // write  AMR1_F1 to AMR1(0x15)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h15;    //0x15
        data_2_sj <= AMR1_F1;  // FW1
        SJ_state <= SJ_RST_WR_AMR1_HOLD;        
      end
    SJ_RST_WR_AMR1_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_RST_WR_AMR2;          
        else
          SJ_state <= SJ_RST_WR_AMR1_HOLD;        
      end
    SJ_RST_WR_AMR2:  // write AMR2_F1 to AMR2(0x16)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h16;    //0x16
        data_2_sj <= AMR2_F1;  // FW1
        SJ_state <= SJ_RST_WR_AMR2_HOLD;        
      end
    SJ_RST_WR_AMR2_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_RST_WR_AMR3;          
        else 
          SJ_state <= SJ_RST_WR_AMR2_HOLD;        
      end
    SJ_RST_WR_AMR3:  // write AMR3_F1 to AMR3(0x17)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h17;    //0x17
        data_2_sj <= AMR3_F1;  // FW1
        SJ_state <= SJ_RST_WR_AMR3_HOLD;        
      end
    SJ_RST_WR_AMR3_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          SJ_state <= SJ_RST_WR_MR_2;        
        else
          SJ_state <= SJ_RST_WR_AMR3_HOLD;        
      end
    SJ_RST_WR_MR_2:  //write 0x00 to MR(0x00)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h00;    //0x00
        data_2_sj <= 8'h00;  //0x01 
        SJ_state <= SJ_RST_WR_MR_2_HOLD;    
      end
    SJ_RST_WR_MR_2_HOLD:  
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          SJ_state <= SJ_RST_RD_MR_1;
        else
          SJ_state <= SJ_RST_WR_MR_2_HOLD;
      end
    SJ_RST_RD_MR_1:   //read MOD register 
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h00;    //0x00
        SJ_state <= SJ_RST_RD_MR_1_HOLD; 
      end
    SJ_RST_RD_MR_1_HOLD:  //read MOD register hold for finish
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            MR_temp <= {data_4_sj[2],data_4_sj[0]};
            SJ_state <= SJ_QUIT_RST_HOLD;
          end
        else begin
            SJ_state <= SJ_RST_RD_MR_1_HOLD;
        end
      end
    SJ_QUIT_RST_HOLD:    // to check MR.0 = 0
      begin
        if(MR_temp[0] == 1'b0)
          SJ_state <= SJ_OPN_IDLE;  // go to operate normally idle
        else
          SJ_state <= SJ_RST_RD_MR_1;      // go to SJ_RST_RD_MR_1 for read again
      end
    /////////////////      operate normally      ////////////////////////////////////
    SJ_OPN_IDLE:          //operate normally idle
      begin
        RX_Message_Flag <= 1'b0;
        if(SJ_INT_n == 1'b0)
          begin
            write_read_en <= 2'b01;   //read
            addr <= 8'h03;    //0x03  (IR)
            SJ_state <= SJ_OPN_RD_IR_HOLD;
          end
        else if(CAN_start_flag) 
            SJ_state <= SJ_OPN_TX_S1;   //can tx step1
        else
          SJ_state <= SJ_OPN_IDLE;        
      end
    SJ_OPN_RD_IR_HOLD:  //read IR register hold for finish
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            MR_temp <= {data_4_sj[2],data_4_sj[0]};
            SJ_state <= SJ_OPN_IR_CHECK;
          end
        else begin
            SJ_state <= SJ_OPN_RD_IR_HOLD;
        end
      end
    SJ_OPN_IR_CHECK:  //check IR register  for RI == 1
      begin
        if(MR_temp[0] == 1'b1)  //receive interupt 
            SJ_state <= SJ_OPN_RXE_S1;
        else
            SJ_state <= SJ_OPN_IDLE; 
      end
    SJ_OPN_RXE_S1:   //read RX error register 0x0E(14)
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h0E;    //0x0E
        SJ_state <= SJ_OPN_RXE_S2;
      end
    SJ_OPN_RXE_S2:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            RXE_Cnt <= data_4_sj;
            SJ_state <= SJ_OPN_TXE_S1;
          end
        else
            SJ_state <= SJ_OPN_RXE_S2;
      end
    SJ_OPN_TXE_S1:   //read 0x0F(15)
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h0F;    //0x0F
        SJ_state <= SJ_OPN_TXE_S2;
      end
    SJ_OPN_TXE_S2:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            TXE_Cnt <= data_4_sj;
            SJ_state <= SJ_OPN_RX_S1;
          end
        else
            SJ_state <= SJ_OPN_TXE_S2;
      end
    SJ_OPN_RX_S1:   //read 0x10(16)
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h10;    //0x10
        SJ_state <= SJ_OPN_RX_S2;
      end
    SJ_OPN_RX_S2:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            RX_frame_info <= data_4_sj[3:0];
            SJ_state <= SJ_OPN_RX_S3;
          end
        else
            SJ_state <= SJ_OPN_RX_S2;
      end
    SJ_OPN_RX_S3:   //read 0x11(17)
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h11;    //0x11
        SJ_state <= SJ_OPN_RX_S4;
      end
    SJ_OPN_RX_S4:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
//            RX_Id1 <= data_4_sj;
            SJ_state <= SJ_OPN_RX_S5;
          end
        else
            SJ_state <= SJ_OPN_RX_S4;
      end
    SJ_OPN_RX_S5:   //read 0x12(18)
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h12;    //0x12
        SJ_state <= SJ_OPN_RX_S6;
      end
    SJ_OPN_RX_S6:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
//            RX_Id2 <= data_4_sj;
            SJ_state <= SJ_OPN_RX_S7;
          end
        else
            SJ_state <= SJ_OPN_RX_S6;
      end
    SJ_OPN_RX_S7:   //read 0x13(19)
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h13;    //0x13
        SJ_state <= SJ_OPN_RX_S8;
      end
    SJ_OPN_RX_S8:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            RX_D1 <= data_4_sj;
            SJ_state <= SJ_OPN_RX_S9;
          end
        else
            SJ_state <= SJ_OPN_RX_S8;
      end
    SJ_OPN_RX_S9:   //read 0x14(20)
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h14;    //0x13
        SJ_state <= SJ_OPN_RX_S10;
      end
    SJ_OPN_RX_S10:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            RX_D2 <= data_4_sj;
            SJ_state <= SJ_OPN_RX_S11;
          end
        else
            SJ_state <= SJ_OPN_RX_S10;
      end
    SJ_OPN_RX_S11:   //read 0x15(21)
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h15;    //0x13
        SJ_state <= SJ_OPN_RX_S12;
      end
    SJ_OPN_RX_S12:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            RX_D3 <= data_4_sj;
            SJ_state <= SJ_OPN_RX_S13;
          end
        else
            SJ_state <= SJ_OPN_RX_S12;
      end
    SJ_OPN_RX_S13:   //read 0x16(22)
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h16;    //0x13
        SJ_state <= SJ_OPN_RX_S14;
      end
    SJ_OPN_RX_S14:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            RX_D4 <= data_4_sj;
            SJ_state <= SJ_OPN_RX_S15;
          end
        else
            SJ_state <= SJ_OPN_RX_S14;
      end
    SJ_OPN_RX_S15:   //read 0x17(23)
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h17;    //0x13
        SJ_state <= SJ_OPN_RX_S16;
      end
    SJ_OPN_RX_S16:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            RX_D5 <= data_4_sj;
            SJ_state <= SJ_OPN_RX_S17;
          end
        else
            SJ_state <= SJ_OPN_RX_S16;
      end
    SJ_OPN_RX_S17:   //read 0x18(24)
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h18;    //0x13
        SJ_state <= SJ_OPN_RX_S18;
      end
    SJ_OPN_RX_S18:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            RX_D6 <= data_4_sj;
            SJ_state <= SJ_OPN_RX_S19;
          end
        else
            SJ_state <= SJ_OPN_RX_S18;
      end
    SJ_OPN_RX_S19:   //read 0x19(25)
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h19;    //0x13
        SJ_state <= SJ_OPN_RX_S20;
      end
    SJ_OPN_RX_S20:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            RX_D7 <= data_4_sj;
            SJ_state <= SJ_OPN_RX_S21;
          end
        else
            SJ_state <= SJ_OPN_RX_S20;
      end
    SJ_OPN_RX_S21:   //read 0x1A(26)
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h1A;    //0x13
        SJ_state <= SJ_OPN_RX_S22;
      end
    SJ_OPN_RX_S22:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            RX_D8 <= data_4_sj;
            RX_Message_Flag <= 1'b1;    // afte receive 1 message ,RX_Message_Flag = 1
            SJ_state <= SJ_OPN_RX_S23;
          end
        else
            SJ_state <= SJ_OPN_RX_S22;
      end
    SJ_OPN_RX_S23:    //write CMR(0x01)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h01;    //0x00
        data_2_sj <= 8'h04;  //0x04 .RRB = 1,start a new RX operation 
        SJ_state <= SJ_OPN_RX_S24;    
      end
    SJ_OPN_RX_S24:
      begin
        RX_Message_Flag <= 1'b0;
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          SJ_state <= SJ_OPN_IDLE;
        else
          SJ_state <= SJ_OPN_RX_S24;       
      end
    SJ_OPN_TX_S1:
      begin
        write_read_en <= 2'b01;   //read
        addr <= 8'h02;    //0x02  (SR)
        SJ_state <= SJ_OPN_TX_S2;        
      end
    SJ_OPN_TX_S2:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            MR_temp <= {data_4_sj[2],data_4_sj[0]};
            SJ_state <= SJ_OPN_TX_S3;
          end
        else
            SJ_state <= SJ_OPN_TX_S2;
      end
    SJ_OPN_TX_S3: //check SR.2
      begin
        if(MR_temp[1] == 1'b1)
          begin
            SJ_state <= SJ_OPN_TX_S4; 
            WD_cnt <= 16'd0;                  
          end
        else if(WD_cnt == 16'd30000)
          begin
            WD_cnt <= 16'd0;
            SJ_state <= SJ_OPN_IDLE;    //if tx time more than n(n > 1) ms
          end
        else begin
          SJ_state <= SJ_OPN_TX_S1;
          WD_cnt <= WD_cnt + 1'b1;
        end
      end
    SJ_OPN_TX_S4:   //write TX_frame_info to 0x10
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h10;    //0x10
//        data_2_sj <= TX_frame_info;  
        data_2_sj <= 8'b00001000;
        SJ_state <= SJ_OPN_TX_S4_HOLD; 
      end
    SJ_OPN_TX_S4_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_OPN_TX_S5;          
        else 
          SJ_state <= SJ_OPN_TX_S4_HOLD;
      end
    SJ_OPN_TX_S5:   //write TX_Id1 to 0x11
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h11;    //0x11
        data_2_sj <= TX_Id1; 
        SJ_state <= SJ_OPN_TX_S5_HOLD; 
      end
    SJ_OPN_TX_S5_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_OPN_TX_S6;          
        else 
          SJ_state <= SJ_OPN_TX_S5_HOLD;
      end
    SJ_OPN_TX_S6:   //write TX_Id2 to 0x12
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h12;    //0x12
        data_2_sj <= TX_Id2; 
        SJ_state <= SJ_OPN_TX_S6_HOLD; 
      end
    SJ_OPN_TX_S6_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_OPN_TX_S7;          
        else 
          SJ_state <= SJ_OPN_TX_S6_HOLD;
      end
    SJ_OPN_TX_S7:   //write TX_D1 to 0x13
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h13;    //0x13
        data_2_sj <= TX_D1; 
        SJ_state <= SJ_OPN_TX_S7_HOLD; 
      end
    SJ_OPN_TX_S7_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_OPN_TX_S8;          
        else 
          SJ_state <= SJ_OPN_TX_S7_HOLD;
      end
    SJ_OPN_TX_S8:   //write TX_D2 to 0x14
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h14;    //0x14
        data_2_sj <= TX_D2; 
        SJ_state <= SJ_OPN_TX_S8_HOLD; 
      end
    SJ_OPN_TX_S8_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_OPN_TX_S9;          
        else 
          SJ_state <= SJ_OPN_TX_S8_HOLD;
      end
    SJ_OPN_TX_S9:   //write TX_D3 to 0x15
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h15;    //0x15
        data_2_sj <= TX_D3; 
        SJ_state <= SJ_OPN_TX_S9_HOLD; 
      end
    SJ_OPN_TX_S9_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_OPN_TX_S10;          
        else 
          SJ_state <= SJ_OPN_TX_S9_HOLD;
      end
    SJ_OPN_TX_S10:   //write TX_D4 to 0x16
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h16;    //0x16
        data_2_sj <= TX_D4; 
        SJ_state <= SJ_OPN_TX_S10_HOLD; 
      end
    SJ_OPN_TX_S10_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_OPN_TX_S11;          
        else 
          SJ_state <= SJ_OPN_TX_S10_HOLD;
      end
    SJ_OPN_TX_S11:   //write TX_D5 to 0x17
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h17;    //0x17
        data_2_sj <= TX_D5; 
        SJ_state <= SJ_OPN_TX_S11_HOLD; 
      end
    SJ_OPN_TX_S11_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_OPN_TX_S12;          
        else 
          SJ_state <= SJ_OPN_TX_S11_HOLD;
      end
    SJ_OPN_TX_S12:   //write TX_D6 to 0x18
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h18;    //0x18
        data_2_sj <= TX_D6; 
        SJ_state <= SJ_OPN_TX_S12_HOLD; 
      end
    SJ_OPN_TX_S12_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_OPN_TX_S13;          
        else 
          SJ_state <= SJ_OPN_TX_S12_HOLD;
      end
    SJ_OPN_TX_S13:   //write TX_D7 to 0x19
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h19;    //0x19
        data_2_sj <= TX_D7; 
        SJ_state <= SJ_OPN_TX_S13_HOLD; 
      end
    SJ_OPN_TX_S13_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)          
          SJ_state <= SJ_OPN_TX_S14;          
        else 
          SJ_state <= SJ_OPN_TX_S13_HOLD;
      end
    SJ_OPN_TX_S14:   //write TX_D8 to 0x1A
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h1A;    //0x1A
        data_2_sj <= TX_D8; 
        SJ_state <= SJ_OPN_TX_S14_HOLD; 
      end
    SJ_OPN_TX_S14_HOLD:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)             
          SJ_state <= SJ_OPN_TX_S15;          
        else 
          SJ_state <= SJ_OPN_TX_S14_HOLD;
      end
    SJ_OPN_TX_S15:  //write CMR(0x01)
      begin
        write_read_en <= 2'b10;   //write
        addr <= 8'h01;    //0x01
//        data_2_sj <= 8'h01;  //0x01 .TR = 1,start a TX operation 
        data_2_sj <= 8'h03;  //0x03 .TR = 1,start a TX operation,AT = 1,transmit once        
        SJ_state <= SJ_OPN_TX_S16;  
      end
    SJ_OPN_TX_S16:
      begin
        write_read_en <= 2'b00; 
        if(finish_flag == 1'b1)
          begin
            SJ_state <= SJ_OPN_TX_S17;
            CAN_finish_flag <= 1'b1;
          end
        else
          SJ_state <= SJ_OPN_TX_S16; 
      end      
    SJ_OPN_TX_S17:  
        SJ_state <= SJ_OPN_TX_S18;
    SJ_OPN_TX_S18:  //wait for CAN_start_flag = 0  
      begin
        CAN_finish_flag <= 1'b0; 
        SJ_state <= SJ_OPN_TX_S19;  
      end         
    SJ_OPN_TX_S19:  //wait for CAN_start_flag = 0  
        SJ_state <= SJ_OPN_TX_S20;  
    SJ_OPN_TX_S20:  //wait for CAN_start_flag = 0          
        SJ_state <= SJ_OPN_IDLE; 
    default:
      begin
        SJ_state <= SJ_RST_IDLE;
      end
    endcase
  end



reg [4:0]Mes_Analys_state; //message analys state
reg [7:0]Sum_Check;         //sum check

parameter ID_F1 = 5'b01011,ID_F2 = 5'b01100,ID_F3 = 5'b01101,ID_F4 = 5'b01110;//Flywheel ID
parameter MA_IDLE = 5'd0,MA_S1 = 5'd1,MA_S2 = 5'd2,MA_RTC =5'd3,MA_RTC_S1=5'd4,MA_RTC_S1_HOLD=5'd5,
          MA_RTC_S2 = 5'd6, MA_RTC_S2_HOLD = 5'd7, MA_RTC_S3 = 5'd8, MA_RTC_S3_HOLD = 5'd9, 
          MA_RTC_S4 = 5'd10, MA_RTC_S4_HOLD = 5'd11, MA_RTC_S5 = 5'd12, MA_RTC_S5_HOLD = 5'd13,
          MA_SMT = 5'd14, MA_SWS =5'd15, MA_SNT = 5'd16, MA_CR = 5'd17, SUM_S1 = 5'd18,
          SUM_S2 = 5'd19, SUM_S3 = 5'd20, SUM_S4 = 5'd21, SUM_S5 = 5'd22,MA_CMD_1 = 5'd23,MA_CMD_2 = 5'd24,
          MA_SWC = 5'd25;      

always @(posedge clk or negedge rst_n)
  if (!rst_n)
    begin
      Mes_Analys_state <= MA_IDLE;
//      Inv_Com_Sta_B <= 8'hFF;
      Inv_Com_Cnt_B <= 8'd0;
      Cor_Com_Cnt_B <= 8'd0;
      Tor_Com_Cnt_B <= 8'd0;
      CAN_start_flag <= 1'b0;
//      TX_frame_info <= 8'd0;
      TX_Id1 <= 8'd0;
      TX_Id2 <= 8'd0;
      TX_D1 <= 8'd0;
      TX_D2 <= 8'd0;
      TX_D3 <= 8'd0;
      TX_D4 <= 8'd0;
      TX_D5 <= 8'd0;
      TX_D6 <= 8'd0;
      TX_D7 <= 8'd0;
      TX_D8 <= 8'd0;
      Sum_Check <=8'd0;
      CMD_State <= 4'b0;
    end
  else 
  begin
    case(Mes_Analys_state)
    MA_IDLE:
      begin
        if(SJA_rst_en == 1'b1)
          begin
            Inv_Com_Cnt_B <= 8'd0;
            Cor_Com_Cnt_B <= 8'd0;
          end
        else if(RX_Message_Flag == 1'b1)
          begin            
            Mes_Analys_state <= MA_S1;  //Step 1
          end
        else begin
          Mes_Analys_state <= MA_IDLE;
        end        
      end
    MA_S1:      //check length 
      begin
        if(RX_frame_info != 4'b1000)
          begin
//            Inv_Com_Sta_B <= 8'h01;     //command length error
            Inv_Com_Cnt_B <= Inv_Com_Cnt_B + 1'b1;
            Mes_Analys_state <= MA_IDLE;
          end
        else 
            Mes_Analys_state <= MA_S2;
      end
    MA_S2:
      begin
        case(RX_D1)
        8'h20:  //request telemetry command
          Mes_Analys_state <= MA_RTC;
        8'h21:  //set max torque
          Mes_Analys_state <= MA_SMT;
        8'h22:  //set wheel speed
          Mes_Analys_state <= MA_SWS;
        8'h23:  //set wheel currunt
          Mes_Analys_state <= MA_SWC;
        8'h24:  //set net torque
          Mes_Analys_state <= MA_SNT;
        8'h2C:  //communication recovery
          Mes_Analys_state <= MA_CR;
        default:
          begin
//            Inv_Com_Sta_B <= 8'h02;     //command type error
            Inv_Com_Cnt_B <= Inv_Com_Cnt_B + 1'b1;
            Mes_Analys_state <= MA_IDLE;
          end
        endcase
      end
    MA_RTC:
      begin
        if({RX_D2,RX_D3,RX_D4,RX_D5,RX_D6,RX_D7,RX_D8} != 56'b0)
          begin
//            Inv_Com_Sta_B <= 8'h03;     //command data error
            Inv_Com_Cnt_B <= Inv_Com_Cnt_B + 1'b1;
            Mes_Analys_state <= MA_IDLE;            
          end
        else 
          begin
            Cor_Com_Cnt_B <= Cor_Com_Cnt_B + 1'b1;
            Mes_Analys_state <= MA_RTC_S1;
          end        
      end
    MA_RTC_S1:  //to prepare for SJA send 
      begin
        CAN_start_flag <= 1'b1;
//        TX_frame_info <= 8'b00001000;     //no change
        TX_Id1 <= {1'b1,ID_F1,2'b11};    //change ID_F1/ID_F1/ID_F3/ID_F4
        TX_Id2 <= 8'b10100000;            //no change
        TX_D1 <= 8'h27;                   //no change
        TX_D2 <= 8'h70;
        TX_D3 <= Cor_Com_Cnt_A;         //correct command count for CANA
        TX_D4 <= Cor_Com_Cnt_B;         //correct command count for CANB   
        TX_D5 <= Inv_Com_Cnt_A;         //invalid command cnt for CANA
        TX_D6 <= Inv_Com_Cnt_B;         //invalid command cnt for CANB
        TX_D7 <= 8'hFF;         //invalid command state for CANB
        TX_D8 <= Selftest_Sta;                //slef test state  flag    
        Mes_Analys_state <= SUM_S1;
      end
    SUM_S1:
      begin
        Sum_Check <= TX_D1 + TX_D2 + TX_D3 + TX_D4 + TX_D5 + TX_D6 + TX_D7 + TX_D8;       
        Mes_Analys_state <= MA_RTC_S1_HOLD;
      end
    MA_RTC_S1_HOLD: //hold for send finish 
      begin
        if(CAN_finish_flag)
          begin
            CAN_start_flag <= 1'b0;
            Mes_Analys_state <= MA_RTC_S2;
          end
        else begin
            CAN_start_flag <= 1'b1;
            Mes_Analys_state <= MA_RTC_S1_HOLD;
        end
      end
    MA_RTC_S2:  //to prepare for SJA send 
      begin
        CAN_start_flag <= 1'b1;
//        TX_frame_info <= 8'b00001000;     //no change  
        TX_Id1 <= {1'b1,ID_F1,2'b11};    //change ID_F1/ID_F1/ID_F3/ID_F4
        TX_Id2 <= 8'b11000000;            //no change
        TX_D1 <= TXE_Cnt_A; 
        TX_D2 <= RXE_Cnt_A;
        TX_D3 <= TXE_Cnt;
        TX_D4 <= RXE_Cnt;
        TX_D5 <= Reset_CANA_Cnt;
        TX_D6 <= Reset_CANB_Cnt;
        TX_D7 <= Motor_Consumption_CAN[15:8];     //byte 1 of fw power
        TX_D8 <= Motor_Consumption_CAN[7:0];      // byte 2 of fw power
        Mes_Analys_state <= SUM_S2;
      end
    SUM_S2:
      begin
        Sum_Check <= Sum_Check + TX_D1 + TX_D2 + TX_D3 + TX_D4 + TX_D5 + TX_D6 + TX_D7 + TX_D8;       
        Mes_Analys_state <= MA_RTC_S2_HOLD;
      end
    MA_RTC_S2_HOLD: //hold for send finish 
      begin
        if(CAN_finish_flag)
          begin
            CAN_start_flag <= 1'b0;
            Mes_Analys_state <= MA_RTC_S3;
          end
        else begin
            CAN_start_flag <= 1'b1;
            Mes_Analys_state <= MA_RTC_S2_HOLD;
        end
      end
    MA_RTC_S3:  //to prepare for SJA send 
      begin
        CAN_start_flag <= 1'b1;
//        TX_frame_info <= 8'b00001000;     //no change  
        TX_Id1 <= {1'b1,ID_F1,2'b11};    //change ID_F1/ID_F1/ID_F3/ID_F4
        TX_Id2 <= 8'b11000000;            //no change
        TX_D1 <= Motor_Speed_CAN[31:24];    //byte 1 of speed
        TX_D2 <= Motor_Speed_CAN[23:16];    //byte 2 of speed         
        TX_D3 <= Motor_Speed_CAN[15:8];    //byte 3 of speed         
        TX_D4 <= Motor_Speed_CAN[7:0];    //byte 4 of speed
        TX_D5 <= Motor_Torque_CAN[31:24];   //byte 1 of Net_Torque
        TX_D6 <= Motor_Torque_CAN[23:16];   //byte 2 of Net_Torque
        TX_D7 <= Motor_Torque_CAN[15:8];   //byte 3 of Net_Torque
        TX_D8 <= Motor_Torque_CAN[7:0];   //byte 4 of Net_Torque 
/*        TX_D1 <= 8'h44;  //test(191227) 626.5
        TX_D2 <= 8'h1c;  //test(191213)
        TX_D3 <= 8'ha0;  //test(191213)
        TX_D4 <= 8'h00;  //test(191213)
        TX_D5 <= 8'h41;  //test(191213)
        TX_D6 <= 8'h96;  //test(191213)
        TX_D7 <= 8'h14;  //test(191213)
        TX_D8 <= 8'h7a;  //test(191213) */
        Mes_Analys_state <= SUM_S3;
      end
    SUM_S3:
      begin
        Sum_Check <= Sum_Check + TX_D1 + TX_D2 + TX_D3 + TX_D4 + TX_D5 + TX_D6 + TX_D7 + TX_D8;       
        Mes_Analys_state <= MA_RTC_S3_HOLD;
      end
    MA_RTC_S3_HOLD: //hold for send finish 
      begin
        if(CAN_finish_flag)
          begin
            CAN_start_flag <= 1'b0;
            Mes_Analys_state <= MA_RTC_S4;
          end
        else begin
            CAN_start_flag <= 1'b1;
            Mes_Analys_state <= MA_RTC_S3_HOLD;
        end
      end
    MA_RTC_S4:  //to prepare for SJA send 
      begin
        CAN_start_flag <= 1'b1;
//        TX_frame_info <= 8'b00001000;     //no change  
        TX_Id1 <= {1'b1,ID_F1,2'b11};    //change ID_F1/ID_F1/ID_F3/ID_F4
        TX_Id2 <= 8'b11000000;            //no change
        TX_D1 <= Motor_Currunt_CAN[15:8];       //byte 1 of current
        TX_D2 <= Motor_Currunt_CAN[7:0];        //byte 2 of current
        TX_D3 <= Motor_Temperate_CAN[15:8];     //byte 1 of temperate
        TX_D4 <= Motor_Temperate_CAN[7:0];      //byte 2 of temperate
        TX_D5 <= 8'h02;                         //valid 0x021a
        TX_D6 <= 8'h1A;                         //valid 0x021a
        TX_D7 <= Max_Torque_CAN[15:8];           //byte 1 of temperate
        TX_D8 <= Max_Torque_CAN[7:0];           //byte 2 of temperate  
        Mes_Analys_state <= SUM_S4;
      end
    SUM_S4:
      begin
        Sum_Check <= Sum_Check + TX_D1 + TX_D2 + TX_D3 + TX_D4 + TX_D5 + TX_D6 + TX_D7 + TX_D8;       
        Mes_Analys_state <= MA_RTC_S4_HOLD;
      end
    MA_RTC_S4_HOLD: //hold for send finish 
      begin
        if(CAN_finish_flag)
          begin
            CAN_start_flag <= 1'b0;
            Mes_Analys_state <= SUM_S5;
          end
        else begin
            CAN_start_flag <= 1'b1;
            Mes_Analys_state <= MA_RTC_S4_HOLD;
        end
      end
    SUM_S5:
      begin
        Sum_Check <= Sum_Check + Motor_Current_CMD[15:8] + Motor_Current_CMD[7:0] + Motor_Torque_CMD[31:24] + Motor_Torque_CMD[23:16] + Motor_Torque_CMD[15:8] + Motor_Torque_CMD[7:0];
//        Sum_Check <= Sum_Check;               
        Mes_Analys_state <= MA_RTC_S5;
		end
    MA_RTC_S5:  //to prepare for SJA send 
      begin
        CAN_start_flag <= 1'b1;
//        TX_frame_info <= 8'b00001000;     //no change  
        TX_Id1 <= {1'b1,ID_F1,2'b11};    //change ID_F1/ID_F1/ID_F3/ID_F4
        TX_Id2 <= 8'b11100000;            //no change
        TX_D1 <= Motor_Current_CMD[15:8];
        TX_D2 <= Motor_Current_CMD[7:0];
        TX_D3 <= Motor_Torque_CMD[31:24];
        TX_D4 <= Motor_Torque_CMD[23:16];
        TX_D5 <= Motor_Torque_CMD[15:8];
        TX_D6 <= Motor_Torque_CMD[7:0];
        TX_D7 <= 8'h00;
        TX_D8 <= Sum_Check;    
        Mes_Analys_state <= MA_RTC_S5_HOLD;
      end
    MA_RTC_S5_HOLD: //hold for send finish 
      begin
        if(CAN_finish_flag)
          begin
            CAN_start_flag <= 1'b0;
            Mes_Analys_state <= MA_IDLE;
          end
        else begin
            CAN_start_flag <= 1'b1;
            Mes_Analys_state <= MA_RTC_S5_HOLD;
        end
      end    
    MA_SMT:
      begin
        if({RX_D6,RX_D7,RX_D8} != 24'b0)
          begin
//            Inv_Com_Sta_B <= 8'h03;     //command data error
            Inv_Com_Cnt_B <= Inv_Com_Cnt_B + 1'b1;
            Mes_Analys_state <= MA_IDLE;            
          end
        else 
          begin
            Cor_Com_Cnt_B <= Cor_Com_Cnt_B + 1'b1;
            Max_Torque_B <= {RX_D2,RX_D3,RX_D4,RX_D5};
            Mes_Analys_state <= MA_CMD_1;
            CMD_State <= 4'b0001;   //set max torque state
          end   
      end
    MA_SWS:
      begin
        if({RX_D6,RX_D7,RX_D8} != 24'b0)
          begin
//            Inv_Com_Sta_B <= 8'h03;     //command data error
            Inv_Com_Cnt_B <= Inv_Com_Cnt_B + 1'b1;
            Mes_Analys_state <= MA_IDLE;            
          end
        else 
          begin
            Cor_Com_Cnt_B <= Cor_Com_Cnt_B + 1'b1;
            Speed_CMD_B <= {RX_D2,RX_D3,RX_D4,RX_D5};
            Mes_Analys_state <= MA_CMD_1;
            CMD_State <= 4'b0010;   //set wheel speed state
          end 
      end
    MA_SWC:
      begin
        if({RX_D4,RX_D5,RX_D6,RX_D7,RX_D8} != 24'b0)
          begin
//            Inv_Com_Sta_B <= 8'h03;     //command data error
            Inv_Com_Cnt_B <= Inv_Com_Cnt_B + 1'b1;
            Mes_Analys_state <= MA_IDLE;            
          end
        else 
          begin
            Cor_Com_Cnt_B <= Cor_Com_Cnt_B + 1'b1;
            Current_CMD_B <= {RX_D2,RX_D3};
            Mes_Analys_state <= MA_CMD_1;
            CMD_State <= 4'b0011;   //set wheel currunt state
          end 
      end
    MA_SNT:
      begin
        if({RX_D6,RX_D7,RX_D8} != 24'b0)
          begin
//            Inv_Com_Sta_B <= 8'h03;     //command data error
            Inv_Com_Cnt_B <= Inv_Com_Cnt_B + 1'b1;
            Mes_Analys_state <= MA_IDLE;            
          end
        else 
          begin
            Cor_Com_Cnt_B <= Cor_Com_Cnt_B + 1'b1;
            Tor_Com_Cnt_B <= Tor_Com_Cnt_B + 1'b1;
            Net_Torque_CMD_B <= {RX_D2,RX_D3,RX_D4,RX_D5};
            Mes_Analys_state <= MA_CMD_1;
            CMD_State <= 4'b0100;   //set net torque state
          end 
      end
    MA_CR:
      begin
        if({RX_D2[7:2],RX_D3,RX_D4,RX_D5,RX_D6,RX_D7,RX_D8} != 54'b0)
          begin
//            Inv_Com_Sta_B <= 8'h03;     //command data error
            Inv_Com_Cnt_B <= Inv_Com_Cnt_B + 1'b1;
            Mes_Analys_state <= MA_IDLE;            
          end
        else 
          begin
            Cor_Com_Cnt_B <= Cor_Com_Cnt_B + 1'b1;
            CR_CMD_B <= RX_D2[1:0];
            Mes_Analys_state <= MA_CMD_1;
            CMD_State <= 4'b1000;   //set communation reset state
          end 
      end
    MA_CMD_1:
      begin
        CMD_Start_Flag <= 1'b1; 
        Mes_Analys_state <= MA_CMD_2;
      end
    MA_CMD_2:
      begin
        if(CMD_Finish_Flag)
          begin
            CMD_Start_Flag <= 1'b0;
            CMD_State <= 4'b0000;
            Mes_Analys_state <= MA_IDLE;
          end
        else begin
          CMD_Start_Flag <= 1'b1; 
          Mes_Analys_state <= MA_CMD_2;
        end
      end
    default:
      Mes_Analys_state <= MA_IDLE;
    endcase
  end



assign Reset_CANB_Cnt = Reset_CANB_Cnt_r - 1'b1;  // power up 1 


WR_RD_SJ WR_RD_SJ_0(
      .write_read_en(write_read_en),   // flag to start write/read operation, 10 - write, 01 - read
      .finish_flag(finish_flag),  // write/read operation end flag,1 - finish
      .clk(clk),
      .rst_n(rst_n),
      .addr(addr),
      .data_2_sj(data_2_sj),
      .data_4_sj(data_4_sj),
      .SJ_AD(SJ_AD),
      .SJ_out_en(SJA_Dir),
      .SJ_ALE(SJ_ALE),
      .SJ_CS_n(SJ_CS_n),
      .SJ_RD_n(SJ_RD_n),
      .SJ_WR_n(SJ_WR_n)
    );


endmodule