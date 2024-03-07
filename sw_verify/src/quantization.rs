use std::fs::File;
use std::io::{BufReader,BufRead};
use std::str::FromStr;

use crate::marker::DqtMarker;
use crate::image::Dct;



pub struct Quantization{
    pub quan_y:Vec<Vec<i16>>,
    pub quan_u:Vec<Vec<i16>>,
    pub quan_v:Vec<Vec<i16>>,
}


impl Quantization{

    pub fn quantization(dct:&Dct,dqt:&DqtMarker) -> Quantization{
        let y_table = &dqt.y_q_table;
        let uv_table = &dqt.uv_q_table;

        let mut quan_y:Vec<Vec<i16>> = Vec::new();
        let mut quan_u:Vec<Vec<i16>> = Vec::new();
        let mut quan_v:Vec<Vec<i16>> = Vec::new();

        for i in 0..dct.dct_y.len(){
            quan_y.push(Vec::new());
            quan_u.push(Vec::new());
            quan_v.push(Vec::new());
            for j in 0..64{
                // fixed point 2**12
                let y_q = 4096 / (y_table[j] as i32); 
                let uv_q = 4096 / (uv_table[j] as i32);
                let tmp_y = (dct.dct_y[i][j] as i32) * y_q;
                let tmp_u = (dct.dct_u[i][j] as i32) * uv_q;
                let tmp_v = (dct.dct_v[i][j] as i32) * uv_q;

                // if (tmp_y & 0b100000000000) != 0 {
                //     quan_y[i].push( ((tmp_y>>12)+1) as i16); 
                // }
                // else {
                //     quan_y[i].push( (tmp_y>>12) as i16); 
                // }
                // if (tmp_u & 0b100000000000) != 0 {
                //     quan_u[i].push( ((tmp_u>>12)+1) as i16); 
                // }
                // else {
                //     quan_u[i].push( (tmp_u>>12) as i16); 
                // }
                // if (tmp_v & 0b100000000000) != 0 {
                //     quan_v[i].push( ((tmp_v>>12)+1) as i16); 
                // }
                // else {
                //     quan_v[i].push( (tmp_v>>12) as i16); 
                // }

                if tmp_y<0{
                    quan_y[i].push( ((tmp_y>>12)+1) as i16); 
                }
                else {
                    quan_y[i].push( (tmp_y>>12) as i16); 
                }
                if tmp_u<0{
                    quan_u[i].push( ((tmp_u>>12)+1) as i16); 
                }
                else {
                    quan_u[i].push( (tmp_u>>12) as i16); 
                }
                if tmp_v<0{
                    quan_v[i].push( ((tmp_v>>12)+1) as i16); 
                }
                else {
                    quan_v[i].push( (tmp_v>>12) as i16); 
                }


                
            }            
        }

        
        Quantization{
            quan_y,
            quan_u,
            quan_v
        }
        
    }

    pub fn hw_check(&self,file_y_name:&String,file_u_name:&String,file_v_name:&String) ->Result<(),String>{
        //scan sim_data
        let file_y = File::open(file_y_name).
            expect(&format!("Counld not file:{}",file_y_name));
        let file_u = File::open(file_u_name).
            expect(&format!("Counld not file:{}",file_u_name));
        let file_v = File::open(file_v_name).
            expect(&format!("Counld not file:{}",file_v_name));
        
        let reader_y = BufReader::new(file_y);
        let reader_u = BufReader::new(file_u);
        let reader_v = BufReader::new(file_v);

        let mut quan_y :Vec<Vec<i16>> = Vec::new();
        let mut quan_u :Vec<Vec<i16>> = Vec::new();
        let mut quan_v :Vec<Vec<i16>> = Vec::new();

        for(i,line) in reader_y.lines().enumerate(){            
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();
                
                quan_y.push(Vec::new());
                for j in 0..parts.len(){
                    let str = parts[j].trim();
                    quan_y[i].push(i16::from_str(str).unwrap());
                }
            }
        }
        for(i,line) in reader_u.lines().enumerate(){            
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();
                
                quan_u.push(Vec::new());
                for j in 0..parts.len(){
                    let str = parts[j].trim();
                    quan_u[i].push(i16::from_str(str).unwrap());
                }
            }
        }
        for(i,line) in reader_v.lines().enumerate(){            
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();

                quan_v.push(Vec::new());
                for j in 0..parts.len(){
                    let str = parts[j].trim();
                    quan_v[i].push(i16::from_str(str).unwrap());
                }
            }
        }


        if self.quan_y.len() != quan_y.len() {
            return Err(format!(" do not match length")) 
        }
        
        for i in 0..quan_y.len(){
            for j in 0..64{
                if self.quan_y[i][j] != quan_y[i][j]{
                    println!("sw:{},hw:{}",self.quan_y[i][j],quan_y[i][j]);
                    return Err(format!("do not match quan y data at pixel[{},{}]",i,j)); 
                }
                if self.quan_u[i][j] != quan_u[i][j]{
                    println!("sw:{},hw:{}",self.quan_u[i][j],quan_u[i][j]);
                    return Err(format!("do not match quan u data at pixel[{},{}]",i,j)); 
                }                
                if self.quan_v[i][j] != quan_v[i][j]{
                    println!("sw:{},hw:{}",self.quan_v[i][j],quan_v[i][j]);
                    return Err(format!("do not match quan v data at pixel[{},{}]",i,j)); 
                }                

                
            }
            
        }

        Ok(())

    }

    

}

pub struct ZigZag{
    pub zig_y:Vec<Vec<i16>>,
    pub zig_u:Vec<Vec<i16>>,
    pub zig_v:Vec<Vec<i16>>,
}

impl ZigZag{
    pub fn zigzag_scan(quan:Quantization)->ZigZag{
        let mut zig_y:Vec<Vec<i16>> = Vec::new();
        let mut zig_u:Vec<Vec<i16>> = Vec::new();
        let mut zig_v:Vec<Vec<i16>> = Vec::new();
        
        //zigzag scan
        let zigzag_index = [
            0, 1, 5, 6, 14, 15, 27, 28,
            2, 4, 7, 13, 16, 26, 29, 42,
            3, 8, 12, 17, 25, 30, 41, 43,
            9, 11, 18, 24, 31, 40, 44, 53,
            10, 19, 23, 32, 39, 45, 52, 54,
            20, 22, 33, 38, 46, 51, 55, 60,
            21, 34, 37, 47, 50, 56, 59, 61,
            35, 36, 48, 49, 57, 58, 62, 63,
        ];

        for i in 0..quan.quan_y.len(){
            zig_y.push(vec![0;64]);
            zig_u.push(vec![0;64]);
            zig_v.push(vec![0;64]);
            for j in 0..64{
                let zz = zigzag_index[j];
                zig_y[i][zz] = quan.quan_y[i][j];
                zig_u[i][zz] = quan.quan_u[i][j];
                zig_v[i][zz] = quan.quan_v[i][j];
            }
        }

        ZigZag{
            zig_y,
            zig_u,
            zig_v
        }
        

    }



    pub fn hw_check(&self,file_y_name:&String,file_u_name:&String,file_v_name:&String) ->Result<(),String>{
        //scan sim_data
        let file_y = File::open(file_y_name).
            expect(&format!("Could not file:{}",file_y_name));
        let file_u = File::open(file_u_name).
            expect(&format!("Could not file:{}",file_u_name));
        let file_v = File::open(file_v_name).
            expect(&format!("Could not file:{}",file_v_name));
        
        let reader_y = BufReader::new(file_y);
        let reader_u = BufReader::new(file_u);
        let reader_v = BufReader::new(file_v);

        let mut zig_y :Vec<Vec<i16>> = Vec::new();
        let mut zig_u :Vec<Vec<i16>> = Vec::new();
        let mut zig_v :Vec<Vec<i16>> = Vec::new();

        for(i,line) in reader_y.lines().enumerate(){            
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();
                
                zig_y.push(Vec::new());
                for j in 0..parts.len(){
                    let str = parts[j].trim();
                    zig_y[i].push(i16::from_str(str).unwrap());
                }
            }
        }
        for(i,line) in reader_u.lines().enumerate(){            
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();
                
                zig_u.push(Vec::new());
                for j in 0..parts.len(){
                    let str = parts[j].trim();
                    zig_u[i].push(i16::from_str(str).unwrap());
                }
            }
        }
        for(i,line) in reader_v.lines().enumerate(){            
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();

                zig_v.push(Vec::new());
                for j in 0..parts.len(){
                    let str = parts[j].trim();
                    zig_v[i].push(i16::from_str(str).unwrap());
                }
            }
        }


        if self.zig_y.len() != zig_y.len() {
            return Err(format!(" do not match length")) 
        }
        
        for i in 0..zig_y.len(){
            for j in 0..64{
                if self.zig_y[i][j] != zig_y[i][j]{
                    println!("sw:{},hw:{}",self.zig_y[i][j],zig_y[i][j]);
                    return Err(format!("do not match zig y data at pixel[{},{}]",i,j)); 
                }
                if self.zig_u[i][j] != zig_u[i][j]{
                    println!("sw:{},hw:{}",self.zig_u[i][j],zig_u[i][j]);
                    return Err(format!("do not match zig u data at pixel[{},{}]",i,j)); 
                }                
                if self.zig_v[i][j] != zig_v[i][j]{
                    println!("sw:{},hw:{}",self.zig_v[i][j],zig_v[i][j]);
                    return Err(format!("do not match zig v data at pixel[{},{}]",i,j)); 
                }                

                
            }
            
        }

        Ok(())

    }

}


    
