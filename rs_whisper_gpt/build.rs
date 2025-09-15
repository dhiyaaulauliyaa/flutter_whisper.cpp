fn main() {
    let target = std::env::var("TARGET").unwrap_or_default();
    
    println!("cargo:rustc-link-lib=framework=Metal");
    println!("cargo:rustc-link-lib=framework=Foundation");
    
    // Link C++ standard library for iOS
    if target.contains("ios") {
        println!("cargo:rustc-link-lib=c++");
        // Set iOS deployment target
        if target.contains("simulator") {
            println!("cargo:rustc-env=IPHONEOS_DEPLOYMENT_TARGET=12.0");
        } else {
            println!("cargo:rustc-env=IPHONEOS_DEPLOYMENT_TARGET=12.0");
        }
    }
}
