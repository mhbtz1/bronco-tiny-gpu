module smolconsumer(
    clk,
    rst_n,
    vld,
    rdy,
    data
);
    input clk, rst_n;
    input [31:0] data;
    input vld;
    output reg rdy;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdy <= 0;
        end else if (vld) begin
            // data which has been retrieved from the consumer
            $display("data processed = [%08h]", data);
            rdy <= 1;
        end
    end
endmodule