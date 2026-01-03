class Register
    string name;
    rand bit [3:0] rank;
    rand bit [3:0] pages;

    function new(string name) 
        this.name = name
    endfunction

    function print()
        $display("name = %0s | rank = %0d | pages = %0d", this.name, this.rank, this.pages)
    endfunction
endclass

module testbench;
    bit [3:0][7:0] test_data;
    Register rt[4];
    string names[4] = '{"a", "b", "c", "d"};

    initial begin
        for (int i = 0; i < 4; i++) begin
            rt[i] = new (names[i]);
            rt[i].randomize();
            rt[i].print()
        end

        test_data = 8'hdeadbeef;
        for (int i = 0; i < $size(test_data); i++) begin
            $display("test_data[%0d] = %0d", i, test_data[i]);
        end
    end
endmodule