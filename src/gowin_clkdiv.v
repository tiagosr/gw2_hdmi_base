
// divide by 5
module gowin_clkdiv (clkout, hclkin, resetn);

output clkout;
input hclkin;
input resetn;


CLKDIV clkdiv_inst (
    .RESETN(resetn),
    .HCLKIN(hclkin),
    .CLKOUT(clkout),
    .CALIB(1'b1)
);

defparam clkdiv_inst.DIV_MODE = "5";
defparam clkdiv_inst.GSREN = "false";

endmodule //Gowin_CLKDIV