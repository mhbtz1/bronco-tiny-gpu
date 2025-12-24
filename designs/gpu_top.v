import constants_pkg::*;

module gpu_top(
    //inputs
    clk, src_vld, src_rdy, src_data,
    //outputs
    snk_vld, snk_rdy, snk_data, busy, result_vld, result_rdy, result_data,
);
    input clk, src_vld, src_rdy, src_data;
    wire snk_vld, snk_rdy, snk_data, busy, result_vld, result_rdy, result_data;

    reg [ADDR_WIDTH-1:0] REG_W_BASE;
    reg [ADDR_WIDTH-1:0] REG_X_BASE;
    reg [1:0] REG_STATUS;
    
    reg fetch_engine_rst_n;
    reg fetch_engine_op_code;
    reg fetc_engine_start;
    reg fetch_engine_cfg_data;
    reg fetch_engine_m_req_vld;
    reg fetch_engine_m_req_rdy;
    reg fetch_engine_m_req_addr;
    reg fetch_engine_m_rsp_vld;
    reg fetch_engine_m_rsp_rdy;
    reg fetch_engine_m_rsp_addr;
    
    fetch_engine fetch_engine_inst(
        .clk(clk),
        .rst_n(fetch_engine_rst_n),
        .start(fetch_engine_start),
        .op_code(fetch_engine_op_code),
        .cfg_data(fetch_engine_cfg_data),
        .m_req_vld(fetch_engine_m_req_vld),
        .m_req_rdy(fetch_engine_m_req_rdy),
        .m_req_addr(fetch_engine_m_req_addr),
        .m_rsp_vld(fetch_engine_m_rsp_vld),
        .m_rsp_data(fetch_engine_m_rsp_data),
        .src_vld(output_vld),
        .src_rdy(output_rdy),
        .src_data(output_data)
    );

    always @ (posedge clk) begin
        if (op_code == FETCH_ENGINE_SET_W_BASE) begin
            REG_W_BASE <= cfg_data;
        end
        else if (op_code == FETCH_ENGINE_SET_X_BASE) begin
            REG_X_BASE <= cfg_data;
        end
        else if (op_code == FETCH_ENGINE_RUN) begin
            fetch_engine_start <= 1;
            fetch_engine_op_code <= op_code;
            fetch_engine_cfg_data <= cfg_data;
            fetch_engine_m_req_vld <= 1;
            fetch_engine_m_req_addr <= REG_W_BASE;
            fetch_engine_m_req_rdy <= 1;
            fetch_engine_m_rsp_vld <= 0;
            fetch_engine_m_rsp_rdy <= 0;
            fetch_engine_m_rsp_addr <= 0;
            fetch_engine_m_rsp_addr <= 0;
        end
    end
endmodule