import constants_pkg::*;

module gpu_top(
    // System
    clk,
    rst_n,
    
    // Control Interface
    start,
    op_code,
    cfg_data,
    
    // Memory Request Interface (to external SRAM)
    m_req_vld,
    m_req_rdy,
    m_req_addr,
    
    // Memory Response Interface (from external SRAM)
    m_rsp_vld,
    m_rsp_rdy,
    m_rsp_data,
    
    // Result Output Interface
    result_vld,
    result_rdy,
    result_data,
    
    // Status
    busy
);
    input wire clk, rst_n, start;
    input wire [1:0] op_code;
    input wire [ADDR_WIDTH-1:0] cfg_data;
    
    output wire m_req_vld;
    input wire m_req_rdy;
    output wire [ADDR_WIDTH-1:0] m_req_addr;
    
    input wire m_rsp_vld;
    output wire m_rsp_rdy;
    input wire [DATA_WIDTH-1:0] m_rsp_data;
    
    output wire result_vld;
    input wire result_rdy;
    output wire [ACC_WIDTH-1:0] result_data;
    
    output wire busy;

    wire core_snk_vld;
    wire core_snk_rdy;
    wire [DATA_WIDTH-1:0] core_snk_data;
    
    fetch_engine fetch_engine_inst(
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .op_code(op_code),
        .cfg_data(cfg_data),
        .m_req_vld(m_req_vld),
        .m_req_rdy(m_req_rdy),
        .m_req_addr(m_req_addr),
        .m_rsp_vld(m_rsp_vld),
        .m_rsp_rdy(m_rsp_rdy),
        .m_rsp_data(m_rsp_data),
        .src_vld(core_snk_vld),
        .src_rdy(core_snk_rdy),
        .src_data(core_snk_data)
    );

    matrix_core matrix_core_inst(
        .clk(clk),
        .rst_n(rst_n),
        .snk_vld(core_snk_vld),
        .snk_rdy(core_snk_rdy),
        .snk_data(core_snk_data),
        .src_vld(result_vld),
        .src_rdy(result_rdy),
        .src_data(result_data)
    );

    assign busy = (m_req_vld || result_vld);

endmodule