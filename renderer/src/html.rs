//! Minimal HTML writer. No template language — the Skeleton is one tree.

pub enum Attr<'a> {
    Kv(&'a str, &'a str),
    Flag(&'a str),
}

pub fn kv<'a>(key: &'a str, value: &'a str) -> Attr<'a> {
    Attr::Kv(key, value)
}

pub fn flag(key: &str) -> Attr<'_> {
    Attr::Flag(key)
}

pub struct Html {
    buf: String,
    depth: usize,
}

impl Html {
    pub fn new() -> Self {
        Self {
            buf: String::with_capacity(16 * 1024),
            depth: 0,
        }
    }

    pub fn doctype(&mut self) {
        self.buf.push_str("<!DOCTYPE html>\n");
    }

    pub fn open(&mut self, tag: &str, attrs: &[Attr<'_>]) {
        self.indent();
        self.buf.push('<');
        self.buf.push_str(tag);
        write_attrs(&mut self.buf, attrs);
        self.buf.push_str(">\n");
        self.depth += 1;
    }

    pub fn close(&mut self, tag: &str) {
        self.depth = self.depth.saturating_sub(1);
        self.indent();
        self.buf.push_str("</");
        self.buf.push_str(tag);
        self.buf.push_str(">\n");
    }

    pub fn void(&mut self, tag: &str, attrs: &[Attr<'_>]) {
        self.indent();
        self.buf.push('<');
        self.buf.push_str(tag);
        write_attrs(&mut self.buf, attrs);
        self.buf.push_str(">\n");
    }

    pub fn text_el(&mut self, tag: &str, attrs: &[Attr<'_>], text: &str) {
        self.indent();
        self.buf.push('<');
        self.buf.push_str(tag);
        write_attrs(&mut self.buf, attrs);
        self.buf.push('>');
        self.buf.push_str(&escape_text(text));
        self.buf.push_str("</");
        self.buf.push_str(tag);
        self.buf.push_str(">\n");
    }

    pub fn finish(self) -> String {
        self.buf
    }

    fn indent(&mut self) {
        for _ in 0..self.depth {
            self.buf.push_str("  ");
        }
    }
}

fn write_attrs(buf: &mut String, attrs: &[Attr<'_>]) {
    for attr in attrs {
        match attr {
            Attr::Kv(key, value) => {
                buf.push(' ');
                buf.push_str(key);
                buf.push_str("=\"");
                buf.push_str(&escape_attr(value));
                buf.push('"');
            }
            Attr::Flag(key) => {
                buf.push(' ');
                buf.push_str(key);
            }
        }
    }
}

pub fn escape_text(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for c in s.chars() {
        match c {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            _ => out.push(c),
        }
    }
    out
}

pub fn escape_attr(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for c in s.chars() {
        match c {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' => out.push_str("&quot;"),
            '\'' => out.push_str("&#39;"),
            _ => out.push(c),
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn escapes_ampersand_in_text() {
        assert_eq!(
            escape_text("Designer & Front-end"),
            "Designer &amp; Front-end"
        );
    }
}
