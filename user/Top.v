`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    18:16:16 11/26/2019
// Design Name:
// Module Name:    Top
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
module Top(
    input   Clk_50M,
    input   RST_INPUT,
    input   AD_dout,
    output  AD_sclk,
    output  AD_din,
    output  AD_cs_n,
    input   Hall_a,
    input   Hall_b,
    input   Hall_c,
    output  PWMH1,
    output  PWML1,
    output  PWMH2,
    output  PWML2,
    output  PWMH3,
    output  PWML3,
    //    output  PWMH4,
    //    output  PWML4,
    //    output  PWML5,
    //    output  reg PWM_OE_n
    output  PWM_OE_n

    //    output  LED,
    //    output  Torque_Dir,
    //    input   [9:0] DSP_Add,
    //    inout   [15:0] DSP_Data,
    //    input   DSP_XWEn,
    //    inout   [7:0] SJ_AD,
    //    input   SJ_INT_n,
    //    output  SJA_Dir,
    //    output  SJ_RD_n,
    //    output  SJ_WR_n,
    //    output  SJ_ALE,
    //    output  SJ_CS_n,
    //    output  SJ_RST_n,
    //    output  SJA_OE_n,
    //    output  Test_5,
    //    output  Test_6
  );


  //reg PWM_OE_n;
  //wire Clk_50M;
  wire RST;
  //reg DWR_WR_n;
  //reg [1:0]DWR_state;
  //reg DWR_flag;
  //wire [15:0] DR_Dout_A;
  //wire [15:0] DR_Din_A;

  reg [15:0] rst_cnt = 16'd0;
  reg rst_reg;

  //always @(posedge Clk_30M_out)
  //  begin
  //    if(rst_cnt == 16'hFFFF)
  //      rst_cnt <= 16'hFFFB;
  //    else
  //      rst_cnt <= rst_cnt + 1'b1;
  //  end
  //
  //always @(posedge Clk_30M_out)
  //  if(rst_cnt < 16'hFFFA)
  //    rst_reg <= 1'b0;
  //  else
  //    rst_reg <= 1'b1;
  //
  //assign  RST = rst_reg && RST_INPUT;
  assign  RST = RST_INPUT;
  //
  //assign SJA_OE_n = 1'b0;
  //assign DSP_Data [15:0] = (DWR_WR_n)? {DR_Dout_A}: 16'hzzzz; //// DWR_WR_n :0 dsp write to dRAM
  //assign DR_Din_A = DSP_Data;
  //always @(posedge Clk_30M_out or negedge RST)
  //  begin
  //    if (!RST)
  //	  begin
  //		DWR_flag <= 1'b0;
  //	  end
  //	else
  //	  begin
  /*
  case(DWR_ADDR)
    10'b1100000001:DWR_flag <= 1'b1;  //16bit 0xFF01~0XFF10
    10'b1100000010:DWR_flag <= 1'b1;
    10'b1100000011:DWR_flag <= 1'b1;
    10'b1100000100:DWR_flag <= 1'b1;
    10'b1100000101:DWR_flag <= 1'b1;
    10'b1100000110:DWR_flag <= 1'b1;
    10'b1100000111:DWR_flag <= 1'b1;
    10'b1100001000:DWR_flag <= 1'b1;
    10'b1100001001:DWR_flag <= 1'b1;
    10'b1100001010:DWR_flag <= 1'b1;
    10'b1100001011:DWR_flag <= 1'b1;
    10'b1100001100:DWR_flag <= 1'b1;
    10'b1100001101:DWR_flag <= 1'b1;
    10'b1100001110:DWR_flag <= 1'b1;
    10'b1100001111:DWR_flag <= 1'b1;
    10'b1100010000:DWR_flag <= 1'b1;
    10'b1111111111:DWR_flag <= 1'b1;  //0XFFFF
    10'b1111111110:DWR_flag <= 1'b1;  //0XFFFE
    default: DWR_flag <= 1'b0;
  endcase
  */
  //      if(DSP_Add[9:8] == 2'b11)   //for dsp xtint addr = 0x0010ff**;
  //        begin
  //          DWR_flag <= 1'b1;
  //        end
  //      else begin
  //          DWR_flag <= 1'b0;
  //      end
  //	  end
  //  end

  //always @(posedge Clk_30M_out or negedge RST)
  //  begin
  //    if (!RST)
  //		DWR_state <= 2'b00;
  //    else
  //        DWR_state <= {DSP_XWEn,DWR_flag};
  //  end
  //
  //always @(posedge Clk_30M_out or negedge RST)
  //  begin
  //    if (!RST)
  //    begin
  //      DWR_WR_n <= 1'b1;
  //      //////test 191205/////////////
  //      PWM_OE_n <= 1'b1;
  //      ////
  //    end
  //
  //    else
  //      begin
  //          //////test 191205/////////////
  //          PWM_OE_n <= 1'b0;
  //          ////
  //          case(DWR_state)
  //          2'b00:
  //              DWR_WR_n <= 1'b1;
  //          2'b01:
  //              DWR_WR_n <= 1'b0;     //dsp write to dRAM
  //          2'b10:
  //              DWR_WR_n <= 1'b1;
  //          2'b11:
  //              DWR_WR_n <= 1'b1;
  //          default:DWR_WR_n <= 1'b1;
  //          endcase
  //		end
  //	end
  //
  //wire [15:0] DR_Dout_B;
  //wire [15:0] DR_Din_B;
  //wire [7:0] DF2ram_addr;
  //wire DF2ram_RW;
  //wire [11:0] AD_Torque;
  //wire start_flag;


  //assign  rst_in = !RST;
  //assign Test_5 = Clk_30M_out;
  //assign Test_6 = Clk_120M;
  //

  wire rst_in;
  wire Clk_30M_out;
  wire Clk_120M_out;
  wire Locked_out_30;    //locked sigenal
  wire Locked_out_120;    //locked sigenal
  wire test_clk;
  wire Clk_50M_out;


  DCM_50_30 DCM1 (
              .CLKIN_IN (Clk_50M),
              .RST_IN   (~RST_INPUT),
              .CLKFX_OUT(Clk_30M_out),
              .CLKIN_IBUFG_OUT(clk_50M_out),
              .CLK0_OUT(),
              .LOCKED_OUT(Locked_out_30)
            );


  DCM_50_120 DCM2 (
               .CLKIN_IN(clk_50M_out),
               .RST_IN(~RST_INPUT),
               .CLKFX_OUT(Clk_120M_out),
               .CLKIN_IBUFG_OUT(CLKIN_IBUFG_OUT),
               .CLK0_OUT(),
               .LOCKED_OUT(Locked_out_120)
             );

  //DCM_L  DCM_L_0(
  //      .CLKIN_IN(Clk_30M),
  //      .RST_IN(rst_in),
  //      .CLKFX_OUT(Clk_120M),
  //      .CLKIN_IBUFG_OUT(Clk_30M_out),
  //      .LOCKED_OUT(Locked_out)
  //      );

  //always @(posedge Clk_30M_out)
  //begin
  //
  //test_clk<=!test_clk;
  //
  //end



  //DualRAM DualRAM_0(
  //	.addra(DSP_Add[7:0]),
  //	.addrb(DF2ram_addr),
  //	.clka(Clk_30M_out),
  //	.clkb(Clk_30M_out),
  ////	.dina(DSP_Data),
  //  .dina(DR_Din_A),
  //	.dinb(DR_Din_B),
  //	.douta(DR_Dout_A),
  //	.doutb(DR_Dout_B),
  ////	.wea(DWR_WR_n),
  //  .wea(DSP_XWEn),
  //	.web(DF2ram_RW)
  //	);

  //////test 191205/////////////
  //  wire [15:0]Test_Data1;
  //  wire [15:0]Test_Data2;
  ///
  ///


  ///////////tongbu operation/////////////
  wire [30:0] sv_l_1;       //data of 120MHz
  wire [31:0] sv_h_1;       //data of 120MHz
  wire [30:0] time_sv_1;    //data of 120MHz

  reg  [30:0] sv_l_2;
  reg  [31:0] sv_h_2;
  reg  [30:0] time_sv_2;
  reg [30:0] sv_l;
  reg [31:0] sv_h;
  reg [30:0] time_sv;

  always @(posedge Clk_30M_out or negedge RST)
    if (!RST)
      begin
        sv_l_2 <= 31'd0;
        sv_h_2 <= 32'd0;
        time_sv_2 <= 31'd0;
      end
    else
      begin
        sv_l_2 <= sv_l_1;
        sv_h_2 <= sv_h_1;
        time_sv_2 <= time_sv_1;
      end
  always @(posedge Clk_30M_out or negedge RST)
    if (!RST)
      begin
        sv_l <= 31'd0;
        sv_h <= 32'd0;
        time_sv <= 31'd0;
      end
    else
      begin
        if(sv_l_2 == sv_l_1)
          sv_l <= sv_l_2;
        if(sv_h_2 == sv_h_1)
          sv_h <= sv_h_2;
        if(time_sv_2 == time_sv_1)
          time_sv <= time_sv_2;
      end


  wire Speed_Dir;
  wire Modechg_flag;
  wire [1:0]BrakeMode;
  wire Q_OE;
  wire [11:0] ctrl_data;  //control data for pwm
  wire LT1800_Flag, GT100_Flag, Clr_flag;
  wire AD_Con;


  wire [11:0] AD_Current_0;    //abs (current from b128s102)
  wire [11:0] AD_R_V;
  wire [7:0] Inv_Com_Cnt_B;     //invalid command cnt for CANB
  wire [7:0] Cor_Com_Cnt_B;     //correct command cnt for CANB
  wire [7:0] Tor_Com_Cnt_B;     //torque command cnt for CANB
  wire [7:0] RXE_Cnt;          //RXE register for CANB
  wire [7:0] TXE_Cnt;          //TXE register for CANA
  wire [7:0] Reset_CANB_Cnt;
  wire CMD_Finish_Flag,CMD_Start_Flag;
  wire [3:0]CMD_State;
  wire SJA_rst_en;
  wire [31:0] Max_Torque_B, Speed_CMD_B, Net_Torque_CMD_B,Motor_Speed_CAN,Motor_Torque_CAN,Motor_Torque_CMD;
  wire [1:0] CR_CMD_B;
  wire [7:0] Inv_Com_Cnt_A, Cor_Com_Cnt_A, RXE_Cnt_A, TXE_Cnt_A, Reset_CANA_Cnt, Selftest_Sta;
  wire [15:0] Motor_Consumption_CAN, Motor_Currunt_CAN, Motor_Temperate_CAN, Max_Torque_CAN; //Motor_Consumption from DSP

  ////////////////////////////////////////////////////////////////////////
  /*************************** Test ********************************/
  ////////////////////////////////////////////////////////////////////////
  assign GT100_Flag=1'b0;
  assign LT1800_Flag=1'b1;
  assign BrakeMode=2'b00;
  assign Q_OE=1'b1;
  assign AD_Con=1'b1;
  assign AD_Torque=1'b1;
  assign Clr_flag=1'b1;
  assign Torque_Dir=1'b0;
  assign ctrl_data=12'd1;
  assign PWM_OE_n=1'd1;

  (*mark_debug = "TRUE" *) reg PWMH1_test;
  always@(posedge Clk_30M_out)
    begin
      PWMH1_test<=PWMH1;
    end

  ////////////////////////////////////////////////////////////////////////
  /*************************** Center_Control ********************************/
  ////////////////////////////////////////////////////////////////////////

  //wire [11:0]Insert_Data;   //dsp insert data for nenghao to fanjie
  //wire ModeNH_Over_Flag;
  //
  //Center_Control Center_Control_0(
  //  .clk(Clk_30M_out),
  //  .rst_n(RST),
  //  .Modechg_flag(Modechg_flag),
  //  .BrakeMode(BrakeMode),
  //  .LT1800_Flag(LT1800_Flag),
  //  .start_flag(start_flag),
  //  .AD_Current(AD_Current_0),
  //  .AD_Torque(AD_Torque),
  //  .torque_flag(Q_OE),
  //  .ctrl_data(ctrl_data),
  //  .Clr_flag(Clr_flag),
  //  .ModeNH_Over_Flag(ModeNH_Over_Flag),
  //  .Insert_Data(Insert_Data)
  //  );
  //

  ////////////////////////////////////////////////////////////////////////
  /*************************** Data_Transfer ********************************/
  ////////////////////////////////////////////////////////////////////////
  //wire [15:0]Motor_Current_CMD;
  //wire [15:0]Current_CMD_B;
  //Data_Transfer Data_Transfer_0(
  //      .DF_clk(Clk_30M_out), .DF_rst(RST), .ram2DF_data(DR_Dout_B),  .DF2ram_data(DR_Din_B), .DF2ram_addr(DF2ram_addr),
  //      .DF2ram_RW(DF2ram_RW),  .Speed_Dir(Speed_Dir),  .sv_h(sv_h), .time_sv(time_sv), .Speed_Value(sv_l), .Torque_Dir(Torque_Dir),
  //      .AD_Torque(AD_Torque),  .start_flag(start_flag), .AD_Current_0(AD_Current_0), .AD_R_V(AD_R_V),
  //      .Inv_Com_Cnt_B(Inv_Com_Cnt_B),  .Cor_Com_Cnt_B(Cor_Com_Cnt_B), .Tor_Com_Cnt_B(Tor_Com_Cnt_B),
  //      .RXE_Cnt(RXE_Cnt), .TXE_Cnt(TXE_Cnt), .Reset_CANB_Cnt(Reset_CANB_Cnt), .CMD_Finish_Flag(CMD_Finish_Flag),
  //      .CMD_Start_Flag(CMD_Start_Flag),  .CMD_State(CMD_State),  .SJA_rst_en(SJA_rst_en),  .Max_Torque_B(Max_Torque_B),
  //      .Speed_CMD_B(Speed_CMD_B),  .Current_CMD_B(Current_CMD_B), .Net_Torque_CMD_B(Net_Torque_CMD_B),  .CR_CMD_B(CR_CMD_B), .Inv_Com_Cnt_A(Inv_Com_Cnt_A),
  //      .Cor_Com_Cnt_A(Cor_Com_Cnt_A),  .RXE_Cnt_A(RXE_Cnt_A),  .TXE_Cnt_A(TXE_Cnt_A),  .Reset_CANA_Cnt(Reset_CANA_Cnt),
  //      .Selftest_Sta(Selftest_Sta),  .Motor_Consumption_CAN(Motor_Consumption_CAN),  .Motor_Speed_CAN(Motor_Speed_CAN),
  //      .Motor_Torque_CAN(Motor_Torque_CAN),  .Motor_Currunt_CAN(Motor_Currunt_CAN), .Motor_Temperate_CAN(Motor_Temperate_CAN),
  //      .Max_Torque_CAN(Max_Torque_CAN),  .Motor_Torque_CMD(Motor_Torque_CMD), .Motor_Current_CMD(Motor_Current_CMD), .BrakeMode(BrakeMode),
  //      .Insert_Data(Insert_Data));

  ////////////////////////////////////////////////////////////////////////
  /*************************** AD ********************************/
  ////////////////////////////////////////////////////////////////////////

  AD AD_0(
       .clk(Clk_30M_out),
       .rst_n(RST),
       .sclk(AD_sclk),
       .dout(AD_dout),
       .din(AD_din),
       .cs_n(AD_cs_n),
       .AD_Con(AD_Con),
       .AD_Current(AD_Current_0),   // current value
       .AD_R_V(AD_R_V)        // resistance value
     );

  ////////////////////////////////////////////////////////////////////////
  /*************************** Mode_Control ********************************/
  ////////////////////////////////////////////////////////////////////////

  //Mode_Control Mode_Control_0(
  //    .clk(Clk_30M_out),
  //    .rst_n(RST),
  //    .Torque_Dir(Torque_Dir),
  //    .Speed_Dir(Speed_Dir),
  //    .sv_h(sv_h),
  //    .LT1800_Flag(LT1800_Flag),
  //    .GT100_Flag(GT100_Flag),
  //    .MainQ_BrakeMode(BrakeMode),
  //    .Clr_flag(Clr_flag),
  //    .Modechg_flag(Modechg_flag),
  //    .ModeNH_Over_Flag(ModeNH_Over_Flag)
  //    );

  ////////////////////////////////////////////////////////////////////////
  /*************************** Q_Control ********************************/
  ////////////////////////////////////////////////////////////////////////

  //Q_Control Q_Control_0(
  //  .clk(Clk_30M_out),
  //  .rst_n(RST),
  //  .Hall_a(Hall_a),
  //  .Hall_b(Hall_b),
  //  .Hall_c(Hall_c),
  //  .Torque_Dir(Torque_Dir),
  //  .Q1(PWMH1),
  //  .Q2(PWML1),
  //  .Q3(PWMH2),
  //  .Q4(PWML2),
  //  .Q5(PWMH3),
  //  .Q6(PWML3),
  //  .Q7(PWMH4),
  //  .Q8(PWML4),
  //  .Q9(PWML5),
  //  .GT100_Flag(GT100_Flag),
  //  .LT1800_Flag(LT1800_Flag),
  //  .BrakeM(BrakeMode),
  //  .OE(Q_OE),
  //  .AD_Con(AD_Con),
  //  .ctrl_data(ctrl_data)
  //    );
  ////////////////////////////////////////////////////////////////////////
  /*************************** SpeedM ********************************/
  ////////////////////////////////////////////////////////////////////////
  SpeedM SpeedM_0(
           .clk120(Clk_120M_out),
           .rst_n(RST),
           .Hall_a(Hall_a),
           .Hall_b(Hall_b),
           .Hall_c(Hall_c),
           .Speed_Value(PWML1),
           //  .Speed_Value(sv_l_1),
           .sv_h(sv_h_1),
           .time_sv(time_sv_1)
         );

  ////////////////////////////////////////////////////////////////////////
  /*************************** Dir_Get ********************************/
  ////////////////////////////////////////////////////////////////////////
  Dir_Get Dir_Get_0(
            .clk(Clk_30M_out),
            .rst_n(RST),
            .Hall_a(Hall_a),
            .Hall_b(Hall_b),
            .Hall_c(Hall_c),
            .Speed_Dir(PWMH1)
            //  .Speed_Dir(Speed_Dir)

          );


  ////////////////////////////////////////////////////////////////////////
  /*************************** SJA_Control ********************************/
  ////////////////////////////////////////////////////////////////////////
  //wire [7:0] RX_D8,RX_D7,RX_D6,RX_D5,RX_D4,RX_D3,RX_D2,RX_D1,RX_frame_info,RX_Id1,RX_Id2; //for test
  //SJA_Control SJA_Control_0(
  //  .SJ_AD(SJ_AD),  .SJ_INT_n(SJ_INT_n),  .SJA_Dir(SJA_Dir),  .SJ_RD_n(SJ_RD_n),  .SJ_WR_n(SJ_WR_n),  .SJ_ALE(SJ_ALE),
  //  .SJ_CS_n(SJ_CS_n),  .SJ_RST_n(SJ_RST_n),  .clk(Clk_30M_out),  .rst_n(RST),  .SJA_rst_en(SJA_rst_en),  .CMD_Finish_Flag(CMD_Finish_Flag),
  //  .Cor_Com_Cnt_A(Cor_Com_Cnt_A),  .Inv_Com_Cnt_A(Inv_Com_Cnt_A),  .Selftest_Sta(Selftest_Sta), .RXE_Cnt_A(RXE_Cnt_A), .TXE_Cnt_A(TXE_Cnt_A),
  //  .Reset_CANA_Cnt(Reset_CANA_Cnt),  .Motor_Consumption_CAN(Motor_Consumption_CAN),  .Motor_Speed_CAN(Motor_Speed_CAN),
  //  .Motor_Torque_CAN(Motor_Torque_CAN), .Motor_Currunt_CAN(Motor_Currunt_CAN), .Motor_Temperate_CAN(Motor_Temperate_CAN),
  //  .Max_Torque_CAN(Max_Torque_CAN),  .Motor_Torque_CMD(Motor_Torque_CMD), .Motor_Current_CMD(Motor_Current_CMD),  .CMD_Start_Flag(CMD_Start_Flag),
  // .RX_D8(RX_D8), .RX_D7(RX_D7), .RX_D6(RX_D6), .RX_D5(RX_D5), .RX_D4(RX_D4), .RX_D3(RX_D3), .RX_D2(RX_D2), .RX_D1(RX_D1),
  //  .RX_frame_info(RX_frame_info), .RX_Id1(RX_Id1), .RX_Id2(RX_Id2),
  //  .SJ_state(), .Max_Torque_B(Max_Torque_B), .Speed_CMD_B(Speed_CMD_B), .Current_CMD_B(Current_CMD_B),
  //  .Net_Torque_CMD_B(Net_Torque_CMD_B),.CR_CMD_B(CR_CMD_B),  .Inv_Com_Cnt_B(Inv_Com_Cnt_B),  .Cor_Com_Cnt_B(Cor_Com_Cnt_B), .Tor_Com_Cnt_B(Tor_Com_Cnt_B),
  //  .RXE_Cnt(RXE_Cnt),  .TXE_Cnt(TXE_Cnt),  .Reset_CANB_Cnt(Reset_CANB_Cnt), .CMD_State(CMD_State)
  //  );


  ///////////////////////test_led////////////////////////
  //reg [24:0] Main_LED_cnt;
  //reg Main_LEDReg;
  //
  //
  //always @(posedge Clk_120M)
  //  if(Main_LED_cnt >= 25'd30000000)
  //    begin
  //      Main_LEDReg <= ~Main_LEDReg;
  //      Main_LED_cnt <= 25'd0;
  //    end
  //   else
  //      Main_LED_cnt <=  Main_LED_cnt + 1'b1;
  //
  //assign LED = Main_LEDReg;

  ////////////////////////////////////////////////////////////////////////
  /*************************** Chipscope ********************************/
  ////////////////////////////////////////////////////////////////////////
  /*
   
  reg [15:0] cnt2 ;
  reg chipclk_reg2;
  always @(posedge Clk_30M_out or negedge RST)
    if(!RST)
        begin 
        cnt2 <= 16'b0;
      end
    else cnt2 <= cnt2 + 1'b1;
   
  always@(posedge Clk_30M_out or negedge RST)
    if(!RST)
    begin
     chipclk_reg2 <=  1'b0;
     end
    else 
     begin
      if(cnt2 <= 16'd32406)
       chipclk_reg2 <= 1'b1;
      else chipclk_reg2 <= 1'b0;
     end
  */
  //assign pwm_out = pwm_reg;

  /*
  wire [54:0] test;
   
  //
  assign test = {28'd0,Speed_Dir,Torque_Dir,Q_OE,start_flag,ctrl_data,PWML5,PWML4,PWMH4,PWML3,PWMH3,PWML2,PWMH2,PWML1,PWMH1,BrakeMode}; 
  //                      8           1       4           1               1          
  //assign test = {present_state,SJA_rst_en,CMD_State,CMD_Finish_Flag,CMD_Start_Flag}; 
  //               10       3         1        12      12            12        2         1        1     1     
  //assign test = {10'b0,Main_State,Clr_flag,AD_Torque,AD_Current_0,ctrl_data,BrakeMode,start_flag,Q_OE,AD_Con}; 
  //                     1      1     1     1     1    1     1     1     1        12      1
  //assign test = {33'b0,PWML5,PWML4,PWMH4,PWML3,PWMH3,PWML2,PWMH2,PWML1,PWMH1,ctrl_data,AD_Con};
  //                 55      48    40      32        24         16     15       14      13       12     11     10       9       8
  //assign test = {SJ_state,RX_D1,RX_Id2,RX_Id1,RX_frame_info,rst_en,SJ_INT_n,SJA_Dir,SJ_RST_n,SJ_CS_n,SJ_WR_n,SJ_RD_n,SJ_ALE,SJ_AD}; 
  //assign test = {12'h000,DSP_XWEn,DR_Din_A,DR_Dout_A,DSP_Add[7:0]};  //,DR_Din_B,DR_Dout_B,DF2ram_addr};
          //     0          1       16       16      10            16      16           8
   
  //assign test = {0,Torque_Dir,GT6400_Flag,GT700_Flag,LT700_Flag,TEST_QC,MainQ_data,LT1800_Flag,BrakeMode,PIDCtr_state,Main_State[2:0],MainAD_StaFlg,ADMain_DataEn,AD_Current2,ADMain_Torque};
   
   
  wire  [35:0]  CONTROL0;
   
   
   
   
  ICON uu1(.CONTROL0(CONTROL0));
  ILA uu2(
      .CONTROL(CONTROL0),
      .CLK(Clk_30M_out),
      .DATA(test), 
      .TRIG0(AD_Con)
  //    .TRIG0(trigo_1)
  //    .TRIG0(SJ_INT_n)
      //.TRIG_OUT()
      );
   
  */

endmodule
