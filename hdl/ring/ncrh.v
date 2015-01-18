interface ncrh_interface;
    logic          probe;
    logic [31:0]   address;
    logic          non_shared;
    
    modport bus
    (
        input probe, address,
        output non_shared
    );
    
    modport ring
    (
        output probe, address,
        input non_shared
    );
endinterface // ncrh_interface
