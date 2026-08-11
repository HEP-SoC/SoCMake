`include "includes.svh"

module mod1;

    `ifdef SUBMOD1_INCLUDED
        submod1 submod_i();
    `elsif SUBMOD2_INCLUDED
        submod2 submod_i();
    `endif

endmodule;
