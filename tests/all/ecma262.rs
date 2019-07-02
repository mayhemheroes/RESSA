#![cfg(test)]
use super::{get_js_file, EverythingVersion, Lib};
use env_logger;


use ressa::{Builder, Parser};
use resast::ref_tree::prelude::*;
use crate::es_tokens;
#[test]
fn es5() {
    let _ = env_logger::try_init();
    info!("ES5");
    let path = Lib::Everything(EverythingVersion::Es5).path();
    let js = get_js_file(&path).expect(&format!("Faield to get {:?}", path));
    for (i, (item, part)) in Parser::new(&js).expect("Failed to create parser").map(|i| match i {
            Ok(i) => i,
            Err(e) => panic!("Error parsing {:?}\n{}", path, e),
        }).zip(es_tokens::ES5.iter()).enumerate() {
        assert_eq!((i, &item), (i, part));
    }
}

#[test]
fn es2015_script() {
    let _ = env_logger::try_init();
    info!("ES2015 Script");
    let path = Lib::Everything(EverythingVersion::Es2015Script).path();
    let js = get_js_file(&path).expect(&format!("Failed to get {:?}", path));
     for (i, (item, part)) in Parser::new(&js).expect("Failed to create parser").map(|i| match i {
            Ok(i) => i,
            Err(e) => panic!("Error parsing {:?}\n{}", path, e),
        }).zip(es_tokens::ES2015.iter()).enumerate() {
        assert_eq!((i, &item), (i, part));
    }
}

#[test]
fn es2015_module() {
    info!("ES2015 Module");
    let _ = env_logger::try_init();
    let path = Lib::Everything(EverythingVersion::Es2015Module).path();
    let js = get_js_file(&path).expect(&format!("Failed to get {:?}", path));
    let mut b = Builder::new();
    let p = b
        .module(true)
        .js(&js)
        .build()
        .expect("Failed to create parser");
    let _res: Vec<_> = p
        .map(|i| match i {
            Ok(i) => i,
            Err(e) => panic!("Error parsing {:?}\n{}", path, e),
        })
        .collect();
    // only one default export is allowed so these must be run ad-hoc
    let js_list = vec![
        "export default function (){}",
        "export default function* i16(){}",
        "export default function* (){}",
        "export default class i17 {}",
        "export default class i18 extends i19 {}",
        "export default class {}",
        "export default x = 0;",
        "export default 0;",
        "export default (0, 1);",
    ];
    for export in js_list {
        let mut b = Builder::new();
        let p = b
            .module(true)
            .js(export)
            .build()
            .expect("Failed to create parser");
        let _res: Vec<_> = p
            .map(|i| match i {
                Ok(i) => i,
                Err(e) => panic!("Error parsing {}\n{}", export, e),
            })
            .collect();
    }
}