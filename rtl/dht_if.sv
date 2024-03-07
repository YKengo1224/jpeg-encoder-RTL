`timescale 1ns/1ps
interface  dht_if
#(
    parameter int CODE_LENGTH   = 16,
    parameter int DC_VVEC_SIZE  = 12,                               // DC
    parameter int AC_VVEC_SIZE  = 162
);

    
    

    logic [15:0] y_dc_huffcode[DC_VVEC_SIZE-1:0];
    logic [7:0]  y_dc_hufflength[DC_VVEC_SIZE-1:0];   //最後のレジスタは終わりを表す記号

    logic [15:0] uv_dc_huffcode[DC_VVEC_SIZE-1:0];
    logic [7:0]  uv_dc_hufflength[DC_VVEC_SIZE-1:0];

    logic [15:0] y_ac_huffcode[15:0][9:0];
    logic [7:0] y_ac_hufflength[15:0][9:0];
    //logic [15:0] y_ac_huffcode[15:0][9:0];
    //logic [7:0] y_ac_hufflength[15:0][9:0];
    // logic [15:0] y_ac_huffcode[159:0];
    // logic [7:0] y_ac_hufflength[159:0];

    logic [15:0] y_eob;    
    logic [7:0] y_eob_len;
    logic [15:0] y_zrl;
    logic [7:0] y_zrl_len;

    logic [15:0] uv_ac_huffcode[15:0][9:0];
    logic [7:0] uv_ac_hufflength[15:0][9:0];
    // logic [15:0] uv_ac_huffcode[159:0];
    // logic [7:0] uv_ac_hufflength[159:0];
    logic [15:0] uv_eob;    
    logic [7:0] uv_eob_len;
    logic [15:0] uv_zrl;
    logic [7:0] uv_zrl_len;



    // modport master (
    //     output marker           ,
    //     output y_dc_huffcode    ,
    //     output y_dc_hufflength  ,
    //     output uv_dc_huffcode   , 
    //     output uv_dc_hufflength ,
    //     output y_ac_huffcode    ,
    //     output y_ac_hufflength  ,
    //     output uv_ac_huffcode   , 
    //     output uv_ac_hufflength 
    // );


    // modport slave (
    //     input marker           ,
    //     input y_dc_huffcode    ,
    //     input y_dc_hufflength  ,
    //     input uv_dc_huffcode   , 
    //     input uv_dc_hufflength ,
    //     input y_ac_huffcode    ,
    //     input y_ac_hufflength  ,
    //     input uv_ac_huffcode   , 
    //     input uv_ac_hufflength 
    // );

    // modport ac_master(
    //     output y_ac_huffcode    ,
    //     output y_ac_hufflength  ,
    //     output uv_ac_huffcode   , 
    //     output uv_ac_hufflength 
    // );

    // modport ac_slave(
    //     input y_ac_huffcode    ,
    //     input y_ac_hufflength  ,
    //     input uv_ac_huffcode   , 
    //     input uv_ac_hufflength 
    // );

    modport master(
        output y_dc_huffcode    ,
        output y_dc_hufflength  ,
        output uv_dc_huffcode   , 
        output uv_dc_hufflength ,

        output y_ac_huffcode    ,
        output y_ac_hufflength  ,
        output y_eob,    
        output y_eob_len,
        output y_zrl,
        output y_zrl_len,
        output uv_ac_huffcode   , 
        output uv_ac_hufflength ,
        output uv_eob,    
        output uv_eob_len,
        output uv_zrl,
        output uv_zrl_len


    );

    modport slave(
        input y_dc_huffcode    ,
        input y_dc_hufflength  ,
        input uv_dc_huffcode   , 
        input uv_dc_hufflength ,

        input y_ac_huffcode    ,
        input y_ac_hufflength  ,
        input y_eob,    
        input y_eob_len,
        input y_zrl,
        input y_zrl_len,
        input uv_ac_huffcode   , 
        input uv_ac_hufflength ,
        input uv_eob,    
        input uv_eob_len,
        input uv_zrl,
        input uv_zrl_len
    );

endinterface
