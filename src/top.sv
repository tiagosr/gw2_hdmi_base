
module HelloHDMI (
    input clk_sys,
    input reset_n,

    // -- Board signals
    // buttons S1 and S2 on the board
    input s1,
    input reset2,

    input clock_ntsc, // external MS5351 clock 0, set with `pll_clk O0=3579K -s`
    input clock_pal,  // external MS5351 clock 1, set with `pll_clk O1=3546K -s`
    
    // uart
    input uart_rxd,
    output uart_txd,

    // -- HDMI signals
    output [2:0] tmds_d_n,
    output [2:0] tmds_d_p,
    output tmds_clk_p,
    output tmds_clk_n,

    // -- LED debug signals
    output [5:0] led,

    // -- WS2812 signal
    output logic ws2812_out
);

logic [15:0] AUDIO_R, AUDIO_L;

wire reset;
assign reset = 1'b0;
wire [2:0] tmds;
wire tmds_clock;
reg vsync_latched;
wire hsync, vsync, blank;
wire [7:0] red, green, blue;
wire [9:0] cy, frame_height, screen_height;
wire [10:0] cx, frame_width, screen_width;

assign blank = hsync && vsync;

localparam AUDIO_RATE=48000;
localparam AUDIO_CLK_DELAY = CLKFRQ * 1000 / AUDIO_RATE / 2;
logic [$clog2(AUDIO_CLK_DELAY)-1:0] audio_divider;
logic clk_audio;

assign AUDIO_R = 16'b0;
assign AUDIO_L = 16'b0;
wire clk = clk_sys;

reg sys_resetn = 0;

wire clk_pixel; // 720p pixel clock: 74.25MHz
wire clk_p5; // 5x pixel clock: 371.25MHz
wire pll_lock; // HDMI PLL locked
gowin_pll_hdmi pll_hdmi (
    .clkin(clk),
    .clkout(clk_p5),
    .lock(pll_lock)
);
gowin_clkdiv clk_div (
    .hclkin(clk_p5),
    .clkout(clk_pixel),
    .resetn(sys_resetn & pll_lock)
);

reg [7:0] reset_cnt = 255;      // reset for 255 cycles before start everything
always @(posedge clk) begin
    reset_cnt <= reset_cnt == 0 ? 8'b0 : reset_cnt - 1'b1;
    if (reset_cnt == 0)
        sys_resetn <= s1 | reset2;
end

reg  [31:0] run_cnt;
wire        running;
reg  [9:0]  cnt_vs;

always @(posedge clk_sys or posedge reset) //I_clk
begin
    if(reset)
        run_cnt <= 32'd0;
    else if(run_cnt >= 32'd27_000_000)
        run_cnt <= 32'd0;
    else
        run_cnt <= run_cnt + 1'b1;
end

assign  running = (run_cnt < 32'd14_000_000) ? 1'b1 : 1'b0;
//testpattern
testpattern #(
    .VIDEO_ID_CODE(VIDEOID)
) testpattern_inst (
    .clk_pixel(clk_pixel          ),//pixel clock
    .reset    (reset              ),//active high
    .I_mode   ({1'b0,cnt_vs[9:8]} ),//data select
    .frame_width   (frame_width   ),
    .frame_height  (frame_height  ),
    .screen_width  (screen_width  ),
    .screen_height (screen_height ),
    .cx       (cx                 ),
    .cy       (cy                 ),
    .hsync    (hsync              ),
    .vsync    (vsync              ),
    .in_r     (8'd0               ),
    .in_g     (8'd255             ),
    .in_b     (8'd0               ),
    .out_r    (red                ),   
    .out_g    (green              ),
    .out_b    (blue               )
);




always_ff@(posedge clk_pixel) 
begin
    if (audio_divider != AUDIO_CLK_DELAY - 1) 
        audio_divider++;
    else begin 
        clk_audio <= ~clk_audio; 
        audio_divider <= 0; 
    end
end



hdmi #(
    .VIDEO_ID_CODE(VIDEOID),
    .DVI_OUTPUT(0),
    .VIDEO_REFRESH_RATE(VIDEO_REFRESH),
    .IT_CONTENT(1),
    .AUDIO_RATE(AUDIO_RATE),
    .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
    .START_X(0),
    .START_Y(0)
) hdmi_inst (
    .clk_pixel_x5(clk_p5),
    .clk_pixel(clk_pixel),
    .clk_audio(clk_audio),
    .rgb(blank?24'b0:{red, green, blue}),
    .reset(reset),
    .audio_sample_word({AUDIO_L, AUDIO_R}),
    .tmds(tmds),
    .tmds_clock(tmds_clock),
    .cx(cx),
    .cy(cy),
    .frame_width(frame_width),
    .frame_height(frame_height),
    .screen_width(screen_width),
    .screen_height(screen_height),
    .vsync(vsync),
    .hsync(hsync)
);

always @(posedge clk_pixel) vsync_latched <= vsync;

always @(posedge clk_pixel or posedge reset) begin
    if (reset) cnt_vs <= 0;
    else if (vsync_latched && !vsync) cnt_vs <= cnt_vs + 1'b1; // falling edge of vsync
end

assign led = ~{cnt_vs[8:5], sys_resetn, pll_lock};
//assign led = ~{cnt_vs[8:3]};
//assign led = ~{green[7:2]};


// Gowin TMDS output buffer
ELVDS_OBUF tmds_bufds [3:0] (
    .I({clk_pixel, tmds}),
    .O({tmds_clk_p, tmds_d_p}),
    .OB({tmds_clk_n, tmds_d_n})
);


endmodule

