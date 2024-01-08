module i2c_controller (
    input wire clk,
    input wire rst,

    /* Host interface */
    input wire[6:0]  in_addr,
    input wire[7:0]  in_data,
    output logic[8:0] out_data,
    input wire       in_enable,
    input wire       in_rw,
    output wire      out_ready,


    /* I2C interface */
    inout wire i2c_sda,
    inout wire i2c_scl,

    /* Config */
    input wire[15:0] prescale,
    input wire stop_on_idle
 );

typedef enum bit[4:0] {
    STATE_IDLE,
    STATE_START,
    STATE_ADDRESS,
    STATE_WRITE_DATA,
    STATE_WRITE_ACK,
    STATE_READ_DATA,
    STATE_READ_ACK,
    STATE_READ_ACK2,
    STATE_STOP
} t_state_reg;

localparam DIVIDEBY = 4;

t_state_reg state = STATE_IDLE, state_next;
bit[7:0] latched_addr_rw;
bit[7:0] latched_data;
bit[7:0] counter;
bit[7:0] counter2 = 0;

bit write_enable;
bit sda_out;
bit i2c_scl_enable = 0;
bit i2c_clk = 1;

assign out_ready = ((rst == 0) && (state == STATE_IDLE)) ? 1 : 0;
assign i2c_scl = (i2c_scl_enable == 0) ? 1 : i2c_clk;
assign i2c_sda = (write_enable == 1) ? sda_out : 1'bz;

always @(posedge clk) begin
    if (counter2 == (DIVIDEBY / 2) - 1) begin
        i2c_clk <= ~i2c_clk;
        counter2 <= 0;
    end else counter2 <= counter2 + 1;
end

always @(negedge i2c_clk, posedge rst) begin
    if (rst == 1) begin
        i2c_scl_enable <= 0;
    end else begin
        i2c_scl_enable <= ((state == STATE_IDLE) || (state == STATE_START) || (state == STATE_STOP)) ? 0 : 1;
    end
end

always @(posedge i2c_clk, posedge rst) begin
    if (rst == 1) begin
        state <= STATE_IDLE;
    end else begin
        case (state)
            STATE_IDLE: begin
                if (in_enable) begin
                    state <= STATE_START;
                    latched_addr_rw <= {in_addr, in_rw};
                    latched_data <= in_data;
                end else state <= STATE_IDLE;
            end
            STATE_START: begin
                counter <= 7;
                state <= STATE_ADDRESS;
            end
            STATE_ADDRESS: begin
                if (counter <= 0) state <= STATE_READ_ACK;
                else counter <= counter - 1'b1;
            end
            STATE_READ_ACK: begin
                if (i2c_sda == 0) begin
                    counter <= 7;
                    if (latched_addr_rw[0] == 0) state <= STATE_WRITE_DATA;
                    else state <= STATE_READ_DATA;
                end else state <= STATE_STOP;
            end
            STATE_WRITE_DATA: begin
                if (counter == 0) state <= STATE_READ_ACK2;
                else counter <= counter - 1'b1;
            end
            STATE_READ_ACK2: begin
                state <= ((i2c_sda == 0) && (in_enable == 1)) ? STATE_IDLE : STATE_STOP;
            end
            STATE_READ_DATA: begin
                out_data[counter] <= i2c_sda;
                if (counter == 0) state <= STATE_WRITE_ACK;
                else counter <= counter - 1'b1;
            end
            STATE_WRITE_ACK: begin
                state <= STATE_STOP;
            end
            STATE_STOP: begin
                state <= STATE_IDLE;
            end
        endcase
    end
end

always @(negedge i2c_clk, posedge rst) begin
    if (rst == 1) begin
        write_enable <= 1;
        sda_out <= 1;
    end else begin
        case (state)
            STATE_START: begin
                write_enable <= 1;
                sda_out <= 0;
            end
            STATE_ADDRESS: begin
                sda_out <= latched_addr_rw[counter];
            end
            STATE_READ_ACK: begin
                write_enable <= 0;
            end
            STATE_WRITE_DATA: begin
                write_enable <= 1;
                sda_out <= latched_data[counter];
            end
            STATE_WRITE_ACK: begin
                write_enable <= 1;
                sda_out <= 0;
            end
            STATE_READ_DATA: begin
                write_enable <= 0;
            end
            STATE_STOP: begin
                write_enable <= 1;
                sda_out <= 1;
            end
        endcase
    end
end

endmodule