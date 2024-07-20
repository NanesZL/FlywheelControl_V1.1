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
    ////////////////////////////
    input   Clk_50M_in,
    ///////////////////////////
    input   AD_dout,
    output  AD_sclk,
    output  AD_din,
    output  AD_cs_n,
    ///////////////////////////
    input   Hall_a,
    input   Hall_b,
    input   Hall_c,
    ///////////////////////////
    input   CAN_RX,
    output  CAN_TX
    ///////////////////////////

    //    output  PWMH1,
    //    output  PWML1,
    //    output  PWMH2,
    //    output  PWML2,
    //    output  PWMH3,
    //    output  PWML3,
    //    output  PWMH4,
    //    output  PWML4,
    //    output  PWML5,
    //    output  reg PWM_OE_n
    //    output  PWM_OE_n

    //    output  Torque_Dir,
  );

    //reg PWM_OE_n;

  //----------------------------------------------------------------------------//

  wire RST;
  assign RST = 1;

  ////////////////////////////////////////////////////////////////////////
  /*************************** CLK_SETUP ********************************/
  //时钟配置模块，根据需要生成30M，50M，120M的时钟
  ////////////////////////////////////////////////////////////////////////

  // wire Clk_30M_out;
  wire Clk_50M_out;
  wire Clk_120M_out;

  // wire Locked_out_30;    //locked sigenal
  // wire Locked_out_120;   //locked sigenal
  wire Locked_out_50;    //locked sigenal


  DCM_50_50_120 DCM_50_50_120_0(
                  .CLKIN_IN(Clk_50M_in),
                  .RST_IN(~RST),
                  .CLKFX_OUT(Clk_120M_out),
                  .CLKIN_IBUFG_OUT(Clk_50M_out),
                  .CLK0_OUT(),
                  .LOCKED_OUT(Locked_out_50)
                );


  ////////////////////////////////////////////////////////////////////////
  /*************************** SpeedM ********************************/
  ////////////////////////////////////////////////////////////////////////

  wire [30:0] sv_l_1;       //data of 120MHz
  wire [31:0] sv_h_1;       //data of 120MHz
  wire [30:0] time_sv_1;    //data of 120MHz

  SpeedM SpeedM_0(
           .clk120(Clk_120M_out),
           .rst_n(RST),
           .Hall_a(Hall_a),
           .Hall_b(Hall_b),
           .Hall_c(Hall_c),
           //  .Speed_Value(PWML1),
           .Speed_Value(sv_l_1),   //低速
           .sv_h(sv_h_1),          //高速
           .time_sv(time_sv_1)
         );

  ////////////////////////////////////////////////////////////////////////
  /*************************** Dir_Get ********************************/
  //获取方向，0为正，1为负
  ////////////////////////////////////////////////////////////////////////
  wire Speed_Dir;

  Dir_Get Dir_Get_0(
            .clk(Clk_50M_out),
            .rst_n(~RST),
            .Hall_a(Hall_a),
            .Hall_b(Hall_b),
            .Hall_c(Hall_c),
            // .Speed_Dir(PWMH1)
            .Speed_Dir(Speed_Dir)
          );

  ////////////////////////////////////////////////////////////////////////
  /*************************** SJA_Control ********************************/
  ////////////////////////////////////////////////////////////////////////
  
  //wire [7:0] RX_D8,RX_D7,RX_D6,RX_D5,RX_D4,RX_D3,RX_D2,RX_D1,RX_frame_info,RX_Id1,RX_Id2; //for test


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



  parameter Revision  = 16'h01 ;
  parameter TEST_MODE = 16'h01 ;
  parameter FL_ch     = 16'h00 ;
  parameter Bus_id    = 1'b0 ;


  reg [19:0] rst_en_cnt=0;
  reg rst_en_1;   //once for power up for SJA1000

  always @ (posedge Clk_50M_out )//or negedge DF_rst)
    if (rst_en_cnt >= 20'd300010)
      rst_en_cnt <= 20'd300006;
    else
      rst_en_cnt <= rst_en_cnt + 1'b1;

  always @ (posedge Clk_50M_out )//or negedge DF_rst)
    if((rst_en_cnt <= 20'd300005)&&(rst_en_cnt >= 20'd300001))
      rst_en_1 <= 1'b1;
    else
      rst_en_1 <= 1'b0;

  assign  SJA_rst_en = rst_en_1 ;//| rst_en;

  SJA_Control  #(
                 .Bus_id    ( Bus_id    ) ,
                 .Revision  ( Revision  )  ,
                 .TEST_MODE ( TEST_MODE )  ,
                 .FL_ch     ( FL_ch     )
               )
               SJA_Control_0(
                 .CAN_RX(CAN_RX),
                 .CAN_TX(CAN_TX),
                 .SJA_rst_en(SJA_rst_en),
                 .clk(Clk_50M_out),
                 .rst_n(RST),
                 .power_33_self_test      ( 0  )  , /////	  input wire         ,/////3.3V二次电源自检
                 .Processor_self_test     ( 0  )  , /////    input wire         ,////处理器自检
                 .AD_self_test            ( 1  )  , /////    input wire         ,////AD自检
                 .Motor_self_test         ( 0  )  , /////    input wire         ,////电机自检

                 .BUCK_voltage_value      (AD_Current_0 )  , /////    input wire [07:0]  ,        //// BUCK电压值
                 .Current_value           (AD_R_V       )  , /////    input wire [15:0]  ,        //// CURRENT电流值
                 .VOLT_33V                (8'h56  )  , /////    input wire [07:0]  ,        //// VOLT_3 .3V
                 .Flywheel_temper         (8'h78  )  , /////    input wire [07:0]  ,        ////飞轮轴温
                 .Flywheel_speed          (8'h87  )  , /////    input wire [15:0]  ,        ////飞轮转速
                 .Flywheel_torque         (8'h76  )  , /////    input wire [15:0]  ,        ////飞轮输出力矩
                 .Self_test_Start_Flag    (   )  , ////                        	 output reg
                 .Torque_Direction        (   )  , //// ////力矩方向               output reg [07:0]
                 .Torque_magnitude        (   )  , //// ////力矩大小               output reg [15:0]
                 .Wheel_speed             (   )  , //// ////目标转速               output reg [15:0]
                 .CMD_State               (   )  , //// //state of command         output  reg [3:0]
                 .SJ_state(SJ_state),
                 .Inv_Com_Cnt_B(Inv_Com_Cnt_B),
                 .Cor_Com_Cnt_B(Cor_Com_Cnt_B),
                 .Tor_Com_Cnt_B(Tor_Com_Cnt_B),
                 .RXE_Cnt(RXE_Cnt),
                 .TXE_Cnt(TXE_Cnt),
                 .Reset_CANB_Cnt(Reset_CANB_Cnt),


                 .TSET_88DATA_O_1 (  )  ,
                 .TSET_88DATA_O_2 (  )  ,
                 .TSET_88DATA_O_3 (  )  ,
                 .TSET_88DATA_O_4 (  )  ,
                 .TSET_88DATA_O_5 (  )  ,
                 .TSET_88DATA_O_6 (  )  ,
                 .TSET_88DATA_O_7 (  )  ,

                 .TSET_66DATA_O_1 (  )  ,
                 .TSET_66DATA_O_2 (  )  ,
                 .TSET_66DATA_O_3 (  )  ,
                 .TSET_66DATA_O_4 (  )  ,
                 .TSET_66DATA_O_5 (  )  ,
                 .TSET_66DATA_O_6 (  )  ,
                 .TSET_66DATA_O_7 (  )  ,


                 .Cor_Com_Cnt_A         ( 1 ) ,
                 .Inv_Com_Cnt_A         ( 2 ) ,
                 .Selftest_Sta          ( 3 ) ,
                 .TXE_Cnt_A             ( 4 ) ,
                 .RXE_Cnt_A             ( 5 ) ,
                 .Reset_CANA_Cnt        ( 6 ) ,
                 .Motor_Consumption_CAN ( 7 ) ,
                 .Motor_Speed_CAN       ( 8 ) ,
                 .Motor_Torque_CAN      ( 9 ) ,
                 .Motor_Currunt_CAN     ( 10 ) ,
                 .Motor_Temperate_CAN   ( 11 ) ,
                 .Max_Torque_CAN        ( 12 ) ,
                 .Motor_Current_CMD     ( 13 ) ,
                 .Motor_Torque_CMD      ( 14 )

               );






  ////////////////////////////////////////////////////////////////////////
  /*************************** Chipscope ********************************/
  ////////////////////////////////////////////////////////////////////////
  // assign GT100_Flag=1'b0;
  // assign LT1800_Flag=1'b1;
  // assign BrakeMode=2'b00;
  // assign Q_OE=1'b1;
  // assign AD_Con=1'b1;
  // assign AD_Torque=1'b1;
  // assign Clr_flag=1'b1;
  // assign Torque_Dir=1'b0;
  // assign ctrl_data=12'd1;
  // assign PWM_OE_n=1'd1;




  // (*mark_debug = "TRUE" *) reg PWMH1_test;
  // always@(posedge Clk_30M_out)
  //   begin
  //     PWMH1_test<=PWMH1;
  //   end


  wire [35:0] CONCTROL_0;
  wire [255:0] cp_data;

  assign cp_data={
           Clk_50M_out,
           Clk_120M_out,
           Speed_Dir,
           sv_l_1[30:0]
         };

  Chipscope_ICON ICON_0(
                   .CONTROL0(CONCTROL_0)
                 );

  Chipscope_ILA ILA_0(
                  .CONTROL(CONCTROL_0),
                  .CLK(Clk_50M_out),
                  .TRIG0(cp_data)
                );

  ///////////tongbu operation/////////////


  reg  [30:0] sv_l_2;
  reg  [31:0] sv_h_2;
  reg  [30:0] time_sv_2;
  reg [30:0] sv_l;
  reg [31:0] sv_h;
  reg [30:0] time_sv;

  always @(posedge Clk_50M_out or negedge RST)
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
  always @(posedge Clk_50M_out or negedge RST)
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


  wire Modechg_flag;
  wire [1:0]BrakeMode;
  wire Q_OE;
  wire [11:0] ctrl_data;  //control data for pwm
  wire LT1800_Flag, GT100_Flag, Clr_flag;
  wire AD_Con;




  ////////////////////////////////////////////////////////////////////////
  /*************************** Center_Control ********************************/
  ////////////////////////////////////////////////////////////////////////

  // wire [11:0]Insert_Data;   //dsp insert data for nenghao to fanjie
  // wire ModeNH_Over_Flag;

  // Center_Control Center_Control_0(
  //                  .clk(Clk_30M_out),
  //                  .rst_n(RST),
  //                  .Modechg_flag(Modechg_flag),
  //                  .BrakeMode(BrakeMode),
  //                  .LT1800_Flag(LT1800_Flag),
  //                  .start_flag(start_flag),
  //                  .AD_Current(AD_Current_0),
  //                  .AD_Torque(AD_Torque),
  //                  .torque_flag(Q_OE),
  //                  .ctrl_data(ctrl_data),
  //                  .Clr_flag(Clr_flag),
  //                  .ModeNH_Over_Flag(ModeNH_Over_Flag),
  //                  .Insert_Data(Insert_Data)
  //                );


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

endmodule
