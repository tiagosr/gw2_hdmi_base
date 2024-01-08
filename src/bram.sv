
// Single port RAM on the Gowin LittleBee FPGAs
// 9-bit address 32-bit data
// 10-bit address 16-bit data
// 11-bit address 8-bit data

module spram8
#(parameter addr_width = 11,
  parameter mem_init_file = "",
  parameter int mem_init_offset = 0)
(
    input wire clock,
    input wire reset = 1'b0,
    input wire[addr_width-1:0] address,
    input wire[7:0] data = 8'b0,
    input wire wren = 1'b0,
    output logic[7:0] q,
    input wire cs = 1'b1
) /*synthesis syn_ramstyle="block_ram"*/;

reg [7:0] mem[addr_width-1:0];

generate
initial begin
    if (mem_init_file != "") begin
        $readmemh(mem_init_file, mem, mem_init_offset, mem_init_offset + (2 ** addr_width));
    end
end
endgenerate

always @(posedge clock) begin
    if (reset) begin
        q <= 8'bz;
    end else begin
        if (cs && wren) q <= data;
        else if (cs) q <= mem[address];

    end
end

always @(posedge clock) begin
    if (cs && wren) mem[address] <= data;
end

endmodule


module spram16
#(parameter addr_width = 10,
  parameter mem_init_file = "",
  parameter int mem_init_offset = 0)
(
    input wire clock,
    input wire reset = 1'b0,
    input wire[addr_width-1:0] address,
    input wire[15:0] data = 16'b0,
    input wire wren = 1'b0,
    output logic[15:0] q,
    input wire cs = 1'b1
) /*synthesis syn_ramstyle="block_ram"*/;

reg [15:0] mem[addr_width-1:0];

generate
initial begin
    if (mem_init_file != "") begin
        $readmemh(mem_init_file, mem, mem_init_offset, mem_init_offset + (2 ** addr_width) * 2);
    end
end
endgenerate

always @(posedge clock) begin
    if (reset) begin
        q <= 16'bz;
    end else begin
        if (cs && wren) q <= data;
        else if (cs) q <= mem[address];
    end
end

always @(posedge clock) begin
    if (cs && wren) mem[address] <= data;
end
endmodule


module spram32
#(parameter addr_width = 9,
  parameter mem_init_file = "",
  parameter int mem_init_offset = 0)
(
    input wire clock,
    input wire reset = 1'b0,
    input wire[addr_width-1:0] address,
    input wire[31:0] data = 31'b0,
    input wire wren = 1'b0,
    output logic[31:0] q,
    input wire cs = 1'b1
) /*synthesis syn_ramstyle="block_ram"*/;

reg [31:0] mem[addr_width-1:0];

generate
initial begin
    if (mem_init_file != "") begin
//        $readmemh(mem_init_file, mem, mem_init_offset, mem_init_offset + (2 ** addr_width) * 4); // TODO: figure out a fix for this?
        $readmemh(mem_init_file, mem, mem_init_offset);
    end
end
endgenerate

always @(posedge clock) begin
    if (reset) begin
        q <= 32'bz;
    end else begin
        if (cs && wren) q <= data;
        else if (cs) q <= mem[address];
    end
end

always @(posedge clock) begin
    if (cs && wren) mem[address] <= data;
end
endmodule


/** ROM-like block RAM */

module sprom8
#(parameter addr_width = 11,
  parameter mem_init_file = "",
  parameter int mem_init_offset = 0)
(
    input wire clock,
    input wire reset = 1'b0,
    input wire[addr_width-1:0] address,
    output logic[7:0] q,
    input wire cs = 1'b1
) /*synthesis syn_ramstyle="block_ram"*/;

reg [7:0] mem[addr_width-1:0];

generate
initial begin
    int i;
    if (mem_init_file != "") begin
        $readmemh(mem_init_file, mem);
    end
end
endgenerate

always @(posedge clock) begin
    if (reset) begin
        q <= 8'bz;
    end else begin
        if (cs) q <= mem[address];
    end
end
endmodule


module sprom16
#(parameter addr_width = 10,
  parameter mem_init_file = "",
  parameter int mem_init_offset = 0)
(
    input wire clock,
    input wire reset = 1'b0,
    input wire[addr_width-1:0] address,
    output logic[15:0] q,
    input wire cs = 1'b1
) /*synthesis syn_ramstyle="block_ram"*/;

reg [15:0] mem[addr_width-1:0];

generate
initial begin
    if (mem_init_file != "") begin
        $readmemh(mem_init_file, mem);
    end
end
endgenerate

always @(posedge clock) begin
    if (reset) begin
        q <= 16'bz;
    end else begin
        if (cs) q <= mem[address];
    end
end
endmodule


module sprom32
#(parameter addr_width = 9,
  parameter mem_init_file = "",
  parameter int mem_init_offset = 0)
(
    input wire clock,
    input wire reset = 1'b0,
    input wire[addr_width-1:0] address,
    output logic[31:0] q,
    input wire cs = 1'b1
) /*synthesis syn_ramstyle="block_ram"*/;

reg [31:0] mem[addr_width-1:0];

generate
initial begin
    if (mem_init_file != "") begin
        $readmemh(mem_init_file, mem);
    end
end
endgenerate

always @(posedge clock) begin
    if (reset) begin
        q <= 32'bz;
    end else begin
        if (cs) q <= mem[address];
    end
end
endmodule

