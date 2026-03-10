module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] result,
    output wire        zero,
    output reg         overflow
);
    localparam [3:0] ALU_AND = 4'b0000;
    localparam [3:0] ALU_OR  = 4'b0001;
    localparam [3:0] ALU_ADD = 4'b0010;
    localparam [3:0] ALU_NOR = 4'b0011;
    localparam [3:0] ALU_SUB = 4'b0110;
    localparam [3:0] ALU_SLT = 4'b0111;

    always @* begin
        result   = 32'd0;
        overflow = 1'b0;
        case (alu_op)
            ALU_AND: result = a & b;
            ALU_OR : result = a | b;
            ALU_ADD: begin
            {overflow, result} = a + b;
            end
            ALU_NOR: result = ~(a | b);
            ALU_SUB: result = a - b;
            ALU_SLT: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            default: result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);

endmodule