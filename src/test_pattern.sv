// ---------------------------------------------------------------------
// File name         : testpattern.v
// Module name       : testpattern
// Created by        : Caojie
// Module Description: 
//						I_mode[2:0] = "000" : color bar     
//						I_mode[2:0] = "001" : net grid     
//						I_mode[2:0] = "010" : gray         
//						I_mode[2:0] = "011" : single color
// ---------------------------------------------------------------------
// Release history
// VERSION |   Date      | AUTHOR  |    DESCRIPTION
// --------------------------------------------------------------------
//   1.0   | 24-Sep-2009 | Caojie  |    initial
// --------------------------------------------------------------------

module testpattern
#(
    parameter int VIDEO_ID_CODE = 1,
    parameter int BIT_WIDTH = VIDEO_ID_CODE < 4 ? 10 : VIDEO_ID_CODE == 4 ? 11 : 12,
    parameter int BIT_HEIGHT = VIDEO_ID_CODE == 16? 11 : 10
)
(
	input              clk_pixel   ,//pixel clock
    input              reset       ,//low active 
    input      [2:0]   I_mode      ,//data select
    
    input logic [BIT_WIDTH-1:0]  frame_width  ,
    input logic [BIT_HEIGHT-1:0] frame_height ,
    input logic [BIT_WIDTH-1:0]  screen_width ,
    input logic [BIT_HEIGHT-1:0] screen_height,
    input logic [BIT_WIDTH-1:0]  cx           ,
    input logic [BIT_HEIGHT-1:0] cy           ,

    input hsync,
    input vsync,

    input logic [7:0] in_r = 8'b0  ,
    input logic [7:0] in_g = 8'b0  ,
    input logic [7:0] in_b = 8'b0  ,

    output logic [7:0] out_r       ,
    output logic [7:0] out_g       ,
    output logic [7:0] out_b
); 

//====================================================
localparam N = 5; //delay N clocks

localparam	WHITE	= {8'd255 , 8'd255 , 8'd255 };//{B,G,R}
localparam	YELLOW	= {8'd0   , 8'd255 , 8'd255 };
localparam	CYAN	= {8'd255 , 8'd255 , 8'd0   };
localparam	GREEN	= {8'd0   , 8'd255 , 8'd0   };
localparam	MAGENTA	= {8'd255 , 8'd0   , 8'd255 };
localparam	RED		= {8'd0   , 8'd0   , 8'd255 };
localparam	BLUE	= {8'd255 , 8'd0   , 8'd0   };
localparam	BLACK	= {8'd0   , 8'd0   , 8'd0   };
  
//====================================================
reg  [11:0]   V_cnt     ;
reg  [11:0]   H_cnt     ;
              

//-------------------------
//Color bar //8ɫ����
reg  [11:0]   Color_trig_num; 
reg           Color_trig    ;
reg  [3:0]    Color_cnt     ;
reg  [23:0]   Color_bar     ;

//----------------------------
//Net grid //32����
reg           Net_h_trig;
reg           Net_v_trig;
wire [1:0]    Net_pos   ;
reg  [23:0]   Net_grid  ;

//----------------------------
//Gray  //�ڰ׻ҽ�
reg  [23:0]   Gray;
reg  [23:0]   Gray_d1;

//-----------------------------
wire [23:0]   Single_color;

//-------------------------------
wire [23:0]   Data_sel;

//-------------------------------
reg  [23:0]   Data_tmp/*synthesis syn_keep=1*/;

//=================================================================================
//Test Pattern


//---------------------------------------------------
//Color bar
//---------------------------------------------------
assign Color_trig_num = screen_width[BIT_WIDTH-1:BIT_WIDTH-8]; //8ɫ��������

reg [10:0] Color_bar_column_counter = 11'b0;

always @(posedge clk_pixel or posedge reset)
begin
    if (reset | (cx == 0) | Color_trig) Color_bar_column_counter <= 11'b0;
    else Color_bar_column_counter <= Color_bar_column_counter + 1'b1;
end

always @(posedge clk_pixel or posedge reset)
begin
	if(reset)
		Color_trig <= 1'b0;
	else if (Color_bar_column_counter == (Color_trig_num-1'b1)) 
		Color_trig <= 1'b1;
	else
		Color_trig <= 1'b0;
end

always @(posedge clk_pixel or posedge reset)
begin
	if(reset)
		Color_cnt <= 3'd0;
    else if (cx == 0)
        Color_cnt <= 3'd0;
	else if ((Color_trig == 1'b1))
		Color_cnt <= Color_cnt + 1'b1;
	else
		Color_cnt <= Color_cnt;
end

always @(posedge clk_pixel or posedge reset)
begin
	if(reset)
		Color_bar <= 24'd0;
	else
		case(Color_cnt)
			3'd0	:	Color_bar	<=	WHITE  ;
			3'd1	:	Color_bar	<=	YELLOW ;
			3'd2	:	Color_bar	<=	CYAN   ;
			3'd3	:	Color_bar	<=	GREEN  ;
			3'd4	:	Color_bar	<=	MAGENTA;
			3'd5	:	Color_bar	<=	RED    ;
			3'd6	:	Color_bar	<=	BLUE   ;
			3'd7	:	Color_bar	<=	BLACK  ;
			default	:	Color_bar	<=	BLACK  ;
		endcase
end

//---------------------------------------------------
//Net grid
//---------------------------------------------------
always @(posedge clk_pixel or posedge reset)
begin
	if(reset)
		Net_h_trig <= 1'b0;
	else if (((cx[4:0] == 5'd0) || (cx == (screen_width-1'b1))))
		Net_h_trig <= 1'b1;
	else
		Net_h_trig <= 1'b0;
end

always @(posedge clk_pixel or posedge reset)
begin
	if(reset)
		Net_v_trig <= 1'b0;
	else if (((cy[4:0] == 5'd0) || (cy == (screen_height-1'b1))))
		Net_v_trig <= 1'b1;
	else
		Net_v_trig <= 1'b0;
end

assign Net_pos = {Net_v_trig,Net_h_trig};

always @(posedge clk_pixel or posedge reset)
begin
	if(reset)
		Net_grid <= 24'd0;
	else 
        case(Net_pos)
			2'b00	:	Net_grid	<=	BLACK  ;
			2'b01	:	Net_grid	<=	RED    ;
			2'b10	:	Net_grid	<=	RED    ;
			2'b11	:	Net_grid	<=	RED    ;
			default	:	Net_grid	<=	BLACK  ;
		endcase
end

//---------------------------------------------------
//Gray
//---------------------------------------------------
always @(posedge clk_pixel or posedge reset)
begin
	if(reset)
		Gray <= 24'd0;
	else
		Gray <= {cx[7:0],cx[7:0],cx[7:0]};
end

always @(posedge clk_pixel or posedge reset)
begin
	if(reset)
		Gray_d1 <= 24'd0;
	else
		Gray_d1 <= Gray;
end

//---------------------------------------------------
//Single color
//---------------------------------------------------
assign Single_color = {in_b,in_g,in_r};

//============================================================
assign Data_sel = (I_mode[2:0] == 3'b000) ? Color_bar		: 
                  (I_mode[2:0] == 3'b001) ? Net_grid 		: 
                  (I_mode[2:0] == 3'b010) ? Gray_d1    		: 
				  (I_mode[2:0] == 3'b011) ? Single_color	: BLUE;

//---------------------------------------------------
always @(posedge clk_pixel or posedge reset)
begin
	if(reset) 
		Data_tmp <= 24'd0;
	else
		Data_tmp <= Data_sel;
end

assign out_r  = Data_tmp[ 7: 0];
assign out_g = Data_tmp[15: 8];
assign out_b = Data_tmp[23:16];

endmodule       
              