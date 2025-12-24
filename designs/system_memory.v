module SRAMMemory (clk, src_vld, src_rdy, src_data, load_state, w_addr, x_addr, output_rdy, output_vld, output_data);
    input clk, src_vld, src_rdy, src_cfg, load_sate, w_addr, x_addr;
    output output_rdy, output_vld, output_data;

    reg [MAT_DIM * MAT_DIM * DATA_WIDTH-1:0] w_memory; // stores a 4 * 4 matrix
    reg [X_DEPTH * DATA_WIDTH-1:0] x_memory; // 
    reg [X_DEPTH * DATA_WIDTH-1:0] acc_memory;

    always @ (posedge clk) begin
        if (src_vld && src_rdy && src_cfg == MATRIX_CORE_LOAD_W) begin
            output_vld <= 1;
            if (src_cfg == MATRIX_CORE_LOAD_W) begin
                output_data <= w_memory[src_data:src_data+DATA_WIDTH];
                output_rdy <= 1;
            end
            if (src_cfg == MATRIX_CORE_LOAD_X) begin
                output_data <= x_memory[src_data:src_data+DATA_WIDTH];
                output_rdy <= 1;
            end
            if (src_cfg == MATRIX_CORE_COMPUTE) begin
                output_data <= acc_memory[src_data:src_data+DATA_WIDTH];
                output_rdy <= 1;
            end
        end
    end

endmodule