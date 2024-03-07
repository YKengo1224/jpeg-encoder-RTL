use opencv::{core, highgui, imgcodecs, imgproc, prelude::*};
use std::fs::File;
use std::io::{BufRead, BufReader, Error};
use std::str::FromStr;

use huffman_encode::HuffmanEncode;
use hw_check::huff_table_check;
use image::{Dct, Image, Mcu, Yuv};
use marker::{DhtMarker, DqtMarker};
use quantization::{Quantization, ZigZag};

mod huffman_encode;
mod hw_check;
mod image;
mod marker;
mod quantization;

#[derive(Debug)]
enum MyError {
    IoError(std::io::Error),
    OpenCVError(opencv::Error),
    CustomError(String),
}
impl From<std::io::Error> for MyError {
    fn from(error: std::io::Error) -> Self {
        MyError::IoError(error)
    }
}

impl From<opencv::Error> for MyError {
    fn from(error: opencv::Error) -> Self {
        MyError::OpenCVError(error)
    }
}
impl From<String> for MyError {
    fn from(error: String) -> Self {
        MyError::CustomError(error)
    }
}

//fn main()->Result<(),String> {
//fn main()->opencv::Result<()> {
fn main() -> Result<(), MyError> {
    //------------------------------------------------------
    //scan out.jpg
    //------------------------------------------------------

    //  let bgr = imgcodecs::imread("sim_result/out.jpg",imgcodecs::IMREAD_COLOR)?;
    // //let bgr = imgcodecs::imread("../../soft_sim/rust/output.jpg",imgcodecs::IMREAD_COLOR)?;
    // let mut rgb_image = core::Mat::default();
    // imgproc::cvt_color(&bgr, &mut rgb_image, imgproc::COLOR_BGR2RGB, 0)?;

    // let len = (rgb_image.rows() * rgb_image.cols()) as usize;
    // let mut r_channel: Vec<u8> = vec![0; len];
    // let mut g_channel: Vec<u8> = vec![0; len];
    // let mut b_channel: Vec<u8> = vec![0; len];

    // let rows = rgb_image.rows();
    // let cols = rgb_image.cols();

    // for i in 0..rows {
    //     for j in 0..cols {
    //         let pixel = rgb_image.at_2d_mut::<core::Vec3b>(i, j)?;
    //         let index = (i * cols + j) as usize;
    //         r_channel[index] = pixel[0];
    //         g_channel[index] = pixel[1];
    //         b_channel[index] = pixel[2];
    //     }
    // }

    //------------------------------------------------------
    //scan rgb data
    //------------------------------------------------------
    let file = File::open("sim_result/image.dat").expect("Coult not open file");
    let reader = BufReader::new(file);

    // let rows = 16;
    // let cols = 32;
    let cols = 1280;
    let rows = 720;

    let mut r: Vec<u8> = Vec::new();
    let mut g: Vec<u8> = Vec::new();
    let mut b: Vec<u8> = Vec::new();

    //push vector
    for (i, line) in reader.lines().enumerate() {
        if let Ok(line) = line {
            let parts: Vec<&str> = line.split(',').collect();
            if parts.len() == 3 {
                //AXI-Stream -> [r,b,g]
                let r_str = parts[0].trim();
                let b_str = parts[1].trim();
                let g_str = parts[2].trim();

                r.push(u8::from_str(r_str).unwrap());
                g.push(u8::from_str(g_str).unwrap());
                b.push(u8::from_str(b_str).unwrap());
            }
        }
    }

    let mut img = core::Mat::new_rows_cols_with_default(
        rows,
        cols,
        core::CV_8UC3,
        core::Scalar::new(0.0, 0.0, 0.0, 0.0),
    )?;

    for y in 0..rows {
        for x in 0..cols {
            let mut pixel: core::Vec3b = *img.at_2d_mut(y, x)?;
            pixel[0] = b[((y * cols) + x) as usize];
            pixel[1] = g[((y * cols) + x) as usize];
            pixel[2] = r[((y * cols) + x) as usize];
            *img.at_2d_mut(y, x)? = pixel;
        }
    }

    //show the image
    // highgui::imshow("Image",&img)?;
    // highgui::wait_key(0)?;

    //output test.jpg
    imgcodecs::imwrite("test.png", &img, &core::Vector::new())?;

    //------------------------------------------------------
    //rgb to yuv
    //------------------------------------------------------

    // let r: Vec<i16> = r.into_iter().map(|x| x as i16).collect();
    // let g: Vec<i16> = g.into_iter().map(|x| x as i16).collect();
    // let b: Vec<i16> = b.into_iter().map(|x| x as i16).collect();
    let rgb: Image = Image::new((r, g, b), rows as usize, cols as usize);

    //point
    let index = 14;

    let yuv: Yuv = rgb.rgb2yuv(index);

    println!(
        "yuv:{},{},{}",
        yuv.pixel_data.0[0], yuv.pixel_data.1[0], yuv.pixel_data.2[0]
    );

    println!("============start rgb check===================");
    rgb.hw_check(&format!("sim_result/image.dat"))?;
    println!("check:ok");
    println!("============start yuv check===================");
    yuv.hw_check(&format!("sim_result/yuv.dat"))?;
    println!("check:ok");

    //------------------------------------------------------
    //mcu
    //------------------------------------------------------
    let mut mcu: Mcu = yuv.gen_mcu_vec();
    println!("=============start mcu check=================");
    mcu.hw_check(
        &format!("sim_result/mcu_y.dat"),
        &format!("sim_result/mcu_u.dat"),
        &format!("sim_result/mcu_v.dat"),
    )?;
    println!("check:ok");

    //println!("{:?}",mcu.mcu_y);

    //------------------------------------------------------
    //dct
    //------------------------------------------------------

    let dct: Dct = mcu.dct_calc();
    // println!("{:?}",dct.dct_v[0]);
    println!("=============start dct check=================");
    println!("{}", dct.dct_y[0][0]);
    dct.hw_check(
        &format!("sim_result/dct_y.dat"),
        &format!("sim_result/dct_u.dat"),
        &format!("sim_result/dct_v.dat"),
    )?;
    println!("check:ok");

    //------------------------------------------------------
    //quan
    //------------------------------------------------------

    let dqt = DqtMarker::new(1);
    let quan: Quantization = Quantization::quantization(&dct, &dqt);
    // println!("{:?}",quan.quan_v[0]);
    println!("=============start quan check=================");
    quan.hw_check(
        &format!("sim_result/quan_y.dat"),
        &format!("sim_result/quan_u.dat"),
        &format!("sim_result/quan_v.dat"),
    )?;

    println!("check:ok");
    //println!("{:?}",quan.quan_v);

    //------------------------------------------------------
    //zigzag
    //------------------------------------------------------

    let zig = ZigZag::zigzag_scan(quan);
    println!("=============start zig check=================");
    zig.hw_check(
        &format!("sim_result/zig_y.dat"),
        &format!("sim_result/zig_u.dat"),
        &format!("sim_result/zig_v.dat"),
    )?;
    println!("check:ok");
    //println!("{:?}",quan.quan_v);

    //------------------------------------------------------
    //huffman
    //------------------------------------------------------

    let dht = DhtMarker::new();

    let mut huffman_encoder = HuffmanEncode::new(&dht);
    huffman_encoder.encoding(zig);
    huffman_encoder.gen_code_vector();

    println!(
        "{},{},{},{}",
        huffman_encoder.code_vector[0],
        huffman_encoder.code_vector[1],
        huffman_encoder.code_vector[3],
        huffman_encoder.code_vector[4]
    );

    println!("=============huffman encode check=================");
    huffman_encoder.hw_check(&format!("sim_result/huffman.dat"))?;
    println!("check:ok");

    //matrix_print_2d(huffman_encoder.y_ac_hufftable,16);
    let huff_table_sim_file_name = vec![
        "sim_result/y_dc_huff_code.dat".to_string(),
        "sim_result/y_dc_huff_length.dat".to_string(),
        "sim_result/uv_dc_huff_code.dat".to_string(),
        "sim_result/uv_dc_huff_length.dat".to_string(),
        "sim_result/y_ac_huff_code.dat".to_string(),
        "sim_result/y_ac_huff_length.dat".to_string(),
        "sim_result/uv_ac_huff_code.dat".to_string(),
        "sim_result/uv_ac_huff_length.dat".to_string(),
    ];

    huff_table_check(huffman_encoder, huff_table_sim_file_name)?;
    // match huff_table_check(huffman_encoder,huff_table_sim_file_name){
    //     Ok(_) => {},
    //     Err(e) => {println!("{}",e);},
    //     }

    Ok(())
}

pub fn matrix_print<T: std::fmt::Binary>(v: &Vec<T>) {
    println!("vec_print:");
    for i in 0..v.len() {
        println!("{:b}", v[i]);
    }
}

pub fn matrix_print_2d<T: std::fmt::Binary>(v: Vec<Vec<T>>, bit_width: usize) {
    println!("vec_print:");
    for i in &v {
        for j in i {
            let binary_str = format!("{:b}", j);
            let padded_binary_str = format!("{:0>width$}", binary_str, width = bit_width);
            println!("{} ", padded_binary_str);
        }
    }
}
