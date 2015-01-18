import bus_package::*;
import cache_package::*;

module msi_protocol
(
    input              enable,
    input              load, store, tag_match,
    input        [1:0] state,
    output logic       hit, miss, writeback,
    output logic [1:0] state_out, command_out,
    output logic       increment, decrement
);
    
    always_comb
    begin
        if (enable && load && !tag_match && (state == M))
        begin // read miss
            state_out   = S;
            command_out = bus_read;
            hit         = 0;
            miss        = 1;
            writeback   = 1;
            increment   = 1;
            decrement   = 1;
        end
        if (enable && load && tag_match && (state == M))
        begin // read hit
            state_out   = S;
            command_out = bus_read;
            hit         = 1;
            miss        = 0;
            writeback   = 0;
            increment   = 0;
            decrement   = 0;            
        end
        else if (enable && store && tag_match && (state == M))
        begin // write hit
            state_out   = M;
            command_out = '0;
            hit         = 1;
            miss        = 0;
            writeback   = 0;
            increment   = 0;
            decrement   = 0;
        end
        else if (enable && store && !tag_match && (state == M))
        begin // write miss
            state_out   = M;
            command_out = bus_readex;
            hit         = 0;
            miss        = 1;
            writeback   = 1;
            increment   = 1;
            decrement   = 1;
        end
        else if (enable && load && tag_match && (state == S))
        begin // read hit
            state_out   = S;
            command_out = '0;
            hit         = 1;
            miss        = 0;
            writeback   = 0;
            increment   = 0;
            decrement   = 0;
        end
        else if (enable && load && !tag_match && (state == S))
        begin // read miss
            state_out   = S;
            command_out = bus_read;
            hit         = 0;
            miss        = 1;
            writeback   = 0;
            increment   = 1;
            decrement   = 1;
        end
        else if (enable && store && tag_match && (state == S))
        begin
            state_out   = M;
            command_out = bus_upgrade;
            hit         = 0;
            miss        = 1;
            writeback   = 0;
            increment   = 0;
            decrement   = 0;
        end
        else if (enable && store && !tag_match && (state == S))
        begin
            state_out   = M;
            command_out = bus_readex;
            hit         = 0;
            miss        = 1;
            writeback   = 0;
            increment   = 1;
            decrement   = 1;
        end
        else if (enable && load && (state == I))
        begin // read miss
            state_out   = S;
            command_out = bus_read;
            hit         = 0;
            miss        = 1;
            writeback   = 0;
            increment   = 1;
            decrement   = 0;
        end
        else if (enable && store && (state == I))
        begin // write miss
            state_out   = M;
            command_out = bus_readex;
            hit         = 0;
            miss        = 1;
            writeback   = 0;
            increment   = 1;
            decrement   = 0;
        end
        else
        begin
            state_out   = I;
            command_out = '0;
            hit         = 1;
            miss        = 0;
            writeback   = 0;
            increment   = 0;
            decrement   = 0;
        end
    end

endmodule // msi_protocol
