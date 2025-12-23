import constants::*;
import skid_buffer::*;
import matrix_core::*;
import fetch_engine::*;

module gpu_top(
    //inputs
    src_vld, src_rdy, src_data
    //outputs
    snk_vld, snk_rdy, snk_data, busy, result_vld, result_rdy, result_data
)
    input src_vld, src_rdy, src_data;
    output snk_vld, snk_rdy, snk_data;

    reg [ADDR_WIDTH-1:0] REG_W_BASE;
    reg [ADDR_WIDTH-1:0] REG_X_BASE;
    reg [ADDR_WIDTH-1:0] REG_STATUS;
    reg [1:0] REG_STATUS;

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
        .m_req_addr(m_req_addr)
    )
endmodule