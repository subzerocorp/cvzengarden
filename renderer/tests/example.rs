//! The `render` example is the parity oracle for the Wasm build (ZG-4). These
//! tests pin its contract: stdout is byte-identical to `render_json`, and a
//! malformed document yields exit 1, an error naming the line, and no stdout.
//!
//! The example is launched through `cargo run -q --example render` using the
//! same `cargo` that runs this test (`env!("CARGO")`) and this crate's
//! manifest. That is deterministic across `CARGO_TARGET_DIR`, profiles, and
//! cross-compilation, unlike a hard-coded `target/debug/examples/render` path.

use std::io::Write;
use std::path::Path;
use std::process::{Command, Output, Stdio};

use resumezen_renderer::render_json;

fn run_example(stdin: &str) -> Output {
    let mut child = Command::new(env!("CARGO"))
        .args(["run", "-q", "--example", "render"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("spawn cargo run --example render");
    child
        .stdin
        .take()
        .expect("piped stdin")
        .write_all(stdin.as_bytes())
        .expect("write example stdin");
    child.wait_with_output().expect("example finished")
}

fn jordan_json() -> String {
    let path = Path::new(env!("CARGO_MANIFEST_DIR")).join("../skeleton/resume.json");
    std::fs::read_to_string(&path).unwrap_or_else(|err| panic!("read {}: {err}", path.display()))
}

#[test]
fn example_render_matches_render_json() {
    let json = jordan_json();
    let expected = render_json(&json).expect("skeleton/resume.json renders");

    let output = run_example(&json);

    assert!(
        output.status.success(),
        "{}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert_eq!(output.stdout, expected.into_bytes());
}

#[test]
fn example_render_reports_malformed_json_on_stderr() {
    let output = run_example("{");

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert_eq!(output.status.code(), Some(1));
    assert!(stderr.contains("line 1"), "{stderr}");
    assert!(output.stdout.is_empty());
}
