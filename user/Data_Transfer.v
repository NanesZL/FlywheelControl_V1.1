///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: Data_Transfer.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::ProASIC3> <Die::A3P1000> <Package::144 FBGA>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module Data_Transfer( DF_clk, DF_rst, ram2DF_data, DF2ram_data, DF2ram_addr, 
                      DF2ram_RW, Speed_Dir, sv_h, time_sv, Speed_Value, Torque_Dir, AD_Torque,start_flag, 
                      AD_Current_0, AD_R_V, Inv_Com_Cnt_B,
                      Cor_Com_Cnt_B, Tor_Com_Cnt_B, RXE_Cnt, TXE_Cnt, Reset_CANB_Cnt,
                      CMD_Finish_Flag, CMD_Start_Flag,CMD_State,SJA_rst_en,Max_Torque_B,Speed_CMD_B,Current_CMD_B,Net_Torque_CMD_B,
                      CR_CMD_B,Inv_Com_Cnt_A,Cor_Com_Cnt_A,RXE_Cnt_A,TXE_Cnt_A,Reset_CANA_Cnt,Selftest_Sta,Motor_Consumption_CAN,
                      Motor_Speed_CAN,Motor_Torque_CAN,Motor_Currunt_CAN,Motor_Temperate_CAN,Max_Torque_CAN,Motor_Torque_CMD,
                      Motor_Current_CMD,BrakeMode,Insert_Data);
input DF_clk, DF_rst, Speed_Dir;
input [15:0]ram2DF_data;
input [30:0]Speed_Value;
input [11:0]AD_Current_0,AD_R_V;
input [31:0]sv_h;
input [30:0] time_sv;
input CMD_Start_Flag;
input [3:0] CMD_State;
input [1:0] BrakeMode;
output reg  CMD_Finish_Flag;
output reg  [15:0]DF2ram_data;
output reg  [7:0]DF2ram_addr;
output reg  DF2ram_RW;
output reg  Torque_Dir;
output reg  start_flag;

input [31:0] Max_Torque_B, Speed_CMD_B, Net_Torque_CMD_B;
input [15:0] Current_CMD_B;
input [1:0] CR_CMD_B; 

////////////CANB///////////////////
input  [7:0]Inv_Com_Cnt_B;     //invalid command cnt for CANB
input  [7:0]Cor_Com_Cnt_B;     //correct command cnt for CANB
input  [7:0]Tor_Com_Cnt_B;     //torque command cnt for CANB
input  [7:0] RXE_Cnt;          //RXE register for CANB
input  [7:0] TXE_Cnt;          //TXE register for CANB 
input  [7:0] Reset_CANB_Cnt;   //Reset of CANB cnt
////////////CANA///////////////////
output reg [7:0]Inv_Com_Cnt_A;     //invalid command cnt for CANA
output reg [7:0]Cor_Com_Cnt_A;     //correct command cnt for CANA
output reg [7:0] RXE_Cnt_A;          //RXE register for CANA
output reg [7:0] TXE_Cnt_A;          //TXE register for CANA 
output reg [7:0] Reset_CANA_Cnt;    //Reset of CANA cnt
output reg [7:0] Selftest_Sta;      //self test state from DSP
output reg [15:0] Motor_Consumption_CAN; //Motor_Consumption from DSP
output reg [31:0] Motor_Speed_CAN;    //speed of float from DSP
output reg [31:0] Motor_Torque_CAN;   //torque of float from DSP
output reg [15:0] Motor_Currunt_CAN;  //currunt from DSP
output reg [15:0] Motor_Temperate_CAN;  //motor temperate from DSP 
output reg [15:0] Max_Torque_CAN;     //max torque from DSP
output reg [31:0] Motor_Torque_CMD;   //motor torque command 
output reg [15:0] Motor_Current_CMD;  //motor currunt command

output reg [11:0] AD_Torque;          //current calculate from DSP
output SJA_rst_en;                   //SJA_rst_en once at first power up ,then...
output reg [11:0] Insert_Data;

reg [7:0] present_state; 
reg  rst_en;
reg [7:0]Mode_Tor_Flag;
reg [7:0]Tor_Com_Cnt_A; //torque command cnt for CANA
reg [15:0] Cycle_Start_1, Cycle_Start_2;
reg [5:0] data2dram_1;
reg [11:0] data2dram_8, data2dram_9;
reg [15:0] data2dram_2, data2dram_3, data2dram_4, data2dram_5, data2dram_6, data2dram_7;
reg [7:0] data2dram_a, data2dram_b, data2dram_c, data2dram_d, data2dram_e;
reg [7:0] CANB_Reset_Command;
reg [15:0] data_count;
reg [15:0] CMD_Data_1, CMD_Data_2;
reg [7:0] CMD_Data_3;
reg [7:0] CMD_Add_1, CMD_Add_2, CMD_Add_3;

parameter ST_idle = 8'd0, ST_1 = 8'd1,  ST_2 = 8'd2,   ST_3 = 8'd3,   ST_4 = 8'd4,   ST_5 = 8'd5,   ST_6 = 8'd6,   ST_7 = 8'd7,
          ST_8  = 8'd8  ,ST_9  = 8'd9  ,ST_10 = 8'd10 ,ST_11 = 8'd11 ,ST_12 = 8'd12 ,ST_13 = 8'd13 ,ST_14 = 8'd14 ,ST_15 = 8'd15,
          ST_16 = 8'd16 ,ST_17 = 8'd17 ,ST_18 = 8'd18 ,ST_19 = 8'd19 ,ST_20 = 8'd20 ,ST_21 = 8'd21 ,ST_22 = 8'd22 ,ST_23 = 8'd23,
          ST_24 = 8'd24 ,ST_25 = 8'd25 ,ST_26 = 8'd26 ,ST_27 = 8'd27 ,ST_28 = 8'd28 ,ST_29 = 8'd29 ,ST_30 = 8'd30 ,ST_31 = 8'd31,
          ST_32 = 8'd32 ,ST_33 = 8'd33 ,ST_34 = 8'd34 ,ST_35 = 8'd35 ,ST_36 = 8'd36 ,ST_37 = 8'd37 ,ST_38 = 8'd38 ,ST_39 = 8'd39,
          ST_40 = 8'd40 ,ST_41 = 8'd41 ,ST_42 = 8'd42 ,ST_43 = 8'd43 ,ST_44 = 8'd44 ,ST_45 = 8'd45 ,ST_46 = 8'd46 ,ST_47 = 8'd47,
          ST_48 = 8'd48 ,ST_49 = 8'd49 ,ST_50 = 8'd50 ,ST_51 = 8'd51 ,ST_52 = 8'd52 ,ST_53 = 8'd53 ,ST_54 = 8'd54 ,ST_55 = 8'd55,
          ST_56 = 8'd56 ,ST_57 = 8'd57 ,ST_58 = 8'd58 ,ST_59 = 8'd59 ,ST_60 = 8'd60 ,ST_61 = 8'd61 ,ST_62 = 8'd62 ,ST_63 = 8'd63,
          ST_64 = 8'd64 ,ST_65 = 8'd65 ,ST_66 = 8'd66 ,ST_67 = 8'd67 ,ST_68 = 8'd68 ,ST_69 = 8'd69 ,ST_70 = 8'd70 ,ST_71 = 8'd71,
          ST_72 = 8'd72 ,ST_73 = 8'd73 ,ST_74 = 8'd74 ,ST_75 = 8'd75 ,ST_76 = 8'd76 ,ST_77 = 8'd77 ,ST_78 = 8'd78 ,ST_79 = 8'd79,
          ST_80 = 8'd80 ,ST_81 = 8'd81 ,ST_82 = 8'd82 ,ST_83 = 8'd83 ,ST_84 = 8'd84 ,ST_85 = 8'd85 ,ST_86 = 8'd86 ,ST_87 = 8'd87,
          ST_88 = 8'd88 ,ST_89 = 8'd89 ,ST_90 = 8'd90 ,ST_91 = 8'd91 ,ST_92 = 8'd92;


reg [7:0] next_state;


reg [11:0] count;
reg [2:0] Start_state;
reg DF_start;
reg NR2_Start_Flag;   //no receiece for 2s operate start
reg NR10_Start_Flag;   //no receiece for 2s operate start
//reg [15:0]NR2_Data,NR10_Data;
reg [3:0]NR2_Data,NR10_Data;
reg [7:0]NR2_Add,NR10_Add;
reg NR2_Finish_Flag,NR10_Finish_Flag;
always @ (posedge DF_clk or negedge DF_rst)
 if(!DF_rst)
    begin
      Start_state <= 3'b000;
      count <= 12'd0;
      DF_start <= 1'b0;
    end
  else begin
  case(Start_state)
  3'b000:
    begin
      Start_state <= 3'b001;
      count <= 16'd0;
      DF_start <= 1'b0;
    end
  3'b001:
    begin
      DF_start <= 1'b0;
//      if(count >= 12'd195)
      if(count >= 12'd1495)   
        Start_state <= 3'b010;
      else 
        begin
        Start_state <= 3'b001;
        count <= count + 1'b1;
        end 
    end
  3'b010:
    begin
      DF_start <= 1'b1;
//      if (count >= 16'd199)
      if (count >= 12'd1499)  //50us
        begin
        Start_state <= 3'b001;
        count <= 12'd0;
        end
      else begin
        Start_state <= 3'b010;
        count <= count + 1'b1;
      end
    end
  default:
    begin
      Start_state <= 3'b000;
      count <= 12'd0;
      DF_start <= 1'b0;
    end 
  endcase

  end




always @ (posedge DF_clk or negedge DF_rst)
 if(!DF_rst)
   begin
   next_state <= ST_idle; 
  end
 else
    begin 
      case(present_state)
        ST_idle:if(DF_start)                next_state <= ST_1; //wait for start
                else                        next_state <= ST_idle;
        ST_1:  if(data_count >= 16'd4)      next_state <= ST_2;   else  next_state <= ST_1;
        ST_2:  if(data_count >= 16'd8)      next_state <= ST_3;   else  next_state <= ST_2;
        ST_3:   if(data_count >= 16'd12)    next_state <= ST_4;   else  next_state <= ST_3;
        ST_4:   if(data_count >= 16'd16)    next_state <= ST_5;   else  next_state <= ST_4;
        ST_5:   if(data_count >= 16'd20)    next_state <= ST_6;   else  next_state <= ST_5;       
        ST_6:   if(data_count >= 16'd24)    next_state <= ST_7;   else  next_state <= ST_6;   
        ST_7:   if(data_count >= 16'd28)    next_state <= ST_8;   else  next_state <= ST_7; 
        ST_8:   if(data_count >= 16'd32)    next_state <= ST_9;   else  next_state <= ST_8; 
        ST_9:   if(data_count >= 16'd36)    next_state <= ST_10;  else  next_state <= ST_9;
        ST_10:  if(data_count >= 16'd40)    next_state <= ST_11;  else  next_state <= ST_10;
        ST_11:  if(data_count >= 16'd44)    next_state <= ST_12;  else  next_state <= ST_11; 
        ST_12:  if(data_count >= 16'd48)    next_state <= ST_13;  else  next_state <= ST_12; 
        ST_13:  if(data_count >= 16'd52)    next_state <= ST_14;  else  next_state <= ST_13; 
        ST_14:  if(data_count >= 16'd56)    next_state <= ST_15;  else  next_state <= ST_14; 
        ST_15:  if(data_count >= 16'd60)    next_state <= ST_16;  else  next_state <= ST_15; 
        ST_16:  if(data_count >= 16'd64)    next_state <= ST_17;  else  next_state <= ST_16; 
        ST_17:  if(data_count >= 16'd68)    next_state <= ST_18;  else  next_state <= ST_17; 
        ST_18:  if(data_count >= 16'd72)    next_state <= ST_19;  else  next_state <= ST_18; 
        ST_19:  if(data_count >= 16'd76)    next_state <= ST_20;  else  next_state <= ST_19;
        ST_20:  if(data_count >= 16'd80)    next_state <= ST_21;  else  next_state <= ST_20; 
        ST_21:  if(data_count >= 16'd84)    next_state <= ST_22;  else  next_state <= ST_21;
        ST_22:  if(data_count >= 16'd88)    next_state <= ST_23;  else  next_state <= ST_22; 
        ST_23:  if(data_count >= 16'd92)    next_state <= ST_24;  else  next_state <= ST_23; 
        ST_24:  if(data_count >= 16'd96)    next_state <= ST_25;  else  next_state <= ST_24;
        ST_25:  if(data_count >= 16'd100)   next_state <= ST_26;  else  next_state <= ST_25; 
        ST_26:  if(data_count >= 16'd104)   next_state <= ST_27;  else  next_state <= ST_26; 
        ST_27:  if(data_count >= 16'd108)   next_state <= ST_28;  else  next_state <= ST_27; 
        ST_28:  if(data_count >= 16'd112)   next_state <= ST_29;  else  next_state <= ST_28; 
        ST_29:  if(data_count >= 16'd116)   next_state <= ST_30;  else  next_state <= ST_29; 
        ST_30:  if(data_count >= 16'd120)   next_state <= ST_31;  else  next_state <= ST_30; 
        ST_31:  if(data_count >= 16'd124)   next_state <= ST_32;  else  next_state <= ST_31; 
        ST_32:  if(data_count >= 16'd128)   next_state <= ST_33;  else  next_state <= ST_32; 
        ST_33:  if(data_count >= 16'd132)   next_state <= ST_34;  else  next_state <= ST_33; 
        ST_34:  if(data_count >= 16'd136)   next_state <= ST_35;  else  next_state <= ST_34; 
        ST_35:  if(data_count >= 16'd140)   next_state <= ST_36;  else  next_state <= ST_35; 
        ST_36:  if(data_count >= 16'd144)   next_state <= ST_37;  else  next_state <= ST_36; 
        ST_37:  if(data_count >= 16'd148)   next_state <= ST_38;  else  next_state <= ST_37; 
        ST_38:  if(data_count >= 16'd152)   next_state <= ST_39;  else  next_state <= ST_38; 
        ST_39:  if(data_count >= 16'd156)   next_state <= ST_40;  else  next_state <= ST_39; 
        ST_40:  if(data_count >= 16'd160)   next_state <= ST_41;  else  next_state <= ST_40; 
        ST_41:  if(data_count >= 16'd164)   next_state <= ST_42;  else  next_state <= ST_41; 
        ST_42:  if(data_count >= 16'd168)   next_state <= ST_43;  else  next_state <= ST_42; 
        ST_43:  if(data_count >= 16'd172)   next_state <= ST_44;  else  next_state <= ST_43; 
        ST_44:  if(data_count >= 16'd176)   next_state <= ST_45;  else  next_state <= ST_44; 
        ST_45:  if(data_count >= 16'd180)   next_state <= ST_46;  else  next_state <= ST_45; 
        ST_46:  if(data_count >= 16'd184)   next_state <= ST_47;  else  next_state <= ST_46; 
        ST_47:  if(data_count >= 16'd188)   next_state <= ST_48;  else  next_state <= ST_47; 
        ST_48:  if(data_count >= 16'd192)   next_state <= ST_49;  else  next_state <= ST_48; 
        ST_49:  if(data_count >= 16'd196)   next_state <= ST_50;  else  next_state <= ST_49; 
        ST_50:  if(data_count >= 16'd200)   next_state <= ST_51;  else  next_state <= ST_50; 
        ST_51:  if(data_count >= 16'd204)   next_state <= ST_52;  else  next_state <= ST_51; 
        ST_52:  if(data_count >= 16'd208)   next_state <= ST_53;  else  next_state <= ST_52; 
        ST_53:  if(data_count >= 16'd212)   next_state <= ST_54;  else  next_state <= ST_53; 
        ST_54:  if(data_count >= 16'd216)   next_state <= ST_55;  else  next_state <= ST_54; 
        ST_55:  if(data_count >= 16'd220)   next_state <= ST_56;  else  next_state <= ST_55; 
        ST_56:  if(data_count >= 16'd224)   next_state <= ST_57;  else  next_state <= ST_56; 
        ST_57:  if(data_count >= 16'd228)   next_state <= ST_58;  else  next_state <= ST_57; 
        ST_58:  if(data_count >= 16'd232)   next_state <= ST_59;  else  next_state <= ST_58; 
        ST_59:  if(data_count >= 16'd236)   next_state <= ST_60;  else  next_state <= ST_59; 
        ST_60:  if(data_count >= 16'd240)   next_state <= ST_61;  else  next_state <= ST_60; 
        ST_61:  if(data_count >= 16'd244)   next_state <= ST_62;  else  next_state <= ST_61; 
        ST_62:  if(data_count >= 16'd248)   next_state <= ST_63;  else  next_state <= ST_62; 
        ST_63:  if(data_count >= 16'd252)   next_state <= ST_64;  else  next_state <= ST_63;          
        ST_64:  if(data_count >= 16'd256)   next_state <= ST_65;  else  next_state <= ST_64; 
        ST_65:  if(data_count >= 16'd260)   next_state <= ST_66;  else  next_state <= ST_65; 
        ST_66:  if(data_count >= 16'd264)   next_state <= ST_67;  else  next_state <= ST_66; 
        ST_67:  if(data_count >= 16'd268)   next_state <= ST_68;  else  next_state <= ST_67; 
        ST_68:  if(data_count >= 16'd272)   next_state <= ST_69;  else  next_state <= ST_68; 
        ST_69:  if(data_count >= 16'd276)   next_state <= ST_70;  else  next_state <= ST_69; 
        ST_70:  if(data_count >= 16'd280)   next_state <= ST_71;  else  next_state <= ST_70;
        ST_71:  if(data_count >= 16'd284)   next_state <= ST_72;  else  next_state <= ST_71; 
        ST_72:  if(CMD_Start_Flag)          next_state <= ST_73;  else  next_state <= ST_79; 
        ST_73:  if(data_count >= 16'd288)   next_state <= ST_74;  else  next_state <= ST_73; 
        ST_74:  if(data_count >= 16'd292)   next_state <= ST_75;  else  next_state <= ST_74; 
        ST_75:  if(data_count >= 16'd296)   next_state <= ST_76;  else  next_state <= ST_75; 
        ST_76:  if(data_count >= 16'd300)   next_state <= ST_77;  else  next_state <= ST_76; 
        ST_77:  if(data_count >= 16'd304)   next_state <= ST_78;  else  next_state <= ST_77; 
        ST_78:  if(data_count >= 16'd308)   next_state <= ST_79;  else  next_state <= ST_78;         
        ST_79:  next_state <= ST_80; 
        ST_80:  if(data_count >= 16'd312)   next_state <= ST_81;  else  next_state <= ST_80; 
        ST_81:  if(data_count >= 16'd316)   next_state <= ST_82;  else  next_state <= ST_81;         
        ST_82:  next_state <= ST_83;
        ST_83:  if(data_count >= 16'd320)   next_state <= ST_84;  else  next_state <= ST_83; 
        ST_84:  if(data_count >= 16'd324)   next_state <= ST_85;  else  next_state <= ST_84;        
        ST_85:  if(data_count >= 16'd328)   next_state <= ST_86;  else  next_state <= ST_85; 
        ST_86:  if(data_count >= 16'd332)   next_state <= ST_87;  else  next_state <= ST_86; 
        ST_87:  if(data_count >= 16'd336)   next_state <= ST_88;  else  next_state <= ST_87; 
        ST_88:  if(data_count >= 16'd340)   next_state <= ST_89;  else  next_state <= ST_88; 
        ST_89:  if(data_count >= 16'd344)   next_state <= ST_90;  else  next_state <= ST_89;
        ST_90:  if(data_count >= 16'd348)   next_state <= ST_91;  else  next_state <= ST_90;
        ST_91:  if(data_count >= 16'd352)   next_state <= ST_92;  else  next_state <= ST_91;
        ST_92:  if(data_count >= 16'd356)   next_state <= ST_idle;  else  next_state <= ST_92; 
        default:next_state <= ST_idle; 
      endcase
  end 

always @ (posedge DF_clk or negedge DF_rst)
  if(!DF_rst)
    begin
      Insert_Data <= 12'd0;
      data_count  <= 16'd0;
      DF2ram_RW   <= 1'b1;
      CMD_Finish_Flag <= 1'b0;
      Cor_Com_Cnt_A <= 8'd0;
      Tor_Com_Cnt_A <= 8'd0;
      Inv_Com_Cnt_A <= 8'd0;
      Mode_Tor_Flag <= 8'd0;
      TXE_Cnt_A <= 8'd0;
      RXE_Cnt_A <= 8'd0;
      Reset_CANA_Cnt <= 8'd0;
      Selftest_Sta <= 8'd0;
      Motor_Consumption_CAN <= 16'd0;
      Motor_Speed_CAN <= 32'd0;
      Motor_Torque_CAN <= 32'd0;
      Motor_Currunt_CAN <= 16'd0;
      Motor_Temperate_CAN <= 16'd0;
      Motor_Torque_CMD <= 32'd0;
      Motor_Current_CMD <= 16'd0;
      AD_Torque <= 12'd0;
      Torque_Dir <= 1'b0;
      Max_Torque_CAN <= 16'd0;
      Cycle_Start_1 <= 16'd0;
      Cycle_Start_2 <= 16'd0;
      CANB_Reset_Command <= 8'd0;
      data2dram_1 <= 6'd0; data2dram_2 <= 16'd0; data2dram_3 <= 16'd0; data2dram_4 <= 16'd0;
      data2dram_5 <= 16'd0; data2dram_6 <= 16'd0; data2dram_7 <= 16'd0; data2dram_8 <= 12'd0;
      data2dram_9 <= 12'd0; data2dram_a <= 8'd0; data2dram_b <= 8'd0; data2dram_c <= 8'd0;
      data2dram_d <= 8'd0; data2dram_e <= 8'd0;
      CMD_Data_1 <= 16'd0;  CMD_Data_2 <= 16'd0;  CMD_Data_3 <= 8'd0;
      CMD_Add_1 <= 8'd0;    CMD_Add_2 <= 8'd0;    CMD_Add_3 <= 8'd0;
      NR2_Data <= 4'd0;    NR10_Data <= 4'd0;   NR2_Add <= 8'd0;      NR10_Add <= 8'd0;
      NR2_Finish_Flag <= 1'b0;  NR10_Finish_Flag <= 1'b0; rst_en <= 1'b0;
  end
  else
    begin
      case(present_state)
        ST_idle: 
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= 16'd0;
            DF2ram_addr <= 8'h00;
          end
        ST_1:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h8f;
          end
        ST_2:  //read  Insert_Data from 0x8f
          begin
            Insert_Data <= ram2DF_data[11:0];
            data_count  <=  data_count + 1'b1; 
          end
        ST_3:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h80;
          end
        ST_4:  //read Tor_Com_Cnt_A and Cor_Com_Cnt_A from 0x80
          begin
            Tor_Com_Cnt_A  <=  ram2DF_data[15:8];
            Cor_Com_Cnt_A  <=  ram2DF_data[7:0];
            data_count  <=  data_count + 1'b1; 
          end
        ST_5:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h81;
          end
        ST_6:  //read Inv_Com_Cnt_A from 0x81
          begin
            Mode_Tor_Flag  <=  ram2DF_data[15:8];
            Inv_Com_Cnt_A  <=  ram2DF_data[7:0];
            data_count  <=  data_count + 1'b1; 
          end
        ST_7:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h82;
          end
        ST_8:  //read TXE_Cnt_A from 0x82
          begin
            TXE_Cnt_A  <=  ram2DF_data[7:0];
            data_count  <=  data_count + 1'b1; 
          end
        ST_9:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h83;
          end
        ST_10:  //read RXE_Cnt_A from 0x83
          begin
            RXE_Cnt_A  <=  ram2DF_data[7:0];
            data_count  <=  data_count + 1'b1; 
          end
        ST_11:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h84;
          end
        ST_12:  //read Reset_CANA_Cnt from 0x84
          begin
            Reset_CANA_Cnt  <=  ram2DF_data[7:0];
            data_count  <=  data_count + 1'b1; 
          end
        ST_13:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h85;
          end
        ST_14:  //read  Selftest_Sta from 0x85
          begin
            Selftest_Sta  <=  ram2DF_data[7:0];
            data_count  <=  data_count + 1'b1; 
          end
        ST_15:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h86;
          end
        ST_16:  //read  Motor_Consumption_CAN from 0x86
          begin
            Motor_Consumption_CAN  <=  ram2DF_data;
            data_count  <=  data_count + 1'b1; 
          end
        ST_17:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h87;
          end
        ST_18:  //read  Motor_Speed_CAN[15:0] from 0x87
          begin
            Motor_Speed_CAN[15:0]  <=  ram2DF_data;
            data_count  <=  data_count + 1'b1; 
          end
        ST_19:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h88;
          end
        ST_20:  //read  Motor_Speed_CAN[31:16] from 0x88
          begin
            Motor_Speed_CAN[31:16]  <=  ram2DF_data;
            data_count  <=  data_count + 1'b1; 
          end
        ST_21:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h89;
          end
        ST_22:  //read  Motor_Torque_CAN[15:0] from 0x89
          begin
            Motor_Torque_CAN[15:0]  <=  ram2DF_data;
            data_count  <=  data_count + 1'b1; 
          end
        ST_23:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h8a;
          end
        ST_24:  //read  Motor_Torque_CAN[31:16] from 0x8a
          begin
            Motor_Torque_CAN[31:16]  <=  ram2DF_data;
            data_count  <=  data_count + 1'b1; 
          end          
        ST_25:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h8b;
          end
        ST_26:  //read  Motor_Currunt_CAN from 0x8b
          begin
            Motor_Currunt_CAN <=  ram2DF_data;
            data_count  <=  data_count + 1'b1; 
          end
        ST_27:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h8c;
          end
        ST_28:  //read  Motor_Temperate_CAN from 0x8c
          begin
            Motor_Temperate_CAN  <=  ram2DF_data;
            data_count  <=  data_count + 1'b1; 
          end
        ST_29:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h8d;
          end
        ST_30:  //read  AD_Torque from 0x8d
          begin
            AD_Torque   <= ram2DF_data[11:0];
            Torque_Dir  <= ram2DF_data[12];
            data_count  <=  data_count + 1'b1; 
          end
        ST_31:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h8e;
          end
        ST_32:  //read  Max_Torque_CAN from 0x8e
          begin
            Max_Torque_CAN  <= ram2DF_data;
            data_count  <=  data_count + 1'b1; 
          end
        ST_33:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'hfe;
          end
        ST_34:  //read  Cycle_Start_1 from 0xfe
          begin
            Cycle_Start_1  <= ram2DF_data;
            data_count  <=  data_count + 1'b1; 
          end
        ST_35:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'hff;
          end
        ST_36:  //read  Cycle_Start_2 from 0xff
          begin
            Cycle_Start_2  <= ram2DF_data;
            data_count  <=  data_count + 1'b1; 
          end
        ST_37:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h48;
          end
        ST_38:  //read  CANB_Reset_Command from 0x48
          begin
            CANB_Reset_Command  <= ram2DF_data[7:0];
            data_count  <=  data_count + 1'b1; 
          end
        ST_39:  
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h48; 
            if(CANB_Reset_Command == 8'h0f)
              rst_en <= 1'b1; 
            else 
              rst_en <= 1'b0;
          end
        ST_40: //write 0x00 to 0x48 
          begin
            rst_en <= 1'b0;
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= 16'h0000;
          end
        ST_41:
          begin
            data2dram_1 <= {BrakeMode[1:0],Speed_Dir,Speed_Dir,Speed_Dir,Speed_Dir};
            data2dram_2 <= sv_h[15:0];
            data2dram_3 <= sv_h[31:16];
            data2dram_4 <= time_sv[15:0];
            data2dram_5 <= {1'b0,time_sv[30:16]};
            data2dram_6 <= Speed_Value[15:0];
            data2dram_7 <= {1'b0,Speed_Value[30:16]};
            data2dram_8 <= AD_Current_0;
            data2dram_9 <= AD_R_V;
            data2dram_a <= Cor_Com_Cnt_B; 
            data2dram_b <= Inv_Com_Cnt_B;
            data2dram_c <= TXE_Cnt;
            data2dram_d <= RXE_Cnt;
            data2dram_e <= Reset_CANB_Cnt;
            data_count  <= data_count + 1'b1;
          end
        ST_42:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h0F;           //start write operation
          end
        ST_43:   //write 0xAA to 0F
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= 16'h00AA;
          end        
        ST_44:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h01;
          end
        ST_45:   //write data1 to 01
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= {10'd0,data2dram_1};
          end
        ST_46:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h04;
          end
        ST_47:   //write data4 to 04
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= data2dram_4;
          end
        ST_48:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h05;
          end
        ST_49:   //write data5 to 05
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= data2dram_5;
          end
        ST_50:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h02;
          end
        ST_51:   //write data2 to 02
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= data2dram_2;
          end
        ST_52:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h03;
          end
        ST_53:   //write data3 to 03
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= data2dram_3;
          end
        ST_54:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h06;
          end
        ST_55:   //write data6 to 06
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= data2dram_6;
          end
        ST_56:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h07;
          end
        ST_57:   //write data7 to 07
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= data2dram_7;
          end
        ST_58:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h08;
          end
        ST_59:   //write data8 to 08
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= {4'd0,data2dram_8};
          end
        ST_60:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h09;
          end
        ST_61:   //write data9 to 09
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= {4'd0,data2dram_9};
          end
        ST_62:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h0a;
          end
        ST_63:   //write dataa to 0a
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= {8'd0,data2dram_a};
          end
        ST_64:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h0b;
          end
        ST_65:   //write datab to 0b
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= {8'd0,data2dram_b};
          end
        ST_66:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h0c;
          end
        ST_67:   //write datac to 0c
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= {8'd0,data2dram_c};
          end
        ST_68:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h0d;
          end
        ST_69:   //write datad to 0d
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= {8'd0,data2dram_d};
          end
        ST_70:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h0e;
          end
        ST_71:   //write datae to 0e
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= {8'd0,data2dram_e};
          end
        ST_72 :  //to get CMD_Data and CMD_Add
          begin
            DF2ram_RW  <= 1'b1;
            if(CMD_Start_Flag)
              case(CMD_State) 
                4'b0001:
                  begin
                    CMD_Data_1 <= Max_Torque_B[31:16];
                    CMD_Data_2 <= Max_Torque_B[15:0];
                    CMD_Data_3 <= 8'h00; //no use data
                    CMD_Add_1 <=  8'h40;
                    CMD_Add_2 <=  8'h41;
                    CMD_Add_3 <=  8'h3f;    //no use address
                  end 
                4'b0010:
                  begin
                    CMD_Data_1 <= Speed_CMD_B[31:16];
                    CMD_Data_2 <= Speed_CMD_B[15:0];
                    CMD_Data_3 <= 8'h55; 
                    CMD_Add_1 <=  8'h42;
                    CMD_Add_2 <=  8'h43;
                    CMD_Add_3 <=  8'h46;                       
                  end
                4'b0011:
                  begin
                    CMD_Data_1 <= Current_CMD_B;
                    CMD_Data_2 <= 16'h0000; //no use data;
                    CMD_Data_3 <= 8'h77; 
                    CMD_Add_1 <=  8'h4A;
                    CMD_Add_2 <=  8'h3f;    //no use data;
                    CMD_Add_3 <=  8'h46; 
                  end
                4'b0100:
                  begin
                    CMD_Data_1 <= Net_Torque_CMD_B[31:16];
                    CMD_Data_2 <= Net_Torque_CMD_B[15:0];
                    CMD_Data_3 <= 8'hAA; 
                    CMD_Add_1 <=  8'h44;
                    CMD_Add_2 <=  8'h45;
                    CMD_Add_3 <=  8'h46;  
                  end
                4'b1000:
                  begin
                    if(CR_CMD_B[0] == 1'b1) //receive command to reset CANA
                      begin
                        CMD_Data_1 <= 16'h000f;
                        CMD_Data_2 <= 16'h0000; //no use data
                        CMD_Data_3 <= 8'h00; //no use data 
                        CMD_Add_1 <=  8'h47;
                        CMD_Add_2 <=  8'h3e;
                        CMD_Add_3 <=  8'h3d;
                      end
                    else begin
                        CMD_Data_1 <= 16'h0000; //no use data
                        CMD_Data_2 <= 16'h0000; //no use data
                        CMD_Data_3 <= 8'h00; //no use data 
                        CMD_Add_1 <=  8'h3a;
                        CMD_Add_2 <=  8'h3b;
                        CMD_Add_3 <=  8'h3c;
                    end
                    if(CR_CMD_B[1] == 1'b1) //receive command to reset CANB
                        rst_en <= 1'b1;  
                    else
                        rst_en <= 1'b0;            
                  end
                default:
                  begin
                    CMD_Data_1 <= 16'h0000; //no use data
                    CMD_Data_2 <= 16'h0000; //no use data
                    CMD_Data_3 <= 8'h00; //no use data 
                    CMD_Add_1 <=  8'h3a;
                    CMD_Add_2 <=  8'h3b;
                    CMD_Add_3 <=  8'h3c;
                  end
                endcase         
          end
        ST_73:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= CMD_Add_1;
          end
        ST_74:   //write CMD_Data_1 to CMD_Add_1
          begin
            rst_en <= 1'b0; //rst_en of CANB for n clks
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= CMD_Data_1;
          end
        ST_75:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= CMD_Add_2;
          end
        ST_76:   //write CMD_Data_2 to CMD_Add_2
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= CMD_Data_2;
          end
        ST_77:
          begin
            DF2ram_RW   <= 1'b1;
            CMD_Finish_Flag <= 1'b1;  //CMD write operation finish = 1 for 4 clks
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= CMD_Add_3;
          end
        ST_78:   //write CMD_Data_3 to CMD_Add_3
          begin
            DF2ram_RW   <= 1'b0;
            CMD_Finish_Flag <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= {8'h00,CMD_Data_3};
          end
        ST_79 :  //to get NR2_Data and NR2_Add
          begin
            rst_en <= 1'b0;
            DF2ram_RW  <= 1'b1;
            if(NR2_Start_Flag)
              begin
                NR2_Data <= 4'hf;
                NR2_Add  <= 8'h49;
              end
            else begin
                NR2_Data <= 4'h0; //no use data
                NR2_Add  <= 8'h39;
              end
          end
        ST_80:
          begin
            NR2_Finish_Flag <= 1'b1;  //CMD write operation finish = 1 for 4 clks
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= NR2_Add;
          end
        ST_81:   //write NR2_Data to NR2_Add
          begin
            NR2_Finish_Flag <= 1'b0;  
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= {12'd0,NR2_Data};
          end
        ST_82 :  //to get NR10_Data and NR10_Add
          begin
            DF2ram_RW  <= 1'b1;
            if(NR10_Start_Flag)
              begin
                rst_en <= 1'b1;
                NR10_Data <= 4'hf;
                NR10_Add  <= 8'h47;
              end
            else begin
                rst_en <= 1'b0;
                NR10_Data <= 4'h0; //no use data
                NR10_Add  <= 8'h38;
              end
          end
        ST_83:
          begin
            rst_en <= 1'b0;
            NR10_Finish_Flag <= 1'b1;  //CMD write operation finish = 1 for 4 clks
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= NR10_Add;
          end
        ST_84:   //write NR10_Data to NR10_Add
          begin
            NR10_Finish_Flag <= 1'b0;  
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= {12'd0,NR10_Data};
          end 
        ST_85:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h0F;           //finish write operation
          end
        ST_86:   //write 0x55 to 0F
          begin
            DF2ram_RW   <= 1'b0;
            data_count  <= data_count + 1'b1;
            DF2ram_data <= 16'h0055;
          end 
        ST_87:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h44;
          end
        ST_88:  //read  Motor_Torque_CMD[31:16] from 0x44
          begin
            Motor_Torque_CMD[31:16]  <= ram2DF_data;
            data_count  <=  data_count + 1'b1; 
          end
        ST_89:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h45;
          end
        ST_90:  //read  Motor_Torque_CMD[15:0] from 0x45
          begin
            Motor_Torque_CMD[15:0]  <= ram2DF_data;
            data_count  <=  data_count + 1'b1; 
          end
        ST_91:
          begin
            DF2ram_RW   <= 1'b1;
            data_count  <= data_count + 1'b1;
            DF2ram_addr <= 8'h4A;
          end
        ST_92:  //read  Motor_Current_CMD[15:0] from 0x4A
          begin
            Motor_Current_CMD[15:0] <= ram2DF_data;
            data_count  <=  data_count + 1'b1; 
          end
        default:
          begin
            Insert_Data <= 12'd0;
            data_count  <= 16'd0;
            DF2ram_RW   <= 1'b1;
            CMD_Finish_Flag <= 1'b0;
            Cor_Com_Cnt_A <= 8'd0;
            Tor_Com_Cnt_A <= 8'd0;
            Inv_Com_Cnt_A <= 8'd0;
            Mode_Tor_Flag <= 8'd0;
            TXE_Cnt_A <= 8'd0;
            RXE_Cnt_A <= 8'd0;
            Reset_CANA_Cnt <= 8'd0;
            Selftest_Sta <= 8'd0;
            Motor_Consumption_CAN <= 16'd0;
            Motor_Speed_CAN <= 32'd0;
            Motor_Torque_CAN <= 32'd0;
            Motor_Currunt_CAN <= 16'd0;
            Motor_Temperate_CAN <= 16'd0;
            Motor_Torque_CMD <= 32'd0;
            Motor_Current_CMD <= 16'd0;
            AD_Torque <= 12'd0;
            Torque_Dir <= 1'b0;
            Max_Torque_CAN <= 16'd0;
            Cycle_Start_1 <= 16'd0;
            Cycle_Start_2 <= 16'd0;
            CANB_Reset_Command <= 8'd0;
            data2dram_1 <= 6'd0; data2dram_2 <= 16'd0; data2dram_3 <= 16'd0; data2dram_4 <= 16'd0;
            data2dram_5 <= 16'd0; data2dram_6 <= 16'd0; data2dram_7 <= 16'd0; data2dram_8 <= 12'd0;
            data2dram_9 <= 12'd0; data2dram_a <= 8'd0; data2dram_b <= 8'd0; data2dram_c <= 8'd0;
            data2dram_d <= 8'd0; data2dram_e <= 8'd0;
            CMD_Data_1 <= 16'd0;  CMD_Data_2 <= 16'd0;  CMD_Data_3 <= 8'd0;
            CMD_Add_1 <= 8'd0;    CMD_Add_2 <= 8'd0;    CMD_Add_3 <= 8'd0;
            NR2_Data <= 4'd0;    NR10_Data <= 4'd0;   NR2_Add <= 8'd0;      NR10_Add <= 8'd0;
            NR2_Finish_Flag <= 1'b0;  NR10_Finish_Flag <= 1'b0; rst_en <= 1'b0;
          end
      endcase
   
    end
reg [7:0] Cor_Com_Cnt_B_1;
reg [7:0] Cor_Com_Cnt_B_2;
reg [7:0] Cor_Com_Cnt_A_1;
reg [7:0] Cor_Com_Cnt_A_2;
reg [7:0] Tor_Com_Cnt_B_1;
reg [7:0] Tor_Com_Cnt_B_2;
reg [7:0] Tor_Com_Cnt_A_1;
reg [7:0] Tor_Com_Cnt_A_2;
reg [25:0] NR_2s_Cnt;   //no receive for 2s cnt
reg [28:0] NR_10s_Cnt;   //no receive for 10s cnt
reg [2:0] NR2_state;
reg [2:0] NR10_state;


always @ (posedge DF_clk or negedge DF_rst)
  if(!DF_rst)
    begin
      Cor_Com_Cnt_B_1 <= 8'b0;
      Cor_Com_Cnt_B_2 <= 8'b0;
      Cor_Com_Cnt_A_1 <= 8'b0;
      Cor_Com_Cnt_A_2 <= 8'b0;
      Tor_Com_Cnt_B_1 <= 8'b0;
      Tor_Com_Cnt_B_2 <= 8'b0;
      Tor_Com_Cnt_A_1 <= 8'b0;
      Tor_Com_Cnt_A_2 <= 8'b0;
    end
  else 
    begin
      Cor_Com_Cnt_B_1 <= Cor_Com_Cnt_B;
      Cor_Com_Cnt_B_2 <= Cor_Com_Cnt_B_1;
      Cor_Com_Cnt_A_1 <= Cor_Com_Cnt_A;
      Cor_Com_Cnt_A_2 <= Cor_Com_Cnt_A_1;
      Tor_Com_Cnt_B_1 <= Tor_Com_Cnt_B;
      Tor_Com_Cnt_B_2 <= Tor_Com_Cnt_B_1;
      Tor_Com_Cnt_A_1 <= Tor_Com_Cnt_A;
      Tor_Com_Cnt_A_2 <= Tor_Com_Cnt_A_1;

    end
always @ (posedge DF_clk or negedge DF_rst)
  if(!DF_rst)
    begin
      NR2_state <= 3'd0;
      NR_2s_Cnt <= 26'd0;
      NR2_Start_Flag <= 1'b0;
    end
  else 
    begin
    case(NR2_state)
      3'd0:
      begin
        if(NR_2s_Cnt >= 26'd60000000)   //2s
          begin
            NR2_state <= 3'd1;
            NR_2s_Cnt <= 26'd0;
          end
        else if((Tor_Com_Cnt_B_2 != Tor_Com_Cnt_B_1)||(Tor_Com_Cnt_A_2 != Tor_Com_Cnt_A_1)||(Mode_Tor_Flag != 8'haa))
          begin
            NR2_state <= 3'd0;
            NR_2s_Cnt <= 26'd0;
          end
        else begin
            NR2_state <= 3'd0;
            NR_2s_Cnt <= NR_2s_Cnt + 1'b1;
        end
      end
      3'd1:
      begin
        NR2_Start_Flag <= 1'b1; 
        NR2_state <= 3'd2;
      end
      3'd2:
      begin
        if(NR2_Finish_Flag)
          begin
            NR2_Start_Flag <= 1'b0; 
            NR2_state <= 3'd0; 
          end
        else begin
            NR2_Start_Flag <= 1'b1; 
            NR2_state <= 3'd2; 
        end
      end
      default:
      begin
        NR2_Start_Flag <= 1'b0; 
        NR2_state <= 3'd0;
        NR_2s_Cnt <= 26'd0;        
      end
    endcase
    end

always @ (posedge DF_clk or negedge DF_rst)
  if(!DF_rst)
    begin
      NR10_state <= 3'd0;
      NR_10s_Cnt <= 29'd0;
      NR10_Start_Flag <= 1'b0;
    end
  else 
    begin
    case(NR10_state)
      3'd0:
      begin
        if(NR_10s_Cnt >= 29'd300000000)   //10s
          begin
            NR10_state <= 3'd1;
            NR_10s_Cnt <= 29'd0;
          end
        else if((Cor_Com_Cnt_B_2 != Cor_Com_Cnt_B_1)||(Cor_Com_Cnt_A_2 != Cor_Com_Cnt_A_1))
          begin
            NR10_state <= 3'd0;
            NR_10s_Cnt <= 29'd0;
          end
        else begin
            NR10_state <= 3'd0;
            NR_10s_Cnt <= NR_10s_Cnt + 1'b1;
        end
      end
      3'd1:
      begin
        NR10_Start_Flag <= 1'b1; 
        NR10_state <= 3'd2;
      end
      3'd2:
      begin
        if(NR10_Finish_Flag)
          begin
            NR10_Start_Flag <= 1'b0; 
            NR10_state <= 3'd0; 
          end
        else begin
            NR10_Start_Flag <= 1'b1; 
            NR10_state <= 3'd2; 
        end
      end
      default:
      begin
        NR10_Start_Flag <= 1'b0; 
        NR10_state <= 3'd0;
        NR_10s_Cnt <= 29'd0;        
      end
    endcase
    end

always @ (posedge DF_clk or negedge DF_rst)
  if(!DF_rst)
    begin
      present_state <= ST_idle; 
    end
  else 
    begin
      present_state <= next_state;
    end

always @ (posedge DF_clk or negedge DF_rst)
  if(!DF_rst)
    begin
      start_flag <= 1'b0; 
    end
  else 
    begin
      if(start_flag == 1'b1)
        start_flag <= 1'b1;
      else begin
        if((Cycle_Start_1 == 16'hAA55)&&(Cycle_Start_2 == 16'h55AA))
          start_flag <= 1'b1;
        else begin
          start_flag <= 1'b0;
        end    
      end
    end 

reg [19:0] rst_en_cnt;
reg rst_en_1;   //once for power up for SJA1000

always @ (posedge DF_clk or negedge DF_rst)
  if(!DF_rst)
    rst_en_cnt <= 20'd0;  
  else if (rst_en_cnt == 20'd300010) 
    rst_en_cnt <= 20'd300006;
  else
    rst_en_cnt <= rst_en_cnt + 1'b1;
always @ (posedge DF_clk or negedge DF_rst)
  if(!DF_rst)
    rst_en_1 <= 1'b0;
  else if((rst_en_cnt <= 20'd300005)&&(rst_en_cnt >= 20'd300001))
    rst_en_1 <= 1'b1;
  else 
    rst_en_1 <= 1'b0;
assign  SJA_rst_en = rst_en_1 | rst_en;
endmodule

