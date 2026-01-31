/// Minimal Rust surface so `cargo fmt` / `clippy` / `test` can run in `just ci`.
pub fn hello(name: &str) -> String {
    format!("hello, {name}")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hello_formats_name() {
        assert_eq!(hello("world"), "hello, world");
    }
}
