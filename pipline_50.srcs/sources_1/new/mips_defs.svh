`ifndef MIPS_DEFS_SVH
`define MIPS_DEFS_SVH

// -----------------------------------------------------------------------------
// Common types / constants for the 5-stage MIPS pipeline (Inst50).
// -----------------------------------------------------------------------------

typedef logic [31:0] word_t;
typedef logic [31:0] addr_t;
typedef logic [4:0]  reg_addr_t;

localparam word_t RESET_PC = 32'h0000_3000;

// -----------------------------------------------------------------------------
// Instruction fields
// -----------------------------------------------------------------------------

typedef struct packed {
    logic [5:0] op;
    logic [4:0] rs;
    logic [4:0] rt;
    logic [4:0] rd;
    logic [4:0] shamt;
    logic [5:0] funct;
    logic [15:0] imm;
    logic [25:0] target;
} instr_fields_t;

// -----------------------------------------------------------------------------
// Opcode / funct constants (MIPS32)
// -----------------------------------------------------------------------------

localparam logic [5:0] OPC_RTYPE  = 6'h00;
localparam logic [5:0] OPC_REGIMM = 6'h01;
localparam logic [5:0] OPC_J      = 6'h02;
localparam logic [5:0] OPC_JAL    = 6'h03;
localparam logic [5:0] OPC_BEQ    = 6'h04;
localparam logic [5:0] OPC_BNE    = 6'h05;
localparam logic [5:0] OPC_BLEZ   = 6'h06;
localparam logic [5:0] OPC_BGTZ   = 6'h07;
localparam logic [5:0] OPC_ADDI   = 6'h08;
localparam logic [5:0] OPC_ADDIU  = 6'h09;
localparam logic [5:0] OPC_SLTI   = 6'h0A;
localparam logic [5:0] OPC_SLTIU  = 6'h0B;
localparam logic [5:0] OPC_ANDI   = 6'h0C;
localparam logic [5:0] OPC_ORI    = 6'h0D;
localparam logic [5:0] OPC_XORI   = 6'h0E;
localparam logic [5:0] OPC_LUI    = 6'h0F;
localparam logic [5:0] OPC_LB     = 6'h20;
localparam logic [5:0] OPC_LH     = 6'h21;
localparam logic [5:0] OPC_LW     = 6'h23;
localparam logic [5:0] OPC_LBU    = 6'h24;
localparam logic [5:0] OPC_LHU    = 6'h25;
localparam logic [5:0] OPC_SB     = 6'h28;
localparam logic [5:0] OPC_SH     = 6'h29;
localparam logic [5:0] OPC_SW     = 6'h2B;

localparam logic [4:0] RT_BLTZ    = 5'h00;
localparam logic [4:0] RT_BGEZ    = 5'h01;

localparam logic [5:0] FUNCT_SLL      = 6'h00;
localparam logic [5:0] FUNCT_SRL      = 6'h02;
localparam logic [5:0] FUNCT_SRA      = 6'h03;
localparam logic [5:0] FUNCT_SLLV     = 6'h04;
localparam logic [5:0] FUNCT_SRLV     = 6'h06;
localparam logic [5:0] FUNCT_SRAV     = 6'h07;
localparam logic [5:0] FUNCT_JR       = 6'h08;
localparam logic [5:0] FUNCT_JALR     = 6'h09;
localparam logic [5:0] FUNCT_SYSCALL  = 6'h0C;
localparam logic [5:0] FUNCT_MFHI     = 6'h10;
localparam logic [5:0] FUNCT_MTHI     = 6'h11;
localparam logic [5:0] FUNCT_MFLO     = 6'h12;
localparam logic [5:0] FUNCT_MTLO     = 6'h13;
localparam logic [5:0] FUNCT_MULT     = 6'h18;
localparam logic [5:0] FUNCT_MULTU    = 6'h19;
localparam logic [5:0] FUNCT_DIV      = 6'h1A;
localparam logic [5:0] FUNCT_DIVU     = 6'h1B;
localparam logic [5:0] FUNCT_ADD      = 6'h20;
localparam logic [5:0] FUNCT_ADDU     = 6'h21;
localparam logic [5:0] FUNCT_SUB      = 6'h22;
localparam logic [5:0] FUNCT_SUBU     = 6'h23;
localparam logic [5:0] FUNCT_AND      = 6'h24;
localparam logic [5:0] FUNCT_OR       = 6'h25;
localparam logic [5:0] FUNCT_XOR      = 6'h26;
localparam logic [5:0] FUNCT_NOR      = 6'h27;
localparam logic [5:0] FUNCT_SLT      = 6'h2A;
localparam logic [5:0] FUNCT_SLTU     = 6'h2B;

// -----------------------------------------------------------------------------
// Pipeline control enums
// -----------------------------------------------------------------------------

typedef enum logic [4:0] {
    ALU_ADD  = 5'd0,
    ALU_SUB  = 5'd1,
    ALU_AND  = 5'd2,
    ALU_OR   = 5'd3,
    ALU_XOR  = 5'd4,
    ALU_NOR  = 5'd5,
    ALU_SLT  = 5'd6,
    ALU_SLTU = 5'd7,
    ALU_SLL  = 5'd8,
    ALU_SRL  = 5'd9,
    ALU_SRA  = 5'd10,
    ALU_SLLV = 5'd11,
    ALU_SRLV = 5'd12,
    ALU_SRAV = 5'd13,
    ALU_LUI  = 5'd14
} alu_op_t;

typedef enum logic [1:0] {
    WB_ALU  = 2'd0,
    WB_MEM  = 2'd1,
    WB_LINK = 2'd2,
    WB_MDU  = 2'd3
} wb_sel_t;

typedef enum logic [1:0] {
    MEM_W = 2'd0,
    MEM_H = 2'd1,
    MEM_B = 2'd2
} mem_width_t;

typedef enum logic [3:0] {
    MDUCMD_NONE               = 4'd0,
    MDUCMD_READ_HI            = 4'd1,
    MDUCMD_READ_LO            = 4'd2,
    MDUCMD_WRITE_HI           = 4'd3,
    MDUCMD_WRITE_LO           = 4'd4,
    MDUCMD_START_SIGNED_MUL   = 4'd5,
    MDUCMD_START_UNSIGNED_MUL = 4'd6,
    MDUCMD_START_SIGNED_DIV   = 4'd7,
    MDUCMD_START_UNSIGNED_DIV = 4'd8
} mdu_cmd_t;

// -----------------------------------------------------------------------------
// Pipeline registers
// -----------------------------------------------------------------------------

typedef struct packed {
    logic  valid;
    word_t pc;
    word_t instr;
} if_id_t;

typedef struct packed {
    logic      valid;
    word_t     pc;

    // decoded register specifiers
    reg_addr_t rs;
    reg_addr_t rt;
    reg_addr_t rd;
    reg_addr_t dest;
    logic [4:0] shamt;

    // operand values (from regfile / forwarding)
    word_t     rs_val;
    word_t     rt_val;
    word_t     imm_ext;
    word_t     link_addr; // pc + 8 (for JAL/JALR, with delay slot)

    // writeback
    logic      reg_write;
    wb_sel_t   wb_sel;

    // memory
    logic      mem_read;
    logic      mem_write;
    mem_width_t mem_width;
    logic      mem_unsigned; // for loads

    // execute
    logic      alu_src_imm;
    alu_op_t   alu_op;

    // MDU
    mdu_cmd_t  mdu_cmd;

    // syscall (handled at commit)
    logic      is_syscall;
} id_ex_t;

typedef struct packed {
    logic      valid;
    word_t     pc;

    // writeback
    logic      reg_write;
    wb_sel_t   wb_sel;
    reg_addr_t dest;
    word_t     ex_result; // ALU/LINK/MDU result (non-load)

    // memory
    logic      mem_read;
    logic      mem_write;
    mem_width_t mem_width;
    logic      mem_unsigned;
    word_t     mem_addr;   // byte address
    word_t     store_data; // original/forwarded rt

    // syscall (flow through pipeline, commit at WB)
    logic      is_syscall;
} ex_mem_t;

typedef struct packed {
    logic      valid;
    word_t     pc;

    // writeback
    logic      reg_write;
    reg_addr_t dest;
    word_t     wb_data;

    // memory write trace (commit-time print)
    logic      mem_write_commit;
    word_t     mem_write_addr_aligned;
    word_t     mem_write_data_word;

    // syscall
    logic      is_syscall;
} mem_wb_t;

`endif // MIPS_DEFS_SVH
