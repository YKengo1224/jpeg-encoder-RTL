use std::f32::consts::PI;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::str::FromStr;

pub struct Image {
    pub pixel_data: (Vec<u8>, Vec<u8>, Vec<u8>),
    pub vec_len: usize,
    pub height: usize,
    pub width: usize,
}

pub struct Yuv {
    pub pixel_data: (Vec<i8>, Vec<i8>, Vec<i8>),
    pub vec_len: usize,
    pub height: usize,
    pub width: usize,
}

pub struct Mcu {
    pub mcu_y: Vec<Vec<i8>>,
    pub mcu_u: Vec<Vec<i8>>,
    pub mcu_v: Vec<Vec<i8>>,
    pub height: usize,
    pub width: usize,
}

pub struct Dct {
    pub dct_y: Vec<Vec<i16>>,
    pub dct_u: Vec<Vec<i16>>,
    pub dct_v: Vec<Vec<i16>>,
    pub height: usize,
    pub width: usize,
}

impl Image {
    pub fn new(pixel_data: (Vec<u8>, Vec<u8>, Vec<u8>), height: usize, width: usize) -> Image {
        let vec_len = height * width;

        Image {
            pixel_data,
            vec_len,
            height,
            width,
        }
    }

    pub fn hw_check(&self, file_name: &String) -> Result<(), String> {
        //scan sim_data
        let file = File::open(file_name).expect(&format!("Counld not file:{}", file_name));

        let reader = BufReader::new(file);

        let mut r: Vec<u8> = Vec::new();
        let mut g: Vec<u8> = Vec::new();
        let mut b: Vec<u8> = Vec::new();

        for (i, line) in reader.lines().enumerate() {
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();
                if parts.len() == 3 {
                    //AXI-stream ->  [r,b,g]
                    let r_str = parts[0].trim();
                    let b_str = parts[1].trim();
                    let g_str = parts[2].trim();

                    r.push(u8::from_str(r_str).unwrap());
                    g.push(u8::from_str(g_str).unwrap());
                    b.push(u8::from_str(b_str).unwrap());
                }
            }
        }

        //check
        if r.len() != self.pixel_data.1.len() {
            return Err(format!(" do not match length"));
        }

        for i in 0..r.len() {
            if self.pixel_data.0[i] != r[i] {
                println!("sw:{},hw:{}", self.pixel_data.0[i], r[i]);
                return Err(format!("do not match r data at pixel[{}]", i));
            }
            if self.pixel_data.1[i] != g[i] {
                println!("sw:{},hw:{}", self.pixel_data.1[i], g[i]);
                return Err(format!("do not match g data at pixel[{}]", i));
            }
            if self.pixel_data.2[i] != b[i] {
                println!("sw:{},hw:{}", self.pixel_data.2[i], b[i]);
                return Err(format!("do not match b data at pixel[{}]", i));
            }
        }

        Ok(())
    }

    pub fn rgb2yuv(&self, index: i32) -> Yuv {
        let y_weight: Vec<f32> = vec![0.299, 0.587, 0.114];
        let u_weight: Vec<f32> = vec![-0.1687, -0.3313, 0.5];
        let v_weight: Vec<f32> = vec![0.5, 0.4188, 0.0813];

        //fixed point Vector
        // let mut y_weight_fix: Vec<i32> = vec![0; 3];
        // let mut u_weight_fix: Vec<i32> = vec![0; 3];
        // let mut v_weight_fix: Vec<i32> = vec![0; 3];

        //float to fixed
        let ex = (1 << index) as f32;
        // for i in 0..3{
        //     y_weight_fix[i] = (y_weight[i] * ex) as i32;
        //     u_weight_fix[i] = (u_weight[i] * ex) as i32;
        //     v_weight_fix[i] = (v_weight[i] * ex) as i32;
        // }
        let y_weight_fix: Vec<i32> = vec![4899, 9617, 1868];
        let u_weight_fix: Vec<i32> = vec![2764, 5428, 8192];
        let v_weight_fix: Vec<i32> = vec![8192, 6860, 1332];

        let mut y_channel: Vec<i8> = Vec::new();
        let mut u_channel: Vec<i8> = Vec::new();
        let mut v_channel: Vec<i8> = Vec::new();

        //rgb to yuv
        for i in 0..(self.vec_len as usize) {
            let r = self.pixel_data.0[i] as i32;
            let g = self.pixel_data.1[i] as i32;
            let b = self.pixel_data.2[i] as i32;

            //y channel
            let y = y_weight_fix[0] * r + y_weight_fix[1] * g + y_weight_fix[2] * b - (128 << 14);
            // let y =
            //     y_weight_fix[0] * r + y_weight_fix[1] * g
            //     + y_weight_fix[2] * b;

            //round
            //let y = if(y & 0b1000000000000000 != 0) && y >= 0 {
            let y = if (y & (1 << (index - 1)) != 0)
                && y >= 0
                && (((y >> index) & 0b01111111) != 0b01111111)
            {
                ((y >> index) + 1) as i8
            } else {
                (y >> index) as i8
            };
            y_channel.push(y);

            //u channel
            let u = -u_weight_fix[0] * r - u_weight_fix[1] * g + u_weight_fix[2] * b;
            // let u = (128 << index) +
            //     u_weight_fix[0] * r + u_weight_fix[1] * g
            //     + u_weight_fix[2] * b ;
            //round
            // let u = if(u & 0b1000000000000000 != 0) && u >= 0 {
            let u = if (u & (1 << (index - 1)) != 0)
                && u >= 0
                && (((u >> index) & 0b01111111) != 0b01111111)
            {
                ((u >> index) + 1) as i8
            } else {
                (u >> index) as i8
            };
            u_channel.push(u);

            //v channel
            let v = v_weight_fix[0] * r - v_weight_fix[1] * g - v_weight_fix[2] * b;
            // let v =  (128 << index) +
            //     v_weight_fix[0] * r + v_weight_fix[1] * g
            //     + v_weight_fix[2] * b ;

            if i == 0 {
                println!("debugd:{}", v);
            }
            //round
            // let v = if(v & 0b1000000000000000 != 0) && v >= 0 {
            let v = if (v & (1 << (index - 1)) != 0)
                && v >= 0
                && (((v >> index) & 0b01111111) != 0b01111111)
            {
                ((v >> index) + 1) as i8
            } else {
                (v >> index) as i8
            };
            v_channel.push(v);
        }

        let pixel_data = (y_channel, u_channel, v_channel);
        let vec_len = self.vec_len;
        let height = self.height;
        let width = self.width;

        Yuv {
            pixel_data,
            vec_len,
            height,
            width,
        }
    }
}

impl Yuv {
    pub fn hw_check(&self, file_name: &String) -> Result<(), String> {
        //scan sim_data
        let file = File::open(file_name).expect(&format!("Counld not file:{}", file_name));

        let reader = BufReader::new(file);

        let mut y: Vec<i8> = Vec::new();
        let mut u: Vec<i8> = Vec::new();
        let mut v: Vec<i8> = Vec::new();

        for (i, line) in reader.lines().enumerate() {
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();
                if parts.len() == 3 {
                    let y_str = parts[0].trim();
                    let u_str = parts[1].trim();
                    let v_str = parts[2].trim();

                    y.push(i8::from_str(y_str).unwrap());
                    u.push(i8::from_str(u_str).unwrap());
                    v.push(i8::from_str(v_str).unwrap());
                }
            }
        }

        //check
        if y.len() != self.pixel_data.1.len() {
            return Err(format!(
                " do not match length sw:{},hw:{}",
                self.pixel_data.1.len(),
                y.len()
            ));
        }

        for i in 0..y.len() {
            if self.pixel_data.0[i] != y[i] {
                println!("sw:{},hw:{}", self.pixel_data.0[i], y[i]);
                return Err(format!("do not match y data at pixel[{}]", i));
            }
            if self.pixel_data.1[i] != u[i] {
                println!("sw:{},hw:{}", self.pixel_data.1[i], u[i]);
                return Err(format!("do not match u data at pixel[{}]", i));
            }
            if self.pixel_data.2[i] != v[i] {
                println!("sw:{},hw:{}", self.pixel_data.2[i], v[i]);
                return Err(format!("do not match v data at pixel[{}]", i));
            }
        }

        Ok(())
    }

    pub fn gen_mcu_vec(&self) -> Mcu {
        let mcu_width_num = self.width / 8;
        let mcu_height_num = self.height / 8;
        let mut mcu_y: Vec<Vec<i8>> = Vec::new();
        let mut mcu_u: Vec<Vec<i8>> = Vec::new();
        let mut mcu_v: Vec<Vec<i8>> = Vec::new();

        let mut y_2d: Vec<Vec<i8>> = vec![vec![0; self.width]; self.height];
        let mut u_2d: Vec<Vec<i8>> = vec![vec![0; self.width]; self.height];
        let mut v_2d: Vec<Vec<i8>> = vec![vec![0; self.width]; self.height];
        let mut count = 0;
        for i in 0..self.height {
            for j in 0..self.width {
                y_2d[i][j] = self.pixel_data.0[count];
                u_2d[i][j] = self.pixel_data.1[count];
                v_2d[i][j] = self.pixel_data.2[count];
                count += 1;
            }
        }

        let h = self.height / 8;
        let w = self.width / 8;

        for i in 0..h {
            for j in 0..w {
                let mut tmp1: Vec<i8> = vec![0; 64];
                let mut tmp2: Vec<i8> = vec![0; 64];
                let mut tmp3: Vec<i8> = vec![0; 64];
                for k in 0..8 {
                    for l in 0..8 {
                        tmp1[(k * 8) + l] = y_2d[(i * 8) + k][(j * 8) + l];
                        tmp2[(k * 8) + l] = u_2d[(i * 8) + k][(j * 8) + l];
                        tmp3[(k * 8) + l] = v_2d[(i * 8) + k][(j * 8) + l];
                    }
                }
                mcu_y.push(tmp1);
                mcu_u.push(tmp2);
                mcu_v.push(tmp3);
            }
        }

        let height = self.height;
        let width = self.width;
        Mcu {
            mcu_y,
            mcu_u,
            mcu_v,
            height,
            width,
        }
    }
}

impl Mcu {
    pub fn hw_check(
        &self,
        file_y_name: &String,
        file_u_name: &String,
        file_v_name: &String,
    ) -> Result<(), String> {
        //scan sim_data
        let file_y = File::open(file_y_name).expect(&format!("Counld not file:{}", file_y_name));
        let file_u = File::open(file_u_name).expect(&format!("Counld not file:{}", file_u_name));
        let file_v = File::open(file_v_name).expect(&format!("Counld not file:{}", file_v_name));

        let reader_y = BufReader::new(file_y);
        let reader_u = BufReader::new(file_u);
        let reader_v = BufReader::new(file_v);

        let mut mcu_y: Vec<Vec<i8>> = Vec::new();
        let mut mcu_u: Vec<Vec<i8>> = Vec::new();
        let mut mcu_v: Vec<Vec<i8>> = Vec::new();

        for (i, line) in reader_y.lines().enumerate() {
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();

                mcu_y.push(Vec::new());
                for j in 0..parts.len() {
                    let str = parts[j].trim();
                    mcu_y[i].push(i8::from_str(str).unwrap());
                }
            }
        }
        for (i, line) in reader_u.lines().enumerate() {
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();

                mcu_u.push(Vec::new());
                for j in 0..parts.len() {
                    let str = parts[j].trim();
                    mcu_u[i].push(i8::from_str(str).unwrap());
                }
            }
        }
        for (i, line) in reader_v.lines().enumerate() {
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();

                mcu_v.push(Vec::new());
                for j in 0..parts.len() {
                    let str = parts[j].trim();
                    mcu_v[i].push(i8::from_str(str).unwrap());
                }
            }
        }

        if self.mcu_y.len() != mcu_y.len() {
            return Err(format!(" do not match length"));
        }

        for i in 0..mcu_y.len() {
            for j in 0..64 {
                if self.mcu_y[i][j] != mcu_y[i][j] {
                    println!("sw:{},hw:{}", self.mcu_y[i][j], mcu_y[i][j]);
                    return Err(format!("do not match mcu y data at pixel[{},{}]", i, j));
                }
                if self.mcu_u[i][j] != mcu_u[i][j] {
                    println!("sw:{},hw:{}", self.mcu_u[i][j], mcu_u[i][j]);
                    return Err(format!("do not match mcu v data at pixel[{},{}]", i, j));
                }
                if self.mcu_v[i][j] != mcu_v[i][j] {
                    println!("sw:{},hw:{}", self.mcu_v[i][j], mcu_v[i][j]);
                    return Err(format!("do not match mcu y data at pixel[{},{}]", i, j));
                }
            }
        }

        Ok(())
    }

    pub fn dct_calc(&mut self) -> Dct {
        let (c, c_t) = Mcu::gen_dct_table();

        let mut out: (Vec<Vec<i16>>, Vec<Vec<i16>>, Vec<Vec<i16>>) =
            (Vec::new(), Vec::new(), Vec::new());

        //i16 to i32
        let y_32: Vec<Vec<i32>> = self
            .mcu_y
            .iter()
            .map(|inner_vec| inner_vec.iter().map(|&x| x as i32).collect::<Vec<i32>>())
            .collect();
        let u_32: Vec<Vec<i32>> = self
            .mcu_u
            .iter()
            .map(|inner_vec| inner_vec.iter().map(|&x| x as i32).collect::<Vec<i32>>())
            .collect();
        let v_32: Vec<Vec<i32>> = self
            .mcu_v
            .iter()
            .map(|inner_vec| inner_vec.iter().map(|&x| x as i32).collect::<Vec<i32>>())
            .collect();

        for i in 0..self.mcu_v.len() {
            let mut tmpy: Vec<i32> = Mcu::matrix_calc(&c, &y_32[i]);
            let mut tmpu: Vec<i32> = Mcu::matrix_calc(&c, &u_32[i]);
            let mut tmpv: Vec<i32> = Mcu::matrix_calc(&c, &v_32[i]);

            for j in 0..64 {
                tmpy[j] = if ((tmpy[j] & 0b10000000000000) != 0) && (tmpy[j] > 0) {
                    (tmpy[j] >> 14) + 1
                } else {
                    tmpy[j] >> 14
                };
                tmpu[j] = if ((tmpu[j] & 0b10000000000000) != 0) && (tmpu[j] > 0) {
                    (tmpu[j] >> 14) + 1
                } else {
                    tmpu[j] >> 14
                };
                tmpv[j] = if ((tmpv[j] & 0b10000000000000) != 0) && (tmpv[j] > 0) {
                    (tmpv[j] >> 14) + 1
                } else {
                    tmpv[j] >> 14
                };
            }
            // let tmpy: Vec<i32> = tmpy.iter().map(|&x| (x>>14) as i32).collect();
            // let tmpu: Vec<i32> = tmpu.iter().map(|&x| (x>>14) as i32).collect();
            // let tmpv: Vec<i32> = tmpv.iter().map(|&x| (x>>14) as i32).collect();

            let tmpy: Vec<i32> = Mcu::matrix_calc(&tmpy, &c_t);
            let tmpu: Vec<i32> = Mcu::matrix_calc(&tmpu, &c_t);
            let tmpv: Vec<i32> = Mcu::matrix_calc(&tmpv, &c_t);

            let mut tmpy16: Vec<i16> = vec![0; 64];
            let mut tmpu16: Vec<i16> = vec![0; 64];
            let mut tmpv16: Vec<i16> = vec![0; 64];

            for j in 0..64 {
                tmpy16[j] = if ((tmpy[j] & 0b10000000000000) != 0) && (tmpy[j] > 0) {
                    ((tmpy[j] >> 14) + 1) as i16
                } else {
                    (tmpy[j] >> 14) as i16
                };
                tmpu16[j] = if ((tmpu[j] & 0b10000000000000) != 0) && (tmpu[j] > 0) {
                    ((tmpu[j] >> 14) + 1) as i16
                } else {
                    (tmpu[j] >> 14) as i16
                };
                tmpv16[j] = if (tmpv[j] & 0b10000000000000) != 0 && (tmpv[j] > 0) {
                    ((tmpv[j] >> 14) + 1) as i16
                } else {
                    (tmpv[j] >> 14) as i16
                };
            }

            out.0.push(tmpy16);
            out.1.push(tmpu16);
            out.2.push(tmpv16);
        }

        let dct_y = out.0;
        let dct_u = out.1;
        let dct_v = out.2;
        let height = self.height;
        let width = self.width;
        Dct {
            dct_y,
            dct_u,
            dct_v,
            height,
            width,
        }
    }

    pub fn matrix_calc(mat1: &Vec<i32>, mat2: &Vec<i32>) -> Vec<i32> {
        let mut out: Vec<i32> = vec![0; 64];

        for i in 0..8 {
            for j in 0..8 {
                for k in 0..8 {
                    out[i * 8 + j] = out[i * 8 + j] + mat1[i * 8 + k] * mat2[k * 8 + j];
                }
            }
        }

        out
    }

    pub fn gen_dct_table() -> (Vec<i32>, Vec<i32>) {
        let mut c: Vec<i32> = vec![0; 64];
        let mut c_t: Vec<i32> = vec![0; 64];

        let ex = (1 << 14) as f32;

        for i in 0..8 {
            for j in 0..8 {
                if i == 0 {
                    let tmp = (1f32 / (8 as f32).sqrt() * ex) as i32;
                    c[i * 8 + j] = tmp;
                    c_t[j * 8 + i] = tmp
                } else {
                    let tmp = ((2f32 / (8 as f32)).sqrt()
                        * ((i as f32) * PI * ((2f32 * (j as f32) + 1f32) / (2f32 * (8 as f32))))
                            .cos()
                        * ex) as i32;

                    c[i * 8 + j] = tmp;
                    c_t[j * 8 + i] = tmp;
                }
            }
        }

        (c, c_t)
    }
}

impl Dct {
    pub fn hw_check(
        &self,
        file_y_name: &String,
        file_u_name: &String,
        file_v_name: &String,
    ) -> Result<(), String> {
        //scan sim_data
        let file_y = File::open(file_y_name).expect(&format!("Counld not file:{}", file_y_name));
        let file_u = File::open(file_u_name).expect(&format!("Counld not file:{}", file_u_name));
        let file_v = File::open(file_v_name).expect(&format!("Counld not file:{}", file_v_name));

        let reader_y = BufReader::new(file_y);
        let reader_u = BufReader::new(file_u);
        let reader_v = BufReader::new(file_v);

        let mut dct_y: Vec<Vec<i16>> = Vec::new();
        let mut dct_u: Vec<Vec<i16>> = Vec::new();
        let mut dct_v: Vec<Vec<i16>> = Vec::new();

        for (i, line) in reader_y.lines().enumerate() {
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();

                dct_y.push(Vec::new());
                for j in 0..parts.len() {
                    let str = parts[j].trim();
                    dct_y[i].push(i16::from_str(str).unwrap());
                }
            }
        }
        for (i, line) in reader_u.lines().enumerate() {
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();

                dct_u.push(Vec::new());
                for j in 0..parts.len() {
                    let str = parts[j].trim();
                    dct_u[i].push(i16::from_str(str).unwrap());
                }
            }
        }
        for (i, line) in reader_v.lines().enumerate() {
            if let Ok(line) = line {
                let parts: Vec<&str> = line.split(',').collect();

                dct_v.push(Vec::new());
                for j in 0..parts.len() {
                    let str = parts[j].trim();
                    dct_v[i].push(i16::from_str(str).unwrap());
                }
            }
        }

        if self.dct_y.len() != dct_y.len() {
            println!("sw:{},hw:{}", self.dct_y.len(), dct_y.len());
            return Err(format!(" do not match length"));
        }

        for i in 0..dct_y.len() {
            for j in 0..64 {
                if self.dct_y[i][j] != dct_y[i][j] {
                    println!("sw:{},hw:{}", self.dct_y[i][j], dct_y[i][j]);
                    return Err(format!("do not match dct y data at pixel[{},{}]", i, j));
                }
                if self.dct_u[i][j] != dct_u[i][j] {
                    println!("sw:{},hw:{}", self.dct_u[i][j], dct_u[i][j]);
                    return Err(format!("do not match dct u data at pixel[{},{}]", i, j));
                }
                if self.dct_v[i][j] != dct_v[i][j] {
                    println!("sw:{},hw:{}", self.dct_v[i][j], dct_v[i][j]);
                    return Err(format!("do not match dct v data at pixel[{},{}]", i, j));
                }
            }
        }

        Ok(())
    }
}
