module regfile (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [4:0]  ra1,
    input  wire [4:0]  ra2,
    input  wire [4:0]  wa,
    input  wire [31:0] wd,
    input  wire        we,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    reg [31:0] regs [0:31];
    integer i;

    // asynchronous reads
    assign rd1 = regs[ra1];
    assign rd2 = regs[ra2];

    // synchronous write + reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end
        else if (we && (wa != 5'd0)) begin
            regs[wa] <= wd;
        end
    end

endmodule