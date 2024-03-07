pub struct DqtMarker{
    pub header: u16,
    pub lq: u16,
    pub y_pqn_tqn: u8,
    pub y_q_table: Vec<u8>,
    pub uv_pqn_tqn: u8,
    pub uv_q_table: Vec<u8>,
    pub marker_vec:Vec<u8>
}

impl DqtMarker {
    pub fn new(comp_level:u8) -> DqtMarker{
        let header_up:u8 = 0xFF;
        let header_bottom = 0xDB;
        let header = 0xFFDB;
        let lq_up = 0x00;
        let lq_bottom = 0x84;
        let lq = 0x0084;
        let y_pqn_tqn = 0x00;
        let (y_q_table,uv_q_table) = DqtMarker::gen_q_table(comp_level);
        let uv_pqn_tqn = 0x01;

        let mut marker_vec :Vec<u8> = Vec::new();
        marker_vec.push(header_up);
        marker_vec.push(header_bottom);
        marker_vec.push(lq_up);
        marker_vec.push(lq_bottom);
        marker_vec.push(y_pqn_tqn);
        marker_vec.extend(&y_q_table);
        marker_vec.push(uv_pqn_tqn);
        marker_vec.extend(&uv_q_table);

        DqtMarker {
            header,
            lq,
            y_pqn_tqn,
            y_q_table,
            uv_pqn_tqn,
            uv_q_table,
            marker_vec
        }
    }

    pub fn gen_q_table(comp_level: u8) ->(Vec<u8>,Vec<u8>){
        let mut y_q = vec![
            16, 11, 10, 16, 24, 40, 51, 61,
            12, 12, 14, 19, 26, 58, 60, 55,
            14, 13, 16, 24, 40, 57, 69, 56,
            14, 17, 22, 29, 51, 87, 80, 62,
            18, 22, 37, 56, 68, 109, 103, 77,
            24, 35, 55, 64, 81, 104, 113, 92,
            49, 64, 78, 87, 103, 121, 120, 101,
            72, 92, 95, 98, 112, 100, 103, 99,
        ];
        let mut uv_q = vec![
            17, 18, 24, 47, 99, 99, 99, 99,
            18, 21, 26, 66, 99, 99, 99, 99,
            24, 26, 56, 99, 99, 99, 99, 99,
            47, 66, 99, 99, 99, 99, 99, 99,
            99, 99, 99, 99, 99, 99, 99, 99,
            99, 99, 99, 99, 99, 99, 99, 99,
            99, 99, 99, 99, 99, 99, 99, 99,
            99, 99, 99, 99, 99, 99, 99, 99,
        ];

        for i in 0..64{
            y_q[i] = y_q[i] / comp_level;
            uv_q[i] = uv_q[i] / comp_level;
        }

        (y_q,uv_q)
   
    }

    
}


pub struct DhtMarker{
    pub header:u16,
    pub y_dc_lh:u16,
    pub uv_dc_lh:u16,
    pub y_ac_lh:u16,
    pub uv_ac_lh:u16,

    ///上位４ビット：AC用かDC用かの識別番号
    ///下位４ビット：各セグメントの識別番号
    pub y_dc_thn:u8, 
    pub uv_dc_thn:u8,
    pub y_ac_thn:u8, 
    pub uv_ac_thn:u8,

    pub y_dc_lvec:Vec<u8>,
    pub uv_dc_lvec:Vec<u8>,
    pub y_ac_lvec:Vec<u8>,
    pub uv_ac_lvec:Vec<u8>,
    pub y_dc_vvec:Vec<u16>,
    pub uv_dc_vvec:Vec<u16>,
    pub y_ac_vvec:Vec<u16>,
    pub uv_ac_vvec:Vec<u16>,
}


impl DhtMarker{

    pub fn new()->DhtMarker{
        let header = 0xFFC4;
        let y_dc_lh = 0x001F;
        let uv_dc_lh = 0x001F;
        let y_ac_lh = 0x00B5;
        let uv_ac_lh= 0x00B5;
        let y_dc_thn = 0x00; 
        let uv_dc_thn= 0x01;
        let y_ac_thn= 0x10; 
        let uv_ac_thn= 0x11;

        let y_dc_lvec:Vec<u8> = vec![
            0x00, //1bit
	           0x01, //2bit
	           0x05, //3bit
	           0x01, //4bit
	           0x01, //5bit
	           0x01, //6bit
	           0x01, //7bit
	           0x01, //8bit
	           0x01, //9bit
	           0x00, //10bit
	           0x00, //11bit
	           0x00, //12bit
	           0x00, //13bit
	           0x00, //14bit
	           0x00, //15bit
	           0x00, //16bit
        ];

        let uv_dc_lvec:Vec<u8> = vec![
        	   0x00, //1bit
	           0x03, //2bit
	           0x01, //3bit
	           0x01, //4bit
	           0x01, //5bit
	           0x01, //6bit
	           0x01, //7bit
	           0x01, //8bit
	           0x01, //9bit
	           0x01, //10bit
	           0x01, //11bit
	           0x00, //12bit
	           0x00, //13bit
	           0x00, //14bit
	           0x00, //15bit
	           0x00, //16bit            
        ];
       
        let y_ac_lvec:Vec<u8> = vec![
            0x00, //1bit
		          0x02, //2bit
		          0x01, //3bit
		          0x03, //4bit
		          0x03, //5bit
		          0x02, //6bit
		          0x04, //7bit
		          0x03, //8bit
		          0x05, //9bit
		          0x05, //10bit
		          0x04, //11bit
		          0x04, //12bit
		          0x00, //13bit
		          0x00, //14bit
		          0x01, //15bit
		          0x7D, //16bit
        ];
        
        let uv_ac_lvec:Vec<u8> = vec![
		          0x00, //1bit
		          0x02, //2bit
		          0x01, //3bit
		          0x02, //4bit
		          0x04, //5bit
		          0x04, //6bit
		          0x03, //7bit
		          0x04, //8bit
		          0x07, //9bit
		          0x05, //10bit
		          0x04, //11bit
		          0x04, //12bit
		          0x00, //13bit
		          0x01, //14bit
		          0x02, //15bit
		          0x77, //16bit
        ];
        
        let y_dc_vvec:Vec<u16> = vec![
            0x00,  // Category 0
	           0x01, // Category 1
	           0x02, // Category 2
	           0x03, // Category 3
	           0x04, // Category 4
	           0x05, // Category 5
	           0x06, // Category 6
	           0x07, // Category 7
	           0x08, // Category 8
	           0x09, // Category 9
	           0x0A, // Category 10
	           0x0B  // Category 11
        ];

        let uv_dc_vvec:Vec<u16> = vec![
            0x00,  // Category 0
	           0x01, // Category 1
	           0x02, // Category 2
	           0x03, // Category 3
	           0x04, // Category 4
	           0x05, // Category 5
	           0x06, // Category 6
	           0x07, // Category 7
	           0x08, // Category 8
	           0x09, // Category 9
	           0x0A, // Category 10
	           0x0B  // Category 11
        ];

        let y_ac_vvec:Vec<u16> = vec![
          		0x01,0x02, //2bit
		          0x03,      //3bit
		          0x00,0x04,0x11, //4bit
		          0x05,0x12,0x21, //5bit
		          0x31,0x41, //6bit
		          0x06,0x13,0x51,0x61, //7bit
		          0x07,0x22,0x71,   //8bit
		          0x14,0x32,0x81,0x91,0xA1, //9bit
		          0x08,0x23,0x42,0xB1,0xC1,  //10bit
		          0x15,0x52,0xD1,0xF0, //11bit
		          0x24,0x33,0x62,0x72, //12bit
		          0x82, //15bit
		          0x09,0x0A,0x16,0x17,0x18,
            0x19,0x1A,0x25,0x26,0x27,0x28,0x29,0x2A,
		          0x34,0x35,0x36,0x37,0x38,0x39,0x3A,0x43,
            0x44,0x45,0x46,0x47,0x48,0x49,0x4A,0x53,
            0x54,0x55,0x56,0x57,0x58,0x59,0x5A,0x63,
            0x64,0x65,0x66,0x67,0x68,0x69,0x6A,0x73,
            0x74,0x75,0x76,0x77,0x78,0x79,0x7A,0x83,
            0x84,0x85,0x86,0x87,0x88,0x89,0x8A,0x92,
            0x93,0x94,0x95,0x96,0x97,0x98,0x99,0x9A,
            0xA2,0xA3,0xA4,0xA5,0xA6,0xA7,0xA8,0xA9,
            0xAA,0xB2,0xB3,0xB4,0xB5,0xB6,0xB7,0xB8,
            0xB9,0xBA,0xC2,0xC3,0xC4,0xC5,0xC6,0xC7,
            0xC8,0xC9,0xCA,0xD2,0xD3,0xD4,0xD5,0xD6,
            0xD7,0xD8,0xD9,0xDA,0xE1,0xE2,0xE3,0xE4,
            0xE5,0xE6,0xE7,0xE8,0xE9,0xEA,0xF1,0xF2,
            0xF3,0xF4,0xF5,0xF6,0xF7,0xF8,0xF9,0xFA,
        ];
            
        let uv_ac_vvec:Vec<u16> =  vec![
            0x00,0x01,//2bit
	           0x02,//3bit
	           0x03,0x11, //4bit
	           0x04,0x05,0x21,0x31, //5bit
	           0x06,0x12,0x41,0x51, //6bit
	           0x07,0x61,0x71, //7bit
	           0x13,0x22,0x32,0x81,   //8bit
	           0x08,0x14,0x42,0x91,0xA1,0xB1,0xC1, //9bit
	           0x09,0x23,0x33,0x52,0xF0,  //10bit
	           0x15,0x62,0x72,0xD1, //11bit
	           0x0A,0x16,0x24,0x34, //12bit
	           0xE1,//14bit
	           0x25,0xF1, //15bit
	           0x17,0x18,0x19,0x1A,0x26,0x27,0x28,
            0x29,0x2A,0x35,0x36,0x37,0x38,0x39,
            0x3A,0x43,0x44,0x45,0x46,0x47,0x48,
            0x49,0x4A,0x53,0x54,0x55,0x56,0x57,
            0x58,0x59,0x5A,0x63,0x64,0x65,0x66,
            0x67,0x68,0x69,0x6A,0x73,0x74,0x75,
            0x76,0x77,0x78,0x79,0x7A,0x82,0x83,
            0x84,0x85,0x86,0x87,0x88,0x89,0x8A,
	           0x92,0x93,0x94,0x95,0x96,0x97,0x98,
            0x99,0x9A,0xA2,0xA3,0xA4,0xA5,0xA6,
            0xA7,0xA8,0xA9,0xAA,0xB2,0xB3,0xB4,
            0xB5,0xB6,0xB7,0xB8,0xB9,0xBA,0xC2,
            0xC3,0xC4,0xC5,0xC6,0xC7,0xC8,0xC9,
            0xCA,0xD2,0xD3,0xD4,0xD5,0xD6,0xD7,
            0xD8,0xD9,0xDA,0xE2,0xE3,0xE4,0xE5,
            0xE6,0xE7,0xE8,0xE9,0xEA,0xF2,0xF3,
            0xF4,0xF5,0xF6,0xF7,0xF8,0xF9,0xFA,
        ];


        
        
        DhtMarker{
            header,
            y_dc_lh,
            uv_dc_lh,
            y_ac_lh,
            uv_ac_lh,
            y_dc_thn, 
            uv_dc_thn,
            y_ac_thn, 
            uv_ac_thn,
            y_dc_lvec,
            uv_dc_lvec,
            y_ac_lvec,
            uv_ac_lvec,
            y_dc_vvec,
            uv_dc_vvec,
            y_ac_vvec,
            uv_ac_vvec,
        }
    }
    
}
