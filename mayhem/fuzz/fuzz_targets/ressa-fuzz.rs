#![no_main]
use libfuzzer_sys::fuzz_target;
use std::str;
use ressa::*;

fuzz_target!(|data: &[u8]| {
    match str::from_utf8(data) {
        Ok(in_string)=>{
            let mut parser = Parser::new(in_string);
            match parser {
                Ok(mut p)=>{
                    p.parse();
                },
                Err(..)=>()
            }
        },
        Err(..)=>()
    }
});
