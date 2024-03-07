use std::fs::File;
use std::io::{BufReader,BufRead};
use std::str::FromStr;

use crate::marker::DhtMarker;
use crate::quantization::ZigZag;
use bitvec::prelude::*;


pub struct HuffmanEncode {
    pub y_dc_huffcode_table: Vec<u16>,
    pub y_dc_hufflength_table: Vec<u8>,
    pub y_ac_huffcode_table: Vec<Vec<u16>>,
    pub y_ac_hufflength_table: Vec<Vec<u8>>,
    pub y_eob: u16,
    pub y_eob_length: u8,
    pub y_zrl: u16,
    pub y_zrl_length:u8,

    pub uv_dc_huffcode_table: Vec<u16>,
    pub uv_dc_hufflength_table: Vec<u8>,
    pub uv_ac_huffcode_table: Vec<Vec<u16>>,
    pub uv_ac_hufflength_table: Vec<Vec<u8>>,
    pub uv_eob: u16,
    pub uv_eob_length: u8,
    pub uv_zrl: u16,
    pub uv_zrl_length:u8,
    
    pub dc_y_prev:i16,
    pub dc_u_prev:i16,
    pub dc_v_prev:i16,
    pub y_code:Vec<Vec<(u16,u8,u16,u8)>>,
    pub u_code:Vec<Vec<(u16,u8,u16,u8)>>,
    pub v_code:Vec<Vec<(u16,u8,u16,u8)>>,
    pub code_vector:Vec<u8>
    
}


impl HuffmanEncode {
    pub fn new(dht:&DhtMarker) -> HuffmanEncode {


        let (y_dc_huffcode_table,y_dc_hufflength_table) =
            HuffmanEncode::gen_huff_table(&dht.y_dc_vvec,&dht.y_dc_lvec);
        let (uv_dc_huffcode_table,uv_dc_hufflength_table) =
            HuffmanEncode::gen_huff_table(&dht.uv_dc_vvec,&dht.uv_dc_lvec);

        let(y_ac_huffcode_table,y_ac_hufflength_table,
            y_eob,y_eob_length,y_zrl,y_zrl_length) =
            HuffmanEncode::gen_ac_huff_code(&dht.y_ac_vvec,&dht.y_ac_lvec);
        
        let(uv_ac_huffcode_table,uv_ac_hufflength_table,
            uv_eob,uv_eob_length,uv_zrl,uv_zrl_length) =
            HuffmanEncode::gen_ac_huff_code(&dht.uv_ac_vvec,&dht.uv_ac_lvec);

        let dc_y_prev:i16 = 0;
        let dc_u_prev:i16 = 0;
        let dc_v_prev:i16 = 0;
        let y_code = Vec::new();
        let u_code = Vec::new();
        let v_code = Vec::new();
        let code_vector = Vec::new();
        HuffmanEncode{
            y_dc_huffcode_table,
            y_dc_hufflength_table,
            y_ac_huffcode_table,
            y_ac_hufflength_table,
            y_eob,
            y_eob_length,
            y_zrl,
            y_zrl_length,

            uv_dc_huffcode_table,
            uv_dc_hufflength_table,
            uv_ac_huffcode_table,
            uv_ac_hufflength_table,
            uv_eob,
            uv_eob_length,
            uv_zrl,
            uv_zrl_length,
            dc_y_prev,
            dc_u_prev,
            dc_v_prev,
            y_code,
            u_code,
            v_code,
            code_vector,
        }

            

    }

    // genelate huffman_table for DHT marker
    pub fn gen_huff_table(vvec:&Vec<u16>,lvec:&Vec<u8>) -> (Vec<u16>,Vec<u8>){
        
        let mut huff_length: Vec<u8> = vec![0;vvec.len()+1]; //13:end poiter

        let mut huff_code: Vec<u16> = vec![0;vvec.len()];

        let mut i:usize = 1usize;
        let mut j:u8    = 1u8;
        let mut k:usize = 0usize;

        //genelate huff_lengthn
        while !(i>16) {
            if j > lvec[i-1] {
                i += 1;
                j = 1;
            }
            else {
                huff_length[k] = i as u8;
                k += 1;
                j += 1;
            }
        }

        let mut k:usize  = 0usize;
        let mut code:u16 = 0u16;
        let mut si:u8    = huff_length[0];

        //genelate huff_code
        while huff_length[k] == si {
            huff_code[k] = code;
            code += 1;
            k += 1;
            if huff_length[k] == si{
                continue;
            }
            else {
                if huff_length[k] == 0 {
                    break;
                }
                else {
                    code = code << 1;
                    si += 1;
                    loop {
                        if huff_length[k] == si {
                            break;
                        }
                        else {
                            code = code << 1;
                            si += 1;
                        }
                    }
                }
            }
        }

        //pop end pointer
        
        huff_length.pop();
        
        (huff_code,huff_length)
            
    }

    
    fn gen_ac_huff_code(vvec:&Vec<u16>,lvec:&Vec<u8>)
                        -> (Vec<Vec<u16>>,Vec<Vec<u8>>,u16,u8,u16,u8){
        let (huff_code,huff_length) = HuffmanEncode::gen_huff_table(vvec,lvec);

        let mut out_code:Vec<Vec<u16>> = vec![vec![0;10]; 16];
        let mut out_len:Vec<Vec<u8>> = vec![vec![0;10]; 16];
        let mut eob: u16 = 0;
        let mut eob_len: u8 = 0;
        let mut zrl: u16 = 0;
        let mut zrl_len: u8 = 0;

        for i in 0..huff_code.len(){
            let code:u16    = huff_code[i];
            let code_len:u8 = huff_length[i];
            let vve:u16     = vvec[i];
            let length:u16  = vve >> 4;
            let bit:u16     = vve & 0x0F;


            if (length == 0) && (bit == 0) {
                eob     = code;
                eob_len = code_len;
            } else if (length == 0xF) && (bit == 0) {
                zrl     = code;
                zrl_len = code_len;
            } else {
                out_code[length as usize][(bit - 1) as usize] = code;
                out_len[length as usize][(bit - 1) as usize]  = code_len;
            }
        }

        
        
        (out_code,out_len,eob,eob_len,zrl,zrl_len)      
    }


    pub fn encoding(&mut self,zig:ZigZag){

        
        
        for i in 0..zig.zig_y.len(){
            let tmp = self.huff_encoding(&zig.zig_y[i],1);
            self.y_code.push(tmp);
            self.dc_y_prev = zig.zig_y[i][0];
            
            let tmp = self.huff_encoding(&zig.zig_u[i],2);
            self.u_code.push(tmp);
            self.dc_u_prev = zig.zig_u[i][0];
            
            let tmp = self.huff_encoding(&zig.zig_v[i],3);
            self.v_code.push(tmp);
            self.dc_v_prev = zig.zig_v[i][0];
        }
        println!("y:{:?}",self.y_code[0]);
        println!("u:{:?}",self.u_code[0]);
        println!("v:{:?}",self.v_code[0]);
        
    }
    
    //-----------------------------------------------------------
    // function:dc encoding : start
    //-----------------------------------------------------------    
    pub fn huff_encoding(&mut self,mcu:&Vec<i16>,comp:u8)
                         -> Vec<(u16,u8,u16,u8)>{

        let is_y = comp == 1;
        let mut out:Vec<(u16,u8,u16,u8)> = Vec::new();
        //dc encoding
        out.push(self.dc_encoding(&mcu,comp));
        //Ac encoding
        out.extend(self.ac_encoding(&mcu,is_y).iter().cloned());
        
        out
    }

    //end
    //-----------------------------------------------------------    

    
    //-----------------------------------------------------------
    // function:dc encoding : start
    //-----------------------------------------------------------    
    pub fn dc_encoding(&mut self,mcu:&Vec<i16>,comp:u8)
                         ->(u16,u8,u16,u8) {

//        let diff:i16 = (mcu[0] as i16) - (self.dc_prev as i16);
        let diff:i16 = if comp==1{(mcu[0] as i16) - (self.dc_y_prev as i16)}
                       else if comp==2{(mcu[0] as i16) - (self.dc_u_prev as i16)}
                       else {(mcu[0] as i16) - (self.dc_v_prev as i16)}; 

        
        let category = match diff.abs() {
            0 => 0,
            1 => 1,
            2..=3 => 2,
            4..=7 => 3,
            8..=15 => 4,
            16..=31 => 5,
            32..=63 => 6,
            64..=127 => 7,
            128..=255 => 8,
            256..=511 => 9,
            512..=1023 => 10,
            1024..=2048 => 11,
            _ => panic!("Unexpected diff value"),
        };


        let huffman_code = if comp==1 {
            self.y_dc_huffcode_table [category]
        } else {
            self.uv_dc_huffcode_table[category]
        };

        let huff_length = if comp==1 {
            self.y_dc_hufflength_table[category]
        } else {
            self.uv_dc_hufflength_table[category]
        };

        let value = if diff < 0 {
            (!diff.abs()) as u16 // ビット反転
        } else {
            diff as u16
        };

        let value_length = category;

   

        (huffman_code,huff_length,value,value_length as u8)

        
    }
    
    //end
    //-----------------------------------------------------------

    
    //-----------------------------------------------------------
    //function:ac_encoding :start
    //-----------------------------------------------------------
    pub fn ac_encoding(&mut self,mcu:&Vec<i16>,is_y:bool)
                       -> Vec<(u16,u8,u16,u8)>{

        let mut zero_count:usize = 0;
        let mut non_zero_ind:usize = 0;
        for i in 1..mcu.len(){
            if(mcu[i]!=0){
                non_zero_ind = i;
            }
        }

        //select (y or ac) :huffman table
        let (huffcode_table,hufflength_table,
             eob,eob_length,zrl,zrl_length) =
            if is_y {
                (&self.y_ac_huffcode_table,&self.y_ac_hufflength_table,
                 &self.y_eob,&self.y_eob_length,
                 &self.y_zrl,&self.y_zrl_length)
            }else{
                (&self.uv_ac_huffcode_table,
                 &self.uv_ac_hufflength_table,
                 &self.uv_eob,&self.uv_eob_length,
                 &self.uv_zrl,&self.uv_zrl_length)
            };

        
        let mut out:Vec<(u16,u8,u16,u8)> = Vec::new();
        //encoding
        for i in 1..mcu.len(){
            //final non zero index
            if i == (non_zero_ind+1){
                out.push((*eob,*eob_length,0,0));
                break;
            }
            //zero
            else if mcu[i] == 0{
                zero_count += 1;
                if zero_count == 16{
                    out.push((*zrl,*zrl_length,0,0));
                    zero_count = 0;
                    continue;
                }
            }
            // not zero 
            else {
                let category =
		                  match mcu[i].abs() {
			                     0 => 0,
			                     1 => 1,
			                     2..=3 => 2,
			                     4..=7 => 3,
			                     8..=15 => 4,
			                     16..=31 => 5,
			                     32..=63 => 6,
			                     64..=127 => 7,
			                     128..=255 => 8,
			                     256..=511 => 9,
			                     512..=1023 => 10,
			                     _ => panic!("Unexpected diff value"),};
                let huffcode:u16 = huffcode_table[zero_count][(category-1)as usize];
                let hufflength:u8 = hufflength_table[zero_count][(category-1)as usize];
                
                //１の補数表現に変換
                let value = if mcu[i] < 0 {
                    (!mcu[i].abs()) as u16 // ビット反転
                } else {
                    mcu[i] as u16
                };
                out.push((huffcode,hufflength,value,category));
                zero_count = 0;
            }
        }
        
        //return
        out        
    }
    //end
    //-----------------------------------------------------------


    //-----------------------------------------------------------
    //function:gen_code_vector
    //-----------------------------------------------------------

    pub fn gen_code_vector(&mut self){

        //bit vector
        let mut bvec = bitvec![u8,Msb0;];
        let mut bvec_length = 0;

        //loop
        for i in 0..self.y_code.len(){
            //insert y
            for  j in 0..self.y_code[i].len(){
                let (code,code_length,value,value_length) = self.y_code[i][j];

                //push bit vector
                for k in (0..code_length).rev(){
                    bvec.push((code>>k)&1 == 1);
                    bvec_length += 1;
                }
                for k in (0..value_length).rev(){
                    bvec.push((value>>k) & 1 == 1);
                    bvec_length += 1;
                }
            }

            //insert u
            for  j in 0..self.u_code[i].len(){
                let (code,code_length,value,value_length) = self.u_code[i][j];

                //push bit vector
                for k in (0..code_length).rev(){
                    bvec.push((code>>k)&1 == 1);
                    bvec_length += 1;
                }
                for k in (0..value_length).rev(){
                    bvec.push((value>>k) & 1 == 1);
                    bvec_length += 1;
                }
            }
            
            //insert v
            for  j in 0..self.y_code[i].len(){
                let (code,code_length,value,value_length) = self.v_code[i][j];

                //push bit vector
                for k in (0..code_length).rev(){
                    bvec.push((code>>k)&1 == 1);
                    bvec_length += 1;
                }
                for k in (0..value_length).rev(){
                    bvec.push((value>>k) & 1 == 1);
                    bvec_length += 1;
                }
            }
        }


        //staffing
        while(bvec_length % 8) != 0{
            bvec.push(true);
            bvec_length += 1;
        }
        

        self.code_vector =  bvec.into_vec();
    }


    pub fn hw_check(&self,file_name:&String) ->Result<(),String>{

        let file = File::open(file_name).
            expect(&format!("Could not file:{}",file_name));

        let reader = BufReader::new(file);

        let mut huffman:Vec<u8> = Vec::new();

        for(i,line) in reader.lines().enumerate(){
            match line {
                Ok(line) => {
                    let l = line.trim();
                    match u8::from_str(&l){
                        Ok(value) => huffman.push(value),
                        Err(_) => {
                            println!("Could not parse line {} {:?}",i,line);
                            return Err(format!("Coult not parse line {} as u8",i));
                        }
                    }
                }
                Err(_) => return Err(format!("Could not read line {}",i)),
            }
            
            
        }

        if self.code_vector.len() != huffman.len(){
            println!("sw:{},hw:{}",self.code_vector.len(),huffman.len());
            return Err(format!("do not match length"))
        }

        for i in 0..huffman.len(){
            if self.code_vector[i] != huffman[i]{
                println!("sw:{},hw:{}",self.code_vector[i],huffman[i]);
                return Err(format!("do not match zig y data at pixel[{}]",i));
            }
        }
        
        Ok(())
    }
    
}



