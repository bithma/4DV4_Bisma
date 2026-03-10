module control_unit (
    input  wire [5:0] opcode,
    output reg        reg_dst,
    output reg        alu_src,
    output reg        mem_to_reg,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        branch, branch_type,
    output reg [3:0]  alu_opcode,
    output reg [1:0]  instruction_RI
);

    // Opcodes
    localparam [5:0] OPC_ADD  = 6'b000001;
    localparam [5:0] OPC_SUB  = 6'b000010;
    localparam [5:0] OPC_ADDI = 6'b000011;
    localparam [5:0] OPC_LW   = 6'b000100;
    localparam [5:0] OPC_SW   = 6'b000101;
    localparam [5:0] OPC_AND  = 6'b000110;
    localparam [5:0] OPC_OR   = 6'b000111;
    localparam [5:0] OPC_NOR  = 6'b001000;
    localparam [5:0] OPC_BEQ  = 6'b001001;
    localparam [5:0] OPC_BNE  = 6'b001010;
    localparam [5:0] OPC_SLT  = 6'b001011;
    localparam [5:0] OPC_EOF  = 6'b001100;

    localparam [3:0] ALU_AND = 4'b0000;
    localparam [3:0] ALU_OR  = 4'b0001;
    localparam [3:0] ALU_ADD = 4'b0010;
    localparam [3:0] ALU_NOR = 4'b0011;
    localparam [3:0] ALU_SUB = 4'b0110;
    localparam [3:0] ALU_SLT = 4'b0111;

always @(*) begin
        reg_dst        = 1'b0;
        alu_src        = 1'b0;
        mem_to_reg     = 1'b0;
        reg_write      = 1'b0;
        mem_read       = 1'b0;
        mem_write      = 1'b0;
        branch         = 1'b0;
        branch_type    = 1'b0;
        alu_opcode     = ALU_ADD;
        instruction_RI = 2'b00;
        
case (opcode)

    OPC_ADD: begin
        reg_dst    = 1'b1;
        reg_write  = 1'b1;
        instruction_RI  = 2'b00;
        alu_opcode = ALU_ADD;
    end

    OPC_SUB: begin
        reg_dst    = 1'b1;
        reg_write  = 1'b1;
        instruction_RI  = 2'b00;
        alu_opcode = ALU_SUB;
    end

    OPC_ADDI: begin
        reg_dst    = 1'b0;
        alu_src    = 1'b1;
        reg_write  = 1'b1;
        instruction_RI  = 2'b01;
        alu_opcode= ALU_ADD;
    end

    OPC_LW: begin
        reg_dst     = 1'b0;
        alu_src     = 1'b1;
        mem_to_reg  = 1'b1;
        reg_write   = 1'b1;
        instruction_RI   = 2'b01;
        alu_opcode = ALU_ADD;
    end

    OPC_SW: begin
        alu_src     = 1'b1;
        mem_write   = 1'b1;
        instruction_RI   = 2'b01;
        alu_opcode = ALU_ADD;
    end

    OPC_AND: begin
        reg_dst     = 1'b1;
        reg_write   = 1'b1;
        instruction_RI   = 2'b00;
        alu_opcode = ALU_AND;
    end

    OPC_OR: begin
        reg_dst     = 1'b1;
        reg_write   = 1'b1;
        instruction_RI   = 2'b00;
        alu_opcode = ALU_OR;
    end

    OPC_NOR: begin
        reg_dst     = 1'b1;
        reg_write   = 1'b1;
        instruction_RI   = 2'b00;
        alu_opcode = ALU_NOR;
    end

    OPC_BEQ: begin
        branch          = 1'b1;
        instruction_RI       = 2'b01;
        alu_opcode     = ALU_SUB;
        branch_type = 1'b0; // beq
    end

    OPC_BNE: begin
        branch          = 1'b1;
        instruction_RI       = 2'b01;
        alu_opcode     = ALU_SUB;
        branch_type = 1'b1; // bne
    end

    OPC_SLT: begin
        reg_dst         = 1'b1;
        reg_write       = 1'b1;
        instruction_RI       = 2'b00;
        alu_opcode     = ALU_SLT;
    end

    OPC_EOF: begin
        instruction_RI       = 2'b10;
    end

    default: begin
        // keep defaults
    end

endcase
end

endmodule