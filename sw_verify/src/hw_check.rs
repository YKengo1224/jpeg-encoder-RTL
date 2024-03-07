use std::fs;
use std::fs::File;
use std::io::{BufRead,BufReader};


use crate::huffman_encode::HuffmanEncode;



pub fn num_to_str<T:std::fmt::Binary>(v : &Vec<T>, bit_width : usize) -> Vec<String>{

    let mut out:Vec<String> = vec!["0".to_string();v.len()];
    let mut count = 0;
    for i in v{
            let binary_str = format!("{:b}",i);
            let padded_binary_str = format!("{:0>width$}", binary_str, width=bit_width);
            out[count] = padded_binary_str;
            count += 1;
    }

    out

}

pub fn num_to_str_2d<T:std::fmt::Binary>(v : &Vec<Vec<T>>, bit_width : usize) -> Vec<String>{

    let mut out:Vec<String> = vec!["0".to_string();v.len()*v[0].len()];
    let mut count = 0;
    for i in v{
        for j in i {
            let binary_str = format!("{:b}",j);
            let padded_binary_str = format!("{:0>width$}", binary_str, width=bit_width);
            out[count] = padded_binary_str;
            count += 1;
        }
    }

    out

}


//check of huff table simulation result
pub fn huff_table_check(sw:HuffmanEncode,sim_file_name:Vec<String>) -> Result<(),String>{

    print!{"huffman table check:"};
    
    //y_dc_huffcode
    line_count_check(num_to_str(&sw.y_dc_huffcode_table,16),&sim_file_name[0])?;
    vec_check(num_to_str(&sw.y_dc_huffcode_table,16),&sim_file_name[0])?;
    //y_dc_hufflength_table
    line_count_check(num_to_str(&sw.y_dc_hufflength_table,8),&sim_file_name[1])?;
    vec_check(num_to_str(&sw.y_dc_hufflength_table,8),&sim_file_name[1])?;

    //uv_dc_huffcode
    line_count_check(num_to_str(&sw.uv_dc_huffcode_table,16),&sim_file_name[2])?;
    vec_check(num_to_str(&sw.uv_dc_huffcode_table,16),&sim_file_name[2])?;
    //uv_dc_hufflength_table
    line_count_check(num_to_str(&sw.uv_dc_hufflength_table,8),&sim_file_name[3])?;
    vec_check(num_to_str(&sw.uv_dc_hufflength_table,8),&sim_file_name[3])?;



    //y_ac_huffcode
    line_count_check(num_to_str_2d(&sw.y_ac_huffcode_table,16),&sim_file_name[4])?;
    vec_check(num_to_str_2d(&sw.y_ac_huffcode_table,16),&sim_file_name[4])?;
    //y_ac_hufflength_table
    line_count_check(num_to_str_2d(&sw.y_ac_hufflength_table,8),&sim_file_name[5])?;
    vec_check(num_to_str_2d(&sw.y_ac_hufflength_table,8),&sim_file_name[5])?;

    //uv_ac_huffcode
    line_count_check(num_to_str_2d(&sw.uv_ac_huffcode_table,16),&sim_file_name[6])?;
    vec_check(num_to_str_2d(&sw.uv_ac_huffcode_table,16),&sim_file_name[6])?;
    //uv_ac_hufflength_table
    line_count_check(num_to_str_2d(&sw.uv_ac_hufflength_table,8),&sim_file_name[7])?;
    vec_check(num_to_str_2d(&sw.uv_ac_hufflength_table,8),&sim_file_name[7])?;



    println!("ok");
    Ok(())
}









pub fn line_count_check<T>(vec:Vec<T>,sim_file_name:&String) -> std::result::Result<(),String>{
    let  f = match fs::read_to_string(sim_file_name){
        Ok(content) =>content,
        Err(_) => return Err(format!("Could not read file:{}",sim_file_name)),
    };
    
    let line_count = f.lines().count();
    if line_count != vec.len() {
        return Err(format!("Simulation results do not match the number of rows in Vector:{}",sim_file_name))
    }
    

    Ok(())
}
    
pub fn vec_check(vec:Vec<String>,sim_file_name:&String) -> std::result::Result<(),String>{
    let file = match File::open(sim_file_name){
        Ok(content) => content,
        Err(_) => return Err(format!("Could not read file:{}",sim_file_name)),
    };
    let reader = BufReader::new(file);

    
    for (i,line) in reader.lines().enumerate() {
        match line{
            Ok(content) => {
                if content != vec[i] {
                    return Err(format!("do not match: file, line{}: {}",i,content));
                }
            }
            Err(e) => {
                println!("reading a line error:{}",e);
            }
        }
    }


    Ok(())
    
    
}



