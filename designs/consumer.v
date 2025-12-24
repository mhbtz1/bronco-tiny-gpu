import constants_pkg::*;

module matrix_core(
    //inputs
    clk, snk_vld, snk_rdy, snk_data,
    //outputs
    src_vld, src_rdy, src_data,
);
    input clk, snk_vld, snk_data, src_vld, src_data;
    output snk_rdy, src_rdy;

    reg [2:0] load_state = 2'b00;

    reg [DATA_WIDTH-1:0] wt_addr = 0;
    reg [DATA_WIDTH-1:0] x_addr = 0;
    reg [DATA_WIDTH-1:0] acc_addr = 0;

    SRAMMemory sram_memory_inst(
        .clk(clk),
        .src_vld(snk_vld),
        .src_rdy(snk_rdy),
        .src_data(snk_data),
        .load_state(load_state),
        .w_addr(w_addr),
        .x_addr(x_addr),
        .output_rdy(src_rdy),
        .output_vld(src_vld),
        .output_data(src_data)
    );

    always @ (posedge clk) begin
        if (snk_vld && snk_rdy) begin
            if (load_state == MATRIX_CORE_LOAD_W) begin
                w_addr <= w_addr + (DATA_WIDTH - 1); 
            end
            if (load_state == MATRIX_CORE_LOAD_X) begin
                x_addr <= x_addr + (DATA_WIDTH - 1);
            end
            if (load_state == MATRIX_CORE_COMPUTE) begin
                acc_addr <= acc_addr + (DATA_WIDTH - 1);
            end
        end
    end

endmodule