import constants::*;

module matrix_core(
    //inputs
    snk_vld, snk_rdy, snk_data,
    //outputs
    src_vld, src_rdy, src_data
)
    input snk_vld, snk_rdy, snk_data;
    output src_vld, src_rdy, src_data;

    reg [DATA_WIDTH-1:0] mat_weights;
    reg [DATA_WIDTH-1:0] vec_inputs;
    reg [DATA_WIDTH-1:0] mat_outputs;

    always @ (posedge clk) begin
        if (snk_vld) begin
            mat_weights <= snk_data;
        end
    end

endmodule