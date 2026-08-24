//! Crate reference oracle: one JSON Resume on stdin, Skeleton HTML on stdout.
//!
//! `cargo run -q --example render < file.json` exits 0 with the exact bytes of
//! `resumezen_renderer::render_json`; on failure it prints the error to stderr,
//! nothing to stdout, and exits 1. The Wasm parity probe compares against this.

use std::io::{self, Read, Write};
use std::process::ExitCode;

fn read_stdin() -> io::Result<String> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;
    Ok(input)
}

fn write_stdout(html: &str) -> io::Result<()> {
    let mut out = io::stdout().lock();
    out.write_all(html.as_bytes())?;
    out.flush()
}

fn fail(message: impl std::fmt::Display) -> ExitCode {
    eprintln!("{message}");
    ExitCode::FAILURE
}

fn main() -> ExitCode {
    let input = match read_stdin() {
        Ok(input) => input,
        Err(err) => return fail(format!("could not read stdin: {err}")),
    };
    match resumezen_renderer::render_json(&input) {
        Ok(html) => write_stdout(&html).map_or_else(fail, |()| ExitCode::SUCCESS),
        Err(err) => fail(err),
    }
}
