(** The HTML document a sandboxed preview frame runs. The chrome mutates the [<style>] elements and
    the article in place, so Theme swaps cross-fade instead of reloading. *)

let style_id_base = "resumezen-base"
let style_id_theme = "resumezen-theme"
let style_id_paper = "resumezen-paper"

(** A stylesheet is inert text inside [<style>] except for its own closing tag, which is neutralised
    here. *)
let inert_css css =
  Js.String.replaceByRe
    ~regexp:(Js.Re.fromStringWithFlags "</style" ~flags:"gi")
    ~replacement:"<\\/style" css

(** Themes reference the Font Library relative to [/themes/]; a document served elsewhere needs
    those URLs anchored. *)
let font_urls_re = Js.Re.fromStringWithFlags "url\\(\\s*(['\"]?)fonts/" ~flags:"g"

let absolute_font_urls css =
  Js.String.replaceByRe ~regexp:font_urls_re ~replacement:"url($1/themes/fonts/" css

let view_attr (view : View_mode.t) = View_mode.to_key view

(** The page box a paper sheet draws, as custom properties on [<html>]. *)
let page_style (box : Print_media.page_box) =
  Printf.sprintf "--resumezen-sheet-w:%s;--resumezen-sheet-h:%s;--resumezen-page-margin:%s"
    (Print_media.sheet_width box.size)
    (Print_media.sheet_height box.size)
    box.margin

let frame ~base_css ~paper_css ~theme_css ~(view : View_mode.t) ~article =
  String.concat ""
    [
      "<!DOCTYPE html><html lang=\"en\" data-view=\"";
      view_attr view;
      "\" style=\"";
      page_style (Print_media.page_box theme_css);
      "\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, \
       initial-scale=1\">";
      "<style id=\"";
      style_id_base;
      "\">";
      inert_css base_css;
      "</style>";
      "<style id=\"";
      style_id_theme;
      "\">";
      inert_css (absolute_font_urls theme_css);
      "</style>";
      "<style id=\"";
      style_id_paper;
      "\">";
      inert_css paper_css;
      "</style>";
      "</head><body>";
      article;
      "</body></html>";
    ]

(** A downloadable document: the Skeleton with one Theme inlined. *)
let standalone ~theme_css resume =
  Skeleton.render ~style:(inert_css (absolute_font_urls theme_css)) resume
